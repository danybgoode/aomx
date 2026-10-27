extends RefCounted

const RulesContent = preload("res://rules_content.gd")
const PATH := "res://content/campaign.v1.json"
const MISSION_IDS := ["arrival_copilco", "foothold_narvarte", "battle_la_roma"]
const CONDITION_KINDS := ["balance_gte", "building_exists", "unit_exists", "district_progress_gte", "match_win"]

static func load_manifest() -> Dictionary:
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null:
		return _bad("campaign_missing")
	var raw := file.get_as_text()
	var parsed = JSON.parse_string(raw)
	var checked := validate(parsed)
	if not checked.ok:
		return checked
	return {"ok": true, "data": parsed, "hash": raw.sha256_text()}

static func find_mission(id: String) -> Dictionary:
	var loaded := load_manifest()
	if not loaded.ok:
		return loaded
	for mission in loaded.data.missions:
		if mission.id == id:
			return {"ok": true, "data": mission, "hash": loaded.hash}
	return _bad("mission_unknown")

static func validate(value: Variant) -> Dictionary:
	if not value is Dictionary or value.get("schema_version") != 1 or value.get("chapter_id") != "arrival-to-la-roma" or not value.get("missions") is Array:
		return _bad("campaign_schema_invalid")
	var missions: Array = value.missions
	if missions.size() != 3:
		return _bad("mission_count_invalid")
	var seen := {}
	for i in missions.size():
		var mission: Variant = missions[i]
		if not mission is Dictionary or mission.get("id") != MISSION_IDS[i] or mission.get("map_id") not in RulesContent.MAP_IDS or not mission.get("title") is String or str(mission.title).is_empty() or not mission.get("description") is String or not mission.get("tutorial") is bool or not mission.get("steps") is Array:
			return _bad("mission_invalid")
		if mission.get("prerequisite") != ("" if i == 0 else MISSION_IDS[i - 1]) or seen.has(mission.id):
			return _bad("mission_prerequisite_invalid")
		seen[mission.id] = true
		if mission.steps.is_empty() or mission.steps.size() > 5:
			return _bad("mission_steps_invalid")
		var step_ids := {}
		for step in mission.steps:
			if not step is Dictionary or not step.get("id") is String or str(step.id).is_empty() or step_ids.has(step.id) or not step.get("label") is String or str(step.label).is_empty() or step.get("kind") not in CONDITION_KINDS:
				return _bad("mission_step_invalid")
			step_ids[step.id] = true
			match step.kind:
				"balance_gte":
					if not _keys(step, ["id", "label", "kind", "resource", "amount"]) or step.resource not in RulesContent.RESOURCE_IDS or not _bounded(step.amount, 1, 1000):
						return _bad("mission_condition_invalid")
				"building_exists":
					if not _keys(step, ["id", "label", "kind", "building"]) or step.building not in RulesContent.BUILDING_IDS or step.building == "command_post":
						return _bad("mission_condition_invalid")
				"unit_exists":
					if not _keys(step, ["id", "label", "kind", "unit"]) or step.unit not in RulesContent.UNIT_IDS:
						return _bad("mission_condition_invalid")
				"district_progress_gte":
					if not _keys(step, ["id", "label", "kind", "ticks"]) or not _bounded(step.ticks, 1, 749):
						return _bad("mission_condition_invalid")
				"match_win":
					if not _keys(step, ["id", "label", "kind"]):
						return _bad("mission_condition_invalid")
		if i == 2 and (mission.tutorial or mission.steps.size() != 1 or mission.steps[0].kind != "match_win"):
			return _bad("final_mission_invalid")
		if i < 2 and (not mission.tutorial or mission.steps.any(func(step: Variant) -> bool: return step.kind == "match_win")):
			return _bad("tutorial_mission_invalid")
	return {"ok": true}

static func advance(game: RefCounted, mission: Dictionary, completed: Array) -> Array:
	var result: Array = completed.duplicate()
	while result.size() < mission.steps.size():
		var step: Dictionary = mission.steps[result.size()]
		if not _met(game, step):
			break
		result.append(step.id)
	return result

static func _met(game: RefCounted, step: Dictionary) -> bool:
	match step.kind:
		"balance_gte":
			return game.balance(0, step.resource) >= int(step.amount)
		"building_exists", "unit_exists":
			var wanted: String = step.building if step.kind == "building_exists" else step.unit
			for entity in game.entities.values():
				if entity.side == 0 and entity.kind == wanted and entity.hp > 0 and entity.complete:
					return true
			return false
		"district_progress_gte":
			return game.district_side == 0 and game.district_progress >= int(step.ticks)
		"match_win":
			return game.result == "win"
	return false

static func _keys(value: Dictionary, expected: Array) -> bool:
	if value.size() != expected.size():
		return false
	for key in expected:
		if not value.has(key):
			return false
	return true

static func _bounded(value: Variant, lo: int, hi: int) -> bool:
	return (value is int or value is float) and float(value) == float(int(value)) and int(value) >= lo and int(value) <= hi

static func _bad(reason: String) -> Dictionary:
	return {"ok": false, "reason": reason}
