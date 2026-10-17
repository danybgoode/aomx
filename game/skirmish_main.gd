extends Node2D

const Skirmish = preload("res://skirmish.gd")
const FunnelOutbox = preload("res://funnel_outbox.gd")
const AlphaConfig = preload("res://alpha_config.gd")
const ArtCatalog = preload("res://art_catalog.gd")
const BattleHud = preload("res://ui/battle_hud.gd")
const TILE_W := 48.0
const TILE_H := 24.0
const ORIGIN := Vector2(640, 65)
const BOARD_CENTER := Vector2(640, 305)
const TICK_SECONDS := 0.1
const ZOOM_MIN := 0.7
const ZOOM_MAX := 2.1
const ZOOM_STEP := 0.1
const UNIT_ART_SCALE := 0.75

var sim = Skirmish.new()
var art = ArtCatalog.new()
var outbox = FunnelOutbox.new()
var choosing_faction := true
var setup_panel: PanelContainer
var setup_goal: Label
var setup_regios: Button
var setup_poblanos: Button
var setup_note: Label
var match_id := ""
var completion_queued := false
var selected_id := -1
var selected_ids: Array[int] = []
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var drag_active := false
var hovered_entity_id := -1
var hovered_source_side := -1
var placing := false
var target_mode := ""
var marker := Vector2i(-1, -1)
var board_zoom := 1.1
var zoom_adjustment := 0.0
var board_pan := Vector2.ZERO
var hud_ui: Control
var paused := false
var last_ui_signature := ""
var last_group_signature := ""
var last_event_entities: Dictionary = {}
var last_district_state := "neutral"
var last_attack_notice_tick := -1000
var last_selected_hp := -1
var last_alert_state := ""
var order_flash_tile := Vector2i(-1, -1)
var order_flash_text := ""
var order_flash_seconds := 0.0
var order_flash_ok := true
var accumulator := 0.0
var syncing := false
var sync_note := ""
var hud: Label
var selection_title: Label
var selection_details: Label
var selection_portrait: TextureRect
var command_help: Label
var command_buttons: Dictionary = {}
var command_panel: Panel
var instructions: Label
var hover_hint: Label
var request: HTTPRequest
var invite_code := ""
var invite_input: LineEdit
var prior_unit_positions: Dictionary = {}
var unit_facing: Dictionary = {}

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
	_build_match_hud(layer)
	instructions = Label.new()
	instructions.visible = false
	layer.add_child(instructions)
	hover_hint = Label.new()
	hover_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hover_hint.add_theme_font_size_override("font_size", 14)
	hover_hint.add_theme_color_override("font_color", Color("ffe391"))
	layer.add_child(hover_hint)
	_build_faction_setup(layer)
	get_viewport().size_changed.connect(_layout_setup)
	_layout_setup()
	_show_setup()
	_update_hud()

func _build_match_hud(layer: CanvasLayer) -> void:
	hud_ui = BattleHud.new()
	layer.add_child(hud_ui)
	hud_ui.command.connect(_activate_command)
	hud_ui.subset_requested.connect(_select_subset)
	hud_ui.navigate.connect(_navigate_minimap)
	hud_ui.minimap.terrain_classifier = Callable(self, "_terrain_id")
	hud_ui.menu_requested.connect(_toggle_diagnostics)
	hud_ui.pause_requested.connect(_toggle_pause)
	hud_ui.restart_requested.connect(_restart_match)
	hud = hud_ui.diagnostics_label
	selection_title = hud_ui.selection_title
	selection_details = hud_ui.selection_details
	selection_portrait = hud_ui.selection_portrait
	command_help = hud_ui.command_help
	command_buttons = hud_ui.command_buttons
	command_panel = hud_ui.command_panel
	invite_input = hud_ui.invite_input
	hud_ui.invite_save.pressed.connect(_save_invite_code)
	hud_ui.support_copy.pressed.connect(_copy_support_id)
	if AlphaConfig.CHANNEL != "development":
		var invite_path := "user://alpha-invite-code.txt"
		if FileAccess.file_exists(invite_path):
			invite_code = FileAccess.get_file_as_string(invite_path).strip_edges()
	hud_ui.invite_input.visible = AlphaConfig.CHANNEL != "development"
	hud_ui.invite_save.visible = AlphaConfig.CHANNEL != "development"

func _toggle_diagnostics() -> void:
	hud_ui.diagnostics.visible = not hud_ui.diagnostics.visible
	_update_hud()

func _toggle_pause() -> void:
	paused = not paused
	hud_ui.pause_button.text = ">" if paused else "II"
	hud_ui.show_notice("Paused" if paused else "Resumed")

func _restart_match() -> void:
	if choosing_faction:
		return
	_start_match(sim.factions[Skirmish.HUMAN])
	hud_ui.show_notice("New match started")

func _navigate_minimap(tile: Vector2i) -> void:
	var top_edge: float = (hud_ui.get_global_transform() * (hud_ui.top.position + Vector2(0, hud_ui.top.size.y))).y
	var bottom_edge: float = (hud_ui.get_global_transform() * hud_ui.bottom.position).y
	var view_center := Vector2(get_viewport().get_visible_rect().size.x * 0.5, (top_edge + bottom_edge) * 0.5)
	board_pan = (view_center - BOARD_CENTER - _board_view_offset()) - (_tile_to_screen(tile) - BOARD_CENTER) * board_zoom
	board_pan = board_pan.clamp(Vector2(-320, -190), Vector2(320, 190))
	hud_ui.minimap.camera_tile = tile
	hud_ui.minimap.queue_redraw()
	queue_redraw()

