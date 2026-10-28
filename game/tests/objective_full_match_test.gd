extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Replay = preload("res://skirmish_replay.gd")
var failed := false

func _initialize() -> void:
	for objective in ["la_roma", "conquest"]:
		for faction_index in Skirmish.FACTION_IDS.size():
			var faction: String = Skirmish.FACTION_IDS[faction_index]
			var opponent: String = Skirmish.FACTION_IDS[(faction_index + 1) % Skirmish.FACTION_IDS.size()]
			var game = Skirmish.new(faction, {}, 23, "standard", "la_roma", opponent, "", objective)
			for n in Skirmish.DRAW_TICK:
				game.tick()
				if game.result != "":
					break
			var key: String = objective + "/" + faction
			if game.result == "" or objective == "conquest" and game.result_reason == "district":
				failed = true
				push_error("Normal objective match did not finish by its rule: " + key)
			if not Replay.verify(Replay.record(game)).ok:
				failed = true
				push_error("Normal objective replay failed: " + key)
			print("OBJECTIVE_FULL_MATCH=", key, " result=", game.result, " reason=", game.result_reason, " tick=", game.tick_number)
	quit(1 if failed else 0)
