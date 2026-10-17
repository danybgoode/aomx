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
	client._choose_faction(Skirmish.REGIOS)
	client.sim.ai_enabled = false
	var mode := OS.get_environment("HUD_CAPTURE_MODE")
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
	client.queue_redraw()
	for i in 8:
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	print("HUD_CAPTURE ", path, " ", image.get_size(), " error=", error)
	quit(0 if error == OK else 1)
