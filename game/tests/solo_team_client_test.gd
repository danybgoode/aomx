extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Skirmish = preload("res://skirmish.gd")
const Outbox = preload("res://funnel_outbox.gd")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://solo-team-client-%d.json" % Time.get_ticks_usec())
	client.audio_settings_path = "user://solo-team-audio-%d.json" % Time.get_ticks_usec()
	client.ui_settings_path = "user://solo-team-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(client)
	await process_frame
	client._choose_mode(2)
	check(client.team_mode and client.selected_map == "la_roma_large" and client.selected_objective == "conquest",
		"2v2 setup pins the large Conquest battlefield")
	check(client.setup_map.disabled and not client.setup_objective.visible and client.setup_goal.text.contains("both opposing command posts"),
		"2v2 setup explains team victory")
	client._choose_faction(Skirmish.REGIOS)
	check(client.sim.team_mode and client.sim._sides().size() == 4 and not client.choosing_faction,
		"faction choice starts a four-side match")
	client._update_hud()
	check(client.hud_ui.secondary_status.text.contains("Our posts") and client.hud_ui.secondary_status.text.contains("Enemy posts"),
		"HUD reports both team posts")
	client._show_setup()
	check(client.choosing_faction and client.match_id.is_empty() and client.setup_panel.visible,
		"MENU returns from 2v2 to the home setup")
	print("Solo 2v2 client checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
