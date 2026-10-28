extends SceneTree

const Skirmish = preload("res://skirmish.gd")

func _initialize() -> void:
	var game = Skirmish.new(Skirmish.REGIOS, {}, 23, "standard", "la_roma", Skirmish.POBLANOS, "", "wonder")
	var saw_wonder := false
	for i in Skirmish.DRAW_TICK:
		game.tick()
		if game._find(Skirmish.COMPUTER, "wonder") != -1:
			saw_wonder = true
		if game.result != "":
			break
	if not saw_wonder or game.ai_rejections > 0 or game.result == "":
		push_error("Normal Wonder AI match failed: built=%s rejections=%d result=%s tick=%d age=%d plan=%s stall=%s" % [str(saw_wonder), game.ai_rejections, game.result, game.tick_number, game.age_index[Skirmish.COMPUTER], game.ai_plan, game.ai_stall_reason])
		quit(1)
	else:
		print("Normal Wonder AI match: result=", game.result, " reason=", game.result_reason, " tick=", game.tick_number, " built=", saw_wonder)
		quit(0)
