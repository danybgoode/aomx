extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const MultiplayerReplay = preload("res://multiplayer_replay.gd")
const PREFIX := "AOMX_MATCH:"
const MAX_LINE := 16777216

var game: RefCounted
var playback: RefCounted
var server := TCPServer.new()
var peer: StreamPeerTCP
var buffer := ""

func _initialize() -> void:
	var port := int(OS.get_environment("AOMX_WORKER_PORT"))
	if port < 1024 or port > 65535 or server.listen(port, "127.0.0.1") != OK:
		printerr("multiplayer worker could not bind loopback")
		quit(2)
		return
	print(PREFIX + "ready")

func _process(_delta: float) -> bool:
	if peer == null and server.is_connection_available():
		peer = server.take_connection()
	if peer == null:
		return false
	peer.poll()
	if peer.get_status() != StreamPeerTCP.STATUS_CONNECTED:
		quit()
		return false
	var available := peer.get_available_bytes()
	if available > 0:
		buffer += peer.get_utf8_string(mini(available, MAX_LINE + 1))
	if buffer.length() > MAX_LINE:
		_emit({"ok": false, "reason": "message_too_large"})
		quit(3)
		return false
	while buffer.contains("\n"):
		var end := buffer.find("\n")
		var line := buffer.substr(0, end)
		buffer = buffer.substr(end + 1)
		var message = JSON.parse_string(line)
		_emit(_handle(message) if message is Dictionary else {"ok": false, "reason": "invalid_json"})
	return false

func _handle(message: Dictionary) -> Dictionary:
	match message.get("type", ""):
		"init":
			if game != null:
				return {"ok": false, "reason": "already_initialized"}
			var map_id = message.get("map_id", "la_roma")
			var factions = message.get("factions", [Skirmish.REGIOS, Skirmish.POBLANOS])
			var seed = message.get("seed", 1)
			if map_id not in RulesContent.MAP_IDS or not factions is Array or factions.size() != 2 or factions[0] not in Skirmish.FACTION_IDS or factions[1] not in Skirmish.FACTION_IDS or not _whole(seed) or seed <= 0:
				return {"ok": false, "reason": "invalid_setup"}
			game = Skirmish.new(factions[0], {}, int(seed), "standard", map_id, factions[1])
			game.ai_enabled = false
			return _state("initialized")
		"tick":
			if game == null:
				return {"ok": false, "reason": "not_initialized"}
			game.tick()
			return _state("tick")
		"order":
			if game == null:
				return {"ok": false, "reason": "not_initialized"}
			var side = message.get("side")
			if not _whole(side) or int(side) not in [0, 1]:
				return {"ok": false, "reason": "invalid_side"}
			var command := {"schema_version": Skirmish.COMMAND_SCHEMA_VERSION,
				"issued_tick": game.tick_number, "sequence": game.next_command,
				"side": int(side), "kind": message.get("kind"),
				"actor_id": int(message.get("actor_id", -1)), "target": message.get("target")}
			var response: Dictionary = game.issue_command(command)
			return {"ok": response.ok, "reason": response.reason,
				"tick": game.tick_number, "sequence": game.next_command - 1 if response.ok else game.next_command,
				"hash": game.state_hash()}
		"state":
			if game == null:
				return {"ok": false, "reason": "not_initialized"}
			return _state("state")
		"replay_init":
			if game != null:
				return {"ok": false, "reason": "already_initialized"}
			var recording = message.get("recording")
			if not recording is Dictionary:
				return {"ok": false, "reason": "replay_invalid"}
			var opened: Dictionary = MultiplayerReplay.create_player(recording)
			if not opened.ok:
				return opened
			playback = opened.player
			game = playback.game
			return _state("replay_frame")
		"replay_step":
			if playback == null or not _whole(message.get("target_tick")):
				return {"ok": false, "reason": "replay_not_initialized"}
			var target_tick := int(message.target_tick)
			if target_tick <= game.tick_number or target_tick > int(playback.recording.end_tick) or target_tick - game.tick_number > 10:
				return {"ok": false, "reason": "replay_frame_out_of_order"}
			if game.tick_number == 0 and playback.command_index == 0:
				var initial: Dictionary = playback.apply_current_commands()
				if not initial.ok:
					return initial
			while game.tick_number < target_tick:
				var advanced: Dictionary = playback.step()
				if not advanced.ok:
					return advanced
			return _state("replay_frame")
	return {"ok": false, "reason": "unknown_type"}

func _whole(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))

func _state(kind: String) -> Dictionary:
	return {"ok": true, "type": kind, "tick": game.tick_number,
		"game_version": Skirmish.GAME_VERSION,
		"command_schema_version": Skirmish.COMMAND_SCHEMA_VERSION,
		"state_schema_version": Skirmish.STATE_SCHEMA_VERSION,
		"content_version": game.content.content_id, "content_hash": game.content_hash,
		"state": game.snapshot(), "views": [_view(0), _view(1)], "hash": game.state_hash()}

func _view(side: int) -> Dictionary:
	var state: Dictionary = game.snapshot()
	var enemy := 1 - side
	var visible: Array = []
	for entity in state.entities:
		if entity.side == side or game.is_entity_visible(side, game.entities[int(entity.id)]):
			visible.append(entity)
	state.entities = visible
	state.balances[enemy] = {"comida": 0, "materiales": 0, "varos": 0, "terrenos": 0}
	for source in state.resource_sources[enemy]:
		state.resource_sources[enemy][source] = {"amount": 0, "refresh_remaining": 0, "refreshes_left": 0}
	state.researched[enemy] = []
	state.explored[enemy] = []
	state.last_seen[enemy] = []
	state.projectiles = state.projectiles.filter(func(projectile: Dictionary) -> bool:
		return game.is_visible(side, Vector2i(int(projectile.tile[0]), int(projectile.tile[1]))))
	return state

func _emit(value: Dictionary) -> void:
	if peer != null:
		peer.put_data((JSON.stringify(value) + "\n").to_utf8_buffer())
