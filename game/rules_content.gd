extends RefCounted

const DEFAULT_PATH := "res://content/skirmish.v1.json"
const UNIT_IDS := ["worker", "melee", "ranged"]
const BUILDING_IDS := ["command_post", "barracks"]
const FACTION_IDS := ["regios", "poblanos"]

static func load_default() -> Dictionary:
	var file := FileAccess.open(DEFAULT_PATH, FileAccess.READ)
	if file == null:
		return {"ok": false, "reason": "content_missing"}
	var raw := file.get_as_text()
	var parsed = JSON.parse_string(raw)
	var check := validate(parsed)
	if not check.ok:
		return check
	return {"ok": true, "data": parsed, "hash": raw.sha256_text()}

static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _bad("content_not_object")
	var d: Dictionary = value
	if not _whole(d.get("schema_version"), 1) or int(d.schema_version) != 1:
		return _bad("unsupported_content_schema")
	if not d.get("content_id") is String or d.content_id.is_empty():
		return _bad("content_id_missing")
	if not _whole(d.get("tick_ms"), 1) or int(d.tick_ms) != 100:
		return _bad("unsupported_tick_duration")
	var map_check := _map(d.get("map"))
	if not map_check.ok:
		return map_check
	for section in ["units", "buildings", "factions", "objectives", "ai"]:
		if not d.get(section) is Dictionary:
			return _bad("missing_" + section)
	for id in UNIT_IDS:
		if not d.units.get(id) is Dictionary:
			return _bad("unknown_unit_" + id)
		var u: Dictionary = d.units[id]
		for key in ["health", "cost", "train_ticks"]:
			if not _whole(u.get(key), 1 if key != "cost" else 0):
				return _bad("invalid_%s_%s" % [id, key])
		if id != "worker":
			for key in ["damage", "range", "cooldown_ticks"]:
				if not _whole(u.get(key), 1):
					return _bad("invalid_%s_%s" % [id, key])
	for id in BUILDING_IDS:
		if not d.buildings.get(id) is Dictionary:
			return _bad("unknown_building_" + id)
		var b: Dictionary = d.buildings[id]
		if not _whole(b.get("health"), 1) or not b.get("trains") is Array:
			return _bad("invalid_building_" + id)
		for role in b.trains:
			if role not in UNIT_IDS:
				return _bad("invalid_train_role_" + str(role))
		if id == "barracks" and (not _whole(b.get("cost"), 0) or not _whole(b.get("build_ticks"), 1)):
			return _bad("invalid_barracks_rules")
	for id in FACTION_IDS:
		if not d.factions.get(id) is Dictionary:
			return _bad("unknown_faction_" + id)
		for key in ["carry_limit", "combat_cost_extra", "building_health_percent"]:
			if not _whole(d.factions[id].get(key), 0):
				return _bad("invalid_%s_%s" % [id, key])
	for key in ["draw_tick", "district_hold_ticks"]:
		if not _whole(d.objectives.get(key), 1):
			return _bad("invalid_objective_" + key)
	for key in ["step_ticks", "district_tick", "attack_tick", "army_cap"]:
		if not _whole(d.ai.get(key), 1):
			return _bad("invalid_ai_" + key)
	return {"ok": true}

static func _map(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _bad("map_missing")
	var m: Dictionary = value
	if not _whole(m.get("width"), 8) or not _whole(m.get("height"), 8):
		return _bad("map_size_invalid")
	var w := int(m.width)
	var h := int(m.height)
	if w > 128 or h > 128:
		return _bad("map_size_unsupported")
	for key in ["blocked_tiles", "resource_positions", "command_posts", "workers", "barracks_positions", "district_min", "district_max", "ai_district_target"]:
		if key == "blocked_tiles":
			if not m.get(key) is Array:
				return _bad("map_" + key + "_invalid")
			for p in m[key]:
				if not _point(p, w, h):
					return _bad("map_" + key + "_invalid")
		elif key in ["district_min", "district_max", "ai_district_target"]:
			if not _point(m.get(key), w, h):
				return _bad("map_" + key + "_invalid")
		else:
			if not m.get(key) is Array or m[key].size() != 2:
				return _bad("map_" + key + "_invalid")
			for p in m[key]:
				if not _point(p, w, h):
					return _bad("map_" + key + "_invalid")
	if not _whole(m.get("resource_amount"), 1):
		return _bad("map_resource_amount_invalid")
	if int(m.district_min[0]) > int(m.district_max[0]) or int(m.district_min[1]) > int(m.district_max[1]):
		return _bad("district_bounds_invalid")
	return {"ok": true}

static func _point(p: Variant, w: int, h: int) -> bool:
	return p is Array and p.size() == 2 and _whole(p[0], 0) and _whole(p[1], 0) and int(p[0]) < w and int(p[1]) < h

static func _whole(v: Variant, minimum: int) -> bool:
	return (v is int or v is float) and float(v) == float(int(v)) and int(v) >= minimum

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
