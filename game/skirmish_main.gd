extends Node2D

const Skirmish = preload("res://skirmish.gd")
const FunnelOutbox = preload("res://funnel_outbox.gd")
const AlphaConfig = preload("res://alpha_config.gd")
const ArtCatalog = preload("res://art_catalog.gd")
const BattleHud = preload("res://ui/battle_hud.gd")
const MatchSave = preload("res://skirmish_persistence.gd")
const TILE_W := 48.0
const TILE_H := 24.0
const ORIGIN := Vector2(640, 65)
const BOARD_CENTER := Vector2(640, 305)
const TICK_SECONDS := 0.1
const ZOOM_MIN := 0.7
const ZOOM_MAX := 2.1
const ZOOM_STEP := 0.1
const UNIT_ART_SCALE := 0.75
const RESOURCE_IDS := ["comida", "materiales", "varos", "terrenos"]
const BUILD_CHOICES := ["depot", "housing", "registry", "barracks"]
const RESOURCE_COLORS := {"comida": Color("93d38b"), "materiales": Color("c4c8d2"), "varos": Color("f3c666"), "terrenos": Color("b9a4e8")}
const AGE_NAMES := {"foranea": "Foránea", "universitaria": "Universitaria", "godin": "Godín", "gentrificacion": "Gentrificación"}

var sim: Skirmish = Skirmish.new()
var art = ArtCatalog.new()
var outbox = FunnelOutbox.new()
var choosing_faction := true
var setup_panel: PanelContainer
var setup_goal: Label
var setup_regios: Button
var setup_poblanos: Button
var setup_resume: Button
var setup_note: Label
var setup_save_error: Label
var match_id := ""
var completion_queued := false
var selected_id := -1
var selected_ids: Array[int] = []
var drag_start := Vector2.ZERO
var drag_current := Vector2.ZERO
var drag_active := false
var hovered_entity_id := -1
var hovered_source_id := ""
var placing := false
var build_kind := "barracks"
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
var save_path := MatchSave.SAVE_PATH
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
	hud_ui.save_requested.connect(_save_match)
	hud_ui.resume_requested.connect(_resume_match)
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
	regios.text = "Regios — workers carry 5; fighters cost +1 Varos"
	regios.custom_minimum_size.y = 72
	regios.add_theme_font_size_override("font_size", 20)
	regios.pressed.connect(_choose_faction.bind(Skirmish.REGIOS))
	regios.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preload("res://ui/hud_skin.gd").apply_button(regios)
	column.add_child(regios)
	setup_regios = regios
	var poblanos := Button.new()
	poblanos.text = "Poblanos — buildings +20% HP; workers carry 4"
	poblanos.custom_minimum_size.y = 72
	poblanos.add_theme_font_size_override("font_size", 20)
	poblanos.pressed.connect(_choose_faction.bind(Skirmish.POBLANOS))
	poblanos.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preload("res://ui/hud_skin.gd").apply_button(poblanos)
	column.add_child(poblanos)
	setup_poblanos = poblanos
	setup_resume = Button.new()
	setup_resume.text = "Resume saved match"
	setup_resume.custom_minimum_size.y = 50
	setup_resume.pressed.connect(_resume_match)
	preload("res://ui/hud_skin.gd").apply_button(setup_resume)
	column.add_child(setup_resume)
	var note := Label.new()
	note.text = "These are fictional strategies, not descriptions of regional people."
	note.add_theme_font_size_override("font_size", 17)
	column.add_child(note)
	setup_note = note
	setup_save_error = Label.new()
	setup_save_error.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_save_error.add_theme_color_override("font_color", Color("ffb49f"))
	column.add_child(setup_save_error)

func _layout_setup() -> void:
	if setup_panel == null:
		return
	var view := get_viewport().get_visible_rect().size
	var mobile := view.x < 950.0 or view.y < 560.0
	var landscape := view.x > view.y
	setup_goal.text = "Destroy enemy post or hold La Roma for 60s." if mobile and not landscape else ("Destroy the enemy post or hold La Roma for 60 seconds." if mobile else "Win by destroying the opposing command post or holding La Roma for 60 seconds.")
	setup_goal.add_theme_font_size_override("font_size", 14 if mobile else 18)
	setup_goal.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	setup_regios.text = ("REGIOS  •  carry 5" if not landscape else "REGIOS  •  carry 5; fighters cost +1 Varos") if mobile else "Regios — workers carry 5; fighters cost +1 Varos"
	setup_poblanos.text = ("POBLANOS  •  tougher buildings" if not landscape else "POBLANOS  •  tougher buildings; carry 4") if mobile else "Poblanos — buildings +20% HP; workers carry 4"
	setup_note.text = "Fictional faction bonuses." if mobile and not landscape else "These are fictional strategies, not descriptions of regional people."
	for b in [setup_regios, setup_poblanos, setup_resume]:
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
	hovered_source_id = ""
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
	setup_resume.visible = FileAccess.file_exists(save_path)
	setup_save_error.text = ""
	hover_hint.text = ""
	instructions.text = "Choose Regios or Poblanos to begin · Press 1 or 2, or click a choice"
	_update_hud()
	queue_redraw()

