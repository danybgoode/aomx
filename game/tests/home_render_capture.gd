extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var target := OS.get_environment("AOMX_HOME_CAPTURE")
	var width := int(OS.get_environment("AOMX_HOME_WIDTH"))
	var height := int(OS.get_environment("AOMX_HOME_HEIGHT"))
	if target.is_empty() or width < 320 or height < 500:
		printerr("Set AOMX_HOME_CAPTURE, AOMX_HOME_WIDTH and AOMX_HOME_HEIGHT")
		quit(1)
		return
	root.size = Vector2i(width, height)
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://home-capture-events-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	for frame in 12:
		await process_frame
	var picture := root.get_texture().get_image()
	var error := picture.save_png(target)
	print("HOME_CAPTURE=%s size=%dx%d error=%d" % [target, width, height, error])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(client.outbox.filename))
	quit(0 if error == OK else 1)
