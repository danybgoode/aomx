extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var learner = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner")
	var standard = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard")
	var challenger = Skirmish.new(Skirmish.REGIOS, {}, 1, "challenger")
	check(learner._ai_profile().step_ticks > standard._ai_profile().step_ticks and standard._ai_profile().step_ticks > challenger._ai_profile().step_ticks,
		"three content-defined reaction cadences")
	check(learner.content_hash == standard.content_hash and standard.content_hash == challenger.content_hash
		and learner._cost(Skirmish.COMPUTER, "melee") == challenger._cost(Skirmish.COMPUTER, "melee"),
		"difficulty never changes unit or economic rules")
	for level in Skirmish.AI_LEVELS:
		var game = Skirmish.new(Skirmish.POBLANOS, {}, 2, level)
		for i in 100:
			game.tick()
		var payload: Dictionary = Save.capture(game, "solo_0123456789abcdef0123456789abcdef")
		var resumed: Dictionary = Save.restore(payload)
		check(resumed.ok and resumed.game.ai_difficulty == level and resumed.game.state_hash() == game.state_hash(),
			"level and planner state survive save for " + level)
		check(Replay.verify(Replay.record(game)).ok, "level replays for " + level)
	var bad: Dictionary = Save.capture(standard, "solo_0123456789abcdef0123456789abcdef")
	bad.state.ai_difficulty = "cheater"
	check(Save.restore(bad).reason == "state_ai_invalid", "unknown difficulty rejected")
	var hidden = Skirmish.new()
	var baseline = Skirmish.new()
	hidden._add_entity(Skirmish.HUMAN, "siege", Vector2i(1, 25))
	check(hidden._ai_observed_enemies().is_empty(), "far enemy starts hidden")
	for i in 120:
		hidden.tick()
		baseline.tick()
	var hidden_orders: Array = hidden.command_log.filter(func(c: Dictionary) -> bool: return c.side == Skirmish.COMPUTER)
	var baseline_orders: Array = baseline.command_log.filter(func(c: Dictionary) -> bool: return c.side == Skirmish.COMPUTER)
	check(hidden_orders == baseline_orders, "hidden enemy alone cannot change AI commands")
	var observed = Skirmish.new()
	var armored := observed._add_entity(Skirmish.HUMAN, "armored", Vector2i(19, 16))
	observed._refresh_visibility()
	check(observed._ai_counter_role(observed._ai_observed_enemies()) == "ranged", "visible armor drives a legal ranged counter")
	observed.tick_number = 100
	observed._refresh_visibility()
	var memory: Dictionary = observed.last_seen[Skirmish.COMPUTER][armored]
	observed.entities[armored].pos = Vector2i(1, 25)
	observed._refresh_visibility()
	check(observed.last_seen[Skirmish.COMPUTER][armored] == memory and memory.kind == "armored" and memory.tick == 100,
		"last-seen memory retains position, kind and age without live hidden updates")
	var depleted = Skirmish.new()
	depleted.resource_sources[Skirmish.COMPUTER].varos.amount = 0
	depleted.tick_number = 19
	depleted.tick()
	var worker := depleted._find(Skirmish.COMPUTER, "worker")
	check(depleted.entities[worker].job == "gather" and depleted.entities[worker].source_resource != "varos",
		"worker redirects to available resource when needed source is depleted")
	var dead_end = Skirmish.new()
	dead_end.resource_sources[Skirmish.COMPUTER].varos.amount = 0
	dead_end.resource_sources[Skirmish.COMPUTER].varos.refreshes_left = 0
	dead_end.tick_number = 19
	dead_end.tick()
	check(dead_end.ai_stall_reason == "needed_resource_exhausted" and dead_end.entities[dead_end._find(Skirmish.COMPUTER, "worker")].job == "gather",
		"permanently exhausted needed source is classified while workers use another source")
	var seed_two = Skirmish.new(Skirmish.REGIOS, {}, 2)
	for game in [standard, seed_two]:
		game._add_entity(Skirmish.COMPUTER, "worker", Vector2i(17, 17))
		game._add_entity(Skirmish.COMPUTER, "worker", Vector2i(18, 17))
	check(standard._ai_goal().id == "housing" and seed_two._ai_goal().id == "depot",
		"two deterministic openings choose different legal construction order")
	var conquest = Skirmish.new()
	var post := conquest._find(Skirmish.HUMAN, "command_post")
	conquest.entities[post].hp = 1
	var attacker := conquest._add_entity(Skirmish.COMPUTER, "melee", Vector2i(4, 3))
	conquest.age_index[Skirmish.COMPUTER] = 3
	conquest.tick_number = int(conquest._ai_profile().attack_tick) - 1
	conquest._refresh_visibility()
	conquest.tick()
	check(conquest.command_log.any(func(order: Dictionary) -> bool:
		return order.side == Skirmish.COMPUTER and order.kind == "attack" and order.actor_id == attacker and order.target == post),
		"visible human command post produces a legal Conquest order")
	check(conquest.result == "loss" and conquest.result_reason == "command_post", "opponent can finish the Conquest route")
	if not failed:
		print("Strategic opponent checks passed: levels, legal information, recovery, save and replay")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
