extends RefCounted

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const REPLAY_SCHEMA_VERSION := 1

static func record(game: RefCounted) -> Dictionary:
	var human: Array[Dictionary] = []
	for command in game.command_log:
		if command.side == Skirmish.HUMAN:
			human.append(command.duplicate(true))
	return {"format": "battle-for-la-roma-replay", "replay_schema_version": REPLAY_SCHEMA_VERSION,
		"game_version": Skirmish.GAME_VERSION, "content_version": game.content.content_id,
		"content_hash": game.content_hash, "human_faction": game.factions[Skirmish.HUMAN],
		"initial_seed": game.initial_seed, "end_tick": game.tick_number,
		"human_commands": human, "checkpoints": game.hash_checkpoints.duplicate(true),
		"expected_hash": game.state_hash(),
		"expected_log_hash": JSON.stringify(game.command_log).sha256_text()}

static func verify(recording: Dictionary) -> Dictionary:
	if recording.get("format") != "battle-for-la-roma-replay" or recording.get("replay_schema_version") != REPLAY_SCHEMA_VERSION:
		return _bad("unsupported_replay_version", 0)
	if recording.get("game_version") != Skirmish.GAME_VERSION:
		return _bad("game_version_mismatch", 0)
	var loaded: Dictionary = RulesContent.load_default()
	if not loaded.ok or recording.get("content_version") != loaded.data.content_id or recording.get("content_hash") != loaded.hash:
		return _bad("content_version_mismatch", 0)
	if recording.get("human_faction") not in [Skirmish.REGIOS, Skirmish.POBLANOS] or not _integer(recording.get("initial_seed"), 1) or not _integer(recording.get("end_tick"), 0):
		return _bad("replay_metadata_invalid", 0)
	if not recording.get("human_commands") is Array or not recording.get("checkpoints") is Array:
		return _bad("replay_history_invalid", 0)
	if not recording.get("expected_hash") is String or recording.expected_hash.length() != 64 or not recording.get("expected_log_hash") is String or recording.expected_log_hash.length() != 64:
		return _bad("replay_hash_invalid", 0)
	var commands: Array = recording.human_commands
	var checkpoints: Array = recording.checkpoints
	var end_tick := int(recording.end_tick)
	if end_tick > 100000 or commands.size() > 200000 or checkpoints.size() > 200000:
		return _bad("replay_history_invalid", 0)
	var last_command_tick := -1
	for entry in commands:
		if not entry is Dictionary or not _integer(entry.get("issued_tick"), 0) or int(entry.issued_tick) < last_command_tick or int(entry.issued_tick) > end_tick:
			return _bad("replay_history_invalid", 0)
		last_command_tick = int(entry.issued_tick)
	var last_checkpoint_tick := -1
	for entry in checkpoints:
		if not entry is Dictionary or not _integer(entry.get("tick"), 1) or int(entry.tick) <= last_checkpoint_tick or int(entry.tick) > end_tick or not entry.get("hash") is String or entry.hash.length() != 64:
			return _bad("replay_history_invalid", 0)
		last_checkpoint_tick = int(entry.tick)
	var game = Skirmish.new(recording.human_faction, {}, int(recording.initial_seed))
	var command_index := 0
	var checkpoint_index := 0
	for logical_tick in range(end_tick + 1):
		if logical_tick > 0:
			game.tick()
			if game.tick_number != logical_tick:
				return _bad("replay_ended_early", logical_tick)
		while checkpoint_index < checkpoints.size() and checkpoints[checkpoint_index].get("tick") == logical_tick:
			var cp: Dictionary = checkpoints[checkpoint_index]
			if cp.get("hash") != game.state_hash():
				return _bad("checkpoint_mismatch", logical_tick)
			checkpoint_index += 1
		while command_index < commands.size() and commands[command_index].get("issued_tick") == logical_tick:
			var command: Dictionary = commands[command_index]
			if command.get("side") != Skirmish.HUMAN or command.get("schema_version") != Skirmish.COMMAND_SCHEMA_VERSION:
				return _bad("replay_command_invalid", logical_tick)
			var response: Dictionary = game.issue_command(command)
			if not response.ok:
				return _bad("replay_command_" + response.reason, logical_tick)
			command_index += 1
	if command_index != commands.size() or checkpoint_index != checkpoints.size():
		return _bad("replay_history_out_of_range", int(recording.end_tick))
	if JSON.stringify(game.command_log).sha256_text() != recording.expected_log_hash:
		return _bad("command_log_mismatch", int(recording.end_tick))
	if game.state_hash() != recording.expected_hash:
		return _bad("final_hash_mismatch", int(recording.end_tick))
	return {"ok": true, "game": game, "tick": game.tick_number, "hash": game.state_hash()}

static func _integer(v: Variant, minimum: int) -> bool:
	return (v is int or v is float) and float(v) == float(int(v)) and int(v) >= minimum

static func _bad(reason: String, tick: int) -> Dictionary:
	return {"ok": false, "reason": reason, "first_divergent_tick": tick}
