extends RefCounted

const Skirmish = preload("res://skirmish.gd")
const SAVE_PATH := "user://solo-skirmish-save.v1.json"
const SAVE_SCHEMA_VERSION := 3
const MAX_SAVE_BYTES := 16777216
const JOBS := ["idle", "move", "gather", "deliver", "build", "attack", "assist", "repair", "attack_move", "hold"]
const RESOURCE_IDS := ["comida", "materiales", "varos", "terrenos"]
const QUEUE_KINDS := ["unit", "tech", "age"]
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
	if not _validate_history(payload.command_log, payload.hash_checkpoints, state, loaded.data):
		return _bad("save_history_invalid")
	var game = Skirmish.new(state.factions[0], {}, int(state.initial_seed))
	game.tick_number = int(state.tick)
	game.result = state.result
	game.terminal_tick = int(state.terminal_tick)
	game.result_reason = state.result_reason
	game.district_side = int(state.district_side)
	game.district_progress = int(state.district_progress)
	game.district_state = state.district_state
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var saved_balances: Dictionary = state.balances[side]
		game.stockpile[side] = int(saved_balances.varos)
		for resource_id in RESOURCE_IDS:
			if resource_id != "varos":
				game.other_stockpiles[side][resource_id] = int(saved_balances[resource_id])
			var saved_source: Dictionary = state.resource_sources[side][resource_id]
			var source: Dictionary = game.resource_sources[side][resource_id]
			source.amount = int(saved_source.amount)
			source.refresh_remaining = int(saved_source.refresh_remaining)
			source.refreshes_left = int(saved_source.refreshes_left)
		game.sources[side] = game.resource_sources[side].varos
		game.age_index[side] = int(state.age_index[side])
		game.researched[side] = state.researched[side].duplicate()
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
			queue.append({"kind": order.kind, "role": order.role, "remaining": int(order.remaining)})
		game.entities[int(e.id)] = {"id": int(e.id), "side": int(e.side), "kind": e.kind,
			"pos": Vector2i(int(e.pos[0]), int(e.pos[1])), "hp": int(e.hp),
			"complete": e.complete, "progress": int(e.progress), "carry": int(e.carry),
			"carry_resource": e.carry_resource, "source_resource": e.source_resource,
			"job": e.job, "target_id": int(e.target_id), "cooldown": int(e.cooldown),
			"blocked_ticks": int(e.blocked_ticks), "order_pos": Vector2i(int(e.order_pos[0]), int(e.order_pos[1])),
			"path": path, "queue": queue}
	game.projectiles.clear()
	for p in state.projectiles:
		game.projectiles.append({"target_id": int(p.target_id), "tile": Vector2i(int(p.tile[0]), int(p.tile[1])), "origin": Vector2i(int(p.origin[0]), int(p.origin[1])), "damage": int(p.damage), "launch": int(p.launch), "arrival": int(p.arrival)})
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		game.explored_tiles[side].clear()
		for p in state.explored[side]:
			game.explored_tiles[side][Vector2i(int(p[0]), int(p[1]))] = true
		game.last_seen[side].clear()
		for memory in state.last_seen[side]:
			game.last_seen[side][int(memory.id)] = Vector2i(int(memory.pos[0]), int(memory.pos[1]))
	game._refresh_visibility()
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
	if not s.get("factions") is Array or s.factions.size() != 2 or s.factions[0] not in [Skirmish.REGIOS, Skirmish.POBLANOS] or s.factions[1] not in [Skirmish.REGIOS, Skirmish.POBLANOS] or s.factions[1] == s.factions[0]:
		return _bad("state_factions_invalid")
	if not s.get("balances") is Array or s.balances.size() != 2:
		return _bad("state_balances_invalid")
	if not s.get("resource_sources") is Array or s.resource_sources.size() != 2:
		return _bad("state_resource_sources_invalid")
	if not s.get("age_index") is Array or s.age_index.size() != 2:
		return _bad("state_age_index_invalid")
	if not s.get("researched") is Array or s.researched.size() != 2:
		return _bad("state_researched_invalid")
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var balance: Variant = s.balances[side]
		if not _keys_exact(balance, RESOURCE_IDS):
			return _bad("state_balances_invalid")
		for resource_id in RESOURCE_IDS:
			if not _integer(balance[resource_id], 0):
				return _bad("state_balances_invalid")
		var source_set: Variant = s.resource_sources[side]
		if not _keys_exact(source_set, RESOURCE_IDS):
			return _bad("state_resource_sources_invalid")
		for resource_id in RESOURCE_IDS:
			var source: Variant = source_set[resource_id]
			if not _keys_exact(source, ["amount", "refresh_remaining", "refreshes_left"]):
				return _bad("state_resource_sources_invalid")
			for field in ["amount", "refresh_remaining", "refreshes_left"]:
				if not _integer(source[field], 0):
					return _bad("state_resource_sources_invalid")
			if int(source.refreshes_left) > int(content.resources[resource_id].refresh_count):
				return _bad("state_resource_sources_invalid")
		if not _integer(s.age_index[side], 0) or int(s.age_index[side]) >= content.ages.order.size():
			return _bad("state_age_index_invalid")
		if not s.researched[side] is Array or s.researched[side].size() > content.techs.size():
			return _bad("state_researched_invalid")
		var seen_techs: Dictionary = {}
		for tech_id in s.researched[side]:
			if not tech_id is String or tech_id not in content.techs or seen_techs.has(tech_id):
				return _bad("state_researched_invalid")
			seen_techs[tech_id] = true
	if s.get("ai_next_role") not in ["melee", "ranged"] or not s.get("ai_enabled") is bool:
		return _bad("state_ai_invalid")
	if not s.get("projectiles") is Array or s.projectiles.size() > 10000 or not s.get("explored") is Array or s.explored.size() != 2 or not s.get("last_seen") is Array or s.last_seen.size() != 2:
		return _bad("state_visibility_invalid")
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		for p in s.explored[side]:
			if not _point(p, int(content.map.width), int(content.map.height)):
				return _bad("state_visibility_invalid")
		for memory in s.last_seen[side]:
			if not memory is Dictionary or not _integer(memory.get("id"), 1) or not _point(memory.get("pos"), int(content.map.width), int(content.map.height)):
				return _bad("state_visibility_invalid")
	for p in s.projectiles:
		if not p is Dictionary or not _integer(p.get("target_id"), 1) or not _point(p.get("tile"), int(content.map.width), int(content.map.height)) or not _point(p.get("origin"), int(content.map.width), int(content.map.height)) or not _integer(p.get("damage"), 1) or not _integer(p.get("launch"), 0) or not _integer(p.get("arrival"), 1) or int(p.arrival) <= int(p.launch):
			return _bad("state_projectile_invalid")
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
		for key in ["hp", "progress", "carry", "cooldown", "blocked_ticks"]:
			if not _integer(e.get(key), -10000 if key == "hp" else 0):
				return _bad("state_entity_" + key + "_invalid")
		if not _integer(e.get("target_id"), -1) or not e.get("complete") is bool or e.get("job") not in JOBS:
			return _bad("state_entity_job_invalid")
		if not _point(e.get("order_pos"), int(content.map.width), int(content.map.height)):
			return _bad("state_entity_order_invalid")
		if not _resource_or_empty(e.get("carry_resource")) or not _resource_or_empty(e.get("source_resource")):
			return _bad("state_entity_resource_invalid")
		if not e.get("path") is Array or e.path.size() > int(content.map.width) * int(content.map.height):
			return _bad("state_entity_path_invalid")
		for p in e.path:
			if not _point(p, int(content.map.width), int(content.map.height)):
				return _bad("state_entity_path_invalid")
		if not e.get("queue") is Array or e.queue.size() > 3:
			return _bad("state_entity_queue_invalid")
		for order in e.queue:
			if not _keys_exact(order, ["kind", "role", "remaining"]) or order.kind not in QUEUE_KINDS or not _integer(order.remaining, 0):
				return _bad("state_entity_queue_invalid")
			match order.kind:
				"unit":
					if order.role not in content.units:
						return _bad("state_entity_queue_invalid")
				"tech":
					if order.role not in content.techs:
						return _bad("state_entity_queue_invalid")
				"age":
					if order.role not in content.ages.transitions:
						return _bad("state_entity_queue_invalid")
	if int(s.next_id) <= last_id:
		return _bad("state_next_id_invalid")
	return {"ok": true}

