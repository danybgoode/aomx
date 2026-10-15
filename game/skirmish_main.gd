extends Node2D

const Skirmish = preload("res://skirmish.gd")
const FunnelOutbox = preload("res://funnel_outbox.gd")
const AlphaConfig = preload("res://alpha_config.gd")
const TILE_W := 48.0
const TILE_H := 24.0
const ORIGIN := Vector2(640, 65)
const TICK_SECONDS := 0.1

var sim = Skirmish.new()
var outbox = FunnelOutbox.new()
var match_id := ""
var completion_queued := false
var selected_id := -1
var placing := false
var marker := Vector2i(-1, -1)
var accumulator := 0.0
var syncing := false
var sync_note := ""
var hud: Label
var instructions: Label
var request: HTTPRequest
var invite_code := ""
var invite_input: LineEdit

func _ready() -> void:
	outbox.game_version = Skirmish.GAME_VERSION
	outbox.content_version = Skirmish.CONTENT_VERSION
	outbox.queue_open_for_launch()
	_start_match()
	request = HTTPRequest.new()
	request.timeout = 3.0
	add_child(request)
	request.request_completed.connect(_on_request_completed)
	var retry_timer := Timer.new()
	retry_timer.wait_time = 5.0
	retry_timer.autostart = true
	retry_timer.timeout.connect(_send_next)
	add_child(retry_timer)
	var layer := CanvasLayer.new()
	add_child(layer)
	if AlphaConfig.CHANNEL != "development":
		var invite_path := "user://alpha-invite-code.txt"
		if FileAccess.file_exists(invite_path):
			invite_code = FileAccess.get_file_as_string(invite_path).strip_edges()
		invite_input = LineEdit.new()
		invite_input.position = Vector2(22, 16)
		invite_input.size = Vector2(270, 34)
		invite_input.placeholder_text = "Enter private alpha invite code"
		invite_input.secret = true
		layer.add_child(invite_input)
		var invite_button := Button.new()
		invite_button.text = "Save invite code"
		invite_button.position = Vector2(302, 16)
		invite_button.pressed.connect(_save_invite_code)
		layer.add_child(invite_button)
		var support_button := Button.new()
		support_button.text = "Copy support ID"
		support_button.position = Vector2(22, 56)
		support_button.pressed.connect(_copy_support_id)
		layer.add_child(support_button)
	hud = Label.new()
	hud.position = Vector2(22, 598)
	hud.add_theme_font_size_override("font_size", 17)
	layer.add_child(hud)
	instructions = Label.new()
	instructions.position = Vector2(22, 755)
	instructions.add_theme_font_size_override("font_size", 16)
	instructions.text = "Click own unit/building · Right-click move/gather/attack · B build · 1 worker · 2 melee · 3 ranged · R restart · F sync"
	layer.add_child(instructions)
	_update_hud()

func _start_match() -> void:
	sim = Skirmish.new()
	match_id = "solo_" + Crypto.new().generate_random_bytes(16).hex_encode()
	completion_queued = false
	selected_id = -1
	placing = false
	marker = Vector2i(-1, -1)
	var saved: Dictionary = outbox.queue("match_started", match_id)
	sync_note = "Match start saved." if saved.ok else "Match start could not be saved; check device storage."
	if OS.is_debug_build():
		match OS.get_environment("SKIRMISH_SMOKE_SCENARIO"):
			"win":
				sim.entities[sim._find(Skirmish.COMPUTER, "command_post")].hp = 0
			"loss":
				sim.entities[sim._find(Skirmish.HUMAN, "command_post")].hp = 0
			"draw":
				sim.tick_number = Skirmish.DRAW_TICK - 1

