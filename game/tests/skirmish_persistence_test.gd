extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.POBLANOS)
	var match_id := "solo_0123456789abcdef0123456789abcdef"
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	check(game.issue(Skirmish.HUMAN, "gather", worker, game.sources[Skirmish.HUMAN].pos).ok,
		"valid current-match command")
	for i in 85:
		game.tick()
	var path := "user://skirmish-save-check-%d.json" % Time.get_ticks_usec()
	var saved: Dictionary = Save.write(game, match_id, false, path)
	check(saved.ok and FileAccess.file_exists(path), "versioned save written")
	var resumed: Dictionary = Save.read(path)
	check(resumed.ok, "saved match loaded")
	if resumed.ok:
		check(resumed.game.state_hash() == game.state_hash() and resumed.match_id == match_id,
			"canonical state and match identity round trip")
		for i in 150:
			game.tick()
			resumed.game.tick()
		check(resumed.game.state_hash() == game.state_hash(), "resumed play stays deterministic")
	var corrupt: Dictionary = Save.capture(game, match_id)
	corrupt.state.entities[0].kind = "bogus"
	check(Save.restore(corrupt).reason == "state_entity_kind_invalid", "unknown saved content ID rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.save_schema_version = 99
	check(Save.restore(corrupt).reason == "unsupported_save_version", "unsupported old or future save rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.content_hash = "different"
	check(Save.restore(corrupt).reason == "content_version_mismatch", "different content rejected")
	var before := FileAccess.get_file_as_string(path)
	var bad_path := "user://skirmish-corrupt-check-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(bad_path, FileAccess.WRITE)
	file.store_string("{ broken")
	file.close()
	check(Save.read(bad_path).reason == "save_corrupt", "malformed JSON rejected")
	check(FileAccess.get_file_as_string(path) == before and FileAccess.file_exists(bad_path),
		"rejected data preserved without modifying valid save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad_path))
	if not failed:
		print("Skirmish persistence checks passed: round trip, continuation, version and corruption")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
