extends Control

signal command(action: String)
signal subset_requested(id: int)
signal navigate(tile: Vector2i)
signal menu_requested
signal pause_requested
signal restart_requested
signal save_requested
signal resume_requested
signal ui_scale_changed(value: float)
signal reduced_motion_changed(value: bool)
signal new_match_requested

const HudSkin = preload("res://ui/hud_skin.gd")
const CommandButton = preload("res://ui/command_button.gd")
const MinimapPanel = preload("res://ui/minimap_panel.gd")
const ACTIONS := {
	"move": {"name": "MOVE", "key": "M", "description": "Choose clear ground for this unit."},
	"attack_move": {"name": "ADVANCE", "key": "", "description": "Move and engage visible enemies in range."},
	"stop": {"name": "STOP", "key": "", "description": "Cancel this unit's current order."},
	"hold": {"name": "HOLD", "key": "", "description": "Stay here and attack enemies in range."},
	"gather": {"name": "GATHER", "key": "H", "description": "Choose a resource source for this worker."},
	"build": {"name": "BUILD", "key": "B", "description": "Choose a building and place it on clear ground."},
	"repair": {"name": "REPAIR", "key": "", "description": "Choose a damaged friendly building."},
	"assist": {"name": "ASSIST", "key": "", "description": "Choose an unfinished friendly building."},
	"attack": {"name": "ATTACK", "key": "A", "description": "Choose an enemy unit or building."},
	"research": {"name": "RESEARCH", "key": "", "description": "Choose an available technology at the registry."},
	"advance": {"name": "AGE UP", "key": "", "description": "Start the next age at the command post."},
	"train_worker": {"name": "WORKER", "key": "1", "description": "Recruit a worker at the command post."},
	"train_melee": {"name": "FIGHTER", "key": "2", "description": "Recruit a melee fighter at the recruitment post."},
	"train_ranged": {"name": "RANGED", "key": "3", "description": "Recruit a ranged fighter at the recruitment post."},
	"train_armored": {"name": "ARMORED", "key": "", "description": "Recruit a durable armored counter."},
	"train_siege": {"name": "SIEGE", "key": "", "description": "Recruit a costly structure attacker."},
	"cancel": {"name": "CANCEL", "key": "", "description": "Leave target mode or choose a paid order to cancel with its shown refund."}
}

var top: Panel
var bottom: Panel
var objective_panel: Panel
var objective_button: Button
var objective_body: VBoxContainer
var objective_title: Label
var objective_progress: ProgressBar
var notification_panel: Panel
var notification_label: Label
var notification_age := 0.0
var event_log: Array[String] = []
var event_log_label: Label
var diagnostics: Panel
var diagnostics_label: Label
var sound_mute: CheckButton
var sound_volume: HSlider
var invite_input: LineEdit
var invite_save: Button
var support_copy: Button
var save_button: Button
var resume_button: Button
var close_diagnostics: Button
var gold_label: Label
var resource_row: HBoxContainer
var top_actions: HBoxContainer
var top_divider: VSeparator
var resource_labels: Dictionary = {}
var age_label: Label
var population_label: Label
var faction_label: Label
var timer_label: Label
var pause_button: Button
var restart_button: Button
var menu_button: Button
var restart_scrim: ColorRect
var restart_dialog: Panel
var restart_confirm: Button
var selection_panel: Panel
var selection_portrait: TextureRect
var group_grid: GridContainer
var selection_title: Label
var selection_faction: Label
var selection_hp: ProgressBar
var selection_hp_label: Label
var selection_details: Label
var selection_stats: Label
var command_panel: Panel
var command_help: Label
var command_empty: Label
var command_buttons: Dictionary = {}
var command_scroll: ScrollContainer
var command_strip: Control
var secondary_panel: Panel
var secondary_title: Label
var secondary_status: Label
var secondary_reason: Label
var secondary_details: Label
var queue_title: Label
var queue_slots: Array[Panel] = []
var secondary_cards: HBoxContainer
var secondary_scroll: ScrollContainer
var minimap: Control
var compact_details: Button
var secondary_toggle: Button
var mobile_secondary_open := false
var paused := false
var last_notification := ""
var choice_panel: Panel
var choice_title: Label
var choice_list: VBoxContainer
var choice_scroll: ScrollContainer
var ui_scale_choice: OptionButton
var reduced_motion_choice: CheckButton
var user_scale := 1.0
var result_panel: Panel
var result_title: Label
var result_reason: Label

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_resize_for_viewport)
	_resize_for_viewport()