func _build_faction_setup(layer: CanvasLayer) -> void:
	setup_panel = PanelContainer.new()
	setup_panel.position = Vector2(235, 105)
	setup_panel.size = Vector2(810, 420)
	setup_panel.add_theme_stylebox_override("panel", preload("res://ui/hud_skin.gd").panel(10, true))
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
	regios.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preload("res://ui/hud_skin.gd").apply_button(regios)
	column.add_child(regios)
	setup_regios = regios
	var poblanos := Button.new()
	poblanos.text = "Poblanos — posts +20% HP; workers carry 4 gold; standard fighter costs"
	poblanos.custom_minimum_size.y = 72
	poblanos.add_theme_font_size_override("font_size", 20)
	poblanos.pressed.connect(_choose_faction.bind(Skirmish.POBLANOS))
	poblanos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preload("res://ui/hud_skin.gd").apply_button(poblanos)
	column.add_child(poblanos)
	setup_poblanos = poblanos
	var note := Label.new()
	note.text = "These are fictional strategies, not descriptions of regional people."
	note.add_theme_font_size_override("font_size", 17)
	column.add_child(note)
	setup_note = note

func _layout_setup() -> void:
	if setup_panel == null:
		return
	var view := get_viewport().get_visible_rect().size
	var mobile := view.x < 950.0 or view.y < 560.0
	var landscape := view.x > view.y
	setup_goal.text = "Destroy enemy post or hold La Roma for 60s." if mobile and not landscape else ("Destroy the enemy post or hold La Roma for 60 seconds." if mobile else "Win by destroying the opposing command post or holding La Roma for 60 seconds.")
	setup_goal.add_theme_font_size_override("font_size", 14 if mobile else 18)
	setup_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_regios.text = ("REGIOS  •  +5 gold deliveries" if not landscape else "REGIOS  •  workers deliver 5 gold; fighters cost +1") if mobile else "Regios — workers deliver 5 gold; combat units cost +1 gold"
	setup_poblanos.text = ("POBLANOS  •  tougher posts" if not landscape else "POBLANOS  •  tougher posts; workers carry 4 gold") if mobile else "Poblanos — posts +20% HP; workers carry 4 gold; standard fighter costs"
	setup_note.text = "Fictional faction bonuses." if mobile and not landscape else "These are fictional strategies, not descriptions of regional people."
	for b in [setup_regios, setup_poblanos]:
		b.custom_minimum_size.y = 50 if mobile and landscape else (65 if mobile else 72)
		b.add_theme_font_size_override("font_size", 15 if mobile else 20)
	setup_note.add_theme_font_size_override("font_size", 12 if mobile else 17)
	setup_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var column: VBoxContainer = setup_panel.get_child(0).get_child(0)
	column.add_theme_constant_override("separation", 8 if mobile else 16)
	var title: Label = column.get_child(0)
	title.add_theme_font_size_override("font_size", 22 if mobile else 30)
	setup_panel.size = Vector2(minf(810, view.x - 24), 280.0 if mobile and landscape else (330.0 if mobile else minf(420, view.y - 24)))
	setup_panel.position = (view - setup_panel.size) * 0.5
	_apply_resize_zoom(view)
	queue_redraw()

func _show_setup() -> void:
	choosing_faction = true
	sim = Skirmish.new()
	outbox.faction = "neutral"
	match_id = ""
	accumulator = 0.0
	selected_id = -1
	selected_ids.clear()
	last_group_signature = ""
	last_ui_signature = ""
	hovered_entity_id = -1
	hovered_source_side = -1
	placing = false
	target_mode = ""
	prior_unit_positions.clear()
	unit_facing.clear()
	board_pan = Vector2.ZERO
	_reset_zoom()
	paused = false
	last_event_entities.clear()
	last_district_state = "neutral"
	setup_panel.show()
	hover_hint.text = ""
	instructions.text = "Choose Regios or Poblanos to begin · Press 1 or 2, or click a choice"
	_update_hud()
	queue_redraw()

func _choose_faction(faction: String) -> void:
	if not choosing_faction or faction not in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		return
	_start_match(faction)

func _start_match(faction: String) -> void:
	sim = Skirmish.new(faction)
	paused = false
	hud_ui.pause_button.text = "II"
	hud_ui.diagnostics.hide()
	outbox.faction = faction
	choosing_faction = false
	setup_panel.hide()
	instructions.text = "Click to select · Right-click to order · B build · 1/2/3 recruit · Esc cancel · +/- zoom · G fullscreen · R factions · F sync"
	match_id = "solo_" + Crypto.new().generate_random_bytes(16).hex_encode()
	completion_queued = false
	selected_id = -1
	selected_ids.clear()
	last_group_signature = ""
	last_ui_signature = ""
	hovered_entity_id = -1
	hovered_source_side = -1
	placing = false
	target_mode = ""
	prior_unit_positions.clear()
	unit_facing.clear()
	last_event_entities.clear()
	for id in sim.entities:
		last_event_entities[id] = sim.entities[id].duplicate(true)
	last_district_state = sim.district_state
	marker = Vector2i(-1, -1)
	_reset_zoom()
	if get_viewport().get_visible_rect().size.x < 950:
		_navigate_minimap(Vector2i(4, 3))
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
	if choosing_faction or paused or hud_ui.restart_scrim.visible:
		return
	_refresh_hover()
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
		for id in selected_ids.duplicate():
			if not sim.entities.has(id):
				selected_ids.erase(id)
		if selected_id != -1 and not sim.entities.has(selected_id):
			selected_id = selected_ids[0] if not selected_ids.is_empty() else -1
			target_mode = ""
			placing = false
		_observe_events()
		_update_unit_facing()
		_update_hud()
		_refresh_hover()
		queue_redraw()