func _choose_faction(faction: String) -> void:
	if not choosing_faction or faction not in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		return
	_start_match(faction)

func _save_match() -> void:
	if choosing_faction or sim.result != "":
		hud_ui.show_notice("Start an active match before saving", true)
		return
	var saved: Dictionary = MatchSave.write(sim, match_id, completion_queued, save_path)
	if saved.ok:
		hud_ui.show_notice("Match saved. Resume it from the faction screen or menu.")
	else:
		hud_ui.show_notice("Save failed: %s. Current match is still playable." % saved.reason.replace("_", " "), true)

func _resume_match() -> void:
	var restored: Dictionary = MatchSave.read(save_path)
	if not restored.ok:
		var message := "Saved match could not load: %s. File kept." % restored.reason.replace("_", " ")
		if choosing_faction:
			setup_save_error.text = message
		else:
			hud_ui.show_notice(message, true)
		return
	if _outbox_has_terminal(restored.match_id) and restored.game.result == "":
		var completed_note := "That saved match already finished. Start a new match; the save file is kept."
		if choosing_faction:
			setup_save_error.text = completed_note
		else:
			hud_ui.show_notice(completed_note, true)
		return
	sim = restored.game as Skirmish
	match_id = restored.match_id
	completion_queued = restored.completion_queued or sim.result != ""
	outbox.faction = sim.factions[Skirmish.HUMAN]
	choosing_faction = false
	setup_panel.hide()
	instructions.text = "Click to select · Right-click to order · B choose building · HQ age up · Registry research · 1/2/3 recruit · Esc cancel · +/- zoom · G fullscreen · R factions · F sync"
	paused = false
	hud_ui.pause_button.text = "II"
	hud_ui.diagnostics.hide()
	accumulator = 0.0
	selected_id = -1
	selected_ids.clear()
	last_group_signature = ""
	last_ui_signature = ""
	hovered_entity_id = -1
	hovered_source_id = ""
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
	order_flash_seconds = 0.0
	hud_ui.show_notice("Saved match resumed")
	_update_hud()
	queue_redraw()

func _outbox_has_terminal(id: String) -> bool:
	if not outbox.state.has("events"):
		return false
	for item in outbox.state.events:
		if item.has("event") and item.event.get("type") == "match_completed" and item.event.get("match_id") == id:
			return true
	return false

func _start_match(faction: String) -> void:
	sim = Skirmish.new(faction)
	paused = false
	hud_ui.pause_button.text = "II"
	hud_ui.diagnostics.hide()
	outbox.faction = faction
	choosing_faction = false
	setup_panel.hide()
	instructions.text = "Click to select · Right-click to order · B choose building · HQ age up · Registry research · 1/2/3 recruit · Esc cancel · +/- zoom · G fullscreen · R factions · F sync"
	match_id = "solo_" + Crypto.new().generate_random_bytes(16).hex_encode()
	completion_queued = false
	selected_id = -1
	selected_ids.clear()
	last_group_signature = ""
	last_ui_signature = ""
	hovered_entity_id = -1
	hovered_source_id = ""
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
			hud_ui.choice_panel.hide()
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
			hud_ui.show_notice("%s complete" % entity.kind.replace("_", " ").capitalize())
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
				hud_ui.choice_panel.hide()
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
			var source_id := _source_at(event.position, tile)
			if _command_state("gather").visible and not source_id.is_empty():
				_issue_order("gather", _source(source_id).pos, _source(source_id).pos)
			elif selected.kind == "worker" and target_id != -1 and sim.entities[target_id].side == Skirmish.HUMAN and sim.entities[target_id].kind in sim.content.buildings:
				_issue_order("assist" if not sim.entities[target_id].complete else "repair", target_id, sim.entities[target_id].pos)
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
			"gather": return "Gathering resource."
			"build": return "Building %s." % str(target.kind).replace("_", " ")
			"repair": return "Repairing building."
			"assist": return "Assisting construction."
			"research": return "Research started: %s." % str(target).replace("_", " ")
			"advance": return "Advancing to %s." % _age_display(str(target))
			"train": return "%s queued." % str(target).capitalize()
			"cancel": return "Paid order canceled; refund returned."
			"attack": return "Attacking target."
	match str(result.get("reason", "invalid_order")):
		"insufficient_stockpile": return "Missing required resources; inspect the cost."
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

