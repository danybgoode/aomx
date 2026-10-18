extends SceneTree

const Skirmish = preload("res://skirmish.gd")
var failed := false

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.POBLANOS)
	game.ai_enabled = false
	for resource_id in Skirmish.RESOURCE_IDS:
		game._add_balance(Skirmish.HUMAN, resource_id, 250)
	var post: int = game._find(Skirmish.HUMAN, "command_post")
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	check(game.content.ages.order[game.age_index[Skirmish.HUMAN]] == "foranea",
		"match begins in Foránea")
	check(game.issue(Skirmish.HUMAN, "advance", post, "universitaria").reason == "building_prerequisite_missing",
		"first advance requires completed depot and housing")
	check(game.issue(Skirmish.HUMAN, "research", post, "carry_capacity_i").reason == "registry_and_tech_required",
		"research requires the registry")
	check(game.issue(Skirmish.HUMAN, "build", worker, {"kind": "registry", "pos": Vector2i(5, 8)}).reason == "age_required",
		"registry cannot be built before its unlock age")
	game._add_entity(Skirmish.HUMAN, "depot", Vector2i(5, 8))
	game._add_entity(Skirmish.HUMAN, "housing", Vector2i(7, 8))
	var before_age: int = game.balance(Skirmish.HUMAN, "terrenos")
	check(game.issue(Skirmish.HUMAN, "advance", post, "universitaria").ok,
		"legal first age advance queues")
	check(game.balance(Skirmish.HUMAN, "terrenos") == before_age - int(game.content.ages.transitions.universitaria.costs.terrenos),
		"age transition charges Terrenos exactly once")
	check(game.age_index[Skirmish.HUMAN] == 0, "queued age is not applied early")
	for i in int(game.content.ages.transitions.universitaria.duration_ticks) + 1:
		game.tick()
	check(game.age_index[Skirmish.HUMAN] == 1 and game.entities[post].queue.is_empty(),
		"Universitaria applies after its declared duration")
	check(game.issue(Skirmish.HUMAN, "advance", post, "godin").reason == "building_prerequisite_missing",
		"Godín needs the registry")
	var registry: int = game._add_entity(Skirmish.HUMAN, "registry", Vector2i(5, 11))
	check(game.issue(Skirmish.HUMAN, "advance", post, "godin").reason == "tech_prerequisite_missing",
		"Godín needs the carry research")
	check(game.issue(Skirmish.HUMAN, "research", registry, "construction_rate_i").reason == "age_required",
		"Godín technology stays locked in Universitaria")
	check(game.issue(Skirmish.HUMAN, "research", registry, "unknown_tech").reason == "registry_and_tech_required",
		"unknown technology ID is rejected")
	var before_tech: int = game.balance(Skirmish.HUMAN, "comida")
	check(game.issue(Skirmish.HUMAN, "research", registry, "carry_capacity_i").ok,
		"carry research queues after the registry unlocks")
	check(game.issue(Skirmish.HUMAN, "cancel", registry, 0).ok,
		"queued research can be canceled")
	check(game.balance(Skirmish.HUMAN, "comida") == before_tech - 2,
		"active research cancellation refunds half its Comida cost")
	check(game.issue(Skirmish.HUMAN, "research", registry, "carry_capacity_i").ok,
		"canceled research can be queued again")
	for i in int(game.content.techs.carry_capacity_i.duration_ticks) + 1:
		game.tick()
	check("carry_capacity_i" in game.researched[Skirmish.HUMAN] and game._carry_limit(Skirmish.HUMAN) == int(game.content.factions.poblanos.carry_limit) + 1,
		"carry research changes the measurable worker limit once")
	check(game.issue(Skirmish.HUMAN, "research", registry, "carry_capacity_i").reason == "already_researched_or_queued",
		"completed research cannot be charged twice")
	check(game.issue(Skirmish.HUMAN, "advance", post, "godin").ok,
		"completed first prerequisite opens Godín")
	for i in int(game.content.ages.transitions.godin.duration_ticks) + 1:
		game.tick()
	check(game.age_index[Skirmish.HUMAN] == 2, "Godín applies after declared duration")
	check(game._construction_rate(Skirmish.HUMAN) == 1,
		"construction rate remains unchanged before research")
	check(game.issue(Skirmish.HUMAN, "research", registry, "construction_rate_i").ok,
		"construction technology accepts its prerequisite")
	for i in int(game.content.techs.construction_rate_i.duration_ticks) + 1:
		game.tick()
	check(game._construction_rate(Skirmish.HUMAN) == 2,
		"construction technology applies its measurable effect")
	check(game.issue(Skirmish.HUMAN, "research", registry, "combat_training_i").reason == "age_required",
		"final-age combat technology stays locked in Godín")
	check(game.issue(Skirmish.HUMAN, "advance", post, "gentrificacion").reason == "building_prerequisite_missing",
		"final transition requires a recruitment post")
	game._add_entity(Skirmish.HUMAN, "barracks", Vector2i(7, 11))
	check(game.issue(Skirmish.HUMAN, "advance", post, "gentrificacion").ok,
		"legal final transition queues")
	for i in int(game.content.ages.transitions.gentrificacion.duration_ticks) + 1:
		game.tick()
	check(game.age_index[Skirmish.HUMAN] == 3 and game.content.ages.order[game.age_index[Skirmish.HUMAN]] == "gentrificacion",
		"match reaches fourth age")
	check(game.issue(Skirmish.HUMAN, "advance", post, "gentrificacion").reason == "next_age_required",
		"fourth age is terminal for advancement")
	var base_damage: int = game._unit_damage(Skirmish.HUMAN, "melee")
	check(game.issue(Skirmish.HUMAN, "research", registry, "combat_training_i").ok,
		"final-age combat technology queues")
	for i in int(game.content.techs.combat_training_i.duration_ticks) + 1:
		game.tick()
	check(game._unit_damage(Skirmish.HUMAN, "melee") == base_damage + 1,
		"combat training raises damage once")
	if not failed:
		print("Strategic progression checks passed: prerequisites, costs, refunds, effects and four ages")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
