extends RefCounted

const RulesContent = preload("res://rules_content.gd")

const WIDTH := 20
const HEIGHT := 20
const HUMAN := 0
const COMPUTER := 1
const REGIOS := "regios"
const POBLANOS := "poblanos"
const DRAW_TICK := 9000
const RESOURCE_POS := {HUMAN: Vector2i(6, 4), COMPUTER: Vector2i(13, 15)}
const BARRACKS_POS := {HUMAN: Vector2i(5, 6), COMPUTER: Vector2i(13, 11)}
const COST := {"barracks": 6, "worker": 4, "melee": 3, "ranged": 4}
const TRAIN_TICKS := {"worker": 40, "melee": 45, "ranged": 55}
const HEALTH := {"worker": 8, "melee": 14, "ranged": 8, "command_post": 50, "barracks": 30}
const DAMAGE := {"melee": 3, "ranged": 2}
const RANGE := {"melee": 1, "ranged": 3}
const COOLDOWN := {"melee": 10, "ranged": 14}
const BUILD_TICKS := 40
const CARRY_LIMIT := 4
const AI_ATTACK_TICK := 800
const AI_DISTRICT_TICK := 350
const DISTRICT_MIN := Vector2i(9, 9)
const DISTRICT_MAX := Vector2i(11, 11)
const HOLD_TICKS := 600
const GAME_VERSION := "godot-4.7.2-skirmish-1"
const CONTENT_VERSION := "la-roma-prototype-1"
const COMMAND_SCHEMA_VERSION := 1
const STATE_SCHEMA_VERSION := 1

var factions: Dictionary = {HUMAN: REGIOS, COMPUTER: POBLANOS}
var content: Dictionary = {}
var content_hash := ""
var map_width := WIDTH
var map_height := HEIGHT
var blocked_tiles: Dictionary = {}
var building_tiles: Dictionary = {}
var rng_state := 1
var initial_seed := 1
var hash_checkpoints: Array[Dictionary] = []
var entities: Dictionary = {}
var sources: Dictionary = {}
var stockpile: Dictionary = {HUMAN: 0, COMPUTER: 0}
var next_id := 1
var tick_number := 0
var result := ""
var terminal_tick := -1
var result_reason := ""
var district_side := -1
var district_progress := 0
var district_state := "neutral"
var feedback := "Gather resource, build a recruitment post, then train an army."
var command_log: Array[Dictionary] = []
var next_command := 1
var ai_next_role := "melee"
var ai_enabled := true
var pending_footprint := Vector2i(-1, -1)

func _init(human_faction: String = REGIOS, custom_content: Dictionary = {}, seed: int = 1) -> void:
	assert(human_faction in [REGIOS, POBLANOS], "Choose a supported faction.")
	if custom_content.is_empty():
		var loaded := RulesContent.load_default()
		assert(loaded.ok, "Could not load validated skirmish content: " + str(loaded.get("reason", "unknown")))
		content = loaded.data
		content_hash = loaded.hash
	else:
		var checked := RulesContent.validate(custom_content)
		assert(checked.ok, "Invalid skirmish content: " + str(checked.get("reason", "unknown")))
		content = custom_content.duplicate(true)
		content_hash = JSON.stringify(content).sha256_text()
	map_width = int(content.map.width)
	map_height = int(content.map.height)
	for point in content.map.blocked_tiles:
		blocked_tiles[Vector2i(int(point[0]), int(point[1]))] = true
	rng_state = seed if seed != 0 else 1
	initial_seed = rng_state
	factions = {HUMAN: human_faction, COMPUTER: POBLANOS if human_faction == REGIOS else REGIOS}
	sources = {HUMAN: {"pos": _point(content.map.resource_positions[HUMAN]), "amount": int(content.map.resource_amount)},
		COMPUTER: {"pos": _point(content.map.resource_positions[COMPUTER]), "amount": int(content.map.resource_amount)}}
	for side in [HUMAN, COMPUTER]:
		_add_entity(side, "command_post", _point(content.map.command_posts[side]))
		_add_entity(side, "worker", _point(content.map.workers[side]))