func _cost_text(costs: Dictionary) -> String:
	var parts: Array[String] = []
	for id in RESOURCE_IDS:
		if int(costs.get(id, 0)) > 0:
			parts.append("%s %d" % [id.substr(0, 1).to_upper(), int(costs[id])])
	return ", ".join(parts) if not parts.is_empty() else "free"

func _missing_costs(costs: Dictionary) -> String:
	var missing: Array[String] = []
	for id in RESOURCE_IDS:
		var need := int(costs.get(id, 0)) - sim.balance(Skirmish.HUMAN, id)
		if need > 0:
			missing.append("%s %d" % [id.capitalize(), need])
	return "Need " + ", ".join(missing) if not missing.is_empty() else ""

func _age_id() -> String:
	return str(sim.content.ages.order[int(sim.age_index[Skirmish.HUMAN])])

func _age_display(id: String) -> String:
	return str(AGE_NAMES.get(id, id.capitalize()))

func _next_age_id() -> String:
	var index := int(sim.age_index[Skirmish.HUMAN]) + 1
	return str(sim.content.ages.order[index]) if index < sim.content.ages.order.size() else ""

func _age_gate(id: String) -> String:
	var data: Dictionary = sim.content.buildings[id] if id in sim.content.buildings else sim.content.units[id]
	var age := str(data.get("min_age", "foranea"))
	return "Requires %s age" % _age_display(age) if sim.content.ages.order.find(age) > int(sim.age_index[Skirmish.HUMAN]) else ""

func _building_reason(id: String) -> String:
	var reason := _age_gate(id)
	if reason.is_empty():
		reason = _missing_costs(sim._costs(Skirmish.HUMAN, id))
	return reason

func _research_reason(id: String) -> String:
	var tech: Dictionary = sim.content.techs[id]
	if id in sim.researched[Skirmish.HUMAN]:
		return "Already researched"
	if sim._queued(Skirmish.HUMAN, "tech", id):
		return "Already in queue"
	if sim.entities[selected_id].queue.size() >= 3:
		return "Queue full"
	if sim.content.ages.order.find(str(tech.age)) > int(sim.age_index[Skirmish.HUMAN]):
		return "Requires %s age" % _age_display(str(tech.age))
	for prerequisite in tech.get("requires_techs", []):
		if prerequisite not in sim.researched[Skirmish.HUMAN]:
			return "Requires " + str(prerequisite).replace("_", " ")
	return _missing_costs(tech.costs)

func _advance_reason(id: String) -> String:
	if id.is_empty():
		return "Final age reached"
	var transition: Dictionary = sim.content.ages.transitions[id]
	if sim._queued(Skirmish.HUMAN, "age", id):
		return "Already in queue"
	if sim.entities[selected_id].queue.size() >= 3:
		return "Queue full"
	for building in transition.get("requires_buildings", []):
		var building_id: int = sim._find(Skirmish.HUMAN, str(building))
		if building_id == -1 or not sim.entities[building_id].complete:
			return "Requires completed " + str(building).replace("_", " ")
	for tech in transition.get("requires_techs", []):
		if tech not in sim.researched[Skirmish.HUMAN]:
			return "Requires " + str(tech).replace("_", " ")
	return _missing_costs(transition.costs)

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
			if visible and RESOURCE_IDS.all(func(id: String) -> bool: return int(_source(id).get("amount", 0)) <= 0):
				reason = "Sources depleted; wait for renewal"
		"build":
			visible = kind == "worker" and selected_ids.size() <= 1
			label = "Choose building"
		"repair", "assist":
			visible = kind == "worker" and selected_ids.size() <= 1
			label = "Choose friendly building"
		"attack": visible = fighter_group
		"research":
			visible = kind == "registry" and selected_ids.size() <= 1
			label = "Choose technology"
			if visible and not sim.entities[selected_id].complete:
				reason = "Construction in progress"
		"advance":
			visible = kind == "command_post" and selected_ids.size() <= 1
			label = "Advance to " + _age_display(_next_age_id()) if not _next_age_id().is_empty() else "Final age"
			if visible:
				reason = _advance_reason(_next_age_id())
		"train_worker", "train_melee", "train_ranged":
			visible = (kind == "command_post" and role == "worker") or (kind == "barracks" and role in ["melee", "ranged"])
			label = "Recruit %s · %s" % [role, _cost_text(sim._costs(Skirmish.HUMAN, role))]
			if visible and not sim.entities[selected_id].complete:
				reason = "Construction in progress"
			elif visible and sim.entities[selected_id].queue.size() >= 3:
				reason = "Queue full"
			elif visible:
				reason = _age_gate(role)
				if reason.is_empty() and sim._population_used(Skirmish.HUMAN) >= sim._population_cap(Skirmish.HUMAN):
					reason = "Population cap; build housing"
				if reason.is_empty():
					reason = _missing_costs(sim._costs(Skirmish.HUMAN, role))
		"cancel":
			var construction_id := _cancelable_construction_id()
			visible = target_mode != "" or construction_id != -1 or (kind in ["command_post", "barracks", "registry"] and sim.entities.has(selected_id) and not sim.entities[selected_id].queue.is_empty())
			label = "Leave target mode" if target_mode != "" else "Cancel paid order"
			if target_mode == "" and construction_id != -1 and _cancel_worker_id() == -1:
				reason = "A worker is needed to cancel construction"
	if visible and sim.result != "" and (action != "cancel" or target_mode == ""):
		reason = "Match finished"
	return {"visible": visible, "enabled": visible and reason.is_empty(), "reason": reason, "label": label}

