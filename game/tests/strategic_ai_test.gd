extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")

func _initialize() -> void:
	var passed := true
	for faction in [Skirmish.REGIOS, Skirmish.POBLANOS]:
		var rules: Dictionary = RulesContent.load_default().data.duplicate(true)
		for level in Skirmish.AI_LEVELS:
			rules.ai.levels[level].scout_tick = 8000
			rules.ai.levels[level].district_tick = 8000
			rules.ai.levels[level].attack_tick = 8000
		var game = Skirmish.new(faction, rules)
		for n in range(5000):
			game.tick()
			if game.age_index[Skirmish.COMPUTER] == 3 and "combat_training_i" in game.researched[Skirmish.COMPUTER]:
				break
		var age: int = game.age_index[Skirmish.COMPUTER]
		if age != 3 or "combat_training_i" not in game.researched[Skirmish.COMPUTER] or game.result != "":
			passed = false
		for resource_id in Skirmish.RESOURCE_IDS:
			if game.balance(Skirmish.COMPUTER, resource_id) < 0:
				passed = false
	if not passed:
		push_error("AI failed to reach legal fourth age")
	else:
		print("Strategic AI reached fourth age and completed research for both factions")
	quit(0 if passed else 1)