func _observe_events() -> void:
	for id in sim.entities:
		var entity: Dictionary = sim.entities[id]
		if entity.side != Skirmish.HUMAN:
			continue
		if not last_event_entities.has(id):
			if entity.kind in ["worker", "melee", "ranged"]:
				hud_ui.show_notice("%s ready" % entity.kind.capitalize())
		elif not last_event_entities[id].complete and entity.complete:
			hud_ui.show_notice("Recruitment post complete")
		elif entity.hp < last_event_entities[id].hp and sim.tick_number - last_attack_notice_tick > 50:
			hud_ui.show_notice("Unit under attack", true)
			last_attack_notice_tick = sim.tick_number
	if sim.district_state != last_district_state:
		if sim.district_state == "human_hold":
			hud_ui.show_notice("La Roma captured • hold for 01:00")
		elif sim.district_state == "computer_hold":
			hud_ui.show_notice("Enemy holds La Roma • contest it", true)
	last_district_state = sim.district_state
	last_event_entities.clear()
	for id in sim.entities:
		last_event_entities[id] = sim.entities[id].duplicate(true)

func _unhandled_input(event: InputEvent) -> void:
	if hud_ui != null and hud_ui.restart_scrim.visible:
		if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
			hud_ui.cancel_restart()
		return
	if paused:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			_toggle_pause()
		elif event is InputEventKey and event.pressed and event.keycode == KEY_TAB:
			_toggle_diagnostics()
		return
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
				_reset_zoom()
				sim.feedback = "Board zoom fit to window."
			KEY_G:
				get_window().mode = Window.MODE_WINDOWED if get_window().mode == Window.MODE_FULLSCREEN else Window.MODE_FULLSCREEN
			KEY_B:
				_activate_command("build")
			KEY_M:
				_activate_command("move")
			KEY_H:
				_activate_command("gather")
			KEY_A:
				_activate_command("attack")
			KEY_SPACE:
				_toggle_pause()
			KEY_ESCAPE:
				placing = false
				target_mode = ""
				sim.feedback = "Order canceled."
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
			KEY_TAB:
				_toggle_diagnostics()
	elif event is InputEventMouseMotion and drag_active:
		drag_current = event.position
		queue_redraw()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if drag_active and drag_start.distance_to(event.position) > 12:
			_select_drag(Rect2(drag_start, event.position - drag_start).abs(), event.shift_pressed)
		drag_active = false
		queue_redraw()
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
			drag_active = target_mode.is_empty()
			drag_start = event.position
			drag_current = event.position
			if target_mode != "" and selected_id != -1:
				_complete_target_order(event.position, tile)
			else:
				var id: int = _pick_visual_entity(event.position, Skirmish.HUMAN)
				if id == -1:
					id = sim.entity_at(tile)
				if id != -1 and sim.entities[id].side == Skirmish.HUMAN:
					if event.shift_pressed:
						if id in selected_ids:
							selected_ids.erase(id)
						else:
							selected_ids.append(id)
					else:
						selected_ids = [id]
				else:
					selected_ids.clear()
				selected_id = selected_ids[0] if not selected_ids.is_empty() else -1
				target_mode = ""
				placing = false
				if selected_id != -1:
					_flash_order(sim.entities[selected_id].pos, "%s selected" % sim.entities[selected_id].kind.replace("_", " "), true)
				else:
					sim.feedback = "Select your unit or building."
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected_id != -1 and sim.entities.has(selected_id):
			var selected: Dictionary = sim.entities[selected_id]
			var target_id: int = _pick_visual_entity(event.position, Skirmish.COMPUTER)
			if target_id == -1:
				target_id = sim.entity_at(tile)
			var gold_tile: Vector2i = sim.sources[Skirmish.HUMAN].pos
			if _command_state("gather").visible and (_pick_visual_source(event.position) == Skirmish.HUMAN or tile == gold_tile):
				_issue_order("gather", gold_tile, gold_tile)
			elif _command_state("attack").visible and target_id != -1 and sim.entities[target_id].side == Skirmish.COMPUTER:
				_issue_order("attack", target_id, sim.entities[target_id].pos)
			elif _command_state("move").visible:
				var moved: Dictionary = _issue_order("move", tile, tile)
				if moved.ok:
					marker = tile
			else:
				_flash_order(selected.pos, "Select a unit to give an order.", false)
			target_mode = ""
			placing = false
	_update_hud()
	_refresh_hover()
	queue_redraw()

func _select_drag(rect: Rect2, additive: bool) -> void:
	var ids: Array[int] = []
	if additive:
		ids.assign(selected_ids)
	for id in sim.entities:
		var e: Dictionary = sim.entities[id]
		if e.side != Skirmish.HUMAN or e.kind not in ["worker", "melee", "ranged"]:
			continue
		var screen := BOARD_CENTER + (_actor_ground(e) - BOARD_CENTER) * board_zoom + board_pan + _board_view_offset()
		if rect.has_point(screen) and id not in ids:
			ids.append(id)
	selected_ids = ids
	selected_id = selected_ids[0] if not selected_ids.is_empty() else -1
	target_mode = ""
	placing = false
	_update_hud()

func _select_subset(id: int) -> void:
	if id not in selected_ids:
		return
	selected_ids = [id]
	selected_id = id
	_update_hud()
	queue_redraw()

func _train(role: String) -> void:
	if selected_id == -1 or not sim.entities.has(selected_id):
		sim.feedback = "Select a production building."
		return
	_issue_order("train", role, sim.entities[selected_id].pos)

func _issue_order(kind: String, target: Variant, tile: Vector2i) -> Dictionary:
	var result: Dictionary = sim.issue(Skirmish.HUMAN, kind, selected_id, target)
	var accepted := 1 if result.ok else 0
	if kind in ["move", "gather", "attack"] and selected_ids.size() > 1:
		for id in selected_ids:
			if id == selected_id or not sim.entities.has(id):
				continue
			var next: Dictionary = sim.issue(Skirmish.HUMAN, kind, id, target)
			if next.ok:
				accepted += 1
		if accepted > 0:
			result = {"ok": true, "reason": "group_order"}
	_flash_order(tile, "%d units ordered." % accepted if selected_ids.size() > 1 and accepted > 0 else _order_message(kind, target, result), result.ok)
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
	zoom_adjustment = board_zoom - _default_board_zoom(get_viewport().get_visible_rect().size)
	sim.feedback = "Board zoom: %d%%. Resize window or press 0 to fit." % roundi(board_zoom * 100.0)

