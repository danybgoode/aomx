extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://warfare-render-probe-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	client._choose_faction(Skirmish.REGIOS)
	client.set_process(false)
	client.sim.ai_enabled = false
	var zoom := OS.get_environment("WARFARE_PROBE_ZOOM")
	if zoom.is_valid_float():
		client.board_zoom = clampf(float(zoom), 1.0, 1.25)
	var roster := {Skirmish.HUMAN: [], Skirmish.COMPUTER: []}
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var added := 0
		for y in range(2, client.sim.map_height - 2):
			for x in range(2, client.sim.map_width - 2):
				if (x < 14) != (side == Skirmish.HUMAN):
					continue
				var tile := Vector2i(x, y)
				if client.sim._walkable(tile) and client.sim._unit_at(tile) == -1:
					roster[side].append(client.sim._add_entity(side, ["melee", "ranged", "armored", "siege"][added % 4], tile))
					added += 1
					if added == 38:
						break
			if added == 38:
				break
	var duel_ids := [roster[Skirmish.HUMAN][36], roster[Skirmish.HUMAN][37], roster[Skirmish.COMPUTER][36], roster[Skirmish.COMPUTER][37]]
	var duel_positions := [Vector2i(11, 9), Vector2i(11, 11), Vector2i(14, 9), Vector2i(14, 11)]
	var duel_kinds := ["ranged", "siege", "armored", "siege"]
	for duel in range(duel_ids.size()):
		var entity: Dictionary = client.sim.entities[duel_ids[duel]]
		entity.kind = duel_kinds[duel]
		entity.hp = client.sim._starting_health(entity.side, entity.kind)
		entity.pos = duel_positions[duel]
		entity.job = "hold"
	client.sim._refresh_visibility()
	client._update_hud()
	client.queue_redraw()
	for i in 8:
		await process_frame
	var intervals: Array[int] = []
	var peak_memory := 0.0
	var projectile_frames := 0
	var combat_deaths := 0
	var last := Time.get_ticks_usec()
	for i in range(600):
		if i % 6 == 0:
			for duel in range(duel_ids.size()):
				if not client.sim.entities.has(duel_ids[duel]) and client.sim._unit_at(duel_positions[duel]) == -1:
					var side: int = Skirmish.HUMAN if duel < 2 else Skirmish.COMPUTER
					duel_ids[duel] = client.sim._add_entity(side, duel_kinds[duel], duel_positions[duel])
					client.sim.entities[duel_ids[duel]].job = "hold"
					combat_deaths += 1
			client.sim.tick()
			client._observe_events()
			client._update_unit_facing()
			client._update_hud()
			client.queue_redraw()
		projectile_frames += client.sim.projectiles.size()
		await process_frame
		var current := Time.get_ticks_usec()
		intervals.append(current - last)
		last = current
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	intervals.sort()
	var frame_p95 := float(intervals[ceili(float(intervals.size()) * 0.95) - 1]) / 1000.0
	var capture := OS.get_environment("WARFARE_CAPTURE_PATH")
	if not capture.is_empty():
		var error := root.get_texture().get_image().save_png(capture)
		if error != OK:
			printerr("Warfare capture failed: ", error)
			quit(1)
			return
	if projectile_frames == 0 or combat_deaths == 0:
		printerr("Rendered battle did not exercise live projectiles and casualties")
		quit(1)
		return
	var report := {"map": "%dx%d" % [client.sim.map_width, client.sim.map_height], "units": client.sim.entities.size(),
		"viewport": get_root().get_visible_rect().size, "zoom": client.board_zoom, "frames": intervals.size(), "ticks": client.sim.tick_number,
		"projectile_frames": projectile_frames, "combat_deaths_replenished": combat_deaths,
		"frame_p95_ms": frame_p95, "frame_budget_ms": 33.3, "peak_static_memory_mib": peak_memory,
		"memory_budget_mib": 512.0, "godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build()}
	print("WARFARE_RENDER_JSON=" + JSON.stringify(report))
	quit(0 if frame_p95 <= 33.3 and peak_memory <= 512.0 else 1)
