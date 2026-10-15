extends RefCounted

const WIDTH := 20
const HEIGHT := 20
const RESOURCE := Vector2i(6, 4)
const DROPOFF := Vector2i(2, 2)
const CARRY_LIMIT := 4
const BUILD_COST := 6
const BUILD_TICKS := 6
const GAME_VERSION := "godot-4.7.2-prototype-1"
const CONTENT_VERSION := "original-map-1"

var worker := Vector2i(3, 2)
var resource_amount := 20
var carrying := 0
var stockpile := 0
var building_position := Vector2i(-1, -1)
var building_progress := 0
var building_complete := false
var path: Array[Vector2i] = []
var job := "idle"
var tick_number := 0
var feedback := "Select the worker, then right-click to move or gather."
var command_log: Array[Dictionary] = []
var _next_command := 1

func issue(kind: String, target: Vector2i = Vector2i(-1, -1)) -> Dictionary:
	var result: Dictionary = {"ok": false, "reason": "unknown_command"}
	match kind:
		"move":
			if not _walkable(target):
				result.reason = "blocked_or_invalid_tile"
			else:
				var route := _route(worker, target)
				if route.is_empty() and worker != target:
					result.reason = "unreachable_tile"
				else:
					path = route
					job = "move" if not path.is_empty() else "idle"
					result = {"ok": true, "reason": "moving"}
		"gather":
			if target != RESOURCE or resource_amount <= 0:
				result.reason = "resource_empty_or_missing"
			else:
				var route := _route_to_adjacent(worker, RESOURCE)
				if route.is_empty() and not _adjacent(worker, RESOURCE):
					result.reason = "resource_unreachable"
				else:
					path = route
					job = "gather"
					result = {"ok": true, "reason": "gathering"}
		"build":
			result = _place_building(target)
	if result.ok:
		command_log.append({"run_id": "prototype-fixture", "command_id": "command_%04d" % _next_command,
			"sequence": _next_command, "issued_tick": tick_number, "kind": kind, "target": [target.x, target.y],
			"game_version": GAME_VERSION, "content_version": CONTENT_VERSION, "test_account": true})
		_next_command += 1
	feedback = result.reason.replace("_", " ")
	return result

func tick() -> void:
	tick_number += 1
	if not path.is_empty():
		worker = path.pop_front()
		return
	match job:
		"gather":
			if not _adjacent(worker, RESOURCE):
				job = "idle"
				feedback = "resource unreachable"
			elif resource_amount > 0 and carrying < CARRY_LIMIT:
				resource_amount -= 1
				carrying += 1
			elif carrying > 0:
				path = _route(worker, DROPOFF)
				job = "deliver"
			else:
				job = "idle"
				feedback = "resource depleted"
		"deliver":
			if worker == DROPOFF:
				stockpile += carrying
				carrying = 0
				if resource_amount > 0:
					path = _route_to_adjacent(worker, RESOURCE)
					job = "gather"
				else:
					job = "idle"
					feedback = "resource depleted"
		"build":
			if _adjacent_to_footprint(worker, building_position):
				building_progress += 1
				if building_progress >= BUILD_TICKS:
					building_complete = true
					job = "idle"
					feedback = "structure complete"
		"move":
			job = "idle"

func snapshot() -> Dictionary:
	return {"tick": tick_number, "worker": [worker.x, worker.y], "source": resource_amount,
		"carrying": carrying, "stockpile": stockpile, "building": [building_position.x, building_position.y],
		"building_progress": building_progress, "building_complete": building_complete, "job": job}

func _place_building(at: Vector2i) -> Dictionary:
	if building_position.x >= 0:
		return {"ok": false, "reason": "only_one_structure"}
	if stockpile < BUILD_COST:
		return {"ok": false, "reason": "insufficient_stockpile"}
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		if not _in_bounds(tile) or _wall(tile) or tile == RESOURCE or tile == DROPOFF or tile == worker:
			return {"ok": false, "reason": "blocked_footprint"}
	building_position = at
	var route := _route_to_footprint(worker, at)
	building_position = Vector2i(-1, -1)
	if route.is_empty() and not _adjacent_to_footprint(worker, at):
		return {"ok": false, "reason": "building_unreachable"}
	stockpile -= BUILD_COST
	building_position = at
	building_progress = 0
	building_complete = false
	path = route
	job = "build"
	return {"ok": true, "reason": "construction_started"}

func _in_bounds(tile: Vector2i) -> bool:
	return tile.x >= 0 and tile.y >= 0 and tile.x < WIDTH and tile.y < HEIGHT

func _wall(tile: Vector2i) -> bool:
	return (tile.x == 10 and tile.y != 10) or tile in [Vector2i(14, 15), Vector2i(16, 15), Vector2i(15, 14), Vector2i(15, 16)]

func _walkable(tile: Vector2i) -> bool:
	if not _in_bounds(tile) or _wall(tile) or tile == RESOURCE:
		return false
	if building_position.x >= 0 and tile.x >= building_position.x and tile.x < building_position.x + 2 and tile.y >= building_position.y and tile.y < building_position.y + 2:
		return false
	return true

func _adjacent(a: Vector2i, b: Vector2i) -> bool:
	return absi(a.x - b.x) + absi(a.y - b.y) == 1

func _adjacent_to_footprint(tile: Vector2i, at: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		if _adjacent(tile, at + offset):
			return true
	return false

func _route_to_adjacent(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var found := false
	for offset in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
		var candidate: Vector2i = target + offset
		if _walkable(candidate):
			var route := _route(from, candidate)
			if (not route.is_empty() or from == candidate) and (not found or route.size() < best.size()):
				best = route
				found = true
	return best

func _route_to_footprint(from: Vector2i, at: Vector2i) -> Array[Vector2i]:
	var best: Array[Vector2i] = []
	var found := false
	for tile in [at + Vector2i.LEFT, at + Vector2i.UP, at + Vector2i(2, 0), at + Vector2i(0, 2),
		at + Vector2i(1, -1), at + Vector2i(2, 1), at + Vector2i(1, 2), at + Vector2i(-1, 1)]:
		if _walkable(tile):
			var route := _route(from, tile)
			if (not route.is_empty() or from == tile) and (not found or route.size() < best.size()):
				best = route
				found = true
	return best

func _route(from: Vector2i, target: Vector2i) -> Array[Vector2i]:
	var empty: Array[Vector2i] = []
	if from == target:
		return empty
	if not _walkable(target):
		return empty
	var queue: Array[Vector2i] = [from]
	var parent: Dictionary = {from: from}
	var index := 0
	while index < queue.size():
		var tile: Vector2i = queue[index]
		index += 1
		for step in [Vector2i.LEFT, Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN]:
			var next: Vector2i = tile + step
			if _walkable(next) and not parent.has(next):
				parent[next] = tile
				queue.append(next)
				if next == target:
					var route: Array[Vector2i] = []
					var cursor := target
					while cursor != from:
						route.push_front(cursor)
						cursor = parent[cursor]
					return route
	return empty