func issue_command(command: Dictionary) -> Dictionary:
	if command.get("schema_version") != COMMAND_SCHEMA_VERSION:
		return {"ok": false, "reason": "unsupported_command_schema"}
	if command.get("issued_tick") != tick_number or command.get("sequence") != next_command:
		return {"ok": false, "reason": "command_order_mismatch"}
	for key in ["side", "kind", "actor_id", "target"]:
		if not command.has(key):
			return {"ok": false, "reason": "command_missing_" + key}
	if not _whole_number(command.side) or not _whole_number(command.actor_id) or not command.kind is String:
		return {"ok": false, "reason": "command_type_invalid"}
	var target: Variant = command.target
	if command.kind in ["move", "gather", "build"]:
		if not target is Array or target.size() != 2 or not _whole_number(target[0]) or not _whole_number(target[1]):
			return {"ok": false, "reason": "command_target_invalid"}
		target = Vector2i(int(target[0]), int(target[1]))
	elif command.kind == "attack":
		if not _whole_number(target):
			return {"ok": false, "reason": "command_target_invalid"}
		target = int(target)
	elif command.kind == "train":
		if not target is String or target not in content.units:
			return {"ok": false, "reason": "command_target_invalid"}
	else:
		return {"ok": false, "reason": "command_kind_invalid"}
	return issue(int(command.side), command.kind, int(command.actor_id), target)

func issue(side: int, kind: String, actor_id: int, target: Variant = null) -> Dictionary:
	var rejected := {"ok": false, "reason": "invalid_order"}
	if result != "":
		return {"ok": false, "reason": "match_finished"}
	if side not in [HUMAN, COMPUTER] or not entities.has(actor_id):
		return {"ok": false, "reason": "unknown_actor"}
	var actor: Dictionary = entities[actor_id]
	if actor.side != side or actor.hp <= 0:
		return {"ok": false, "reason": "wrong_side_or_dead"}
	match kind:
		"move":
			if actor.kind == "command_post" or actor.kind == "barracks" or not target is Vector2i or not _walkable(target):
				rejected.reason = "blocked_or_invalid_tile"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return tile == target)
				if route.is_empty() and actor.pos != target:
					rejected.reason = "unreachable_tile"
				else:
					actor.path = route
					actor.job = "move" if not route.is_empty() else "idle"
					rejected = {"ok": true, "reason": "moving"}
		"gather":
			if actor.kind != "worker" or target != sources[side].pos or sources[side].amount <= 0:
				rejected.reason = "resource_unavailable"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance(tile, target) == 1)
				if route.is_empty() and _distance(actor.pos, target) != 1:
					rejected.reason = "resource_unreachable"
				else:
					actor.path = route
					actor.job = "gather"
					rejected = {"ok": true, "reason": "gathering"}
		"build":
			if actor.kind != "worker" or not target is Vector2i:
				rejected.reason = "worker_required"
			elif _find(side, "barracks") != -1:
				rejected.reason = "only_one_recruitment_post"
			elif stockpile[side] < _cost(side, "barracks"):
				rejected.reason = "insufficient_stockpile"
			elif not _clear_footprint(target):
				rejected.reason = "blocked_footprint"
			else:
				pending_footprint = target
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_footprint(tile, target) == 1)
				pending_footprint = Vector2i(-1, -1)
				if route.is_empty() and _distance_to_footprint(actor.pos, target) != 1:
					rejected.reason = "building_unreachable"
				else:
					stockpile[side] -= _cost(side, "barracks")
					var building_id := _add_entity(side, "barracks", target)
					entities[building_id].complete = false
					entities[building_id].progress = 0
					actor.path = route
					actor.job = "build"
					actor.target_id = building_id
					rejected = {"ok": true, "reason": "construction_started"}
		"train":
			if actor.kind not in ["command_post", "barracks"] or not target is String:
				rejected.reason = "production_building_required"
			elif not actor.complete:
				rejected.reason = "building_incomplete"
			elif target not in content.buildings[actor.kind].trains:
				rejected.reason = "role_unavailable"
			elif stockpile[side] < _cost(side, target):
				rejected.reason = "insufficient_stockpile"
			elif actor.queue.size() >= 3:
				rejected.reason = "queue_full"
			else:
				stockpile[side] -= _cost(side, target)
				actor.queue.append({"role": target, "remaining": int(content.units[target].train_ticks)})
				rejected = {"ok": true, "reason": "training_queued"}
		"attack":
			if actor.kind not in ["melee", "ranged"] or not target is int or not entities.has(target):
				rejected.reason = "combat_unit_and_target_required"
			elif entities[target].side == side or entities[target].hp <= 0:
				rejected.reason = "invalid_enemy_target"
			else:
				var reach := int(content.units[actor.kind].range)
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, entities[target]) <= reach)
				if route.is_empty() and _distance_to_entity(actor.pos, entities[target]) > reach:
					rejected.reason = "target_unreachable"
				else:
					actor.path = route
					actor.job = "attack"
					actor.target_id = target
					rejected = {"ok": true, "reason": "attacking"}
	if rejected.ok:
		command_log.append({"command_id": "command_%05d" % next_command,
			"schema_version": COMMAND_SCHEMA_VERSION, "sequence": next_command, "issued_tick": tick_number, "side": side, "kind": kind,
			"actor_id": actor_id, "target": _log_target(target), "game_version": GAME_VERSION,
			"content_version": CONTENT_VERSION, "test_account": true})
		next_command += 1
	if side == HUMAN:
		feedback = rejected.reason.replace("_", " ")
	return rejected

