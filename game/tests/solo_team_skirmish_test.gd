extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failures := 0

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.REGIOS, {}, 23, "standard", "la_roma_large", Skirmish.POBLANOS, "", "conquest", true)
	check(game.team_mode and game._sides().size() == 4 and game.map_width == 96, "four sides play on the large map")
	for side in game._sides():
		check(game._find(side, "command_post") != -1 and game._find(side, "worker") != -1 and game._find(side, "bicitaxi") != -1,
			"side %d has its own base, worker and scout" % side)
		check(game.resource_sources[side].size() == 4 and game.expansion_sources[side].size() == 4,
			"side %d has separate starter and expansion resources" % side)
		var home_worker: Dictionary = game.entities[game._find(side, "worker")]
		for resource_id in Skirmish.RESOURCE_IDS:
			var source: Dictionary = game.resource_sources[side][resource_id]
			var route: Array[Vector2i] = game._route_until(home_worker.pos, func(tile: Vector2i) -> bool: return game._distance(tile, source.pos) == 1)
			check(not game._wall(source.pos) and (not route.is_empty() or game._distance(home_worker.pos, source.pos) == 1),
				"side %d can reach its %s starter source" % [side, resource_id])
	var human_post := game._find(Skirmish.HUMAN, "command_post")
	var ally_post := game._find(Skirmish.ALLY, "command_post")
	var enemy_post := game._find(Skirmish.COMPUTER, "command_post")
	var other_enemy_post := game._find(Skirmish.SECOND_OPPONENT, "command_post")
	check(game._is_enemy(Skirmish.HUMAN, Skirmish.COMPUTER) and not game._is_enemy(Skirmish.HUMAN, Skirmish.ALLY),
		"team membership defines hostility")
	check(game.is_visible(Skirmish.HUMAN, game.entities[ally_post].pos), "allied vision is shared")
	game.ai_enabled = false
	game.entities[enemy_post].hp = 0
	game.tick()
	check(game.result == "", "one destroyed opposing post does not end 2v2")
	game.entities[other_enemy_post].hp = 0
	game.tick()
	check(game.result == "win" and game.entities[human_post].hp > 0 and game.entities[ally_post].hp > 0,
		"both opposing posts must fall for a team win")
	var diplomacy = Skirmish.new(Skirmish.OAXAQUENOS, {}, 33, "standard", "la_roma_large", Skirmish.VERACRUZANOS, "", "conquest", true)
	var fighter := diplomacy._add_entity(Skirmish.HUMAN, "melee", Vector2i(16, 13))
	check(diplomacy.issue(Skirmish.HUMAN, "attack", fighter, diplomacy._find(Skirmish.ALLY, "worker")).reason == "invalid_enemy_target",
		"player cannot attack an ally")
	var active = Skirmish.new(Skirmish.OAXAQUENOS, {}, 33, "standard", "la_roma_large", Skirmish.VERACRUZANOS, "", "conquest", true)
	for i in 160:
		active.tick()
	for side in [Skirmish.COMPUTER, Skirmish.ALLY, Skirmish.SECOND_OPPONENT]:
		check(active.command_log.any(func(command: Dictionary) -> bool: return command.side == side),
			"AI side %d issues independent orders" % side)
	var saved := Save.restore(Save.capture(active, "solo_" + "f".repeat(32)))
	check(saved.ok and saved.game.state_hash() == active.state_hash(), "four-side save restores exactly")
	var tampered := Save.capture(active, "solo_" + "e".repeat(32))
	tampered.state.factions[2] = Skirmish.POBLANOS
	check(Save.restore(tampered).reason == "state_factions_invalid", "save rejects a forged ally faction")
	var verified := Replay.verify(Replay.record(active))
	check(verified.ok and verified.hash == active.state_hash(), "four-side replay reconstructs the match")
	print("Solo 2v2 checks: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(1 if failures else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failures += 1
