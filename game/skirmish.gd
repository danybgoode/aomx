extends RefCounted

const RulesContent = preload("res://rules_content.gd")

const WIDTH := 28
const HEIGHT := 28
const HUMAN := 0
const COMPUTER := 1
const REGIOS := "regios"
const POBLANOS := "poblanos"
const RESOURCE_IDS := ["comida", "materiales", "varos", "terrenos"]
const BUILDING_KINDS := ["command_post", "barracks", "depot", "housing", "registry"]
const COMBAT_KINDS := ["melee", "ranged", "armored", "siege"]
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
const AI_ATTACK_TICK := 2600
const AI_DISTRICT_TICK := 2400
const DISTRICT_MIN := Vector2i(8, 8)
const DISTRICT_MAX := Vector2i(11, 11)
const HOLD_TICKS := 750
const GAME_VERSION := "godot-4.7.2-skirmish-4"
const CONTENT_VERSION := "la-roma-opponent-4"
const COMMAND_SCHEMA_VERSION := 3
const STATE_SCHEMA_VERSION := 4
const AI_LEVELS := ["learner", "standard", "challenger"]

var factions: Dictionary = {HUMAN: REGIOS, COMPUTER: POBLANOS}
var content: Dictionary = {}
var content_hash := ""
var map_width := WIDTH
var map_height := HEIGHT
var blocked_tiles: Dictionary = {}
var cliff_tiles: Dictionary = {}
var elevated_tiles: Dictionary = {}
var visible_tiles: Dictionary = {HUMAN: {}, COMPUTER: {}}
var explored_tiles: Dictionary = {HUMAN: {}, COMPUTER: {}}
var last_seen: Dictionary = {HUMAN: {}, COMPUTER: {}}
var sight_cache: Dictionary = {}
var building_tiles: Dictionary = {}
var projectiles: Array[Dictionary] = []
var rng_state := 1
var initial_seed := 1
var hash_checkpoints: Array[Dictionary] = []
var entities: Dictionary = {}
var sources: Dictionary = {}
var stockpile: Dictionary = {HUMAN: 0, COMPUTER: 0}
var resource_sources: Dictionary = {}
var source_tiles: Dictionary = {}
var other_stockpiles: Dictionary = {}
var age_index: Dictionary = {HUMAN: 0, COMPUTER: 0}
var researched: Dictionary = {HUMAN: [], COMPUTER: []}
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
var ai_difficulty := "standard"
var ai_opening := 0
var ai_plan := "opening"
var ai_stall_reason := ""
var ai_rejections := 0
var ai_last_rejection := ""
var pending_footprint := Vector2i(-1, -1)

