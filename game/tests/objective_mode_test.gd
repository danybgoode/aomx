extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var conquest = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", "", "", "conquest")
	conquest.ai_enabled = false
	conquest._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
	for i in Skirmish.HOLD_TICKS + 1:
		conquest.tick()
	check(conquest.result == "" and conquest.district_progress == 0, "Conquest excludes center victory")
	check(conquest.snapshot().objective_id == "conquest", "Conquest identity is canonical")
	var match_id := "solo_0123456789abcdef0123456789abcdef"
	var payload := Save.capture(conquest, match_id)
	var restored := Save.restore(payload)
	check(restored.ok and restored.game.objective_id == "conquest" and restored.game.state_hash() == conquest.state_hash(), "Conquest save restores mode and hash")
	var replay_game = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", "", "", "conquest")
	for i in 30:
		replay_game.tick()
	var recording := Replay.record(replay_game)
	var verified := Replay.verify(recording)
	check(verified.ok and verified.game.objective_id == "conquest", "Conquest replay verifies")
	var malformed := payload.duplicate(true)
	malformed.state.objective_id = "unknown"
	check(Save.restore(malformed).reason == "state_objective_invalid", "unknown objective rejected")
	conquest.entities[conquest._find(Skirmish.COMPUTER, "command_post")].hp = 0
	conquest.tick()
	check(conquest.result == "win" and conquest.result_reason == "command_post", "post remains Conquest finish")
	var legacy = Skirmish.new()
	check(not legacy.snapshot().has("objective_id"), "legacy snapshot has no new field")
	if failed:
		quit(1)
	else:
		print("Objective mode checks passed: choice, terminal, save, replay, legacy")
		quit(0)

func check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error(description)