func _default_board_zoom(view: Vector2) -> float:
	# Keep the touch board legible; its minimap handles navigation in narrow layouts.
	if view.x < 620.0 or view.y < 560.0:
		return 1.1
	return clampf(1.1 * minf(view.x / 1280.0, view.y / 800.0), 0.72, 1.9)

func _apply_resize_zoom(view: Vector2) -> void:
	board_zoom = clampf(_default_board_zoom(view) + zoom_adjustment, ZOOM_MIN, ZOOM_MAX)

func _reset_zoom() -> void:
	zoom_adjustment = 0.0
	_apply_resize_zoom(get_viewport().get_visible_rect().size)

func _selected_kind() -> String:
	if not sim.entities.has(selected_id):
		return ""
	if selected_ids.size() > 1:
		var first: String = sim.entities[selected_id].kind
		for id in selected_ids:
			if not sim.entities.has(id) or sim.entities[id].kind != first:
				return "mixed"
	return sim.entities[selected_id].kind

func _command_state(action: String) -> Dictionary:
	var kind := _selected_kind()
	var roles: Array[String] = []
	for id in selected_ids:
		if sim.entities.has(id):
			roles.append(sim.entities[id].kind)
	if roles.is_empty() and not kind.is_empty():
		roles.append(kind)
	var mobile_group := not roles.is_empty() and roles.all(func(role_name: String) -> bool: return role_name in ["worker", "melee", "ranged"])
	var fighter_group := not roles.is_empty() and roles.all(func(role_name: String) -> bool: return role_name in ["melee", "ranged"])
	var worker_group := not roles.is_empty() and roles.all(func(role_name: String) -> bool: return role_name == "worker")
	var role := action.trim_prefix("train_")
	var visible := false
	var label := action.replace("_", " ").capitalize()
	var reason := ""
	match action:
		"move": visible = mobile_group
		"gather":
			visible = worker_group
			if visible and sim.sources[Skirmish.HUMAN].amount <= 0:
				reason = "Gold cart empty"
		"build":
			visible = kind == "worker" and selected_ids.size() <= 1
			label = "Build post · %d gold" % sim._cost(Skirmish.HUMAN, "barracks")
			if visible and sim._find(Skirmish.HUMAN, "barracks") != -1:
				reason = "One post limit"
		"attack": visible = fighter_group
		"train_worker", "train_melee", "train_ranged":
			visible = (kind == "command_post" and role == "worker") or (kind == "barracks" and role in ["melee", "ranged"])
			label = "Recruit %s · %d gold" % [role, sim._cost(Skirmish.HUMAN, role)]
			if visible and not sim.entities[selected_id].complete:
				reason = "Construction in progress"
			elif visible and sim.entities[selected_id].queue.size() >= 3:
				reason = "Queue full"
		"cancel":
			visible = target_mode != ""
			label = "Cancel · Esc"
	if visible and action not in ["move", "gather", "attack", "cancel"] and reason.is_empty() and sim.stockpile[Skirmish.HUMAN] < sim._cost(Skirmish.HUMAN, "barracks" if action == "build" else role):
		reason = "Need %d gold" % sim._cost(Skirmish.HUMAN, "barracks" if action == "build" else role)
	if visible and sim.result != "" and action != "cancel":
		reason = "Match finished"
	return {"visible": visible, "enabled": visible and reason.is_empty(), "reason": reason, "label": label}

func _activate_command(action: String) -> void:
	if paused:
		hud_ui.show_notice("Resume to issue orders")
		return
	if action == "cancel":
		target_mode = ""
		placing = false
		sim.feedback = "Order canceled."
	else:
		var state := _command_state(action)
		if not state.enabled:
			var message: String = state.reason if not state.reason.is_empty() else "Select an actor for that order."
			_flash_order(sim.entities[selected_id].pos if sim.entities.has(selected_id) else Vector2i(-1, -1), message, false)
		elif action.begins_with("train_"):
			_train(action.trim_prefix("train_"))
		else:
			target_mode = action
			placing = action == "build"
			sim.feedback = _target_prompt()
	_update_hud()
	queue_redraw()

func _target_prompt() -> String:
	match target_mode:
		"move": return "Move: click a clear ground tile. Esc cancels."
		"gather": return "Gather: click your gold cart. Esc cancels."
		"build": return "Build: click a clear 2×2 site outside La Roma. Esc cancels."
		"attack": return "Attack: click an enemy unit or post. Esc cancels."
	return ""

func _complete_target_order(screen: Vector2, tile: Vector2i) -> void:
	var result: Dictionary = {"ok": false}
	match target_mode:
		"move":
			result = _issue_order("move", tile, tile)
			if result.ok:
				marker = tile
		"build": result = _issue_order("build", tile, tile)
		"gather":
			var gold_tile: Vector2i = sim.sources[Skirmish.HUMAN].pos
			if _pick_visual_source(screen) == Skirmish.HUMAN or tile == gold_tile:
				result = _issue_order("gather", gold_tile, gold_tile)
			else:
				_flash_order(tile, "Click your gold cart.", false)
		"attack":
			var enemy_id: int = _pick_visual_entity(screen, Skirmish.COMPUTER)
			if enemy_id == -1:
				enemy_id = sim.entity_at(tile)
			if enemy_id != -1 and sim.entities[enemy_id].side == Skirmish.COMPUTER:
				result = _issue_order("attack", enemy_id, sim.entities[enemy_id].pos)
			else:
				_flash_order(tile, "Click an enemy unit or post.", false)
	if result.ok:
		target_mode = ""
		placing = false