func _init(human_faction: String = REGIOS, custom_content: Dictionary = {}, seed: int = 1, difficulty: String = "standard") -> void:
	assert(human_faction in [REGIOS, POBLANOS], "Choose a supported faction.")
	assert(difficulty in AI_LEVELS, "Choose a supported opponent level.")
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
	for point in content.map.cliff_tiles:
		cliff_tiles[Vector2i(int(point[0]), int(point[1]))] = true
	for point in content.map.elevated_tiles:
		elevated_tiles[Vector2i(int(point[0]), int(point[1]))] = true
	rng_state = seed if seed != 0 else 1
	initial_seed = rng_state
	ai_difficulty = difficulty
	ai_opening = posmod(initial_seed, 2)
	factions = {HUMAN: human_faction, COMPUTER: POBLANOS if human_faction == REGIOS else REGIOS}
	for side in [HUMAN, COMPUTER]:
		resource_sources[side] = {}
		other_stockpiles[side] = {"comida": 0, "materiales": 0, "terrenos": 0}
		for resource_id in RESOURCE_IDS:
			var rule: Dictionary = content.resources[resource_id]
			var source_pos := _point(rule.source_positions[side])
			source_tiles[source_pos] = true
			resource_sources[side][resource_id] = {"pos": source_pos,
				"amount": int(rule.amount), "refresh_remaining": 0, "refreshes_left": int(rule.refresh_count)}
		sources[side] = resource_sources[side].varos
	for side in [HUMAN, COMPUTER]:
		_add_entity(side, "command_post", _point(content.map.command_posts[side]))
		_add_entity(side, "worker", _point(content.map.workers[side]))
	_refresh_visibility()

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
	if command.kind in ["move", "gather", "attack_move"]:
		if not target is Array or target.size() != 2 or not _whole_number(target[0]) or not _whole_number(target[1]):
			return {"ok": false, "reason": "command_target_invalid"}
		target = Vector2i(int(target[0]), int(target[1]))
	elif command.kind == "build":
		if target is Array and target.size() == 2 and _whole_number(target[0]) and _whole_number(target[1]):
			target = Vector2i(int(target[0]), int(target[1]))
		elif target is Dictionary and target.get("kind") is String and target.get("pos") is Array and target.pos.size() == 2 and _whole_number(target.pos[0]) and _whole_number(target.pos[1]):
			target = {"kind": target.kind, "pos": Vector2i(int(target.pos[0]), int(target.pos[1]))}
		else:
			return {"ok": false, "reason": "command_target_invalid"}
	elif command.kind in ["attack", "assist", "repair", "cancel"]:
		if not _whole_number(target):
			return {"ok": false, "reason": "command_target_invalid"}
		target = int(target)
	elif command.kind in ["train", "research", "advance", "stop", "hold"]:
		if not target is String:
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
		"stop", "hold":
			if actor.kind in content.buildings:
				rejected.reason = "mobile_unit_required"
			else:
				actor.path.clear()
				actor.job = "hold" if kind == "hold" else "idle"
				actor.target_id = -1
				rejected = {"ok": true, "reason": "holding" if kind == "hold" else "stopped"}
		"attack_move":
			if actor.kind not in COMBAT_KINDS or not target is Vector2i or not _walkable(target):
				rejected.reason = "combat_unit_and_tile_required"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return tile == target)
				if route.is_empty() and actor.pos != target:
					rejected.reason = "unreachable_tile"
				else:
					actor.path = route
					actor.job = "attack_move"
					actor.order_pos = target
					rejected = {"ok": true, "reason": "advancing"}
		"move":
			if actor.kind in content.buildings or not target is Vector2i or not _walkable(target):
				rejected.reason = "blocked_or_invalid_tile"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return tile == target)
				if route.is_empty() and actor.pos != target:
					rejected.reason = "unreachable_tile"
				else:
					actor.path = route
					actor.job = "move" if not route.is_empty() else "idle"
					actor.order_pos = target
					rejected = {"ok": true, "reason": "moving"}
		"gather":
			var resource_id := _resource_at(side, target) if target is Vector2i else ""
			if actor.kind != "worker" or resource_id.is_empty():
				rejected.reason = "resource_unavailable"
			else:
				var source: Dictionary = resource_sources[side][resource_id]
				if source.amount <= 0:
					rejected.reason = "resource_depleted"
				elif actor.carry > 0 and actor.carry_resource != resource_id:
					rejected.reason = "deliver_current_cargo_first"
				else:
					var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance(tile, target) == 1)
					if route.is_empty() and _distance(actor.pos, target) != 1:
						rejected.reason = "resource_unreachable"
					else:
						actor.path = route
						actor.source_resource = resource_id
						actor.job = "gather"
						rejected = {"ok": true, "reason": "gathering"}
		"build":
			var building_kind := "barracks"
			var at := Vector2i(-1, -1)
			if target is Vector2i:
				at = target
			elif target is Dictionary and target.get("kind") is String and target.get("pos") is Vector2i:
				building_kind = target.kind
				at = target.pos
			if actor.kind != "worker":
				rejected.reason = "worker_required"
			elif building_kind not in content.buildings or building_kind == "command_post":
				rejected.reason = "building_unavailable"
			elif not _age_allows(side, content.buildings[building_kind].min_age):
				rejected.reason = "age_required"
			elif not _can_pay(side, _costs(side, building_kind)):
				rejected.reason = "insufficient_stockpile"
			elif not _clear_footprint(at):
				rejected.reason = "blocked_footprint"
			else:
				pending_footprint = at
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_footprint(tile, at) == 1)
				var workers_can_exit := _build_preserves_worker_routes(side)
				pending_footprint = Vector2i(-1, -1)
				if not workers_can_exit:
					rejected.reason = "blocked_worker_route"
				elif route.is_empty() and _distance_to_footprint(actor.pos, at) != 1:
					rejected.reason = "building_unreachable"
				else:
					_pay(side, _costs(side, building_kind))
					var building_id := _add_entity(side, building_kind, at)
					entities[building_id].complete = false
					entities[building_id].progress = 0
					actor.path = route
					actor.job = "build"
					actor.target_id = building_id
					rejected = {"ok": true, "reason": "construction_started"}
		"assist":
			if actor.kind != "worker" or not target is int or not entities.has(target) or entities[target].side != side or entities[target].kind not in content.buildings or entities[target].complete:
				rejected.reason = "incomplete_friendly_building_required"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, entities[target]) == 1)
				if route.is_empty() and _distance_to_entity(actor.pos, entities[target]) != 1:
					rejected.reason = "building_unreachable"
				else:
					actor.path = route
					actor.job = "build"
					actor.target_id = target
					rejected = {"ok": true, "reason": "assisting_construction"}
		"repair":
			if actor.kind != "worker" or not target is int or not entities.has(target) or entities[target].side != side or entities[target].kind not in content.buildings or not entities[target].complete:
				rejected.reason = "complete_friendly_building_required"
			elif entities[target].hp >= _starting_health(side, entities[target].kind):
				rejected.reason = "building_undamaged"
			elif balance(side, "materiales") < 1:
				rejected.reason = "need_materiales"
			else:
				var route := _route_until(actor.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, entities[target]) == 1)
				if route.is_empty() and _distance_to_entity(actor.pos, entities[target]) != 1:
					rejected.reason = "building_unreachable"
				else:
					actor.path = route
					actor.job = "repair"
					actor.target_id = target
					rejected = {"ok": true, "reason": "repairing"}
		"train":
			if actor.kind not in content.buildings or not target is String or target not in content.units:
				rejected.reason = "production_building_required"
			elif not actor.complete:
				rejected.reason = "building_incomplete"
			elif target not in content.buildings[actor.kind].trains:
				rejected.reason = "role_unavailable"
			elif not _age_allows(side, content.units[target].min_age):
				rejected.reason = "age_required"
			elif _population_used(side) >= _population_cap(side):
				rejected.reason = "population_cap"
			elif not _can_pay(side, _costs(side, target)):
				rejected.reason = "insufficient_stockpile"
			elif actor.queue.size() >= 3:
				rejected.reason = "queue_full"
			else:
				_pay(side, _costs(side, target))
				actor.queue.append({"kind": "unit", "role": target, "remaining": int(content.units[target].train_ticks)})
				rejected = {"ok": true, "reason": "training_queued"}
		"research":
			if actor.kind != "registry" or not actor.complete or not target is String or target not in content.techs:
				rejected.reason = "registry_and_tech_required"
			elif target in researched[side] or _queued(side, "tech", target):
				rejected.reason = "already_researched_or_queued"
			elif not _age_allows(side, content.techs[target].age):
				rejected.reason = "age_required"
			elif not _has_techs(side, content.techs[target].requires_techs):
				rejected.reason = "tech_prerequisite_missing"
			elif not _can_pay(side, content.techs[target].costs):
				rejected.reason = "insufficient_stockpile"
			elif actor.queue.size() >= 3:
				rejected.reason = "queue_full"
			else:
				_pay(side, content.techs[target].costs)
				actor.queue.append({"kind": "tech", "role": target, "remaining": int(content.techs[target].duration_ticks)})
				rejected = {"ok": true, "reason": "research_queued"}
		"advance":
			var next_age := ""
			if age_index[side] < content.ages.order.size() - 1:
				next_age = content.ages.order[age_index[side] + 1]
			if actor.kind != "command_post" or not actor.complete or target != next_age or next_age.is_empty():
				rejected.reason = "next_age_required"
			else:
				var transition: Dictionary = content.ages.transitions[next_age]
				if not _has_buildings(side, transition.requires_buildings):
					rejected.reason = "building_prerequisite_missing"
				elif not _has_techs(side, transition.requires_techs):
					rejected.reason = "tech_prerequisite_missing"
				elif _queued(side, "age", next_age):
					rejected.reason = "age_already_queued"
				elif not _can_pay(side, transition.costs):
					rejected.reason = "insufficient_stockpile"
				elif actor.queue.size() >= 3:
					rejected.reason = "queue_full"
				else:
					_pay(side, transition.costs)
					actor.queue.append({"kind": "age", "role": next_age, "remaining": int(transition.duration_ticks)})
					rejected = {"ok": true, "reason": "age_queued"}
		"cancel":
			if actor.kind in content.buildings and actor.complete and target is int and target >= 0 and target < actor.queue.size():
				var order: Dictionary = actor.queue[target]
				_refund(side, _order_costs(side, order), 50 if target == 0 else 100)
				actor.queue.remove_at(target)
				rejected = {"ok": true, "reason": "queue_canceled"}
			elif actor.kind == "worker" and target is int and entities.has(target) and entities[target].side == side and entities[target].kind in content.buildings and not entities[target].complete:
				var canceled: Dictionary = entities[target]
				_refund(side, _costs(side, canceled.kind), 50)
				_release_building(canceled.pos)
				entities.erase(target)
				for worker in entities.values():
					if worker.kind == "worker" and worker.target_id == target:
						worker.job = "idle"
						worker.target_id = -1
				rejected = {"ok": true, "reason": "construction_canceled"}
			else:
				rejected.reason = "nothing_to_cancel"
		"attack":
			if actor.kind not in COMBAT_KINDS or not target is int or not entities.has(target):
				rejected.reason = "combat_unit_and_target_required"
			elif entities[target].side == side or entities[target].hp <= 0:
				rejected.reason = "invalid_enemy_target"
			elif not is_entity_visible(side, entities[target]):
				rejected.reason = "target_not_visible"
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
	elif side == COMPUTER:
		ai_rejections += 1
		ai_last_rejection = rejected.reason
	if side == HUMAN:
		feedback = rejected.reason.replace("_", " ")
	return rejected

