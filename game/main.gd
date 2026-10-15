extends Node2D

const Sim = preload("res://simulation.gd")
const TILE_W := 48.0
const TILE_H := 24.0
const ORIGIN := Vector2(640, 66)
const TICK_SECONDS := 0.1

var sim = Sim.new()
var selected := false
var placing := false
var marker := Vector2i(-1, -1)
var accumulator := 0.0
var hud: Label
var instructions: Label

func _ready() -> void:
	var layer := CanvasLayer.new()
	add_child(layer)
	hud = Label.new()
	hud.position = Vector2(22, 650)
	hud.add_theme_font_size_override("font_size", 20)
	layer.add_child(hud)
	instructions = Label.new()
	instructions.position = Vector2(22, 735)
	instructions.add_theme_font_size_override("font_size", 17)
	instructions.text = "Left-click worker to select · Right-click tile to move/resource to gather · B to build · R to reset"
	layer.add_child(instructions)
	_update_hud()

func _process(delta: float) -> void:
	accumulator += delta
	var advanced := false
	while accumulator >= TICK_SECONDS:
		sim.tick()
		accumulator -= TICK_SECONDS
		advanced = true
	if advanced:
		_update_hud()
		queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_B and selected:
			placing = true
			sim.feedback = "Choose a clear 2 by 2 footprint. Cost: 6."
		elif event.keycode == KEY_ESCAPE:
			placing = false
		elif event.keycode == KEY_R:
			sim = Sim.new()
			selected = false
			placing = false
			marker = Vector2i(-1, -1)
	elif event is InputEventMouseButton and event.pressed:
		var tile := _screen_to_tile(event.position)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if placing:
				var outcome: Dictionary = sim.issue("build", tile)
				if outcome.ok:
					placing = false
			elif tile == sim.worker:
				selected = true
				sim.feedback = "worker selected"
			else:
				selected = false
		elif event.button_index == MOUSE_BUTTON_RIGHT and selected:
			var outcome: Dictionary
			if tile == Sim.RESOURCE:
				outcome = sim.issue("gather", tile)
			else:
				outcome = sim.issue("move", tile)
			if outcome.ok:
				marker = tile
	_update_hud()
	queue_redraw()

func _update_hud() -> void:
	var building_text := "none"
	if sim.building_position.x >= 0:
		building_text = "complete" if sim.building_complete else "%d/%d" % [sim.building_progress, Sim.BUILD_TICKS]
	hud.text = "Source: %d   Carrying: %d/%d   Stockpile: %d   Structure: %s   Frame process: %.2f ms\n%s\n%s" % [
		sim.resource_amount, sim.carrying, Sim.CARRY_LIMIT, sim.stockpile, building_text,
		Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0,
		"Selected worker" if selected else "Click the worker", sim.feedback.capitalize()]

func _tile_to_screen(tile: Vector2i) -> Vector2:
	return ORIGIN + Vector2((tile.x - tile.y) * TILE_W * 0.5, (tile.x + tile.y) * TILE_H * 0.5)

func _screen_to_tile(screen: Vector2) -> Vector2i:
	var dx := (screen.x - ORIGIN.x) / (TILE_W * 0.5)
	var dy := (screen.y - ORIGIN.y) / (TILE_H * 0.5)
	return Vector2i(roundi((dx + dy) * 0.5), roundi((dy - dx) * 0.5))

func _diamond(center: Vector2) -> PackedVector2Array:
	return PackedVector2Array([center + Vector2(0, -TILE_H * 0.5), center + Vector2(TILE_W * 0.5, 0),
		center + Vector2(0, TILE_H * 0.5), center + Vector2(-TILE_W * 0.5, 0)])

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, get_viewport_rect().size), Color("17212a"))
	for y in range(Sim.HEIGHT):
		for x in range(Sim.WIDTH):
			var tile := Vector2i(x, y)
			var center := _tile_to_screen(tile)
			var color := Color("526c5d") if (x + y) % 2 == 0 else Color("496251")
			if x == 10 and y != 10 or tile in [Vector2i(14, 15), Vector2i(16, 15), Vector2i(15, 14), Vector2i(15, 16)]:
				color = Color("263a4a")
			if tile == Sim.DROPOFF:
				color = Color("d9ae6b")
			if tile == marker:
				color = Color("7a9ccd")
			draw_colored_polygon(_diamond(center), color)
			draw_polyline(_diamond(center) + PackedVector2Array([_diamond(center)[0]]), Color("283b40"), 1.0)
	if sim.resource_amount > 0:
		var resource_center := _tile_to_screen(Sim.RESOURCE)
		draw_circle(resource_center + Vector2(0, -9), 11.0, Color("e7b34a"))
		draw_string(ThemeDB.fallback_font, resource_center + Vector2(-10, -20), str(sim.resource_amount), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color.WHITE)
	if sim.building_position.x >= 0:
		for oy in range(2):
			for ox in range(2):
				var center := _tile_to_screen(sim.building_position + Vector2i(ox, oy))
				draw_colored_polygon(_diamond(center), Color("c77c4d") if sim.building_complete else Color("9d8f7a"))
	var worker_center := _tile_to_screen(sim.worker) + Vector2(0, -12)
	if selected:
		draw_arc(worker_center + Vector2(0, 10), 15, 0, TAU, 24, Color("eae466"), 2.0)
	draw_circle(worker_center, 8.0, Color("65c7d2"))
	draw_circle(worker_center + Vector2(0, -5), 4.0, Color("f2d8a3"))
	if placing:
		var preview_tile := _screen_to_tile(get_global_mouse_position())
		for oy in range(2):
			for ox in range(2):
				var center := _tile_to_screen(preview_tile + Vector2i(ox, oy))
				draw_colored_polygon(_diamond(center), Color(0.9, 0.9, 0.3, 0.45))
