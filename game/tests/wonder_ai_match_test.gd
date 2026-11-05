extends SceneTree

const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	var failed := false
	for map_id in Skirmish.MAP_IDS:
		var game = Skirmish.new(Skirmish.REGIOS, {}, 23, "standard", map_id, Skirmish.POBLANOS, "", "wonder")
		var saw_wonder := false
		for i in Skirmish.DRAW_TICK:
			game.tick()
			if game._find(Skirmish.COMPUTER, "wonder") != -1:
				saw_wonder = true
			if game.result != "":
				break
		if not saw_wonder or game.result == "" or map_id == "la_roma" and game.ai_rejections > 0:
			failed = true
			push_error("Normal Wonder AI match failed on %s: built=%s rejections=%d last=%s result=%s tick=%d age=%d plan=%s stall=%s" % [map_id, str(saw_wonder), game.ai_rejections, game.ai_last_rejection, game.result, game.tick_number, game.age_index[Skirmish.COMPUTER], game.ai_plan, game.ai_stall_reason])
		else:
			print("Normal Wonder AI match on ", map_id, ": result=", game.result, " reason=", game.result_reason, " tick=", game.tick_number, " built=", saw_wonder)
	quit(1 if failed else 0)
