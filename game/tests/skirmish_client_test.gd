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
	for zoom in [1.0, 1.1, 1.25]:
		client.board_zoom = zoom
		for tile in [Vector2i(4, 2), Vector2i(6, 4), Vector2i(13, 15)]:
			var screen: Vector2 = Vector2(640, 305) + (client._tile_to_screen(tile) - Vector2(640, 305)) * zoom
			check(client._screen_to_tile(screen) == tile, "board hit testing matches visible tile at zoom %.2f" % zoom)
	client.board_zoom = 1.1
	var worker_id: int = client.sim._find(Skirmish.HUMAN, "worker")
	var worker_tile: Vector2i = client.sim.entities[worker_id].pos
	var worker_body: Vector2 = client._tile_to_screen(worker_tile) + Vector2(0, -27)
	var worker_screen: Vector2 = Vector2(640, 305) + (worker_body - Vector2(640, 305)) * client.board_zoom
	check(client._screen_to_tile(worker_screen) != worker_tile, "worker body overhangs its simulation tile")
	check(client._pick_visual_entity(worker_screen, Skirmish.HUMAN) == worker_id, "visible worker body is pickable")
	var select_click := InputEventMouseButton.new()
	select_click.button_index = MOUSE_BUTTON_LEFT
	select_click.position = worker_screen
	select_click.pressed = true
	client._unhandled_input(select_click)
	check(client.selected_id == worker_id, "clicking the worker body selects it")
	check(client.selection_title.text.contains("Worker") and client.selection_portrait.texture != null and client.selection_details.text.contains("HP"),
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
	var cart_screen: Vector2 = Vector2(640, 305) + (cart_body - Vector2(640, 305)) * client.board_zoom
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
	check(client.command_buttons["build"].disabled and client.command_buttons["build"].text.contains("Need"),
		"unaffordable build explains its cost")
	client.sim.stockpile[Skirmish.HUMAN] = 10
	var post_id: int = client.sim._find(Skirmish.HUMAN, "command_post")
	client.selected_id = post_id
	client._update_hud()
	check(client.command_buttons["train_worker"].visible and not client.command_buttons["gather"].visible,
		"command post shows its own recruitment order")
	var gold_before: int = client.sim.stockpile[Skirmish.HUMAN]
	client._activate_command("train_worker")
	check(client.sim.entities[post_id].queue.size() == 1 and client.sim.stockpile[Skirmish.HUMAN] == gold_before - client.sim._cost(Skirmish.HUMAN, "worker"),
		"recruit button uses actual cost and production queue")
	check(client.selection_details.text.contains("Queue 1"), "selection panel reports the real queue")
	client.sim.entities[client.sim._find(Skirmish.COMPUTER, "command_post")].hp = 0
	client._process(0.1)
	check(client.outbox.state.events.size() == 5 and client.outbox.state.events[4].event.faction == Skirmish.POBLANOS,
		"second faction completion keeps its chosen faction")
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
