extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	for resource_id in Skirmish.RESOURCE_IDS:
		var game = Skirmish.new()
		game.ai_enabled = false
		var worker: int = game._find(Skirmish.HUMAN, "worker")
		var source: Dictionary = game.resource_sources[Skirmish.HUMAN][resource_id]
		var starting_amount: int = source.amount
		check(game.issue(Skirmish.HUMAN, "gather", worker, source.pos).ok,
			"worker accepts physical %s source" % resource_id)
		var carried := false
		for i in 300:
			game.tick()
			if game.entities[worker].carry > 0 and game.entities[worker].carry_resource == resource_id:
				carried = true
			if game.balance(Skirmish.HUMAN, resource_id) > 0:
				break
		check(carried and source.amount < starting_amount, "%s is picked up from finite source" % resource_id)
		check(game.balance(Skirmish.HUMAN, resource_id) > 0 and game.entities[worker].carry_resource == "",
			"%s cargo reaches a valid drop-off" % resource_id)
		for other_id in Skirmish.RESOURCE_IDS:
			if other_id != resource_id:
				check(game.balance(Skirmish.HUMAN, other_id) == 0,
					"%s delivery does not credit %s" % [resource_id, other_id])
	var refresh = Skirmish.new()
	refresh.ai_enabled = false
	var lot: Dictionary = refresh.resource_sources[Skirmish.HUMAN].terrenos
	lot.amount = 1
	lot.refreshes_left = 1
	var survey_worker: int = refresh._find(Skirmish.HUMAN, "worker")
	check(refresh.issue(Skirmish.HUMAN, "gather", survey_worker, lot.pos).ok,
		"worker accepts the last packet in a vacant lot")
	for i in 150:
		refresh.tick()
		if lot.amount == 0:
			break
	check(lot.amount == 0 and refresh.entities[survey_worker].carry_resource == "terrenos",
		"worker physically depletes the vacant lot")
	for i in int(refresh.content.resources.terrenos.refresh_ticks):
		refresh.tick()
	check(lot.amount == int(refresh.content.resources.terrenos.refresh_amount) and lot.refreshes_left == 0,
		"vacant lot replenishes finite survey packets after timed refresh")
	lot.amount = 0
	for i in int(refresh.content.resources.terrenos.refresh_ticks) * 2:
		refresh.tick()
	check(lot.amount == 0, "exhausted refresh budget does not create infinite packets")
	var reroute = Skirmish.new()
	reroute.ai_enabled = false
	var reroute_worker: int = reroute._find(Skirmish.HUMAN, "worker")
	var post: int = reroute._find(Skirmish.HUMAN, "command_post")
	var depot: int = reroute._add_entity(Skirmish.HUMAN, "depot", Vector2i(8, 2))
	reroute.entities[reroute_worker].pos = Vector2i(8, 6)
	reroute.entities[reroute_worker].carry = 2
	reroute.entities[reroute_worker].carry_resource = "comida"
	reroute.entities[reroute_worker].source_resource = ""
	reroute.tick()
	check(reroute.entities[reroute_worker].target_id == depot, "worker chooses nearer depot")
	reroute.entities[depot].hp = 0
	for i in 100:
		reroute.tick()
		if reroute.balance(Skirmish.HUMAN, "comida") == 2:
			break
	check(reroute.balance(Skirmish.HUMAN, "comida") == 2 and reroute.entities[reroute_worker].carry == 0,
		"lost depot reroutes cargo to surviving command post")
	check(reroute.entities.has(post), "drop-off recovery keeps the match alive")
	var build = Skirmish.new()
	build.ai_enabled = false
	build._add_balance(Skirmish.HUMAN, "materiales", 30)
	build._add_balance(Skirmish.HUMAN, "varos", 30)
	build._add_balance(Skirmish.HUMAN, "comida", 30)
	var first: int = build._find(Skirmish.HUMAN, "worker")
	var second: int = build._add_entity(Skirmish.HUMAN, "worker", Vector2i(7, 8))
	build.entities[first].pos = Vector2i(4, 8)
	check(build.issue(Skirmish.HUMAN, "build", first, {"kind": "housing", "pos": Vector2i(5, 8)}).ok,
		"first worker starts housing")
	var house: int = build._find(Skirmish.HUMAN, "housing")
	check(build.issue(Skirmish.HUMAN, "assist", second, house).ok,
		"second worker assists the same construction")
	for i in 10:
		build.tick()
	check(build.entities[house].progress >= 20, "two workers contribute shared progress")
	for i in 20:
		build.tick()
	check(build.entities[house].complete and build._population_cap(Skirmish.HUMAN) == 8,
		"completed housing raises population capacity")
	build.entities[house].hp -= 6
	var before_repair: int = build.balance(Skirmish.HUMAN, "materiales")
	check(build.issue(Skirmish.HUMAN, "repair", first, house).ok, "worker accepts paid repair")
	for i in 30:
		build.tick()
	check(build.entities[house].hp == build._starting_health(Skirmish.HUMAN, "housing") and build.balance(Skirmish.HUMAN, "materiales") < before_repair,
		"repair restores health and consumes Materiales")
	var cap = Skirmish.new()
	cap.ai_enabled = false
	cap._add_balance(Skirmish.HUMAN, "comida", 20)
	cap._add_balance(Skirmish.HUMAN, "varos", 20)
	for i in 3:
		cap._add_entity(Skirmish.HUMAN, "worker", Vector2i(4 + i, 3))
	var cap_post: int = cap._find(Skirmish.HUMAN, "command_post")
	check(cap._population_used(Skirmish.HUMAN) == cap._population_cap(Skirmish.HUMAN),
		"starting cap counts living units")
	check(cap.issue(Skirmish.HUMAN, "train", cap_post, "worker").reason == "population_cap",
		"population cap blocks recruitment")
	cap._add_entity(Skirmish.HUMAN, "housing", Vector2i(5, 8))
	check(cap.issue(Skirmish.HUMAN, "train", cap_post, "worker").ok,
		"housing permits recruitment")
	var cancel = Skirmish.new()
	cancel.ai_enabled = false
	cancel._add_balance(Skirmish.HUMAN, "materiales", 10)
	cancel._add_balance(Skirmish.HUMAN, "varos", 10)
	var cancel_worker: int = cancel._find(Skirmish.HUMAN, "worker")
	check(cancel.issue(Skirmish.HUMAN, "build", cancel_worker, {"kind": "depot", "pos": Vector2i(5, 8)}).ok,
		"depot construction accepts payment")
	var cancel_depot: int = cancel._find(Skirmish.HUMAN, "depot")
	check(cancel.issue(Skirmish.HUMAN, "cancel", cancel_worker, cancel_depot).ok,
		"unfinished construction can be canceled")
	check(cancel._find(Skirmish.HUMAN, "depot") == -1 and cancel.balance(Skirmish.HUMAN, "varos") == 8 and cancel.balance(Skirmish.HUMAN, "materiales") == 8,
		"construction cancellation refunds half of each paid resource")
	var changing_route = Skirmish.new()
	changing_route.ai_enabled = false
	changing_route._add_balance(Skirmish.HUMAN, "materiales", 20)
	changing_route._add_balance(Skirmish.HUMAN, "varos", 20)
	var mover: int = changing_route._find(Skirmish.HUMAN, "worker")
	var site_worker: int = changing_route._add_entity(Skirmish.HUMAN, "worker", Vector2i(7, 2))
	check(changing_route.issue(Skirmish.HUMAN, "move", mover, Vector2i(8, 8)).ok,
		"worker starts a route before another building is placed")
	var original_path: Array = changing_route.entities[mover].path.duplicate()
	var new_site := Vector2i(-1, -1)
	for route_tile in original_path:
		if new_site.x >= 0:
			break
		for offset in [Vector2i.ZERO, Vector2i.RIGHT, Vector2i.DOWN, Vector2i(1, 1)]:
			var candidate: Vector2i = route_tile - offset
			if changing_route.issue(Skirmish.HUMAN, "build", site_worker, {"kind": "housing", "pos": candidate}).ok:
				new_site = candidate
				break
	check(new_site.x >= 0, "second worker can build across an existing route")
	if new_site.x >= 0:
		for i in 90:
			changing_route.tick()
			check(not changing_route._contains(new_site, changing_route.entities[mover].pos),
				"moving worker never crosses a newly occupied footprint")
	if not failed:
		print("Strategic economy checks passed: four resources, refresh, reroute, construction, repair, population, cancellation")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