func tick() -> void:
	if result != "":
		return
	tick_number += 1
	_tick_sources()
	if ai_enabled and tick_number % int(_ai_profile().step_ticks) == 0:
		_refresh_visibility()
		_ai_step()
	var damages: Dictionary = {}
	var moved_ids: Dictionary = {}
	for projectile in projectiles:
		if int(projectile.arrival) <= tick_number and entities.has(int(projectile.target_id)) and entities[projectile.target_id].hp > 0 and entities[projectile.target_id].pos == projectile.tile:
			damages[projectile.target_id] = int(damages.get(projectile.target_id, 0)) + int(projectile.damage)
	projectiles = projectiles.filter(func(p: Dictionary) -> bool: return int(p.arrival) > tick_number)
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		if not entities.has(id):
			continue
		var entity: Dictionary = entities[id]
		if entity.hp <= 0:
			continue
		if entity.kind in content.buildings:
			_tick_production(entity)
			continue
		if entity.cooldown > 0:
			entity.cooldown -= 1
		if entity.job == "attack" and (not entities.has(entity.target_id) or entities[entity.target_id].hp <= 0 or not is_entity_visible(entity.side, entities[entity.target_id])):
			entity.job = "idle"
			entity.path.clear()
			entity.target_id = -1
			if entity.side == HUMAN:
				feedback = "Target lost from sight. Scout before attacking again."
		if entity.job in ["attack_move", "hold"] and _tick_auto_attack(entity, damages):
			continue
		if not entity.path.is_empty():
			if tick_number % 3 == 0:
				if moved_ids.has(id):
					continue
				var occupied_by := _unit_at(entity.path[0])
				if occupied_by != -1 and occupied_by != id and entities[occupied_by].side == entity.side and not moved_ids.has(occupied_by) and not entities[occupied_by].path.is_empty() and entities[occupied_by].path[0] == entity.pos:
					var old_pos: Vector2i = entity.pos
					entity.pos = entity.path.pop_front()
					entities[occupied_by].pos = old_pos
					entities[occupied_by].path.pop_front()
					entity.blocked_ticks = 0
					entities[occupied_by].blocked_ticks = 0
					moved_ids[id] = true
					moved_ids[occupied_by] = true
				elif _walkable(entity.path[0]) and occupied_by == -1:
					entity.pos = entity.path.pop_front()
					entity.blocked_ticks = 0
				elif _walkable(entity.path[0]):
					entity.blocked_ticks += 3
					if entity.blocked_ticks == 30:
						_reroute_occupied(entity)
					elif entity.blocked_ticks >= 90:
						entity.path.clear()
						entity.job = "idle"
						if entity.side == HUMAN:
							feedback = "No free route. Choose another destination."
				else:
					_reroute_blocked(entity)
			continue
		if entity.kind == "worker" and entity.job == "idle" and entity.carry > 0:
			_begin_delivery(entity)
		match entity.job:
			"gather": _tick_gather(entity)
			"deliver": _tick_deliver(entity)
			"build": _tick_build(entity)
			"repair": _tick_repair(entity)
			"attack": _tick_attack(entity, damages)
			"attack_move", "hold": _tick_auto_attack(entity, damages)
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
	_refresh_visibility()
	if tick_number % 50 == 0 or result != "":
		hash_checkpoints.append({"tick": tick_number, "hash": state_hash()})

func _reroute_blocked(entity: Dictionary) -> void:
	entity.path.clear()
	match entity.job:
		"gather":
			if entity.source_resource in RESOURCE_IDS:
				var source: Dictionary = resource_sources[entity.side][entity.source_resource]
				if source.amount > 0:
					entity.path = _route_until(entity.pos, func(tile: Vector2i) -> bool: return _distance(tile, source.pos) == 1)
					if not entity.path.is_empty() or _distance(entity.pos, source.pos) == 1:
						return
		"deliver":
			_begin_delivery(entity)
			return
		"build", "repair":
			if entities.has(entity.target_id):
				var building: Dictionary = entities[entity.target_id]
				entity.path = _route_until(entity.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, building) == 1)
				if not entity.path.is_empty() or _distance_to_entity(entity.pos, building) == 1:
					return
		"attack":
			if entities.has(entity.target_id):
				var target: Dictionary = entities[entity.target_id]
				var reach := int(content.units[entity.kind].range)
				entity.path = _route_until(entity.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, target) <= reach)
				if not entity.path.is_empty() or _distance_to_entity(entity.pos, target) <= reach:
					return
	entity.job = "idle"
	if entity.side == HUMAN:
		feedback = "No route to the ordered destination."

func _reroute_occupied(entity: Dictionary) -> void:
	# Crowds are transient obstacles. Static paths remain valid when a neighbor
	# steps away (or swaps); abort explicitly after a bounded wait below.
	if entity.side == HUMAN:
		feedback = "Crowded route; unit waiting for a free tile."

