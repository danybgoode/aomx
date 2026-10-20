extends RefCounted

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const MAX_TICKS := 100000
const MAX_COMMANDS := 200000

var game: RefCounted
var recording: Dictionary
var command_index := 0

static func verify(data: Dictionary) -> Dictionary:
	var opened := _open(data)
	if not opened.ok:
		return opened
	var player = opened.player
	var checkpoints: Array = data.checkpoints
	var checkpoint_index := 0
	for tick_number in range(int(data.end_tick) + 1):
		if tick_number > 0:
			player.game.tick()
			if player.game.tick_number != tick_number:
				return _bad("replay_ended_early", tick_number)
		while checkpoint_index < checkpoints.size() and int(checkpoints[checkpoint_index].get("tick", -1)) == tick_number:
			if checkpoints[checkpoint_index].get("hash") != player.game.state_hash():
				return _bad("checkpoint_mismatch", tick_number)
			checkpoint_index += 1
		var applied: Dictionary = player.apply_current_commands()
		if not applied.ok:
			return applied
	if checkpoint_index != checkpoints.size() or player.command_index != data.commands.size():
		return _bad("history_out_of_range", int(data.end_tick))
	if player.game.state_hash() != data.expected_hash:
		return _bad("final_hash_mismatch", int(data.end_tick))
	if int(data.terminal.get("tick", -1)) != int(data.end_tick) or data.terminal.get("hash") != data.expected_hash:
		return _bad("terminal_mismatch", int(data.end_tick))
	var expected := [player.game.result, "loss" if player.game.result == "win" else "win" if player.game.result == "loss" else "draw"]
	if data.terminal.get("results") != expected:
		return _bad("terminal_mismatch", int(data.end_tick))
	return {"ok": true, "tick": player.game.tick_number, "hash": player.game.state_hash()}

static func create_player(data: Dictionary) -> Dictionary:
	var checked := verify(data)
	if not checked.ok:
		return checked
	return _open(data)

static func _open(data: Dictionary) -> Dictionary:
	if data.get("format") != "battle-for-la-roma-multiplayer-replay" or data.get("replay_schema_version") != 1:
		return _bad("unsupported_replay_version", 0)
	if data.get("game_version") != Skirmish.GAME_VERSION or data.get("content_version") != Skirmish.CONTENT_VERSION:
		return _bad("game_version_mismatch", 0)
	if data.get("map_id") not in RulesContent.MAP_IDS:
		return _bad("replay_map_invalid", 0)
	var loaded: Dictionary = RulesContent.load_map(data.map_id)
	if not loaded.ok or data.get("content_hash") != loaded.hash:
		return _bad("content_version_mismatch", 0)
	if not data.get("factions") is Array or data.factions.size() != 2 or data.factions[0] not in Skirmish.FACTION_IDS or data.factions[1] not in Skirmish.FACTION_IDS:
		return _bad("replay_factions_invalid", 0)
	if not _whole(data.get("initial_seed")) or int(data.initial_seed) < 1 or not _whole(data.get("end_tick")) or int(data.end_tick) < 0 or int(data.end_tick) > MAX_TICKS:
		return _bad("replay_metadata_invalid", 0)
	if not data.get("commands") is Array or data.commands.size() > MAX_COMMANDS or not data.get("checkpoints") is Array or data.checkpoints.size() > MAX_TICKS:
		return _bad("replay_history_invalid", 0)
	if not data.get("expected_hash") is String or data.expected_hash.length() != 64 or not data.get("terminal") is Dictionary:
		return _bad("replay_hash_invalid", 0)
	var last_tick := -1
	var last_sequence := 0
	for command in data.commands:
		if not command is Dictionary or command.get("schema_version") != Skirmish.COMMAND_SCHEMA_VERSION or not _whole(command.get("side")) or int(command.side) not in [0, 1] or not _whole(command.get("issued_tick")) or not _whole(command.get("sequence")) or int(command.issued_tick) < last_tick or int(command.issued_tick) > int(data.end_tick) or int(command.sequence) != last_sequence + 1:
			return _bad("replay_history_invalid", 0)
		last_tick = int(command.issued_tick)
		last_sequence = int(command.sequence)
	var previous := -1
	for checkpoint in data.checkpoints:
		if not checkpoint is Dictionary or not _whole(checkpoint.get("tick")) or int(checkpoint.tick) <= previous or int(checkpoint.tick) > int(data.end_tick) or not checkpoint.get("hash") is String or checkpoint.hash.length() != 64:
			return _bad("replay_history_invalid", 0)
		previous = int(checkpoint.tick)
	var player = new()
	player.recording = data
	player.game = Skirmish.new(data.factions[0], {}, int(data.initial_seed), "standard", data.map_id, data.factions[1])
	player.game.ai_enabled = false
	return {"ok": true, "player": player}

func apply_current_commands() -> Dictionary:
	while command_index < recording.commands.size() and int(recording.commands[command_index].issued_tick) == game.tick_number:
		var response: Dictionary = game.issue_command(recording.commands[command_index])
		if not response.ok:
			return _bad("replay_command_" + response.reason, game.tick_number)
		command_index += 1
	return {"ok": true}

func step() -> Dictionary:
	if game.tick_number >= int(recording.end_tick):
		return {"ok": false, "reason": "replay_complete"}
	game.tick()
	return apply_current_commands()

static func _bad(reason: String, tick: int) -> Dictionary:
	return {"ok": false, "reason": reason, "first_divergent_tick": tick}

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))