func _activate_command(action: String) -> void:
	if paused:
		hud_ui.show_notice("Resume to issue orders")
		return
	if action.begins_with("build_"):
		build_kind = action.trim_prefix("build_")
		if sim.result != "" or _selected_kind() != "worker" or selected_ids.size() != 1 or build_kind not in BUILD_CHOICES:
			_flash_order(Vector2i(-1, -1), "Select a living worker to build.", false)
			return
		var build_reason := _building_reason(build_kind)
		if not build_reason.is_empty():
			_flash_order(sim.entities[selected_id].pos, build_reason, false)
			return
		target_mode = "build"
		placing = true
		sim.feedback = _target_prompt()
		_update_hud()
		return
	if action.begins_with("research_"):
		var tech_id := action.trim_prefix("research_")
		if sim.result != "" or _selected_kind() != "registry" or selected_ids.size() != 1 or not sim.entities[selected_id].complete or tech_id not in sim.content.techs:
			_flash_order(Vector2i(-1, -1), "Select a completed registry to research.", false)
			return
		var research_reason := _research_reason(tech_id)
		if not research_reason.is_empty():
			_flash_order(sim.entities[selected_id].pos, research_reason, false)
			return
		_issue_order("research", tech_id, sim.entities[selected_id].pos)
		_update_hud()
		return
	if action.begins_with("cancel_queue_"):
		var queue_index := int(action.trim_prefix("cancel_queue_"))
		if sim.entities.has(selected_id):
			_issue_order("cancel", queue_index, sim.entities[selected_id].pos)
		_update_hud()
		return
	if action.begins_with("cancel_build_"):
		var building_id := int(action.trim_prefix("cancel_build_"))
		var worker_id := _cancel_worker_id()
		if worker_id != -1 and sim.entities.has(building_id):
			var at: Vector2i = sim.entities[building_id].pos
			var response: Dictionary = sim.issue(Skirmish.HUMAN, "cancel", worker_id, building_id)
			_flash_order(at, _order_message("cancel", building_id, response), response.ok)
		_update_hud()
		return
	if action == "cancel":
		if target_mode != "":
			target_mode = ""
			placing = false
			hud_ui.choice_panel.hide()
			sim.feedback = "Order canceled."
		else:
			_show_cancel_choices()
	else:
		var state := _command_state(action)
		if not state.enabled:
			var message: String = state.reason if not state.reason.is_empty() else "Select an actor for that order."
			_flash_order(sim.entities[selected_id].pos if sim.entities.has(selected_id) else Vector2i(-1, -1), message, false)
		elif action.begins_with("train_"):
			_train(action.trim_prefix("train_"))
		elif action == "build":
			var choices: Array[Dictionary] = []
			for id in BUILD_CHOICES:
				var reason := _building_reason(id)
				choices.append({"id": "build_" + id, "label": "%s · %s%s" % [id.capitalize(), _cost_text(sim._costs(Skirmish.HUMAN, id)), " — " + reason if not reason.is_empty() else ""], "enabled": reason.is_empty(), "reason": reason})
			hud_ui.show_choices("CHOOSE BUILDING", choices)
		elif action == "research":
			var choices: Array[Dictionary] = []
			for id in sim.content.techs:
				var reason := _research_reason(id)
				choices.append({"id": "research_" + id, "label": "%s · %s%s" % [str(id).replace("_i", "").replace("_", " ").capitalize(), _cost_text(sim.content.techs[id].costs), " — " + reason if not reason.is_empty() else ""], "enabled": reason.is_empty(), "reason": reason})
			hud_ui.show_choices("CHOOSE RESEARCH", choices)
		elif action == "advance":
			_issue_order("advance", _next_age_id(), sim.entities[selected_id].pos)
		else:
			target_mode = action
			placing = false
			sim.feedback = _target_prompt()
	_update_hud()
	queue_redraw()

