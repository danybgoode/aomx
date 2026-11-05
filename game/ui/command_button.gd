extends Button

const HudSkin = preload("res://ui/hud_skin.gd")
var glyph := "move":
	set(value):
		glyph = value
		queue_redraw()
var active := false:
	set(value):
		active = value
		queue_redraw()
var caption := "":
	set(value):
		caption = value
		queue_redraw()
var caption_scale := 1.0

func _ready() -> void:
	HudSkin.apply_button(self)
	custom_minimum_size = Vector2(76, 64)
	focus_mode = Control.FOCUS_ALL
	mouse_entered.connect(queue_redraw)
	mouse_exited.connect(queue_redraw)
	pressed.connect(queue_redraw)
	button_up.connect(queue_redraw)

func _draw() -> void:
	var c: Color = HudSkin.GOLD if glyph == "gold" else (HudSkin.MUTED if disabled else (HudSkin.GOLD if active or is_hovered() else HudSkin.TEXT))
	if size.y < 60.0:
		if not caption.is_empty():
			draw_string(ThemeDB.fallback_font, Vector2(2, size.y * 0.5 + 6), caption.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, roundi(16.0 * caption_scale), c)
		return
	var o := Vector2(size.x * 0.5, 24)
	if active:
		draw_rect(Rect2(Vector2(3, 3), size - Vector2(6, 6)), HudSkin.GOLD, false, 2)
	match glyph:
		"stop":
			draw_rect(Rect2(o - Vector2(12, 12), Vector2(24, 24)), c)
		"hold":
			poly([o + Vector2(-12, -13), o + Vector2(12, -13), o + Vector2(10, 6), o + Vector2(0, 15), o + Vector2(-10, 6)], c)
		"attack_move":
			poly([o + Vector2(-16, 3), o + Vector2(2, -13), o + Vector2(2, -5), o + Vector2(15, -5), o + Vector2(15, 7), o + Vector2(2, 7), o + Vector2(2, 14)], c)
		"move":
			poly([o + Vector2(-17, 0), o + Vector2(2, -15), o + Vector2(2, -6), o + Vector2(17, -6), o + Vector2(17, 6), o + Vector2(2, 6), o + Vector2(2, 15)], c)
		"attack":
			draw_line(o + Vector2(-13, -12), o + Vector2(12, 13), c, 4)
			draw_line(o + Vector2(13, -12), o + Vector2(-12, 13), c, 4)
			draw_line(o + Vector2(-16, -10), o + Vector2(-10, -16), c, 3)
			draw_line(o + Vector2(16, -10), o + Vector2(10, -16), c, 3)
		"gather":
			draw_line(o + Vector2(-11, 12), o + Vector2(7, -12), c, 5)
			poly([o + Vector2(2, -13), o + Vector2(16, -14), o + Vector2(14, -4), o + Vector2(4, -5)], c)
		"build":
			draw_line(o + Vector2(-10, 14), o + Vector2(7, -12), c, 5)
			poly([o + Vector2(-1, -15), o + Vector2(15, -15), o + Vector2(17, -8), o + Vector2(2, -7)], c)
		"train_worker", "train_melee", "train_ranged":
			draw_circle(o + Vector2(0, -9), 6, c)
			draw_rect(Rect2(o + Vector2(-10, -1), Vector2(20, 14)), c)
			if glyph == "train_melee":
				draw_line(o + Vector2(12, -13), o + Vector2(12, 12), HudSkin.BRONZE, 3)
			elif glyph == "train_ranged":
				draw_arc(o + Vector2(10, 0), 12, -1.3, 1.3, 12, HudSkin.BRONZE, 3)
		"cancel":
			draw_arc(o, 13, 0, TAU, 24, c, 3)
			draw_line(o + Vector2(-9, -9), o + Vector2(9, 9), c, 3)
		"pause":
			draw_rect(Rect2(o + Vector2(-9, -13), Vector2(6, 26)), c)
			draw_rect(Rect2(o + Vector2(3, -13), Vector2(6, 26)), c)
		"menu":
			for y in [-9, 0, 9]:
				draw_line(o + Vector2(-13, y), o + Vector2(13, y), c, 3)
		"gold":
			poly([o + Vector2(-11, 3), o + Vector2(-6, -8), o + Vector2(8, -8), o + Vector2(13, 3), o + Vector2(6, 12), o + Vector2(-7, 12)], c)
	if not caption.is_empty():
		draw_string(ThemeDB.fallback_font, Vector2(2, size.y - 9), caption.to_upper(), HORIZONTAL_ALIGNMENT_CENTER, size.x - 4, roundi(16.0 * caption_scale), c)

func poly(points: Array[Vector2], color: Color) -> void:
	draw_colored_polygon(PackedVector2Array(points), color)
