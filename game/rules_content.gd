extends RefCounted

const DEFAULT_PATH := "res://content/skirmish.v1.json"
const RESOURCE_IDS := ["comida", "materiales", "varos", "terrenos"]
const UNIT_IDS := ["worker", "melee", "ranged", "armored", "siege"]
const SCOUT_ID := "bicitaxi"
const BUILDING_IDS := ["command_post", "barracks", "depot", "housing", "registry"]
const FACTION_IDS := ["regios", "poblanos", "oaxaquenos", "veracruzanos"]
const MAP_IDS := ["la_roma", "narvarte", "copilco", "la_roma_large"]
const AGE_IDS := ["foranea", "universitaria", "godin", "gentrificacion"]
const TECH_IDS := ["carry_capacity_i", "construction_rate_i", "combat_training_i", "cooperative_build_i", "street_exchange_i"]
const EFFECT_IDS := ["carry_capacity", "construction_rate", "combat_training", "trade_bonus"]
const AI_LEVELS := ["learner", "standard", "challenger"]

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

static func load_map(map_id: String) -> Dictionary:
	if map_id not in MAP_IDS:
		return _bad("unknown_map_id")
	var base := load_default()
	if not base.ok or map_id == "la_roma":
		return base
	var path := "res://content/maps/%s.json" % map_id
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _bad("map_content_missing")
	var overlay = JSON.parse_string(file.get_as_text())
	if not overlay is Dictionary or overlay.get("id") != map_id or not overlay.get("sources") is Dictionary:
		return _bad("map_content_invalid")
	var data: Dictionary = base.data.duplicate(true)
	data.map_id = map_id
	data.map = overlay.get("map")
	if map_id == "la_roma_large":
		if not overlay.get("expansion_sources") is Dictionary or not overlay.get("units") is Dictionary or not overlay.units.get(SCOUT_ID) is Dictionary:
			return _bad("large_map_content_invalid")
		data.units[SCOUT_ID] = overlay.units[SCOUT_ID]
	for resource_id in RESOURCE_IDS:
		if not overlay.sources.get(resource_id) is Array:
			return _bad("map_sources_invalid")
		data.resources[resource_id].source_positions = overlay.sources[resource_id]
		if map_id == "la_roma_large":
			data.resources[resource_id].expansion_positions = overlay.expansion_sources.get(resource_id)
	var check := validate(data)
	if not check.ok:
		return check
	return {"ok": true, "data": data, "hash": JSON.stringify(data).sha256_text()}

