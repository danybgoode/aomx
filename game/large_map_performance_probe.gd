extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const UNITS := 80
const FIGHTERS_PER_SIDE := 36

func _initialize() -> void:
	var size := 128 if OS.get_environment("LARGE_PERF_SIZE") == "128" else 96
	var content: Dictionary = RulesContent.load_map("la_roma_large").data.duplicate(true)
	content.map.width = size
	content.map.height = size
	var game = Skirmish.new(Skirmish.REGIOS, content, 41, "standard", "la_roma_large")
	game.ai_enabled = OS.get_environment("LARGE_PERF_AI") == "1"
	var fighters: Array[int] = []
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var added := 0
		for y in range(12, size - 12, 5):
			for x in range(12 if side == Skirmish.HUMAN else size / 2 + 7, size / 2 - 7 if side == Skirmish.HUMAN else size - 12, 5):
				var tile := Vector2i(x, y)
				if game._walkable(tile) and game._unit_at(tile) == -1:
					fighters.append(game._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile))
					added += 1
					if added == FIGHTERS_PER_SIDE:
						break
			if added == FIGHTERS_PER_SIDE:
				break
	if game.entities.size() != UNITS - 2:
		printerr("Large-map roster incomplete: ", game.entities.size())
		quit(1)
		return
	var duel_ids := [fighters[0], fighters[FIGHTERS_PER_SIDE]]
	game.entities[duel_ids[0]].pos = Vector2i(42, 44)
	game.entities[duel_ids[1]].pos = Vector2i(53, 44)
	if not game._walkable(game.entities[duel_ids[0]].pos) or not game._walkable(game.entities[duel_ids[1]].pos):
		printerr("Large-map duel tiles are not traversable")
		quit(1)
		return
	var total_ticks := 6000
	var requested := OS.get_environment("LARGE_PERF_TICKS")
	if requested.is_valid_int():
		total_ticks = maxi(100, int(requested))
	var route_us: Array[int] = []
	var tick_us: Array[int] = []
	var accepted := 0
	var mixed_orders := {"scout": 0, "gather": 0, "build": 0, "combat": 0}
	var max_live_entities: int = game.entities.size()
	var peak_memory := 0.0
	var slow_ticks: Array[Dictionary] = []
	var over_budget_ticks := 0
	var order_stride := 30 if OS.get_environment("LARGE_PERF_ORDER_STRIDE") == "30" else 6
	for logical_tick in total_ticks:
		if logical_tick == 0:
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				var started := Time.get_ticks_usec()
				var combat_order: Dictionary = game.issue(side, "attack_move", duel_ids[side], Vector2i(50, 44) if side == Skirmish.HUMAN else Vector2i(45, 44))
				route_us.append(Time.get_ticks_usec() - started)
				if combat_order.ok:
					mixed_orders.combat += 1
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				var scout_id := game._find(side, "bicitaxi")
				for scout_goal in ([Vector2i(30, 30), Vector2i(25, 25), Vector2i(20, 25)] if side == Skirmish.HUMAN else [Vector2i(65, 65), Vector2i(70, 70), Vector2i(75, 70)]):
					var started := Time.get_ticks_usec()
					var scout_order: Dictionary = game.issue(side, "move", scout_id, scout_goal)
					route_us.append(Time.get_ticks_usec() - started)
					if scout_order.ok:
						mixed_orders.scout += 1
						break
				var worker_id := game._find(side, "worker")
				var started := Time.get_ticks_usec()
				var gather_order: Dictionary = game.issue(side, "gather", worker_id, game.resource_sources[side].comida.pos)
				route_us.append(Time.get_ticks_usec() - started)
				if gather_order.ok:
					mixed_orders.gather += 1
		if logical_tick == 100:
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				for resource_id in Skirmish.RESOURCE_IDS:
					game._add_balance(side, resource_id, 500)
				var worker_id := game._find(side, "worker")
				var preferred: Vector2i = game._point(content.map.barracks_positions[side])
				for offset in [Vector2i.ZERO, Vector2i(0, 3), Vector2i(3, 0), Vector2i(-3, 0), Vector2i(0, -3), Vector2i(4, 4)]:
					var started := Time.get_ticks_usec()
					var build_order: Dictionary = game.issue(side, "build", worker_id, {"kind": "barracks", "pos": preferred + offset})
					route_us.append(Time.get_ticks_usec() - started)
					if build_order.ok:
						mixed_orders.build += 1
						break
		if logical_tick % 500 == 250:
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				var id := fighters[side * FIGHTERS_PER_SIDE]
				var target := Vector2i(44, 47) if side == Skirmish.HUMAN else Vector2i(size - 45, 47)
				if game.entities.has(id):
					var started := Time.get_ticks_usec()
					var combat_order: Dictionary = game.issue(side, "attack_move", id, target)
					route_us.append(Time.get_ticks_usec() - started)
					if combat_order.ok:
						mixed_orders.combat += 1
		if logical_tick % 100 == 0 and OS.get_environment("LARGE_PERF_NO_ORDERS") != "1":
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				for index in range(side * FIGHTERS_PER_SIDE + posmod(logical_tick / 100, 3), side * FIGHTERS_PER_SIDE + FIGHTERS_PER_SIDE, order_stride):
					var id := fighters[index]
					if id in duel_ids or not game.entities.has(id):
						continue
					var target := Vector2i(35, 65) if side == Skirmish.HUMAN else Vector2i(size - 36, 30)
					if logical_tick % 200 == 100:
						target = Vector2i(30, 30) if side == Skirmish.HUMAN else Vector2i(size - 31, size - 31)
					if not game._walkable(target):
						continue
					var started := Time.get_ticks_usec()
					var response: Dictionary = game.issue(side, "move", id, target)
					route_us.append(Time.get_ticks_usec() - started)
					if response.ok:
						accepted += 1
		var started := Time.get_ticks_usec()
		game.tick()
		var elapsed := Time.get_ticks_usec() - started
		tick_us.append(elapsed)
		if elapsed > 8000:
			over_budget_ticks += 1
			var blocked := 0
			for entity in game.entities.values():
				if entity.kind in game.content.units and entity.blocked_ticks > 0:
					blocked += 1
			slow_ticks.append({"tick": logical_tick, "ms": float(elapsed) / 1000.0, "blocked": blocked})
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		max_live_entities = maxi(max_live_entities, game.entities.size())
	var duel_casualties := int(not game.entities.has(duel_ids[0])) + int(not game.entities.has(duel_ids[1]))
	var report := {"map": "%dx%d" % [game.map_width, game.map_height], "live_entities": game.entities.size(),
		"ai_enabled": game.ai_enabled, "completed_ticks": game.tick_number, "result": game.result,
		"max_live_entities": max_live_entities, "mixed_orders": mixed_orders,
		"duel_casualties": duel_casualties,
		"ticks": total_ticks, "simulated_seconds": total_ticks / 10, "orders": route_us.size(), "accepted_orders": accepted,
		"route_p95_ms": _p95(route_us), "tick_p95_ms": _p95(tick_us), "peak_static_memory_mib": peak_memory,
		"route_budget_ms": 12.0, "tick_budget_ms": 8.0, "memory_budget_mib": 768.0,
		"over_budget_ticks": over_budget_ticks,
		"godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build()}
	slow_ticks.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.ms > b.ms)
	report["slow_ticks"] = slow_ticks.slice(0, mini(10, slow_ticks.size()))
	var budget_enforced := OS.get_environment("LARGE_PERF_ENFORCE") != "false"
	report["budget_enforced"] = budget_enforced
	print("LARGE_MAP_PERF_JSON=" + JSON.stringify(report))
	quit(0 if route_us.size() >= 10 and accepted > 0 and max_live_entities <= UNITS and mixed_orders.scout == 2 and mixed_orders.gather == 2 and mixed_orders.build == 2 and mixed_orders.combat > 0 and duel_casualties > 0 and game.tick_number == total_ticks and (not budget_enforced or (report.route_p95_ms <= 12.0 and report.tick_p95_ms <= 8.0 and peak_memory <= 768.0)) else 1)

func _p95(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[ceili(float(sorted.size()) * 0.95) - 1]) / 1000.0