func tick() -> void:
	if result != "":
		return
	tick_number += 1
	if ai_enabled and tick_number % int(content.ai.step_ticks) == 0:
		_ai_step()
	var damages: Dictionary = {}
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		if not entities.has(id):
			continue
		var entity: Dictionary = entities[id]
		if entity.hp <= 0:
			continue
		if entity.kind in ["command_post", "barracks"]:
			_tick_production(entity)
			continue
		if entity.cooldown > 0:
			entity.cooldown -= 1
		if not entity.path.is_empty():
			if tick_number % 3 == 0:
				entity.pos = entity.path.pop_front()
			continue
		match entity.job:
			"gather": _tick_gather(entity)
			"deliver": _tick_deliver(entity)
			"build": _tick_build(entity)
			"attack": _tick_attack(entity, damages)
			"move": entity.job = "idle"
	var damage_ids: Array = damages.keys()
	damage_ids.sort()
	for target_id in damage_ids:
		if entities.has(target_id):
			entities[target_id].hp -= damages[target_id]
	for id in ids:
		if entities.has(id) and entities[id].hp <= 0 and entities[id].kind not in ["command_post"]:
			if entities[id].kind in content.buildings:
				_release_building(entities[id].pos)
			entities.erase(id)
	var human_post := _find(HUMAN, "command_post")
	var computer_post := _find(COMPUTER, "command_post")
	var human_dead: bool = human_post == -1 or entities[human_post].hp <= 0
	var computer_dead: bool = computer_post == -1 or entities[computer_post].hp <= 0
	if human_dead and computer_dead:
		_finish("draw", "simultaneous_posts")
	elif computer_dead:
		_finish("win", "command_post")
	elif human_dead:
		_finish("loss", "command_post")
	else:
		_tick_district()
		if result == "" and tick_number >= int(content.objectives.draw_tick):
			_finish("draw", "time_limit")
	if tick_number % 50 == 0 or result != "":
		hash_checkpoints.append({"tick": tick_number, "hash": state_hash()})

func _tick_district() -> void:
	var present := {HUMAN: false, COMPUTER: false}
	for e in entities.values():
		if e.hp > 0 and e.kind in ["melee", "ranged"] and _in_district(e.pos):
			present[e.side] = true
	if present[HUMAN] and present[COMPUTER]:
		district_state = "contested"
		district_side = -1
		district_progress = 0
		return
	if not present[HUMAN] and not present[COMPUTER]:
		district_state = "reset" if district_progress > 0 else "neutral"
		district_side = -1
		district_progress = 0
		return
	var owner: int = HUMAN if present[HUMAN] else COMPUTER
	if district_side == owner:
		district_progress += 1
	else:
		district_side = owner
		district_progress = 1
		district_state = "human_hold" if owner == HUMAN else "computer_hold"
	if district_progress >= int(content.objectives.district_hold_ticks):
		_finish("win" if owner == HUMAN else "loss", "district")

