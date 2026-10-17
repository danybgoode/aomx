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
	var bad: Dictionary = loaded.data.duplicate(true)
	bad.units.melee.cost = -1
	check(RulesContent.validate(bad).reason == "invalid_melee_cost", "invalid cost rejected")
	bad = loaded.data.duplicate(true)
	bad.map.resource_positions[0] = [500, 1]
	check(RulesContent.validate(bad).reason == "map_resource_positions_invalid", "out of bounds source rejected")
	bad = loaded.data.duplicate(true)
	bad.buildings.barracks.trains = ["unknown_unit"]
	check(RulesContent.validate(bad).reason == "invalid_train_role_unknown_unit", "unknown role ID rejected")
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
