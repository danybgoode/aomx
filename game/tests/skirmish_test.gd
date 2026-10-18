extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new()
	check(game.entities.size() == 4, "mirrored posts and workers boot")
	var worker := game._find(Skirmish.HUMAN, "worker")
	var post := game._find(Skirmish.HUMAN, "command_post")
	check(not game.issue(Skirmish.HUMAN, "train", post, "worker").ok, "unaffordable worker rejected")
	check(not game.issue(Skirmish.HUMAN, "move", game._find(Skirmish.COMPUTER, "worker"), Vector2i(4, 4)).ok, "enemy ownership rejected")
	check(game.issue(Skirmish.HUMAN, "gather", worker, Skirmish.RESOURCE_POS[Skirmish.HUMAN]).ok, "gather order accepted")
	for i in range(450):
		game.tick()
		if game.stockpile[Skirmish.HUMAN] >= 12:
			break
	check(game.stockpile[Skirmish.HUMAN] >= 12, "worker delivered resource")
	game._add_balance(Skirmish.HUMAN, "materiales", 20)
	game._add_balance(Skirmish.HUMAN, "comida", 20)
	var before: int = game.stockpile[Skirmish.HUMAN]
	var material_before: int = game.balance(Skirmish.HUMAN, "materiales")
	check(game.issue(Skirmish.HUMAN, "build", worker, Vector2i(10, 2)).reason == "blocked_footprint", "wall footprint rejected")
	check(game.stockpile[Skirmish.HUMAN] == before and game.balance(Skirmish.HUMAN, "materiales") == material_before,
		"rejected build spends nothing")
	check(game.issue(Skirmish.HUMAN, "build", worker, Skirmish.BARRACKS_POS[Skirmish.HUMAN]).ok, "recruitment post placed")
	check(game.stockpile[Skirmish.HUMAN] == before - Skirmish.COST.barracks and game.balance(Skirmish.HUMAN, "materiales") == material_before - 4,
		"construction cost charged once across resources")
	var barracks := game._find(Skirmish.HUMAN, "barracks")
	if barracks == -1:
		quit(1)
		return
	check(not game.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "incomplete barracks cannot train")
	for i in range(130):
		game.tick()
		check(not game._contains(Skirmish.BARRACKS_POS[Skirmish.HUMAN], game.entities[worker].pos), "builder avoids footprint")
		if game.entities[barracks].complete:
			break
	check(game.entities[barracks].complete, "worker completed recruitment post")
	game.stockpile[Skirmish.HUMAN] = 20
	check(game.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "melee queued")
	check(game.issue(Skirmish.HUMAN, "train", barracks, "ranged").ok, "ranged queued")
	for i in range(150):
		game.tick()
	check(game._find(Skirmish.HUMAN, "melee") != -1, "melee produced")
	check(game._find(Skirmish.HUMAN, "ranged") != -1, "ranged produced")
	var melee := game._find(Skirmish.HUMAN, "melee")
	var enemy_worker := game._find(Skirmish.COMPUTER, "worker")
	check(not game.issue(Skirmish.HUMAN, "attack", melee, worker).ok, "friendly attack rejected")
	check(game.issue(Skirmish.HUMAN, "attack", melee, enemy_worker).ok, "enemy attack accepted")
	var melee_fight = Skirmish.new()
	var melee_post := melee_fight._find(Skirmish.COMPUTER, "command_post")
	var nearby_melee := melee_fight._add_entity(Skirmish.HUMAN, "melee", Vector2i(14, 16))
	check(melee_fight.issue(Skirmish.HUMAN, "attack", nearby_melee, melee_post).ok, "melee post attack accepted")
	var post_hp: int = melee_fight.entities[melee_post].hp
	melee_fight.tick()
	check(melee_fight.entities[melee_post].hp == post_hp, "melee must close range")
	var ranged_fight = Skirmish.new()
	var ranged_post := ranged_fight._find(Skirmish.COMPUTER, "command_post")
	var nearby_ranged := ranged_fight._add_entity(Skirmish.HUMAN, "ranged", Vector2i(14, 16))
	check(ranged_fight.issue(Skirmish.HUMAN, "attack", nearby_ranged, ranged_post).ok, "ranged post attack accepted")
	var ranged_hp: int = ranged_fight.entities[ranged_post].hp
	ranged_fight.tick()
	check(ranged_fight.entities[ranged_post].hp == ranged_hp - Skirmish.DAMAGE.ranged, "ranged attacks from distance")
	var cleared = Skirmish.new()
	var blocker := cleared._add_entity(Skirmish.COMPUTER, "barracks", Vector2i(13, 11))
	cleared.entities[blocker].hp = Skirmish.DAMAGE.melee
	var attacker := cleared._add_entity(Skirmish.HUMAN, "melee", Vector2i(12, 11))
	check(not cleared.issue(Skirmish.HUMAN, "move", attacker, Vector2i(13, 11)).ok, "living building blocks path")
	check(cleared.issue(Skirmish.HUMAN, "attack", attacker, blocker).ok, "building attack accepted")
	cleared.tick()
	check(not cleared.entities.has(blocker), "destroyed building removed")
	check(cleared.issue(Skirmish.HUMAN, "move", attacker, Vector2i(13, 11)).ok, "destroyed footprint opens path")
	var replay_a = Skirmish.new()
	var replay_b = Skirmish.new()
	for copy in [replay_a, replay_b]:
		copy.issue(Skirmish.HUMAN, "gather", copy._find(Skirmish.HUMAN, "worker"), Skirmish.RESOURCE_POS[Skirmish.HUMAN])
		for i in range(300):
			copy.tick()
	check(replay_a.snapshot() == replay_b.snapshot(), "replay state equal")
	check(replay_a.state_hash() == replay_b.state_hash(), "replay final state hash equal")
	check(replay_a.command_log == replay_b.command_log, "replay command log equal")
	var opponent = Skirmish.new()
	for i in range(Skirmish.AI_ATTACK_TICK + 50):
		opponent.tick()
	var ai_melee: bool = opponent.command_log.any(func(order: Dictionary) -> bool: return order.side == Skirmish.COMPUTER and order.kind == "train" and order.target == "melee")
	var ai_ranged: bool = opponent.command_log.any(func(order: Dictionary) -> bool: return order.side == Skirmish.COMPUTER and order.kind == "train" and order.target == "ranged")
	var ai_attack: bool = opponent.command_log.any(func(order: Dictionary) -> bool: return order.side == Skirmish.COMPUTER and order.kind == "attack" and order.issued_tick >= Skirmish.AI_ATTACK_TICK)
	check(ai_melee and ai_ranged and ai_attack, "authored opponent gathers, recruits mixed roles, then attacks through orders")
	var win = Skirmish.new()
	var enemy_post := win._find(Skirmish.COMPUTER, "command_post")
	win.entities[enemy_post].hp = 0
	win.tick()
	check(win.result == "win", "opponent post destruction wins")
	var terminal_tick: int = win.terminal_tick
	win.tick()
	check(win.terminal_tick == terminal_tick and not win.issue(Skirmish.HUMAN, "move", win._find(Skirmish.HUMAN, "worker"), Vector2i(5, 2)).ok, "terminal result freezes commands")
	var loss = Skirmish.new()
	loss.entities[loss._find(Skirmish.HUMAN, "command_post")].hp = 0
	loss.tick()
	check(loss.result == "loss", "own post destruction loses")
	var draw = Skirmish.new()
	draw.tick_number = Skirmish.DRAW_TICK - 1
	draw.tick()
	check(draw.result == "draw", "15-minute limit draws")
	var simultaneous = Skirmish.new()
	simultaneous.entities[simultaneous._find(Skirmish.HUMAN, "command_post")].hp = 0
	simultaneous.entities[simultaneous._find(Skirmish.COMPUTER, "command_post")].hp = 0
	simultaneous.tick()
	check(simultaneous.result == "draw", "simultaneous post destruction draws")
	if not failed:
		print("Solo skirmish checks passed: economy, production, combat orders, replay, win/loss/draw")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
