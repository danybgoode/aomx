extends SceneTree

const Outbox = preload("res://funnel_outbox.gd")
var failed := false

func _initialize() -> void:
	var path := "user://funnel-outbox-check-%d.json" % Time.get_ticks_usec()
	var first = Outbox.new(path)
	var opened: Dictionary = first.queue("game_opened")
	check(opened.ok, "first open saved")
	check(opened.event.test_account, "prototype traffic test tagged")
	check(opened.event.local_sequence == 1, "first sequence")
	var persisted = Outbox.new(path)
	check(persisted.state.player_id == first.state.player_id, "installation ID survives restart")
	var same: Dictionary = persisted.queue("game_opened")
	check(same.event.event_id == opened.event.event_id, "restart does not duplicate first open")
	check(persisted.queue_open_for_launch().event.event_id == opened.event.event_id, "same-day launch reuses open")
	var later: Dictionary = persisted.queue("game_opened", "", "", true)
	check(later.ok and later.event.event_id != opened.event.event_id and later.event.local_sequence == 2, "intentional return open gets stable new ID")
	check(Outbox.new(path).state.events.size() == 2, "return open survives restart")
	var started: Dictionary = persisted.queue("match_started", "prototype_match_0001")
	check(started.ok and started.event.local_sequence == 3, "test match start saved in order")
	check(started.event.player_id == opened.event.player_id, "events share installation ID")
	check(Outbox.new(path).state.events.size() == 3, "all events survive restart")
	check(persisted.first_pending().event_id == opened.event.event_id, "oldest event retries first")
	check(not persisted.apply_receipt({"event_id": opened.event.event_id, "status": "accepted"}), "incomplete receipt cannot claim success")
	check(persisted.first_pending().event_id == opened.event.event_id, "incomplete receipt stays pending")
	check(persisted.apply_receipt({"event_id": opened.event.event_id, "receipt_id": "receipt_0001", "received_at": "2026-10-14T00:00:00.000Z", "status": "excluded", "reason": "test_account"}), "excluded receipt saved")
	check(persisted.first_pending().event_id == later.event.event_id, "return open retries before start")
	check(persisted.apply_receipt({"event_id": later.event.event_id, "receipt_id": "receipt_return_0001", "received_at": "2026-10-14T00:00:00.000Z", "status": "excluded", "reason": "test_account"}), "return open receipt saved")
	check(persisted.first_pending().event_id == started.event.event_id, "start retries next")
	check(persisted.apply_receipt({"event_id": started.event.event_id, "receipt_id": "receipt_0002", "received_at": "2026-10-14T00:00:01.000Z", "status": "rejected", "reason": "clock_reversal"}), "rejection saved")
	var after = Outbox.new(path)
	check(after.first_pending().is_empty(), "accepted and attention events are not retried")
	check(after.state.events[2].status == "needs_attention", "rejected event retained")
	check(after.summary().contains("need attention"), "attention is visible")
	check(after.summary().contains("clock_reversal"), "persisted attention reason survives restart")
	var completed: Dictionary = after.queue("match_completed", "prototype_match_0001", "win")
	check(completed.ok and completed.event.result == "win", "terminal result saved with match ID")
	check(after.first_pending().event_id == completed.event.event_id, "later pending events continue after a rejected predecessor")
	check(after.queue("match_completed", "prototype_match_0001", "loss").event.event_id == completed.event.event_id, "second local terminal result reuses first event")
	check(not after.queue("match_completed", "prototype_match_0002", "unknown").ok, "invalid terminal result rejected")
	check(Outbox.new(path).state.events.size() == 4, "terminal result survives restart once")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var return_path := "user://funnel-return-check-%d.json" % Time.get_ticks_usec()
	var return_outbox = Outbox.new(return_path)
	var first_return_open: Dictionary = return_outbox.queue_open_for_launch()
	var yesterday: Dictionary = return_outbox.state.duplicate(true)
	yesterday.events[0].event.claimed_at = "2026-01-01T00:00:00.000Z"
	check(return_outbox._save(yesterday), "older open fixture saved")
	var next_day = Outbox.new(return_path)
	var session_open: Dictionary = next_day.queue_open_for_launch()
	check(session_open.ok and session_open.event.event_id != first_return_open.event.event_id, "later UTC day launch emits return open")
	check(next_day.queue_open_for_launch().event.event_id == session_open.event.event_id, "same-day relaunch reuses return open")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(return_path))
	var clock_path := "user://funnel-clock-check-%d.json" % Time.get_ticks_usec()
	var clock_outbox = Outbox.new(clock_path)
	var quarantined_open: Dictionary = clock_outbox.queue_open_for_launch().event
	check(clock_outbox.apply_receipt({"event_id": quarantined_open.event_id,
		"receipt_id": "receipt_clock_0001", "received_at": "2026-10-14T00:00:00.000Z",
		"status": "quarantined", "reason": "clock_ahead"}), "clock anomaly retained")
	var recovered_open: Dictionary = clock_outbox.queue_open_for_launch().event
	check(recovered_open.event_id != quarantined_open.event_id and recovered_open.local_sequence == 2,
		"same-day restart can create a fresh open after clock correction")
	check(Outbox.new(clock_path).first_pending().event_id == recovered_open.event_id,
		"recovered open survives restart and can sync")
	check(clock_outbox.summary().contains("restart the app"), "clock recovery guidance is visible")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(clock_path))
	if not failed:
		print("Godot outbox checks passed: durable open/start, restart, sequence, receipts, attention")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