func _tick_district() -> void:
	var present := {HUMAN: false, COMPUTER: false}
	for e in entities.values():
		if e.hp > 0 and e.kind in COMBAT_KINDS and _in_district(e.pos):
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
			"carry_resource": e.carry_resource, "source_resource": e.source_resource,
			"job": e.job, "target_id": e.target_id, "cooldown": e.cooldown,
			"blocked_ticks": e.blocked_ticks, "order_pos": [e.order_pos.x, e.order_pos.y],
			"path": e.path.map(func(p: Vector2i) -> Array: return [p.x, p.y]), "queue": e.queue.duplicate(true)})
	var balances: Array = []
	var source_states: Array = []
	for side in [HUMAN, COMPUTER]:
		var side_balances := {}
		var side_sources := {}
		for resource_id in RESOURCE_IDS:
			side_balances[resource_id] = balance(side, resource_id)
			var source: Dictionary = resource_sources[side][resource_id]
			side_sources[resource_id] = {"amount": source.amount,
				"refresh_remaining": source.refresh_remaining, "refreshes_left": source.refreshes_left}
		balances.append(side_balances)
		source_states.append(side_sources)
	return {"tick": tick_number, "result": result, "terminal_tick": terminal_tick,
		"result_reason": result_reason, "district_side": district_side,
		"district_progress": district_progress, "district_state": district_state,
		"state_schema_version": STATE_SCHEMA_VERSION, "content_version": content.content_id,
		"content_hash": content_hash, "rng_state": rng_state, "initial_seed": initial_seed,
		"factions": [factions[HUMAN], factions[COMPUTER]],
		"balances": balances, "resource_sources": source_states,
		"age_index": [age_index[HUMAN], age_index[COMPUTER]],
		"researched": [researched[HUMAN].duplicate(), researched[COMPUTER].duplicate()],
		"entities": list, "projectiles": projectiles.map(func(p: Dictionary) -> Dictionary: return {"target_id": p.target_id, "tile": [p.tile.x, p.tile.y], "origin": [p.origin.x, p.origin.y], "damage": p.damage, "launch": p.launch, "arrival": p.arrival}),
		"explored": [_sorted_points(explored_tiles[HUMAN]), _sorted_points(explored_tiles[COMPUTER])],
		"last_seen": [_sorted_sight_memory(HUMAN), _sorted_sight_memory(COMPUTER)],
		"next_id": next_id, "next_command": next_command, "ai_next_role": ai_next_role,
		"ai_enabled": ai_enabled, "ai_difficulty": ai_difficulty, "ai_opening": ai_opening,
		"ai_plan": ai_plan, "ai_stall_reason": ai_stall_reason,
		"ai_rejections": ai_rejections, "ai_last_rejection": ai_last_rejection}

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
		"complete": true, "progress": 0, "carry": 0, "carry_resource": "", "source_resource": "",
		"job": "idle", "path": [],
		"target_id": -1, "cooldown": 0, "queue": [], "blocked_ticks": 0, "order_pos": pos}
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

func _tick_sources() -> void:
	for side in [HUMAN, COMPUTER]:
		for resource_id in RESOURCE_IDS:
			var source: Dictionary = resource_sources[side][resource_id]
			if source.amount > 0 or source.refreshes_left <= 0:
				continue
			if source.refresh_remaining <= 0:
				source.refresh_remaining = int(content.resources[resource_id].refresh_ticks)
			source.refresh_remaining -= 1
			if source.refresh_remaining <= 0:
				source.amount = int(content.resources[resource_id].refresh_amount)
				source.refreshes_left -= 1

func _resource_at(side: int, tile: Vector2i) -> String:
	for resource_id in RESOURCE_IDS:
		if resource_sources[side][resource_id].pos == tile:
			return resource_id
	return ""

func _dropoff_for(side: int, resource_id: String, from: Vector2i) -> Dictionary:
	var best_id := -1
	var best_route: Array[Vector2i] = []
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		var building: Dictionary = entities[id]
		if building.side != side or building.hp <= 0 or not building.complete:
			continue
		var valid: bool = building.kind in ["command_post", "registry"] if resource_id == "terrenos" else building.kind in ["command_post", "depot"]
		if not valid:
			continue
		var route := _route_until(from, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, building) == 1)
		if route.is_empty() and _distance_to_entity(from, building) != 1:
			continue
		if best_id == -1 or route.size() < best_route.size():
			best_id = id
			best_route = route
	return {"id": best_id, "route": best_route}

func _begin_delivery(e: Dictionary) -> void:
	if e.carry <= 0 or e.carry_resource not in RESOURCE_IDS:
		e.job = "idle"
		return
	var destination := _dropoff_for(e.side, e.carry_resource, e.pos)
	if destination.id == -1:
		e.job = "idle"
		e.path = []
		return
	e.target_id = int(destination.id)
	e.path = destination.route
	e.job = "deliver"

func _tick_gather(e: Dictionary) -> void:
	var resource_id: String = e.source_resource
	if resource_id not in RESOURCE_IDS:
		e.job = "idle"
		return
	var source: Dictionary = resource_sources[e.side][resource_id]
	if _distance(e.pos, source.pos) != 1:
		e.job = "idle"
	elif source.amount > 0 and e.carry < _carry_limit(e.side):
		if tick_number % 3 == 0:
			source.amount -= 1
			e.carry += 1
			e.carry_resource = resource_id
	elif e.carry > 0:
		_begin_delivery(e)
	else:
		e.job = "idle"

func _tick_deliver(e: Dictionary) -> void:
	var destination := _dropoff_for(e.side, e.carry_resource, e.pos)
	if destination.id == -1:
		e.job = "idle"
		e.path = []
		return
	if _distance_to_entity(e.pos, entities[destination.id]) != 1:
		e.path = destination.route
		e.target_id = int(destination.id)
		return
	_add_balance(e.side, e.carry_resource, e.carry)
	e.carry = 0
	e.carry_resource = ""
	e.target_id = -1
	if e.source_resource in RESOURCE_IDS and resource_sources[e.side][e.source_resource].amount > 0:
		var source: Dictionary = resource_sources[e.side][e.source_resource]
		e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance(tile, source.pos) == 1)
		e.job = "gather" if not e.path.is_empty() or _distance(e.pos, source.pos) == 1 else "idle"
	else:
		e.job = "idle"

func _tick_build(e: Dictionary) -> void:
	if not entities.has(e.target_id):
		e.job = "idle"
		return
	var building: Dictionary = entities[e.target_id]
	if building.complete:
		e.job = "idle"
		return
	if _distance_to_entity(e.pos, building) != 1:
		e.job = "idle"
		return
	building.progress += _construction_rate(e.side)
	if building.progress >= int(content.buildings[building.kind].build_ticks):
		building.complete = true
		building.progress = int(content.buildings[building.kind].build_ticks)
		e.job = "idle"
		if e.side == HUMAN:
			feedback = "%s complete." % building.kind.replace("_", " ").capitalize()

