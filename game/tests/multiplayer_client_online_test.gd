extends SceneTree

const Client = preload("res://multiplayer_client.gd")
const State = preload("res://multiplayer_state.gd")
var client: Node
var deadline := 0

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	client = Client.new()
	root.add_child(client)
	client.endpoint = OS.get_environment("AOMX_TEST_MATCH_ENDPOINT")
	client.joined.connect(_joined)
	client.state_received.connect(_state)
	client.problem.connect(func(message: String) -> void: printerr(message))
	deadline = Time.get_ticks_msec() + 8000
	client.connect_match(OS.get_environment("AOMX_TEST_MATCH_CODE"), OS.get_environment("AOMX_TEST_MATCH_PLAYER"))

func _process(_delta: float) -> bool:
	if deadline > 0 and Time.get_ticks_msec() > deadline:
		printerr("online client timed out")
		quit(1)
	return false

func _joined(info: Dictionary) -> void:
	if not info.ok or int(info.side) != int(OS.get_environment("AOMX_TEST_EXPECT_SIDE")):
		printerr("online client joined wrong slot")
		quit(1)

func _state(response: Dictionary) -> void:
	if not response.ok or not response.get("state") is Dictionary:
		printerr("online client state missing")
		quit(1)
	var loaded: Dictionary = State.restore_for_side(response.state, str(response.match_id), int(response.side))
	if not loaded.ok:
		printerr("online client restore side " + str(response.side) + ": " + str(loaded.reason))
		quit(1)
		return
	print("AOMX_CLIENT_PASS tick=" + str(loaded.game.tick_number))
	quit(0)