func _cancelable_construction_id() -> int:
	if not sim.entities.has(selected_id):
		return -1
	var selected: Dictionary = sim.entities[selected_id]
	if selected.side != Skirmish.HUMAN:
		return -1
	if selected.kind in sim.content.buildings and not selected.complete:
		return selected_id
	if selected.kind == "worker" and selected.target_id != -1 and sim.entities.has(selected.target_id):
		var building: Dictionary = sim.entities[selected.target_id]
		if building.side == Skirmish.HUMAN and building.kind in sim.content.buildings and not building.complete:
			return int(selected.target_id)
	return -1

func _cancel_worker_id() -> int:
	if sim.entities.has(selected_id) and sim.entities[selected_id].kind == "worker":
		return selected_id
	return sim._find(Skirmish.HUMAN, "worker")

func _refund_text(costs: Dictionary, percent: int) -> String:
	var refunded := {}
	for resource_id in RESOURCE_IDS:
		refunded[resource_id] = int(costs.get(resource_id, 0)) * percent / 100
	return _cost_text(refunded)

func _show_cancel_choices() -> void:
	var choices: Array[Dictionary] = []
	var construction_id := _cancelable_construction_id()
	if construction_id != -1:
		var building: Dictionary = sim.entities[construction_id]
		choices.append({"id": "cancel_build_%d" % construction_id,
			"label": "Cancel %s · refund %s" % [building.kind.replace("_", " ").capitalize(), _refund_text(sim._costs(Skirmish.HUMAN, building.kind), 50)],
			"enabled": _cancel_worker_id() != -1, "reason": "A worker is needed to cancel construction"})
	elif sim.entities.has(selected_id) and sim.entities[selected_id].kind in sim.content.buildings:
		var queue: Array = sim.entities[selected_id].queue
		for index in queue.size():
			var order: Dictionary = queue[index]
			var percent := 50 if index == 0 else 100
			choices.append({"id": "cancel_queue_%d" % index,
				"label": "Cancel %s · refund %s" % [str(order.role).replace("_", " ").capitalize(), _refund_text(sim._order_costs(Skirmish.HUMAN, order), percent)],
				"enabled": true, "reason": ""})
	if not choices.is_empty():
		hud_ui.show_choices("CANCEL PAID ORDER", choices)

func _target_prompt() -> String:
	match target_mode:
		"move": return "Move: click a clear ground tile. Esc cancels."
		"gather": return "Gather: click a Comida, Materiales, Varos or Terrenos source. Esc cancels."
		"build": return "Build %s: click a clear 2×2 site. Esc cancels." % build_kind.capitalize()
		"repair": return "Repair: click a damaged friendly building. Esc cancels."
		"assist": return "Assist: click an unfinished friendly building. Esc cancels."
		"attack": return "Attack: click an enemy unit or post. Esc cancels."
	return ""