func snapshot() -> Dictionary:
	var list: Array = []
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		var e: Dictionary = entities[id]
		list.append({"id": id, "side": e.side, "kind": e.kind, "pos": [e.pos.x, e.pos.y],
			"hp": e.hp, "complete": e.complete, "progress": e.progress, "carry": e.carry,
			"job": e.job, "target_id": e.target_id, "cooldown": e.cooldown,
			"path": e.path.map(func(p: Vector2i) -> Array: return [p.x, p.y]), "queue": e.queue.duplicate(true)})
	return {"tick": tick_number, "result": result, "terminal_tick": terminal_tick,
		"result_reason": result_reason, "district_side": district_side,
		"district_progress": district_progress, "district_state": district_state,
		"state_schema_version": STATE_SCHEMA_VERSION, "content_version": content.content_id,
		"content_hash": content_hash, "rng_state": rng_state, "initial_seed": initial_seed,
		"factions": [factions[HUMAN], factions[COMPUTER]],
		"stockpile": [stockpile[HUMAN], stockpile[COMPUTER]],
		"sources": [sources[HUMAN].amount, sources[COMPUTER].amount], "entities": list,
		"next_id": next_id, "next_command": next_command, "ai_next_role": ai_next_role,
		"ai_enabled": ai_enabled}

func state_hash() -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(JSON.stringify(snapshot()).to_utf8_buffer())
	return hash.finish().hex_encode()

func _add_entity(side: int, kind: String, pos: Vector2i) -> int:
	assert(kind in content.units or kind in content.buildings, "Unknown content ID: " + kind)
	var id := next_id
	next_id += 1
	entities[id] = {"id": id, "side": side, "kind": kind, "pos": pos, "hp": _starting_health(side, kind),
		"complete": true, "progress": 0, "carry": 0, "job": "idle", "path": [],
		"target_id": -1, "cooldown": 0, "queue": []}
	if kind in content.buildings:
		_occupy_building(pos)
	return id

func _occupy_building(at: Vector2i) -> void:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		building_tiles[tile] = int(building_tiles.get(tile, 0)) + 1

func _release_building(at: Vector2i) -> void:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		var remaining := int(building_tiles.get(tile, 0)) - 1
		if remaining > 0:
			building_tiles[tile] = remaining
		else:
			building_tiles.erase(tile)

func rebuild_navigation() -> void:
	building_tiles.clear()
	for e in entities.values():
		if e.kind in content.buildings and e.hp > 0:
			_occupy_building(e.pos)

func _find(side: int, kind: String) -> int:
	for id in entities:
		if entities[id].side == side and entities[id].kind == kind and entities[id].hp > 0:
			return id
	return -1

func _tick_gather(e: Dictionary) -> void:
	var source: Dictionary = sources[e.side]
	if _distance(e.pos, source.pos) != 1:
		e.job = "idle"
	elif source.amount > 0 and e.carry < _carry_limit(e.side):
		if tick_number % 3 == 0:
			source.amount -= 1
			e.carry += 1
	elif e.carry > 0:
		var post_id := _find(e.side, "command_post")
		if post_id == -1:
			e.job = "idle"
		else:
			e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, entities[post_id]) == 1)
			e.job = "deliver"
	else:
		e.job = "idle"

func _tick_deliver(e: Dictionary) -> void:
	var post_id := _find(e.side, "command_post")
	if post_id == -1 or _distance_to_entity(e.pos, entities[post_id]) != 1:
		e.job = "idle"
		return
	stockpile[e.side] += e.carry
	e.carry = 0
	if sources[e.side].amount > 0:
		e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance(tile, sources[e.side].pos) == 1)
		e.job = "gather"
	else:
		e.job = "idle"

