extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
const FIXTURE_PATH := "res://tests/fixtures/cross-platform-hashes.v3.json"
var failed := false

func _initialize() -> void:
	var fixture: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE_PATH))
	check(fixture.schema_version == 3 and fixture.content_version == Skirmish.CONTENT_VERSION,
		"hash fixture is pinned to warfare content version")
	for faction in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		var game = Skirmish.new(faction)
		var worker: int = game._find(Skirmish.HUMAN, "worker")
		check(game.issue(Skirmish.HUMAN, "gather", worker, game.sources[Skirmish.HUMAN].pos).ok,
			"opening command for " + faction)
		var switched := false
		for n in 700:
			game.tick()
			if game.tick_number >= 250 and not switched and game.entities[worker].carry == 0:
				var material_source: Dictionary = game.resource_sources[Skirmish.HUMAN].materiales
				switched = game.issue(Skirmish.HUMAN, "gather", worker, material_source.pos).ok
		check(switched and game.balance(Skirmish.HUMAN, "varos") > 0 and game.balance(Skirmish.HUMAN, "materiales") > 0,
			"human changes physical resource route during AI progression for " + faction)
		var key: String = faction + "_700"
		var hash: String = game.state_hash()
		print("HASH_FIXTURE=%s:%s" % [key, hash])
		check(fixture.cases.get(key) == hash, "cross-platform hash matches pinned fixture for " + key)
		check(Replay.verify(Replay.record(game)).ok, "long command and AI replay for " + faction)
	if not failed:
		print("Cross-platform hash fixtures passed on " + OS.get_name())
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
