extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://multiplayer_replay.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", Skirmish.POBLANOS)
	game.ai_enabled = false
	var first_hash: String = game.state_hash()
	var second_worker: int = game._find(Skirmish.COMPUTER, "worker")
	check(not game.issue(Skirmish.COMPUTER, "train", second_worker, "melee").ok,
		"invalid second-human order rejected")
	check(game.state_hash() == first_hash, "rejected second-human order leaves canonical state unchanged")
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	check(gather_to(game, worker, "materiales", 6), "materials gathered")
	check(gather_to(game, worker, "varos", 12), "cash gathered")
	check(gather_to(game, worker, "comida", 2), "food gathered")
	check(game.issue(Skirmish.HUMAN, "build", worker,
		{"kind": "barracks", "pos": Skirmish.BARRACKS_POS[Skirmish.HUMAN]}).ok, "barracks ordered")
	var barracks: int = game._find(Skirmish.HUMAN, "barracks")
	for i in 200:
		if barracks != -1 and game.entities[barracks].complete:
			break
		game.tick()
	check(barracks != -1 and game.entities[barracks].complete, "barracks completed")
	check(game.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "fighter queued")
	var fighter := -1
	for i in 200:
		fighter = game._find(Skirmish.HUMAN, "melee")
		if fighter != -1:
			break
		game.tick()
	check(fighter != -1, "fighter trained")
	check(game.issue(Skirmish.HUMAN, "move", fighter, Vector2i(9, 10)).ok, "fighter moves to center")
	for i in 1800:
		game.tick()
		if game.result != "":
			break
	if game.result == "":
		printerr("center diagnostic: pos=", game.entities[fighter].pos, " job=", game.entities[fighter].job,
			" district=", game.district_state, " progress=", game.district_progress)
	check(game.result == "win", "unopposed center hold finishes")
	var commands: Array = game.command_log.duplicate(true)
	var recording := {"format": "battle-for-la-roma-multiplayer-replay", "replay_schema_version": 1,
		"match_id": "online_" + "a".repeat(32), "game_version": Skirmish.GAME_VERSION,
		"content_version": Skirmish.CONTENT_VERSION, "content_hash": game.content_hash,
		"map_id": game.map_id, "factions": [game.factions[0], game.factions[1]], "initial_seed": 1,
		"end_tick": game.tick_number, "commands": commands,
		"checkpoints": [{"tick": 0, "hash": first_hash}],
		"expected_hash": game.state_hash(), "terminal": {"tick": game.tick_number,
		"reason": game.result_reason, "results": ["win", "loss"], "hash": game.state_hash()}}
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(recording))
	var checked: Dictionary = Replay.verify(parsed)
	check(checked.ok, "serialized two-sided replay reproduces result: " + str(checked.get("reason", "")))
	var fixture_path := OS.get_environment("AOMX_TEST_REPLAY_OUTPUT")
	if checked.ok and not fixture_path.is_empty():
		var fixture := FileAccess.open(fixture_path, FileAccess.WRITE)
		check(fixture != null, "replay fixture opened")
		if fixture != null:
			fixture.store_string(JSON.stringify(parsed))
			fixture.close()
	var altered: Dictionary = parsed.duplicate(true)
	altered.checkpoints[0].hash = "0".repeat(64)
	var divergent: Dictionary = Replay.verify(altered)
	check(not divergent.ok and divergent.first_divergent_tick == 0, "first divergent tick reported")
	altered = parsed.duplicate(true)
	altered.replay_schema_version = 99
	check(Replay.verify(altered).reason == "unsupported_replay_version", "unsupported version rejected")
	if not failed:
		print("Multiplayer replay checks passed: terminal, JSON, divergence, version")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true

func gather_to(game: RefCounted, worker: int, resource_id: String, amount: int) -> bool:
	for i in 100:
		if game.entities[worker].carry == 0:
			break
		game.tick()
	var source: Dictionary = game.resource_sources[Skirmish.HUMAN][resource_id]
	if not game.issue(Skirmish.HUMAN, "gather", worker, source.pos).ok:
		return false
	for i in 300:
		if game.balance(Skirmish.HUMAN, resource_id) >= amount:
			return true
		game.tick()
	return false
