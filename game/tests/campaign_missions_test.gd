extends SceneTree

const CampaignMissions = preload("res://campaign_missions.gd")
const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var loaded := CampaignMissions.load_manifest()
	check(loaded.ok and loaded.data.missions.size() == 3, "three versioned missions load")
	if not loaded.ok:
		quit(1)
		return
	var invalid: Dictionary = loaded.data.duplicate(true)
	invalid.missions[1].prerequisite = "battle_la_roma"
	check(CampaignMissions.validate(invalid).reason == "mission_prerequisite_invalid", "prerequisite cycle rejected")
	invalid = loaded.data.duplicate(true)
	invalid.missions[0].steps[0].amount = 100000
	check(CampaignMissions.validate(invalid).reason == "mission_condition_invalid", "unbounded condition rejected")
	invalid = loaded.data.duplicate(true)
	invalid.missions[0].steps[1].kind = "execute_script"
	check(CampaignMissions.validate(invalid).reason == "mission_step_invalid", "arbitrary action rejected")
	var ordinary = Skirmish.new()
	check(not ordinary.snapshot().has("mission_id"), "ordinary skirmish snapshot unchanged")
	var game = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner", "copilco", "", "arrival_copilco")
	game.ai_enabled = false
	game.stockpile[Skirmish.HUMAN] = 4
	game.tick()
	check(game.mission_steps == ["gather"] and game.mission_result == "", "gather goal advances once")
	var post := game._add_entity(Skirmish.HUMAN, "barracks", Vector2i(5, 6))
	game.entities[post].complete = true
	game.tick()
	check(game.mission_steps == ["gather", "build"], "construction goal advances")
	var fighter := game._add_entity(Skirmish.HUMAN, "melee", Vector2i(6, 7))
	game.entities[fighter].complete = true
	game.tick()
	check(game.mission_steps == ["gather", "build", "recruit"] and game.mission_result == "win", "tutorial terminal is deterministic")
	var terminal_tick: int = game.tick_number
	game.tick()
	check(game.tick_number == terminal_tick, "completed tutorial cannot advance again")
	var match_id := "solo_0123456789abcdef0123456789abcdef"
	var saved := Save.capture(game, match_id)
	var restored := Save.restore(saved)
	check(restored.ok, "mission state restores")
	if restored.ok:
		check(restored.game.mission_id == "arrival_copilco" and restored.game.mission_result == "win" and restored.game.state_hash() == game.state_hash(), "mission hash and result survive restore")
	var bad: Dictionary = saved.duplicate(true)
	bad.state.mission_hash = "0".repeat(64)
	check(Save.restore(bad).reason == "state_mission_invalid", "changed mission definition rejected")
	bad = saved.duplicate(true)
	bad.state.mission_steps = ["recruit"]
	check(Save.restore(bad).reason == "state_mission_invalid", "out-of-order mission progress rejected")
	var played = Skirmish.new(Skirmish.POBLANOS, {}, 1, "learner", "copilco", "", "arrival_copilco")
	var worker: int = played._find(Skirmish.HUMAN, "worker")
	check(gather_to(played, worker, "materiales", 6), "real material gathering")
	check(gather_to(played, worker, "varos", 9), "real cash gathering")
	check(gather_to(played, worker, "comida", 2), "real food gathering")
	var build_pos: Vector2i = played._point(played.content.map.barracks_positions[Skirmish.HUMAN])
	check(played.issue(Skirmish.HUMAN, "build", worker, {"kind": "barracks", "pos": build_pos}).ok, "real construction order")
	var barracks: int = played._find(Skirmish.HUMAN, "barracks")
	for i in 150:
		if barracks != -1 and played.entities[barracks].complete:
			break
		played.tick()
	check(barracks != -1 and played.entities[barracks].complete, "real construction finishes")
	if barracks != -1 and played.entities[barracks].complete:
		check(played.issue(Skirmish.HUMAN, "train", barracks, "melee").ok, "real training order")
	for i in 150:
		if played.mission_result != "":
			break
		played.tick()
	check(played.mission_result == "win", "real orders finish tutorial")
	var recording := Replay.record(played)
	check(Replay.verify(recording).ok, "real mission replays with matching canonical hash")
	var wrong_mission: Dictionary = recording.duplicate(true)
	wrong_mission.mission_hash = "0".repeat(64)
	check(Replay.verify(wrong_mission).reason == "mission_version_mismatch", "changed mission replay rejected")
	if not failed:
		print("Campaign mission checks passed: manifest, fixed ticks, terminal and save validation")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAIL: ", label)

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
