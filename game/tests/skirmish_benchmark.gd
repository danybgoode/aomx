extends SceneTree

const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	var game = Skirmish.new()
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		for i in range(5):
			game._add_entity(side, "melee" if i % 2 == 0 else "ranged",
				Vector2i(3 + i, 8) if side == Skirmish.HUMAN else Vector2i(12 + i, 12))
	var ids: Array = game.entities.keys()
	ids.sort()
	var began := Time.get_ticks_usec()
	var accepted := 0
	for i in range(500):
		for id in ids:
			var e: Dictionary = game.entities[id]
			if e.kind in ["melee", "ranged"]:
				var target: Vector2i = Vector2i(9, 10) if i % 2 == 0 else e.pos
				if game.issue(e.side, "move", id, target).ok:
					accepted += 1
	var path_ms := float(Time.get_ticks_usec() - began) / 1000.0
	# A fresh simulation avoids queued commands changing the tick workload.
	game = Skirmish.new()
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		for i in range(5):
			game._add_entity(side, "melee" if i % 2 == 0 else "ranged",
				Vector2i(3 + i, 8) if side == Skirmish.HUMAN else Vector2i(12 + i, 12))
	began = Time.get_ticks_usec()
	for i in range(1000):
		game.tick()
	var tick_ms := float(Time.get_ticks_usec() - began) / 1000.0
	print("scale=12 units, 20x20 map; 5000 route attempts accepted=%d total_ms=%.3f mean_ms=%.4f; 1000 ticks total_ms=%.3f mean_ms=%.4f" % [accepted, path_ms, path_ms / 5000.0, tick_ms, tick_ms / 1000.0])
	quit(0)
