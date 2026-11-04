extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
var failures := 0

func _initialize() -> void:
	for map_id in ["la_roma", "narvarte", "copilco"]:
		var loaded := RulesContent.load_map(map_id)
		check(loaded.ok, "%s authored map validates" % map_id)
		if not loaded.ok:
			continue
		var game = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", map_id)
		game.ai_enabled = false
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var positions: Array[Vector2i] = []
			var worker: Dictionary = game.entities[game._find(side, "worker")]
			for resource_id in Skirmish.RESOURCE_IDS:
				var source: Dictionary = game.resource_sources[side][resource_id]
				positions.append(source.pos)
				var route: Array[Vector2i] = game._route_until(worker.pos, func(tile: Vector2i) -> bool: return game._distance(tile, source.pos) == 1)
				check(not game._wall(source.pos) and (not route.is_empty() or game._distance(worker.pos, source.pos) == 1),
					"%s side %d can reach %s" % [map_id, side, resource_id])
			for a in positions.size():
				for b in range(a + 1, positions.size()):
					check(game._distance(positions[a], positions[b]) >= 4,
						"%s side %d resource sites are spaced apart" % [map_id, side])
	print("Small resource spacing checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