func _update_hud() -> void:
	if hud_ui == null:
		return
	var ui = hud_ui
	ui.visible = not choosing_faction
	if choosing_faction:
		return
	if selected_id != -1 and not sim.entities.has(selected_id):
		selected_id = -1
		selected_ids.clear()
	var seconds := floori(float(sim.tick_number) / 10.0)
	ui.timer_label.text = "%02d:%02d" % [seconds / 60, seconds % 60]
	ui.faction_label.text = sim.factions[Skirmish.HUMAN].to_upper()
	ui.gold_label.text = str(sim.stockpile[Skirmish.HUMAN])
	ui.gold_label.tooltip_text = "%d gold in stockpile • %d remaining at your cart" % [sim.stockpile[Skirmish.HUMAN], sim.sources[Skirmish.HUMAN].amount]
	ui.objective_title.text = _district_note()
	ui.objective_progress.value = sim.district_progress
	ui.objective_progress.tooltip_text = _district_note()
	ui.minimap.sim = sim
	var visible_view := get_viewport().get_visible_rect().size
	var hud_bottom: float = (ui.get_global_transform() * ui.bottom.position).y
	ui.minimap.view_span = Vector2(20, 20) if visible_view.x >= 1000 else Vector2(clampf(visible_view.x / 48.0, 5, 20), clampf((hud_bottom - 60.0) / 24.0, 5, 20))
	ui.minimap.queue_redraw()
	var own_post := sim._find(Skirmish.HUMAN, "command_post")
	var enemy_post := sim._find(Skirmish.COMPUTER, "command_post")
	var own_hp: int = maxi(0, sim.entities[own_post].hp) if own_post != -1 else 0
	var enemy_hp: int = maxi(0, sim.entities[enemy_post].hp) if enemy_post != -1 else 0
	ui.secondary_status.text = "CENTER  %s\nHOLD  %02d:%02d / 01:00\n\nCommand posts\nOurs %d HP  •  Enemy %d HP" % [sim.district_state.replace("_", " ").capitalize(),
		floori(float(sim.district_progress) / 600.0), floori(float(sim.district_progress) / 10.0) % 60, own_hp, enemy_hp]
	var group_signature := str(selected_ids)
	if group_signature != last_group_signature:
		last_group_signature = group_signature
		if selected_ids.size() > 1:
			var portraits: Array[Dictionary] = []
			for id in selected_ids:
				if sim.entities.has(id):
					portraits.append({"id": id, "texture": art.texture(_actor_art_id(sim.entities[id]))})
			ui.set_group(portraits)
		else:
			ui.set_group([])
	if selected_id == -1:
		ui.set_selection(art.texture("building_command_post_%s" % _faction_color(Skirmish.HUMAN)), "NO SELECTION", sim.factions[Skirmish.HUMAN].capitalize(), 0, 0, "Select a unit or post", "")
	else:
		var actor: Dictionary = sim.entities[selected_id]
		var max_hp: int = sim._starting_health(Skirmish.HUMAN, actor.kind)
		var activity: String = actor.job.capitalize()
		if actor.kind == "worker" and actor.carry > 0:
			activity += "  •  carry %d" % actor.carry
		var stats := ""
		if actor.kind in ["melee", "ranged"]:
			stats = "⚔ %d  •  range %d" % [Skirmish.DAMAGE[actor.kind], Skirmish.RANGE[actor.kind]]
		elif actor.kind == "worker":
			stats = "Carry cap %d" % sim._carry_limit(Skirmish.HUMAN)
		else:
			stats = "Construction %d%%" % roundi(100.0 * actor.progress / Skirmish.BUILD_TICKS) if not actor.complete else "Ready"
			if not actor.queue.is_empty():
				var first: Dictionary = actor.queue[0]
				stats += "  •  Queue %d: %s %ds" % [actor.queue.size(), first.role, ceili(float(first.remaining) / 10.0)]
		ui.set_selection(art.texture(_actor_art_id(actor)), "%d UNITS" % selected_ids.size() if selected_ids.size() > 1 else "%s #%d" % [actor.kind.replace("_", " ").capitalize(), selected_id],
			sim.factions[Skirmish.HUMAN].capitalize(), actor.hp if selected_ids.size() <= 1 else 0, max_hp if selected_ids.size() <= 1 else 0,
			"Group selected" if selected_ids.size() > 1 else activity, "%d selected • tap a portrait for one" % selected_ids.size() if selected_ids.size() > 1 else stats)
	for action in command_buttons:
		var state := _command_state(action)
		var cost := 0
		if action == "build":
			cost = sim._cost(Skirmish.HUMAN, "barracks")
		elif action.begins_with("train_"):
			cost = sim._cost(Skirmish.HUMAN, action.trim_prefix("train_"))
		ui.set_action(action, state, cost, target_mode == action)
	ui.command_help.text = _target_prompt() if target_mode != "" else ""
	ui.reflow_commands()
	_update_secondary()
	var queue: Array = sim.entities[selected_id].queue if sim.entities.has(selected_id) and _selected_kind() in ["command_post", "barracks"] else []
	ui.set_queue(queue)
	var support := "%s · %s\n%s\n%s" % [AlphaConfig.CHANNEL, AlphaConfig.BUILD_ID, _sync_brief(), sync_note]
	ui.diagnostics_label.text = support
	var attention := false
	if not outbox.state.is_empty():
		for item in outbox.state.events:
			if item.status == "needs_attention":
				attention = true
	var alert := attention or sync_note.contains("could not") or sync_note.contains("unavailable") or sync_note.contains("not accepted") or (AlphaConfig.CHANNEL != "development" and invite_code.is_empty())
	ui.menu_button.text = "..!" if alert else "..."
	if alert and last_alert_state != "attention":
		ui.show_notice("Sync needs attention • open menu", true)
	last_alert_state = "attention" if alert else "clear"
	if sim.result != "":
		ui.show_notice("%s • %s" % [sim.result.to_upper(), sim.result_reason.replace("_", " ")], true)
	elif order_flash_seconds > 0 and not order_flash_text.is_empty():
		ui.show_notice(order_flash_text, not order_flash_ok)

