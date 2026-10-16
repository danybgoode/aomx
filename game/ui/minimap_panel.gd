extends Control

signal navigate(tile: Vector2i)
const Skirmish = preload("res://skirmish.gd")
const HudSkin = preload("res://ui/hud_skin.gd")
var sim: RefCounted
var camera_tile := Vector2i(10, 10)
var view_span := Vector2(20, 20)
var terrain_classifier: Callable

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2.ZERO
	tooltip_text = "LA ROMA MAP • click to center view"

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), HudSkin.INK)
	var inner := Rect2(Vector2(7, 7), size - Vector2(14, 14))
	draw_rect(inner, Color("383b31"))
	for x in Skirmish.WIDTH:
		for y in Skirmish.HEIGHT:
			var tile := Vector2i(x, y)
			var cell := Rect2(inner.position + Vector2(float(x) / Skirmish.WIDTH, float(y) / Skirmish.HEIGHT) * inner.size,
				inner.size / Vector2(Skirmish.WIDTH, Skirmish.HEIGHT) + Vector2.ONE)
			var terrain: String = terrain_classifier.call(tile) if terrain_classifier.is_valid() else "terrain_grass_0"
			var color := Color("454945") if terrain.contains("asphalt") else Color("777368") if terrain.contains("sidewalk") else Color("4e624b")
			if terrain.contains("plaza"):
				color = HudSkin.BRONZE
			draw_rect(cell, color)
	if sim != null:
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var source: Dictionary = sim.sources[side]
			if source.amount > 0:
				draw_circle(_point(inner, source.pos), 3, HudSkin.GOLD)
		for entity in sim.entities.values():
			if entity.hp <= 0:
				continue
			var c: Color = Color("70d5e7") if entity.side == Skirmish.HUMAN else Color("ed796a")
			var p := _point(inner, entity.pos)
			if entity.kind in ["command_post", "barracks"]:
				draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), c)
			else:
				draw_circle(p, 3, c)
	var camera_p := _point(inner, camera_tile)
	var view_size := inner.size * view_span / Vector2(Skirmish.WIDTH, Skirmish.HEIGHT)
	var camera_rect := Rect2(camera_p - view_size * 0.5, view_size).intersection(inner)
	draw_rect(camera_rect, HudSkin.TEXT, false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, size), HudSkin.BRONZE, false, 2)

func _point(inner: Rect2, tile: Vector2i) -> Vector2:
	return inner.position + (Vector2(tile) + Vector2(0.5, 0.5)) / Vector2(Skirmish.WIDTH, Skirmish.HEIGHT) * inner.size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var inner := Rect2(Vector2(7, 7), size - Vector2(14, 14))
		var p: Vector2 = ((event.position - inner.position) / inner.size).clamp(Vector2.ZERO, Vector2.ONE * 0.999)
		navigate.emit(Vector2i(floori(p.x * Skirmish.WIDTH), floori(p.y * Skirmish.HEIGHT)))
		accept_event()
