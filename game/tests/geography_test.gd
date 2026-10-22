extends SceneTree

const Geography = preload("res://map_geography.gd")
const RulesContent = preload("res://rules_content.gd")
const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	var registry := Geography.load_registry()
	if not registry.ok:
		printerr("Geography load reason: ", registry.get("reason", "unknown"))
	check(registry.ok, "reviewed geography registry loads")
	if not registry.ok:
		quit(1)
		return
	var data: Dictionary = registry.data
	check(data.alcaldias.size() == 16 and data.alcaldias[13].code == "09015" and data.alcaldias[13].name_es == "Cuauhtémoc", "16 sourced alcaldía IDs include Cuauhtémoc")
	check(data.places[0].alcaldia_id == "alc_09015" and data.places[1].parent_id == "col_roma_norte", "Cibeles parent placement is explicit")
	check(data.maps[0].coordinate_transform.begins_with("none;") and data.sources.inegi_agem_2026_10_22.geometry_import == false, "no source geometry is imported")
	var copy: Dictionary = Geography.map_copy("la_roma")
	check(copy.ok and "Roma Norte" in copy.label and "stylized" in copy.description and "Cibeles" in copy.wins, "map choice explains place and play")
	check(Geography.tile_role("la_roma", Vector2i(10, 2)) == "blocked", "simulation blocker stays authoritative")
	check(Geography.tile_role("la_roma", Vector2i(9, 9)) == "decorative", "Cibeles anchor is view-only")
	check(Geography.tile_role("la_roma", Vector2i(4, 2)) == "traversable", "open tile remains traversable")
	var invalid: Dictionary = data.duplicate(true)
	invalid.places[1].parent_id = "unknown"
	check(Geography.validate(invalid).reason == "place_parent_invalid", "unknown place parent rejected")
	invalid = data.duplicate(true)
	invalid.maps[0].decorative_tiles = [[10, 2]]
	check(Geography.validate(invalid).reason == "geography_decorative_conflict", "decorative marker cannot cover a blocker")
	invalid = data.duplicate(true)
	invalid.maps[0].objective_anchor = [10, 8]
	check(Geography.validate(invalid).reason == "geography_objective_blocked", "Cibeles anchor cannot be blocked")
	var base := RulesContent.load_map("la_roma")
	check(base.ok and base.data.content_id == Skirmish.CONTENT_VERSION, "existing v5 simulation content unchanged")
	var game = Skirmish.new(Skirmish.REGIOS, {}, 41, "standard", "la_roma")
	for resource_id in Skirmish.RESOURCE_IDS:
		var distances: Array[int] = []
		for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
			var worker_tile: Vector2i = game.entities[game._find(side, "worker")].pos
			var source_tile: Vector2i = game.resource_sources[side][resource_id].pos
			distances.append(game._route_until(worker_tile, func(tile: Vector2i) -> bool: return absi(tile.x - source_tile.x) + absi(tile.y - source_tile.y) == 1).size())
		check(distances[0] > 0 and distances[1] > 0 and absi(distances[0] - distances[1]) <= 2, "both sides reach comparable " + resource_id + " opening")
	var objective_distances: Array[int] = []
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var worker_tile: Vector2i = game.entities[game._find(side, "worker")].pos
		var objective_route: Array = game._route_until(worker_tile, func(tile: Vector2i) -> bool: return tile == Vector2i(9, 9))
		check(objective_route.size() > 0, "both sides reach Cibeles")
		objective_distances.append(objective_route.size())
	check(absi(objective_distances[0] - objective_distances[1]) <= 2, "both sides have comparable Cibeles access")
	var payload := Save.capture(game, "solo_0123456789abcdef0123456789abcdef")
	check(Save.restore(payload).ok and Replay.verify(Replay.record(game)).ok, "v5 save and replay still reproduce")
	if not failed:
		print("Geography checks passed: 16 references, safe authored map roles, fair access and v5 compatibility")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
