extends RefCounted

# This prototype deliberately emits only test-account traffic. A real match start
# belongs to the funded solo-skirmish client once a playable match exists.
const SCHEMA_VERSION := 1
const GAME_VERSION := "godot-4.7.2-prototype-1"
const CONTENT_VERSION := "original-map-1"

var filename: String
var state: Dictionary

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

func queue(type: String, match_id: String = "") -> Dictionary:
	if state.is_empty() or type not in ["game_opened", "match_started"]:
		return {"ok": false, "reason": "outbox_unavailable"}
	for item in state.events:
		if item.event.type == type and (type == "game_opened" or item.event.get("match_id", "") == match_id):
			return {"ok": true, "event": item.event, "existing": true}
	if type == "match_started" and match_id.is_empty():
		return {"ok": false, "reason": "missing_match_id"}
	var utc := Time.get_datetime_string_from_system(true) + ".000Z"
	var event := {"schema_version": SCHEMA_VERSION, "type": type, "event_id": _id(),
		"player_id": state.player_id, "claimed_at": utc, "local_sequence": state.next_sequence,
		"game_version": GAME_VERSION, "content_version": CONTENT_VERSION,
		"mode": "solo", "faction": "neutral", "test_account": true, "bot": false}
	if type == "match_started":
		event.match_id = match_id
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
	return "%d test event(s) synced. Test play is not counted." % accepted

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
