extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var capture_path := OS.get_environment("AOMX_CDMX_CAPTURE")
	var mode := OS.get_environment("AOMX_CDMX_MODE")
	if capture_path.is_empty() or mode not in ["overview", "center", "dense", "roles", "place"]:
		printerr("AOMX_CDMX_CAPTURE and AOMX_CDMX_MODE=overview|center|dense|roles|place are required")
		quit(1)
		return
	var client: Node = Scene.instantiate()
	client.outbox = Outbox.new("user://cdmx-capture-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	var faction := OS.get_environment("AOMX_CDMX_FACTION")
	client._choose_faction(faction if faction in Skirmish.FACTION_IDS else Skirmish.REGIOS)
	client.sim.ai_enabled = false
	await process_frame
	var requested_zoom := OS.get_environment("AOMX_CDMX_ZOOM")
	if requested_zoom.is_valid_float():
		client.board_zoom = clampf(requested_zoom.to_float(), client.ZOOM_MIN, client.ZOOM_MAX)
		client.zoom_adjustment = client.board_zoom - client._default_board_zoom(root.get_visible_rect().size)
	if mode != "overview":
		client._navigate_minimap(Vector2i(10, 10))
		client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 9))
	if mode == "dense":
		for index in range(6):
			client.sim._add_entity(Skirmish.HUMAN, "melee" if index % 2 == 0 else "ranged", Vector2i(7 + index, 8))
			client.sim._add_entity(Skirmish.COMPUTER, "armored" if index % 2 == 0 else "siege", Vector2i(8 + index, 11))
	if mode == "roles":
		for index in range(5):
			var kind: String = ["worker", "melee", "ranged", "armored", "siege"][index]
			client.sim._add_entity(Skirmish.HUMAN, kind, Vector2i(5 + index * 2, 10))
			client.sim._add_entity(Skirmish.COMPUTER, kind, Vector2i(6 + index * 2, 13))
	if mode == "place":
		for index in range(4):
			var building: String = ["barracks", "depot", "housing", "registry"][index]
			var id: int = client.sim._add_entity(Skirmish.HUMAN, building, Vector2i(4 + index * 4, 13))
			if building == "housing":
				client.sim.entities[id].complete = false
				client.sim.entities[id].progress = 2
			if building == "depot":
				client.sim.entities[id].hp = client.sim._starting_health(Skirmish.HUMAN, building) / 3
	client.sim._refresh_visibility()
	client._update_hud()
	client.queue_redraw()
	var frame_intervals: Array[float] = []
	var peak_memory := 0.0
	var prior := Time.get_ticks_usec()
	for index in 120:
		await process_frame
		var now := Time.get_ticks_usec()
		frame_intervals.append(float(now - prior) / 1000.0)
		prior = now
		peak_memory = maxf(peak_memory, Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0)
	frame_intervals.sort()
	var image := root.get_texture().get_image()
	var error := image.save_png(capture_path)
	print("CDMX_RENDER mode=%s zoom=%.2f entities=%d p95_interval_ms=%.2f peak_static_mib=%.1f capture=%s error=%d" % [
		mode, client.board_zoom, client.sim.entities.size(), frame_intervals[113], peak_memory, capture_path, error])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(client.outbox.filename))
	quit(0 if error == OK else 1)
