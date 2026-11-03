extends SceneTree

const RulesContent = preload("res://rules_content.gd")
const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
var failures := 0

func _initialize() -> void:
	var loaded := RulesContent.load_map("la_roma_medium")
	check(loaded.ok, "medium map validates: " + str(loaded.get("reason", "ok")))
	if not loaded.ok:
		quit(1)
		return
	var game = Skirmish.new(Skirmish.REGIOS, {}, 11, "standard", "la_roma_medium")
	game.ai_enabled = false
	check(game.map_width == 56 and game.map_height == 56, "medium match spans 56×56 tiles")
	check(game.map_sites.size() == 8, "medium map has eight neutral scouted resource sites")
	var repeat = Skirmish.new(Skirmish.REGIOS, {}, 11, "standard", "la_roma_medium")
	var alternate = Skirmish.new(Skirmish.REGIOS, {}, 12, "standard", "la_roma_medium")
	check(game.map_sites.map(func(site: Dictionary) -> Vector2i: return site.pos) == repeat.map_sites.map(func(site: Dictionary) -> Vector2i: return site.pos),
		"the same seed pins resource coordinates")
	check(game.map_sites.map(func(site: Dictionary) -> Vector2i: return site.pos) != alternate.map_sites.map(func(site: Dictionary) -> Vector2i: return site.pos),
		"different seeds move scouted resource coordinates")
	var neutral: Dictionary = game.map_sites[0]
	check(game._resource_at(Skirmish.HUMAN, neutral.pos) == neutral.resource_id and game._resource_at(Skirmish.COMPUTER, neutral.pos) == neutral.resource_id,
		"either side can gather a discovered neutral site")
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		check(game.expansion_sources[side].size() == 4 and game._find(side, "bicitaxi") != -1,
			"each side has four distant resource sites and an opening scout")
		for resource_id in Skirmish.RESOURCE_IDS:
			var starter: Dictionary = game.resource_sources[side][resource_id]
			var expansion: Dictionary = game.expansion_sources[side][resource_id]
			check(game._distance(starter.pos, expansion.pos) >= 12,
				"%s expansion is away from the starting cluster" % resource_id)
	var scout := game._find(Skirmish.HUMAN, "bicitaxi")
	var worker := game._find(Skirmish.HUMAN, "worker")
	check(game.issue(Skirmish.HUMAN, "gather", worker, neutral.pos).reason == "resource_not_discovered",
		"a hidden neutral site cannot be ordered by coordinates")
	check(game.issue(Skirmish.HUMAN, "move", scout, neutral.pos + Vector2i.LEFT).ok,
		"scout can move toward an unknown neutral site")
	for i in 500:
		if game.is_explored(Skirmish.HUMAN, neutral.pos):
			break
		game.tick()
	check(game.is_explored(Skirmish.HUMAN, neutral.pos), "scouting reveals the neutral source")
	check(game.issue(Skirmish.HUMAN, "gather", worker, neutral.pos).ok,
		"a worker can gather the explored neutral source")
	var food: Dictionary = game.expansion_sources[Skirmish.HUMAN].comida
	check(not game.is_explored(Skirmish.HUMAN, food.pos), "food expansion starts behind fog")
	check(game.issue(Skirmish.HUMAN, "move", scout, food.pos + Vector2i.LEFT).ok,
		"scout can route toward a distant food site")
	for i in 500:
		if game.is_explored(Skirmish.HUMAN, food.pos):
			break
		game.tick()
	check(game.is_explored(Skirmish.HUMAN, food.pos), "scout discovers expansion by moving")
	for i in 500:
		if neutral.amount < int(game.content.resources[neutral.resource_id].amount):
			break
		game.tick()
	check(neutral.amount < int(game.content.resources[neutral.resource_id].amount),
		"worker depletes a scouted neutral source")
	var saved := Save.restore(Save.capture(game, "solo_" + "d".repeat(32)))
	check(saved.ok and saved.game.map_id == "la_roma_medium" and saved.game.state_hash() == game.state_hash(),
		"medium match restores with expansion and fog")
	var corrupt: Dictionary = Save.capture(game, "solo_" + "e".repeat(32))
	corrupt.state.map_sites[0].pos = [1, 1]
	check(Save.restore(corrupt).reason == "state_map_sites_invalid", "save rejects forged scouted-site coordinates")
	var large = Skirmish.new(Skirmish.REGIOS, {}, 11, "standard", "la_roma_large")
	var large_other = Skirmish.new(Skirmish.REGIOS, {}, 12, "standard", "la_roma_large")
	check(large.map_sites.size() == 8 and large.map_sites[0].pos != large_other.map_sites[0].pos,
		"large map also has seeded discoverable sites")
	print("Medium map checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
