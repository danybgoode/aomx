extends RefCounted

const AlphaConfig = preload("res://alpha_config.gd")
const SCHEMA_VERSION := 1
const GAME_VERSION := "godot-4.7.2-prototype-1"
const CONTENT_VERSION := "original-map-1"

var filename: String
var state: Dictionary
var game_version := GAME_VERSION
var content_version := CONTENT_VERSION
var test_account := AlphaConfig.TEST_ACCOUNT

func _init(path: String = "user://funnel-outbox.json") -> void:
	filename = path
	if FileAccess.file_exists(filename):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(filename))
		if parsed is Dictionary and parsed.has("player_id") and parsed.has("events") and parsed.has("next_sequence"):
			state = parsed
			return
		push_error("Outbox cannot be read; existing events were left untouched.")
		return
	state = {"player_id": _id(), "next_sequence": 1, "events": []}
	if not _save(state):
		state = {}

func queue_open_for_launch() -> Dictionary:
	if state.is_empty():
		return {"ok": false, "reason": "outbox_unavailable"}
	var last_open: Dictionary = {}
	for item in state.events:
		if item.event.type == "game_opened":
			last_open = item.event
	var today := Time.get_date_string_from_system(true)
	if not last_open.is_empty() and last_open.claimed_at.substr(0, 10) == today:
		return {"ok": true, "event": last_open, "existing": true}
	return queue("game_opened", "", "", not last_open.is_empty() and today > last_open.claimed_at.substr(0, 10))

func queue(type: String, match_id: String = "", result: String = "", new_session: bool = false) -> Dictionary:
	if state.is_empty() or type not in ["game_opened", "match_started", "match_completed"]:
		return {"ok": false, "reason": "outbox_unavailable"}
	for item in state.events:
		if item.event.type == type and (type == "game_opened" and not new_session or type != "game_opened" and item.event.get("match_id", "") == match_id):
			return {"ok": true, "event": item.event, "existing": true}
	if type != "game_opened" and match_id.is_empty():
		return {"ok": false, "reason": "missing_match_id"}
	if type == "match_completed" and result not in ["win", "loss", "draw"]:
		return {"ok": false, "reason": "invalid_result"}
	if type != "match_completed" and not result.is_empty():
		return {"ok": false, "reason": "unexpected_result"}
	if type == "match_completed" and not state.events.any(func(item: Dictionary) -> bool:
		return item.event.type == "match_started" and item.event.get("match_id", "") == match_id):
		return {"ok": false, "reason": "missing_match_start"}
	var utc := Time.get_datetime_string_from_system(true) + ".000Z"
	var event := {"schema_version": SCHEMA_VERSION, "type": type, "event_id": _id(),
		"player_id": state.player_id, "claimed_at": utc, "local_sequence": state.next_sequence,
		"game_version": game_version, "content_version": content_version,
		"mode": "solo", "faction": "neutral", "test_account": test_account, "bot": false}
	if type != "game_opened":
		event.match_id = match_id
	if type == "match_completed":
		event.result = result
	var next: Dictionary = state.duplicate(true)
	next.events.append({"event": event, "status": "pending", "receipt": null})
	next.next_sequence += 1
	if not _save(next):
		return {"ok": false, "reason": "could_not_save"}
	state = next
	return {"ok": true, "event": event, "existing": false}

func first_pending() -> Dictionary:
	if state.is_empty():
		return {}
	for item in state.events:
		if item.status == "needs_attention":
			return {}
		if item.status == "pending":
			return item.event
	return {}

func apply_receipt(receipt: Dictionary) -> bool:
	if state.is_empty() or not receipt.get("event_id") is String or not receipt.get("receipt_id") is String or not receipt.get("received_at") is String:
		return false
	if receipt.event_id.is_empty() or receipt.receipt_id.is_empty() or not receipt.received_at.ends_with("Z"):
		return false
	if receipt.get("status") not in ["accepted", "excluded", "rejected", "quarantined"]:
		return false
	if receipt.status in ["rejected", "quarantined"] and (not receipt.get("reason") is String or receipt.reason.is_empty()):
		return false
	var next: Dictionary = state.duplicate(true)
	for item in next.events:
		if item.event.event_id == receipt.event_id and item.status == "pending":
			item.receipt = receipt
			item.status = "accepted" if receipt.get("status") in ["accepted", "excluded"] else "needs_attention"
			if _save(next):
				state = next
				return true
			return false
	return false

func summary() -> String:
	if state.is_empty():
		return "Could not save local play data. Check device storage."
	var pending := 0
	var accepted := 0
	var attention := 0
	var attention_reason := ""
	for item in state.events:
		match item.status:
			"pending": pending += 1
			"accepted": accepted += 1
			"needs_attention":
				attention += 1
				if attention_reason.is_empty():
					attention_reason = item.receipt.get("reason", "sync error")
	if attention > 0:
		var action := "Check your device clock" if attention_reason in ["clock_ahead", "clock_reversal"] else "Check the local audit or contact support"
		return "%d event(s) need attention: %s. %s; local copy retained." % [attention, attention_reason, action]
	if pending > 0:
		return "%d event(s) saved on this device. Pending sync." % pending
	return "%d event(s) synced. %s" % [accepted, "Test play is not counted." if test_account else "Accepted play will appear after cohort review."]

func _save(next: Dictionary) -> bool:
	var absolute := ProjectSettings.globalize_path(filename)
	var temp := absolute + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(next))
	file.flush()
	var error := file.get_error()
	file.close()
	if error != OK:
		return false
	return DirAccess.rename_absolute(temp, absolute) == OK

func _id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()
