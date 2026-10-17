extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := "user://skirmish-client-check-%d.json" % Time.get_ticks_usec()
	var client = Scene.instantiate()
	client.outbox = Outbox.new(path)
	root.add_child(client)
	check(client.outbox.state.events.size() == 1 and client.choosing_faction, "client opens setup without starting a match")
	client._process(0.1)
	check(client.sim.tick_number == 0 and client.match_id.is_empty(), "setup does not advance a match")
	client._choose_faction(Skirmish.REGIOS)
	check(client.outbox.state.events.size() == 2, "faction choice saves one match start")
	var start: Dictionary = client.outbox.state.events[1].event
	check(start.type == "match_started" and start.test_account and start.faction == Skirmish.REGIOS, "client start is test tagged with chosen faction")
	check(start.game_version == Skirmish.GAME_VERSION and start.content_version == Skirmish.CONTENT_VERSION, "client event carries skirmish rule versions")
	check(start.match_id == client.match_id, "client match ID matches saved start")
	var enemy_post: int = client.sim._find(Skirmish.COMPUTER, "command_post")
	client.sim.entities[enemy_post].hp = 0
	client._process(0.1)
	check(client.sim.result == "win", "terminal result displayed from simulation")
	check(client.outbox.state.events.size() == 3, "one terminal event saved")
	var finish: Dictionary = client.outbox.state.events[2].event
	check(finish.type == "match_completed" and finish.result == "win" and finish.faction == Skirmish.REGIOS, "client saves actual terminal result with matching faction")
	check(finish.match_id == start.match_id and finish.local_sequence > start.local_sequence, "result links to start in order")
	client._process(0.1)
	check(client.outbox.state.events.size() == 3, "repeated frame cannot duplicate terminal result")
	check(Outbox.new(path).state.events.size() == 3, "terminal result survives restart")
	client._show_setup()
	check(client.choosing_faction and client.outbox.state.events.size() == 3, "restart returns to choice without starting early")
	client._choose_faction(Skirmish.POBLANOS)
	check(client.outbox.state.events.size() == 4 and client.match_id != start.match_id, "new faction choice creates a new match start")
	check(client.outbox.state.events[3].event.faction == Skirmish.POBLANOS, "restart can choose other faction")
	check(client.sim.result.is_empty(), "restart clears terminal state")
	var original_window_size := root.size
	root.size = Vector2i(1536, 960)
	await process_frame
	var large_window_zoom: float = client.board_zoom
	var resize_tile := Vector2i(6, 4)
	var large_tile_screen: Vector2 = Vector2(640, 305) + (client._tile_to_screen(resize_tile) - Vector2(640, 305)) * large_window_zoom + client.board_pan + client._board_view_offset()
	check(client._screen_to_tile(large_tile_screen) == resize_tile, "tile picking follows resize-based zoom")
	root.size = Vector2i(1024, 700)
	await process_frame
	check(client.board_zoom < large_window_zoom, "resizing a desktop window changes battlefield zoom")
	client._change_zoom(0.1)
	var manual_offset: float = client.zoom_adjustment
	root.size = original_window_size
	await process_frame
	check(is_equal_approx(client.board_zoom, client._default_board_zoom(Vector2(original_window_size)) + manual_offset),
		"window resize preserves the player's wheel/key zoom adjustment")
	client._reset_zoom()
	check(is_equal_approx(client.board_zoom, client._default_board_zoom(Vector2(original_window_size))),
		"zoom reset fits the current window")
	client.board_pan = Vector2.ZERO
	for zoom in [1.0, 1.1, 1.25]:
		client.board_zoom = zoom
		for tile in [Vector2i(4, 2), Vector2i(6, 4), Vector2i(13, 15)]:
			var screen: Vector2 = Vector2(640, 305) + (client._tile_to_screen(tile) - Vector2(640, 305)) * zoom + client._board_view_offset()
			check(client._screen_to_tile(screen) == tile, "board hit testing matches visible tile at zoom %.2f" % zoom)
	client.board_zoom = 1.1
	client._navigate_minimap(Vector2i(10, 10))
	check(client.hud_ui.minimap.camera_tile == Vector2i(10, 10) and client.board_pan != Vector2.ZERO,
		"minimap navigation moves the existing battlefield camera")
	var map_click := InputEventMouseButton.new()
	map_click.button_index = MOUSE_BUTTON_LEFT
	map_click.position = Vector2(7, 7) + (client.hud_ui.minimap.size - Vector2(14, 14)) * Vector2(0.375, 0.325)
	map_click.pressed = true
	client.hud_ui.minimap._gui_input(map_click)
	check(client.hud_ui.minimap.camera_tile == Vector2i(7, 6), "clicking the minimap moves the camera")
	client._toggle_pause()
	var paused_tick: int = client.sim.tick_number
	client._process(0.5)
	check(client.sim.tick_number == paused_tick and client.paused, "pause control holds simulation time")
	client._toggle_pause()
	client._toggle_diagnostics()
	check(client.hud_ui.diagnostics.visible and client.invite_input != null, "menu exposes preserved alpha diagnostics")
	client._toggle_diagnostics()
	client.board_pan = Vector2.ZERO
	var worker_id: int = client.sim._find(Skirmish.HUMAN, "worker")
	var worker_tile: Vector2i = client.sim.entities[worker_id].pos
	var worker_body: Vector2 = client._tile_to_screen(worker_tile) + Vector2(0, -27)
	var worker_screen: Vector2 = Vector2(640, 305) + (worker_body - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	check(client._screen_to_tile(worker_screen) != worker_tile, "worker body overhangs its simulation tile")
	check(client._pick_visual_entity(worker_screen, Skirmish.HUMAN) == worker_id, "visible worker body is pickable")
	var select_click := InputEventMouseButton.new()
	select_click.button_index = MOUSE_BUTTON_LEFT
	select_click.position = worker_screen
	select_click.pressed = true
	client._unhandled_input(select_click)
	check(client.selected_id == worker_id, "clicking the worker body selects it")
	check(client.selection_title.text.contains("Worker") and client.selection_portrait.texture != null and client.hud_ui.selection_hp_label.text.contains("HP"),
		"selection panel follows the active board actor")
	check(client.command_buttons["gather"].visible and client.command_buttons["move"].visible and not client.command_buttons["attack"].visible,
		"worker sees only relevant commands")
	var before_hud: String = client.sim.state_hash()
	client._update_hud()
	check(client.sim.state_hash() == before_hud, "HUD refresh does not change simulation state")
	client._activate_command("gather")
	check(client.target_mode == "gather" and client.command_help.text.contains("gold cart"), "gather button arms a clear target prompt")
	client._activate_command("cancel")
	check(client.target_mode.is_empty() and not client.placing, "cancel returns to ordinary selection")
	var gold_tile: Vector2i = Skirmish.RESOURCE_POS[Skirmish.HUMAN]
	var cart_body: Vector2 = client._tile_to_screen(gold_tile) + Vector2(0, -20)
	var cart_screen: Vector2 = Vector2(640, 305) + (cart_body - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	check(client._screen_to_tile(cart_screen) != gold_tile, "cart body overhangs its resource tile")
	check(client._pick_visual_source(cart_screen) == Skirmish.HUMAN, "visible cart body is targetable")
	client._activate_command("gather")
	var gather_left := InputEventMouseButton.new()
	gather_left.button_index = MOUSE_BUTTON_LEFT
	gather_left.position = cart_screen
	gather_left.pressed = true
	client._unhandled_input(gather_left)
	check(client.sim.entities[worker_id].job == "gather" and client.target_mode.is_empty(),
		"gather button and left-click cart use the existing simulation order")
	var gather_click := InputEventMouseButton.new()
	gather_click.button_index = MOUSE_BUTTON_RIGHT
	gather_click.position = cart_screen
	gather_click.pressed = true
	client._unhandled_input(gather_click)
	check(client.sim.entities[worker_id].job == "gather" and client.order_flash_tile == gold_tile,
		"right-clicking the cart body orders the selected worker to gather")
	var gather: Dictionary = client._issue_order("gather", gold_tile, gold_tile)
	check(gather.ok and client.order_flash_ok and client.order_flash_tile == gold_tile and client.sim.feedback == "Gathering gold.", "accepted gather has visible target feedback")
	var rejected: Dictionary = client._issue_order("build", Vector2i(10, 2), Vector2i(10, 2))
	check(not rejected.ok and not client.order_flash_ok and client.sim.feedback != "", "rejected build has distinct readable feedback")
	check(client.command_buttons["build"].disabled and client.command_buttons["build"].tooltip_text.contains("Need"),
		"unaffordable build explains its cost")
	client.sim.stockpile[Skirmish.HUMAN] = 10
	var post_id: int = client.sim._find(Skirmish.HUMAN, "command_post")
	client.selected_id = post_id
	client.selected_ids.clear()
	client.selected_ids.append(post_id)
	client._update_hud()
	check(client.command_buttons["train_worker"].visible and not client.command_buttons["gather"].visible,
		"command post shows its own recruitment order")
	var gold_before: int = client.sim.stockpile[Skirmish.HUMAN]
	client._activate_command("train_worker")
	check(client.sim.entities[post_id].queue.size() == 1 and client.sim.stockpile[Skirmish.HUMAN] == gold_before - client.sim._cost(Skirmish.HUMAN, "worker"),
		"recruit button uses actual cost and production queue")
	check(client.hud_ui.selection_stats.text.contains("Queue 1"), "selection panel reports the real queue")
	client.selected_id = worker_id
	client.selected_ids.clear()
	client.selected_ids.append(worker_id)
	client._update_hud()
	client._activate_command("build")
	check(client.target_mode == "build" and client.placing, "build button arms the existing placement preview")
	client._complete_target_order(Vector2.ZERO, Skirmish.BARRACKS_POS[Skirmish.HUMAN])
	check(client.sim._find(Skirmish.HUMAN, "barracks") != -1 and client.target_mode.is_empty(),
		"build button places a post through the validated simulation order")
	client.sim.entities.erase(worker_id)
	client._process(0.1)
	check(client.selected_id == -1 and client.selection_title.text == "NO SELECTION", "lost actor clears the selection panel")
	var fighter_id: int = client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(4, 2))
	var target_id: int = client.sim._add_entity(Skirmish.COMPUTER, "melee", Vector2i(5, 2))
	client.selected_id = fighter_id
	client.selected_ids.clear()
	client.selected_ids.append(fighter_id)
	client._activate_command("attack")
	client._activate_command("cancel")
	check(client.target_mode.is_empty(), "attack target flow can be canceled")
	client._activate_command("attack")
	var enemy_screen: Vector2 = Vector2(640, 305) + (client._tile_to_screen(Vector2i(5, 2)) - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	client._complete_target_order(enemy_screen, Vector2i(5, 2))
	check(client.sim.entities[fighter_id].job == "attack" and client.sim.entities[fighter_id].target_id == target_id,
		"attack button targets a visible enemy through the existing order path")
	var wing_id: int = client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(4, 3))
	var group_center: Vector2 = Vector2(640, 305) + (client._tile_to_screen(Vector2i(4, 2)) - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	client._select_drag(Rect2(group_center - Vector2(40, 25), Vector2(80, 70)), false)
	check(client.selected_ids.size() == 2 and client.selection_title.text.contains("2 UNITS") and client.hud_ui.group_grid.visible,
		"drag selection builds a clickable portrait group")
	var group_log_size: int = client.sim.command_log.size()
	client._issue_order("attack", target_id, Vector2i(5, 2))
	check(client.sim.command_log.size() == group_log_size + 2 and client.sim.entities[wing_id].target_id == target_id,
		"group attack dispatches validated simulation commands for each fighter")
	client._select_subset(wing_id)
	check(client.selected_ids == [wing_id] and not client.hud_ui.group_grid.visible,
		"portrait subset returns to one unit")
	var baseline_top_height := 52.0
	for viewport_size in [Vector2i(1536, 960), Vector2i(1920, 1080), Vector2i(844, 390), Vector2i(390, 844)]:
		root.size = viewport_size
		await process_frame
		var bar: Panel = client.hud_ui.bottom
		var map: Control = client.hud_ui.minimap
		var bar_rect: Rect2 = bar.get_global_rect()
		var map_rect: Rect2 = map.get_global_rect()
		var top_rect: Rect2 = client.hud_ui.top.get_global_rect()
		check(bar_rect.position.x >= 0 and bar_rect.position.y >= 0 and bar_rect.end.x <= viewport_size.x and bar_rect.end.y <= viewport_size.y,
			"bottom HUD stays inside %s viewport" % viewport_size)
		check(map_rect.position.x >= 0 and map_rect.position.y >= 0 and map_rect.end.x <= viewport_size.x and map_rect.end.y <= viewport_size.y,
			"minimap stays inside %s viewport" % viewport_size)
		check(top_rect.position.x >= 0 and top_rect.end.x <= viewport_size.x and top_rect.end.y <= viewport_size.y,
			"top HUD stays inside %s viewport" % viewport_size)
		if viewport_size.x >= 1280:
			check(top_rect.size.y > baseline_top_height and bar_rect.size.y > 193.0,
				"desktop top and bottom HUD grow with the battlefield at %s" % viewport_size)
		if viewport_size.x < 950:
			for button in client.command_buttons.values():
				if button.visible:
					check(button.get_global_rect().size.y >= 44, "mobile command touch target is at least 44 pixels high")
	root.size = original_window_size
	await process_frame
	client.sim.entities[client.sim._find(Skirmish.COMPUTER, "command_post")].hp = 0
	client._process(0.1)
	check(client.outbox.state.events.size() == 5 and client.outbox.state.events[4].event.faction == Skirmish.POBLANOS,
		"second faction completion keeps its chosen faction")
	var finished_match_id: String = client.match_id
	client._toggle_pause()
	client.hud_ui.restart_button.pressed.emit()
	check(client.hud_ui.restart_scrim.visible and client.match_id == finished_match_id,
		"visible reset asks before discarding match progress")
	var reset_prompt_tick: int = client.sim.tick_number
	client._process(0.5)
	check(client.sim.tick_number == reset_prompt_tick, "reset confirmation holds simulation time")
	client.hud_ui.cancel_restart()
	check(not client.hud_ui.restart_scrim.visible and client.match_id == finished_match_id,
		"canceling reset keeps the current match")
	client.hud_ui.restart_button.pressed.emit()
	client.hud_ui.restart_confirm.pressed.emit()
	check(client.match_id != finished_match_id and client.sim.tick_number == 0 and client.sim.result.is_empty(),
		"visible reset button starts a fresh match")
	check(client.sim.factions[Skirmish.HUMAN] == Skirmish.POBLANOS and not client.paused and client.hud_ui.pause_button.text == "II",
		"reset retains the faction and clears pause state")
	check(client.outbox.state.events.size() == 6 and client.outbox.state.events[5].event.type == "match_started",
		"reset saves exactly one new match start")
	root.remove_child(client)
	client.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not failed:
		print("Skirmish client checks passed: saved start/result, one terminal event, restart")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
