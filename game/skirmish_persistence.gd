extends RefCounted

const Skirmish = preload("res://skirmish.gd")
const SAVE_PATH := "user://solo-skirmish-save.v1.json"
const SAVE_SCHEMA_VERSION := 1
const MAX_SAVE_BYTES := 16777216
const JOBS := ["idle", "move", "gather", "deliver", "build", "attack"]
const RESULTS := ["", "win", "loss", "draw"]

static func capture(game: RefCounted, match_id: String, completion_queued: bool = false) -> Dictionary:
	return {"format": "battle-for-la-roma-save", "save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": Skirmish.GAME_VERSION, "content_version": game.content.content_id,
		"content_hash": game.content_hash, "match_id": match_id,
		"completion_queued": completion_queued, "state": game.snapshot(),
		"state_hash": game.state_hash(), "command_log": game.command_log.duplicate(true),
		"hash_checkpoints": game.hash_checkpoints.duplicate(true)}

static func write(game: RefCounted, match_id: String, completion_queued: bool = false, path: String = SAVE_PATH) -> Dictionary:
	if not _match_id(match_id):
		return _bad("invalid_match_id")
	var payload := JSON.stringify(capture(game, match_id, completion_queued))
	if payload.to_utf8_buffer().size() > MAX_SAVE_BYTES:
		return _bad("save_too_large")
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _bad("save_storage_unavailable")
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.get_file_as_string(temporary) != payload:
		return _bad("save_write_failed")
	var rename_error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if rename_error != OK:
		return _bad("save_replace_failed")
	return {"ok": true, "path": path, "state_hash": game.state_hash()}