func _resize_for_viewport() -> void:
	var view := get_viewport().get_visible_rect().size
	# Reserve enough physical space for board picking at the largest text setting.
	var factor := minf(_desired_scale(view), 1.5)
	scale = Vector2.ONE * factor
	size = view / factor
	_layout()

func _desired_scale(view: Vector2) -> float:
	var desktop_factor := clampf(minf(view.x / 1280.0, view.y / 800.0), 1.0, 1.5)
	return user_scale * desktop_factor

func _refresh_text_scale() -> void:
	var boost := _desired_scale(get_viewport().get_visible_rect().size) / scale.x
	_apply_text_scale(self, boost)
	for button in command_buttons.values():
		button.caption_scale = boost
		button.queue_redraw()

func _apply_text_scale(node: Node, boost: float) -> void:
	if node is Control:
		var control: Control = node
		if control.has_theme_font_size_override("font_size"):
			if not control.has_meta("base_font_size"):
				control.set_meta("base_font_size", control.get_theme_font_size("font_size"))
			control.add_theme_font_size_override("font_size", roundi(float(control.get_meta("base_font_size")) * boost))
	for child in node.get_children():
		_apply_text_scale(child, boost)

func set_ui_scale(value: float) -> void:
	user_scale = clampf(value, 1.0, 2.0)
	if ui_scale_choice != null:
		ui_scale_choice.select([1.0, 1.25, 1.5, 2.0].find(user_scale))
	_resize_for_viewport()

func _panel(parent: Node, padding: int = 8, stronger: bool = false) -> Panel:
	var p := Panel.new()
	p.add_theme_stylebox_override("panel", HudSkin.panel(padding, stronger))
	parent.add_child(p)
	return p

func _label(parent: Node, value: String = "", size: int = 14, color: Color = HudSkin.TEXT) -> Label:
	var l := Label.new()
	l.text = value
	HudSkin.label(l, size, color)
	parent.add_child(l)
	return l

func _button(parent: Node, value: String) -> Button:
	var b := Button.new()
	b.text = value
	HudSkin.apply_button(b)
	parent.add_child(b)
	return b

