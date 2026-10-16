extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	for faction in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		var game = Skirmish.new(faction)
		game.ai_enabled = false
		check(not game._wall(Vector2i(10, 9)) and not game._wall(Vector2i(10, 11)), "three open center lanes")
		check(not game._clear_footprint(Vector2i(8, 9)), "construction cannot overlap La Roma")
		var worker: int = game._find(Skirmish.HUMAN, "worker")
		game.entities[worker].pos = Vector2i(9, 10)
		game.tick()
		check(game.district_state == "neutral" and game.district_progress == 0, "workers cannot hold the district")
		game.entities[worker].pos = Vector2i(4, 2)
		var fighter := game._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
		game.tick()
		check(game.district_state == "human_hold" and game.district_progress == 1, "human hold starts at one tick")
		var enemy := game._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(11, 10))
		game.tick()
		check(game.district_state == "contested" and game.district_progress == 0, "combat contest resets hold")
		game.entities[enemy].pos = Vector2i(12, 10)
		game.tick()
		check(game.district_progress == 1, "hold restarts after contest")
		game.entities[fighter].pos = Vector2i(8, 10)
		game.tick()
		check(game.district_state == "reset" and game.district_progress == 0, "empty zone resets hold")
		game.entities[fighter].pos = Vector2i(9, 10)
		for i in range(Skirmish.HOLD_TICKS - 1):
			game.tick()
		check(game.result == "" and game.district_progress == Skirmish.HOLD_TICKS - 1, "hold needs all 600 ticks")
		game.tick()
		check(game.result == "win" and game.result_reason == "district", "exact 600-tick district win")
		var terminal: int = game.terminal_tick
		game.tick()
		check(game.terminal_tick == terminal and not game.issue(Skirmish.HUMAN, "move", fighter, Vector2i(9, 9)).ok,
			"district finish freezes match")
		var threatened = Skirmish.new(faction)
		threatened.ai_enabled = false
		threatened._add_entity(Skirmish.COMPUTER, "melee", Vector2i(11, 10))
		for i in range(Skirmish.HOLD_TICKS):
			threatened.tick()
		check(threatened.result == "loss" and threatened.result_reason == "district", "computer district win")
		var precedence = Skirmish.new(faction)
		precedence.ai_enabled = false
		precedence._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
		precedence.district_side = Skirmish.HUMAN
		precedence.district_progress = Skirmish.HOLD_TICKS - 1
		precedence.entities[precedence._find(Skirmish.HUMAN, "command_post")].hp = 0
		precedence.tick()
		check(precedence.result == "loss" and precedence.result_reason == "command_post", "post defeat precedes hold")
		var both = Skirmish.new(faction)
		both.ai_enabled = false
		both._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
		both.district_side = Skirmish.HUMAN
		both.district_progress = Skirmish.HOLD_TICKS - 1
		both.entities[both._find(Skirmish.HUMAN, "command_post")].hp = 0
		both.entities[both._find(Skirmish.COMPUTER, "command_post")].hp = 0
		both.tick()
		check(both.result == "draw" and both.result_reason == "simultaneous_posts", "simultaneous posts precede hold")
		var replay_a = Skirmish.new(faction)
		var replay_b = Skirmish.new(faction)
		for copy in [replay_a, replay_b]:
			copy._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
			for i in range(400):
				copy.tick()
		check(replay_a.state_hash() == replay_b.state_hash() and replay_a.command_log == replay_b.command_log,
			"district and AI replay deterministically")
		var counter = Skirmish.new(faction)
		counter._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
		counter._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(13, 10))
		counter.tick_number = Skirmish.AI_DISTRICT_TICK + 9
		counter.tick()
		var ai_order: bool = counter.command_log.any(func(order: Dictionary) -> bool:
			return order.side == Skirmish.COMPUTER and order.kind == "attack" and order.target == counter._find(Skirmish.HUMAN, "melee"))
		check(ai_order, "computer counters human presence through a validated attack order")
		var open_center = Skirmish.new(faction)
		open_center._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(13, 10))
		open_center.tick_number = Skirmish.AI_DISTRICT_TICK + 9
		open_center.tick()
		var move_order: bool = open_center.command_log.any(func(order: Dictionary) -> bool:
			return order.side == Skirmish.COMPUTER and order.kind == "move" and order.target == [11, 10])
		check(move_order, "computer moves toward district through validated order")
		check(not open_center.entities[open_center._find(Skirmish.COMPUTER, "ranged")].path.is_empty(), "computer has a center route")
		var idle_player = Skirmish.new(faction)
		for i in range(1200):
			idle_player.tick()
			if idle_player.result != "":
				break
		check(idle_player.result == "loss", "active opponent can finish against an idle human")
		check(idle_player.command_log.any(func(order: Dictionary) -> bool:
			return order.side == Skirmish.COMPUTER and order.kind == "move" and order.target == [11, 10]),
			"opponent actually enters the center in a normal match")
	if not failed:
		print("District checks passed: hold, contest, reset, precedence, AI counter, replay")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