func _update_secondary() -> void:
	var ui = hud_ui
	var kind := _selected_kind()
	var signature := "%s:%d:%d:%d:%d" % [kind, selected_id, selected_ids.size(), sim.stockpile[Skirmish.HUMAN], sim._find(Skirmish.HUMAN, "barracks")]
	if signature == last_ui_signature:
		return
	last_ui_signature = signature
	var cards: Array[Dictionary] = []
	var title := "TACTICAL VIEW"
	if selected_ids.size() > 1:
		title = "GROUP • %d" % selected_ids.size()
	elif kind == "worker":
		title = "CONSTRUCTION"
		var state := _command_state("build")
		cards.append({"texture": art.texture("building_barracks_blue"), "label": "POST\n%d GOLD" % sim._cost(Skirmish.HUMAN, "barracks"),
			"enabled": state.enabled, "reason": state.reason, "cost": sim._cost(Skirmish.HUMAN, "barracks"), "tooltip": "Recruitment post • %d gold\n%s" % [sim._cost(Skirmish.HUMAN, "barracks"), state.reason if not state.reason.is_empty() else "Click, then place on clear ground"], "action": "build"})
	elif kind in ["command_post", "barracks"]:
		title = "PRODUCTION"
		for role: String in (["worker"] if kind == "command_post" else ["melee", "ranged"]):
			var action: String = "train_" + role
			var state := _command_state(action)
			cards.append({"texture": art.texture("unit_%s_blue" % role), "label": "%s\n%d GOLD" % [role.to_upper(), sim._cost(Skirmish.HUMAN, role)],
				"enabled": state.enabled, "reason": state.reason, "cost": sim._cost(Skirmish.HUMAN, role), "tooltip": "%s • %d gold\n%s" % [role.capitalize(), sim._cost(Skirmish.HUMAN, role), state.reason if not state.reason.is_empty() else "Recruit here"], "action": action})
	elif kind in ["melee", "ranged"]:
		title = "FIELD ORDERS"
		cards.append({"texture": art.texture(_actor_art_id(sim.entities[selected_id])), "label": "ATTACK\nA", "enabled": true, "tooltip": "Choose an enemy target • A", "action": "attack"})
	else:
		title = "LA ROMA"
	ui.set_secondary(title, cards)
	if kind == "worker":
		ui.secondary_details.text = "RECRUITMENT POST\n2 × 2 site  •  one allowed"
	elif kind in ["command_post", "barracks"]:
		ui.secondary_details.text = "RECRUIT UNITS\nSpend stockpiled gold"
	elif kind in ["melee", "ranged"]:
		ui.secondary_details.text = "COMBAT\nChoose an enemy target"
	else:
		ui.secondary_details.text = ""

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
		"human_hold": return "Your hold %02d:%02d / 01:00" % [floori(float(sim.district_progress) / 600.0), floori(float(sim.district_progress) / 10.0) % 60]
		"computer_hold": return "Enemy hold %02d:%02d / 01:00 — contest it" % [floori(float(sim.district_progress) / 600.0), floori(float(sim.district_progress) / 10.0) % 60]
		"contested": return "Contested — hold reset"
		"reset": return "Empty — hold reset"
		"terminal": return "Complete: %s (%s)." % [sim.result, sim.result_reason.replace("_", " ")]
	return "Neutral — bring a fighter to center"

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

func _board_view_offset() -> Vector2:
	var view := get_viewport().get_visible_rect().size
	if view.x >= 1000.0 and view.y >= 700.0:
		return (view - Vector2(1280, 800)) * 0.5
	var playable_bottom: float = (hud_ui.get_global_transform() * hud_ui.bottom.position).y if hud_ui != null else view.y - 180.0
	return Vector2(view.x * 0.5 - BOARD_CENTER.x, (playable_bottom + 55.0) * 0.5 - BOARD_CENTER.y)

func _screen_to_board(screen: Vector2) -> Vector2:
	return BOARD_CENTER + (screen - BOARD_CENTER - board_pan - _board_view_offset()) / board_zoom

func _screen_to_tile(screen: Vector2) -> Vector2i:
	screen = _screen_to_board(screen)
	var dx := (screen.x - ORIGIN.x) / (TILE_W * 0.5)
	var dy := (screen.y - ORIGIN.y) / (TILE_H * 0.5)
	return Vector2i(roundi((dx + dy) * 0.5), roundi((dy - dx) * 0.5))

func _sorted_entity_ids() -> Array:
	var ids: Array = sim.entities.keys()
	ids.sort_custom(func(a: int, b: int) -> bool:
		var ea: Dictionary = sim.entities[a]
		var eb: Dictionary = sim.entities[b]
		var ya: int = ea.pos.x + ea.pos.y + (3 if ea.kind in ["command_post", "barracks"] else 0)
		var yb: int = eb.pos.x + eb.pos.y + (3 if eb.kind in ["command_post", "barracks"] else 0)
		return ya < yb if ya != yb else a < b)
	return ids

func _actor_ground(entity: Dictionary) -> Vector2:
	return _tile_to_screen(entity.pos) + (Vector2(0, 36) if entity.kind in ["command_post", "barracks"] else Vector2.ZERO)

func _actor_art_id(entity: Dictionary) -> String:
	var is_building: bool = entity.kind in ["command_post", "barracks"]
	return ("building_" if is_building else "unit_") + entity.kind + "_" + _faction_color(entity.side)

func _pick_visual_entity(screen: Vector2, side: int) -> int:
	var board := _screen_to_board(screen)
	var ids := _sorted_entity_ids()
	ids.reverse()
	# A nearby HQ can overhang a worker; prefer the smaller unit where hit areas overlap.
	for want_building in [false, true]:
		for id in ids:
			var entity: Dictionary = sim.entities[id]
			var is_building: bool = entity.kind in ["command_post", "barracks"]
			if entity.side != side or is_building != want_building:
				continue
			var scale := 1.0 if is_building else UNIT_ART_SCALE
			var delta := (board - _actor_ground(entity)) / scale
			if not is_building and unit_facing.get(id, 1) < 0:
				delta.x = -delta.x
			var art_id := _actor_art_id(entity)
			if art.hit_test(art_id, art.pivot(art_id) + delta):
				return id
	return -1