func _build() -> void:
	top = _panel(self, 5, true)
	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.add_theme_constant_override("separation", 12)
	top.add_child(top_row)
	faction_label = _label(top_row, "LA ROMA", 16, HudSkin.GOLD)
	faction_label.custom_minimum_size.x = 160
	resource_row = HBoxContainer.new()
	resource_row.add_theme_constant_override("separation", 10)
	top_row.add_child(resource_row)
	top_actions = HBoxContainer.new()
	top_actions.add_theme_constant_override("separation", 6)
	top.add_child(top_actions)
	top_actions.hide()
	for id in ["comida", "materiales", "varos", "terrenos"]:
		var label := _label(resource_row, "%s 0" % id.substr(0, 1).to_upper(), 18, HudSkin.GOLD)
		label.tooltip_text = "%s in stockpile" % id.capitalize()
		resource_labels[id] = label
	gold_label = resource_labels["varos"]
	age_label = _label(top_row, "FORÁNEA", 18, HudSkin.GOLD)
	population_label = _label(top_row, "0/0", 18, HudSkin.TEXT)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	population_label.tooltip_text = "Population used / housing capacity"
	top_divider = VSeparator.new()
	top_row.add_child(top_divider)
	timer_label = _label(top_row, "00:00", 18)
	timer_label.custom_minimum_size.x = 58
	pause_button = _button(top_row, "II")
	pause_button.tooltip_text = "Pause / resume • Space"
	pause_button.pressed.connect(func() -> void: pause_requested.emit())
	restart_button = _button(top_row, "RESET")
	restart_button.tooltip_text = "Start a fresh match as the same faction • R opens faction choice"
	restart_button.pressed.connect(func() -> void: restart_scrim.show())
	menu_button = _button(top_row, "...")
	menu_button.tooltip_text = "Settings, alpha support and diagnostics"
	menu_button.pressed.connect(func() -> void: menu_requested.emit())

	choice_panel = _panel(self, 12, true)
	choice_panel.z_index = 25
	choice_title = _label(choice_panel, "CHOOSE", 17, HudSkin.GOLD)
	choice_scroll = ScrollContainer.new()
	choice_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	choice_panel.add_child(choice_scroll)
	choice_list = VBoxContainer.new()
	choice_list.add_theme_constant_override("separation", 6)
	choice_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	choice_scroll.add_child(choice_list)
	choice_panel.hide()

	bottom = _panel(self, 7, true)
	selection_panel = _panel(bottom, 7)
	selection_portrait = TextureRect.new()
	selection_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	selection_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	selection_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	selection_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selection_panel.add_child(selection_portrait)
	group_grid = GridContainer.new()
	group_grid.columns = 3
	group_grid.add_theme_constant_override("h_separation", 2)
	group_grid.add_theme_constant_override("v_separation", 2)
	selection_panel.add_child(group_grid)
	group_grid.hide()
	selection_title = _label(selection_panel, "NO SELECTION", 18, HudSkin.GOLD)
	selection_faction = _label(selection_panel, "", 16, HudSkin.MUTED)
	selection_hp = ProgressBar.new()
	selection_hp.show_percentage = false
	selection_hp.add_theme_stylebox_override("background", HudSkin.button(HudSkin.INK, HudSkin.BRONZE))
	selection_hp.add_theme_stylebox_override("fill", HudSkin.button(HudSkin.GREEN, HudSkin.GREEN))
	selection_panel.add_child(selection_hp)
	selection_hp_label = _label(selection_panel, "", 16)
	selection_details = _label(selection_panel, "", 16, HudSkin.MUTED)
	selection_stats = _label(selection_panel, "", 16, HudSkin.TEXT)
	compact_details = _button(selection_panel, "^")
	compact_details.tooltip_text = "Expand selection details"
	compact_details.pressed.connect(func() -> void: selection_stats.visible = not selection_stats.visible)

	command_panel = _panel(bottom, 7)
	var command_heading := _label(command_panel, "COMMANDS", 16, HudSkin.GOLD)
	command_heading.name = "Heading"
	command_scroll = ScrollContainer.new()
	command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	command_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	command_panel.add_child(command_scroll)
	command_strip = Control.new()
	command_scroll.add_child(command_strip)
	for action in ACTIONS:
		var b := CommandButton.new()
		b.glyph = action
		b.caption = ACTIONS[action].name
		b.pressed.connect(func() -> void: command.emit(action))
		command_strip.add_child(b)
		command_buttons[action] = b
	command_help = _label(command_panel, "", 16, HudSkin.GOLD)
	command_help.name = "Help"
	command_empty = _label(command_panel, "SELECT AN ACTOR", 18, HudSkin.MUTED)
	command_help.clip_text = true
	secondary_panel = _panel(bottom, 7)
	secondary_title = _label(secondary_panel, "CONTEXT", 16, HudSkin.GOLD)
	secondary_status = _label(secondary_panel, "", 16, HudSkin.TEXT)
	secondary_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secondary_reason = _label(secondary_panel, "", 16, HudSkin.MUTED)
	secondary_details = _label(secondary_panel, "", 16, HudSkin.TEXT)
	secondary_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_title = _label(secondary_panel, "QUEUE  0 / 3", 16, HudSkin.GOLD)
	for i in 3:
		var slot := _panel(secondary_panel, 3)
		var slot_label := _label(slot, "—", 16, HudSkin.MUTED)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		queue_slots.append(slot)
	secondary_scroll = ScrollContainer.new()
	secondary_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	secondary_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	secondary_panel.add_child(secondary_scroll)
	secondary_cards = HBoxContainer.new()
	secondary_cards.add_theme_constant_override("separation", 6)
	secondary_scroll.add_child(secondary_cards)
	secondary_toggle = _button(bottom, "OPTIONS ^")
	secondary_toggle.pressed.connect(func() -> void:
		mobile_secondary_open = not mobile_secondary_open
		_layout())

	objective_panel = _panel(self, 6)
	var objectives := VBoxContainer.new()
	objectives.add_theme_constant_override("separation", 4)
	objective_panel.add_child(objectives)
	objective_button = _button(objectives, "OBJECTIVES v")
	objective_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	objective_button.pressed.connect(func() -> void:
		objective_body.visible = not objective_body.visible
		_layout())
	objective_body = VBoxContainer.new()
	objective_body.add_theme_constant_override("separation", 3)
	objectives.add_child(objective_body)
	objective_title = _label(objective_body, "Capture La Roma", 16)
	objective_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_title.custom_minimum_size.y = 40
	var objective_alternative := _label(objective_body, "or destroy enemy command post", 16, HudSkin.MUTED)
	objective_alternative.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	objective_progress = ProgressBar.new()
	objective_progress.max_value = 600
	objective_progress.show_percentage = false
	objective_progress.custom_minimum_size.y = 10
	objective_progress.add_theme_stylebox_override("background", HudSkin.button(HudSkin.INK))
	objective_progress.add_theme_stylebox_override("fill", HudSkin.button(HudSkin.GOLD))
	objective_body.add_child(objective_progress)

	minimap = MinimapPanel.new()
	minimap.navigate.connect(func(tile: Vector2i) -> void: navigate.emit(tile))
	self.add_child(minimap)
	notification_panel = _panel(self, 7)
	notification_label = _label(notification_panel, "", 16, HudSkin.TEXT)
	notification_panel.hide()

	diagnostics = _panel(self, 14, true)
	diagnostics.z_index = 20
	var diag_scroll := ScrollContainer.new()
	diag_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	diagnostics.add_child(diag_scroll)
	var diag_col := VBoxContainer.new()
	diag_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	diag_col.add_theme_constant_override("separation", 8)
	diag_scroll.add_child(diag_col)
	var head := HBoxContainer.new()
	diag_col.add_child(head)
	_label(head, "SETTINGS / ALPHA SUPPORT", 19, HudSkin.GOLD)
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(grow)
	close_diagnostics = _button(head, "Close")
	close_diagnostics.pressed.connect(func() -> void: diagnostics.hide())
	var scale_row := HBoxContainer.new()
	diag_col.add_child(scale_row)
	_label(scale_row, "Interface size", 16)
	ui_scale_choice = OptionButton.new()
	for label in ["100%", "125%", "150%", "200%"]:
		ui_scale_choice.add_item(label)
	ui_scale_choice.custom_minimum_size = Vector2(130, 44)
	ui_scale_choice.add_theme_font_size_override("font_size", 16)
	ui_scale_choice.item_selected.connect(func(index: int) -> void: ui_scale_changed.emit([1.0, 1.25, 1.5, 2.0][index]))
	scale_row.add_child(ui_scale_choice)
	reduced_motion_choice = CheckButton.new()
	reduced_motion_choice.text = "Reduce unit motion"
	reduced_motion_choice.add_theme_font_size_override("font_size", 16)
	reduced_motion_choice.custom_minimum_size.y = 44
	reduced_motion_choice.toggled.connect(func(value: bool) -> void: reduced_motion_changed.emit(value))
	diag_col.add_child(reduced_motion_choice)
	_label(diag_col, "Order cues also appear as text on the battlefield.", 16, HudSkin.MUTED)
	var sound_row := HBoxContainer.new()
	diag_col.add_child(sound_row)
	sound_mute = CheckButton.new()
	sound_mute.text = "Mute cues"
	sound_row.add_child(sound_mute)
	sound_volume = HSlider.new()
	sound_volume.min_value = 0
	sound_volume.max_value = 100
	sound_volume.step = 5
	sound_volume.value = 55
	sound_volume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sound_volume.tooltip_text = "Order cue volume"
	sound_row.add_child(sound_volume)
	diagnostics_label = _label(diag_col, "", 16)
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	save_button = _button(diag_col, "Save current match")
	save_button.pressed.connect(func() -> void: save_requested.emit())
	resume_button = _button(diag_col, "Resume saved match")
	resume_button.pressed.connect(func() -> void: resume_requested.emit())
	event_log_label = _label(diag_col, "EVENTS", 16, HudSkin.MUTED)
	event_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	invite_input = LineEdit.new()
	invite_input.placeholder_text = "Private alpha invite code"
	invite_input.secret = true
	diag_col.add_child(invite_input)
	invite_save = _button(diag_col, "Save invite code")
	support_copy = _button(diag_col, "Copy support ID")
	diagnostics.hide()

	result_panel = _panel(self, 16, true)
	result_panel.z_index = 15
	var result_column := VBoxContainer.new()
	result_column.add_theme_constant_override("separation", 10)
	result_panel.add_child(result_column)
	result_title = _label(result_column, "VICTORY", 28, HudSkin.GOLD)
	result_reason = _label(result_column, "", 18)
	result_reason.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var new_match := _button(result_column, "Choose a new match")
	new_match.pressed.connect(func() -> void: new_match_requested.emit())
	result_panel.hide()

	restart_scrim = ColorRect.new()
	restart_scrim.color = Color(0, 0, 0, 0.65)
	restart_scrim.mouse_filter = Control.MOUSE_FILTER_STOP
	restart_scrim.z_index = 30
	add_child(restart_scrim)
	restart_dialog = _panel(restart_scrim, 12, true)
	_label(restart_dialog, "RESET MATCH?", 19, HudSkin.GOLD).position = Vector2(14, 10)
	var warning := _label(restart_dialog, "Start over with the same faction?\nCurrent match progress will be lost.", 14)
	warning.position = Vector2(14, 42)
	warning.size = Vector2(340, 50)
	var cancel_reset := _button(restart_dialog, "CANCEL")
	cancel_reset.position = Vector2(14, 99)
	cancel_reset.size = Vector2(120, 36)
	cancel_reset.pressed.connect(cancel_restart)
	restart_confirm = _button(restart_dialog, "RESET MATCH")
	restart_confirm.position = Vector2(142, 99)
	restart_confirm.size = Vector2(150, 36)
	restart_confirm.pressed.connect(func() -> void:
		restart_scrim.hide()
		restart_requested.emit())
	restart_scrim.hide()

