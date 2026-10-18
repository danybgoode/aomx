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
	client.sim.ai_enabled = false
	var original_id: String = client.match_id
	var worker: int = client.sim._find(Skirmish.HUMAN, "worker")
	check(client.sim.issue(Skirmish.HUMAN, "gather", worker, client.sim.resource_sources[Skirmish.HUMAN].comida.pos).ok,
		"Comida gathering issued before saving")
	for i in 60:
		client.sim.tick()
	for resource_id in Skirmish.RESOURCE_IDS:
		client.sim._add_balance(Skirmish.HUMAN, resource_id, 100)
	check(client.sim.issue(Skirmish.HUMAN, "build", worker, {"kind": "depot", "pos": Vector2i(4, 6)}).ok,
		"depot build starts through the legal command")
	for i in 100:
		client.sim.tick()
	check(client.sim.entities[client.sim._find(Skirmish.HUMAN, "depot")].complete, "depot finishes before age prerequisite")
	check(client.sim.issue(Skirmish.HUMAN, "build", worker, {"kind": "housing", "pos": Vector2i(7, 4)}).ok,
		"housing build starts through the legal command")
	for i in 100:
		client.sim.tick()
	check(client.sim.entities[client.sim._find(Skirmish.HUMAN, "housing")].complete, "housing finishes before age prerequisite")
	var post: int = client.sim._find(Skirmish.HUMAN, "command_post")
	check(client.sim.issue(Skirmish.HUMAN, "advance", post, "universitaria").ok,
		"age advance queues with completed prerequisites")
	check(client.sim.entities[post].queue.size() == 1 and client.sim.entities[post].queue[0].kind == "age",
		"age queue is visible before save")
	client.selected_id = post
	client.selected_ids.clear()
	client.selected_ids.append(post)
	client._update_hud()
	var terrenos_after_age_cost: int = client.sim.balance(Skirmish.HUMAN, "terrenos")
	client._activate_command("cancel")
	client.hud_ui._choose_entry("cancel_queue_0")
	check(client.sim.entities[post].queue.is_empty() and client.sim.balance(Skirmish.HUMAN, "terrenos") > terrenos_after_age_cost,
		"player can cancel a queued age and receive a refund")
	check(client.sim.issue(Skirmish.HUMAN, "advance", post, "universitaria").ok, "age can be queued again after cancellation")
	var original_hash: String = client.sim.state_hash()
	var original_comida: int = client.sim.balance(Skirmish.HUMAN, "comida")
	var original_source: int = client.sim.resource_sources[Skirmish.HUMAN].comida.amount
	var event_count: int = client.outbox.state.events.size()
	client._save_match()
	check(FileAccess.file_exists(save_path), "menu Save wrote a match file")
	client._show_setup()
	check(client.setup_resume.visible, "faction screen offers Resume")
	client._resume_match()
	check(not client.choosing_faction and client.match_id == original_id and client.sim.state_hash() == original_hash,
		"Resume restores match identity and canonical state")
	check(client.sim.balance(Skirmish.HUMAN, "comida") == original_comida and client.sim.resource_sources[Skirmish.HUMAN].comida.amount == original_source,
		"Resume restores stockpile and finite source state")
	check(client.sim.entities[client.sim._find(Skirmish.HUMAN, "command_post")].queue[0].kind == "age",
		"Resume preserves the active age queue")
	for i in 90:
		client.sim.tick()
	check(client.sim.age_index[Skirmish.HUMAN] == 1 and client.hud_ui != null, "queued transition reaches Universitaria after resume")
	client._update_hud()
	check(client.hud_ui.age_label.text == "UNIVERSITARIA", "HUD displays the resumed age")
	check(client.sim.issue(Skirmish.HUMAN, "build", worker, {"kind": "registry", "pos": Vector2i(5, 8)}).ok,
		"Universitaria unlocks registry construction")
	for i in 100:
		client.sim.tick()
	var registry: int = client.sim._find(Skirmish.HUMAN, "registry")
	check(registry != -1 and client.sim.entities[registry].complete, "registry completes after resume")
	check(client.sim.issue(Skirmish.HUMAN, "research", registry, "carry_capacity_i").ok,
		"registry queues carry research")
	client.selected_id = registry
	client.selected_ids.clear()
	client.selected_ids.append(registry)
	client._update_hud()
	var comida_after_tech_cost: int = client.sim.balance(Skirmish.HUMAN, "comida")
	client._activate_command("cancel")
	client.hud_ui._choose_entry("cancel_queue_0")
	check(client.sim.entities[registry].queue.is_empty() and client.sim.balance(Skirmish.HUMAN, "comida") > comida_after_tech_cost,
		"player can cancel queued research and receive a refund")
	check(client.sim.issue(Skirmish.HUMAN, "research", registry, "carry_capacity_i").ok,
		"research can be queued again after cancellation")
	for i in 60:
		client.sim.tick()
	check("carry_capacity_i" in client.sim.researched[Skirmish.HUMAN], "research effect completes after resume")
	client._save_match()
	client._show_setup()
	client._resume_match()
	check(client.sim.age_index[Skirmish.HUMAN] == 1 and "carry_capacity_i" in client.sim.researched[Skirmish.HUMAN],
		"second Resume preserves completed age and technology")
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
		print("Skirmish save client checks passed: resources, age, research, resume, result deduplication and error feedback")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
