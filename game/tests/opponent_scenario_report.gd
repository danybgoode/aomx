extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
const MAX_TICKS := 4200

func _initialize() -> void:
	var rows: Array[Dictionary] = []
	for faction in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		for level in Skirmish.AI_LEVELS:
			for seed in [1, 2]:
				rows.append(_run_case(faction, level, seed))
	var report := {"game_version": Skirmish.GAME_VERSION, "content_version": Skirmish.CONTENT_VERSION,
		"map": "authored_28x28", "max_ticks": MAX_TICKS, "cases": rows}
	var output := JSON.stringify(report, "  ")
	var path := OS.get_environment("OPPONENT_REPORT_PATH")
	if not path.is_empty():
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file == null:
			printerr("Could not write opponent report to ", path)
			quit(1)
			return
		file.store_string(output + "\n")
		file.close()
	print("OPPONENT_REPORT=", output)
	var failed := false
	for row in rows:
		if row.result == "unfinished" or not row.replay_ok or row.ai_rejections > 0:
			printerr("Opponent scenario failed: ", row.faction, " ", row.level, " seed ", row.scenario_seed)
			failed = true
	quit(1 if failed else 0)

func _run_case(faction: String, level: String, seed: int) -> Dictionary:
	var game = Skirmish.new(faction, {}, seed, level)
	var times: Array[int] = []
	var plans := {}
	var stalls := {}
	var trajectory: Array[Dictionary] = []
	for step in MAX_TICKS:
		if game.result != "":
			break
		var started := Time.get_ticks_usec()
		game.tick()
		times.append(Time.get_ticks_usec() - started)
		plans[game.ai_plan] = int(plans.get(game.ai_plan, 0)) + 1
		if not game.ai_stall_reason.is_empty():
			stalls[game.ai_stall_reason] = int(stalls.get(game.ai_stall_reason, 0)) + 1
		if game.tick_number % 600 == 0:
			var balances := {}
			for resource_id in Skirmish.RESOURCE_IDS:
				balances[resource_id] = game.balance(Skirmish.COMPUTER, resource_id)
			trajectory.append({"tick": game.tick_number, "age": game.age_index[Skirmish.COMPUTER],
				"workers": _count(game, "worker"), "fighters": game._count_fighters(Skirmish.COMPUTER),
				"balances": balances})
	times.sort()
	var command_counts := {}
	for command in game.command_log:
		if command.side == Skirmish.COMPUTER:
			command_counts[command.kind] = int(command_counts.get(command.kind, 0)) + 1
	var replay_ok: bool = Replay.verify(Replay.record(game)).ok
	return {"faction": faction, "level": level, "scenario_seed": seed,
		"opening": game.ai_opening, "result": game.result if not game.result.is_empty() else "unfinished",
		"reason": game.result_reason, "ticks": game.tick_number, "ai_age": game.age_index[Skirmish.COMPUTER],
		"ai_commands": command_counts, "ai_rejections": game.ai_rejections,
		"ai_last_rejection": game.ai_last_rejection, "stall_ticks": stalls, "plans": plans,
		"trajectory": trajectory, "tick_p95_us": _percentile(times, 95), "tick_max_us": _percentile(times, 100),
		"replay_ok": replay_ok, "state_hash": game.state_hash()}

func _count(game: RefCounted, kind: String) -> int:
	var count := 0
	for entity in game.entities.values():
		if entity.side == Skirmish.COMPUTER and entity.kind == kind and entity.hp > 0:
			count += 1
	return count

func _percentile(samples: Array[int], percent: int) -> int:
	if samples.is_empty():
		return 0
	return samples[mini(samples.size() - 1, ceili(float(samples.size()) * float(percent) / 100.0) - 1)]