func cancel_restart() -> void:
	restart_scrim.hide()

func _layout() -> void:
	if top == null:
		return
	var w := size.x
	var h := size.y
	var stacked := w < 950 or h < 560
	var narrow_top := w < 620
	var compact_top := w < 1180
	var margin := 8.0 if stacked else 12.0
	var top_h := 136.0 if narrow_top else (90.0 if compact_top else 64.0)
	top.position = Vector2(margin, margin)
	top.size = Vector2(w - margin * 2.0, top_h)
	var top_row: HBoxContainer = top.get_node("TopRow")
	if compact_top and resource_row.get_parent() != top:
		resource_row.reparent(top)
	elif not compact_top and resource_row.get_parent() != top_row:
		resource_row.reparent(top_row)
		top_row.move_child(resource_row, 1)
	if narrow_top and timer_label.get_parent() != top_actions:
		for control in [timer_label, pause_button, restart_button, menu_button]:
			control.reparent(top_actions)
	elif not narrow_top and timer_label.get_parent() != top_row:
		for control in [timer_label, pause_button, restart_button, menu_button]:
			control.reparent(top_row)
	top_actions.visible = narrow_top
	top_divider.visible = not narrow_top
	top_actions.position = Vector2(6, 49)
	top_actions.size = Vector2(top.size.x - 12, 46)
	top_row.position = Vector2(6, 5)
	top_row.size = Vector2(top.size.x - 12, 48)
	top_row.add_theme_constant_override("separation", 4 if compact_top else 9)
	resource_row.position = Vector2(8, 101 if narrow_top else 54) if compact_top else Vector2.ZERO
	resource_row.size = Vector2(top.size.x - 16, 30) if compact_top else Vector2.ZERO
	resource_row.add_theme_constant_override("separation", 3 if narrow_top else (12 if compact_top else 10))
	faction_label.custom_minimum_size.x = 95 if compact_top else 145
	faction_label.clip_text = true
	faction_label.add_theme_font_size_override("font_size", 18)
	for id in resource_labels:
		(resource_labels[id] as Label).add_theme_font_size_override("font_size", 16 if narrow_top else 18)
	age_label.add_theme_font_size_override("font_size", 18)
	population_label.add_theme_font_size_override("font_size", 18)
	timer_label.add_theme_font_size_override("font_size", 18)
	timer_label.custom_minimum_size.x = 58
	var bottom_h := 188.0 if stacked else 220.0
	var bottom_w := minf(w - 2.0 * margin, 1250.0)
	bottom.position = Vector2((w - bottom_w) * 0.5, h - bottom_h - margin)
	bottom.size = Vector2(bottom_w, bottom_h)
	var available := bottom.size.x - 16.0
	var content_h := bottom_h - 16.0
	var left_w := minf(315.0, available * 0.28)
	var right_w := clampf(available * 0.27, 230.0, 335.0)
	var gap := 7.0
	var center_w := available - left_w - right_w - 2.0 * gap
	if stacked:
		selection_panel.position = Vector2(8, 8)
		selection_panel.size = Vector2(available, 70)
		command_panel.position = Vector2(8, 85)
		command_panel.size = Vector2(available, content_h - 77)
		secondary_panel.position = Vector2(8, -160)
		secondary_panel.size = Vector2(available, 152)
		secondary_panel.visible = mobile_secondary_open
		secondary_toggle.position = Vector2(available - 122, 18)
		secondary_toggle.size = Vector2(116, 44)
		secondary_toggle.show()
	else:
		selection_panel.position = Vector2(8, 8)
		selection_panel.size = Vector2(left_w, content_h)
		command_panel.position = Vector2(8 + left_w + gap, 8)
		command_panel.size = Vector2(center_w, content_h)
		secondary_panel.position = Vector2(8 + left_w + gap + center_w + gap, 8)
		secondary_panel.size = Vector2(right_w, content_h)
		secondary_panel.show()
		secondary_toggle.hide()
	_layout_selection(stacked)
	_layout_commands(stacked)
	secondary_title.position = Vector2(5, 3)
	secondary_scroll.position = Vector2(5, 40 if stacked else 25)
	secondary_scroll.size = Vector2(secondary_panel.size.x - (126 if not stacked and secondary_title.text in ["PRODUCTION", "RESEARCH"] else 10), secondary_panel.size.y - (45 if stacked else 30))
	secondary_status.position = Vector2(6, 30)
	secondary_status.size = secondary_panel.size - Vector2(12, 38)
	secondary_reason.position = Vector2(6, 22 if stacked else secondary_panel.size.y - 24)
	secondary_reason.size = Vector2(secondary_panel.size.x - 12, 16)
	var queue_visible := not stacked and queue_title.visible
	secondary_details.position = Vector2(114 if not stacked else 5, 29)
	secondary_details.size = Vector2(maxf(0, secondary_panel.size.x - 126), 46)
	secondary_details.visible = not stacked and not secondary_status.visible
	queue_title.position = Vector2(114, 84)
	queue_title.size = Vector2(secondary_panel.size.x - 122, 18)
	queue_title.visible = queue_visible
	for i in 3:
		var slot: Panel = queue_slots[i]
		slot.position = Vector2(114 + i * 60, 106)
		slot.size = Vector2(54, 49)
		slot.visible = queue_visible
		var slot_label: Label = slot.get_child(0)
		slot_label.position = Vector2(2, 10)
		slot_label.size = Vector2(46, 25)
	var map_w := 180.0 if not stacked else 112.0
	var map_h := 150.0 if not stacked else 105.0
	minimap.position = Vector2(w - margin - map_w, top.position.y + top_h + 8)
	minimap.size = Vector2(map_w, map_h)
	objective_panel.position = Vector2(margin, top.position.y + top_h + 8)
	if stacked and not objective_panel.has_meta("mobile_initialized"):
		objective_body.hide()
		objective_panel.set_meta("mobile_initialized", true)
	objective_panel.size = Vector2(310 if not stacked else 190, 150 if objective_body.visible else 44)
	objective_panel.clip_contents = true
	objective_button.text = ("GOALS " if stacked else "OBJECTIVES ") + ("v" if objective_body.visible else ">")
	var objective_content: VBoxContainer = objective_panel.get_child(0)
	objective_content.position = Vector2(6, 5)
	objective_content.size = objective_panel.size - Vector2(12, 10)
	objective_title.clip_text = false
	notification_label.position = Vector2(7, 5)
	notification_panel.position = Vector2((w - 480) * 0.5, bottom.position.y - 57)
	notification_panel.size = Vector2(minf(480, w - 2 * margin), 48)
	diagnostics.size = Vector2(minf(480, w - 22), minf(420, h - 22))
	diagnostics.position = (size - diagnostics.size) * 0.5
	var diag_scroll: ScrollContainer = diagnostics.get_child(0)
	diag_scroll.position = Vector2(12, 12)
	diag_scroll.size = diagnostics.size - Vector2(24, 24)
	var diag_content: VBoxContainer = diag_scroll.get_child(0)
	diag_content.position = Vector2(12, 12)
	diag_content.size.x = diag_scroll.size.x - 24
	restart_scrim.position = Vector2.ZERO
	restart_scrim.size = size
	restart_dialog.size = Vector2(minf(370, w - 24), 148)
	restart_dialog.position = (size - restart_dialog.size) * 0.5
	choice_panel.size = Vector2(minf(370, w - 24), minf(300, h - 90))
	choice_panel.position = (size - choice_panel.size) * 0.5
	choice_title.position = Vector2(12, 8)
	choice_title.size = Vector2(choice_panel.size.x - 24, 24)
	choice_scroll.position = Vector2(12, 37)
	choice_scroll.size = Vector2(choice_panel.size.x - 24, choice_panel.size.y - 49)
	result_panel.size = Vector2(minf(420, w - 24), 185)
	result_panel.position = (size - result_panel.size) * 0.5
	var result_column: VBoxContainer = result_panel.get_child(0)
	result_column.position = Vector2(15, 15)
	result_column.size = result_panel.size - Vector2(30, 30)
	_refresh_text_scale()

