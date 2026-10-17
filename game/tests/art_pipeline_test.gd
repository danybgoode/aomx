extends SceneTree

const ArtCatalog = preload("res://art_catalog.gd")
const Pilot = preload("res://art_pilot.tscn")
var failed := false

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var catalog = ArtCatalog.new()
	catalog.load_manifest(true)
	var match_catalog = ArtCatalog.new()
	match_catalog.load_manifest()
	check(match_catalog.textures.has("prop_owned_flowers") and not match_catalog.textures.has("critter_boar_se_idle_0"), "match loads only approved owned art")
	for id in ["terrain_owned_000", "terrain_owned_022", "prop_owned_flowers", "building_concept_command_post_blue"]:
		check(catalog.texture(id) != null, "candidate texture loads: " + id)
	check(catalog.texture("terrain_owned_022").get_size() == Vector2(48, 48), "raised tile export has 48x24 top projection")
	check(catalog.pivot("terrain_owned_022") == Vector2(24, 12), "tile ground contact matches current projection")
	check(catalog.texture("building_concept_command_post_blue").get_size() == Vector2(96, 85), "concept derivative uses 2x2 width")
	var pilot = Pilot.instantiate()
	root.add_child(pilot)
	for direction in ["se", "sw", "nw", "ne"]:
		for frame in range(7):
			var id: String = "critter_boar_%s_idle_%d" % [direction, frame]
			check(catalog.texture(id).get_size() == Vector2(46, 32), "boar frame geometry: " + id)
			check(catalog.pivot(id) == Vector2(23, 29), "boar feet anchor: " + id)
	check(pilot.frame_id() == "critter_boar_se_idle_0", "pilot starts with idle frame")
	pilot.direction_index = 1
	pilot.elapsed = 1.0 / 7.0
	check(pilot.frame_id() == "critter_boar_sw_idle_1", "pilot changes direction and frame without simulation")
	pilot.queue_free()
	print("Art pipeline: ", "FAIL" if failed else "PASS")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed = true
		push_error(label)
