extends SceneTree

const RulesContent = preload("res://rules_content.gd")
const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
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
	var loaded: Dictionary = RulesContent.load_map("la_roma_large")
	check(loaded.ok and loaded.data.map_id == "la_roma_large" and loaded.data.units.has("bicitaxi"), "large map and scout pass versioned content validator")
	var match_game = Skirmish.new(Skirmish.REGIOS, {}, 41, "standard", "la_roma_large")
	check(match_game.map_width == 96 and match_game.map_height == 96, "large map starts in simulation")
	for side in 2:
		var scout_id: int = match_game._find(side, "bicitaxi")
		check(scout_id != -1 and match_game.entities[scout_id].pos == _point(map.scouts[side]), "side %d starts with bicitaxi" % side)
		if side == Skirmish.HUMAN:
			check(match_game.issue(side, "attack", scout_id, match_game._find(1 - side, "command_post")).reason == "combat_unit_and_target_required", "bicitaxi cannot attack")
			check(match_game.issue(side, "gather", scout_id, _point(overlay.sources.comida[side])).reason == "resource_unavailable", "bicitaxi cannot gather")
			check(match_game.issue(side, "build", scout_id, Vector2i(30, 30)).reason == "worker_required", "bicitaxi cannot build")
		check(match_game.expansion_sources[side].size() == RESOURCES.size(), "side %d has four expansion sites" % side)
	var human_worker: int = match_game._find(Skirmish.HUMAN, "worker")
	var food_expansion: Dictionary = match_game.expansion_sources[Skirmish.HUMAN].comida
	var original_amount: int = food_expansion.amount
	check(match_game.issue(Skirmish.HUMAN, "gather", human_worker, food_expansion.pos).ok, "worker can target a distant expansion")
	for i in 300:
		match_game.tick()
	check(food_expansion.amount < original_amount and match_game.resource_sources[Skirmish.HUMAN].comida.amount == int(loaded.data.resources.comida.amount),
		"distant source gathers independently of the starter site")
	var saved: Dictionary = Save.restore(Save.capture(match_game, "solo_0123456789abcdef0123456789abcdef"))
	check(saved.ok and saved.game.state_hash() == match_game.state_hash(), "large expansion amounts survive save and resume")
	var replayed: Dictionary = Replay.verify(Replay.record(match_game))
	if not replayed.ok:
		printerr("Large map replay: ", replayed)
	check(replayed.ok and replayed.hash == match_game.state_hash(), "large map scout and expansion command replay deterministically")
	var ai_game = Skirmish.new(Skirmish.REGIOS, {}, 42, "standard", "la_roma_large")
	var ai_scout_id: int = ai_game._find(Skirmish.COMPUTER, "bicitaxi")
	ai_game._ai_step()
	check(ai_game.entities[ai_scout_id].job == "move" and not ai_game.entities[ai_scout_id].path.is_empty(),
		"computer bicitaxi receives a legal opening scout route")
	var ai_food: Dictionary = ai_game.expansion_sources[Skirmish.COMPUTER].comida
	ai_game.entities[ai_scout_id].pos = ai_food.pos + Vector2i(1, 0)
	ai_game._refresh_visibility()
	check(ai_game.is_explored(Skirmish.COMPUTER, ai_food.pos), "scout reveals expansion through ordinary sight")
	for resource_id in RESOURCES:
		ai_game.resource_sources[Skirmish.COMPUTER][resource_id].amount = 0
		ai_game.resource_sources[Skirmish.COMPUTER][resource_id].refreshes_left = 0
		if resource_id != "comida":
			ai_game.expansion_sources[Skirmish.COMPUTER][resource_id].amount = 0
	var ai_worker_id: int = ai_game._find(Skirmish.COMPUTER, "worker")
	ai_game.entities[ai_worker_id].job = "idle"
	ai_game.entities[ai_worker_id].path.clear()
	ai_game._ai_step()
	check(ai_game.entities[ai_worker_id].job == "gather" and ai_game.entities[ai_worker_id].order_pos == ai_food.pos,
		"computer gathers from a scouted expansion when starter sources expire")
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