func _layout_selection(stacked: bool) -> void:
	var s := selection_panel.size
	var p := 56.0 if stacked else 104.0
	selection_portrait.position = Vector2(6, 7)
	selection_portrait.size = Vector2(p, minf(p, s.y - 14))
	group_grid.columns = 6 if stacked else 3
	group_grid.position = Vector2(5, 7)
	group_grid.size = Vector2(270 if stacked else 138, 52 if stacked else 98)
	var x := (270.0 if group_grid.visible else p + 12.0) if stacked else (150.0 if group_grid.visible else p + 12.0)
	selection_title.position = Vector2(x, 5)
	selection_title.clip_text = true
	selection_title.size = Vector2(maxf(0, s.x - x - (128 if stacked else 8)), 28)
	selection_faction.position = Vector2(x, 29)
	selection_faction.size = Vector2(maxf(0, s.x - x - (128 if stacked else 8)), 22)
	selection_faction.visible = not stacked
	selection_hp.position = Vector2(x, 51)
	selection_hp.size = Vector2(s.x - x - 10, 13)
	selection_hp_label.position = Vector2(x, 69)
	selection_hp_label.size = Vector2(s.x - x - 10, 22)
	if stacked:
		selection_hp.position.y = 55
		selection_hp.size.x = minf(180, maxf(0, s.x - x - 270))
		selection_hp_label.position = Vector2(x + selection_hp.size.x + 8, 47)
		selection_hp_label.size = Vector2(130, 22)
	selection_details.position = Vector2(7, p + 13) if not stacked else Vector2(x, 29)
	selection_details.size = Vector2(s.x - 14, 28) if not stacked else Vector2(maxf(0, s.x - x - 130), 24)
	selection_stats.position = Vector2(7, p + 45)
	selection_stats.size = Vector2(s.x - 14, 36)
	selection_stats.visible = not stacked
	compact_details.visible = false