func _complete_target_order(screen: Vector2, tile: Vector2i) -> void:
	var result: Dictionary = {"ok": false}
	match target_mode:
		"move":
			result = _issue_order("move", tile, tile)
			if result.ok:
				marker = tile
		"build": result = _issue_order("build", {"kind": build_kind, "pos": tile}, tile)
		"gather":
			var source_id := _source_at(screen, tile)
			if not source_id.is_empty():
				var source_tile: Vector2i = _source(source_id).pos
				result = _issue_order("gather", source_tile, source_tile)
			else:
				_flash_order(tile, "Click a labeled resource source.", false)
		"repair", "assist":
			var building_id: int = _pick_visual_entity(screen, Skirmish.HUMAN)
			if building_id == -1:
				building_id = sim.entity_at(tile)
			if building_id != -1 and sim.entities[building_id].side == Skirmish.HUMAN and sim.entities[building_id].kind in sim.content.buildings:
				result = _issue_order(target_mode, building_id, sim.entities[building_id].pos)
			else:
				_flash_order(tile, "Click a friendly building.", false)
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
	var stockpiles := {}
	var source_notes := {}
	for resource_id in RESOURCE_IDS:
		stockpiles[resource_id] = sim.balance(Skirmish.HUMAN, resource_id)
		var source: Dictionary = _source(resource_id)
		source_notes[resource_id] = "%d at source; %d refreshes left" % [int(source.get("amount", 0)), int(source.get("refreshes_left", 0))]
	ui.set_economy(stockpiles, _age_display(_age_id()), sim._population_used(Skirmish.HUMAN), sim._population_cap(Skirmish.HUMAN), source_notes)
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
					portraits.append({"id": id, "texture": _actor_texture(sim.entities[id])})
			ui.set_group(portraits)
		else:
			ui.set_group([])
	if selected_id == -1:
		ui.set_selection(art.texture("building_command_post_%s" % _faction_color(Skirmish.HUMAN)), "NO SELECTION", sim.factions[Skirmish.HUMAN].capitalize(), 0, 0, "Select a unit or post", "")
	else:
		var actor: Dictionary = sim.entities[selected_id]
		var max_hp: int = sim._starting_health(Skirmish.HUMAN, actor.kind)
		var activity: String = actor.job.capitalize()
		if actor.kind == "worker":
			if actor.carry > 0:
				activity += "  •  carrying %d %s" % [actor.carry, str(actor.get("carry_resource", "resource")).capitalize()]
			elif not str(actor.get("source_resource", "")).is_empty():
				activity += "  •  %s source" % str(actor.source_resource).capitalize()
		var stats := ""
		if actor.kind in ["melee", "ranged"]:
			stats = "⚔ %d  •  range %d" % [sim._unit_damage(Skirmish.HUMAN, actor.kind), Skirmish.RANGE[actor.kind]]
		elif actor.kind == "worker":
			stats = "Carry cap %d" % sim._carry_limit(Skirmish.HUMAN)
		else:
			stats = "Construction %d%%" % roundi(100.0 * actor.progress / maxi(1, int(sim.content.buildings[actor.kind].build_ticks))) if not actor.complete else "Ready"
			if not actor.queue.is_empty():
				var first: Dictionary = actor.queue[0]
				stats += "  •  Queue %d: %s %ds" % [actor.queue.size(), first.role, ceili(float(first.remaining) / 10.0)]
		ui.set_selection(_actor_texture(actor), "%d UNITS" % selected_ids.size() if selected_ids.size() > 1 else "%s #%d" % [actor.kind.replace("_", " ").capitalize(), selected_id],
			sim.factions[Skirmish.HUMAN].capitalize(), actor.hp if selected_ids.size() <= 1 else 0, max_hp if selected_ids.size() <= 1 else 0,
			"Group selected" if selected_ids.size() > 1 else activity, "%d selected • tap a portrait for one" % selected_ids.size() if selected_ids.size() > 1 else stats)
	for action in command_buttons:
		var state := _command_state(action)
		ui.set_action(action, state, 0, target_mode == action)
	ui.command_help.text = _target_prompt() if target_mode != "" else ""
	ui.reflow_commands()
	_update_secondary()
	var queue: Array = sim.entities[selected_id].queue if sim.entities.has(selected_id) and _selected_kind() in ["command_post", "barracks", "registry"] else []
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
	var balances: Array[String] = []
	for id in RESOURCE_IDS:
		balances.append(str(sim.balance(Skirmish.HUMAN, id)))
	var actor_state := ""
	if sim.entities.has(selected_id):
		actor_state = "%s:%d" % [str(sim.entities[selected_id].complete), sim.entities[selected_id].queue.size()]
	var building_state: Array[String] = []
	for entity in sim.entities.values():
		if entity.side == Skirmish.HUMAN and entity.kind in sim.content.buildings:
			building_state.append("%s:%s" % [entity.kind, str(entity.complete)])
	var signature := "%s:%d:%d:%s:%d:%s:%s:%s" % [kind, selected_id, selected_ids.size(), ",".join(balances), int(sim.age_index[Skirmish.HUMAN]), str(sim.researched[Skirmish.HUMAN]), actor_state, ",".join(building_state)]
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
		cards.append({"texture": art.texture("building_barracks_blue"), "label": "BUILD\nB", "enabled": state.enabled, "reason": state.reason, "tooltip": "Choose depot, housing, registry or recruitment post", "action": "build"})
	elif kind in ["command_post", "barracks"]:
		title = "PRODUCTION"
		for role: String in (["worker"] if kind == "command_post" else ["melee", "ranged"]):
			var action: String = "train_" + role
			var state := _command_state(action)
			cards.append({"texture": art.texture("unit_%s_blue" % role), "label": "%s\n%s" % [role.to_upper(), _cost_text(sim._costs(Skirmish.HUMAN, role))],
				"enabled": state.enabled, "reason": state.reason, "tooltip": "%s • %s\n%s" % [role.capitalize(), _cost_text(sim._costs(Skirmish.HUMAN, role)), state.reason if not state.reason.is_empty() else "Recruit here"], "action": action})
		if kind == "command_post" and not _next_age_id().is_empty():
			var age_state := _command_state("advance")
			cards.append({"label": "AGE\nUP", "enabled": age_state.enabled, "reason": age_state.reason, "tooltip": "%s • %s" % [age_state.label, _cost_text(sim.content.ages.transitions[_next_age_id()].costs)], "action": "advance"})
	elif kind == "registry":
		title = "RESEARCH"
		var research_state := _command_state("research")
		cards.append({"label": "TECH\nTREE", "enabled": research_state.enabled, "reason": research_state.reason, "tooltip": "Choose an available technology", "action": "research"})
	elif kind in ["melee", "ranged"]:
		title = "FIELD ORDERS"
		cards.append({"texture": art.texture(_actor_art_id(sim.entities[selected_id])), "label": "ATTACK\nA", "enabled": true, "tooltip": "Choose an enemy target • A", "action": "attack"})
	else:
		title = "LA ROMA"
	ui.set_secondary(title, cards)
	if kind == "worker":
		ui.secondary_details.text = "EXPAND\nBuild, assist or repair"
	elif kind in ["command_post", "barracks"]:
		ui.secondary_details.text = "RECRUIT UNITS\nOr advance the age"
	elif kind == "registry":
		ui.secondary_details.text = "RESEARCH\nInspect costs and prerequisites"
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
		var ya: int = ea.pos.x + ea.pos.y + (3 if ea.kind in sim.content.buildings else 0)
		var yb: int = eb.pos.x + eb.pos.y + (3 if eb.kind in sim.content.buildings else 0)
		return ya < yb if ya != yb else a < b)
	return ids

