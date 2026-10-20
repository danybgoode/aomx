extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")

const CASES := [
	{"name": "baseline", "edge": 20, "fighters": 10, "orders": 300, "ticks": 300,
		"route_p95_budget_ms": 2.0, "tick_p95_budget_ms": 2.0},
	{"name": "crowded", "edge": 32, "fighters": 78, "orders": 500, "ticks": 300,
		"route_p95_budget_ms": 6.0, "tick_p95_budget_ms": 4.0},
	{"name": "large_army", "edge": 48, "fighters": 158, "orders": 800, "ticks": 300,
		"route_p95_budget_ms": 12.0, "tick_p95_budget_ms": 8.0}
]

# Current La Roma rules allow 24 population per side. Each side starts with one worker,
# so 46 fighters plus the four starting entities exercise that playable ceiling.
const LIVE_CAPACITY_CASES := [
	{"name": "la_roma_population_cap", "edge": 28, "fighters": 46, "orders": 500, "ticks": 300,
		"route_p95_budget_ms": 12.0, "tick_p95_budget_ms": 8.0}
]

func _initialize() -> void:
	var loaded: Dictionary = RulesContent.load_default()
	if not loaded.ok:
		printerr("Benchmark content unavailable: ", loaded.reason)
		quit(1)
		return
	var profile := OS.get_environment("AOMX_BENCH_PROFILE")
	var cases: Array = CASES
	if profile.begins_with("live_capacity"):
		cases = LIVE_CAPACITY_CASES
	elif profile == "large_army_paced":
		cases = [CASES[2]]
	var pace_ms := 100 if profile.ends_with("_paced") else 0
	for settings in cases:
		var definitions: Dictionary = loaded.data.duplicate(true)
		definitions.map.width = settings.edge
		definitions.map.height = settings.edge
		var game = Skirmish.new(Skirmish.REGIOS, definitions)
		var ids: Array[int] = []
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var desired: int = settings.fighters / 2
			var added := 0
			for y in range(2, settings.edge - 2):
				for x in range(2, settings.edge - 2):
					if (x < settings.edge / 2) != (side == Skirmish.HUMAN):
						continue
					var tile := Vector2i(x, y)
					if game._walkable(tile) and game._unit_at(tile) == -1:
						ids.append(game._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile))
						added += 1
					if added >= desired:
						break
				if added >= desired:
					break
		var route_us: Array[int] = []
		var accepted := 0
		for n in settings.orders:
			var id: int = ids[n % ids.size()]
			var entity: Dictionary = game.entities[id]
			var far := Vector2i(settings.edge - 6, settings.edge - 6)
			var near := Vector2i(4, 8)
			var target: Vector2i = far if entity.side == Skirmish.HUMAN else near
			var began: int = Time.get_ticks_usec()
			var response: Dictionary = game.issue(entity.side, "move", id, target)
			route_us.append(Time.get_ticks_usec() - began)
			if response.ok:
				accepted += 1
		var tick_us: Array[int] = []
		for n in settings.ticks:
			var began: int = Time.get_ticks_usec()
			game.tick()
			tick_us.append(Time.get_ticks_usec() - began)
			if pace_ms > 0:
				OS.delay_msec(maxi(0, pace_ms - int((Time.get_ticks_usec() - began) / 1000)))
		var route_p95 := _percentile(route_us, 0.95)
		var tick_p95 := _percentile(tick_us, 0.95)
		var report := {"scenario": settings.name, "map": "%dx%d" % [settings.edge, settings.edge],
			"units": game.entities.size(), "orders": settings.orders, "accepted_orders": accepted,
			"ticks": settings.ticks, "pace_ms": pace_ms,
			"route_mean_ms": _mean(route_us), "route_p95_ms": route_p95,
			"tick_mean_ms": _mean(tick_us), "tick_p95_ms": tick_p95,
			"route_p95_budget_ms": settings.route_p95_budget_ms,
			"tick_p95_budget_ms": settings.tick_p95_budget_ms,
			"route_budget_met": route_p95 <= settings.route_p95_budget_ms,
			"tick_budget_met": tick_p95 <= settings.tick_p95_budget_ms,
			"static_memory_bytes": int(Performance.get_monitor(Performance.MEMORY_STATIC)),
			"godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build(),
			"state_hash": game.state_hash()}
		print("BENCHMARK_JSON=" + JSON.stringify(report))
	quit(0)

func _percentile(values: Array[int], rate: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(ceili(float(sorted.size()) * rate) - 1, 0, sorted.size() - 1)]) / 1000.0

func _mean(values: Array[int]) -> float:
	var total := 0
	for value in values:
		total += value
	return float(total) / float(values.size()) / 1000.0