func _tick_repair(e: Dictionary) -> void:
	if not entities.has(e.target_id):
		e.job = "idle"
		return
	var building: Dictionary = entities[e.target_id]
	if building.hp <= 0 or not building.complete or _distance_to_entity(e.pos, building) != 1:
		e.job = "idle"
		return
	var maximum := _starting_health(e.side, building.kind)
	if building.hp >= maximum or balance(e.side, "materiales") <= 0:
		e.job = "idle"
		return
	if tick_number % 5 == 0:
		_add_balance(e.side, "materiales", -1)
		building.hp = mini(maximum, building.hp + 2 * _construction_rate(e.side))

func _tick_production(e: Dictionary) -> void:
	if not e.complete or e.queue.is_empty():
		return
	var order: Dictionary = e.queue[0]
	if order.remaining > 0:
		order.remaining -= 1
		return
	match order.kind:
		"unit":
			if _population_alive(e.side) >= _population_cap(e.side):
				return
			for tile in _perimeter(e.pos):
				if _walkable(tile) and _unit_at(tile) == -1:
					_add_entity(e.side, order.role, tile)
					e.queue.pop_front()
					return
		"tech":
			if order.role not in researched[e.side]:
				researched[e.side].append(order.role)
				researched[e.side].sort()
			e.queue.pop_front()
		"age":
			if age_index[e.side] + 1 < content.ages.order.size() and content.ages.order[age_index[e.side] + 1] == order.role:
				age_index[e.side] += 1
			e.queue.pop_front()

func _tick_attack(e: Dictionary, damages: Dictionary) -> void:
	if not entities.has(e.target_id) or entities[e.target_id].hp <= 0:
		e.job = "idle"
		return
	var target: Dictionary = entities[e.target_id]
	if not is_entity_visible(e.side, target):
		e.job = "idle"
		e.path.clear()
		if e.side == HUMAN:
			feedback = "Target lost from sight. Scout before attacking again."
		return
	if _distance_to_entity(e.pos, target) > int(content.units[e.kind].range):
		e.path = _route_until(e.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, target) <= int(content.units[e.kind].range))
		if e.path.is_empty():
			e.job = "idle"
		return
	if e.cooldown == 0:
		var damage := _attack_damage(e, target)
		var travel := int(content.units[e.kind].projectile_ticks)
		if travel > 0:
			projectiles.append({"target_id": e.target_id, "tile": target.pos, "origin": e.pos, "damage": damage, "launch": tick_number, "arrival": tick_number + travel})
		else:
			damages[e.target_id] = int(damages.get(e.target_id, 0)) + damage
		e.cooldown = int(content.units[e.kind].cooldown_ticks)

func _tick_auto_attack(e: Dictionary, damages: Dictionary) -> bool:
	if e.kind not in COMBAT_KINDS:
		return false
	var target_id := -1
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		var target: Dictionary = entities[id]
		if target.side != e.side and target.hp > 0 and is_entity_visible(e.side, target) and _distance_to_entity(e.pos, target) <= int(content.units[e.kind].range):
			target_id = id
			break
	if target_id == -1:
		return false
	var old_job: String = e.job
	var old_target: int = e.target_id
	e.target_id = target_id
	_tick_attack(e, damages)
	e.target_id = old_target
	e.job = old_job
	return true

func _attack_damage(attacker: Dictionary, target: Dictionary) -> int:
	var rule: Dictionary = content.units[attacker.kind]
	var armor := int(content.buildings[target.kind].armor) if target.kind in content.buildings else int(content.units[target.kind].armor)
	var bonus_key := "structure" if target.kind in content.buildings else str(target.kind)
	return maxi(1, _unit_damage(attacker.side, attacker.kind) + int(rule.bonuses.get(bonus_key, 0)) - armor)

func _ai_profile() -> Dictionary:
	return content.ai.levels[ai_difficulty]

func _ai_observed_enemies() -> Array[Dictionary]:
	var observed: Array[Dictionary] = []
	for id in _visible_enemy_ids(COMPUTER):
		var e: Dictionary = entities[id]
		observed.append({"id": id, "kind": e.kind, "pos": e.pos, "hp": e.hp})
	return observed

func _ai_counter_role(observed: Array[Dictionary]) -> String:
	if not _ai_profile().counter:
		return ""
	for enemy in observed:
		match enemy.kind:
			"siege": return "melee"
			"armored": return "ranged"
			"ranged":
				if age_index[COMPUTER] >= 1:
					return "armored"
			"melee": return "ranged"
	return ""

func _ai_goal(observed: Array[Dictionary] = []) -> Dictionary:
	var side := COMPUTER
	var profile := _ai_profile()
	var workers := 0
	for entity in entities.values():
		if entity.side == side and entity.hp > 0 and entity.kind == "worker":
			workers += 1
	if workers + _count_queued_role(side, "worker") < int(profile.workers):
		return {"kind": "train", "id": "worker", "costs": _costs(side, "worker")}
	var opening_buildings := ["housing", "depot", "barracks"] if ai_opening == 1 else ["depot", "housing", "barracks"]
	for building_kind in opening_buildings:
		var building_id := _find(side, building_kind)
		if building_id == -1:
			return {"kind": "build", "id": building_kind, "costs": _costs(side, building_kind)}
		if not entities[building_id].complete:
			return {"kind": "wait", "id": building_id, "costs": {}}
	var barracks_id := _find(side, "barracks")
	if barracks_id != -1 and entities[barracks_id].complete and _count_fighters(side) + _queued_fighters(side) < 2:
		if _population_used(side) >= _population_cap(side) and _population_cap(side) < int(content.population.max_cap):
			return {"kind": "build", "id": "housing", "costs": _costs(side, "housing")}
		var role := _ai_counter_role(observed)
		if role.is_empty():
			role = ai_next_role
		return {"kind": "train", "id": role, "costs": _costs(side, role)}
	if age_index[side] == 0 and not _queued(side, "age", "universitaria"):
		return {"kind": "advance", "id": "universitaria", "costs": content.ages.transitions.universitaria.costs}
	if age_index[side] >= 1:
		var registry_id := _find(side, "registry")
		if registry_id == -1:
			return {"kind": "build", "id": "registry", "costs": _costs(side, "registry")}
		if not entities[registry_id].complete:
			return {"kind": "wait", "id": registry_id, "costs": {}}
	if age_index[side] >= 1 and "carry_capacity_i" not in researched[side] and not _queued(side, "tech", "carry_capacity_i"):
		return {"kind": "research", "id": "carry_capacity_i", "costs": content.techs.carry_capacity_i.costs}
	if age_index[side] == 1 and "carry_capacity_i" not in researched[side]:
		return {"kind": "hold", "id": "carry_capacity_i", "costs": {}}
	if age_index[side] == 1 and not _queued(side, "age", "godin"):
		return {"kind": "advance", "id": "godin", "costs": content.ages.transitions.godin.costs}
	if age_index[side] >= 2 and "construction_rate_i" not in researched[side] and not _queued(side, "tech", "construction_rate_i"):
		return {"kind": "research", "id": "construction_rate_i", "costs": content.techs.construction_rate_i.costs}
	if age_index[side] == 2 and "construction_rate_i" not in researched[side]:
		return {"kind": "hold", "id": "construction_rate_i", "costs": {}}
	if age_index[side] == 2 and not _queued(side, "age", "gentrificacion"):
		return {"kind": "advance", "id": "gentrificacion", "costs": content.ages.transitions.gentrificacion.costs}
	if age_index[side] >= 3 and "combat_training_i" not in researched[side] and not _queued(side, "tech", "combat_training_i"):
		return {"kind": "research", "id": "combat_training_i", "costs": content.techs.combat_training_i.costs}
	if barracks_id != -1 and entities[barracks_id].complete and _count_fighters(side) + _queued_fighters(side) < int(profile.army_cap):
		if _population_used(side) >= _population_cap(side) and _population_cap(side) < int(content.population.max_cap):
			return {"kind": "build", "id": "housing", "costs": _costs(side, "housing")}
		var role := _ai_counter_role(observed)
		if role.is_empty():
			role = "siege" if age_index[side] >= 2 and _find(side, "siege") == -1 and _count_queued_role(side, "siege") == 0 else "armored" if age_index[side] >= 1 and _find(side, "armored") == -1 and _count_queued_role(side, "armored") == 0 else ai_next_role
		return {"kind": "train", "id": role, "costs": _costs(side, role)}
	return {}

