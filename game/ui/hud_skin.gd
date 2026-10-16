extends RefCounted

const INK := Color("171b21")
const STONE := Color("252a2c")
const STONE_LIGHT := Color("34383a")
const BRONZE := Color("a78451")
const GOLD := Color("f1cf88")
const TEXT := Color("f1ead9")
const MUTED := Color("b8b9b1")
const GREEN := Color("81bb8a")
const RED := Color("dc8072")

static func panel(padding: int = 10, stronger: bool = false) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = INK if stronger else STONE
	s.border_color = BRONZE
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.shadow_color = Color(0, 0, 0, 0.38)
	s.shadow_size = 4
	s.set_content_margin_all(padding)
	return s

static func button(fill: Color, border: Color = BRONZE) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = fill
	s.border_color = border
	s.set_border_width_all(2)
	s.set_corner_radius_all(3)
	s.set_content_margin_all(3)
	return s

static func apply_button(b: Button) -> void:
	b.add_theme_stylebox_override("normal", button(STONE_LIGHT))
	b.add_theme_stylebox_override("hover", button(Color("4b483b"), GOLD))
	b.add_theme_stylebox_override("pressed", button(Color("6a5232"), GOLD))
	b.add_theme_stylebox_override("focus", button(Color(0, 0, 0, 0), GOLD))
	b.add_theme_stylebox_override("disabled", button(Color("222528"), Color("54534a")))
	b.add_theme_color_override("font_color", TEXT)
	b.add_theme_color_override("font_hover_color", GOLD)
	b.add_theme_color_override("font_disabled_color", Color("777973"))

static func label(l: Label, size: int = 14, color: Color = TEXT) -> Label:
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l
