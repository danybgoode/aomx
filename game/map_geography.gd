extends RefCounted

const PATH := "res://content/geography/cdmx.v1.json"
const RulesContent = preload("res://rules_content.gd")

static func load_registry() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return _bad("geography_missing")
	var parsed = JSON.parse_string(file.get_as_text())
	var checked := validate(parsed)
	if not checked.ok:
		return checked
	return {"ok": true, "data": parsed}

static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("schema_version") != 1:
		return _bad("geography_schema_invalid")
	for key in ["sources", "alcaldias", "places", "territories", "maps", "strings"]:
		if not value.has(key):
			return _bad("geography_" + key + "_missing")
	if not value.sources is Dictionary or not value.alcaldias is Array or not value.places is Array or not value.territories is Array or not value.maps is Array or not value.strings is Dictionary:
		return _bad("geography_shape_invalid")
	for source_id in value.sources:
		var source = value.sources[source_id]
		if not source is Dictionary or not source.get("url") is String or not str(source.url).begins_with("https://") or not source.get("publisher") is String or str(source.publisher).is_empty() or not source.get("retrieved_utc") is String or not source.get("license_review") is String or source.get("geometry_import") != false:
			return _bad("geography_source_invalid")
	var alcaldia_ids := {}
	var codes := {}
	if value.alcaldias.size() != 16:
		return _bad("alcaldia_count_invalid")
	for item in value.alcaldias:
		if not item is Dictionary or not item.get("id") is String or not item.get("code") is String or not item.get("name_es") is String or str(item.name_es).is_empty() or not value.sources.has(item.get("source_id")):
			return _bad("alcaldia_invalid")
		if item.id != "alc_" + item.code or not item.code.begins_with("09") or item.code.length() != 5 or alcaldia_ids.has(item.id) or codes.has(item.code):
			return _bad("alcaldia_id_invalid")
		alcaldia_ids[item.id] = true
		codes[item.code] = true
	for code in range(2, 18):
		if not codes.has("09%03d" % code):
			return _bad("alcaldia_code_missing")
	var place_ids := {}
	for place in value.places:
		if not place is Dictionary or not place.get("id") is String or not place.get("name_es") is String or str(place.name_es).is_empty() or not value.sources.has(place.get("source_id")) or place_ids.has(place.id):
			return _bad("place_invalid")
		if place.get("kind") == "colonia":
			if not alcaldia_ids.has(place.get("alcaldia_id")):
				return _bad("place_alcaldia_invalid")
		elif place.get("kind") == "landmark":
			if not place_ids.has(place.get("parent_id")):
				return _bad("place_parent_invalid")
		else:
			return _bad("place_kind_invalid")
		place_ids[place.id] = true
	var territory_ids := {}
	for territory in value.territories:
		if not territory is Dictionary or territory.get("kind") != "fictional_playable" or not place_ids.has(territory.get("inspired_by")) or not territory.get("id") is String or territory_ids.has(territory.id):
			return _bad("territory_invalid")
		territory_ids[territory.id] = true
	if value.maps.size() != 1:
		return _bad("geography_map_count_invalid")
	var map_record = value.maps[0]
	if not map_record is Dictionary or map_record.get("map_id") != "la_roma" or not territory_ids.has(map_record.get("territory_id")) or not map_record.get("place_ids") is Array or not map_record.get("decorative_tiles") is Array:
		return _bad("geography_map_invalid")
	for place_id in map_record.place_ids:
		if not place_ids.has(place_id):
			return _bad("geography_map_place_invalid")
	if not place_ids.has(map_record.get("objective_place_id")) or not map_record.place_ids.has(map_record.objective_place_id):
		return _bad("geography_objective_place_invalid")
	var loaded := RulesContent.load_map("la_roma")
	if not loaded.ok:
		return _bad("geography_base_map_invalid")
	var map_data: Dictionary = loaded.data.map
	var width := int(map_data.width)
	var height := int(map_data.height)
	if not _point(map_record.get("objective_anchor"), width, height):
		return _bad("geography_objective_anchor_invalid")
	var anchor: Array = map_record.objective_anchor
	if int(anchor[0]) < int(map_data.district_min[0]) or int(anchor[0]) > int(map_data.district_max[0]) or int(anchor[1]) < int(map_data.district_min[1]) or int(anchor[1]) > int(map_data.district_max[1]):
		return _bad("geography_objective_outside_district")
	var impassable := {}
	for tile in map_data.blocked_tiles + map_data.cliff_tiles:
		impassable[Vector2i(int(tile[0]), int(tile[1]))] = true
	if impassable.has(Vector2i(int(anchor[0]), int(anchor[1]))):
		return _bad("geography_objective_blocked")
	var decorative := {}
	for point in map_record.decorative_tiles:
		if not _point(point, width, height):
			return _bad("geography_decorative_invalid")
		var tile := Vector2i(int(point[0]), int(point[1]))
		if impassable.has(tile) or decorative.has(tile):
			return _bad("geography_decorative_conflict")
		decorative[tile] = true
	if not map_record.get("tile_roles") is Dictionary or not map_record.tile_roles.has("blocked") or not map_record.tile_roles.has("decorative") or not map_record.tile_roles.has("traversable") or not map_record.get("coordinate_transform") is String:
		return _bad("geography_tile_roles_invalid")
	for locale in ["en", "es"]:
		if not value.strings.has(locale) or not value.strings[locale] is Dictionary:
			return _bad("geography_locale_missing")
		for field in ["label_key", "description_key", "wins_key"]:
			if not map_record.get(field) is String or not value.strings[locale].get(map_record[field]) is String or str(value.strings[locale][map_record[field]]).is_empty():
				return _bad("geography_label_missing")
	return {"ok": true}

static func map_copy(map_id: String, locale: String = "en") -> Dictionary:
	if map_id != "la_roma":
		return _bad("geography_map_unknown")
	var loaded := load_registry()
	if not loaded.ok:
		return loaded
	var data: Dictionary = loaded.data
	var record: Dictionary = data.maps[0]
	var labels: Dictionary = data.strings.get(locale, data.strings.en)
	return {"ok": true, "label": labels[record.label_key], "description": labels[record.description_key], "wins": labels[record.wins_key]}

static func tile_role(map_id: String, point: Vector2i) -> String:
	if map_id != "la_roma":
		return "unknown"
	var loaded := load_registry()
	if not loaded.ok:
		return "unknown"
	var map_data: Dictionary = RulesContent.load_map(map_id).data.map
	if point.x < 0 or point.y < 0 or point.x >= int(map_data.width) or point.y >= int(map_data.height):
		return "unknown"
	for tile in map_data.blocked_tiles + map_data.cliff_tiles:
		if point == Vector2i(int(tile[0]), int(tile[1])):
			return "blocked"
	for tile in loaded.data.maps[0].decorative_tiles:
		if point == Vector2i(int(tile[0]), int(tile[1])):
			return "decorative"
	return "traversable"

static func _point(value: Variant, width: int, height: int) -> bool:
	return value is Array and value.size() == 2 and _whole(value[0]) and _whole(value[1]) and int(value[0]) >= 0 and int(value[1]) >= 0 and int(value[0]) < width and int(value[1]) < height

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
