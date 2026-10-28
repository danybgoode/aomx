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
	var objective := OS.get_environment("HUD_CAPTURE_OBJECTIVE")
	if objective == "conquest":
		client._choose_objective(1)
	elif objective == "wonder":
		client.wonder_flag = {"enabled": true, "served": true, "flag_version": 1}
		client._refresh_wonder_setup()
		client._choose_objective(2)
	var ui_scale := OS.get_environment("HUD_CAPTURE_SCALE")
	if ui_scale.is_valid_float():
		client._set_ui_scale(float(ui_scale), false)
	var mode := OS.get_environment("HUD_CAPTURE_MODE")
	if mode in ["campaign_setup", "campaign_goal"]:
		client._choose_mode(1)
	if mode not in ["setup", "campaign_setup"]:
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
		client.sim.result_reason = "wonder" if objective == "wonder" else "command_post"
		client._update_hud()
	if mode == "wonder_progress":
		var wonder: int = client.sim._add_entity(Skirmish.HUMAN, "wonder", Vector2i(5, 8))
		client.sim.entities[wonder].complete = true
		var enemy_wonder: int = client.sim._add_entity(Skirmish.COMPUTER, "wonder", Vector2i(16, 9))
		client.sim.entities[enemy_wonder].complete = true
		client.sim.wonder_progress = [430, 270]
		client.paused = true
		client.selected_id = wonder
		client.selected_ids.clear()
		client.selected_ids.append(wonder)
		client._update_hud()
	if mode in ["effect", "crowded_effect"]:
		client._set_reduced_effects(false)
		client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
		if mode == "crowded_effect":
			for tile in [Vector2i(8, 9), Vector2i(8, 10), Vector2i(9, 9), Vector2i(10, 9)]:
				client.sim._add_entity(Skirmish.HUMAN, "melee", tile)
			for tile in [Vector2i(11, 9), Vector2i(11, 10), Vector2i(12, 9), Vector2i(12, 10)]:
				client.sim._add_entity(Skirmish.COMPUTER, "melee", tile)
		client.sim._refresh_visibility()
		client._baseline_presentation()
		client.sim.tick_number += 1
		client.sim.district_state = "human_hold"
		client._observe_events()
		client._update_hud()
	client.queue_redraw()
	for i in (2 if mode in ["effect", "crowded_effect"] else 8):
		await process_frame
	var image := root.get_texture().get_image()
	var error := image.save_png(path)
	print("HUD_CAPTURE ", path, " ", image.get_size(), " error=", error)
	quit(0 if error == OK else 1)