func _actor_ground(entity: Dictionary) -> Vector2:
	return _tile_to_screen(entity.pos) + (Vector2(0, 36) if entity.kind in sim.content.buildings else Vector2.ZERO)

func _actor_art_id(entity: Dictionary) -> String:
	var is_building: bool = entity.kind in sim.content.buildings
	var id: String = ("building_" if is_building else "unit_") + str(entity.kind) + "_" + _faction_color(entity.side)
	return id if art.records.has(id) else "building_barracks_" + _faction_color(entity.side)

func _actor_texture(entity: Dictionary) -> Texture2D:
	var id := _actor_art_id(entity)
	if art.records.has(id):
		return art.texture(id)
	return art.texture("building_barracks_" + _faction_color(entity.side))

func _pick_visual_entity(screen: Vector2, side: int) -> int:
	var board := _screen_to_board(screen)
	var ids := _sorted_entity_ids()
	ids.reverse()
	# A nearby HQ can overhang a worker; prefer the smaller unit where hit areas overlap.
	for want_building in [false, true]:
		for id in ids:
			var entity: Dictionary = sim.entities[id]
			var is_building: bool = entity.kind in sim.content.buildings
			if entity.side != side or is_building != want_building:
				continue
			var scale := 1.0 if is_building else UNIT_ART_SCALE
			var delta := (board - _actor_ground(entity)) / scale
			if not is_building and unit_facing.get(id, 1) < 0:
				delta.x = -delta.x
			var art_id := _actor_art_id(entity)
			if (art.records.has(art_id) and art.hit_test(art_id, art.pivot(art_id) + delta)) or (is_building and not art.records.has(art_id) and Rect2(Vector2(-38, -58), Vector2(76, 72)).has_point(delta)):
				return id
	return -1

func _source(id: String) -> Dictionary:
	return sim.resource_sources[Skirmish.HUMAN].get(id, {})

func _pick_visual_source(screen: Vector2) -> String:
	var board := _screen_to_board(screen)
	for id in RESOURCE_IDS:
		var source := _source(id)
		if int(source.get("amount", 0)) > 0 and board.distance_to(_tile_to_screen(source.pos) + Vector2(0, -8)) <= 17:
			return id
	return ""

func _source_at(screen: Vector2, tile: Vector2i) -> String:
	var id := _pick_visual_source(screen)
	if not id.is_empty():
		return id
	for resource_id in RESOURCE_IDS:
		var source := _source(resource_id)
		if source.get("pos", Vector2i(-1, -1)) == tile and int(source.get("amount", 0)) > 0:
			return resource_id
	return ""

