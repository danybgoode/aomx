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
	var width: int = sim.map_width if sim != null else Skirmish.WIDTH
	var height: int = sim.map_height if sim != null else Skirmish.HEIGHT
	for x in width:
		for y in height:
			var tile := Vector2i(x, y)
			var cell := Rect2(inner.position + Vector2(float(x) / width, float(y) / height) * inner.size,
				inner.size / Vector2(width, height) + Vector2.ONE)
			var terrain: String = terrain_classifier.call(tile) if terrain_classifier.is_valid() else "terrain_grass_0"
			var color := Color("454945") if terrain.contains("asphalt") else Color("777368") if terrain.contains("sidewalk") else Color("4e624b")
			if terrain.contains("plaza"):
				color = HudSkin.BRONZE
			if sim != null and not sim.is_explored(Skirmish.HUMAN, tile):
				color = Color("141a21")
			elif sim != null and not sim.is_visible(Skirmish.HUMAN, tile):
				color = color.darkened(0.65)
			draw_rect(cell, color)
	if sim != null:
		var resource_colors := {"comida": Color("93d38b"), "materiales": Color("c4c8d2"), "varos": Color("f3c666"), "terrenos": Color("b9a4e8")}
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			for id in Skirmish.RESOURCE_IDS:
				var source: Dictionary = sim.resource_sources[side][id]
				if source.amount > 0 and sim.is_visible(Skirmish.HUMAN, source.pos):
					draw_circle(_point(inner, source.pos), 2.5, resource_colors[id])
		for entity in sim.entities.values():
			if entity.hp <= 0 or (entity.side == Skirmish.COMPUTER and not sim.is_visible(Skirmish.HUMAN, entity.pos)):
				continue
			var c: Color = Color("70d5e7") if entity.side == Skirmish.HUMAN else Color("ed796a")
			var p := _point(inner, entity.pos)
			if entity.kind in sim.content.buildings:
				draw_rect(Rect2(p - Vector2(4, 4), Vector2(8, 8)), c)
			else:
				draw_circle(p, 3, c)
	var camera_p := _point(inner, camera_tile)
	var view_size := inner.size * view_span / Vector2(width, height)
	var camera_rect := Rect2(camera_p - view_size * 0.5, view_size).intersection(inner)
	draw_rect(camera_rect, HudSkin.TEXT, false, 1.5)
	draw_rect(Rect2(Vector2.ZERO, size), HudSkin.BRONZE, false, 2)

func _point(inner: Rect2, tile: Vector2i) -> Vector2:
	return inner.position + (Vector2(tile) + Vector2(0.5, 0.5)) / Vector2(sim.map_width, sim.map_height) * inner.size

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var inner := Rect2(Vector2(7, 7), size - Vector2(14, 14))
		var p: Vector2 = ((event.position - inner.position) / inner.size).clamp(Vector2.ZERO, Vector2.ONE * 0.999)
		navigate.emit(Vector2i(floori(p.x * sim.map_width), floori(p.y * sim.map_height)))
		accept_event()
