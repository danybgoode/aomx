extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var path := OS.get_environment("HUD_CAPTURE_PATH")
	if path.is_empty():
		printerr("HUD_CAPTURE_PATH is required")
		quit(1)
		return
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://hud-capture-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	var ui_scale := OS.get_environment("HUD_CAPTURE_SCALE")
	if ui_scale.is_valid_float():
		client._set_ui_scale(float(ui_scale), false)
	var mode := OS.get_environment("HUD_CAPTURE_MODE")
	if mode != "setup":
		var map_id := OS.get_environment("HUD_CAPTURE_MAP")
		if map_id in Skirmish.MAP_IDS:
			client.selected_map = map_id
		var faction := OS.get_environment("HUD_CAPTURE_FACTION")
		client._choose_faction(faction if faction in Skirmish.FACTION_IDS else Skirmish.REGIOS)
		client.sim.ai_enabled = false
	if mode == "worker":
		client.selected_id = client.sim._find(Skirmish.HUMAN, "worker")
	elif mode == "building":
		client.selected_id = client.sim._find(Skirmish.HUMAN, "command_post")
	if client.selected_id != -1:
		client.selected_ids.clear()
		client.selected_ids.append(client.selected_id)
	client._update_hud()
	if mode == "reset":
		client.hud_ui.restart_button.pressed.emit()
	if mode == "settings":
		client._toggle_diagnostics()
	if mode == "result":
		client.sim.result = "win"
		client.sim.result_reason = "command_post"
		client._update_hud()
	client.queue_redraw()
	for i in 8:
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	print("HUD_CAPTURE ", path, " ", image.get_size(), " error=", error)
	quit(0 if error == OK else 1)
