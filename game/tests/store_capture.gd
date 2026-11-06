extends SceneTree
## Renders real in-game scenes for the itch.io page and other store art.
##   STORE_SCENE=battle|economy|wonder|large STORE_CAPTURE=/abs/out.png [AOMX_LOCALE=es|en]
## Scenes are staged with the normal rules and art; nothing is painted over. Run windowed
## (not --headless) so the board renders: godot --path game --script res://tests/store_capture.gd

const Scene = preload("res://skirmish_main.tscn")
const Outbox = preload("res://funnel_outbox.gd")
const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	call_deferred("_capture")

func _capture() -> void:
	var scene := OS.get_environment("STORE_SCENE")
	var path := OS.get_environment("STORE_CAPTURE")
	if path.is_empty() or scene not in ["battle", "economy", "wonder", "large"]:
		printerr("Set STORE_SCENE (battle, economy, wonder, large) and STORE_CAPTURE")
		quit(1)
		return
	root.size = Vector2i(1280, 800)
	get_root().get_tree().create_timer(60.0).timeout.connect(func() -> void:
		printerr("store capture timed out")
		quit(1))
	var client = Scene.instantiate()
	client.outbox = Outbox.new("user://store-capture-%d.json" % Time.get_ticks_usec())
	root.add_child(client)
	if scene == "large":
		client._choose_map(Skirmish.MAP_IDS.find("la_roma_large"))
	if scene == "wonder":
		client.wonder_flag = {"enabled": true, "served": true, "flag_version": 1, "exposure_proof": "a".repeat(64)}
		client._refresh_wonder_setup()
		client._choose_objective(2)
	client._choose_faction(Skirmish.REGIOS if scene != "economy" else Skirmish.POBLANOS)
	client.sim.ai_enabled = false
	client._set_reduced_effects(false)
	var sim = client.sim
	match scene:
		"battle":
			_buildings(sim, Skirmish.HUMAN, ["barracks", "housing", "housing", "depot"], Vector2i(4, 14))
			_buildings(sim, Skirmish.COMPUTER, ["barracks", "housing"], Vector2i(18, 5))
			var ours := _squad(sim, Skirmish.HUMAN, ["melee", "melee", "ranged", "armored", "melee", "ranged", "siege", "melee"], Vector2i(8, 10))
			var theirs := _squad(sim, Skirmish.COMPUTER, ["melee", "ranged", "melee", "armored", "ranged", "melee", "melee"], Vector2i(12, 9))
			_engage(sim, ours, theirs)
			for i in 14:
				sim.tick()
			sim.district_state = "human_hold"
			sim.district_progress = 410
			_select(client, ours)
		"economy":
			_buildings(sim, Skirmish.HUMAN, ["depot", "housing", "registry", "barracks"], Vector2i(4, 13))
			var workers := _squad(sim, Skirmish.HUMAN, ["worker", "worker", "worker", "worker", "worker"], Vector2i(7, 8))
			var sources: Dictionary = sim.resource_sources[Skirmish.HUMAN]
			var ids: Array = sources.keys()
			for i in workers.size():
				sim.issue(Skirmish.HUMAN, "gather", workers[i], sources[ids[i % ids.size()]].pos)
			for i in 90:
				sim.tick()
			for id in Skirmish.RESOURCE_IDS:
				sim._add_balance(Skirmish.HUMAN, id, 40 + id.length() * 7)
			_select(client, [workers[0]])
		"wonder":
			_buildings(sim, Skirmish.HUMAN, ["housing", "registry", "barracks"], Vector2i(4, 14))
			var wonder: int = sim._add_entity(Skirmish.HUMAN, "wonder", Vector2i(5, 8))
			var enemy_wonder: int = sim._add_entity(Skirmish.COMPUTER, "wonder", Vector2i(16, 9))
			sim.entities[enemy_wonder].complete = true
			sim.wonder_progress[Skirmish.HUMAN] = 520
			sim.wonder_progress[Skirmish.COMPUTER] = 340
			sim.age_index[Skirmish.HUMAN] = 2
			_squad(sim, Skirmish.HUMAN, ["melee", "ranged", "melee", "armored"], Vector2i(7, 7))
			_select(client, [wonder])
		"large":
			_buildings(sim, Skirmish.HUMAN, ["barracks", "housing", "housing", "depot", "registry"], Vector2i(20, 30))
			var ours := _squad(sim, Skirmish.HUMAN, ["melee", "ranged", "melee", "armored", "melee", "ranged", "siege", "melee", "ranged", "melee"], Vector2i(30, 30))
			var theirs := _squad(sim, Skirmish.COMPUTER, ["melee", "ranged", "melee", "armored", "melee", "ranged", "melee", "melee"], Vector2i(35, 29))
			_engage(sim, ours, theirs)
			for i in 10:
				sim.tick()
			_select(client, ours)
	sim._refresh_visibility()
	client._update_hud()
	client.paused = true
	client.board_zoom = 1.25
	var focus: Vector2i = {"battle": Vector2i(10, 10), "economy": Vector2i(8, 9), "wonder": Vector2i(8, 9), "large": Vector2i(32, 30)}[scene]
	# Edge panning follows the mouse; the store shots must not drift with it.
	client.set_process(false)
	await process_frame
	client._navigate_minimap(focus)
	for i in 10:
		client.queue_redraw()
		await process_frame
	var error := root.get_texture().get_image().save_png(path)
	print("STORE_CAPTURE %s %s error=%d" % [scene, path, error])
	quit(0 if error == OK else 1)

## Places completed buildings on the first clear 2×2 sites found near an anchor.
func _buildings(sim, side: int, kinds: Array, anchor: Vector2i) -> void:
	var placed := 0
	for radius in range(0, 10):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if placed >= kinds.size():
					return
				var at: Vector2i = anchor + Vector2i(dx, dy) * 3
				if _clear(sim, at):
					sim._add_entity(side, kinds[placed], at)
					placed += 1

func _clear(sim, at: Vector2i) -> bool:
	for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
		var tile: Vector2i = at + offset
		if tile.x < 1 or tile.y < 1 or tile.x >= sim.map_width - 1 or tile.y >= sim.map_height - 1:
			return false
		if not sim._walkable(tile) or sim._unit_at(tile) != -1:
			return false
	return true

## Adds units on free tiles spiralling out from a point.
func _squad(sim, side: int, kinds: Array, near: Vector2i) -> Array:
	var ids := []
	for radius in range(0, 6):
		for dy in range(-radius, radius + 1):
			for dx in range(-radius, radius + 1):
				if ids.size() >= kinds.size():
					return ids
				var tile: Vector2i = near + Vector2i(dx, dy)
				if sim._walkable(tile) and sim._unit_at(tile) == -1:
					ids.append(sim._add_entity(side, kinds[ids.size()], tile))
	return ids

func _engage(sim, ours: Array, theirs: Array) -> void:
	sim._refresh_visibility()
	for i in ours.size():
		sim.issue(Skirmish.HUMAN, "attack", ours[i], theirs[i % theirs.size()])
	for i in theirs.size():
		var unit: Dictionary = sim.entities[theirs[i]]
		unit.target_id = ours[i % ours.size()]
		unit.job = "attack"

func _select(client, ids: Array) -> void:
	client.selected_ids.clear()
	for id in ids:
		client.selected_ids.append(id)
	client.selected_id = ids[0] if ids.size() == 1 else -1
	if ids.size() > 1:
		client.selected_id = ids[0]