func _count_fighters(side: int) -> int:
	var count := 0
	for entity in entities.values():
		if entity.side == side and entity.hp > 0 and entity.kind in COMBAT_KINDS:
			count += 1
	return count

func _queued_fighters(side: int) -> int:
	var count := 0
	for role in COMBAT_KINDS:
		count += _count_queued_role(side, role)
	return count

func _count_queued_role(side: int, role: String) -> int:
	var count := 0
	for entity in entities.values():
		if entity.side == side and entity.kind in content.buildings:
			for order in entity.queue:
				if order.kind == "unit" and order.role == role:
					count += 1
	return count

func _ai_shortage(costs: Dictionary) -> String:
	var resource_id := "varos"
	var shortage := -1
	for id in RESOURCE_IDS:
		var missing: int = maxi(0, int(costs.get(id, 0)) - balance(COMPUTER, id))
		if missing > shortage:
			shortage = missing
			resource_id = id
	return resource_id

func _ai_build(kind: String) -> bool:
	var worker_ids: Array = []
	for id in entities:
		if entities[id].side == COMPUTER and entities[id].kind == "worker" and entities[id].hp > 0 and entities[id].job not in ["build", "repair"]:
			worker_ids.append(id)
	if worker_ids.is_empty():
		return false
	var preferred := _point(content.map.barracks_positions[COMPUTER])
	if kind == "barracks":
		for worker_id in worker_ids:
			if issue(COMPUTER, "build", worker_id, {"kind": kind, "pos": preferred}).ok:
				return true
	var post: Dictionary = entities[_find(COMPUTER, "command_post")]
	for radius in range(1, 15):
		for y in range(1, map_height - 1):
			for x in range(1, map_width - 1):
				var at := Vector2i(x, y)
				if _distance(at, post.pos) != radius or not _clear_footprint(at):
					continue
				for worker_id in worker_ids:
					if issue(COMPUTER, "build", worker_id, {"kind": kind, "pos": at}).ok:
						return true
	return false

func _ai_issue_waypoint(actor_id: int, preferred: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN,
		Vector2i(-2, 0), Vector2i(0, -2), Vector2i(2, 0), Vector2i(0, 2)]:
		var at: Vector2i = preferred + offset
		if _walkable(at) and issue(COMPUTER, "attack_move", actor_id, at).ok:
			return true
	return false

