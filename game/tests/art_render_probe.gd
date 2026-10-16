extends SceneTree

const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_probe")

func _probe() -> void:
	var scene: PackedScene = load("res://skirmish_main.tscn")
	var game: Node = scene.instantiate()
	root.add_child(game)
	game._start_match(Skirmish.REGIOS)
	var requested_zoom := OS.get_environment("AOMX_ART_ZOOM")
	if requested_zoom.is_valid_float():
		game.board_zoom = clampf(requested_zoom.to_float(), 1.0, 1.25)
	game.sim.ai_enabled = false
	for offset in range(5):
		game.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(3 + offset, 7))
		game.sim._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(12 + offset, 12))
	game.queue_redraw()
	await create_timer(0.5).timeout
	var intervals: Array[float] = []
	var peak_memory := 0.0
	var prior_usec := Time.get_ticks_usec()
	for i in range(180):
		await process_frame
		var now_usec := Time.get_ticks_usec()
		intervals.append(float(now_usec - prior_usec) / 1000.0)
		prior_usec = now_usec
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	intervals.sort()
	print("Art render probe: 20x20, 12 units, 180 displayed frames, zoom %.0f%%; frame-interval median %.2f ms, p95 %.2f ms (includes display wait); process monitor %.2f ms, peak static memory %.1f MiB" % [
		game.board_zoom * 100.0, intervals[90], intervals[171], Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0, peak_memory])
	quit()
