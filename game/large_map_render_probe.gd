extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://large-map-render-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	client._choose_map(Skirmish.MAP_IDS.find("la_roma_large"))
	client._choose_faction(Skirmish.REGIOS)
	client.set_process(false)
	client.sim.ai_enabled = false
	for i in 8:
		client.queue_redraw()
		await process_frame
	var initial_path := OS.get_environment("LARGE_RENDER_INITIAL")
	if not initial_path.is_empty() and root.get_texture().get_image().save_png(initial_path) != OK:
		printerr("Initial large-map capture failed")
		quit(1)
		return
	var added := 0
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var per_side_added := 0
		for y in range(18, 78, 5):
			for x in range(10 if side == Skirmish.HUMAN else 54, 42 if side == Skirmish.HUMAN else 87, 5):
				var tile := Vector2i(x, y)
				if client.sim._walkable(tile) and client.sim._unit_at(tile) == -1:
					client.sim._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile)
					added += 1
					per_side_added += 1
					if per_side_added == 37:
						break
			if per_side_added == 37:
				break
	if client.sim.entities.size() != 80:
		printerr("Rendered roster incomplete: ", client.sim.entities.size())
		quit(1)
		return
	client.sim._refresh_visibility()
	var frame_us: Array[int] = []
	var peak_memory := 0.0
	var last := Time.get_ticks_usec()
	for frame in 600:
		if frame % 6 == 0:
			client.sim.tick()
			client._update_hud()
			client.queue_redraw()
		await process_frame
		var now := Time.get_ticks_usec()
		frame_us.append(now - last)
		last = now
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	var stress_path := OS.get_environment("LARGE_RENDER_STRESS")
	if not stress_path.is_empty() and root.get_texture().get_image().save_png(stress_path) != OK:
		printerr("Stress large-map capture failed")
		quit(1)
		return
	frame_us.sort()
	var p95 := float(frame_us[ceili(float(frame_us.size()) * 0.95) - 1]) / 1000.0
	var report := {"map": "96x96", "units": client.sim.entities.size(), "viewport": root.get_visible_rect().size,
		"frames": frame_us.size(), "frame_p95_ms": p95, "frame_budget_ms": 33.3,
		"peak_static_memory_mib": peak_memory, "memory_budget_mib": 768.0,
		"godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build()}
	print("LARGE_MAP_RENDER_JSON=" + JSON.stringify(report))
	quit(0 if p95 <= 33.3 and peak_memory <= 768.0 else 1)