func _tick_build(e: Dictionary) -> void:
	if not entities.has(e.target_id):
		e.job = "idle"
		return
	var building: Dictionary = entities[e.target_id]
	if _distance_to_entity(e.pos, building) != 1:
		e.job = "idle"
		return
	building.progress += 1
	if building.progress >= int(content.buildings.barracks.build_ticks):
		building.complete = true
		e.job = "idle"
		if e.side == HUMAN:
			feedback = "Recruitment post complete."

func _tick_production(e: Dictionary) -> void:
	if not e.complete or e.queue.is_empty():
		return
	var order: Dictionary = e.queue[0]
	if order.remaining > 0:
		order.remaining -= 1
		return
	for tile in _perimeter(e.pos):
		if _walkable(tile) and _unit_at(tile) == -1:
			_add_entity(e.side, order.role, tile)
			e.queue.pop_front()
			return

func _tick_attack(e: Dictionary, damages: Dictionary) -> void:
	if not entities.has(e.target_id) or entities[e.target_id].hp <= 0:
		e.job = "idle"
		return
	var target: Dictionary = entities[e.target_id]
	if _distance_to_entity(e.pos, target) > int(content.units[e.kind].range):
		e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, target) <= int(content.units[e.kind].range))
		if e.path.is_empty():
			e.job = "idle"
		return
	if e.cooldown == 0:
		damages[e.target_id] = damages.get(e.target_id, 0) + int(content.units[e.kind].damage)
		e.cooldown = int(content.units[e.kind].cooldown_ticks)

func _ai_step() -> void:
	var worker_id := _find(COMPUTER, "worker")
	if worker_id != -1 and entities[worker_id].job == "idle" and sources[COMPUTER].amount > 0:
		issue(COMPUTER, "gather", worker_id, sources[COMPUTER].pos)
	var barracks_id := _find(COMPUTER, "barracks")
	if barracks_id == -1 and worker_id != -1 and stockpile[COMPUTER] >= _cost(COMPUTER, "barracks"):
		issue(COMPUTER, "build", worker_id, _point(content.map.barracks_positions[COMPUTER]))
		barracks_id = _find(COMPUTER, "barracks")
	if barracks_id != -1 and entities[barracks_id].complete and stockpile[COMPUTER] >= _cost(COMPUTER, ai_next_role) and _count_units(COMPUTER) + entities[barracks_id].queue.size() < int(content.ai.army_cap):
		if issue(COMPUTER, "train", barracks_id, ai_next_role).ok:
			ai_next_role = "ranged" if ai_next_role == "melee" else "melee"
	if tick_number < int(content.ai.district_tick):
		return
	var human_post := _find(HUMAN, "command_post")
	var human_district := -1
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		if entities.has(id) and entities[id].side == HUMAN and entities[id].hp > 0 and entities[id].kind in ["melee", "ranged"] and _in_district(entities[id].pos):
			human_district = id
			break
	for id in ids:
		if not entities.has(id) or entities[id].side != COMPUTER or entities[id].kind not in ["melee", "ranged"]:
			continue
		var unit: Dictionary = entities[id]
		if human_district != -1:
			if unit.job != "attack" or unit.target_id != human_district:
				issue(COMPUTER, "attack", id, human_district)
		elif unit.kind == "melee" and tick_number >= int(content.ai.attack_tick) and human_post != -1:
			if (not _in_district(unit.pos) or _other_computer_fighter_in_district(id)) and unit.job in ["idle", "move"]:
				issue(COMPUTER, "attack", id, human_post)
		elif unit.job == "idle" and not _in_district(unit.pos):
			issue(COMPUTER, "move", id, _point(content.map.ai_district_target))

func _other_computer_fighter_in_district(except_id: int) -> bool:
	for id in entities:
		if id != except_id and entities[id].side == COMPUTER and entities[id].hp > 0 and entities[id].kind in ["melee", "ranged"] and _in_district(entities[id].pos):
			return true
	return false

func _count_units(side: int) -> int:
	var count := 0
	for e in entities.values():
		if e.side == side and e.kind in ["worker", "melee", "ranged"]:
			count += 1
	return count

func _cost(side: int, kind: String) -> int:
	var base: int = int(content.units[kind].cost) if kind in content.units else int(content.buildings[kind].cost)
	return base + (int(content.factions[factions[side]].combat_cost_extra) if kind in ["melee", "ranged"] else 0)