static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary:
		return _bad("content_not_object")
	var d: Dictionary = value
	if not _whole(d.get("schema_version"), 1) or int(d.schema_version) != 3:
		return _bad("unsupported_content_schema")
	if not d.get("content_id") is String or d.content_id.is_empty():
		return _bad("content_id_missing")
	if d.get("map_id") not in MAP_IDS:
		return _bad("map_id_invalid")
	if not _whole(d.get("tick_ms"), 1) or int(d.tick_ms) != 100:
		return _bad("unsupported_tick_duration")
	var map_check := _map(d.get("map"))
	if not map_check.ok:
		return map_check
	for section in ["resources", "units", "buildings", "factions", "objectives", "ai", "population", "ages", "techs"]:
		if not d.get(section) is Dictionary:
			return _bad("missing_" + section)
	if not _known_keys(d.resources, RESOURCE_IDS):
		return _bad("resource_ids_invalid")
	for id in RESOURCE_IDS:
		var source: Dictionary = d.resources[id]
		if not source.get("source_positions") is Array or source.source_positions.size() != 2:
			return _bad("invalid_%s_positions" % id)
		for point in source.source_positions:
			if not _point(point, int(d.map.width), int(d.map.height)):
				return _bad("invalid_%s_positions" % id)
			if not map_check.reachable.has(Vector2i(int(point[0]), int(point[1]))):
				return _bad("inaccessible_%s_source" % id)
		if d.map_id == "la_roma_large":
			if not source.get("expansion_positions") is Array or source.expansion_positions.size() != 2:
				return _bad("invalid_%s_expansion_positions" % id)
			for point in source.expansion_positions:
				if not _point(point, int(d.map.width), int(d.map.height)) or not map_check.reachable.has(Vector2i(int(point[0]), int(point[1]))):
					return _bad("invalid_%s_expansion_positions" % id)
		for key in ["amount", "refresh_amount", "refresh_ticks", "refresh_count"]:
			if not _whole(source.get(key), 1):
				return _bad("invalid_%s_%s" % [id, key])
	var source_tiles := {}
	for resource_id in RESOURCE_IDS:
		for point in d.resources[resource_id].source_positions:
			var tile := Vector2i(int(point[0]), int(point[1]))
			if source_tiles.has(tile):
				return _bad("source_positions_overlap")
			source_tiles[tile] = true
		for point in d.resources[resource_id].get("expansion_positions", []):
			var tile := Vector2i(int(point[0]), int(point[1]))
			if source_tiles.has(tile):
				return _bad("source_positions_overlap")
			source_tiles[tile] = true
	var occupied_anchors := {}
	for point in d.map.command_posts + d.map.barracks_positions:
		var at := Vector2i(int(point[0]), int(point[1]))
		for dx in 2:
			for dy in 2:
				var tile := at + Vector2i(dx, dy)
				if tile.x >= int(d.map.width) or tile.y >= int(d.map.height) or not map_check.reachable.has(tile) or source_tiles.has(tile) or occupied_anchors.has(tile):
					return _bad("map_building_footprint_invalid")
				occupied_anchors[tile] = true
	if d.map_id == "la_roma_large":
		if not d.map.get("scouts") is Array or d.map.scouts.size() != 2:
			return _bad("map_scouts_invalid")
		for point in d.map.scouts:
			if not _point(point, int(d.map.width), int(d.map.height)):
				return _bad("map_scouts_invalid")
			var tile := Vector2i(int(point[0]), int(point[1]))
			if not map_check.reachable.has(tile) or source_tiles.has(tile) or occupied_anchors.has(tile):
				return _bad("map_scouts_invalid")
	if not _known_keys(d.units, UNIT_IDS + ([SCOUT_ID] if d.map_id == "la_roma_large" else [])):
		return _bad("unit_ids_invalid")
	for id in d.units:
		var u: Dictionary = d.units[id]
		if not _whole(u.get("armor"), 0) or u.get("attack_class") not in ["none", "blunt", "piercing", "siege"] or not u.get("bonuses") is Dictionary or not _whole(u.get("projectile_ticks"), 0):
			return _bad("invalid_%s_combat" % id)
		for bonus in u.bonuses:
			if bonus not in UNIT_IDS and bonus != "structure" or not _whole(u.bonuses[bonus], 1):
				return _bad("invalid_%s_bonus" % id)
		for key in ["health", "cost", "train_ticks"]:
			if not _whole(u.get(key), 1 if key != "cost" else 0):
				return _bad("invalid_%s_%s" % [id, key])
		if not _costs(u.get("costs")) or int(u.costs.varos) != int(u.cost):
			return _bad("invalid_%s_costs" % id)
		if u.get("min_age") not in AGE_IDS:
			return _bad("invalid_%s_min_age" % id)
		if id == SCOUT_ID and (not _whole(u.get("sight"), 6) or not _whole(u.get("move_ticks"), 1)):
			return _bad("invalid_scout_mobility")
		if id not in ["worker", SCOUT_ID]:
			for key in ["damage", "range", "cooldown_ticks"]:
				if not _whole(u.get(key), 1):
					return _bad("invalid_%s_%s" % [id, key])
	if not _known_keys(d.buildings, BUILDING_IDS):
		return _bad("building_ids_invalid")
	for id in BUILDING_IDS:
		var b: Dictionary = d.buildings[id]
		if not _whole(b.get("armor"), 0):
			return _bad("invalid_%s_armor" % id)
		if not _whole(b.get("health"), 1) or not b.get("trains") is Array:
			return _bad("invalid_building_" + id)
		for role in b.trains:
			if role not in UNIT_IDS:
				return _bad("invalid_train_role_" + str(role))
		if not _whole(b.get("cost"), 0) or not _whole(b.get("build_ticks"), 1):
			return _bad("invalid_%s_rules" % id)
		if not _costs(b.get("costs")) or int(b.costs.varos) != int(b.cost):
			return _bad("invalid_%s_costs" % id)
		if b.get("min_age") not in AGE_IDS or not _whole(b.get("population_bonus"), 0):
			return _bad("invalid_%s_progression" % id)
	if not _known_keys(d.factions, FACTION_IDS):
		return _bad("faction_ids_invalid")
	for id in FACTION_IDS:
		for key in ["carry_limit", "combat_cost_extra", "building_health_percent", "gather_ticks", "move_ticks"]:
			if not _whole(d.factions[id].get(key), 0):
				return _bad("invalid_%s_%s" % [id, key])
		if int(d.factions[id].gather_ticks) < 1 or int(d.factions[id].move_ticks) < 1:
			return _bad("invalid_%s_interval" % id)
	for key in ["base_cap", "max_cap", "housing_bonus"]:
		if not _whole(d.population.get(key), 1):
			return _bad("invalid_population_%s" % key)
	if int(d.population.max_cap) < int(d.population.base_cap) or int(d.buildings.housing.population_bonus) != int(d.population.housing_bonus):
		return _bad("invalid_population_cap")
	for key in ["draw_tick", "district_hold_ticks"]:
		if not _whole(d.objectives.get(key), 1):
			return _bad("invalid_objective_" + key)
	for key in ["step_ticks", "district_tick", "attack_tick", "army_cap"]:
		if not _whole(d.ai.get(key), 1):
			return _bad("invalid_ai_" + key)
	if not _known_keys(d.ai.get("levels"), AI_LEVELS):
		return _bad("invalid_ai_levels")
	for level in AI_LEVELS:
		var profile: Dictionary = d.ai.levels[level]
		for key in ["step_ticks", "scout_tick", "district_tick", "attack_tick", "army_cap", "workers", "memory_ticks"]:
			if not _whole(profile.get(key), 1):
				return _bad("invalid_ai_%s_%s" % [level, key])
		if not profile.get("counter") is bool or int(profile.scout_tick) > int(profile.district_tick) or int(profile.district_tick) > int(profile.attack_tick):
			return _bad("invalid_ai_" + level)
	if not d.ages.get("order") is Array or d.ages.order != AGE_IDS or not d.ages.get("transitions") is Dictionary:
		return _bad("age_order_invalid")
	if not _known_keys(d.ages.transitions, AGE_IDS.slice(1)):
		return _bad("age_transition_ids_invalid")
	if not _known_keys(d.techs, TECH_IDS):
		return _bad("tech_ids_invalid")
	for id in TECH_IDS:
		var tech: Dictionary = d.techs[id]
		if tech.get("age") not in AGE_IDS or not _costs(tech.get("costs")) or not _whole(tech.get("duration_ticks"), 1):
			return _bad("invalid_%s_rules" % id)
		if tech.get("requires_faction", "") != "" and tech.get("requires_faction") not in FACTION_IDS:
			return _bad("invalid_%s_faction" % id)
		if not _references(tech.get("requires_techs"), TECH_IDS):
			return _bad("invalid_%s_prerequisites" % id)
		for prerequisite in tech.requires_techs:
			if AGE_IDS.find(d.techs[prerequisite].get("age")) > AGE_IDS.find(tech.age):
				return _bad("invalid_%s_prerequisite_age" % id)
		if not tech.get("effect") is Dictionary or tech.effect.get("kind") not in EFFECT_IDS or not _whole(tech.effect.get("amount"), 1):
			return _bad("invalid_%s_effect" % id)
	var visiting := {}
	var visited := {}
	for id in TECH_IDS:
		if _tech_cycle(id, d.techs, visiting, visited):
			return _bad("tech_cycle")
	for index in range(1, AGE_IDS.size()):
		var id: String = AGE_IDS[index]
		var transition: Dictionary = d.ages.transitions[id]
		if not _costs(transition.get("costs")) or not _whole(transition.get("duration_ticks"), 1):
			return _bad("invalid_%s_transition" % id)
		if not _references(transition.get("requires_buildings"), BUILDING_IDS) or not _references(transition.get("requires_techs"), TECH_IDS):
			return _bad("invalid_%s_prerequisites" % id)
		for building in transition.requires_buildings:
			if AGE_IDS.find(d.buildings[building].min_age) >= index:
				return _bad("invalid_%s_prerequisite_age" % id)
		for tech_id in transition.requires_techs:
			if AGE_IDS.find(d.techs[tech_id].age) >= index:
				return _bad("invalid_%s_prerequisite_age" % id)
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
	var blocked_lookup := {}
	for p in m.blocked_tiles:
		blocked_lookup[Vector2i(int(p[0]), int(p[1]))] = true
	var terrain_lookup := blocked_lookup.duplicate()
	for key in ["elevated_tiles", "cliff_tiles"]:
		if not m.get(key) is Array:
			return _bad("map_" + key + "_invalid")
		for p in m[key]:
			if not _point(p, w, h):
				return _bad("map_" + key + "_invalid")
			var terrain_tile := Vector2i(int(p[0]), int(p[1]))
			if terrain_lookup.has(terrain_tile):
				return _bad("map_" + key + "_invalid")
			terrain_lookup[terrain_tile] = true
	var impassable := {}
	for p in m.blocked_tiles + m.cliff_tiles:
		impassable[Vector2i(int(p[0]), int(p[1]))] = true
	var open_district_tiles := 0
	for x in range(int(m.district_min[0]), int(m.district_max[0]) + 1):
		for y in range(int(m.district_min[1]), int(m.district_max[1]) + 1):
			if not impassable.has(Vector2i(x, y)):
				open_district_tiles += 1
	if open_district_tiles < 2:
		return _bad("district_blocked")
	var start := Vector2i(int(m.workers[0][0]), int(m.workers[0][1]))
	var finish := Vector2i(int(m.workers[1][0]), int(m.workers[1][1]))
	var frontier: Array[Vector2i] = [start]
	var reached := {start: true}
	var cursor := 0
	while cursor < frontier.size():
		var tile := frontier[cursor]
		cursor += 1
		for step in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if next.x >= 0 and next.y >= 0 and next.x < w and next.y < h and not impassable.has(next) and not reached.has(next):
				reached[next] = true
				frontier.append(next)
	if not reached.has(finish) or not reached.has(Vector2i(int(m.ai_district_target[0]), int(m.ai_district_target[1]))):
		return _bad("critical_route_disconnected")
	for key in ["workers", "command_posts", "barracks_positions", "resource_positions"]:
		for p in m[key]:
			if not reached.has(Vector2i(int(p[0]), int(p[1]))):
				return _bad("critical_route_disconnected")
	return {"ok": true, "reachable": reached}

