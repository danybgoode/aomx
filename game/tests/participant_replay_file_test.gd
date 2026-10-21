extends SceneTree

const ParticipantReplay = preload("res://participant_replay.gd")

func _initialize() -> void:
	var source := OS.get_environment("AOMX_TEST_PARTICIPANT_SOURCE")
	var output := OS.get_environment("AOMX_TEST_PARTICIPANT_OUTPUT")
	var fixture = JSON.parse_string(FileAccess.get_file_as_string(source))
	if not fixture is Dictionary:
		_fail("fixture_invalid")
		return
	var saved := ParticipantReplay.write(fixture, output)
	if not saved.ok:
		_fail("valid_write_" + str(saved.reason))
		return
	var opened := ParticipantReplay.read(output)
	if not opened.ok or opened.recording.frames.size() != fixture.frames.size():
		_fail("valid_read")
		return
	var valid_bytes := FileAccess.get_file_as_string(output)
	var corrupt_path := output + ".corrupt.json"
	var corrupt := FileAccess.open(corrupt_path, FileAccess.WRITE)
	corrupt.store_string(valid_bytes.substr(0, valid_bytes.length() - 4))
	corrupt.close()
	var corrupt_result := ParticipantReplay.read(corrupt_path)
	if corrupt_result.ok or corrupt_result.reason != "replay_corrupt" or not FileAccess.file_exists(corrupt_path):
		_fail("corrupt_file_handling")
		return
	var unsupported_path := output + ".old.json"
	var old: Dictionary = opened.recording.duplicate(true)
	old.replay_schema_version = 99
	var unsupported := FileAccess.open(unsupported_path, FileAccess.WRITE)
	unsupported.store_string(JSON.stringify(old))
	unsupported.close()
	var old_result := ParticipantReplay.read(unsupported_path)
	if old_result.ok or old_result.reason != "unsupported_replay_version" or not FileAccess.file_exists(unsupported_path):
		_fail("unsupported_file_handling")
		return
	old = opened.recording.duplicate(true)
	old.frames[0].state.explored[1 - int(old.side)] = [0]
	var fog_path := output + ".fog.json"
	var fog := FileAccess.open(fog_path, FileAccess.WRITE)
	fog.store_string(JSON.stringify(old))
	fog.close()
	var fog_result := ParticipantReplay.read(fog_path)
	if fog_result.ok or not FileAccess.file_exists(fog_path):
		_fail("tampered_fog_handling")
		return
	if int(fixture.side) == 0:
		var oversized_path := output + ".oversized.json"
		var oversized := FileAccess.open(oversized_path, FileAccess.WRITE)
		var chunk := PackedByteArray()
		chunk.resize(1048576)
		for i in 65:
			oversized.store_buffer(chunk)
		oversized.close()
		var oversized_result := ParticipantReplay.read(oversized_path)
		if oversized_result.ok or oversized_result.reason != "replay_too_large" or not FileAccess.file_exists(oversized_path):
			_fail("oversized_file_handling")
			return
	print("Participant replay file checks passed: valid, corrupt, unsupported, fog, size")
	quit(0)

func _fail(reason: String) -> void:
	printerr("FAIL: " + reason)
	quit(1)
