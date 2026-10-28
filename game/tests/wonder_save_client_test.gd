extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var suffix := Time.get_ticks_usec()
	var save_path := "user://wonder-ui-save-%d.json" % suffix
	var outbox_path := "user://wonder-ui-events-%d.json" % suffix
	var client: Node = Scene.instantiate()
	client.save_path = save_path
	client.outbox = Outbox.new(outbox_path)
	root.add_child(client)
	client.wonder_flag = {"enabled": true, "served": true, "flag_version": 1, "exposure_proof": "a".repeat(64)}
	client._refresh_wonder_setup()
	client._choose_objective(2)
	client._choose_faction(Skirmish.REGIOS)
	check(client.sim.objective_id == "wonder" and client.sim.content.content_id == "la-roma-wonder-1", "served Wonder starts with isolated content")
	var original_id: String = client.match_id
	var start: Dictionary = client.outbox.state.events[1].event
	check(start.objective_id == "wonder" and start.wonder_flag_version == 1 and start.wonder_exposure_proof == "a".repeat(64),
		"start pins the served evaluation proof")
	client.sim.ai_enabled = false
	client.sim.age_index[Skirmish.HUMAN] = 2
	for resource_id in Skirmish.RESOURCE_IDS:
		client.sim._add_balance(Skirmish.HUMAN, resource_id, 50)
	var worker: int = client.sim._find(Skirmish.HUMAN, "worker")
	check(client.sim.issue(Skirmish.HUMAN, "build", worker, {"kind": "wonder", "pos": Vector2i(5, 8)}).ok,
		"Wonder construction starts by a paid legal order")
	client.sim.entities[worker].pos = Vector2i(5, 7)
	client.sim.entities[worker].path.clear()
	for i in 300:
		client.sim.tick()
	var project: int = client.sim._find(Skirmish.HUMAN, "wonder")
	check(client.sim.entities[project].complete and client.sim.wonder_progress[Skirmish.HUMAN] == 120,
		"Wonder completed and held for 120 ticks before save")
	var original_hash: String = client.sim.state_hash()
	client._save_match()
	check(FileAccess.file_exists(save_path), "Wonder saves through menu path")
	client._show_setup()
	client.wonder_flag = {"enabled": false, "served": true, "flag_version": 2, "exposure_proof": "b".repeat(64)}
	client._refresh_wonder_setup()
	client._resume_match()
	check(not client.choosing_faction and client.sim.objective_id == "wonder" and client.match_id == original_id and client.sim.state_hash() == original_hash,
		"pinned Wonder match resumes after a served-off decision")
	check(client.sim.wonder_progress[Skirmish.HUMAN] == 120 and client.outbox.state.events.size() == 2,
		"resume preserves countdown and does not duplicate start")
	client.sim.entities[client.sim._find(Skirmish.COMPUTER, "command_post")].hp = 0
	client._process(0.1)
	check(client.sim.result == "win" and client.sim.result_reason == "command_post" and client.outbox.state.events.size() == 4,
		"resumed Wonder match records one finish and adoption")
	check(client.outbox.state.events[3].event.wonder_exposure_proof == start.wonder_exposure_proof,
		"completion keeps start's exposure even after flag-off")
	client._show_setup()
	client._choose_objective(2)
	check(client.setup_objective.is_item_disabled(2) and client.selected_objective != "wonder", "served off blocks new Wonder starts")
	client.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(outbox_path))
	if failed: quit(1)
	else:
		print("Wonder save client checks passed")
		quit(0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		push_error(label)