func _layout_commands(stacked: bool) -> void:
	var s := command_panel.size
	var heading: Label = command_panel.get_node("Heading")
	heading.position = Vector2(4, 2)
	heading.size = Vector2(s.x - 8, 22)
	heading.text = "COMMANDS  •  SCROLL FOR MORE →" if stacked else "COMMANDS"
	command_scroll.position = Vector2(4, 25)
	command_scroll.size = Vector2(s.x - 8, s.y - (27 if stacked else 52))
	command_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO if stacked else ScrollContainer.SCROLL_MODE_DISABLED
	command_help.position = Vector2(4, s.y - 25)
	command_help.size = Vector2(s.x - 8, 22)
	command_help.visible = not stacked
	command_empty.position = Vector2(8, 31)
	command_empty.size = Vector2(s.x - 16, 28)
	reflow_commands()

func set_action(action: String, state: Dictionary, cost: int, active: bool) -> void:
	var b: Button = command_buttons[action]
	b.visible = state.visible
	b.disabled = not state.enabled
	b.set("active", active)
	var meta: Dictionary = ACTIONS[action]
	b.set("caption", meta.name)
	var tip := "%s\n%s" % [meta.name, meta.description]
	if cost > 0:
		tip += "\nCost: %d varos" % cost
	if not state.reason.is_empty():
		tip += "\nUnavailable: %s" % state.reason
	else:
		if not meta.key.is_empty():
			tip += "\nShortcut: %s" % meta.key
	b.tooltip_text = tip