static func read(path: String = SAVE_PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return _bad("save_missing")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _bad("save_storage_unavailable")
	if file.get_length() > MAX_SAVE_BYTES:
		file.close()
		return _bad("save_too_large")
	var raw := file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(raw) != OK:
		return _bad("save_corrupt")
	var parsed = parser.data
	if not parsed is Dictionary:
		return _bad("save_corrupt")
	return restore(parsed)

static func restore(payload: Dictionary) -> Dictionary:
	if payload.get("format") != "battle-for-la-roma-save":
		return _bad("save_format_unknown")
	if not _integer(payload.get("save_schema_version"), 0) or int(payload.save_schema_version) != SAVE_SCHEMA_VERSION:
		return _bad("unsupported_save_version")
	if payload.get("game_version") != Skirmish.GAME_VERSION:
		return _bad("unsupported_game_version")
	var loaded: Dictionary = preload("res://rules_content.gd").load_default()
	if not loaded.ok or payload.get("content_version") != loaded.data.content_id or payload.get("content_hash") != loaded.hash:
		return _bad("content_version_mismatch")
	if not _match_id(payload.get("match_id")) or not payload.get("completion_queued") is bool:
		return _bad("save_metadata_invalid")
	if not payload.get("state") is Dictionary or not payload.get("state_hash") is String:
		return _bad("save_state_invalid")
	var state: Dictionary = payload.state
	var checked := _validate_state(state, loaded.data, loaded.hash)
	if not checked.ok:
		return checked
	if not payload.get("command_log") is Array or not payload.get("hash_checkpoints") is Array:
		return _bad("save_history_invalid")
	if not _validate_history(payload.command_log, payload.hash_checkpoints, state):
		return _bad("save_history_invalid")
	var game = Skirmish.new(state.factions[0], {}, int(state.initial_seed))
	game.tick_number = int(state.tick)
	game.result = state.result
	game.terminal_tick = int(state.terminal_tick)
	game.result_reason = state.result_reason
	game.district_side = int(state.district_side)
	game.district_progress = int(state.district_progress)
	game.district_state = state.district_state
	game.stockpile = {Skirmish.HUMAN: int(state.stockpile[0]), Skirmish.COMPUTER: int(state.stockpile[1])}
	game.sources[Skirmish.HUMAN].amount = int(state.sources[0])
	game.sources[Skirmish.COMPUTER].amount = int(state.sources[1])
	game.next_id = int(state.next_id)
	game.next_command = int(state.next_command)
	game.ai_next_role = state.ai_next_role
	game.ai_enabled = state.ai_enabled
	game.rng_state = int(state.rng_state)
	game.entities.clear()
	for raw_entity in state.entities:
		var e: Dictionary = raw_entity
		var path: Array[Vector2i] = []
		for p in e.path:
			path.append(Vector2i(int(p[0]), int(p[1])))
		var queue: Array = []
		for order in e.queue:
			queue.append({"role": order.role, "remaining": int(order.remaining)})
		game.entities[int(e.id)] = {"id": int(e.id), "side": int(e.side), "kind": e.kind,
			"pos": Vector2i(int(e.pos[0]), int(e.pos[1])), "hp": int(e.hp),
			"complete": e.complete, "progress": int(e.progress), "carry": int(e.carry),
			"job": e.job, "target_id": int(e.target_id), "cooldown": int(e.cooldown),
			"path": path, "queue": queue}
	game.rebuild_navigation()
	game.command_log.clear()
	for command in payload.command_log:
		game.command_log.append(command.duplicate(true))
	game.hash_checkpoints.clear()
	for checkpoint in payload.hash_checkpoints:
		game.hash_checkpoints.append({"tick": int(checkpoint.tick), "hash": checkpoint.hash})
	if game.state_hash() != payload.state_hash:
		return _bad("save_hash_mismatch")
	return {"ok": true, "game": game, "match_id": payload.match_id,
		"completion_queued": payload.completion_queued, "state_hash": payload.state_hash}

static func _validate_state(s: Dictionary, content: Dictionary, hash: String) -> Dictionary:
	if s.get("state_schema_version") != Skirmish.STATE_SCHEMA_VERSION or s.get("content_version") != content.content_id or s.get("content_hash") != hash:
		return _bad("state_version_mismatch")
	for key in ["tick", "district_progress", "next_id", "next_command", "rng_state", "initial_seed"]:
		if not _integer(s.get(key), 1 if key in ["next_id", "next_command", "rng_state", "initial_seed"] else 0):
			return _bad("state_" + key + "_invalid")
	if not _integer(s.get("terminal_tick"), -1) or not _integer(s.get("district_side"), -1) or int(s.district_side) > 1:
		return _bad("state_terminal_invalid")
	if s.get("result") not in RESULTS or not s.get("result_reason") is String or not s.get("district_state") is String:
		return _bad("state_result_invalid")
	if s.result == "" and int(s.terminal_tick) != -1:
		return _bad("state_terminal_invalid")
	if s.result != "" and int(s.terminal_tick) > int(s.tick):
		return _bad("state_terminal_invalid")
	if not s.get("factions") is Array or s.factions.size() != 2 or s.factions[0] not in [Skirmish.REGIOS, Skirmish.POBLANOS] or s.factions[1] == s.factions[0]:
		return _bad("state_factions_invalid")
	for key in ["stockpile", "sources"]:
		if not s.get(key) is Array or s[key].size() != 2:
			return _bad("state_" + key + "_invalid")
		for n in s[key]:
			if not _integer(n, 0):
				return _bad("state_" + key + "_invalid")
	if s.get("ai_next_role") not in ["melee", "ranged"] or not s.get("ai_enabled") is bool:
		return _bad("state_ai_invalid")
	if not s.get("entities") is Array or s.entities.size() > 10000:
		return _bad("state_entities_invalid")
	var last_id := 0
	for raw_entity in s.entities:
		if not raw_entity is Dictionary:
			return _bad("state_entity_invalid")
		var e: Dictionary = raw_entity
		if not _integer(e.get("id"), 1) or int(e.id) <= last_id or not _integer(e.get("side"), 0) or int(e.side) > 1:
			return _bad("state_entity_id_invalid")
		last_id = int(e.id)
		if e.get("kind") not in content.units and e.get("kind") not in content.buildings:
			return _bad("state_entity_kind_invalid")
		if not _point(e.get("pos"), int(content.map.width), int(content.map.height)):
			return _bad("state_entity_position_invalid")
		for key in ["hp", "progress", "carry", "cooldown"]:
			if not _integer(e.get(key), -10000 if key == "hp" else 0):
				return _bad("state_entity_" + key + "_invalid")
		if not _integer(e.get("target_id"), -1) or not e.get("complete") is bool or e.get("job") not in JOBS:
			return _bad("state_entity_job_invalid")
		if not e.get("path") is Array or e.path.size() > int(content.map.width) * int(content.map.height):
			return _bad("state_entity_path_invalid")
		for p in e.path:
			if not _point(p, int(content.map.width), int(content.map.height)):
				return _bad("state_entity_path_invalid")
		if not e.get("queue") is Array or e.queue.size() > 3:
			return _bad("state_entity_queue_invalid")
		for order in e.queue:
			if not order is Dictionary or order.get("role") not in content.units or not _integer(order.get("remaining"), 0):
				return _bad("state_entity_queue_invalid")
	if int(s.next_id) <= last_id:
		return _bad("state_next_id_invalid")
	return {"ok": true}

static func _validate_history(commands: Array, checkpoints: Array, state: Dictionary) -> bool:
	if commands.size() > 200000 or checkpoints.size() > 200000 or int(state.next_command) != commands.size() + 1:
		return false
	var sequence := 0
	for raw in commands:
		if not raw is Dictionary:
			return false
		sequence += 1
		if not _integer(raw.get("sequence"), 1) or int(raw.sequence) != sequence or not _integer(raw.get("issued_tick"), 0) or int(raw.issued_tick) > int(state.tick):
			return false
		if raw.get("schema_version") != Skirmish.COMMAND_SCHEMA_VERSION or raw.get("kind") not in ["move", "gather", "build", "train", "attack"] or not _integer(raw.get("side"), 0) or int(raw.side) > 1 or not _integer(raw.get("actor_id"), 1):
			return false
	var last_tick := -1
	for cp in checkpoints:
		if not cp is Dictionary or not _integer(cp.get("tick"), 1) or int(cp.tick) <= last_tick or int(cp.tick) > int(state.tick):
			return false
		if not cp.get("hash") is String or cp.hash.length() != 64:
			return false
		last_tick = int(cp.tick)
	return true

static func _integer(v: Variant, minimum: int) -> bool:
	return (v is int or v is float) and float(v) == float(int(v)) and int(v) >= minimum

static func _point(p: Variant, w: int, h: int) -> bool:
	return p is Array and p.size() == 2 and _integer(p[0], 0) and _integer(p[1], 0) and int(p[0]) < w and int(p[1]) < h

static func _match_id(value: Variant) -> bool:
	if not value is String or value.length() != 37 or not value.begins_with("solo_"):
		return false
	for c in value.substr(5):
		if c not in "0123456789abcdef":
			return false
	return true

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
