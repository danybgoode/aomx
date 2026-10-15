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
	check(client.outbox.state.events.size() == 2, "client saves open and start on boot")
	var start: Dictionary = client.outbox.state.events[1].event
	check(start.type == "match_started" and start.test_account, "client start is test tagged")
	check(start.game_version == Skirmish.GAME_VERSION and start.content_version == Skirmish.CONTENT_VERSION, "client event carries skirmish rule versions")
	check(start.match_id == client.match_id, "client match ID matches saved start")
	var enemy_post: int = client.sim._find(Skirmish.COMPUTER, "command_post")
	client.sim.entities[enemy_post].hp = 0
	client._process(0.1)
	check(client.sim.result == "win", "terminal result displayed from simulation")
	check(client.outbox.state.events.size() == 3, "one terminal event saved")
	var finish: Dictionary = client.outbox.state.events[2].event
	check(finish.type == "match_completed" and finish.result == "win", "client saves actual terminal result")
	check(finish.match_id == start.match_id and finish.local_sequence > start.local_sequence, "result links to start in order")
	client._process(0.1)
	check(client.outbox.state.events.size() == 3, "repeated frame cannot duplicate terminal result")
	check(Outbox.new(path).state.events.size() == 3, "terminal result survives restart")
	client._start_match()
	check(client.outbox.state.events.size() == 4 and client.match_id != start.match_id, "restart creates a new match start")
	check(client.sim.result.is_empty(), "restart clears terminal state")
	for zoom in [1.0, 1.1, 1.25]:
		client.board_zoom = zoom
		for tile in [Vector2i(4, 2), Vector2i(6, 4), Vector2i(13, 15)]:
			var screen: Vector2 = Vector2(640, 305) + (client._tile_to_screen(tile) - Vector2(640, 305)) * zoom
			check(client._screen_to_tile(screen) == tile, "board hit testing matches visible tile at zoom %.2f" % zoom)
	client.board_zoom = 1.1
	client.selected_id = client.sim._find(Skirmish.HUMAN, "worker")
	var gold_tile: Vector2i = Skirmish.RESOURCE_POS[Skirmish.HUMAN]
	var gather: Dictionary = client._issue_order("gather", gold_tile, gold_tile)
	check(gather.ok and client.order_flash_ok and client.order_flash_tile == gold_tile and client.sim.feedback == "Gathering gold.", "accepted gather has visible target feedback")
	var rejected: Dictionary = client._issue_order("build", Vector2i(10, 2), Vector2i(10, 2))
	check(not rejected.ok and not client.order_flash_ok and client.sim.feedback != "", "rejected build has distinct readable feedback")
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
