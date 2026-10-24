extends SceneTree

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var client = Scene.instantiate()
	var path := "user://large-map-client-%d.json" % Time.get_ticks_usec()
	client.outbox = Outbox.new(path)
	root.add_child(client)
	client._choose_map(Skirmish.MAP_IDS.find("la_roma_large"))
	check(client.selected_map == "la_roma_large" and "bicitaxi" in client.setup_map_details.text, "large map is selectable with clear scout copy")
	client._choose_faction(Skirmish.REGIOS)
	check(client.sim.map_width == 96 and client.hud_ui.minimap.camera_tile == client._starting_camera_tile(), "camera opens on readable home view")
	var scout_id: int = client.sim._find(Skirmish.HUMAN, "bicitaxi")
	check(scout_id != -1 and client._actor_art_id(client.sim.entities[scout_id]) == "unit_bicitaxi_blue", "scout has distinct project-original artwork")
	var source: Dictionary = client.sim.expansion_sources[Skirmish.HUMAN].comida
	client.sim.visible_tiles[Skirmish.HUMAN][source.pos] = true
	client._navigate_minimap(Vector2i(84, 84))
	check(client.hud_ui.minimap.camera_tile == Vector2i(84, 84) and absf(client.board_pan.y) > 620.0, "minimap can reach distant quadrant beyond old pan clamp")
	client._navigate_minimap(source.pos)
	check(client.hud_ui.minimap.camera_tile == source.pos, "minimap centers a distant expansion")
	var source_body: Vector2 = client._tile_to_screen(source.pos) + Vector2(0, -8)
	var source_screen: Vector2 = Vector2(640, 305) + (source_body - Vector2(640, 305)) * client.board_zoom + client.board_pan + client._board_view_offset()
	var site: Dictionary = client._source_site_at(source_screen, source.pos)
	check(not site.is_empty() and site.id == "comida" and site.source.pos == source.pos, "distant site can be picked for gathering")
	root.remove_child(client)
	client.queue_free()
	await process_frame
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if not failed:
		print("Large map client checks: PASS")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
