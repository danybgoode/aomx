extends Node2D

const Skirmish = preload("res://skirmish.gd")
const FunnelOutbox = preload("res://funnel_outbox.gd")
const AlphaConfig = preload("res://alpha_config.gd")
const ArtCatalog = preload("res://art_catalog.gd")
const TILE_W := 48.0
const TILE_H := 24.0
const ORIGIN := Vector2(640, 65)
const BOARD_CENTER := Vector2(640, 305)
const TICK_SECONDS := 0.1
const ZOOM_MIN := 1.0
const ZOOM_MAX := 1.25
const ZOOM_STEP := 0.1

var sim = Skirmish.new()
var art = ArtCatalog.new()
var outbox = FunnelOutbox.new()
var choosing_faction := true
var setup_panel: PanelContainer
var setup_goal: Label
var match_id := ""
var completion_queued := false
var selected_id := -1
var placing := false
var marker := Vector2i(-1, -1)
var board_zoom := 1.1
var order_flash_tile := Vector2i(-1, -1)
var order_flash_text := ""
var order_flash_seconds := 0.0
var order_flash_ok := true
var accumulator := 0.0
var syncing := false
var sync_note := ""
var hud: Label
var instructions: Label
var request: HTTPRequest
var invite_code := ""
var invite_input: LineEdit

func _ready() -> void:
	art.load_manifest()
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	outbox.game_version = Skirmish.GAME_VERSION
	outbox.content_version = Skirmish.CONTENT_VERSION
	outbox.queue_open_for_launch()
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
		invite_input.size = Vector2(300, 42)
		invite_input.add_theme_font_size_override("font_size", 18)
		invite_input.placeholder_text = "Enter private alpha invite code"
		invite_input.secret = true
		layer.add_child(invite_input)
		var invite_button := Button.new()
		invite_button.text = "Save invite code"
		invite_button.position = Vector2(335, 16)
		invite_button.add_theme_font_size_override("font_size", 18)
		invite_button.pressed.connect(_save_invite_code)
		layer.add_child(invite_button)
		var support_button := Button.new()
		support_button.text = "Copy support ID"
		support_button.position = Vector2(22, 65)
		support_button.add_theme_font_size_override("font_size", 18)
		support_button.pressed.connect(_copy_support_id)
		layer.add_child(support_button)
	hud = Label.new()
	hud.position = Vector2(22, 600)
	hud.size = Vector2(1236, 140)
	hud.add_theme_font_size_override("font_size", 16)
	layer.add_child(hud)
	instructions = Label.new()
	instructions.position = Vector2(22, 756)
	instructions.add_theme_font_size_override("font_size", 18)
	instructions.text = "Click blue unit · Right-click order · B build · 1/2/3 recruit · +/- or wheel zoom · G fullscreen · R restart · F sync"
	layer.add_child(instructions)
	_build_faction_setup(layer)
	_show_setup()
	_update_hud()

func _build_faction_setup(layer: CanvasLayer) -> void:
	setup_panel = PanelContainer.new()
	setup_panel.position = Vector2(235, 105)
	setup_panel.size = Vector2(810, 420)
	layer.add_child(setup_panel)
	var margin := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 24)
	setup_panel.add_child(margin)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 16)
	margin.add_child(column)
	var title := Label.new()
	title.text = "Choose a faction"
	title.add_theme_font_size_override("font_size", 30)
	column.add_child(title)
	setup_goal = Label.new()
	setup_goal.text = "Win by destroying the opposing command post or holding La Roma for 60 seconds."
	setup_goal.add_theme_font_size_override("font_size", 18)
	column.add_child(setup_goal)
	var regios := Button.new()
	regios.text = "Regios — workers deliver 5 gold; combat units cost +1 gold"
	regios.custom_minimum_size.y = 72
	regios.add_theme_font_size_override("font_size", 20)
	regios.pressed.connect(_choose_faction.bind(Skirmish.REGIOS))
	column.add_child(regios)
	var poblanos := Button.new()
	poblanos.text = "Poblanos — posts +20% HP; workers carry 4 gold; standard fighter costs"
	poblanos.custom_minimum_size.y = 72
	poblanos.add_theme_font_size_override("font_size", 20)
	poblanos.pressed.connect(_choose_faction.bind(Skirmish.POBLANOS))
	column.add_child(poblanos)
	var note := Label.new()
	note.text = "These are fictional strategies, not descriptions of regional people."
	note.add_theme_font_size_override("font_size", 17)
	column.add_child(note)

