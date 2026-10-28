extends Node

signal joined(info: Dictionary)
signal state_received(state: Dictionary)
signal order_ack(response: Dictionary)
signal replay_received(response: Dictionary)
signal replay_frame_received(response: Dictionary)
signal problem(message: String)

const AlphaConfig = preload("res://alpha_config.gd")
const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const PROTOCOL_VERSION := 1

var endpoint := AlphaConfig.MATCH_ENDPOINT
var invite_code := ""
var player_id := ""
var match_id := ""
var side := -1
var token := ""
var status := "idle"
var next_sequence := 1
var latest_tick := 0
var pending_orders: Array[Dictionary] = []
var join_request: HTTPRequest
var state_request: HTTPRequest
var order_request: HTTPRequest
var replay_request: HTTPRequest
var replay_frame_request: HTTPRequest
var replay_token := ""
var replay_frame_loading := false
var poll_timer: Timer
var joining := false
var polling := false
var ordering := false
var reconnecting := false
var reconnect_started_ms := 0
var request_generation := 0

func _ready() -> void:
	_reset_requests()
	poll_timer = Timer.new()
	poll_timer.wait_time = 0.2
	poll_timer.autostart = false
	poll_timer.timeout.connect(_poll)
	add_child(poll_timer)

func _request_node() -> HTTPRequest:
	var req := HTTPRequest.new()
	req.timeout = 4.0
	req.body_size_limit = 16777216
	add_child(req)
	return req

func _reset_requests() -> void:
	request_generation += 1
	for request_node in [join_request, state_request, order_request, replay_request, replay_frame_request]:
		if request_node != null:
			request_node.cancel_request()
			request_node.queue_free()
	join_request = _request_node()
	state_request = _request_node()
	order_request = _request_node()
	replay_request = _request_node()
	replay_frame_request = _request_node()
	replay_request.timeout = 120.0
	replay_frame_request.timeout = 120.0
	join_request.request_completed.connect(_on_join.bind(request_generation))
	state_request.request_completed.connect(_on_state.bind(request_generation))
	order_request.request_completed.connect(_on_order.bind(request_generation))
	replay_request.request_completed.connect(_on_replay.bind(request_generation))
	replay_frame_request.request_completed.connect(_on_replay_frame.bind(request_generation))

