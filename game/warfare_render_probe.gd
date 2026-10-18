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
	client.sim.ai_enabled = false
	var zoom := OS.get_environment("WARFARE_PROBE_ZOOM")
	if zoom.is_valid_float():
		client.board_zoom = clampf(float(zoom), 1.0, 1.25)
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var added := 0
		for y in range(2, client.sim.map_height - 2):
			for x in range(2, client.sim.map_width - 2):
				if (x < 14) != (side == Skirmish.HUMAN):
					continue
				var tile := Vector2i(x, y)
				if client.sim._walkable(tile) and client.sim._unit_at(tile) == -1:
					client.sim._add_entity(side, ["melee", "ranged", "armored", "siege"][added % 4], tile)
					added += 1
					if added == 38:
						break
			if added == 38:
				break
	client.sim._refresh_visibility()
	client._update_hud()
	client.queue_redraw()
	for i in 8:
		await process_frame
	var intervals: Array[int] = []
	var peak_memory := 0.0
	var last := Time.get_ticks_usec()
	for i in range(180):
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
	var report := {"map": "%dx%d" % [client.sim.map_width, client.sim.map_height], "units": client.sim.entities.size(),
		"viewport": get_root().get_visible_rect().size, "zoom": client.board_zoom, "frames": intervals.size(),
		"frame_p95_ms": frame_p95, "frame_budget_ms": 33.3, "peak_static_memory_mib": peak_memory,
		"memory_budget_mib": 512.0, "godot": Engine.get_version_info().string, "os": OS.get_name(), "debug": OS.is_debug_build()}
	print("WARFARE_RENDER_JSON=" + JSON.stringify(report))
	quit(0 if frame_p95 <= 33.3 and peak_memory <= 512.0 else 1)