func _ai_step() -> void:
	var side := COMPUTER
	var profile := _ai_profile()
	var observed := _ai_observed_enemies()
	var goal := _ai_goal(observed)
	ai_stall_reason = ""
	ai_plan = str(goal.get("kind", "hold"))
	if not goal.is_empty() and _can_pay(side, goal.costs):
		var actor_id := -1
		match goal.kind:
			"build":
				if not _ai_build(goal.id):
					ai_stall_reason = "building_site_unreachable"
			"wait":
				for id in entities:
					var worker: Dictionary = entities[id]
					if worker.side == side and worker.kind == "worker" and worker.hp > 0 and worker.carry == 0 and worker.job in ["idle", "gather"]:
						issue(side, "assist", id, goal.id)
			"train":
				actor_id = _find(side, "command_post" if goal.id == "worker" else "barracks")
				if actor_id != -1 and issue(side, "train", actor_id, goal.id).ok and goal.id in COMBAT_KINDS:
					ai_next_role = "ranged" if goal.id == "melee" else "melee"
			"research":
				actor_id = _find(side, "registry")
				if actor_id != -1:
					issue(side, "research", actor_id, goal.id)
			"advance":
				actor_id = _find(side, "command_post")
				if actor_id != -1:
					issue(side, "advance", actor_id, goal.id)
	goal = _ai_goal(observed)
	var resource_id: String = _ai_shortage(goal.costs) if not goal.is_empty() else str(RESOURCE_IDS[int(tick_number / int(profile.step_ticks)) % RESOURCE_IDS.size()])
	if resource_sources[side][resource_id].amount <= 0:
		for alternate in RESOURCE_IDS:
			if resource_sources[side][alternate].amount > 0:
				resource_id = alternate
				break
		if resource_sources[side][resource_id].amount <= 0:
			var can_refresh := false
			for candidate in RESOURCE_IDS:
				if resource_sources[side][candidate].refreshes_left > 0:
					can_refresh = true
			ai_stall_reason = "waiting_for_resource_refresh" if can_refresh else "all_sources_exhausted"
	var ids: Array = entities.keys()
	ids.sort()
	var assigned_to_needed := false
	for id in ids:
		if entities[id].side == side and entities[id].kind == "worker" and entities[id].hp > 0 and entities[id].source_resource == resource_id and entities[id].job in ["gather", "deliver"]:
			assigned_to_needed = true
			break
	var reassigned := false
	for id in ids:
		if not entities.has(id):
			continue
		var worker: Dictionary = entities[id]
		if worker.side != side or worker.kind != "worker" or worker.hp <= 0:
			continue
		if worker.carry > 0:
			continue
		var may_reassign: bool = worker.job == "gather" and worker.source_resource != resource_id and not assigned_to_needed and not reassigned and tick_number % 80 == 0
		if worker.job == "idle" or may_reassign:
			var source: Dictionary = resource_sources[side][resource_id]
			if source.amount > 0:
				if issue(side, "gather", id, source.pos).ok:
					assigned_to_needed = true
					reassigned = true
	var fighters := _count_fighters(side)
	if fighters > 0 and age_index[side] >= 1 and tick_number >= int(profile.scout_tick) and tick_number < int(profile.district_tick):
		for id in ids:
			if entities.has(id) and entities[id].side == side and entities[id].kind in COMBAT_KINDS and entities[id].job == "idle":
				if _ai_issue_waypoint(id, Vector2i(12, 12)):
					ai_plan = "scout"
				break
	var human_post := -1
	var human_district := -1
	for enemy in observed:
		if enemy.kind == "command_post":
			human_post = enemy.id
		if enemy.kind in COMBAT_KINDS and _in_district(enemy.pos):
			human_district = enemy.id
	var own_post := _find(side, "command_post")
	var nearby_threat := -1
	if own_post != -1:
		for enemy in observed:
			if enemy.kind in COMBAT_KINDS and _distance(enemy.pos, entities[own_post].pos) <= 6:
				nearby_threat = enemy.id
				break
	if tick_number < int(profile.district_tick) or age_index[side] < 3:
		var early_target := human_district if human_district != -1 else nearby_threat
		if early_target != -1:
			for id in ids:
				if entities.has(id) and entities[id].side == side and entities[id].kind in COMBAT_KINDS and (entities[id].job != "attack" or entities[id].target_id != early_target):
					if issue(side, "attack", id, early_target).ok:
						ai_plan = "defend"
		return
	for id in ids:
		if not entities.has(id) or entities[id].side != side or entities[id].kind not in COMBAT_KINDS:
			continue
		var unit: Dictionary = entities[id]
		var defense_target := human_district if human_district != -1 else nearby_threat
		if defense_target != -1:
			if unit.job != "attack" or unit.target_id != defense_target:
				if issue(side, "attack", id, defense_target).ok:
					ai_plan = "defend"
		elif tick_number >= int(profile.attack_tick) and (not _in_district(unit.pos) or _other_computer_fighter_in_district(id)):
			if human_post != -1:
				if unit.job != "attack" or unit.target_id != human_post:
					if issue(side, "attack", id, human_post).ok:
						ai_plan = "conquest"
			elif unit.job in ["idle", "move"]:
				var search_pos := _point(content.map.command_posts[HUMAN])
				for memory in last_seen[side].values():
					if memory.kind == "command_post" and tick_number - int(memory.tick) <= int(profile.memory_ticks):
						search_pos = memory.pos
				var approach := search_pos + Vector2i(2, 2)
				if _ai_issue_waypoint(id, approach):
					ai_plan = "search"
		elif unit.job == "idle" and not _in_district(unit.pos):
			if issue(side, "move", id, _point(content.map.ai_district_target)).ok:
				ai_plan = "district"

func _other_computer_fighter_in_district(except_id: int) -> bool:
	for id in entities:
		if id != except_id and entities[id].side == COMPUTER and entities[id].hp > 0 and entities[id].kind in COMBAT_KINDS and _in_district(entities[id].pos):
			return true
	return false

func _count_units(side: int) -> int:
	var count := 0
	for e in entities.values():
		if e.side == side and e.kind in content.units:
			count += 1
	return count

func balance(side: int, resource_id: String) -> int:
	if resource_id == "varos":
		return int(stockpile[side])
	return int(other_stockpiles[side].get(resource_id, 0))

func _add_balance(side: int, resource_id: String, amount: int) -> void:
	if resource_id == "varos":
		stockpile[side] = int(stockpile[side]) + amount
	else:
		other_stockpiles[side][resource_id] = balance(side, resource_id) + amount

func _costs(side: int, kind: String) -> Dictionary:
	var rule: Dictionary = content.units[kind] if kind in content.units else content.buildings[kind]
	var costs: Dictionary = rule.costs.duplicate(true)
	if kind in COMBAT_KINDS:
		costs.varos = int(costs.varos) + int(content.factions[factions[side]].combat_cost_extra)
	return costs

func _can_pay(side: int, costs: Dictionary) -> bool:
	for resource_id in RESOURCE_IDS:
		if balance(side, resource_id) < int(costs.get(resource_id, 0)):
			return false
	return true

func _pay(side: int, costs: Dictionary) -> void:
	assert(_can_pay(side, costs))
	for resource_id in RESOURCE_IDS:
		_add_balance(side, resource_id, -int(costs.get(resource_id, 0)))

func _refund(side: int, costs: Dictionary, percent: int) -> void:
	for resource_id in RESOURCE_IDS:
		_add_balance(side, resource_id, int(costs.get(resource_id, 0)) * percent / 100)

func _order_costs(side: int, order: Dictionary) -> Dictionary:
	match order.kind:
		"unit": return _costs(side, order.role)
		"tech": return content.techs[order.role].costs
		"age": return content.ages.transitions[order.role].costs
	return {}

func _age_allows(side: int, age_id: String) -> bool:
	var needed: int = content.ages.order.find(age_id)
	return needed >= 0 and age_index[side] >= needed

func _has_buildings(side: int, building_ids: Array) -> bool:
	for kind in building_ids:
		var found := false
		for entity in entities.values():
			if entity.side == side and entity.kind == kind and entity.hp > 0 and entity.complete:
				found = true
				break
		if not found:
			return false
	return true

func _has_techs(side: int, tech_ids: Array) -> bool:
	for tech_id in tech_ids:
		if tech_id not in researched[side]:
			return false
	return true

func _queued(side: int, kind: String, role: String) -> bool:
	for entity in entities.values():
		if entity.side == side and entity.kind in content.buildings:
			for order in entity.queue:
				if order.kind == kind and order.role == role:
					return true
	return false

func _population_alive(side: int) -> int:
	var count := 0
	for entity in entities.values():
		if entity.side == side and entity.hp > 0 and entity.kind in content.units:
			count += 1
	return count

func _population_used(side: int) -> int:
	var count := _population_alive(side)
	for entity in entities.values():
		if entity.side == side and entity.kind in content.buildings:
			for order in entity.queue:
				if order.kind == "unit":
					count += 1
	return count

