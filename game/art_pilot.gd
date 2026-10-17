extends Node2D

const ArtCatalog = preload("res://art_catalog.gd")
const DIRECTIONS := ["se", "sw", "nw", "ne"]

var art = ArtCatalog.new()
var elapsed := 0.0
var direction_index := 0

func _ready() -> void:
	art.load_manifest(true)
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_LEFT:
			direction_index = posmod(direction_index - 1, DIRECTIONS.size())
		elif event.keycode == KEY_RIGHT:
			direction_index = posmod(direction_index + 1, DIRECTIONS.size())
		elif event.keycode == KEY_S:
			_save_capture()
		elif event.keycode == KEY_P:
			print("Art pilot FPS: ", Engine.get_frames_per_second())
		queue_redraw()

func _save_capture() -> void:
	var path := "user://owned-art-pilot.png"
	var result := get_viewport().get_texture().get_image().save_png(path)
	print("Art pilot capture: ", ProjectSettings.globalize_path(path), " result=", result)

func frame_id() -> String:
	return "critter_boar_%s_idle_%d" % [DIRECTIONS[direction_index], int(elapsed * 7.0) % 7]

func _sprite(id: String, ground: Vector2) -> void:
	draw_texture(art.texture(id), ground - art.pivot(id))

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0,-12), center + Vector2(24,0),
		center + Vector2(0,12), center + Vector2(-24,0)])

func _sample(origin: Vector2, zoom: float) -> void:
	draw_set_transform(origin, 0.0, Vector2.ONE * zoom)
	for row in range(4):
		for col in range(5):
			var center := Vector2(105 + (col-row)*24, 145 + (col+row)*12)
			draw_colored_polygon(_diamond(center), Color("987e69"))
	# Raised tile candidates are shown at their true 48x24 top-diamond pitch.
	_sprite("terrain_owned_000", Vector2(129, 169))
	_sprite("terrain_owned_022", Vector2(177, 169))
	_sprite("prop_owned_flowers", Vector2(201, 193))
	_sprite("building_command_post_blue", Vector2(95, 285))
	_sprite("building_concept_command_post_blue", Vector2(255, 285))
	_sprite(frame_id(), Vector2(188, 275))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("17212a"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 55), "OWNED ART SCALE PILOT", HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color("f7e6bf"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 84), "Raised source tiles · ambient boar candidate (pilot only) · isolated concept building", HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("d5d4c8"))
	_sample(Vector2(80, 155), 1.0)
	_sample(Vector2(670, 125), 1.25)
	draw_string(ThemeDB.fallback_font, Vector2(83, 585), "100%   current post / concept post", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(672, 585), "125%   current post / concept post", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(42, 655), "Boar %s idle frame %d / 7  ·  Left / Right: direction  ·  S: capture  ·  P: FPS" % [DIRECTIONS[direction_index].to_upper(), int(elapsed * 7.0) % 7 + 1], HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("ffe391"))
	draw_string(ThemeDB.fallback_font, Vector2(42, 687), "The tiles and boar do not alter passability, selection or objectives.", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, Color("d5d4c8"))
