extends SceneTree

const RulesContent = preload("res://rules_content.gd")
const RESOURCES := ["comida", "materiales", "varos", "terrenos"]
const STEPS := [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]
var failed := false

func _initialize() -> void:
	var file := FileAccess.open("res://content/maps/la_roma_large.json", FileAccess.READ)
	check(file != null, "large map overlay exists")
	if file == null:
		quit(1)
		return
	var overlay: Dictionary = JSON.parse_string(file.get_as_text())
	var map: Dictionary = overlay.map
	check(overlay.id == "la_roma_large" and map.width == 96 and map.height == 96, "one 96x96 pilot")
	var content: Dictionary = RulesContent.load_default().data.duplicate(true)
	content.map = map
	for resource_id in RESOURCES:
		content.resources[resource_id].source_positions = overlay.sources[resource_id]
	check(RulesContent.validate(content).ok, "geometry passes current content validator")
	var obstacles: Dictionary = {}
	for point in map.blocked_tiles + map.cliff_tiles:
		obstacles[_point(point)] = true
	var source_tiles: Dictionary = {}
	for group in [overlay.sources, overlay.expansion_sources]:
		for resource_id in RESOURCES:
			check(group.has(resource_id) and group[resource_id].size() == 2, "two symmetric %s positions" % resource_id)
			for point in group[resource_id]:
				source_tiles[_point(point)] = true
	for side in 2:
		var home := _point(map.workers[side])
		var scout := _point(map.scouts[side])
		check(not obstacles.has(home) and not obstacles.has(scout), "side %d starts on open ground" % side)
		for resource_id in RESOURCES:
			var starter := _point(overlay.sources[resource_id][side])
			var expansion := _point(overlay.expansion_sources[resource_id][side])
			var starter_distance := _route_distance(home, starter, obstacles, source_tiles)
			var expansion_distance := _route_distance(home, expansion, obstacles, source_tiles)
			check(starter_distance >= 1 and starter_distance <= 30, "%s side %d starter access" % [resource_id, side])
			check(expansion_distance >= 32 and expansion_distance <= 65, "%s side %d expansion journey" % [resource_id, side])
			if side == 1:
				var other_starter := _route_distance(_point(map.workers[0]), _point(overlay.sources[resource_id][0]), obstacles, source_tiles)
				var other_expansion := _route_distance(_point(map.workers[0]), _point(overlay.expansion_sources[resource_id][0]), obstacles, source_tiles)
				check(starter_distance == other_starter and expansion_distance == other_expansion, "%s travel parity" % resource_id)
		var upper := _point(overlay.expansion_sources.comida[side])
		var lower := _point(overlay.expansion_sources.varos[side])
		check(absi(upper.x - lower.x) + absi(upper.y - lower.y) >= 20, "side %d has distinct expansion choices" % side)
	if not failed:
		print("Large map layout checks: PASS")
	quit(1 if failed else 0)

func _route_distance(start: Vector2i, source: Vector2i, obstacles: Dictionary, source_tiles: Dictionary) -> int:
	var frontier: Array[Vector2i] = [start]
	var distance: Dictionary = {start: 0}
	var index := 0
	while index < frontier.size():
		var tile: Vector2i = frontier[index]
		index += 1
		if absi(tile.x - source.x) + absi(tile.y - source.y) == 1:
			return int(distance[tile])
		for step in STEPS:
			var next: Vector2i = tile + step
			if next.x < 0 or next.y < 0 or next.x >= 96 or next.y >= 96 or obstacles.has(next) or source_tiles.has(next) or distance.has(next):
				continue
			distance[next] = int(distance[tile]) + 1
			frontier.append(next)
	return -1

func _point(raw: Array) -> Vector2i:
	return Vector2i(int(raw[0]), int(raw[1]))

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
