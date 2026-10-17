extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var capture_path := OS.get_environment("AOMX_FOUNDATION_CAPTURE")
	var mode := OS.get_environment("AOMX_FOUNDATION_MODE")
	if capture_path.is_empty() or mode not in ["save_resume", "crowd"]:
		printerr("AOMX_FOUNDATION_CAPTURE and AOMX_FOUNDATION_MODE=save_resume|crowd are required")
		quit(1)
		return
	var stamp := Time.get_ticks_usec()
	var client: Node = Scene.instantiate()
	client.save_path = "user://foundation-render-save-%d.json" % stamp
	client.outbox = Outbox.new("user://foundation-render-events-%d.json" % stamp)
	root.add_child(client)
	client._choose_faction(Skirmish.REGIOS)
	client.sim.ai_enabled = false
	if mode == "save_resume":
		client.sim.issue(Skirmish.HUMAN, "gather", client.sim._find(Skirmish.HUMAN, "worker"),
			client.sim.sources[Skirmish.HUMAN].pos)
		for n in 60:
			client.sim.tick()
		client._save_match()
		client._show_setup()
		client._resume_match()
		client._toggle_diagnostics()
	else:
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var added := 0
			for y in range(4, 16):
				for x in range(2, 18):
					if (x < 10) != (side == Skirmish.HUMAN):
						continue
					var tile := Vector2i(x, y)
					if client.sim._walkable(tile) and client.sim._unit_at(tile) == -1:
						client.sim._add_entity(side, "melee" if added % 2 == 0 else "ranged", tile)
						added += 1
					if added == 39:
						break
				if added == 39:
					break
		client.sim.tick()
	client._update_hud()
	client.queue_redraw()
	var intervals: Array[float] = []
	var memory_peak := 0.0
	var prior := Time.get_ticks_usec()
	for n in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		intervals.append(float(now - prior) / 1000.0)
		prior = now
		memory_peak = maxf(memory_peak, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	intervals.sort()
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	print("FOUNDATION_RENDER=%s units=%d p95_frame_interval_ms=%.2f process_ms=%.2f peak_static_mib=%.1f capture=%s error=%d" % [
		mode, client.sim.entities.size(), intervals[113], Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		memory_peak, capture_path, error])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(client.save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(client.outbox.filename))
	quit(0 if error == OK else 1)
