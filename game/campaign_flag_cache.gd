extends RefCounted

const PATH := "user://campaign-flag.v1.json"
const MAX_BYTES := 2048

static func read(player_id: String, environment: String, path: String = PATH) -> Dictionary:
	var off := {"enabled": false, "served": false}
	if not FileAccess.file_exists(path):
		return off
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return off
	if file.get_length() > MAX_BYTES:
		file.close()
		return off
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	file.close()
	if error != OK or not parser.data is Dictionary:
		return off
	var data: Dictionary = parser.data
	if data.get("schema_version") != 1 or data.get("player_id") != player_id or data.get("environment") != environment or not data.get("enabled") is bool or not _version(data.get("flag_version")) or not _version(data.get("snapshot_version")):
		return off
	return {"enabled": data.enabled, "served": true, "flag_version": data.flag_version, "snapshot_version": data.snapshot_version}

static func write(player_id: String, environment: String, decision: Dictionary, path: String = PATH) -> bool:
	if player_id.is_empty() or not decision.get("enabled") is bool or decision.get("environment") != environment or not _version(decision.get("flag_version")) or not _version(decision.get("snapshot_version")):
		return false
	var payload := JSON.stringify({"schema_version": 1, "player_id": player_id,
		"environment": environment, "enabled": decision.enabled,
		"flag_version": decision.flag_version, "snapshot_version": decision.snapshot_version})
	if payload.to_utf8_buffer().size() > MAX_BYTES:
		return false
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.get_file_as_string(temporary) != payload:
		return false
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) == OK

static func _version(value: Variant) -> bool:
	return value is String and not value.is_empty() and value.length() <= 128