func set_economy(stockpiles: Dictionary, age_name: String, population: int, capacity: int, source_notes: Dictionary) -> void:
	for id in resource_labels:
		var label: Label = resource_labels[id]
		label.text = "%s %d" % [id.capitalize(), int(stockpiles.get(id, 0))]
		label.tooltip_text = "%s: %d in stockpile. %s" % [id.capitalize(), int(stockpiles.get(id, 0)), str(source_notes.get(id, ""))]
	age_label.text = age_name.to_upper()
	age_label.tooltip_text = "Current age: " + age_name
	population_label.text = "%d/%d" % [population, capacity]
	population_label.tooltip_text = "Population used / capacity: %d / %d" % [population, capacity]

func show_choices(title: String, entries: Array[Dictionary]) -> void:
	choice_title.text = title
	for child in choice_list.get_children():
		child.queue_free()
	for entry in entries:
		var id := str(entry.get("id", ""))
		var b := _button(choice_list, str(entry.get("label", id)))
		b.custom_minimum_size.y = 48
		b.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not bool(entry.get("enabled", false))
		b.tooltip_text = str(entry.get("reason", ""))
		b.pressed.connect(_choose_entry.bind(id))
	var cancel := _button(choice_list, "CANCEL")
	cancel.custom_minimum_size.y = 44
	cancel.pressed.connect(func() -> void: choice_panel.hide())
	choice_panel.show()
	_refresh_text_scale()

func _choose_entry(id: String) -> void:
	choice_panel.hide()
	command.emit(id)

func reflow_commands() -> void:
	var stacked := size.x < 950 or size.y < 560
	var item_w := 88.0 if stacked else minf(90.0, (command_scroll.size.x - 20.0) / 4.0)
	var item_h := 64.0 if stacked else 72.0
	var i := 0
	for action in ACTIONS:
		var b: Button = command_buttons[action]
		if not b.visible:
			continue
		b.position = Vector2(float(i if stacked else i % 4) * (item_w + 6), 0 if stacked else float(i / 4) * (item_h + 6))
		b.size = Vector2(item_w, item_h)
		i += 1
	command_strip.custom_minimum_size = Vector2(maxf(command_scroll.size.x, float(i) * (item_w + 6)) if stacked else command_scroll.size.x, item_h if stacked else maxf(item_h, float(ceili(float(i) / 4.0)) * (item_h + 6)))
	command_empty.visible = i == 0

