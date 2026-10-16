extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	for human_faction in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		var game = Skirmish.new(human_faction)
		var other := Skirmish.POBLANOS if human_faction == Skirmish.REGIOS else Skirmish.REGIOS
		check(game.factions[Skirmish.HUMAN] == human_faction and game.factions[Skirmish.COMPUTER] == other,
			"choice gives the opponent the other faction")
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var expected_post := 60 if game.factions[side] == Skirmish.POBLANOS else 50
			check(game.entities[game._find(side, "command_post")].hp == expected_post,
				"command post health follows faction on either side")
			var expected_carry := 5 if game.factions[side] == Skirmish.REGIOS else 4
			check(game._carry_limit(side) == expected_carry, "worker carry follows faction on either side")
			var barracks := game._add_entity(side, "barracks", Skirmish.BARRACKS_POS[side])
			var expected_barracks := 36 if game.factions[side] == Skirmish.POBLANOS else 30
			check(game.entities[barracks].hp == expected_barracks,
				"recruitment post health follows faction on either side")
			game.stockpile[side] = 20
			var melee_cost := 4 if game.factions[side] == Skirmish.REGIOS else 3
			var ranged_cost := 5 if game.factions[side] == Skirmish.REGIOS else 4
			check(game.issue(side, "train", barracks, "melee").ok and game.stockpile[side] == 20 - melee_cost,
				"melee cost charged for selected faction")
			check(game.issue(side, "train", barracks, "ranged").ok and game.stockpile[side] == 20 - melee_cost - ranged_cost,
				"ranged cost charged for selected faction")
		var replay_a = Skirmish.new(human_faction)
		var replay_b = Skirmish.new(human_faction)
		for copy in [replay_a, replay_b]:
			copy.issue(Skirmish.HUMAN, "gather", copy._find(Skirmish.HUMAN, "worker"),
				Skirmish.RESOURCE_POS[Skirmish.HUMAN])
			for i in range(320):
				copy.tick()
		check(replay_a.state_hash() == replay_b.state_hash() and replay_a.command_log == replay_b.command_log,
			"faction rules retain deterministic replay")
		check(replay_a.stockpile[Skirmish.HUMAN] >= (5 if human_faction == Skirmish.REGIOS else 4),
			"worker delivers the faction amount")
	if not failed:
		print("Faction checks passed: choice, health, carry, costs, deterministic replay")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
