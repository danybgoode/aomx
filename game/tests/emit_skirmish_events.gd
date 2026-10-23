extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var path := OS.get_environment("SKIRMISH_FIXTURE_PATH")
	if path.is_empty():
		printerr("SKIRMISH_FIXTURE_PATH is required")
		quit(1)
		return
	var client = Scene.instantiate()
	client.outbox = Outbox.new(path)
	root.add_child(client)
	# This fixture checks event exclusion, not playback. Keep its terminal cue off.
	client.hud_ui.sound_mute.set_pressed_no_signal(true)
	client._choose_faction(Skirmish.REGIOS)
	var enemy_post: int = client.sim._find(Skirmish.COMPUTER, "command_post")
	client.sim.entities[enemy_post].hp = 0
	client._process(0.1)
	if client.outbox.state.events.size() != 3 or client.outbox.state.events[2].event.type != "match_completed":
		printerr("Skirmish fixture could not save terminal event")
		quit(1)
		return
	print("Skirmish client fixture saved: open, start, completed win")
	root.remove_child(client)
	client.queue_free()
	await process_frame
	quit(0)