func _process(delta: float) -> void:
	accumulator += delta
	var advanced := false
	while accumulator >= TICK_SECONDS:
		sim.tick()
		accumulator -= TICK_SECONDS
		advanced = true
	if sim.result != "" and not completion_queued:
		var saved: Dictionary = outbox.queue("match_completed", match_id, sim.result)
		completion_queued = saved.ok
		if not saved.ok:
			sync_note = "Result could not be saved; check device storage."
	if advanced:
		_update_hud()
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_B:
				if _selected_kind() == "worker":
					if sim.stockpile[Skirmish.HUMAN] < Skirmish.COST.barracks:
						placing = false
						sim.feedback = "Need 6 resource. Right-click gold with a worker to gather."
					else:
						placing = true
						sim.feedback = "Choose a clear 2 by 2 footprint. Cost: 6."
			KEY_ESCAPE:
				placing = false
			KEY_1:
				_train("worker")
			KEY_2:
				_train("melee")
			KEY_3:
				_train("ranged")
			KEY_R:
				_start_match()
			KEY_F:
				_send_next()
	elif event is InputEventMouseButton and event.pressed:
		var tile := _screen_to_tile(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if placing and selected_id != -1:
				var placed: Dictionary = sim.issue(Skirmish.HUMAN, "build", selected_id, tile)
				if placed.ok:
					placing = false
			else:
				var id: int = sim.entity_at(tile)
				selected_id = id if id != -1 and sim.entities[id].side == Skirmish.HUMAN else -1
				if selected_id != -1:
					sim.feedback = "%s selected" % sim.entities[selected_id].kind.replace("_", " ")
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_id != -1 and sim.entities.has(selected_id):
			var selected: Dictionary = sim.entities[selected_id]
			var target_id: int = sim.entity_at(tile)
			if selected.kind == "worker" and tile == sim.sources[Skirmish.HUMAN].pos:
				sim.issue(Skirmish.HUMAN, "gather", selected_id, tile)
			elif selected.kind in ["melee", "ranged"] and target_id != -1 and sim.entities[target_id].side == Skirmish.COMPUTER:
				sim.issue(Skirmish.HUMAN, "attack", selected_id, target_id)
			elif selected.kind in ["worker", "melee", "ranged"]:
				var moved: Dictionary = sim.issue(Skirmish.HUMAN, "move", selected_id, tile)
				if moved.ok:
					marker = tile
	_update_hud()
	queue_redraw()

func _train(role: String) -> void:
	if selected_id == -1 or not sim.entities.has(selected_id):
		sim.feedback = "Select a production building."
		return
	sim.issue(Skirmish.HUMAN, "train", selected_id, role)

func _selected_kind() -> String:
	return sim.entities[selected_id].kind if sim.entities.has(selected_id) else ""

func _update_hud() -> void:
	if hud == null:
		return
	if selected_id != -1 and not sim.entities.has(selected_id):
		selected_id = -1
	var human_post := sim._find(Skirmish.HUMAN, "command_post")
	var enemy_post := sim._find(Skirmish.COMPUTER, "command_post")
	var own_hp: int = maxi(0, sim.entities[human_post].hp) if human_post != -1 else 0
	var enemy_hp: int = maxi(0, sim.entities[enemy_post].hp) if enemy_post != -1 else 0
	var chosen := "none" if selected_id == -1 else "%s #%d (%d HP)" % [sim.entities[selected_id].kind.replace("_", " "), selected_id, sim.entities[selected_id].hp]
	var total_seconds: int = floori(float(sim.tick_number) / 10.0)
	var opponent_note := "Opponent attacks at 01:20." if sim.tick_number < Skirmish.AI_ATTACK_TICK else "Opponent attacking."
	hud.text = "Battle for La Roma · %s · %s\nStockpile: %d   Gold left: %d   Our units: %d   Opponent units: %d   Time: %02d:%02d   Frame process: %.1f ms\nSelected: %s   Command posts: %d / %d HP\n%s   %s\n%s %s" % [
		AlphaConfig.CHANNEL, AlphaConfig.BUILD_ID,
		sim.stockpile[Skirmish.HUMAN], sim.sources[Skirmish.HUMAN].amount,
		sim._count_units(Skirmish.HUMAN), sim._count_units(Skirmish.COMPUTER),
		floori(float(total_seconds) / 60.0), total_seconds % 60, Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		chosen, own_hp, enemy_hp, sim.feedback.capitalize(), "Result: %s. Press R to restart." % sim.result if sim.result != "" else opponent_note,
		outbox.summary(), sync_note]

func _send_next() -> void:
	if syncing:
		return
	if AlphaConfig.CHANNEL != "development" and invite_code.is_empty():
		sync_note = "Enter the private alpha invite code to sync saved play."
		_update_hud()
		return
	var event: Dictionary = outbox.first_pending()
	if event.is_empty():
		sync_note = "" if outbox.summary().contains("need attention") else "Nothing pending."
		_update_hud()
		return
	syncing = true
	var headers := ["Content-Type: application/json"]
	if AlphaConfig.CHANNEL != "development":
		headers.append("X-Aomx-Invite-Code: " + invite_code)
	var error := request.request(AlphaConfig.ENDPOINT, headers,
		HTTPClient.METHOD_POST, JSON.stringify(event))
	if error != OK:
		syncing = false
		sync_note = "Service unavailable. Events remain saved on this device."
		_update_hud()

func _on_request_completed(result_code: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	syncing = false
	if response_code == 401:
		sync_note = "Invite code was not accepted. Re-enter it; saved play is still pending."
		_update_hud()
		return
	if result_code != HTTPRequest.RESULT_SUCCESS or response_code not in [200, 422]:
		sync_note = "Service unavailable. Events remain saved on this device."
		_update_hud()
		return
	var receipt = JSON.parse_string(body.get_string_from_utf8())
	if not receipt is Dictionary or not outbox.apply_receipt(receipt):
		sync_note = "Receipt could not be saved. Retry later."
		_update_hud()
		return
	if receipt.status in ["accepted", "excluded"]:
		sync_note = "Event synced to the audit."
		_send_next()
	else:
		sync_note = "Needs attention: %s. Local copy retained." % receipt.get("reason", "rejected")
		_send_next()
	_update_hud()

func _save_invite_code() -> void:
	var candidate := invite_input.text.strip_edges()
	if candidate.length() < 24 or candidate.length() > 80:
		sync_note = "Check the invite code and try again."
		_update_hud()
		return
	var file := FileAccess.open("user://alpha-invite-code.txt", FileAccess.WRITE)
	if file == null:
		sync_note = "Could not save the invite code. Check device storage."
		_update_hud()
		return
	file.store_string(candidate)
	file.flush()
	file.close()
	invite_code = candidate
	invite_input.clear()
	sync_note = "Invite code saved. Saved play will sync when online."
	_send_next()

func _copy_support_id() -> void:
	if outbox.state.has("player_id"):
		DisplayServer.clipboard_set(str(outbox.state.player_id))
		sync_note = "Support ID copied. Share it only with the alpha operator for help or deletion."
		_update_hud()

func _tile_to_screen(tile: Vector2i) -> Vector2:
	return ORIGIN + Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)

func _screen_to_tile(screen: Vector2) -> Vector2i:
	var dx := (screen.x - ORIGIN.x) / (TILE_W * 0.5)
	var dy := (screen.y - ORIGIN.y) / (TILE_H * 0.5)
	return Vector2i(roundi((dx + dy) * 0.5), roundi((dy - dx) * 0.5))

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0, -TILE_H * 0.5), center + Vector2(TILE_W * 0.5, 0),
		center + Vector2(0, TILE_H * 0.5), center + Vector2(-TILE_W * 0.5, 0)])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("17212a"))
	for y in range(Skirmish.HEIGHT):
		for x in range(Skirmish.WIDTH):
			var tile := Vector2i(x, y)
			var center := _tile_to_screen(tile)
			var color := Color("526c5d") if (x + y) % 2 == 0 else Color("496251")
			if sim._wall(tile):
				color = Color("263a4a")
			if tile == marker:
				color = Color("7a9ccd")
			draw_colored_polygon(_diamond(center), color)
			draw_polyline(_diamond(center) + PackedVector2Array([_diamond(center)[0]]), Color("283b40"), 1.0)
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var source: Dictionary = sim.sources[side]
		if source.amount > 0:
			var center := _tile_to_screen(source.pos)
			draw_circle(center + Vector2(0, -9), 11.0, Color("e7b34a"))
			draw_string(ThemeDB.fallback_font, center + Vector2(-10, -20), str(source.amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	var ids: Array = sim.entities.keys()
	ids.sort()
	for id in ids:
		var e: Dictionary = sim.entities[id]
		if e.kind not in ["command_post", "barracks"]:
			continue
		var color := Color("4b9ead") if e.side == Skirmish.HUMAN else Color("be665a")
		if not e.complete:
			color = Color("a89172")
		for oy in range(2):
			for ox in range(2):
				draw_colored_polygon(_diamond(_tile_to_screen(e.pos + Vector2i(ox, oy))), color)
		var center := _tile_to_screen(e.pos + Vector2i(1, 0)) + Vector2(0, -16)
		draw_string(ThemeDB.fallback_font, center, "%s %d" % ["HQ" if e.kind == "command_post" else "POST", maxi(0, e.hp)], HORIZONTAL_ALIGNMENT_CENTER, 75, 15, Color.WHITE)
		if id == selected_id:
			draw_arc(center + Vector2(0, 10), 24, 0, TAU, 24, Color("f2de69"), 2.0)
	for id in ids:
		var e: Dictionary = sim.entities[id]
		if e.kind not in ["worker", "melee", "ranged"]:
			continue
		var center := _tile_to_screen(e.pos) + Vector2(0, -10)
		var color := Color("6dd4df") if e.side == Skirmish.HUMAN else Color("ef8272")
		if e.kind == "worker":
			draw_circle(center, 8, color)
		elif e.kind == "melee":
			draw_rect(Rect2(center - Vector2(8, 8), Vector2(16, 16)), color)
		else:
			draw_colored_polygon(PackedVector2Array([center + Vector2(0, -10), center + Vector2(10, 8), center + Vector2(-10, 8)]), color)
		draw_string(ThemeDB.fallback_font, center + Vector2(-8, -13), str(e.hp), HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
		if id == selected_id:
			draw_arc(center + Vector2(0, 5), 16, 0, TAU, 24, Color("f2de69"), 2.0)
	if placing:
		var preview_tile := _screen_to_tile(get_global_mouse_position())
		var valid: bool = sim._clear_footprint(preview_tile) and sim.stockpile[Skirmish.HUMAN] >= Skirmish.COST.barracks
		for oy in range(2):
			for ox in range(2):
				draw_colored_polygon(_diamond(_tile_to_screen(preview_tile + Vector2i(ox, oy))),
					Color(0.8, 0.9, 0.3, 0.55) if valid else Color(0.9, 0.25, 0.2, 0.55))
