extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const TARGET_TICKS := 6000
const TARGET_UNITS := 80

func _initialize() -> void:
	var game = Skirmish.new()
	game.ai_enabled = false
	var fighters: Array[int] = []
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var center := Vector2i(9, 9) if side == Skirmish.HUMAN else Vector2i(11, 11)
		fighters.append(game._add_entity(side, "melee", center))
		var added := 1
		for y in range(2, game.map_height - 2):
			for x in range(2, game.map_width - 2):
				if (x < 14) != (side == Skirmish.HUMAN):
					continue
				var tile := Vector2i(x, y)
				if game._walkable(tile) and game._unit_at(tile) == -1:
					fighters.append(game._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile))
					added += 1
					if added == 38:
						break
			if added == 38:
				break
	if game.entities.size() != TARGET_UNITS:
		printerr("Performance roster incomplete: ", game.entities.size())
		quit(1)
		return
	# Four fighters hold a separate live duel while the other units stress routes.
	# Replenishment keeps combat, armor and traveling projectiles active for ten minutes.
	var duel_indices := [36, 37, 74, 75]
	var duel_positions := [Vector2i(18, 22), Vector2i(18, 24), Vector2i(22, 22), Vector2i(22, 24)]
	var duel_kinds := ["ranged", "siege", "armored", "siege"]
	for duel in range(duel_indices.size()):
		var entity: Dictionary = game.entities[fighters[duel_indices[duel]]]
		entity.kind = duel_kinds[duel]
		entity.hp = game._starting_health(entity.side, entity.kind)
		entity.pos = duel_positions[duel]
		entity.job = "hold"
	game._refresh_visibility()
	var route_us: Array[int] = []
	var tick_us: Array[int] = []
	var orders := 0
	var accepted := 0
	var peak_memory := 0.0
	var combat_deaths := 0
	var projectile_frames := 0
	for logical_tick in range(TARGET_TICKS):
		for duel in range(duel_indices.size()):
			var slot: int = duel_indices[duel]
			if not game.entities.has(fighters[slot]) and game._unit_at(duel_positions[duel]) == -1:
				var side: int = Skirmish.HUMAN if duel < 2 else Skirmish.COMPUTER
				fighters[slot] = game._add_entity(side, duel_kinds[duel], duel_positions[duel])
				game.entities[fighters[slot]].job = "hold"
				combat_deaths += 1
		if logical_tick % 100 == 0:
			for index in range(fighters.size()):
				if index in [0, 38] or index in duel_indices:
					continue
				var id: int = fighters[index]
				if not game.entities.has(id):
					continue
				var entity: Dictionary = game.entities[id]
				var destination := Vector2i(5, 20) if entity.side == Skirmish.HUMAN else Vector2i(22, 5)
				if logical_tick % 200 == 100:
					destination = Vector2i(5, 6) if entity.side == Skirmish.HUMAN else Vector2i(22, 20)
				var began := Time.get_ticks_usec()
				var response: Dictionary = game.issue(entity.side, "move", id, destination)
				route_us.append(Time.get_ticks_usec() - began)
				orders += 1
				if response.ok:
					accepted += 1
		var started := Time.get_ticks_usec()
		game.tick()
		tick_us.append(Time.get_ticks_usec() - started)
		projectile_frames += game.projectiles.size()
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
		if game.result != "":
			printerr("Performance scenario ended early at tick ", game.tick_number, ": ", game.result_reason)
			quit(1)
			return
	var route_p95 := _p95(route_us)
	var tick_p95 := _p95(tick_us)
	if combat_deaths < 4 or projectile_frames < 100:
		printerr("Performance battle did not sustain combat: deaths=", combat_deaths, " projectile frames=", projectile_frames)
		quit(1)
		return
	var report := {"map": "%dx%d" % [game.map_width, game.map_height], "initial_units": TARGET_UNITS, "final_entities": game.entities.size(), "orders": orders,
		"accepted_orders": accepted, "ticks": TARGET_TICKS, "simulated_seconds": TARGET_TICKS / 10,
		"combat_deaths_replenished": combat_deaths, "projectile_frames": projectile_frames,
		"route_p95_ms": route_p95, "tick_p95_ms": tick_p95, "peak_static_memory_mib": peak_memory,
		"route_budget_ms": 6.0, "tick_budget_ms": 4.0, "memory_budget_mib": 512.0,
		"godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build(),
		"hash": game.state_hash()}
	print("WARFARE_PERF_JSON=" + JSON.stringify(report))
	quit(0 if route_p95 <= 6.0 and tick_p95 <= 4.0 and peak_memory <= 512.0 else 1)

func _p95(values: Array[int]) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[ceili(float(sorted.size()) * 0.95) - 1]) / 1000.0