static func _validate_history(commands: Array, checkpoints: Array, state: Dictionary, content: Dictionary) -> bool:
	if commands.size() > 200000 or checkpoints.size() > 200000 or int(state.next_command) != commands.size() + 1:
		return false
	var sequence := 0
	for raw in commands:
		if not raw is Dictionary:
			return false
		sequence += 1
		if not _integer(raw.get("sequence"), 1) or int(raw.sequence) != sequence or not _integer(raw.get("issued_tick"), 0) or int(raw.issued_tick) > int(state.tick):
			return false
		if raw.get("schema_version") != Skirmish.COMMAND_SCHEMA_VERSION or not _integer(raw.get("side"), 0) or int(raw.side) > 1 or not _integer(raw.get("actor_id"), 1):
			return false
		if not _command_target(raw.get("kind"), raw.get("target"), content):
			return false
	var last_tick := -1
	for cp in checkpoints:
		if not cp is Dictionary or not _integer(cp.get("tick"), 1) or int(cp.tick) <= last_tick or int(cp.tick) > int(state.tick):
			return false
		if not cp.get("hash") is String or cp.hash.length() != 64:
			return false
		last_tick = int(cp.tick)
	return true

static func _command_target(kind: Variant, target: Variant, content: Dictionary) -> bool:
	var width := int(content.map.width)
	var height := int(content.map.height)
	match kind:
		"move", "gather", "attack_move":
			return _point(target, width, height)
		"build":
			if _point(target, width, height):
				return true
			return _keys_exact(target, ["kind", "pos"]) and target.kind in content.buildings and target.kind != "command_post" and _point(target.pos, width, height)
		"train":
			return target is String and target in content.units
		"research":
			return target is String and target in content.techs
		"advance":
			return target is String and target in content.ages.transitions
		"stop", "hold":
			return target is String and target == ""
		"attack", "assist", "repair":
			return _integer(target, 1)
		"cancel":
			return _integer(target, 0)
	return false

static func _keys_exact(value: Variant, expected: Array) -> bool:
	if not value is Dictionary or value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true

static func _resource_or_empty(value: Variant) -> bool:
	return value is String and (value == "" or value in RESOURCE_IDS)

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