func _refresh_hover() -> void:
	if choosing_faction or placing:
		if hovered_entity_id != -1 or not hovered_source_id.is_empty() or not hover_hint.text.is_empty():
			hovered_entity_id = -1
			hovered_source_id = ""
			hover_hint.text = ""
			queue_redraw()
		return
	var screen := get_viewport().get_mouse_position()
	var next_entity := _pick_visual_entity(screen, Skirmish.HUMAN)
	var next_source := ""
	if next_entity == -1:
		next_source = _pick_visual_source(screen)
	if next_entity == -1 and next_source.is_empty() and _selected_kind() in ["melee", "ranged"]:
		next_entity = _pick_visual_entity(screen, Skirmish.COMPUTER)
	var next_hint := ""
	if next_entity != -1:
		var e: Dictionary = sim.entities[next_entity]
		if e.side == Skirmish.HUMAN:
			next_hint = "Selected %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity] if next_entity == selected_id else "Click to select %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity]
		else:
			next_hint = "Right-click to attack %s #%d" % [e.kind.replace("_", " ").capitalize(), next_entity]
	elif not next_source.is_empty():
		next_hint = "%s source · %d left%s" % [next_source.capitalize(), int(_source(next_source).amount), " · right-click to gather" if _selected_kind() == "worker" else " · select a worker"]
	if next_entity != hovered_entity_id or next_source != hovered_source_id or next_hint != hover_hint.text:
		hovered_entity_id = next_entity
		hovered_source_id = next_source
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
	# Owner-supplied flowers are decorative; the simulation and tile picking ignore them.
	for tile in [Vector2i(3, 14), Vector2i(17, 6)]:
		var flowers_id := "prop_owned_flowers"
		draw_texture(art.texture(flowers_id), _tile_to_screen(tile) - art.pivot(flowers_id))
	var medallion_id := "prop_plaza_medallion"
	draw_texture(art.texture(medallion_id), _tile_to_screen(Vector2i(10, 10)) - art.pivot(medallion_id))
	draw_string(ThemeDB.fallback_font, _tile_to_screen(Vector2i(10, 9)) + Vector2(-58, -30), "LA ROMA", HORIZONTAL_ALIGNMENT_CENTER, 116, 15, Color.WHITE)
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		for resource_id in RESOURCE_IDS:
			var source: Dictionary = sim.resource_sources[side].get(resource_id, {})
			if source.is_empty():
				continue
			var center := _tile_to_screen(source.pos) + Vector2(0, -8)
			var color: Color = RESOURCE_COLORS[resource_id]
			var active := int(source.get("amount", 0)) > 0
			draw_circle(center, 13, color.darkened(0.45) if active else Color("60646a"))
			draw_arc(center, 13, 0, TAU, 24, Color.WHITE if resource_id == hovered_source_id and side == Skirmish.HUMAN else color, 2.0)
			draw_arc(center, 16, 0, TAU, 24, Color("70d5e7") if side == Skirmish.HUMAN else Color("ed796a"), 1.5)
			draw_string(ThemeDB.fallback_font, center + Vector2(-9, 5), resource_id.substr(0, 1).to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 18, 15, Color.WHITE)
			draw_string(ThemeDB.fallback_font, center + Vector2(-35, -22), "%s %d" % [resource_id.substr(0, 1).to_upper(), int(source.get("amount", 0))],
				HORIZONTAL_ALIGNMENT_CENTER, 70, 12, Color.WHITE)
	var ids := _sorted_entity_ids()
	for id in ids:
		var e: Dictionary = sim.entities[id]
		var is_building: bool = e.kind in sim.content.buildings
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
		if is_building and e.kind not in ["command_post", "barracks"]:
			draw_rect(Rect2(ground + Vector2(-35, -54), Vector2(70, 18)), Color("1b2430"))
			draw_string(ThemeDB.fallback_font, ground + Vector2(-33, -40), e.kind.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, 66, 12, Color.WHITE)
		if not is_building and unit_facing.get(id, 1) < 0:
			draw_set_transform(BOARD_CENTER * (1.0 - board_zoom) + board_pan + _board_view_offset(), 0.0, Vector2.ONE * board_zoom)
		if is_building and not e.complete:
			draw_rect(Rect2(ground + Vector2(-47, -27), Vector2(94, 26)), Color(0.63, 0.46, 0.28, 0.35))
			draw_rect(Rect2(ground + Vector2(-22, -33), Vector2(44, 4)), Color("3b3029"))
			draw_rect(Rect2(ground + Vector2(-22, -33), Vector2(44.0 * e.progress / maxi(1, int(sim.content.buildings[e.kind].build_ticks)), 4)), Color("e5c36f"))
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
		var active_building: bool = active.kind in sim.content.buildings
		var active_ground := _actor_ground(active)
		draw_arc(active_ground + Vector2(0, -24 if active_building else -5),
			23 if active_building else 16, 0, TAU, 24, Color("7eeaff"), 3.0)
		if not active_building:
			var tip := active_ground + Vector2(0, -art.pivot(_actor_art_id(active)).y * UNIT_ART_SCALE - 9)
			draw_colored_polygon(PackedVector2Array([tip + Vector2(-6, -4), tip + Vector2(6, -4), tip + Vector2(0, 4)]),
				Color("7eeaff"))
	if placing:
		var preview_tile := _screen_to_tile(get_global_mouse_position())
		var valid: bool = sim._clear_footprint(preview_tile) and _building_reason(build_kind).is_empty()
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