func _population_cap(side: int) -> int:
	var cap: int = int(content.population.base_cap)
	for entity in entities.values():
		if entity.side == side and entity.kind == "housing" and entity.hp > 0 and entity.complete:
			cap += int(content.population.housing_bonus)
	return mini(cap, int(content.population.max_cap))

func _construction_rate(side: int) -> int:
	return 1 + (int(content.techs.construction_rate_i.effect.amount) if "construction_rate_i" in researched[side] else 0)

func _unit_damage(side: int, kind: String) -> int:
	return int(content.units[kind].damage) + (int(content.techs.combat_training_i.effect.amount) if "combat_training_i" in researched[side] else 0)

func _cost(side: int, kind: String) -> int:
	return int(_costs(side, kind).varos)

func _carry_limit(side: int) -> int:
	return int(content.factions[factions[side]].carry_limit) + (int(content.techs.carry_capacity_i.effect.amount) if "carry_capacity_i" in researched[side] else 0)

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
	if target is Dictionary and target.get("pos") is Vector2i:
		return {"kind": target.kind, "pos": [target.pos.x, target.pos.y]}
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
	return blocked_tiles.has(tile) or cliff_tiles.has(tile)

func is_visible(side: int, tile: Vector2i) -> bool:
	return visible_tiles[side].has(tile)

func is_entity_visible(side: int, entity: Dictionary) -> bool:
	if entity.kind in content.buildings:
		for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
			if is_visible(side, entity.pos + offset):
				return true
		return false
	return is_visible(side, entity.pos)

func is_explored(side: int, tile: Vector2i) -> bool:
	return explored_tiles[side].has(tile)

func _refresh_visibility() -> void:
	visible_tiles = {HUMAN: {}, COMPUTER: {}}
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		var observer: Dictionary = entities[id]
		if observer.hp <= 0:
			continue
		var side: int = observer.side
		var radius := 7 if elevated_tiles.has(observer.pos) else 5
		if observer.kind in content.buildings:
			radius = 6
		for tile in _sight_for(observer.pos, radius):
			visible_tiles[side][tile] = true
			explored_tiles[side][tile] = true
	for side in [HUMAN, COMPUTER]:
		for id in ids:
			var e: Dictionary = entities[id]
			if e.side != side and e.hp > 0 and is_entity_visible(side, e):
				last_seen[side][id] = {"pos": e.pos, "kind": e.kind, "tick": tick_number}

func _visible_enemy_ids(side: int) -> Array:
	var observed: Array = []
	var ids: Array = entities.keys()
	ids.sort()
	for id in ids:
		var e: Dictionary = entities[id]
		if e.side != side and e.hp > 0 and is_entity_visible(side, e):
			observed.append(id)
	return observed

func _sight_for(origin: Vector2i, radius: int) -> Array[Vector2i]:
	var key := Vector3i(origin.x, origin.y, radius)
	if sight_cache.has(key):
		return sight_cache[key]
	var points: Array[Vector2i] = []
	for y in range(maxi(0, origin.y - radius), mini(map_height, origin.y + radius + 1)):
		for x in range(maxi(0, origin.x - radius), mini(map_width, origin.x + radius + 1)):
			var tile := Vector2i(x, y)
			if _distance(origin, tile) <= radius and _line_visible(origin, tile):
				points.append(tile)
	sight_cache[key] = points
	return points

func _line_visible(from: Vector2i, to: Vector2i) -> bool:
	var steps := maxi(absi(to.x - from.x), absi(to.y - from.y))
	if steps == 0:
		return true
	for index in range(1, steps):
		var fraction := float(index) / float(steps)
		var tile := Vector2i(roundi(lerpf(from.x, to.x, fraction)), roundi(lerpf(from.y, to.y, fraction)))
		if _wall(tile) or (elevated_tiles.has(tile) and not elevated_tiles.has(from)):
			return false
	return true

func _sorted_points(points: Dictionary) -> Array:
	var keys: Array = points.keys()
	keys.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y if a.y != b.y else a.x < b.x)
	return keys.map(func(p: Vector2i) -> Array: return [p.x, p.y])

func _sorted_sight_memory(side: int) -> Array:
	var ids: Array = last_seen[side].keys()
	ids.sort()
	return ids.map(func(id: int) -> Dictionary:
		var memory: Dictionary = last_seen[side][id]
		return {"id": id, "pos": [memory.pos.x, memory.pos.y], "kind": memory.kind, "tick": memory.tick})

func _in_district(tile: Vector2i) -> bool:
	var low := _point(content.map.district_min)
	var high := _point(content.map.district_max)
	return tile.x >= low.x and tile.x <= high.x and tile.y >= low.y and tile.y <= high.y

func _walkable(tile: Vector2i) -> bool:
	if tile.x < 0 or tile.y < 0 or tile.x >= map_width or tile.y >= map_height or _wall(tile):
		return false
	if pending_footprint.x >= 0 and _contains(pending_footprint, tile):
		return false
	if source_tiles.has(tile):
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

func _build_preserves_worker_routes(side: int) -> bool:
	var post_id := _find(side, "command_post")
	if post_id == -1:
		return false
	var post: Dictionary = entities[post_id]
	for worker in entities.values():
		if worker.side != side or worker.kind != "worker" or worker.hp <= 0:
			continue
		if _distance_to_entity(worker.pos, post) == 1:
			continue
		var route := _route_until(worker.pos, func(tile: Vector2i) -> bool: return _distance_to_entity(tile, post) == 1)
		if route.is_empty():
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
	return _distance_to_footprint(tile, e.pos) if e.kind in content.buildings else _distance(tile, e.pos)

func _unit_at(tile: Vector2i) -> int:
	for id in entities:
		var e: Dictionary = entities[id]
		if e.hp > 0 and e.kind in content.units and e.pos == tile:
			return id
	return -1

func entity_at(tile: Vector2i) -> int:
	var unit_id := _unit_at(tile)
	if unit_id != -1:
		return unit_id
	for id in entities:
		var e: Dictionary = entities[id]
		if e.hp > 0 and e.kind in content.buildings and _contains(e.pos, tile):
			return id
	return -1

func _perimeter(at: Vector2i) -> Array[Vector2i]:
	return [at + Vector2i.LEFT, at + Vector2i(-1, 1), at + Vector2i.UP,
		at + Vector2i(1, -1), at + Vector2i(2, 0), at + Vector2i(2, 1),
		at + Vector2i(0, 2), at + Vector2i(1, 2)]

func _route_until(from: Vector2i, condition: Callable, avoid_occupied: bool = false) -> Array[Vector2i]:
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
			if _walkable(next) and (not avoid_occupied or _unit_at(next) == -1) and not parent.has(next):
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
