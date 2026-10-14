extends SceneTree

const Sim = preload("res://simulation.gd")
var _failed := false

func _initialize() -> void:
	var sim = Sim.new()
	_check(sim.issue("move", Vector2i(4, 2)).ok, "reachable move accepted")
	sim.tick()
	_check(sim.worker == Vector2i(4, 2), "worker reached destination")
	var prior: Dictionary = sim.snapshot()
	_check(not sim.issue("move", Vector2i(10, 1)).ok, "wall rejected")
	_check(sim.snapshot() == prior, "rejection unchanged state")
	_check(not sim.issue("move", Vector2i(15, 15)).ok, "unreachable pocket rejected")
	_check(sim.issue("gather", Sim.RESOURCE).ok, "gather accepted")
	for i in range(20):
		sim.tick()
		if sim.carrying > 0:
			break
	_check(sim.carrying > 0, "worker gathered")
	var conserved: int = sim.resource_amount + sim.carrying + sim.stockpile
	_check(conserved == 20, "gather conserves resource")
	_check(sim.issue("move", Vector2i(4, 2)).ok, "interrupt accepted")
	_check(sim.carrying > 0, "interruption retains carried resource")
	_check(sim.issue("gather", Sim.RESOURCE).ok, "resume accepted")
	for i in range(150):
		sim.tick()
		if sim.stockpile >= 8:
			break
	_check(sim.stockpile >= 8, "stockpile gained through delivery")
	_check(sim.resource_amount + sim.carrying + sim.stockpile == 20, "delivery conserves resource")
	var before: int = sim.stockpile
	_check(not sim.issue("build", Vector2i(10, 2)).ok, "blocked placement rejected")
	_check(sim.stockpile == before, "invalid placement spends nothing")
	_check(sim.issue("build", Vector2i(4, 7)).ok, "valid placement accepted")
	_check(sim.stockpile == before - Sim.BUILD_COST, "cost charged once")
	_check(not sim.issue("build", Vector2i(4, 7)).ok, "repeat build rejected")
	_check(sim.stockpile == before - Sim.BUILD_COST, "repeat spends nothing")
	for i in range(60):
		sim.tick()
		_check(not (sim.worker.x >= 4 and sim.worker.x <= 5 and sim.worker.y >= 7 and sim.worker.y <= 8), "worker avoids construction footprint")
		if sim.building_complete:
			break
	_check(sim.building_complete, "building completes")
	_check(not sim.issue("move", Vector2i(4, 7)).ok, "footprint blocks movement")
	_check(sim.resource_amount + sim.carrying + sim.stockpile + Sim.BUILD_COST == 20, "full resource ledger conserved")
	var a = Sim.new()
	var b = Sim.new()
	for copy in [a, b]:
		copy.issue("move", Vector2i(4, 2))
		for i in range(2): copy.tick()
		copy.issue("gather", Sim.RESOURCE)
		for i in range(90): copy.tick()
		copy.issue("build", Vector2i(4, 7))
		for i in range(40): copy.tick()
	_check(a.snapshot() == b.snapshot(), "replay state matches")
	_check(a.command_log == b.command_log, "replay command metadata matches")
	if not _failed:
		print("RTS simulation checks passed: move, rejection, gather, interruption, build, resource ledger, replay")
	quit(1 if _failed else 0)

func _check(ok: bool, label: String) -> void:
	if not ok:
		printerr("FAIL: ", label)
		_failed = true