func _show_setup() -> void:
	choosing_faction = true
	sim = Skirmish.new()
	outbox.faction = "neutral"
	match_id = ""
	accumulator = 0.0
	selected_id = -1
	placing = false
	setup_panel.show()
	instructions.text = "Choose Regios or Poblanos to begin · Press 1 or 2, or click a choice"
	_update_hud()
	queue_redraw()

func _choose_faction(faction: String) -> void:
	if not choosing_faction or faction not in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		return
	_start_match(faction)

func _start_match(faction: String) -> void:
	sim = Skirmish.new(faction)
	outbox.faction = faction
	choosing_faction = false
	setup_panel.hide()
	instructions.text = "Click blue unit · Right-click order · B build · 1/2/3 recruit · +/- or wheel zoom · G fullscreen · R choose faction · F sync"
	match_id = "solo_" + Crypto.new().generate_random_bytes(16).hex_encode()
	completion_queued = false
	selected_id = -1
	placing = false
	marker = Vector2i(-1, -1)
	order_flash_seconds = 0.0
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
			"district_hold":
				sim.ai_enabled = false
				sim._add_entity(Skirmish.HUMAN, "melee", Vector2i(9, 10))
			"district_contest":
				sim.ai_enabled = false
				sim._add_entity(Skirmish.HUMAN, "ranged", Vector2i(9, 10))
				var defender: int = sim._add_entity(Skirmish.COMPUTER, "melee", Vector2i(11, 10))
				sim.entities[defender].hp = 2
	_update_hud()
	queue_redraw()

