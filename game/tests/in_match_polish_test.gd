extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var game = Skirmish.new()
	game.ai_enabled = false
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	var actor: Dictionary = game.entities[worker]
	actor.carry = 3
	actor.carry_resource = "varos"
	actor.source_resource = "varos"
	actor.order_pos = game.resource_sources[Skirmish.HUMAN].varos.pos
	actor.job = "gather"
	var food_tile: Vector2i = game.resource_sources[Skirmish.HUMAN].comida.pos
	var before: int = game.balance(Skirmish.HUMAN, "varos")
	var switched: Dictionary = game.issue(Skirmish.HUMAN, "gather", worker, food_tile)
	check(switched.ok and switched.reason == "delivering_then_gathering" and actor.job == "deliver" and actor.source_resource == "comida",
		"worker accepts a new resource and starts by delivering old cargo")
	var delivered := false
	for i in 150:
		game.tick()
		if game.balance(Skirmish.HUMAN, "varos") == before + 3 and actor.job == "gather":
			delivered = true
			break
	check(delivered and actor.carry_resource == "" and actor.order_pos == food_tile,
		"worker deposits the old resource then resumes the requested resource")
	for map_id in Skirmish.MAP_IDS:
		var chapter = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner", map_id, "", "arrival_copilco")
		check(chapter.map_id == map_id and chapter.mission_id == "arrival_copilco", "campaign chapter opens on " + map_id)
		var saved := Save.capture(chapter, "solo_0123456789abcdef0123456789abcdef")
		check(Save.restore(saved).ok, "campaign choice restores on " + map_id)
	var client = Scene.instantiate()
	root.add_child(client)
	client._choose_faction(Skirmish.REGIOS)
	client.sim.ai_enabled = false
	var source: Dictionary = client.sim.resource_sources[Skirmish.HUMAN].comida
	client.selected_source_tile = source.pos
	client.selected_id = -1
	client.selected_ids.clear()
	client._update_hud()
	check(client.hud_ui.selection_title.text == "COMIDA SOURCE" and client.hud_ui.selection_details.text.contains("remaining"),
		"selected resource shows type and remaining stock")
	source.amount = 0
	source.refreshes_left = 0
	client._update_hud()
	check(client.hud_ui.selection_details.text.contains("Depleted"), "depleted site is named in selection details")
	var scout: int = client.sim._find(Skirmish.HUMAN, "worker")
	client.selected_id = scout
	client.selected_ids.clear()
	client.selected_ids.append(scout)
	var fallback: Vector2i = client._group_move_target(scout, source.pos, {})
	check(fallback != source.pos and client.sim._walkable(fallback), "move onto a resource finds the nearest free tile")
	root.remove_child(client)
	client.queue_free()
	await process_frame
	if not failed:
		print("In-match polish checks passed")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