func _pick_visual_source(screen: Vector2) -> int:
	var source: Dictionary = sim.sources[Skirmish.HUMAN]
	if source.amount <= 0:
		return -1
	var pixel := art.pivot("prop_gold_cart") + _screen_to_board(screen) - _tile_to_screen(source.pos)
	return Skirmish.HUMAN if art.hit_test("prop_gold_cart", pixel) else -1

func _refresh_hover() -> void:
	if choosing_faction or placing:
		if hovered_entity_id != -1 or hovered_source_side != -1 or not hover_hint.text.is_empty():
			hovered_entity_id = -1
			hovered_source_side = -1
			hover_hint.text = ""
			queue_redraw()
		return
	var screen := get_viewport().get_mouse_position()
	var next_entity := _pick_visual_entity(screen, Skirmish.HUMAN)
	var next_source := -1
	if next_entity == -1:
		next_source = _pick_visual_source(screen)
	if next_entity == -1 and next_source == -1 and _selected_kind() in ["melee", "ranged"]:
		next_entity = _pick_visual_entity(screen, Skirmish.COMPUTER)
	var next_hint := ""
	if next_entity != -1:
		var e: Dictionary = sim.entities[next_entity]
		if e.side == Skirmish.HUMAN:
			next_hint = "Selected %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity] if next_entity == selected_id else "Click to select %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity]
		else:
			next_hint = "Right-click to attack %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity]
	elif next_source != -1:
		next_hint = "Right-click to gather gold" if _selected_kind() == "worker" else "Gold source · select a worker to gather"
	if next_entity != hovered_entity_id or next_source != hovered_source_side or next_hint != hover_hint.text:
		hovered_entity_id = next_entity
		hovered_source_side = next_source
		hover_hint.text = next_hint
		hover_hint.position = (screen + Vector2(14, -34)).clamp(Vector2(8, 65), get_viewport().get_visible_rect().size - Vector2(240, 25))
		queue_redraw()

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0, -TILE_H * 0.5), center + Vector2(TILE_W * 0.5, 0),
		center + Vector2(0, TILE_H * 0.5), center + Vector2(-TILE_W * 0.5, 0)])

func _update_unit_facing() -> void:
	var present := {}
	for id in sim.entities:
		var e: Dictionary = sim.entities[id]
		if e.kind not in ["worker", "melee", "ranged"]:
			continue
		present[id] = true
		if prior_unit_positions.has(id):
			var delta: Vector2i = e.pos - prior_unit_positions[id]
			if delta != Vector2i.ZERO:
				unit_facing[id] = 1 if delta.x - delta.y >= 0 else -1
			elif e.job == "attack" and sim.entities.has(e.target_id):
				var target_delta: Vector2i = sim.entities[e.target_id].pos - e.pos
				if target_delta.x != target_delta.y:
					unit_facing[id] = 1 if target_delta.x - target_delta.y > 0 else -1
		prior_unit_positions[id] = e.pos
	for id in prior_unit_positions.keys():
		if not present.has(id):
			prior_unit_positions.erase(id)
			unit_facing.erase(id)

func _terrain_id(tile: Vector2i) -> String:
	var kind := "grass"
	if sim._in_district(tile):
		kind = "plaza"
	elif sim._wall(tile) or tile.y in [4, 15] or tile.x in [5, 14]:
		kind = "asphalt"
	elif tile.x in [4, 6, 13, 15] or tile.y in [3, 5, 14, 16] or (tile.x >= 8 and tile.x <= 12 and tile.y >= 7 and tile.y <= 13):
		kind = "sidewalk"
	return "terrain_%s_%d" % [kind, posmod(tile.x * 13 + tile.y * 7, 4)]

func _faction_color(side: int) -> String:
	return "blue" if sim.factions[side] == Skirmish.POBLANOS else "red"

func _district_color() -> Color:
	match sim.district_state:
		"human_hold": return Color("398ac0") if _faction_color(Skirmish.HUMAN) == "blue" else Color("bf5f51")
		"computer_hold": return Color("398ac0") if _faction_color(Skirmish.COMPUTER) == "blue" else Color("bf5f51")
		"contested": return Color("b086d0")
	return Color("e2c87e")