func set_selection(portrait: Texture2D, title: String, faction: String, hp: int, max_hp: int, activity: String, stats: String) -> void:
	selection_portrait.texture = portrait
	selection_title.text = title
	selection_faction.text = faction
	selection_hp.max_value = max_hp
	selection_hp.value = hp
	selection_hp.visible = max_hp > 0
	selection_hp_label.text = "%d / %d HP" % [hp, max_hp] if max_hp > 0 else ""
	selection_details.text = activity
	selection_stats.text = stats

func set_group(items: Array) -> void:
	selection_portrait.visible = items.is_empty()
	group_grid.visible = not items.is_empty()
	for child in group_grid.get_children():
		child.queue_free()
	for item in items.slice(0, 6):
		var b := Button.new()
		HudSkin.apply_button(b)
		b.custom_minimum_size = Vector2(44, 44)
		b.icon = item.texture
		b.expand_icon = true
		b.tooltip_text = "Select unit #%d" % item.id
		b.pressed.connect(func() -> void: subset_requested.emit(item.id))
		group_grid.add_child(b)

func set_secondary(title: String, cards: Array[Dictionary]) -> void:
	secondary_title.text = title
	for child in secondary_cards.get_children():
		child.queue_free()
	secondary_status.visible = cards.is_empty()
	secondary_reason.visible = not cards.is_empty()
	secondary_details.visible = not cards.is_empty() and size.x >= 950
	secondary_reason.text = ""
	for card in cards:
		var b := Button.new()
		HudSkin.apply_button(b)
		b.custom_minimum_size = Vector2(90, 74 if size.x < 950 else 104)
		b.icon = card.get("texture")
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = true
		b.text = str(card.get("label", "")).get_slice("\n", 0) if size.x < 950 else card.get("label", "")
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = not card.get("enabled", false)
		b.tooltip_text = card.get("tooltip", "")
		if card.has("action"):
			b.pressed.connect(func() -> void: command.emit(card.action))
		secondary_cards.add_child(b)
		if secondary_reason.text.is_empty():
			secondary_reason.text = str(card.get("reason", "")) if not card.get("enabled", true) else ("Cost %d gold" % int(card.get("cost", 0)) if card.get("cost", 0) > 0 else "")
	_refresh_text_scale()
	_layout()

func set_queue(entries: Array) -> void:
	var show_queue := not entries.is_empty() or secondary_title.text in ["PRODUCTION", "RESEARCH"]
	queue_title.visible = show_queue and size.x >= 950
	queue_title.text = "QUEUE  %d / 3" % entries.size()
	for i in 3:
		var slot: Panel = queue_slots[i]
		slot.visible = show_queue and size.x >= 950
		var label: Label = slot.get_child(0)
		if i < entries.size():
			label.text = "%s\n%ds" % [entries[i].role.substr(0, 3).to_upper(), ceili(float(entries[i].remaining) / 10.0)]
		else:
			label.text = "—"
	if size.x < 950 and show_queue:
		secondary_reason.text = "Queue %d / 3" % entries.size()

func show_notice(message: String, important: bool = false) -> void:
	if message.is_empty() or message == last_notification:
		return
	last_notification = message
	notification_label.text = ("! " if important else "* ") + message
	notification_panel.show()
	event_log.push_front(message)
	if event_log.size() > 8:
		event_log.pop_back()
	event_log_label.text = "EVENTS\n" + "\n".join(event_log)
	notification_age = 5.0 if important else 3.0

func show_result(outcome: String, reason: String) -> void:
	result_panel.visible = not outcome.is_empty()
	if outcome.is_empty():
		return
	result_title.text = {"win": "VICTORY", "loss": "DEFEAT", "draw": "DRAW"}.get(outcome, outcome.to_upper())
	var cause: String = {
		"command_post": "The enemy command post was destroyed." if outcome == "win" else "Your command post was destroyed.",
		"simultaneous_posts": "Both command posts were destroyed.",
		"district": "Your side held the center long enough." if outcome == "win" else "The enemy held the center long enough.",
		"time_limit": "The match reached its time limit."
	}.get(reason, reason.replace("_", " ").capitalize() + ".")
	result_reason.text = "%s Choose a new match when ready." % cause

func _process(delta: float) -> void:
	if notification_age > 0:
		notification_age -= delta
		if notification_age <= 0:
			notification_panel.hide()
			last_notification = ""
