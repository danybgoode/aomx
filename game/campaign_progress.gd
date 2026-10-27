extends RefCounted

const CampaignMissions = preload("res://campaign_missions.gd")
const PATH := "user://campaign-progress.v1.json"
const MAX_BYTES := 8192

static func read(path: String = PATH) -> Dictionary:
	var manifest := CampaignMissions.load_manifest()
	if not manifest.ok:
		return manifest
	if not FileAccess.file_exists(path):
		return {"ok": true, "completed": [], "hash": manifest.hash}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _bad("progress_storage_unavailable")
	if file.get_length() > MAX_BYTES:
		file.close()
		return _bad("progress_too_large")
	var parser := JSON.new()
	var parse_error := parser.parse(file.get_as_text())
	file.close()
	if parse_error != OK:
		return _bad("progress_version_or_format_invalid")
	var parsed = parser.data
	if not parsed is Dictionary or parsed.get("schema_version") != 1 or parsed.get("chapter_id") != manifest.data.chapter_id or parsed.get("mission_hash") != manifest.hash or not parsed.get("completed") is Array:
		return _bad("progress_version_or_format_invalid")
	if parsed.completed.size() > manifest.data.missions.size():
		return _bad("progress_order_invalid")
	for i in parsed.completed.size():
		if parsed.completed[i] != manifest.data.missions[i].id:
			return _bad("progress_order_invalid")
	return {"ok": true, "completed": parsed.completed.duplicate(), "hash": manifest.hash}

static func available(mission_id: String, completed: Array) -> bool:
	var manifest := CampaignMissions.load_manifest()
	if not manifest.ok:
		return false
	for mission in manifest.data.missions:
		if mission.id == mission_id:
			return mission.prerequisite.is_empty() or mission.prerequisite in completed
	return false

static func record_verified(game: RefCounted, path: String = PATH) -> Dictionary:
	if game.mission_result != "win" or game.mission_id.is_empty() or game.mission_steps.size() != game.mission_definition.steps.size():
		return _bad("mission_not_won")
	var progress := read(path)
	if not progress.ok:
		return progress
	if game.mission_hash != progress.hash:
		return _bad("progress_mission_version_invalid")
	if game.mission_id in progress.completed:
		return {"ok": true, "completed": progress.completed, "existing": true}
	if not available(game.mission_id, progress.completed):
		return _bad("mission_locked")
	var next: Array = progress.completed.duplicate()
	next.append(game.mission_id)
	var payload := JSON.stringify({"schema_version": 1, "chapter_id": "arrival-to-la-roma",
		"mission_hash": progress.hash, "completed": next})
	if payload.to_utf8_buffer().size() > MAX_BYTES:
		return _bad("progress_too_large")
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _bad("progress_storage_unavailable")
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.get_file_as_string(temporary) != payload:
		return _bad("progress_write_failed")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) != OK:
		return _bad("progress_replace_failed")
	return {"ok": true, "completed": next, "existing": false}

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