func _draw_sprite_outline(art_id: String, rect: Rect2, color: Color) -> void:
	var texture := art.texture(art_id)
	for offset in [Vector2(-2, 0), Vector2(2, 0), Vector2(0, -2), Vector2(0, 2)]:
		draw_texture_rect(texture, Rect2(rect.position + offset, rect.size), false, color)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("17212a"))
	draw_set_transform(BOARD_CENTER * (1.0 - board_zoom) + board_pan + _board_view_offset(), 0.0, Vector2.ONE * board_zoom)
	# Decorative props underlay actors so selectable units stay visible at their ground contact.
	for y in range(Skirmish.HEIGHT):
		for x in range(Skirmish.WIDTH):
			var tile := Vector2i(x, y)
			var center := _tile_to_screen(tile)
			draw_texture(art.texture(_terrain_id(tile)), center - Vector2(24, 12))
			if sim._in_district(tile):
				var tint := _district_color()
				tint.a = 0.27 if sim.district_state in ["neutral", "reset"] else 0.45
				draw_colored_polygon(_diamond(center), tint)
			if tile == marker:
				draw_polyline(_diamond(center) + PackedVector2Array([_diamond(center)[0]]), Color("a7dbf2"), 2.0)
			if sim._wall(tile):
				var wall_id := "prop_barricade"
				draw_texture(art.texture(wall_id), center - art.pivot(wall_id))
	for tile in [Vector2i(2, 13), Vector2i(17, 5)]:
		var tree_id := "prop_jacaranda"
		draw_texture(art.texture(tree_id), _tile_to_screen(tile) - art.pivot(tree_id))
	var medallion_id := "prop_plaza_medallion"
	draw_texture(art.texture(medallion_id), _tile_to_screen(Vector2i(10, 10)) - art.pivot(medallion_id))
	draw_string(ThemeDB.fallback_font, _tile_to_screen(Vector2i(10, 9)) + Vector2(-58, -30), "LA ROMA", HORIZONTAL_ALIGNMENT_CENTER, 116, 15, Color.WHITE)
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var source: Dictionary = sim.sources[side]
		if source.amount > 0:
			var center := _tile_to_screen(source.pos)
			var cart_id := "prop_gold_cart"
			if side == hovered_source_side:
				draw_circle(center + Vector2(0, -5), 17, Color(1.0, 0.82, 0.3, 0.24))
				draw_arc(center + Vector2(0, -5), 18, 0, TAU, 24, Color("ffe391"), 2.0)
				_draw_sprite_outline(cart_id, Rect2(center - art.pivot(cart_id), art.texture(cart_id).get_size()), Color("ffe391"))
			draw_texture(art.texture(cart_id), center - art.pivot(cart_id))
			draw_string(ThemeDB.fallback_font, center + Vector2(-22, -45), "GOLD %d" % source.amount,
				HORIZONTAL_ALIGNMENT_CENTER, 44, 12, Color("fff0ba"))
	var ids := _sorted_entity_ids()
	for id in ids:
		var e: Dictionary = sim.entities[id]
		var is_building: bool = e.kind in ["command_post", "barracks"]
		var ground := _actor_ground(e)
		var art_id := _actor_art_id(e)
		var art_scale := 1.0 if is_building else UNIT_ART_SCALE
		var ring_center := ground + Vector2(0, -24 if is_building else -5)
		if id == selected_id:
			draw_circle(ring_center, 23 if is_building else 16, Color(0.12, 0.78, 0.96, 0.26))
		elif id == hovered_entity_id:
			draw_circle(ring_center, 23 if is_building else 15, Color(1.0, 0.83, 0.41, 0.2))
			draw_arc(ring_center, 23 if is_building else 15, 0, TAU, 24, Color("ffe391"), 2.0)
		var bob := 0.0
		if not is_building and e.job in ["move", "attack", "gather", "deliver", "build"]:
			bob = -2.0 if sim.tick_number % 4 < 2 else 0.0
		var sprite_rect := Rect2(ground - art.pivot(art_id) * art_scale + Vector2(0, bob),
			art.texture(art_id).get_size() * art_scale)
		if not is_building and unit_facing.get(id, 1) < 0:
			draw_set_transform(BOARD_CENTER * (1.0 - board_zoom) + board_pan + _board_view_offset() + Vector2(ground.x * 2.0 * board_zoom, 0),
				0.0, Vector2(-board_zoom, board_zoom))
		if id == selected_id or id == hovered_entity_id:
			_draw_sprite_outline(art_id, sprite_rect, Color("7eeaff") if id == selected_id else Color("ffe391"))
		draw_texture_rect(art.texture(art_id), sprite_rect, false)
		if not is_building and unit_facing.get(id, 1) < 0:
			draw_set_transform(BOARD_CENTER * (1.0 - board_zoom) + board_pan + _board_view_offset(), 0.0, Vector2.ONE * board_zoom)
		if is_building and not e.complete:
			draw_rect(Rect2(ground + Vector2(-47, -27), Vector2(94, 26)), Color(0.63, 0.46, 0.28, 0.35))
			draw_rect(Rect2(ground + Vector2(-22, -33), Vector2(44, 4)), Color("3b3029"))
			draw_rect(Rect2(ground + Vector2(-22, -33), Vector2(44.0 * e.progress / Skirmish.BUILD_TICKS, 4)), Color("e5c36f"))
		if is_building and e.hp <= 0:
			draw_rect(Rect2(ground - art.pivot(art_id), art.texture(art_id).get_size()),
				Color(0.15, 0.1, 0.1, 0.6))
		var max_hp: int = sim._starting_health(e.side, e.kind)
		var bar_width := 42.0 if is_building else 24.0
		var bar_y := -art.pivot(art_id).y * art_scale - 4.0
		draw_rect(Rect2(ground + Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width, 4)), Color("242a2b"))
		draw_rect(Rect2(ground + Vector2(-bar_width * 0.5, bar_y), Vector2(bar_width * clampf(float(e.hp) / max_hp, 0, 1), 4)),
			Color("67d69a") if e.side == Skirmish.HUMAN else Color("e76b62"))
		if not is_building and e.job == "attack" and e.cooldown > Skirmish.COOLDOWN.get(e.kind, 1) - 2:
			draw_circle(ground + Vector2(10 * art_scale * unit_facing.get(id, 1), -22 * art_scale + bob), 3.0, Color("ffe2a1"))
		if not is_building and e.kind == "worker" and e.carry > 0:
			draw_circle(ground + Vector2(-11 * art_scale * unit_facing.get(id, 1), -22 * art_scale + bob), 3.0, Color("f9c45e"))
	if sim.entities.has(selected_id):
		var active: Dictionary = sim.entities[selected_id]
		var active_building: bool = active.kind in ["command_post", "barracks"]
		var active_ground := _actor_ground(active)
		draw_arc(active_ground + Vector2(0, -24 if active_building else -5),
			23 if active_building else 16, 0, TAU, 24, Color("7eeaff"), 3.0)
		if not active_building:
			var tip := active_ground + Vector2(0, -art.pivot(_actor_art_id(active)).y * UNIT_ART_SCALE - 9)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -4), tip + Vector2(6, -4), tip + Vector2(0, 4)]),
				Color("7eeaff"))
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
	if drag_active and drag_start.distance_to(drag_current) > 12:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		draw_rect(Rect2(drag_start, drag_current - drag_start).abs(), Color("7eeaff"), false, 2.0)
