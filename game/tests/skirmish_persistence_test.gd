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
	# Exercise restoration of nonzero strategic state, including a source mid-refresh.
	game.other_stockpiles[Skirmish.HUMAN].comida = 7
	game.other_stockpiles[Skirmish.HUMAN].materiales = 6
	game.other_stockpiles[Skirmish.HUMAN].terrenos = 5
	game.age_index[Skirmish.HUMAN] = 1
	game.researched[Skirmish.HUMAN] = ["carry_capacity_i"]
	game.resource_sources[Skirmish.HUMAN].terrenos.amount = 0
	game.resource_sources[Skirmish.HUMAN].terrenos.refresh_remaining = 12
	game.resource_sources[Skirmish.HUMAN].terrenos.refreshes_left = 3
	var post: int = game._find(Skirmish.HUMAN, "command_post")
	game.entities[post].queue.append({"kind": "unit", "role": "worker", "remaining": 20})
	var path := "user://skirmish-save-check-%d.json" % Time.get_ticks_usec()
	var saved: Dictionary = Save.write(game, match_id, false, path)
	check(saved.ok and FileAccess.file_exists(path), "versioned save written")
	var snapshot: Dictionary = game.snapshot()
	check(snapshot.state_schema_version == 5 and snapshot.map_id == "la_roma" and snapshot.balances.size() == 2
		and snapshot.resource_sources.size() == 2 and snapshot.age_index.size() == 2
		and snapshot.researched.size() == 2 and snapshot.balances[0].terrenos == 5
		and snapshot.resource_sources[0].terrenos.refresh_remaining == 12
		and snapshot.age_index[0] == 1 and snapshot.researched[0] == ["carry_capacity_i"]
		and snapshot.entities[0].queue[0].kind == "unit",
		"nonzero strategic state captured")
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
	corrupt.save_schema_version = 1
	check(Save.restore(corrupt).reason == "unsupported_save_version", "prior save version rejected explicitly")
	corrupt = Save.capture(game, match_id)
	corrupt.save_schema_version = 99
	check(Save.restore(corrupt).reason == "unsupported_save_version", "future save version rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.game_version = "godot-4.7.2-skirmish-5"
	check(Save.restore(corrupt).reason == "unsupported_game_version", "prior movement rules save rejected explicitly")
	corrupt.game_version = "godot-4.7.2-skirmish-6"
	check(Save.restore(corrupt).reason == "unsupported_game_version", "prior crowd recovery save rejected explicitly")
	corrupt = Save.capture(game, match_id)
	corrupt.state.balances[0].erase("terrenos")
	check(Save.restore(corrupt).reason == "state_balances_invalid", "missing resource balance rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.resource_sources[0].terrenos.refreshes_left = -1
	check(Save.restore(corrupt).reason == "state_resource_sources_invalid", "invalid resource refresh rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.age_index[0] = 4
	check(Save.restore(corrupt).reason == "state_age_index_invalid", "out-of-range age rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.factions[1] = "unknown_faction"
	check(Save.restore(corrupt).reason == "state_factions_invalid", "unknown opposing faction rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.researched[0].append("unknown_tech")
	check(Save.restore(corrupt).reason == "state_researched_invalid", "unknown tech rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.entities[0].carry_resource = "unknown_resource"
	check(Save.restore(corrupt).reason == "state_entity_resource_invalid", "unknown carried resource rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.state.entities[0].queue = [{"kind": "tech", "role": "unknown_tech", "remaining": 1}]
	check(Save.restore(corrupt).reason == "state_entity_queue_invalid", "unknown queued tech rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.command_log[0].target = [999, 999]
	check(Save.restore(corrupt).reason == "save_history_invalid", "out-of-map command target rejected")
	corrupt = Save.capture(game, match_id)
	corrupt.content_hash = "different"
	check(Save.restore(corrupt).reason == "content_version_mismatch", "different content rejected")
	var before := FileAccess.get_file_as_string(path)
	var old_path := "user://skirmish-old-check-%d.json" % Time.get_ticks_usec()
	var old_payload: Dictionary = Save.capture(game, match_id)
	old_payload.save_schema_version = 1
	var old_file := FileAccess.open(old_path, FileAccess.WRITE)
	old_file.store_string(JSON.stringify(old_payload))
	old_file.close()
	check(Save.read(old_path).reason == "unsupported_save_version" and FileAccess.file_exists(old_path),
		"old save remains on disk after explicit version rejection")
	var bad_path := "user://skirmish-corrupt-check-%d.json" % Time.get_ticks_usec()
	var file := FileAccess.open(bad_path, FileAccess.WRITE)
	file.store_string("{ broken")
	file.close()
	check(Save.read(bad_path).reason == "save_corrupt", "malformed JSON rejected")
	check(FileAccess.get_file_as_string(path) == before and FileAccess.file_exists(bad_path),
		"rejected data preserved without modifying valid save")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(old_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(bad_path))
	if not failed:
		print("Skirmish persistence checks passed: round trip, continuation, version and corruption")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
