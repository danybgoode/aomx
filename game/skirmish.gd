extends RefCounted

const WIDTH := 20
const HEIGHT := 20
const HUMAN := 0
const COMPUTER := 1
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
const GAME_VERSION := "godot-4.7.2-skirmish-1"
const CONTENT_VERSION := "original-skirmish-map-1"

var entities: Dictionary = {}
var sources: Dictionary = {}
var stockpile: Dictionary = {HUMAN: 0, COMPUTER: 0}
var next_id := 1
var tick_number := 0
var result := ""
var terminal_tick := -1
var feedback := "Gather resource, build a recruitment post, then train an army."
var command_log: Array[Dictionary] = []
var next_command := 1
var ai_next_role := "melee"
var pending_footprint := Vector2i(-1, -1)

func _init() -> void:
	sources = {HUMAN: {"pos": RESOURCE_POS[HUMAN], "amount": 60},
		COMPUTER: {"pos": RESOURCE_POS[COMPUTER], "amount": 60}}
	_add_entity(HUMAN, "command_post", Vector2i(2, 2))
	_add_entity(COMPUTER, "command_post", Vector2i(16, 16))
	_add_entity(HUMAN, "worker", Vector2i(4, 2))
	_add_entity(COMPUTER, "worker", Vector2i(15, 17))

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
			elif stockpile[side] < COST.barracks:
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
					stockpile[side] -= COST.barracks
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
			elif (actor.kind == "command_post" and target != "worker") or (actor.kind == "barracks" and target not in ["melee", "ranged"]):
				rejected.reason = "role_unavailable"
			elif stockpile[side] < COST[target]:
				rejected.reason = "insufficient_stockpile"
			elif actor.queue.size() >= 3:
				rejected.reason = "queue_full"
			else:
				stockpile[side] -= COST[target]
				actor.queue.append({"role": target, "remaining": TRAIN_TICKS[target]})
				rejected = {"ok": true, "reason": "training_queued"}
		"attack":
			if actor.kind not in ["melee", "ranged"] or not target is int or not entities.has(target):
				rejected.reason = "combat_unit_and_target_required"
			elif entities[target].side == side or entities[target].hp <= 0:
				rejected.reason = "invalid_enemy_target"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, entities[target]) <= RANGE[actor.kind])
				if route.is_empty() and _distance_to_entity(actor.pos, entities[target]) > RANGE[actor.kind]:
					rejected.reason = "target_unreachable"
				else:
					actor.path = route
					actor.job = "attack"
					actor.target_id = target
					rejected = {"ok": true, "reason": "attacking"}
	if rejected.ok:
		command_log.append({"command_id": "command_%05d" % next_command,
			"sequence": next_command, "issued_tick": tick_number, "side": side, "kind": kind,
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
	if tick_number % 20 == 0:
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
	for target_id in damages.keys():
		if entities.has(target_id):
			entities[target_id].hp -= damages[target_id]
	for id in ids:
		if entities.has(id) and entities[id].hp <= 0 and entities[id].kind not in ["command_post"]:
			entities.erase(id)
	var human_post := _find(HUMAN, "command_post")
	var computer_post := _find(COMPUTER, "command_post")
	var human_dead: bool = human_post == -1 or entities[human_post].hp <= 0
	var computer_dead: bool = computer_post == -1 or entities[computer_post].hp <= 0
	if human_dead and computer_dead:
		_finish("draw")
	elif computer_dead:
		_finish("win")
	elif human_dead:
		_finish("loss")
	elif tick_number >= DRAW_TICK:
		_finish("draw")

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
		"stockpile": [stockpile[HUMAN], stockpile[COMPUTER]],
		"sources": [sources[HUMAN].amount, sources[COMPUTER].amount], "entities": list,
		"next_id": next_id, "next_command": next_command, "ai_next_role": ai_next_role}

func state_hash() -> String:
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(JSON.stringify(snapshot()).to_utf8_buffer())
	return hash.finish().hex_encode()

func _add_entity(side: int, kind: String, pos: Vector2i) -> int:
	var id := next_id
	next_id += 1
	entities[id] = {"id": id, "side": side, "kind": kind, "pos": pos, "hp": HEALTH[kind],
		"complete": true, "progress": 0, "carry": 0, "job": "idle", "path": [],
		"target_id": -1, "cooldown": 0, "queue": []}
	return id

func _find(side: int, kind: String) -> int:
	for id in entities:
		if entities[id].side == side and entities[id].kind == kind and entities[id].hp > 0:
			return id
	return -1

func _tick_gather(e: Dictionary) -> void:
	var source: Dictionary = sources[e.side]
	if _distance(e.pos, source.pos) != 1:
		e.job = "idle"
	elif source.amount > 0 and e.carry < CARRY_LIMIT:
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
	if building.progress >= BUILD_TICKS:
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
	if _distance_to_entity(e.pos, target) > RANGE[e.kind]:
		e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, target) <= RANGE[e.kind])
		if e.path.is_empty():
			e.job = "idle"
		return
	if e.cooldown == 0:
		damages[e.target_id] = damages.get(e.target_id, 0) + DAMAGE[e.kind]
		e.cooldown = COOLDOWN[e.kind]

