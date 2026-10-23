extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.POBLANOS)
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	check(gather_to(game, worker, "materiales", 6), "materials gathered for construction and training")
	check(gather_to(game, worker, "varos", 9), "cash gathered for construction and training")
	check(gather_to(game, worker, "comida", 2), "food gathered for training")
	check(game.issue(Skirmish.HUMAN, "build", worker,
		{"kind": "barracks", "pos": Skirmish.BARRACKS_POS[Skirmish.HUMAN]}).ok,
		"typed construction command accepted")
	var barracks: int = game._find(Skirmish.HUMAN, "barracks")
	for i in 150:
		if barracks != -1 and game.entities[barracks].complete:
			break
		game.tick()
	check(barracks != -1 and game.entities[barracks].complete, "construction completes")
	if barracks != -1 and game.entities[barracks].complete:
		check(game.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "training command accepted")
	for i in 100:
		game.tick()
	var recording: Dictionary = Replay.record(game)
	check(recording.replay_schema_version == 5, "world replay schema recorded")
	var checked: Dictionary = Replay.verify(recording)
	check(checked.ok and checked.hash == game.state_hash(), "human commands and deterministic AI replay to same state")
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(recording))
	check(Replay.verify(parsed).ok, "versioned replay survives JSON round trip")
	var old: Dictionary = recording.duplicate(true)
	old.replay_schema_version = 1
	check(Replay.verify(old).reason == "unsupported_replay_version", "prior replay rejected explicitly")
	old = recording.duplicate(true)
	old.game_version = "godot-4.7.2-skirmish-5"
	check(Replay.verify(old).reason == "game_version_mismatch", "prior movement rules replay rejected explicitly")
	var altered: Dictionary = recording.duplicate(true)
	altered.checkpoints[0].hash = "0".repeat(64)
	var mismatch: Dictionary = Replay.verify(altered)
	check(not mismatch.ok and mismatch.reason == "checkpoint_mismatch" and mismatch.first_divergent_tick == 50,
		"first divergent checkpoint is reported")
	altered = recording.duplicate(true)
	altered.human_commands[0].target = [3, 3]
	mismatch = Replay.verify(altered)
	check(not mismatch.ok and mismatch.first_divergent_tick == 0, "changed command reports divergence at issue tick")
	altered = recording.duplicate(true)
	var build_index := -1
	for i in altered.human_commands.size():
		if altered.human_commands[i].kind == "build":
			build_index = i
			break
	if build_index != -1:
		altered.human_commands[build_index].target.kind = "unknown_building"
		mismatch = Replay.verify(altered)
		check(not mismatch.ok and mismatch.reason == "replay_history_invalid", "unknown typed building rejected")
	else:
		check(false, "typed building recorded for replay validation")
	altered = JSON.parse_string(JSON.stringify(recording))
	altered.human_commands[0] = null
	mismatch = Replay.verify(altered)
	check(not mismatch.ok and mismatch.reason == "replay_history_invalid", "malformed command is rejected without a runtime error")
	altered = JSON.parse_string(JSON.stringify(recording))
	altered.checkpoints[0] = null
	mismatch = Replay.verify(altered)
	check(not mismatch.ok and mismatch.reason == "replay_history_invalid", "malformed checkpoint is rejected without a runtime error")
	if not failed:
		print("Skirmish replay checks passed: JSON, AI ordering, checkpoints and divergence")
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
	for i in 250:
		if game.balance(Skirmish.HUMAN, resource_id) >= amount:
			return true
		game.tick()
	return false
