extends RefCounted

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const MultiplayerState = preload("res://multiplayer_state.gd")
const FORMAT := "battle-for-la-roma-participant-replay"
const VERSION := 1
const MAX_BYTES := 67108864
const MAX_FRAMES := 10001

static func write(recording: Dictionary, path: String) -> Dictionary:
	var payload_data := recording.duplicate(true)
	if payload_data.get("frames") is Array:
		payload_data.frames_sha256 = JSON.stringify(payload_data.frames).sha256_text()
	var checked := verify(payload_data)
	if not checked.ok:
		return checked
	var payload := JSON.stringify(payload_data)
	if payload.to_utf8_buffer().size() > MAX_BYTES:
		return _bad("replay_too_large")
	var directory := path.get_base_dir()
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory)) != OK:
		return _bad("replay_storage_unavailable")
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return _bad("replay_storage_unavailable")
	file.store_string(payload)
	file.flush()
	file.close()
	if FileAccess.get_file_as_string(temporary) != payload:
		return _bad("replay_write_failed")
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path)) != OK:
		return _bad("replay_replace_failed")
	return {"ok": true, "path": path}

static func read(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _bad("replay_missing")
	if file.get_length() > MAX_BYTES:
		file.close()
		return _bad("replay_too_large")
	var parser := JSON.new()
	var raw := file.get_as_text()
	file.close()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		return _bad("replay_corrupt")
	var checked := verify(parser.data)
	if not checked.ok:
		return checked
	return {"ok": true, "recording": parser.data}

static func verify(recording: Dictionary) -> Dictionary:
	if recording.get("format") != FORMAT or recording.get("replay_schema_version") != VERSION:
		return _bad("unsupported_replay_version")
	var match_id = recording.get("match_id")
	var side = recording.get("side")
	var end_tick = recording.get("end_tick")
	if not match_id is String or not match_id.begins_with("online_") or match_id.length() != 39:
		return _bad("replay_metadata_invalid")
	if not _whole(side) or int(side) not in [0, 1] or not _whole(end_tick) or int(end_tick) < 0 or int(end_tick) > 100000:
		return _bad("replay_metadata_invalid")
	if recording.get("game_version") != Skirmish.GAME_VERSION or recording.get("content_version") != Skirmish.CONTENT_VERSION:
		return _bad("game_version_mismatch")
	var map_id = recording.get("map_id")
	if not map_id is String or map_id not in RulesContent.MAP_IDS:
		return _bad("replay_map_invalid")
	var content := RulesContent.load_map(map_id)
	if not content.ok or recording.get("content_hash") != content.hash:
		return _bad("content_version_mismatch")
	var frames = recording.get("frames")
	if not frames is Array or frames.is_empty() or frames.size() > MAX_FRAMES or frames.size() != int(ceil(float(end_tick) / 10.0)) + 1:
		return _bad("replay_history_invalid")
	if not recording.get("frames_sha256") is String or recording.frames_sha256 != JSON.stringify(frames).sha256_text():
		return _bad("replay_corrupt")
	var terminal = recording.get("terminal")
	if not terminal is Dictionary or not _whole(terminal.get("tick")) or int(terminal.tick) != int(end_tick) or not terminal.get("results") is Array or terminal.results.size() != 2 or terminal.results[int(side)] not in ["win", "loss", "draw"]:
		return _bad("replay_terminal_invalid")
	for index in frames.size():
		var frame = frames[index]
		if not frame is Dictionary or frame.get("match_id") != match_id or not _whole(frame.get("side")) or int(frame.side) != int(side) or not _whole(frame.get("frame_index")) or int(frame.frame_index) != index or not _whole(frame.get("tick")) or int(frame.tick) != mini(int(end_tick), index * 10) or not frame.get("state") is Dictionary:
			return _bad("replay_history_invalid", index * 10)
		var state: Dictionary = frame.state
		if not state.get("explored") is Array or state.explored.size() != 2 or not state.get("last_seen") is Array or state.last_seen.size() != 2 or not state.get("researched") is Array or state.researched.size() != 2:
			return _bad("replay_state_invalid", int(frame.tick))
		var enemy := 1 - int(side)
		if not state.explored[enemy] is Array or not state.explored[enemy].is_empty() or not state.last_seen[enemy] is Array or not state.last_seen[enemy].is_empty() or not state.researched[enemy] is Array or not state.researched[enemy].is_empty():
			return _bad("replay_fog_invalid", int(frame.tick))
		var restored := MultiplayerState.restore_for_side(state, match_id, int(side))
		if not restored.ok:
			return _bad("replay_state_invalid", int(frame.tick))
		if int(restored.game.tick_number) != int(frame.tick):
			return _bad("replay_tick_mismatch", int(frame.tick))
		if index == frames.size() - 1 and frame.get("terminal") != terminal:
			return _bad("replay_terminal_invalid", int(frame.tick))
		if index == frames.size() - 1 and restored.game.result != terminal.results[int(side)]:
			return _bad("replay_terminal_invalid", int(frame.tick))
	return {"ok": true}

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))

static func _bad(reason: String, tick: int = 0) -> Dictionary:
	return {"ok": false, "reason": reason, "first_divergent_tick": tick}
