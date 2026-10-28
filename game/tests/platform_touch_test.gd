extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://platform-touch-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	var setup_zoom: float = client.board_zoom
	var setup_touch := InputEventScreenTouch.new()
	setup_touch.pressed = true
	setup_touch.position = Vector2(400, 250)
	client._unhandled_input(setup_touch)
	var setup_drag := InputEventScreenDrag.new()
	setup_drag.position = Vector2(500, 250)
	client._unhandled_input(setup_drag)
	check(client.choosing_faction and client.touch_points.is_empty() and client.board_pan == Vector2.ZERO and client.board_zoom == setup_zoom,
		"faction setup ignores board touch gestures")
	client._choose_faction(Skirmish.REGIOS)
	var worker: int = client.sim._find(Skirmish.HUMAN, "worker")
	var pos: Vector2i = client.sim.entities[worker].pos
	var point: Vector2 = Vector2(640, 305) + (client._tile_to_screen(pos) - Vector2(640, 305)) * client.board_zoom + client.board_pan + client._board_view_offset()
	var emulated := InputEventMouseButton.new()
	emulated.device = InputEvent.DEVICE_ID_EMULATION
	emulated.button_index = MOUSE_BUTTON_LEFT
	emulated.position = point
	emulated.pressed = true
	client._unhandled_input(emulated)
	check(client.selected_id == -1, "emulated touch mouse does not dispatch a duplicate board click")
	_touch(client, 0, Vector2(20, 20), true)
	_touch(client, 0, Vector2(20, 20), false)
	check(client.selected_id == -1, "a touch beginning over the HUD cannot select the board beneath it")
	_touch(client, 0, point, true)
	_touch(client, 0, point, false)
	check(client.selected_id == worker, "single touch selects a worker through the normal command path")
	var second: int = client.sim._add_entity(Skirmish.HUMAN, "worker", pos + Vector2i(1, 0))
	var second_pos: Vector2i = client.sim.entities[second].pos
	var second_point: Vector2 = Vector2(640, 305) + (client._tile_to_screen(second_pos) - Vector2(640, 305)) * client.board_zoom + client.board_pan + client._board_view_offset()
	client._activate_command("group_select")
	_touch(client, 0, second_point, true)
	_touch(client, 0, second_point, false)
	check(client.touch_group_mode and client.selected_ids.size() == 2 and worker in client.selected_ids and second in client.selected_ids,
		"group mode adds a second worker by touch without replacing the first")
	client._activate_command("group_select")
	check(not client.touch_group_mode, "group mode finishes with both units selected")
	client._activate_command("move")
	check(client.target_mode == "move", "visible Move command enters target mode")
	var original_count: int = client.sim.command_log.size()
	var original_pan: Vector2 = client.board_pan
	_touch(client, 0, point, true)
	_drag(client, 0, point + Vector2(80, 0))
	_touch(client, 0, point + Vector2(80, 0), false)
	check(client.board_pan != original_pan and client.sim.command_log.size() == original_count and client.target_mode == "move",
		"drag pans without issuing a pending order")
	var original_zoom: float = client.board_zoom
	_touch(client, 0, Vector2(500, 260), true)
	_touch(client, 1, Vector2(700, 260), true)
	_drag(client, 1, Vector2(780, 260))
	_touch(client, 1, Vector2(780, 260), false)
	_touch(client, 0, Vector2(500, 260), false)
	check(client.board_zoom > original_zoom and client.sim.command_log.size() == original_count,
		"pinch zooms without sending a board order")
	client._activate_command("cancel")
	check(client.target_mode.is_empty() and client.sim.command_log.size() == original_count,
		"Cancel leaves target mode without a paid command")
	var original_size := root.size
	root.size = Vector2i(844, 390)
	await process_frame
	var ui = client.hud_ui
	var home_post: int = client.sim._find(Skirmish.HUMAN, "command_post")
	check(client._starting_camera_tile() == client.sim.entities[home_post].pos,
		"phone landscape starts the camera at the player's command post")
	check(ui.bottom.position.y - (ui.top.position.y + ui.top.size.y) >= 120.0,
		"phone landscape keeps a pickable board band between top and commands")
	check(ui.command_scroll.size.y >= 44.0 and ui.secondary_toggle.get_global_rect().end.y <= ui.command_panel.get_global_rect().position.y,
		"phone landscape keeps a complete command row and context toggle")
	check(ui.command_buttons["move"].size.y <= 44.0 and ui.command_buttons["move"].get_global_rect().end.y <= ui.command_panel.get_global_rect().end.y,
		"phone landscape command labels stay inside their tap targets")
	root.size = Vector2i(390, 844)
	await process_frame
	check(ui.bottom.position.y - (ui.top.position.y + ui.top.size.y) >= 300.0,
		"phone portrait keeps the battlefield available")
	root.size = original_size
	client.queue_free()
	if not failed:
		print("Platform touch checks passed")
	quit(1 if failed else 0)

func _touch(client: Node, index: int, position: Vector2, pressed: bool) -> void:
	var event := InputEventScreenTouch.new()
	event.index = index
	event.position = position
	event.pressed = pressed
	client._handle_board_touch(event)

func _drag(client: Node, index: int, position: Vector2) -> void:
	var event := InputEventScreenDrag.new()
	event.index = index
	event.position = position
	client._handle_board_touch(event)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
