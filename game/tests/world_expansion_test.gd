extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var hashes: Dictionary = {}
	for map_id in RulesContent.MAP_IDS:
		var loaded: Dictionary = RulesContent.load_map(map_id)
		check(loaded.ok, "valid authored map " + map_id)
		if not loaded.ok:
			continue
		hashes[map_id] = loaded.hash
		if map_id != "la_roma":
			var route_game = Skirmish.new(Skirmish.REGIOS, {}, 41, "standard", map_id)
			for resource_id in Skirmish.RESOURCE_IDS:
				var distances: Array[int] = []
				for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
					var source_tile: Vector2i = route_game.resource_sources[side][resource_id].pos
					var worker_tile: Vector2i = route_game.entities[route_game._find(side, "worker")].pos
					# Legacy maps retain their original fixture; the large-map layout test measures real adjacent routes.
					distances.append(route_game._route_until(worker_tile, func(tile: Vector2i) -> bool: return tile == source_tile).size())
				check(absi(distances[0] - distances[1]) <= 1, "comparable opening route: " + map_id + "/" + resource_id)
		for i in Skirmish.FACTION_IDS.size():
			var faction: String = Skirmish.FACTION_IDS[i]
			var mirror = Skirmish.new(faction, {}, 41, "standard", map_id, faction)
			check(mirror.factions[Skirmish.HUMAN] == mirror.factions[Skirmish.COMPUTER] and Save.restore(Save.capture(mirror, "solo_0123456789abcdef0123456789abcdef")).ok and Replay.verify(Replay.record(mirror)).ok,
				"mirror match saves and replays: " + map_id + "/" + faction)
			var opponent: String = Skirmish.FACTION_IDS[(i + 1) % Skirmish.FACTION_IDS.size()]
			for level in Skirmish.AI_LEVELS:
				var game = Skirmish.new(faction, {}, 41, level, map_id, opponent)
				var label: String = map_id + "/" + faction + "/" + level
				check(game.map_id == map_id and game.factions[Skirmish.COMPUTER] == opponent, "match pins choices: " + label)
				var worker: int = game._find(Skirmish.HUMAN, "worker")
				check(game.issue(Skirmish.HUMAN, "gather", worker, game.sources[Skirmish.HUMAN].pos).ok, "gather order: " + label)
				for tick in 80:
					game.tick()
				check(Save.restore(Save.capture(game, "solo_0123456789abcdef0123456789abcdef")).ok, "save round trip: " + label)
				check(Replay.verify(Replay.record(game)).ok, "replay round trip: " + label)
				var conquest = Skirmish.new(faction, {}, 41, level, map_id, opponent)
				conquest.ai_enabled = false
				conquest.entities[conquest._find(Skirmish.COMPUTER, "command_post")].hp = 0
				conquest.tick()
				check(conquest.result == "win" and conquest.result_reason == "command_post", "conquest terminal: " + label)
				var hold = Skirmish.new(faction, {}, 41, level, map_id, opponent)
				hold.ai_enabled = false
				hold._add_entity(Skirmish.HUMAN, "melee", Vector2i(int(hold.content.map.district_min[0]) + 1, int(hold.content.map.district_min[1]) + 1))
				hold.district_side = Skirmish.HUMAN
				hold.district_progress = int(hold.content.objectives.district_hold_ticks) - 1
				hold.tick()
				check(hold.result == "win" and hold.result_reason == "district", "center-hold terminal: " + label)
	check(hashes.size() == 4 and hashes.la_roma != hashes.narvarte and hashes.narvarte != hashes.copilco and hashes.copilco != hashes.la_roma_large,
		"map choices pin distinct content hashes")
	var oax = Skirmish.new(Skirmish.OAXAQUENOS)
	var ver = Skirmish.new(Skirmish.VERACRUZANOS)
	check(oax.content.factions.oaxaquenos.gather_ticks < oax.content.factions.regios.gather_ticks and oax._starting_health(Skirmish.HUMAN, "command_post") < Skirmish.new()._starting_health(Skirmish.HUMAN, "command_post"), "Oaxaqueños gain gathering and concede post health")
	check(ver.content.factions.veracruzanos.move_ticks < ver.content.factions.regios.move_ticks and ver._starting_health(Skirmish.HUMAN, "command_post") < Skirmish.new()._starting_health(Skirmish.HUMAN, "command_post"), "Veracruzanos gain movement and concede post health")
	for faction in [Skirmish.OAXAQUENOS, Skirmish.VERACRUZANOS]:
		var game = Skirmish.new(faction)
		game.ai_enabled = false
		game.age_index[Skirmish.HUMAN] = 1
		for resource_id in Skirmish.RESOURCE_IDS:
			game._add_balance(Skirmish.HUMAN, resource_id, 100)
		var registry: int = game._add_entity(Skirmish.HUMAN, "registry", Vector2i(3, 7))
		var own_tech := "cooperative_build_i" if faction == Skirmish.OAXAQUENOS else "street_exchange_i"
		var other_tech := "street_exchange_i" if faction == Skirmish.OAXAQUENOS else "cooperative_build_i"
		check(game.issue(Skirmish.HUMAN, "research", registry, other_tech).reason == "faction_tech_unavailable", "cross-faction tech rejected: " + faction)
		check(game.issue(Skirmish.HUMAN, "research", registry, own_tech).ok, "legal faction research queued: " + faction)
		for tick in 60:
			game.tick()
		check(own_tech in game.researched[Skirmish.HUMAN], "faction tech completes: " + faction)
		if faction == Skirmish.OAXAQUENOS:
			check(game._construction_rate(Skirmish.HUMAN) == 2, "cooperative construction increases support rate")
		else:
			var worker: int = game._find(Skirmish.HUMAN, "worker")
			game.entities[worker].pos = Vector2i(4, 3)
			game.entities[worker].carry = 1
			game.entities[worker].carry_resource = "comida"
			game.entities[worker].job = "deliver"
			var before: int = game.balance(Skirmish.HUMAN, "varos")
			game.tick()
			check(game.balance(Skirmish.HUMAN, "varos") == before + 1, "trade bonus pays on a non-Varos delivery")
		var wrong: Dictionary = Save.capture(game, "solo_0123456789abcdef0123456789abcdef")
		wrong.state.researched[0].append(other_tech)
		check(Save.restore(wrong).reason == "state_researched_invalid", "save rejects another faction's tech")
	var invalid: Dictionary = RulesContent.load_default().data.duplicate(true)
	invalid.map_id = "unknown"
	check(RulesContent.validate(invalid).reason == "map_id_invalid", "unknown map rejected")
	invalid = RulesContent.load_map("narvarte").data.duplicate(true)
	invalid.resources.varos.source_positions[0] = invalid.map.blocked_tiles[0]
	check(RulesContent.validate(invalid).reason == "inaccessible_varos_source", "blocked map resource rejected")
	if not failed:
		print("World expansion checks passed: 4 factions x 4 maps x 3 AI levels, both terminals, save and replay")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
