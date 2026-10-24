extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const UNITS := 80

func _initialize() -> void:
	var size := 128 if OS.get_environment("LARGE_PERF_SIZE") == "128" else 96
	var content: Dictionary = RulesContent.load_map("la_roma_large").data.duplicate(true)
	content.map.width = size
	content.map.height = size
	var game = Skirmish.new(Skirmish.REGIOS, content, 41, "standard", "la_roma_large")
	game.ai_enabled = false
	var fighters: Array[int] = []
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var added := 0
		for y in range(12, size - 12, 5):
			for x in range(12 if side == Skirmish.HUMAN else size / 2 + 7, size / 2 - 7 if side == Skirmish.HUMAN else size - 12, 5):
				var tile := Vector2i(x, y)
				if game._walkable(tile) and game._unit_at(tile) == -1:
					fighters.append(game._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile))
					added += 1
					if added == 37:
						break
			if added == 37:
				break
	if game.entities.size() != UNITS:
		printerr("Large-map roster incomplete: ", game.entities.size())
		quit(1)
		return
	var total_ticks := 6000
	var requested := OS.get_environment("LARGE_PERF_TICKS")
	if requested.is_valid_int():
		total_ticks = maxi(100, int(requested))
	var route_us: Array[int] = []
	var tick_us: Array[int] = []
	var accepted := 0
	var peak_memory := 0.0
	var slow_ticks: Array[Dictionary] = []
	var over_budget_ticks := 0
	var order_stride := 30 if OS.get_environment("LARGE_PERF_ORDER_STRIDE") == "30" else 6
	for logical_tick in total_ticks:
		if logical_tick % 100 == 0 and OS.get_environment("LARGE_PERF_NO_ORDERS") != "1":
			for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
				for index in range(side * 37 + posmod(logical_tick / 100, 3), side * 37 + 37, order_stride):
					var id := fighters[index]
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
	var report := {"map": "%dx%d" % [game.map_width, game.map_height], "live_entities": game.entities.size(),
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
	quit(0 if route_us.size() >= 10 and accepted > 0 and (not budget_enforced or (report.route_p95_ms <= 12.0 and report.tick_p95_ms <= 8.0 and peak_memory <= 768.0)) else 1)

func _p95(values: Array[int]) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[ceili(float(sorted.size()) * 0.95) - 1]) / 1000.0
