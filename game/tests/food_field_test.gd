extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failures := 0

func _initialize() -> void:
	var game = Skirmish.new()
	game.ai_enabled = false
	var worker_id: int = game._find(Skirmish.HUMAN, "worker")
	var worker: Dictionary = game.entities[worker_id]
	var at := Vector2i(-1, -1)
	for radius in range(2, 7):
		for x in range(worker.pos.x - radius, worker.pos.x + radius + 1):
			for y in range(worker.pos.y - radius, worker.pos.y + radius + 1):
				var candidate := Vector2i(x, y)
				if at.x < 0 and game._walkable(candidate) and game._unit_at(candidate) == -1 and not game._in_district(candidate):
					var route: Array[Vector2i] = game._route_until(worker.pos, func(tile: Vector2i) -> bool: return game._distance(tile, candidate) == 1, true)
					if not route.is_empty() or game._distance(worker.pos, candidate) == 1:
						at = candidate
		if at.x >= 0:
			break
	check(at.x >= 0, "field has a reachable site")
	game._add_balance(Skirmish.HUMAN, "materiales", 20)
	game._add_balance(Skirmish.HUMAN, "varos", 20)
	var before_materiales := game.balance(Skirmish.HUMAN, "materiales")
	var before_varos := game.balance(Skirmish.HUMAN, "varos")
	check(game.issue(Skirmish.HUMAN, "plant", worker_id, at).ok, "worker plants first field")
	check(game.balance(Skirmish.HUMAN, "materiales") == before_materiales - 4 and game.balance(Skirmish.HUMAN, "varos") == before_varos - 2,
		"field costs both resources exactly once")
	check(game.issue(Skirmish.HUMAN, "plant", worker_id, at).ok, "unfinished field can be resumed without a second cost")
	for i in 70:
		game.tick()
	var field: Dictionary = game._field_at(Skirmish.HUMAN, at)
	check(field.progress == Skirmish.FIELD_BUILD_TICKS and field.amount < Skirmish.FIELD_YIELD, "field matures and worker harvests")
	var second := game._add_entity(Skirmish.HUMAN, "worker", worker.pos + Vector2i.RIGHT)
	check(game.issue(Skirmish.HUMAN, "gather", second, at).ok, "second worker can harvest same field")
	var before_harvest: int = field.amount
	for i in 35:
		game.tick()
	check(field.amount < before_harvest, "two workers advance the field harvest")
	var payload := Save.capture(game, "solo_" + "a".repeat(32))
	var restored := Save.restore(payload)
	if not restored.ok:
		printerr("RESTORE: ", restored.reason)
	check(restored.ok and restored.game.food_fields[Skirmish.HUMAN][0].amount == field.amount,
		"food field and assignments survive save restore")
	field.amount = 0
	game.entities[worker_id].carry = 0
	game.entities[worker_id].carry_resource = ""
	check(game.issue(Skirmish.HUMAN, "plant", worker_id, at).ok and field.progress == 0,
		"depleted field can be replanted at the same site")
	var ai = Skirmish.new()
	ai.resource_sources[Skirmish.COMPUTER].comida.amount = 0
	ai.resource_sources[Skirmish.COMPUTER].comida.refreshes_left = 0
	ai._add_balance(Skirmish.COMPUTER, "materiales", 20)
	ai._add_balance(Skirmish.COMPUTER, "varos", 20)
	for i in 280:
		ai.tick()
	check(ai.food_fields[Skirmish.COMPUTER].size() > 0 and ai.food_fields[Skirmish.COMPUTER][0].progress > 0,
		"AI plants after food source exhaustion")
	var replay_game = Skirmish.new()
	var replay_worker: int = replay_game._find(Skirmish.HUMAN, "worker")
	for resource_id in ["materiales", "varos"]:
		var source: Dictionary = replay_game.resource_sources[Skirmish.HUMAN][resource_id]
		check(replay_game.issue(Skirmish.HUMAN, "gather", replay_worker, source.pos).ok,
			"replay worker starts collecting %s" % resource_id)
		var target_balance := 4 if resource_id == "materiales" else 2
		for i in 350:
			if replay_game.balance(Skirmish.HUMAN, resource_id) >= target_balance and replay_game.entities[replay_worker].carry == 0:
				break
			replay_game.tick()
	check(replay_game.issue(Skirmish.HUMAN, "plant", replay_worker, at).ok, "earned resources pay for replay field")
	for i in 75:
		replay_game.tick()
	check(Replay.verify(Replay.record(replay_game)).ok, "normal gathering, planting and harvest replay deterministically")
	check(Save.restore(Save.capture(replay_game, "solo_" + "b".repeat(32))).ok,
		"ordinary field save validates full command history")
	var corrupt: Dictionary = Save.capture(replay_game, "solo_" + "c".repeat(32))
	corrupt.state.food_fields[Skirmish.HUMAN][0].pos = [-1, 0]
	check(Save.restore(corrupt).reason == "state_food_fields_invalid", "invalid planted field is rejected before restore")
	print("Food field checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
