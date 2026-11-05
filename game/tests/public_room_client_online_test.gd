extends SceneTree

const Client = preload("res://multiplayer_client.gd")
var client: Node
var code := ""
var joined := false
var deadline := 0

func _initialize() -> void:
	call_deferred("_start")

func _start() -> void:
	client = Client.new()
	root.add_child(client)
	client.endpoint = OS.get_environment("AOMX_TEST_MATCH_ENDPOINT")
	client.room_created.connect(func(room_code: String) -> void: code = room_code)
	client.joined.connect(func(info: Dictionary) -> void:
		joined = info.ok and int(info.side) == 0)
	client.state_received.connect(_on_state)
	client.problem.connect(func(message: String) -> void:
		printerr(message)
		quit(1))
	deadline = Time.get_ticks_msec() + 8000
	client.create_room("player0005")

func _on_state(response: Dictionary) -> void:
	if not joined or not response.ok or response.status != "waiting" or code.length() != 24:
		printerr("Public room client did not create a waiting room")
		quit(1)
		return
	print("AOMX_ROOM_CREATED " + code)
	quit(0)

func _process(_delta: float) -> bool:
	if deadline > 0 and Time.get_ticks_msec() > deadline:
		printerr("Public room client timed out")
		quit(1)
	return false
