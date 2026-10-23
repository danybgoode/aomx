extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Cues = preload("res://presentation_cues.gd")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var policy = Cues.new()
	check(policy.claim("economy", "a", 10), "first economy event is accepted")
	check(not policy.claim("economy", "a", 10), "same event key cannot replay")
	check(not policy.claim("economy", "b", 11), "economy tick burst is coalesced")
	check(policy.claim("economy", "b", 45), "economy can sound again after cooldown")
	check(policy.priority("objective") > policy.priority("economy"), "objective outranks economy")
	policy.reset()
	check(policy.claim("economy", "a", 0), "new match clears prior event keys")

	var path := "user://presentation-cues-test-%d.json" % Time.get_ticks_usec()
	var client = Scene.instantiate()
	client.outbox = Outbox.new(path)
	var audio_settings := "user://presentation-audio-%d.json" % Time.get_ticks_usec()
	var ui_settings := "user://presentation-ui-%d.json" % Time.get_ticks_usec()
	client.audio_settings_path = audio_settings
	client.ui_settings_path = ui_settings
	root.add_child(client)
	client._choose_faction(Skirmish.REGIOS)
	var worker_id: int = client.sim._find(Skirmish.HUMAN, "worker")
	var tile: Vector2i = client.sim.entities[worker_id].pos
	client.selected_id = worker_id
	client.selected_ids.clear()
	client.selected_ids.append(worker_id)
	var state_hash: String = client.sim.state_hash()
	check(client._emit_cue("economy", "view-only", tile), "visible friendly cue accepted")
	check(client.sim.state_hash() == state_hash, "presentation event does not change simulation hash")
	check(not client._emit_cue("threat", "hidden", Vector2i(27, 27)), "fogged tile cannot trigger a cue")
	check(not client.cue_policy.seen_keys.has("hidden"), "fogged cue is not admitted to policy")

	client.hud_ui.sound_mute.button_pressed = true
	check(FileAccess.file_exists(audio_settings) and JSON.parse_string(FileAccess.get_file_as_string(audio_settings)).muted,
		"mute preference is saved in the existing audio-settings format")
	var accepted: Dictionary = client._issue_order("stop", "", tile)
	check(accepted.ok and client.cue_policy.last_kind_tick.has("order-confirm"), "accepted order uses confirmation policy while muted")
	check(not client.order_audio.playing and client.order_flash_ok, "muted accepted order stays visibly confirmed")
	var rejected: Dictionary = client._issue_order("move", Vector2i(-1, -1), tile)
	check(not rejected.ok and client.cue_policy.last_kind_tick.has("order-reject"), "rejected order uses distinct policy")
	check(not client.order_flash_ok and not client.order_flash_text.is_empty(), "rejected order remains visibly explained")

	client._baseline_presentation()
	client.online = true
	client.online_client.status = "playing"
	var queued: Dictionary = client._issue_order("move", tile, tile)
	check(queued.ok and client.order_flash_text.contains("awaiting host"), "queued online order is not labelled accepted")
	check(not client.cue_policy.last_kind_tick.has("order-confirm"), "online order waits for host acknowledgement before sound")
	client._on_online_order_ack({"ok": true})
	check(client.cue_policy.last_kind_tick.has("order-confirm") and client.order_flash_text.contains("accepted by host"),
		"host acknowledgement produces confirmation")
	client._issue_order("move", tile, tile)
	client._on_online_order_ack({"ok": false, "reason": "blocked_or_invalid_tile"})
	check(client.cue_policy.last_kind_tick.has("order-reject") and client.order_flash_text.contains("rejected"),
		"host rejection replaces queued feedback")
	var pending_building: int = client.sim._add_entity(Skirmish.HUMAN, "depot", tile + Vector2i(1, 0))
	client.sim.entities[pending_building].complete = false
	client._activate_command("cancel_build_%d" % pending_building)
	check(client.order_flash_pending and client.order_flash_text.contains("awaiting host"),
		"online construction cancel stays pending without promising a refund")
	client._on_online_order_ack({"ok": false, "reason": "cannot_cancel"})
	check(not client.order_flash_pending and not client.order_flash_ok and client.order_flash_text.contains("rejected"),
		"host rejection resolves online construction cancel")
	client.online = false
	client._baseline_presentation()
	client.sim.tick_number += 40
	client.sim.entities[worker_id].carry = 1
	client.sim.entities[worker_id].carry_resource = "comida"
	client._observe_events()
	check(client.cue_policy.last_kind_tick.has("economy"), "gather milestone maps to economy cue")
	client.sim.tick_number += 40
	client.sim.entities[worker_id].carry = 0
	client._observe_events()
	check(client.hud_ui.event_log.has("Comida delivered"), "delivery has a text equivalent")

	var building_id: int = client.sim._add_entity(Skirmish.HUMAN, "depot", tile + Vector2i(1, 0))
	client.sim.entities[building_id].complete = false
	client._baseline_presentation()
	client.sim.tick_number += 1
	client.sim.entities[building_id].complete = true
	client._observe_events()
	check(client.cue_policy.last_kind_tick.has("construction"), "construction completion maps to cue")

	client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
	client.sim._refresh_visibility()
	client._baseline_presentation()
	client.sim.tick_number += 1
	client.sim.district_state = "human_hold"
	client._observe_events()
	check(client.cue_policy.last_kind_tick.has("objective"), "visible objective transition maps to cue")

	client._baseline_presentation()
	client.sim.tick_number += 1
	client.sim.entities[worker_id].hp -= 1
	client._observe_events()
	check(client.cue_policy.last_kind_tick.has("threat"), "friendly damage maps to threat cue")
	var isolated: int = client.sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(27, 27))
	client.sim._refresh_visibility()
	client._baseline_presentation()
	client.sim.tick_number += 1
	client.sim.entities.erase(isolated)
	client.sim._refresh_visibility()
	check(not client.sim.is_visible(Skirmish.HUMAN, Vector2i(27, 27)), "isolated fighter death tile returns to fog")
	client._observe_events()
	check(client.hud_ui.event_log.has("Friendly unit lost") and client.cue_policy.last_kind_tick.has("destruction"),
		"owned loss remains announced without revealing a fogged location")
	check(client.cue_effects.is_empty(), "fogged owned loss has no positional marker")
	client._set_reduced_effects(true)
	check(client.cue_effects.is_empty(), "reduced effects clears transient board effects")
	check(JSON.parse_string(FileAccess.get_file_as_string(ui_settings)).reduced_effects,
		"reduced-effects preference persists through existing UI settings")
	client.sim.result = "win"
	client.sim.result_reason = "command_post"
	client._observe_events()
	check(client.cue_policy.seen_keys.has("%s:result" % client.match_id), "terminal transition sounds once")
	var emitted: int = client.cue_policy.seen_keys.size()
	client._observe_events()
	check(client.cue_policy.seen_keys.size() == emitted, "repeated terminal state cannot repeat cue")
	client._baseline_presentation()
	client._observe_events()
	check(client.cue_policy.seen_keys.is_empty(), "resume/replay baseline does not emit past cues")

	root.remove_child(client)
	client.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(audio_settings))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(ui_settings))
	if not failed:
		print("Presentation cue checks passed: policy, visibility, mute, deltas and terminal one-shot")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