static func _known_keys(value: Variant, ids: Array) -> bool:
	if not value is Dictionary or value.size() != ids.size():
		return false
	for id in ids:
		if not value.get(id) is Dictionary:
			return false
	return true

static func _costs(value: Variant) -> bool:
	if not value is Dictionary or value.size() != RESOURCE_IDS.size():
		return false
	for id in RESOURCE_IDS:
		if not _whole(value.get(id), 0):
			return false
	return true

static func _references(value: Variant, ids: Array) -> bool:
	if not value is Array:
		return false
	var seen := {}
	for id in value:
		if id not in ids or seen.has(id):
			return false
		seen[id] = true
	return true

static func _tech_cycle(id: String, techs: Dictionary, visiting: Dictionary, visited: Dictionary) -> bool:
	if visiting.has(id):
		return true
	if visited.has(id):
		return false
	visiting[id] = true
	for dependency in techs[id].requires_techs:
		if _tech_cycle(dependency, techs, visiting, visited):
			return true
	visiting.erase(id)
	visited[id] = true
	return false

static func _point(p: Variant, w: int, h: int) -> bool:
	return p is Array and p.size() == 2 and _whole(p[0], 0) and _whole(p[1], 0) and int(p[0]) < w and int(p[1]) < h

static func _whole(v: Variant, minimum: int) -> bool:
	return (v is int or v is float) and float(v) == float(int(v)) and int(v) >= minimum

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
