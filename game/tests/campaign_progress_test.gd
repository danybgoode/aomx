extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Progress = preload("res://campaign_progress.gd")
var failed := false

func _initialize() -> void:
	var path := OS.get_user_data_dir().path_join("aomx-campaign-progress-%d.json" % Time.get_ticks_usec())
	var initial := Progress.read(path)
	check(initial.ok and initial.completed.is_empty(), "new profile has empty progress")
	check(Progress.available("arrival_copilco", initial.completed), "first mission is available")
	check(not Progress.available("foothold_narvarte", initial.completed), "second mission starts locked")
	var game = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner", "copilco", "", "arrival_copilco")
	check(Progress.record_verified(game, path).reason == "mission_not_won", "unwon mission cannot unlock")
	game.mission_steps = ["gather", "build", "recruit"]
	game.mission_result = "win"
	game.tick_number = 1
	var recorded := Progress.record_verified(game, path)
	check(recorded.ok and recorded.completed == ["arrival_copilco"] and not recorded.existing, "verified win writes one unlock")
	var again := Progress.record_verified(game, path)
	check(again.ok and again.existing and again.completed == ["arrival_copilco"], "duplicate result is idempotent")
	var restarted := Progress.read(path)
	check(restarted.ok and restarted.completed == ["arrival_copilco"] and Progress.available("foothold_narvarte", restarted.completed), "restart restores next mission")
	var final_game = Skirmish.new(Skirmish.REGIOS, {}, 1, "learner", "la_roma_large", "", "battle_la_roma")
	final_game.mission_steps = ["victory"]
	final_game.mission_result = "win"
	final_game.result = "win"
	final_game.tick_number = 1
	final_game.terminal_tick = 1
	check(Progress.record_verified(final_game, path).reason == "mission_locked", "later mission cannot skip prerequisite")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{bad")
	file.close()
	check(Progress.read(path).reason == "progress_version_or_format_invalid", "corrupt ledger is rejected")
	check(FileAccess.get_file_as_string(path) == "{bad", "corrupt ledger remains intact")
	DirAccess.remove_absolute(path)
	if not failed:
		print("Campaign progress checks passed: locked, verified, duplicate, restart and corruption")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAIL: ", label)
