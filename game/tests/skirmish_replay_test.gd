extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.POBLANOS)
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	check(game.issue(Skirmish.HUMAN, "gather", worker, game.sources[Skirmish.HUMAN].pos).ok,
		"opening command accepted")
	for i in 250:
		game.tick()
	check(game.stockpile[Skirmish.HUMAN] >= 6, "gathering supports construction")
	check(game.issue(Skirmish.HUMAN, "build", worker, Skirmish.BARRACKS_POS[Skirmish.HUMAN]).ok,
		"construction command accepted")
	for i in 150:
		game.tick()
	var barracks: int = game._find(Skirmish.HUMAN, "barracks")
	check(game.entities[barracks].complete, "construction completes")
	if game.stockpile[Skirmish.HUMAN] >= game._cost(Skirmish.HUMAN, "melee"):
		check(game.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "training command accepted")
	for i in 250:
		game.tick()
	var recording: Dictionary = Replay.record(game)
	var checked: Dictionary = Replay.verify(recording)
	check(checked.ok and checked.hash == game.state_hash(), "human commands and deterministic AI replay to same state")
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(recording))
	check(Replay.verify(parsed).ok, "versioned replay survives JSON round trip")
	var altered: Dictionary = recording.duplicate(true)
	altered.checkpoints[0].hash = "0".repeat(64)
	var mismatch: Dictionary = Replay.verify(altered)
	check(not mismatch.ok and mismatch.reason == "checkpoint_mismatch" and mismatch.first_divergent_tick == 50,
		"first divergent checkpoint is reported")
	altered = recording.duplicate(true)
	altered.human_commands[0].target = [3, 3]
	mismatch = Replay.verify(altered)
	check(not mismatch.ok and mismatch.first_divergent_tick == 0, "changed command reports divergence at issue tick")
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
