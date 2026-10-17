extends Control

signal command(action: String)
signal subset_requested(id: int)
signal navigate(tile: Vector2i)
signal menu_requested
signal pause_requested
signal restart_requested

const HudSkin = preload("res://ui/hud_skin.gd")
const CommandButton = preload("res://ui/command_button.gd")
const MinimapPanel = preload("res://ui/minimap_panel.gd")
const ACTIONS := {
	"move": {"name": "MOVE", "key": "M", "description": "Choose clear ground for this unit."},
	"gather": {"name": "GATHER", "key": "H", "description": "Send the worker to your gold cart."},
	"build": {"name": "BUILD", "key": "B", "description": "Place a recruitment post on a clear 2×2 site."},
	"attack": {"name": "ATTACK", "key": "A", "description": "Choose an enemy unit or building."},
	"train_worker": {"name": "WORKER", "key": "1", "description": "Recruit a worker at the command post."},
	"train_melee": {"name": "FIGHTER", "key": "2", "description": "Recruit a melee fighter at the recruitment post."},
	"train_ranged": {"name": "RANGED", "key": "3", "description": "Recruit a ranged fighter at the recruitment post."},
	"cancel": {"name": "CANCEL", "key": "Esc", "description": "Leave target or placement mode."}
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
var invite_input: LineEdit
var invite_save: Button
var support_copy: Button
var close_diagnostics: Button
var gold_label: Label
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
var secondary_panel: Panel
var secondary_title: Label
var secondary_status: Label
var secondary_reason: Label
var secondary_details: Label
var queue_title: Label
var queue_slots: Array[Panel] = []
var secondary_cards: HBoxContainer
var minimap: Control
var compact_details: Button
var secondary_toggle: Button
var mobile_secondary_open := false
var paused := false
var last_notification := ""

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	_build()
	resized.connect(_layout)
	get_viewport().size_changed.connect(_resize_for_viewport)
	_resize_for_viewport()

func _resize_for_viewport() -> void:
	var view := get_viewport().get_visible_rect().size
	var factor := 1.0
	if view.x >= 950.0 and view.y >= 560.0:
		factor = clampf(minf(view.x / 1280.0, view.y / 800.0), 1.0, 1.75)
	scale = Vector2.ONE * factor
	size = view / factor
	_layout()

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
	var resource := HBoxContainer.new()
	resource.add_theme_constant_override("separation", 5)
	top_row.add_child(resource)
	var icon := CommandButton.new()
	icon.glyph = "gold"
	icon.text = ""
	icon.disabled = true
	icon.custom_minimum_size = Vector2(35, 32)
	resource.add_child(icon)
	icon.custom_minimum_size = Vector2(35, 32)
	gold_label = _label(resource, "0", 18, HudSkin.GOLD)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_row.add_child(spacer)
	gold_label.tooltip_text = "Gold in your stockpile. The only spendable resource in this alpha."
	var divider := VSeparator.new()
	top_row.add_child(divider)
	timer_label = _label(top_row, "00:00", 17)
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
	selection_title = _label(selection_panel, "NO SELECTION", 17, HudSkin.GOLD)
	selection_faction = _label(selection_panel, "", 12, HudSkin.MUTED)
	selection_hp = ProgressBar.new()
	selection_hp.show_percentage = false
	selection_hp.add_theme_stylebox_override("background", HudSkin.button(HudSkin.INK, HudSkin.BRONZE))
	selection_hp.add_theme_stylebox_override("fill", HudSkin.button(HudSkin.GREEN, HudSkin.GREEN))
	selection_panel.add_child(selection_hp)
	selection_hp_label = _label(selection_panel, "", 12)
	selection_details = _label(selection_panel, "", 13, HudSkin.MUTED)
	selection_stats = _label(selection_panel, "", 12, HudSkin.TEXT)
	compact_details = _button(selection_panel, "^")
	compact_details.tooltip_text = "Expand selection details"
	compact_details.pressed.connect(func() -> void: selection_stats.visible = not selection_stats.visible)

	command_panel = _panel(bottom, 7)
	var command_heading := _label(command_panel, "COMMANDS", 12, HudSkin.GOLD)
	command_heading.name = "Heading"
	for action in ACTIONS:
		var b := CommandButton.new()
		b.glyph = action
		b.caption = ACTIONS[action].name
		b.pressed.connect(func() -> void: command.emit(action))
		command_panel.add_child(b)
		command_buttons[action] = b
	command_help = _label(command_panel, "", 13, HudSkin.GOLD)
	command_help.name = "Help"
	command_empty = _label(command_panel, "SELECT AN ACTOR", 13, HudSkin.MUTED)
	command_help.clip_text = true
	secondary_panel = _panel(bottom, 7)
	secondary_title = _label(secondary_panel, "CONTEXT", 12, HudSkin.GOLD)
	secondary_status = _label(secondary_panel, "", 13, HudSkin.TEXT)
	secondary_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	secondary_reason = _label(secondary_panel, "", 11, HudSkin.MUTED)
	secondary_details = _label(secondary_panel, "", 13, HudSkin.TEXT)
	secondary_details.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	queue_title = _label(secondary_panel, "QUEUE  0 / 3", 11, HudSkin.GOLD)
	for i in 3:
		var slot := _panel(secondary_panel, 3)
		var slot_label := _label(slot, "—", 12, HudSkin.MUTED)
		slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		queue_slots.append(slot)
	secondary_cards = HBoxContainer.new()
	secondary_cards.add_theme_constant_override("separation", 6)
	secondary_panel.add_child(secondary_cards)
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
	objective_title = _label(objective_body, "Capture La Roma", 13)
	_label(objective_body, "or destroy enemy command post", 11, HudSkin.MUTED)
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
	notification_label = _label(notification_panel, "", 13, HudSkin.TEXT)
	notification_panel.hide()

	diagnostics = _panel(self, 14, true)
	diagnostics.z_index = 20
	var diag_col := VBoxContainer.new()
	diag_col.add_theme_constant_override("separation", 8)
	diagnostics.add_child(diag_col)
	var head := HBoxContainer.new()
	diag_col.add_child(head)
	_label(head, "SETTINGS / ALPHA SUPPORT", 19, HudSkin.GOLD)
	var grow := Control.new()
	grow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(grow)
	close_diagnostics = _button(head, "X")
	close_diagnostics.pressed.connect(func() -> void: diagnostics.hide())
	diagnostics_label = _label(diag_col, "", 13)
	diagnostics_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	event_log_label = _label(diag_col, "EVENTS", 12, HudSkin.MUTED)
	event_log_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	invite_input = LineEdit.new()
	invite_input.placeholder_text = "Private alpha invite code"
	invite_input.secret = true
	diag_col.add_child(invite_input)
	invite_save = _button(diag_col, "Save invite code")
	support_copy = _button(diag_col, "Copy support ID")
	diagnostics.hide()

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
	var portrait := w < 620
	var mobile := w < 950 or h < 560
	var margin := 7.0 if mobile else 13.0
	var top_h := 52.0
	top.position = Vector2(margin, margin)
	top.size = Vector2(w - margin * 2.0, top_h)
	var top_row: HBoxContainer = top.get_node("TopRow")
	top_row.position = Vector2.ZERO
	top_row.size = top.size - Vector2(12, 10)
	top_row.add_theme_constant_override("separation", 4 if mobile else 12)
	faction_label.custom_minimum_size.x = 70 if mobile else 160
	faction_label.add_theme_font_size_override("font_size", 12 if mobile else 16)
	timer_label.add_theme_font_size_override("font_size", 13 if mobile else 17)
	timer_label.custom_minimum_size.x = 48 if mobile else 58
	restart_button.add_theme_font_size_override("font_size", 12 if mobile else 16)
	var bottom_h := 222.0 if portrait else (122.0 if mobile else 193.0)
	var bottom_w := minf(w - 2.0 * margin, 1250.0) if not mobile else w - 2.0 * margin
	bottom.position = Vector2((w - bottom_w) * 0.5, h - bottom_h - margin)
	bottom.size = Vector2(bottom_w, bottom_h)
	var available := bottom.size.x - 16.0
	var content_h := bottom_h - 16.0
	var left_w := 315.0 if not mobile else (170.0 if not portrait else available)
	var right_w := available - left_w - 400.0 - 14.0 if not mobile else (130.0 if not portrait else available)
	var gap := 7.0
	var center_w := available - left_w - right_w - 2.0 * gap
	if portrait:
		selection_panel.position = Vector2(8, 8)
		selection_panel.size = Vector2(available, 75)
		command_panel.position = Vector2(8, 90)
		command_panel.size = Vector2(available, content_h - 82)
		secondary_panel.position = Vector2(8, -118)
		secondary_panel.size = Vector2(available, 110)
		secondary_panel.visible = mobile_secondary_open
		secondary_toggle.position = Vector2(available - 90, 82)
		secondary_toggle.size = Vector2(90, 27)
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
	_layout_selection(portrait, mobile)
	_layout_commands(portrait, mobile)
	secondary_title.position = Vector2(5, 3)
	secondary_cards.position = Vector2(5, 40 if mobile else 25)
	secondary_cards.size = secondary_panel.size - Vector2(10, 45 if mobile else 30)
	secondary_status.position = Vector2(6, 30)
	secondary_status.size = secondary_panel.size - Vector2(12, 38)
	secondary_reason.position = Vector2(6, 22 if mobile else secondary_panel.size.y - 19)
	secondary_reason.size = Vector2(secondary_panel.size.x - 12, 16)
	var queue_visible := not mobile and queue_title.visible
	secondary_details.position = Vector2(114 if not mobile else 5, 29)
	secondary_details.size = Vector2(maxf(0, secondary_panel.size.x - 126), 46)
	secondary_details.visible = not mobile and not secondary_status.visible
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
	var map_w := 180.0 if not mobile else (104.0 if not portrait else 112.0)
	var map_h := 150.0 if not mobile else (91.0 if not portrait else 105.0)
	minimap.position = Vector2(w - margin - map_w, top.position.y + top_h + 8)
	minimap.size = Vector2(map_w, map_h)
	objective_panel.position = Vector2(margin, top.position.y + top_h + 8)
	if mobile and not objective_panel.has_meta("mobile_initialized"):
		objective_body.hide()
		objective_panel.set_meta("mobile_initialized", true)
	objective_panel.size = Vector2(230 if not mobile else (170 if not portrait else 165), 104 if objective_body.visible else 39)
	objective_panel.clip_contents = true
	objective_button.text = ("GOALS " if mobile else "OBJECTIVES ") + ("v" if objective_body.visible else ">")
	var objective_content: VBoxContainer = objective_panel.get_child(0)
	objective_content.position = Vector2(6, 5)
	objective_content.size = objective_panel.size - Vector2(12, 10)
	objective_title.clip_text = true
	notification_label.position = Vector2(7, 5)
	notification_panel.position = Vector2((w - 340) * 0.5, bottom.position.y - 44)
	notification_panel.size = Vector2(minf(340, w - 2 * margin), 36)
	diagnostics.size = Vector2(minf(480, w - 22), minf(340, h - 22))
	diagnostics.position = (size - diagnostics.size) * 0.5
	var diag_content: VBoxContainer = diagnostics.get_child(0)
	diag_content.position = Vector2(12, 12)
	diag_content.size = diagnostics.size - Vector2(24, 24)
	restart_scrim.position = Vector2.ZERO
	restart_scrim.size = size
	restart_dialog.size = Vector2(minf(370, w - 24), 148)
	restart_dialog.position = (size - restart_dialog.size) * 0.5

func _layout_selection(portrait: bool, mobile: bool) -> void:
	var s := selection_panel.size
	var p := 62.0 if mobile else 98.0
	selection_portrait.position = Vector2(6, 7)
	selection_portrait.size = Vector2(p, minf(p, s.y - 14))
	group_grid.position = Vector2(5, 7)
	group_grid.size = Vector2(p, minf(p, s.y - 14))
	var x := p + 12.0
	selection_title.position = Vector2(x, 5)
	selection_title.clip_text = true
	selection_title.size = Vector2(s.x - x - 8, 24)
	selection_faction.position = Vector2(x, 29)
	selection_faction.size = Vector2(s.x - x - 8, 18)
	selection_hp.position = Vector2(x, 51)
	selection_hp.size = Vector2(s.x - x - 10, 13)
	selection_hp_label.position = Vector2(x, 66)
	selection_hp_label.size = Vector2(s.x - x - 10, 17)
	if portrait:
		selection_hp_label.position = Vector2(x, 43)
		selection_hp_label.size = Vector2(80, 13)
		selection_hp.position.y = 57
		selection_hp.size.y = 9
	selection_details.position = Vector2(7, p + 13) if not portrait else Vector2(x + 88, 28)
	selection_details.size = Vector2(s.x - 14, 28) if not portrait else Vector2(maxf(0, s.x - x - 94), 21)
	selection_stats.position = Vector2(7, p + 40)
	selection_stats.size = Vector2(s.x - 14, 36)
	selection_stats.visible = not mobile
	compact_details.visible = mobile and portrait
	compact_details.position = Vector2(s.x - 31, 5)
	compact_details.size = Vector2(25, 26)
	if mobile:
		selection_title.add_theme_font_size_override("font_size", 13)
		selection_details.add_theme_font_size_override("font_size", 11)

func _layout_commands(portrait: bool, mobile: bool) -> void:
	var s := command_panel.size
	var heading: Label = command_panel.get_node("Heading")
	heading.position = Vector2(4, 2)
	heading.size = Vector2(s.x - 8, 18)
	var cols := 4 if not portrait else 4
	var gap := 4.0
	var item_w := minf(68.0, (s.x - 12 - gap * float(cols - 1)) / cols)
	var item_h := 60.0 if not mobile else 58.0
	var i := 0
	for action in ACTIONS:
		var b: Button = command_buttons[action]
		if not b.visible:
			continue
		b.position = Vector2(4 + float(i % cols) * (item_w + gap), 23 + float(i / cols) * (item_h + gap))
		b.size = Vector2(item_w, item_h)
		i += 1
	command_help.position = Vector2(4, s.y - 24)
	command_help.size = Vector2(s.x - 8, 20)
	command_help.visible = not mobile
	command_empty.position = Vector2(8, 30)
	command_empty.size = Vector2(s.x - 16, 28)

func set_action(action: String, state: Dictionary, cost: int, active: bool) -> void:
	var b: Button = command_buttons[action]
	b.visible = state.visible
	b.disabled = not state.enabled
	b.set("active", active)
	var meta: Dictionary = ACTIONS[action]
	b.set("caption", meta.name)
	var tip := "%s\n%s" % [meta.name, meta.description]
	if cost > 0:
		tip += "\nCost: %d gold" % cost
	if not state.reason.is_empty():
		tip += "\nUnavailable: %s" % state.reason
	else:
		tip += "\nShortcut: %s" % meta.key
	b.tooltip_text = tip

func reflow_commands() -> void:
	var w := command_panel.size.x
	var mobile := size.x < 950 or size.y < 560
	var item_w := minf(70.0, (w - 24.0) / 4.0)
	var item_h := 58.0 if mobile else 60.0
	var i := 0
	for action in ACTIONS:
		var b: Button = command_buttons[action]
		if not b.visible:
			continue
		b.position = Vector2(4 + float(i % 4) * (item_w + 4), 23 + float(i / 4) * (item_h + 4))
		b.size = Vector2(item_w, item_h)
		i += 1
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
		b.custom_minimum_size = Vector2(30, 30)
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
		b.custom_minimum_size = Vector2(79, 58 if size.x < 950 else 96)
		b.icon = card.get("texture")
		b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		b.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
		b.expand_icon = true
		b.text = str(card.get("label", "")).get_slice("\n", 0) if size.x < 950 else card.get("label", "")
		b.add_theme_font_size_override("font_size", 10)
		b.disabled = not card.get("enabled", false)
		b.tooltip_text = card.get("tooltip", "")
		if card.has("action"):
			b.pressed.connect(func() -> void: command.emit(card.action))
		secondary_cards.add_child(b)
		if secondary_reason.text.is_empty():
			secondary_reason.text = str(card.get("reason", "")) if not card.get("enabled", true) else ("Cost %d gold" % int(card.get("cost", 0)) if card.get("cost", 0) > 0 else "")

func set_queue(entries: Array) -> void:
	var show_queue := not entries.is_empty() or secondary_title.text == "PRODUCTION"
	queue_title.visible = show_queue and size.x >= 950
	queue_title.text = "PRODUCTION QUEUE  %d / 3" % entries.size()
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

func _process(delta: float) -> void:
	if notification_age > 0:
		notification_age -= delta
		if notification_age <= 0:
			notification_panel.hide()
			last_notification = ""
