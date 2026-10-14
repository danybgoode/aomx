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
	var started: Dictionary = persisted.queue("match_started", "prototype_match_0001")
	check(started.ok and started.event.local_sequence == 2, "test match start saved in order")
	check(started.event.player_id == opened.event.player_id, "events share installation ID")
	check(Outbox.new(path).state.events.size() == 2, "both events survive restart")
	check(persisted.first_pending().event_id == opened.event.event_id, "oldest event retries first")
	check(not persisted.apply_receipt({"event_id": opened.event.event_id, "status": "accepted"}), "incomplete receipt cannot claim success")
	check(persisted.first_pending().event_id == opened.event.event_id, "incomplete receipt stays pending")
	check(persisted.apply_receipt({"event_id": opened.event.event_id, "receipt_id": "receipt_0001", "received_at": "2026-10-14T00:00:00.000Z", "status": "excluded", "reason": "test_account"}), "excluded receipt saved")
	check(persisted.first_pending().event_id == started.event.event_id, "second event retries next")
	check(persisted.apply_receipt({"event_id": started.event.event_id, "receipt_id": "receipt_0002", "received_at": "2026-10-14T00:00:01.000Z", "status": "rejected", "reason": "clock_reversal"}), "rejection saved")
	var after = Outbox.new(path)
	check(after.first_pending().is_empty(), "accepted and attention events are not retried")
	check(after.state.events[1].status == "needs_attention", "rejected event retained")
	check(after.summary().contains("need attention"), "attention is visible")
	check(after.summary().contains("clock_reversal"), "persisted attention reason survives restart")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not failed:
		print("Godot outbox checks passed: durable open/start, restart, sequence, receipts, attention")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