func connect_match(code: String, installation_id: String) -> void:
	if joining or endpoint.is_empty() or code.is_empty() or installation_id.is_empty():
		problem.emit("Enter an invite code and check your connection.")
		return
	invite_code = code.strip_edges()
	player_id = installation_id
	joining = true
	status = "joining"
	var payload := {"invite_code": invite_code, "player_id": player_id,
		"protocol_version": PROTOCOL_VERSION, "game_version": Skirmish.GAME_VERSION,
		"content_version": Skirmish.CONTENT_VERSION,
		"command_schema_version": Skirmish.COMMAND_SCHEMA_VERSION,
		"state_schema_version": Skirmish.STATE_SCHEMA_VERSION,
		"content_hash": RulesContent.load_default().get("hash", ""),
		"simulation_hash": AlphaConfig.SIMULATION_HASH}
	var err := join_request.request(endpoint + "/v1/match/join",
		["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		joining = false
		problem.emit("Could not start the private connection.")
		if reconnecting:
			_schedule_reconnect()

func _on_join(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, generation: int) -> void:
	if generation != request_generation or not joining:
		return
	joining = false
	var response := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not response.get("ok", false):
		var reason := str(response.get("reason", "connection_failed"))
		if reconnecting and reason == "connection_failed":
			_schedule_reconnect()
			return
		status = "error"
		reconnecting = false
		problem.emit("This pilot build needs an updated private-match host. Solo play is available." if reason == "version_mismatch" else "Private match: " + reason.replace("_", " "))
		return
	match_id = str(response.match_id)
	side = int(response.side)
	token = str(response.token)
	status = str(response.status)
	if pending_orders.is_empty():
		next_sequence = int(response.get("next_sequence", next_sequence))
	reconnecting = false
	reconnect_started_ms = 0
	joined.emit(response)
	if status in ["no_result", "complete"]:
		_poll()
	else:
		poll_timer.start()
		_poll()

func _poll() -> void:
	if polling or token.is_empty() or status == "error":
		return
	polling = true
	var err := state_request.request(endpoint + "/v1/match/state",
		["X-Aomx-Match-Token: " + token], HTTPClient.METHOD_GET)
	if err != OK:
		polling = false
		_reconnect()

func _on_state(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, generation: int) -> void:
	if generation != request_generation or token.is_empty():
		return
	polling = false
	var response := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not response.get("ok", false):
		_reconnect()
		return
	status = str(response.status)
	latest_tick = int(response.get("tick", latest_tick))
	state_received.emit(response)
	if status in ["complete", "no_result"]:
		poll_timer.stop()
	else:
		_send_next_order()

func queue_order(kind: String, actor_id: int, target: Variant) -> Dictionary:
	if status != "playing":
		return {"ok": false, "reason": "match_not_playing"}
	pending_orders.append({"match_id": match_id, "side": side, "expected_tick": latest_tick,
		"sequence": next_sequence + pending_orders.size(),
		"kind": kind, "actor_id": actor_id, "target": target})
	_send_next_order()
	return {"ok": true, "reason": "order_sent"}

func _send_next_order() -> void:
	if ordering or pending_orders.is_empty() or token.is_empty() or status != "playing":
		return
	ordering = true
	var err := order_request.request(endpoint + "/v1/match/order",
		["Content-Type: application/json", "X-Aomx-Match-Token: " + token],
		HTTPClient.METHOD_POST, JSON.stringify(pending_orders[0]))
	if err != OK:
		ordering = false
		_reconnect()

func _on_order(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, generation: int) -> void:
	if generation != request_generation or token.is_empty():
		return
	ordering = false
	var response := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or response_code >= 500:
		_reconnect()
		return
	if response.get("reason") == "sequence_mismatch" or response.get("reason") == "unauthorized":
		problem.emit("Orders need a fresh session: " + str(response.reason).replace("_", " "))
		_reconnect()
		return
	if not pending_orders.is_empty():
		pending_orders.pop_front()
		next_sequence += 1
	order_ack.emit(response)
	_send_next_order()

func _reconnect() -> void:
	if reconnecting or joining or invite_code.is_empty() or status in ["complete", "no_result"]:
		return
	reconnecting = true
	reconnect_started_ms = Time.get_ticks_msec()
	problem.emit("Connection interrupted. Rejoining your slot…")
	status = "reconnecting"
	# The server binds the same code and installation ID to the same slot.
	connect_match(invite_code, player_id)

func _schedule_reconnect() -> void:
	if Time.get_ticks_msec() - reconnect_started_ms >= 60000:
		status = "error"
		reconnecting = false
		problem.emit("The reconnect window expired. No result was recorded.")
		return
	get_tree().create_timer(2.0).timeout.connect(func() -> void:
		if reconnecting and not joining:
			connect_match(invite_code, player_id))

func request_replay() -> void:
	if status != "complete" or replay_request == null:
		problem.emit("Finish a private match before opening its replay.")
		return
	var payload := {"invite_code": invite_code, "player_id": player_id, "match_id": match_id}
	var err := replay_request.request(endpoint + "/v1/match/replay",
		["Content-Type: application/json"], HTTPClient.METHOD_POST, JSON.stringify(payload))
	if err != OK:
		problem.emit("Could not request this replay.")

func _on_replay(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, generation: int) -> void:
	if generation != request_generation or token.is_empty():
		return
	var response := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not response.get("ok", false):
		problem.emit("Replay unavailable: " + str(response.get("reason", "connection_failed")).replace("_", " "))
		return
	replay_token = str(response.replay_token)
	replay_received.emit(response)

func request_replay_frame(index: int) -> void:
	if replay_token.is_empty() or replay_frame_loading:
		return
	replay_frame_loading = true
	var err := replay_frame_request.request(endpoint + "/v1/match/replay/frame",
		["Content-Type: application/json", "X-Aomx-Replay-Token: " + replay_token],
		HTTPClient.METHOD_POST, JSON.stringify({"frame_index": index}))
	if err != OK:
		replay_frame_loading = false
		problem.emit("Could not request replay frame.")

func _on_replay_frame(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray, generation: int) -> void:
	if generation != request_generation or replay_token.is_empty():
		return
	replay_frame_loading = false
	var response := _decode(body)
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200 or not response.get("ok", false):
		problem.emit("Replay unavailable: " + str(response.get("reason", "connection_failed")).replace("_", " "))
		return
	replay_frame_received.emit(response)

func _decode(body: PackedByteArray) -> Dictionary:
	var value = JSON.parse_string(body.get_string_from_utf8())
	return value if value is Dictionary else {}

func leave() -> void:
	poll_timer.stop()
	_reset_requests()
	token = ""
	replay_token = ""
	replay_frame_loading = false
	match_id = ""
	invite_code = ""
	player_id = ""
	status = "idle"
	pending_orders.clear()
	next_sequence = 1
	latest_tick = 0
	joining = false
	polling = false
	ordering = false
	reconnecting = false
	reconnect_started_ms = 0
