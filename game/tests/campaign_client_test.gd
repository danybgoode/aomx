extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Progress = preload("res://campaign_progress.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var suffix := str(Time.get_ticks_usec())
	var progress_path := OS.get_user_data_dir().path_join("aomx-campaign-client-%s.json" % suffix)
	var outbox_path := OS.get_user_data_dir().path_join("aomx-campaign-outbox-%s.json" % suffix)
	var client = Scene.instantiate()
	client.outbox = Outbox.new(outbox_path)
	client.campaign_progress_path = progress_path
	root.add_child(client)
	client._choose_mode(1)
	check(client.campaign_mode and client.setup_mission.visible and client.setup_map.disabled, "campaign has its own setup")
	check("available" in client.setup_mission.get_item_text(0) and "locked" in client.setup_mission.get_item_text(1), "chapter shows locks")
	client._choose_mission(1)
	check("Locked" in client.setup_campaign_note.text, "mission explains prerequisite")
	client._choose_faction(Skirmish.REGIOS)
	check(client.choosing_faction and client.match_id.is_empty(), "locked mission cannot start")
	client._choose_mission(0)
	client._choose_faction(Skirmish.REGIOS)
	check(client.sim.mission_id == "arrival_copilco" and not client.choosing_faction, "available mission starts on its map")
	check(client.outbox.state.events.size() == 1, "tutorial does not enter match funnel")
	client.sim.mission_steps = ["gather", "build", "recruit"]
	client.sim.mission_result = "win"
	client.sim.tick_number = 1
	client._process(0.1)
	check(Progress.read(progress_path).completed == ["arrival_copilco"], "verified result unlocks once")
	check(client.outbox.state.events.size() == 2 and client.outbox.state.events[1].event.type == "campaign_mission_completed", "first win queues one adoption event")
	check(client.hud_ui.result_panel.visible, "mission result renders")
	client._show_setup()
	client._choose_mode(1)
	check("available" in client.setup_mission.get_item_text(1), "new setup reads saved unlock")
	var foothold = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner", "narvarte", "", "foothold_narvarte")
	foothold.mission_steps = ["expand", "contest"]
	foothold.mission_result = "win"
	foothold.tick_number = 1
	check(Progress.record_verified(foothold, progress_path).ok, "second verified win unlocks finale")
	client._refresh_campaign_setup()
	client._choose_mission(2)
	check(client.selected_map == "la_roma_large" and "available" in client.setup_mission.get_item_text(2), "finale uses the large map")
	client._choose_faction(Skirmish.REGIOS)
	check(client.outbox.state.events[2].event.type == "match_started" and client.outbox.state.events[2].event.mode == "campaign", "finale queues an eligible candidate start")
	var enemy_post: int = client.sim._find(Skirmish.COMPUTER, "command_post")
	client.sim.entities[enemy_post].hp = 0
	client._process(0.1)
	check(client.sim.mission_result == "win" and Progress.read(progress_path).completed.size() == 3, "full final battle unlocks chapter completion")
	check(client.outbox.state.events[3].event.type == "match_completed" and client.outbox.state.events[4].event.type == "campaign_mission_completed", "finale queues terminal before adoption")
	client._show_setup()
	client._choose_mode(0)
	check(not client.setup_map.disabled and not client.setup_mission.visible, "skirmish map choice remains separate")
	check(client.outbox.state.events.size() == 5, "chapter did not queue tutorial match events")
	DirAccess.remove_absolute(progress_path)
	DirAccess.remove_absolute(outbox_path)
	client.queue_free()
	if not failed:
		print("Campaign client checks passed: locks, start, result, unlock and skirmish isolation")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAIL: ", label)