func _ai_step() -> void:
	var worker_id := _find(COMPUTER, "worker")
	if worker_id != -1 and entities[worker_id].job == "idle" and sources[COMPUTER].amount > 0:
		issue(COMPUTER, "gather", worker_id, sources[COMPUTER].pos)
	var barracks_id := _find(COMPUTER, "barracks")
	if barracks_id == -1 and worker_id != -1 and stockpile[COMPUTER] >= COST.barracks:
		issue(COMPUTER, "build", worker_id, BARRACKS_POS[COMPUTER])
		barracks_id = _find(COMPUTER, "barracks")
	if barracks_id != -1 and entities[barracks_id].complete and stockpile[COMPUTER] >= COST[ai_next_role] and _count_units(COMPUTER) + entities[barracks_id].queue.size() < 3:
		if issue(COMPUTER, "train", barracks_id, ai_next_role).ok:
			ai_next_role = "ranged" if ai_next_role == "melee" else "melee"
	var human_post := _find(HUMAN, "command_post")
	if human_post != -1 and tick_number >= AI_ATTACK_TICK:
		var ids: Array = entities.keys()
		ids.sort()
		for id in ids:
			if entities.has(id) and entities[id].side == COMPUTER and entities[id].kind in ["melee", "ranged"] and entities[id].job == "idle":
				issue(COMPUTER, "attack", id, human_post)

func _count_units(side: int) -> int:
	var count := 0
	for e in entities.values():
		if e.side == side and e.kind in ["worker", "melee", "ranged"]:
			count += 1
	return count

func _finish(outcome: String) -> void:
	if result != "":
		return
	result = outcome
	terminal_tick = tick_number
	feedback = "Victory!" if outcome == "win" else "Defeat." if outcome == "loss" else "Draw."

func _log_target(target: Variant) -> Variant:
	if target is Vector2i:
		return [target.x, target.y]
	return target

func _wall(tile: Vector2i) -> bool:
	return (tile.x == 10 and tile.y != 10) or tile in [Vector2i(14, 15), Vector2i(16, 15), Vector2i(15, 14), Vector2i(15, 16)]

func _walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= WIDTH or tile.y >= HEIGHT or _wall(tile):
		return false
	if pending_footprint.x >= 0 and _contains(pending_footprint, tile):
		return false
	for source in sources.values():
		if tile == source.pos:
			return false
	for e in entities.values():
		if e.hp > 0 and e.kind in ["command_post", "barracks"] and _contains(e.pos, tile):
			return false
	return true

func _clear_footprint(at: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		if not _walkable(tile) or _unit_at(tile) != -1:
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
