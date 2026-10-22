extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
const Minimap = preload("res://ui/minimap_panel.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var unbound_map = Minimap.new()
	unbound_map.size = Vector2(120, 120)
	root.add_child(unbound_map)
	await process_frame
	var unbound_click := InputEventMouseButton.new()
	unbound_click.button_index = MOUSE_BUTTON_LEFT
	unbound_click.position = Vector2(40, 40)
	unbound_click.pressed = true
	unbound_map._gui_input(unbound_click)
	check(unbound_map._point(Rect2(Vector2(7, 7), Vector2(106, 106)), Vector2i(10, 10)).is_finite(),
		"minimap draws and ignores clicks before a simulation is attached")
	unbound_map.queue_free()
	var path := "user://skirmish-client-check-%d.json" % Time.get_ticks_usec()
	var client = Scene.instantiate()
	client.outbox = Outbox.new(path)
	root.add_child(client)
	check("Roma Norte" in client.setup_map.get_item_text(0) and "stylized" in client.setup_map_details.text and "Cibeles" in client.setup_goal.text,
		"La Roma setup gives sourced place context and both win routes")
	client._choose_map(1)
	check(client.selected_map == "narvarte" and "center" in client.setup_goal.text, "other map choice keeps generic objective copy")
	client._choose_map(0)
	check(client.outbox.state.events.size() == 1 and client.choosing_faction, "client opens setup without starting a match")
	client._process(0.1)
	check(client.sim.tick_number == 0 and client.match_id.is_empty(), "setup does not advance a match")
	client._choose_faction(Skirmish.REGIOS)
	check(client._terrain_id(Vector2i(0, 0)).begins_with("terrain_cdmx_"), "La Roma uses the traced CDMX ground pack")
	for kind in ["worker", "melee", "ranged", "armored", "siege"]:
		check(client._actor_art_id({"kind": kind, "side": Skirmish.HUMAN}) == "unit_cdmx_" + kind, "La Roma maps unit role: " + kind)
	for kind in ["command_post", "barracks", "depot", "housing", "registry"]:
		var expected: String = "roma_command_post" if kind == "command_post" else kind
		check(client._actor_art_id({"kind": kind, "side": Skirmish.HUMAN}) == "building_cdmx_" + expected, "La Roma maps building: " + kind)
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
	for zoom in [1.0, 1.1, 1.25, 2.1]:
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
	check(client.hud_ui.minimap.camera_tile == Vector2i(10, 9), "clicking the minimap moves the camera")
	client._toggle_pause()
	var paused_tick: int = client.sim.tick_number
	client._process(0.5)
	check(client.sim.tick_number == paused_tick and client.paused, "pause control holds simulation time")
	client._toggle_pause()
	client._toggle_diagnostics()
	check(client.hud_ui.diagnostics.visible and client.invite_input != null, "menu exposes preserved alpha diagnostics")
	client._toggle_diagnostics()
	client.board_pan = Vector2.ZERO
	var armored_id: int = client.sim._add_entity(Skirmish.HUMAN, "armored", Vector2i(5, 12))
	var siege_id: int = client.sim._add_entity(Skirmish.HUMAN, "siege", Vector2i(6, 12))
	var armored_screen: Vector2 = Vector2(640, 305) + (client._actor_ground(client.sim.entities[armored_id]) - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	var siege_screen: Vector2 = Vector2(640, 305) + (client._actor_ground(client.sim.entities[siege_id]) - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	client._select_drag(Rect2(armored_screen, siege_screen - armored_screen).grow(2), false)
	check(armored_id in client.selected_ids and siege_id in client.selected_ids, "drag selection includes armored and siege roles")
	client.sim.entities.erase(armored_id)
	client.sim.entities.erase(siege_id)
	client.selected_ids.clear()
	client.selected_id = -1
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
	check(client.hud_ui.resource_labels.size() == 4 and client.hud_ui.age_label.text == "FORÁNEA" and client.hud_ui.population_label.text == "1/4",
		"HUD shows four resource counters, age and population")
	var before_hud: String = client.sim.state_hash()
	client._update_hud()
	check(client.sim.state_hash() == before_hud, "HUD refresh does not change simulation state")
	client._activate_command("gather")
	check(client.target_mode == "gather" and client.command_help.text.contains("Comida") and client.command_help.text.contains("Terrenos"),
		"gather button names all four sources")
	client._activate_command("cancel")
	check(client.target_mode.is_empty() and not client.placing, "cancel returns to ordinary selection")
	for resource_id in Skirmish.RESOURCE_IDS:
		var source_tile: Vector2i = client.sim.resource_sources[Skirmish.HUMAN][resource_id].pos
		var source_body: Vector2 = client._tile_to_screen(source_tile) + Vector2(0, -8)
		var source_screen: Vector2 = Vector2(640, 305) + (source_body - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
		check(client._pick_visual_source(source_screen) == (resource_id if client.sim.is_visible(Skirmish.HUMAN, source_tile) else ""), "%s source targetability follows sight" % resource_id)
	var hidden_source: Dictionary = client.sim.resource_sources[Skirmish.HUMAN].terrenos
	var original_source_pos: Vector2i = hidden_source.pos
	hidden_source.pos = Vector2i(26, 2)
	client.sim._refresh_visibility()
	var hidden_body: Vector2 = client._tile_to_screen(hidden_source.pos) + Vector2(0, -8)
	var hidden_screen: Vector2 = Vector2(640, 305) + (hidden_body - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	check(not client.sim.is_visible(Skirmish.HUMAN, hidden_source.pos) and client._pick_visual_source(hidden_screen).is_empty() and client._source_at(hidden_screen, hidden_source.pos).is_empty(),
		"fogged source cannot be hovered or ordered")
	hidden_source.pos = original_source_pos
	client.sim._refresh_visibility()
	var hidden_shot := {"origin": Vector2i(26, 2), "tile": Vector2i(4, 2), "launch": client.sim.tick_number, "arrival": client.sim.tick_number + 5}
	check(not client._projectile_visible(hidden_shot), "projectile launch in fog does not reveal shooter position")
	client.sim.tick_number += 5
	check(client._projectile_visible(hidden_shot), "projectile appears after entering visible ground")
	client.sim.tick_number -= 5
	var comida_tile: Vector2i = client.sim.resource_sources[Skirmish.HUMAN].comida.pos
	var comida_body: Vector2 = client._tile_to_screen(comida_tile) + Vector2(0, -8)
	var comida_screen: Vector2 = Vector2(640, 305) + (comida_body - Vector2(640, 305)) * client.board_zoom + client._board_view_offset()
	client._activate_command("gather")
	var gather_left := InputEventMouseButton.new()
	gather_left.button_index = MOUSE_BUTTON_LEFT
	gather_left.position = comida_screen
	gather_left.pressed = true
	client._unhandled_input(gather_left)
	check(client.sim.entities[worker_id].job == "gather" and client.sim.entities[worker_id].source_resource == "comida" and client.target_mode.is_empty(),
		"gather button and left-click source use the validated resource order")
	var gather_click := InputEventMouseButton.new()
	gather_click.button_index = MOUSE_BUTTON_RIGHT
	gather_click.position = comida_screen
	gather_click.pressed = true
	client._unhandled_input(gather_click)
	check(client.sim.entities[worker_id].job == "gather" and client.order_flash_tile == comida_tile,
		"right-clicking the source marker orders the selected worker to gather")
	var gather: Dictionary = client._issue_order("gather", comida_tile, comida_tile)
	check(gather.ok and client.order_flash_ok and client.order_flash_tile == comida_tile and client.sim.feedback == "Gathering resource.",
		"accepted gather has visible target feedback")
	var rejected: Dictionary = client._issue_order("build", {"kind": "depot", "pos": Vector2i(10, 2)}, Vector2i(10, 2))
	check(not rejected.ok and not client.order_flash_ok and client.sim.feedback != "", "rejected build has distinct readable feedback")
	client._activate_command("build")
	check(client.hud_ui.choice_panel.visible and client._building_reason("depot").contains("Need"),
		"build chooser shows the resource shortfall")
	client.hud_ui.choice_panel.hide()
	for resource_id in Skirmish.RESOURCE_IDS:
		client.sim._add_balance(Skirmish.HUMAN, resource_id, 100)
	client._update_hud()
	check(client.hud_ui.resource_labels["terrenos"].text == "T 100", "Terrenos stockpile updates in the HUD")
	check(client._building_reason("registry").contains("age"), "registry explains its age gate")
	var post_id: int = client.sim._find(Skirmish.HUMAN, "command_post")
	client.selected_id = post_id
	client.selected_ids.clear()
	client.selected_ids.append(post_id)
	client._update_hud()
	check(client.command_buttons["train_worker"].visible and not client.command_buttons["gather"].visible,
		"command post shows its own recruitment order")
	var comida_before: int = client.sim.balance(Skirmish.HUMAN, "comida")
	client._activate_command("train_worker")
	check(client.sim.entities[post_id].queue.size() == 1 and client.sim.balance(Skirmish.HUMAN, "comida") == comida_before - int(client.sim._costs(Skirmish.HUMAN, "worker").comida),
		"recruit button uses four-resource cost and production queue")
	check(client.hud_ui.selection_stats.text.contains("Queue 1"), "selection panel reports the real queue")
	check(client.command_buttons["cancel"].visible, "queued production exposes paid-order cancellation")
	client._activate_command("cancel")
	check(client.hud_ui.choice_panel.visible and client.hud_ui.choice_title.text == "CANCEL PAID ORDER", "queue cancellation shows a confirmation choice")
	var queue_refund: int = int(client.sim._costs(Skirmish.HUMAN, "worker").comida) / 2
	client.hud_ui._choose_entry("cancel_queue_0")
	check(client.sim.entities[post_id].queue.is_empty() and client.sim.balance(Skirmish.HUMAN, "comida") == comida_before - int(client.sim._costs(Skirmish.HUMAN, "worker").comida) + queue_refund,
		"player can cancel active recruitment with the declared half refund")
	client.selected_id = worker_id
	client.selected_ids.clear()
	client.selected_ids.append(worker_id)
	client._update_hud()
	client._activate_command("build")
	check(client.hud_ui.choice_panel.visible and not client.placing, "build button opens the building choices")
	client.hud_ui._choose_entry("build_barracks")
	check(client.target_mode == "build" and client.placing and not client.hud_ui.choice_panel.visible,
		"chosen building arms the placement preview")
	client._complete_target_order(Vector2.ZERO, Skirmish.BARRACKS_POS[Skirmish.HUMAN])
	var unfinished_barracks: int = client.sim._find(Skirmish.HUMAN, "barracks")
	check(unfinished_barracks != -1 and client.target_mode.is_empty(),
		"build button places a post through the validated simulation order")
	var materials_before_cancel: int = client.sim.balance(Skirmish.HUMAN, "materiales")
	client._activate_command("cancel")
	check(client.hud_ui.choice_panel.visible, "incomplete construction exposes cancellation")
	client.hud_ui._choose_entry("cancel_build_%d" % unfinished_barracks)
	check(client.sim._find(Skirmish.HUMAN, "barracks") == -1 and client.sim.balance(Skirmish.HUMAN, "materiales") > materials_before_cancel,
		"player can cancel unfinished construction and receive its refund")
	client._activate_command("build")
	check(client.hud_ui.choice_panel.visible, "worker can open the building chooser before combat")
	client.sim.entities.erase(worker_id)
	client._process(0.1)
	check(client.selected_id == -1 and client.selection_title.text == "NO SELECTION" and not client.hud_ui.choice_panel.visible,
		"lost worker closes its stale building chooser")
	client._activate_command("build_depot")
	check(not client.placing, "stale building choice cannot arm placement after worker death")
	client.sim.age_index[Skirmish.HUMAN] = 1
	var registry_id: int = client.sim._add_entity(Skirmish.HUMAN, "registry", Vector2i(7, 8))
	client.selected_id = registry_id
	client.selected_ids.clear()
	client.selected_ids.append(registry_id)
	client._update_hud()
	client._activate_command("research")
	check(client.hud_ui.choice_panel.visible, "registry can open the research chooser")
	client.sim.entities[registry_id].hp = 0
	client._process(0.1)
	check(client.selected_id == -1 and not client.hud_ui.choice_panel.visible,
		"destroyed registry closes its stale research chooser")
	client._activate_command("research_carry_capacity_i")
	check(not client.sim._queued(Skirmish.HUMAN, "tech", "carry_capacity_i"),
		"stale research choice is rejected without crashing")
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
	for viewport_size in [Vector2i(1024, 700), Vector2i(1536, 960), Vector2i(1920, 1080), Vector2i(844, 390), Vector2i(390, 844)]:
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
		if viewport_size == Vector2i(1024, 700):
			for resource_id in Skirmish.RESOURCE_IDS:
				var counter: Label = client.hud_ui.resource_labels[resource_id]
				check(top_rect.encloses(counter.get_global_rect()), "%s counter fits the 1024×700 HUD" % resource_id)
			check(top_rect.encloses(client.hud_ui.age_label.get_global_rect()) and top_rect.encloses(client.hud_ui.population_label.get_global_rect()),
				"age and population fit the 1024×700 HUD")
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
	client.hud_ui.sound_mute.button_pressed = true
	check(client.order_audio.stream_paused, "mute control silences the order cue")
	client.hud_ui.sound_mute.button_pressed = false
	client.hud_ui.sound_volume.value = 0
	check(client.order_audio.stream_paused, "zero volume silences the order cue")
	client.hud_ui.sound_volume.value = 55
	check(not client.order_audio.stream_paused, "volume control restores the order cue")
	client._show_setup()
	client._choose_map(1)
	client._choose_opponent(4)
	client._choose_faction(Skirmish.OAXAQUENOS)
	check(client.sim.map_id == "narvarte" and client.sim.factions[Skirmish.HUMAN] == Skirmish.OAXAQUENOS and client.sim.factions[Skirmish.COMPUTER] == Skirmish.VERACRUZANOS,
		"setup choices create the selected authored map and cross-faction opponent")
	client._restart_match()
	check(client.sim.map_id == "narvarte" and client.sim.factions[Skirmish.COMPUTER] == Skirmish.VERACRUZANOS,
		"reset preserves the selected map and opponent")
	client._show_setup()
	client._choose_opponent(3)
	client._choose_faction(Skirmish.OAXAQUENOS)
	check(client.sim.factions[Skirmish.COMPUTER] == Skirmish.OAXAQUENOS,
		"explicit same-faction opponent starts a mirror match")
	root.remove_child(client)
	client.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not failed:
		print("Skirmish client checks passed: saved start/result, one terminal event, restart")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
