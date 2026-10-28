extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
const FIXTURE_PATH := "res://tests/fixtures/wonder-cross-platform-hashes.v1.json"
var failed := false

func _initialize() -> void:
	var generating := OS.get_environment("GENERATE_WONDER_HASHES") == "1"
	var fixture: Dictionary = {} if generating else JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	if not generating and (fixture.get("schema_version") != 1 or fixture.get("content_version") != "la-roma-wonder-1"):
		push_error("Wonder cross-platform fixture version mismatch")
		quit(1)
		return
	var cases := {}
	for faction_index in Skirmish.FACTION_IDS.size():
		var faction: String = Skirmish.FACTION_IDS[faction_index]
		var opponent: String = Skirmish.FACTION_IDS[(faction_index + 1) % Skirmish.FACTION_IDS.size()]
		var game = Skirmish.new(faction, {}, 23, "standard", "la_roma", opponent, "", "wonder")
		for n in Skirmish.DRAW_TICK:
			game.tick()
			if game.result != "":
				break
		var key := faction + "_normal_match"
		if game.result == "":
			failed = true
			push_error("Wonder match did not reach a terminal result: " + key)
		cases[key] = game.state_hash()
		print("WONDER_HASH_FIXTURE=", key, ":", cases[key], " terminal=", game.result, "/", game.result_reason, " tick=", game.tick_number)
		if not generating and fixture.cases.get(key) != cases[key]:
			failed = true
			push_error("Wonder cross-platform hash mismatch: " + key)
		if not Replay.verify(Replay.record(game)).ok:
			failed = true
			push_error("Wonder normal-match replay failed: " + key)
	if generating:
		print("WONDER_HASH_JSON=", JSON.stringify({"schema_version": 1, "game_version": Skirmish.GAME_VERSION,
			"content_version": "la-roma-wonder-1", "cases": cases}))
	else:
		print("Wonder cross-platform hashes passed on ", OS.get_name())
	quit(1 if failed else 0)
