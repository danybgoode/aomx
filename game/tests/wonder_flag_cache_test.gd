extends SceneTree

const Cache = preload("res://wonder_flag_cache.gd")
var failed := false

func _initialize() -> void:
	var path := OS.get_user_data_dir().path_join("aomx-wonder-flag-%d.json" % Time.get_ticks_usec())
	check(not Cache.read("player_0001", "preview", path).enabled, "first use defaults off")
	var on := {"enabled": true, "environment": "preview", "flag_version": 2, "snapshot_version": 2, "exposure_proof": "a".repeat(64)}
	check(Cache.write("player_0001", "preview", on, path), "served on version writes")
	check(Cache.read("player_0001", "preview", path).enabled, "offline session uses last served on")
	check(not Cache.read("player_other", "preview", path).enabled, "cache is bound to player")
	check(not Cache.read("player_0001", "production", path).enabled, "cache is bound to environment")
	check(not Cache.write("player_0001", "preview", {"enabled": false, "environment": "preview"}, path), "unversioned fallback cannot overwrite served choice")
	check(Cache.read("player_0001", "preview", path).enabled, "fallback leaves last served version")
	var off := {"enabled": false, "environment": "preview", "flag_version": 3, "snapshot_version": 3, "exposure_proof": "b".repeat(64)}
	check(Cache.write("player_0001", "preview", off, path), "served off version writes")
	check(not Cache.read("player_0001", "preview", path).enabled, "next served off disables new starts")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	check(not Cache.read("player_0001", "preview", path).enabled, "corrupt cache fails off")
	DirAccess.remove_absolute(path)
	if not failed:
		print("Wonder flag cache checks passed: first use, offline, identity and served off")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		printerr("FAIL: ", label)