func _process(delta: float) -> void:
	if choosing_faction:
		return
	if order_flash_seconds > 0.0:
		order_flash_seconds = maxf(0.0, order_flash_seconds - delta)
		queue_redraw()
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
	if choosing_faction:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_1:
				_choose_faction(Skirmish.REGIOS)
			elif event.keycode == KEY_2:
				_choose_faction(Skirmish.POBLANOS)
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_EQUAL, KEY_PLUS, KEY_KP_ADD:
				_change_zoom(ZOOM_STEP)
			KEY_MINUS, KEY_KP_SUBTRACT:
				_change_zoom(-ZOOM_STEP)
			KEY_0:
				board_zoom = 1.1
				sim.feedback = "Board zoom reset to 110%."
			KEY_G:
				get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_B:
				if _selected_kind() == "worker":
					if sim.stockpile[Skirmish.HUMAN] < sim._cost(Skirmish.HUMAN, "barracks"):
						placing = false
						_flash_order(sim.entities[selected_id].pos, "Need 6 gold. Gather first.", false)
					else:
						placing = true
						_flash_order(sim.entities[selected_id].pos, "Choose a clear 2x2 site. Cost: 6.", true)
				else:
					sim.feedback = "Select a worker to build."
			KEY_ESCAPE:
				placing = false
			KEY_1:
				_train("worker")
			KEY_2:
				_train("melee")
			KEY_3:
				_train("ranged")
			KEY_R:
				_show_setup()
			KEY_F:
				_send_next()
	elif event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_change_zoom(ZOOM_STEP)
			_update_hud()
			queue_redraw()
			return
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_change_zoom(-ZOOM_STEP)
			_update_hud()
			queue_redraw()
			return
		var tile := _screen_to_tile(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if placing and selected_id != -1:
				var placed: Dictionary = _issue_order("build", tile, tile)
				if placed.ok:
					placing = false
			else:
				var id: int = sim.entity_at(tile)
				selected_id = id if id != -1 and sim.entities[id].side == Skirmish.HUMAN else -1
				if selected_id != -1:
					_flash_order(tile, "%s selected" % sim.entities[selected_id].kind.replace("_", " "), true)
				else:
					sim.feedback = "Select a blue unit or building."
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_id != -1 and sim.entities.has(selected_id):
			var selected: Dictionary = sim.entities[selected_id]
			var target_id: int = sim.entity_at(tile)
			if selected.kind == "worker" and tile == sim.sources[Skirmish.HUMAN].pos:
				_issue_order("gather", tile, tile)
			elif selected.kind in ["melee", "ranged"] and target_id != -1 and sim.entities[target_id].side == Skirmish.COMPUTER:
				_issue_order("attack", target_id, tile)
			elif selected.kind in ["worker", "melee", "ranged"]:
				var moved: Dictionary = _issue_order("move", tile, tile)
				if moved.ok:
					marker = tile
			else:
				_flash_order(selected.pos, "Select a unit to give an order.", false)
	_update_hud()
	queue_redraw()

func _train(role: String) -> void:
	if selected_id == -1 or not sim.entities.has(selected_id):
		sim.feedback = "Select a production building."
		return
	_issue_order("train", role, sim.entities[selected_id].pos)

func _issue_order(kind: String, target: Variant, tile: Vector2i) -> Dictionary:
	var result: Dictionary = sim.issue(Skirmish.HUMAN, kind, selected_id, target)
	_flash_order(tile, _order_message(kind, target, result), result.ok)
	return result

func _order_message(kind: String, target: Variant, result: Dictionary) -> String:
	if result.ok:
		match kind:
			"move": return "Moving here."
			"gather": return "Gathering gold."
			"build": return "Building a recruitment post."
			"train": return "%s queued." % str(target).capitalize()
			"attack": return "Attacking target."
	match str(result.get("reason", "invalid_order")):
		"insufficient_stockpile": return "Not enough gold in stockpile."
		"blocked_footprint": return "This 2x2 site is blocked."
		"blocked_or_invalid_tile": return "Cannot move onto this tile."
		"unreachable_tile", "building_unreachable", "target_unreachable", "resource_unreachable": return "No route to target."
		"building_incomplete": return "Wait for construction to finish."
		"queue_full": return "Production queue is full."
		"match_finished": return "Match finished. Press R to restart."
	return str(result.get("reason", "Order failed.")).replace("_", " ").capitalize() + "."

func _flash_order(tile: Vector2i, message: String, ok: bool) -> void:
	order_flash_tile = tile
	order_flash_text = message
	order_flash_ok = ok
	order_flash_seconds = 1.6
	sim.feedback = message

func _change_zoom(delta: float) -> void:
	board_zoom = clampf(snappedf(board_zoom + delta, 0.05), ZOOM_MIN, ZOOM_MAX)
	sim.feedback = "Board zoom: %d%%. 0 resets." % roundi(board_zoom * 100.0)

func _selected_kind() -> String:
	return sim.entities[selected_id].kind if sim.entities.has(selected_id) else ""

func _update_hud() -> void:
	if hud == null:
		return
	if choosing_faction:
		hud.text = "Battle for La Roma · Choose a faction to start\nRegios: carry 5 gold, fighters cost +1 · Poblanos: posts +20%% HP, carry 4, standard fighter costs\nWin by destroying the opposing command post or holding La Roma for 60 seconds.\nSync: %s %s" % [outbox.summary(), sync_note]
		return
	if selected_id != -1 and not sim.entities.has(selected_id):
		selected_id = -1
	var human_post := sim._find(Skirmish.HUMAN, "command_post")
	var enemy_post := sim._find(Skirmish.COMPUTER, "command_post")
	var own_hp: int = maxi(0, sim.entities[human_post].hp) if human_post != -1 else 0
	var enemy_hp: int = maxi(0, sim.entities[enemy_post].hp) if enemy_post != -1 else 0
	var chosen := "none" if selected_id == -1 else "%s #%d (%d HP)" % [sim.entities[selected_id].kind.replace("_", " "), selected_id, sim.entities[selected_id].hp]
	var total_seconds: int = floori(float(sim.tick_number) / 10.0)
	var opponent_note := "Opponent pursues La Roma and your command post."
	hud.text = "Battle for La Roma · %s vs %s · %s · %s\nStockpile %d · Gold left %d · Our units %d · Opponent %d · Time %02d:%02d · %s\nSelected: %s · Command posts %d / %d HP\nLa Roma: %s\nLast action: %s\nSync: %s %s" % [
		sim.factions[Skirmish.HUMAN].capitalize(), sim.factions[Skirmish.COMPUTER].capitalize(), AlphaConfig.CHANNEL, AlphaConfig.BUILD_ID,
		sim.stockpile[Skirmish.HUMAN], sim.sources[Skirmish.HUMAN].amount,
		sim._count_units(Skirmish.HUMAN), sim._count_units(Skirmish.COMPUTER),
		floori(float(total_seconds) / 60.0), total_seconds % 60, "Result: %s. Press R to restart." % sim.result if sim.result != "" else opponent_note,
		chosen, own_hp, enemy_hp, _district_note(), sim.feedback,
		_sync_brief(), sync_note]

func _sync_brief() -> String:
	if outbox.state.is_empty():
		return "Local storage unavailable."
	var pending := 0
	var synced := 0
	var attention := 0
	for item in outbox.state.events:
		match item.status:
			"pending": pending += 1
			"accepted": synced += 1
			"needs_attention": attention += 1
	return "%d pending · %d synced · %d need attention." % [pending, synced, attention]

func _district_note() -> String:
	match sim.district_state:
		"human_hold": return "Your hold %02d:%02d / 01:00. Keep enemy fighters out." % [floori(float(sim.district_progress) / 600.0), floori(float(sim.district_progress) / 10.0) % 60]
		"computer_hold": return "Enemy hold %02d:%02d / 01:00 — send a fighter into the marked center!" % [floori(float(sim.district_progress) / 600.0), floori(float(sim.district_progress) / 10.0) % 60]
		"contested": return "Contested — both armies are inside; timer reset."
		"reset": return "Empty — hold reset."
		"terminal": return "Complete: %s (%s)." % [sim.result, sim.result_reason.replace("_", " ")]
	return "Neutral — move a melee or ranged unit into the marked 3x3 center."

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
	screen = BOARD_CENTER + (screen - BOARD_CENTER) / board_zoom
	var dx := (screen.x - ORIGIN.x) / (TILE_W * 0.5)
	var dy := (screen.y - ORIGIN.y) / (TILE_H * 0.5)
	return Vector2i(roundi((dx + dy) * 0.5), roundi((dy - dx) * 0.5))

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0, -TILE_H * 0.5), center + Vector2(TILE_W * 0.5, 0),
		center + Vector2(0, TILE_H * 0.5), center + Vector2(-TILE_W * 0.5, 0)])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("17212a"))
	draw_set_transform(BOARD_CENTER * (1.0 - board_zoom), 0.0, Vector2.ONE * board_zoom)
	for y in range(Skirmish.HEIGHT):
		for x in range(Skirmish.WIDTH):
			var tile := Vector2i(x, y)
			var center := _tile_to_screen(tile)
			var color := Color("526c5d") if (x + y) % 2 == 0 else Color("496251")
			if sim._wall(tile):
				color = Color("263a4a")
			elif sim._in_district(tile):
				color = Color("7b6840") if sim.district_state in ["neutral", "reset"] else Color("3b8a96") if sim.district_state == "human_hold" else Color("a6564a") if sim.district_state == "computer_hold" else Color("89578c")
			if tile == marker:
				color = Color("7a9ccd")
			if not sim._wall(tile) and not sim._in_district(tile) and (x + y) % 2 == 0:
				draw_texture(art.texture("terrain_grass_0"), center - Vector2(24, 12))
			else:
				draw_colored_polygon(_diamond(center), color)
			draw_polyline(_diamond(center) + PackedVector2Array([_diamond(center)[0]]), Color("283b40"), 1.0)
	draw_string(ThemeDB.fallback_font, _tile_to_screen(Vector2i(10, 9)) + Vector2(-58, -38), "LA ROMA 3x3", HORIZONTAL_ALIGNMENT_CENTER, 116, 17, Color.WHITE)
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
		if e.kind == "command_post" and sim.factions[e.side] == Skirmish.POBLANOS:
			var art_id := "building_command_post_blue"
			draw_texture(art.texture(art_id), _tile_to_screen(e.pos) + Vector2(0, 36) - art.pivot(art_id))
		else:
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
		if e.kind == "worker" and sim.factions[e.side] == Skirmish.POBLANOS:
			var art_id := "unit_worker_blue"
			draw_texture(art.texture(art_id), _tile_to_screen(e.pos) - art.pivot(art_id))
		elif e.kind == "worker":
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
		var valid: bool = sim._clear_footprint(preview_tile) and sim.stockpile[Skirmish.HUMAN] >= sim._cost(Skirmish.HUMAN, "barracks")
		for oy in range(2):
			for ox in range(2):
				draw_colored_polygon(_diamond(_tile_to_screen(preview_tile + Vector2i(ox, oy))),
					Color(0.8, 0.9, 0.3, 0.55) if valid else Color(0.9, 0.25, 0.2, 0.55))
	if order_flash_seconds > 0.0 and order_flash_tile.x >= 0:
		var flash_center := _tile_to_screen(order_flash_tile)
		var flash_color := Color("82e7d0") if order_flash_ok else Color("ff8b7e")
		draw_arc(flash_center, 22, 0, TAU, 32, flash_color, 3.0)
		draw_string(ThemeDB.fallback_font, flash_center + Vector2(-100, -26), order_flash_text,
			HORIZONTAL_ALIGNMENT_CENTER, 200, 18, flash_color)
