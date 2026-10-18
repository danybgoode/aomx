extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
var failed := false

func _initialize() -> void:
	var loaded: Dictionary = RulesContent.load_default()
	check(loaded.ok and loaded.data.content_id == Skirmish.CONTENT_VERSION, "versioned default content loads")
	if not loaded.ok:
		quit(1)
		return
	check(loaded.data.schema_version == 3 and loaded.data.resources.size() == 4 and loaded.data.ages.order.size() == 4,
		"four-resource four-age strategy content loads")
	check(loaded.data.techs.size() == 3 and loaded.data.buildings.size() == 5,
		"mechanics-first techs and building roster load")
	var bad: Dictionary = loaded.data.duplicate(true)
	bad.units.melee.cost = -1
	check(RulesContent.validate(bad).reason == "invalid_melee_cost", "invalid cost rejected")
	bad = loaded.data.duplicate(true)
	bad.map.resource_positions[0] = [500, 1]
	check(RulesContent.validate(bad).reason == "map_resource_positions_invalid", "out of bounds source rejected")
	bad = loaded.data.duplicate(true)
	bad.buildings.barracks.trains = ["unknown_unit"]
	check(RulesContent.validate(bad).reason == "invalid_train_role_unknown_unit", "unknown role ID rejected")
	bad = loaded.data.duplicate(true)
	bad.resources.terrenos.source_positions[0] = [500, 1]
	check(RulesContent.validate(bad).reason == "invalid_terrenos_positions", "out-of-bounds survey lot rejected")
	bad = loaded.data.duplicate(true)
	bad.units.worker.costs.comida = -1
	check(RulesContent.validate(bad).reason == "invalid_worker_costs", "negative resource cost rejected")
	bad = loaded.data.duplicate(true)
	bad.units.siege.bonuses.unknown = 3
	check(RulesContent.validate(bad).reason == "invalid_siege_bonus", "unknown counter reference rejected")
	bad = loaded.data.duplicate(true)
	bad.map.cliff_tiles.append([10, 8])
	check(RulesContent.validate(bad).reason == "map_cliff_tiles_invalid", "cliff cannot overlap a blocked wall")
	bad = loaded.data.duplicate(true)
	for y in range(int(bad.map.height)):
		if y != 17:
			bad.map.blocked_tiles.append([11, y])
	check(RulesContent.validate(bad).reason == "critical_route_disconnected", "isolated starting routes rejected")
	bad = loaded.data.duplicate(true)
	bad.buildings.depot.costs.extra = 1
	check(RulesContent.validate(bad).reason == "invalid_depot_costs", "unknown resource ID rejected")
	bad = loaded.data.duplicate(true)
	bad.ages.transitions.godin.requires_buildings = ["unknown_building"]
	check(RulesContent.validate(bad).reason == "invalid_godin_prerequisites", "unknown age building prerequisite rejected")
	bad = loaded.data.duplicate(true)
	bad.techs.carry_capacity_i.requires_techs = ["construction_rate_i"]
	bad.techs.construction_rate_i.age = "universitaria"
	check(RulesContent.validate(bad).reason == "tech_cycle", "technology prerequisite cycle rejected")
	bad = loaded.data.duplicate(true)
	bad.ages.transitions.universitaria.requires_techs = ["carry_capacity_i"]
	check(RulesContent.validate(bad).reason == "invalid_universitaria_prerequisite_age", "age cannot require a same-age tech")
	var game = Skirmish.new()
	check(game.content_hash == loaded.hash, "simulation pins content digest")
	var worker: int = game._find(Skirmish.HUMAN, "worker")
	var command := {"schema_version": Skirmish.COMMAND_SCHEMA_VERSION, "sequence": game.next_command,
		"issued_tick": game.tick_number, "side": Skirmish.HUMAN, "kind": "gather", "actor_id": worker,
		"target": [6, 4]}
	check(game.issue_command(command).ok, "versioned command reaches existing match")
	var before: String = game.state_hash()
	command.sequence = 999
	check(game.issue_command(command).reason == "command_order_mismatch" and game.state_hash() == before,
		"stale sequence rejected before mutation")
	command.sequence = game.next_command
	command.schema_version = 999
	check(game.issue_command(command).reason == "unsupported_command_schema" and game.state_hash() == before,
		"unknown command version rejected before mutation")
	var custom: Dictionary = loaded.data.duplicate(true)
	custom.units.melee.cost = 9
	custom.units.melee.costs.varos = 9
	custom.factions.regios.carry_limit = 7
	var changed = Skirmish.new(Skirmish.REGIOS, custom)
	check(changed._cost(Skirmish.HUMAN, "melee") == 10 and changed._carry_limit(Skirmish.HUMAN) == 7,
		"validated definitions, not legacy constants, drive rules")
	if not failed:
		print("Rules content checks passed: schema, IDs, commands and data-driven values")
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		failed = true