func _carry_limit(side: int) -> int:
	return int(content.factions[factions[side]].carry_limit)

func _starting_health(side: int, kind: String) -> int:
	if kind in content.buildings:
		return int(content.buildings[kind].health) * int(content.factions[factions[side]].building_health_percent) / 100
	return int(content.units[kind].health)

func _finish(outcome: String, reason: String) -> void:
	if result != "":
		return
	result = outcome
	result_reason = reason
	terminal_tick = tick_number
	district_state = "terminal"
	feedback = ("La Roma held. Victory!" if outcome == "win" else "La Roma lost. Defeat.") if reason == "district" else "Victory!" if outcome == "win" else "Defeat." if outcome == "loss" else "Draw."

func _log_target(target: Variant) -> Variant:
	if target is Vector2i:
		return [target.x, target.y]
	return target

func _point(pair: Array) -> Vector2i:
	return Vector2i(int(pair[0]), int(pair[1]))

func _whole_number(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))

func _next_random() -> int:
	# A local, integer-only stream. No current skirmish rule draws from it.
	rng_state = int((int(rng_state) * 48271) % 2147483647)
	if rng_state == 0:
		rng_state = 1
	return rng_state

func _wall(tile: Vector2i) -> bool:
	return blocked_tiles.has(tile)

func _in_district(tile: Vector2i) -> bool:
	var low := _point(content.map.district_min)
	var high := _point(content.map.district_max)
	return tile.x >= low.x and tile.x <= high.x and tile.y >= low.y and tile.y <= high.y

func _walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_width or tile.y >= map_height or _wall(tile):
		return false
	if pending_footprint.x >= 0 and _contains(pending_footprint, tile):
		return false
	for source in sources.values():
		if tile == source.pos:
			return false
	if building_tiles.has(tile):
		return false
	return true

func _clear_footprint(at: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		if _in_district(tile) or not _walkable(tile) or _unit_at(tile) != -1:
			return false
	return true

func _contains(at: Vector2i, tile: Vector2i) -> bool:
	return tile.x >= at.x and tile.x < at.x + 2 and tile.y >= at.y and tile.y < at.y + 2

func _distance(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)

func _distance_to_footprint(tile: Vector2i, at: Vector2i) -> int:
	var nearest := 999
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		nearest = mini(nearest, _distance(tile, at + offset))
	return nearest

func _distance_to_entity(tile: Vector2i, e: Dictionary) -> int:
	return _distance_to_footprint(tile, e.pos) if e.kind in ["command_post", "barracks"] else _distance(tile, e.pos)

func _unit_at(tile: Vector2i) -> int:
	for id in entities:
		var e: Dictionary = entities[id]
		if e.hp > 0 and e.kind in ["worker", "melee", "ranged"] and e.pos == tile:
			return id
	return -1

func entity_at(tile: Vector2i) -> int:
	var unit_id := _unit_at(tile)
	if unit_id != -1:
		return unit_id
	for id in entities:
		var e: Dictionary = entities[id]
		if e.hp > 0 and e.kind in ["command_post", "barracks"] and _contains(e.pos, tile):
			return id
	return -1

func _perimeter(at: Vector2i) -> Array[Vector2i]:
	return [at + Vector2i.LEFT, at + Vector2i(-1, 1), at + Vector2i.UP,
		at + Vector2i(1, -1), at + Vector2i(2, 0), at + Vector2i(2, 1),
		at + Vector2i(0, 2), at + Vector2i(1, 2)]

func _route_until(from: Vector2i, condition: Callable) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if condition.call(from):
		return empty
	var queue: Array[Vector2i] = [from]
	var parent: Dictionary = {from: from}
	var index := 0
	while index < queue.size():
		var tile: Vector2i = queue[index]
		index += 1
		for step in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if _walkable(next) and not parent.has(next):
				parent[next] = tile
				if condition.call(next):
					var route: Array[Vector2i] = []
					var cursor := next
					while cursor != from:
						route.push_front(cursor)
						cursor = parent[cursor]
					return route
				queue.append(next)
	return empty
