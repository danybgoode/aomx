extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failures := 0

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.REGIOS, {}, 17, "standard", "la_roma_large")
	game.ai_enabled = false
	var workers: Array[int] = [game._find(Skirmish.HUMAN, "worker")]
	for y in range(6, 16):
		for x in range(5, 18):
			var tile := Vector2i(x, y)
			if workers.size() >= 16:
				break
			if game._walkable(tile) and game._unit_at(tile) == -1:
				workers.append(game._add_entity(Skirmish.HUMAN, "worker", tile))
		if workers.size() >= 16:
			break
	check(workers.size() == 16, "crowd scenario starts sixteen separate workers")
	for i in workers.size():
		var resource_id := "comida" if i < 8 else "materiales"
		var source: Dictionary = game.resource_sources[Skirmish.HUMAN][resource_id]
		check(game.issue(Skirmish.HUMAN, "gather", workers[i], source.pos).ok,
			"worker %d accepts an independent gather order" % i)
	for tick in 1200:
		game.tick()
	for id in ["comida", "materiales"]:
		check(game.balance(Skirmish.HUMAN, id) == 80,
			"crowded %s workers deliver the entire starter source" % id)
	var stalled := 0
	for worker_id in workers:
		if game.entities[worker_id].blocked_ticks >= 90:
			stalled += 1
	check(stalled == 0, "no worker remains blocked after a crowded source is mined")
	print("Crowded worker income checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
