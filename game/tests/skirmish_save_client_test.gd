extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var suffix := Time.get_ticks_usec()
	var save_path := "user://skirmish-ui-save-%d.json" % suffix
	var outbox_path := "user://skirmish-ui-events-%d.json" % suffix
	var client: Node = Scene.instantiate()
	client.save_path = save_path
	client.outbox = Outbox.new(outbox_path)
	root.add_child(client)
	client._choose_faction(Skirmish.REGIOS)
	var original_id: String = client.match_id
	var worker: int = client.sim._find(Skirmish.HUMAN, "worker")
	check(client.sim.issue(Skirmish.HUMAN, "gather", worker, client.sim.sources[Skirmish.HUMAN].pos).ok,
		"playable command issued before saving")
	for i in 60:
		client.sim.tick()
	var original_hash: String = client.sim.state_hash()
	var event_count: int = client.outbox.state.events.size()
	client._save_match()
	check(FileAccess.file_exists(save_path), "menu Save wrote a match file")
	client._show_setup()
	check(client.setup_resume.visible, "faction screen offers Resume")
	client._resume_match()
	check(not client.choosing_faction and client.match_id == original_id and client.sim.state_hash() == original_hash,
		"Resume restores match identity and canonical state")
	check(client.outbox.state.events.size() == event_count, "Resume does not queue a second match start")
	client.sim.entities[client.sim._find(Skirmish.COMPUTER, "command_post")].hp = 0
	client._process(0.1)
	check(client.sim.result == "win" and client.outbox.state.events.size() == event_count + 1,
		"resumed match queues one terminal result")
	client._show_setup()
	client._resume_match()
	check(client.choosing_faction and client.setup_save_error.text.contains("already finished"),
		"a previously completed match cannot be replayed as a new result")
	check(client.outbox.state.events.size() == event_count + 1, "no duplicate completion after blocked resume")
	var file := FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string("{ corrupt")
	file.close()
	client._resume_match()
	check(client.choosing_faction and client.setup_save_error.text.contains("could not load") and FileAccess.file_exists(save_path),
		"corrupt save gives visible feedback and stays intact")
	client.queue_free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(outbox_path))
	if not failed:
		print("Skirmish save client checks passed: save, resume, result deduplication and error feedback")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
