extends SceneTree

const Client = preload("res://multiplayer_client.gd")
const State = preload("res://multiplayer_state.gd")
var client: Node
var deadline := 0
var expected_side := -1

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	client = Client.new()
	root.add_child(client)
	client.endpoint = OS.get_environment("AOMX_TEST_MATCH_ENDPOINT")
	client.invite_code = OS.get_environment("AOMX_TEST_MATCH_CODE")
	client.player_id = OS.get_environment("AOMX_TEST_MATCH_PLAYER")
	client.match_id = OS.get_environment("AOMX_TEST_MATCH_ID")
	client.token = "fixture_authenticated_participant"
	client.status = "complete"
	expected_side = int(OS.get_environment("AOMX_TEST_EXPECT_SIDE"))
	client.replay_received.connect(_opened)
	client.replay_frame_received.connect(_frame)
	client.problem.connect(func(message: String) -> void:
		printerr(message)
		quit(1))
	deadline = Time.get_ticks_msec() + 20000
	client.request_replay()

func _process(_delta: float) -> bool:
	if deadline > 0 and Time.get_ticks_msec() > deadline:
		printerr("native replay client timed out")
		quit(1)
	return false

func _opened(response: Dictionary) -> void:
	if int(response.side) != expected_side or int(response.frame_count) < 2:
		printerr("native replay metadata invalid")
		quit(1)
		return
	client.request_replay_frame(0)

func _frame(response: Dictionary) -> void:
	var loaded: Dictionary = State.restore_for_side(response.state, client.match_id, expected_side)
	if not loaded.ok or int(response.frame_index) != 0:
		printerr("native replay frame invalid: ", loaded.get("reason", "index"))
		quit(1)
		return
	print("AOMX_REPLAY_CLIENT_PASS side=" + str(expected_side))
	quit(0)
