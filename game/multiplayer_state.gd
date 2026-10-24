extends RefCounted

const Save = preload("res://skirmish_persistence.gd")

static func restore_for_side(state: Dictionary, match_id: String, side: int) -> Dictionary:
	if side not in [0, 1]:
		return {"ok": false, "reason": "invalid_slot"}
	var local_state: Dictionary = state.duplicate(true)
	if side == 1:
		var side_arrays := ["factions", "balances", "resource_sources", "age_index", "researched", "explored", "last_seen"]
		if local_state.has("expansion_sources"):
			side_arrays.append("expansion_sources")
		for key in side_arrays:
			if not local_state.get(key) is Array or local_state[key].size() != 2:
				return {"ok": false, "reason": "network_state_invalid"}
			local_state[key].reverse()
		for entity in local_state.get("entities", []):
			if not entity is Dictionary or not _whole(entity.get("side")) or int(entity.side) not in [0, 1]:
				return {"ok": false, "reason": "network_state_invalid"}
			entity.side = 1 - int(entity.side)
		if _whole(local_state.get("district_side")) and int(local_state.district_side) in [0, 1]:
			local_state.district_side = 1 - int(local_state.district_side)
		if local_state.get("district_state") == "human_hold":
			local_state.district_state = "computer_hold"
		elif local_state.get("district_state") == "computer_hold":
			local_state.district_state = "human_hold"
		if local_state.get("result") == "win":
			local_state.result = "loss"
		elif local_state.get("result") == "loss":
			local_state.result = "win"
	return Save.restore_network(local_state, match_id)

static func _whole(value: Variant) -> bool:
	return (value is int or value is float) and float(value) == float(int(value))
