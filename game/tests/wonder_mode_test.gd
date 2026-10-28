extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const RulesContent = preload("res://rules_content.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
const Outbox = preload("res://funnel_outbox.gd")
var failed := false

func _initialize() -> void:
	var content := RulesContent.load_wonder("la_roma")
	check(content.ok and content.data.content_id == "la-roma-wonder-1", "versioned Wonder overlay loads")
	check(not RulesContent.load_wonder("narvarte").ok, "Wonder rejects other maps")
	var base := RulesContent.load_default()
	check(base.ok and not base.data.buildings.has("wonder"), "legacy content remains unchanged")
	for faction in Skirmish.FACTION_IDS:
		var game = Skirmish.new(faction, {}, 4, "standard", "la_roma", "", "", "wonder")
		game.ai_enabled = false
		var worker := game._find(Skirmish.HUMAN, "worker")
		var target := {"kind": "wonder", "pos": Vector2i(5, 8)}
		check(game.issue(Skirmish.HUMAN, "build", worker, target).reason == "age_required", faction + " must reach godin")
		game.age_index[Skirmish.HUMAN] = 2
		for resource_id in Skirmish.RESOURCE_IDS:
			game._add_balance(Skirmish.HUMAN, resource_id, 50)
		var before := game.balance(Skirmish.HUMAN, "materiales")
		var placed := game.issue(Skirmish.HUMAN, "build", worker, target)
		check(placed.ok, faction + " pays and places Wonder")
		check(game.balance(Skirmish.HUMAN, "materiales") == before - 20, faction + " pays material cost")
		check(game.issue(Skirmish.HUMAN, "build", worker, {"kind": "wonder", "pos": Vector2i(7, 7)}).reason == "wonder_already_active", "one active Wonder per side")
		var wonder := game._find(Skirmish.HUMAN, "wonder")
		game.entities[wonder].complete = true
		game.entities[wonder].progress = 180
		for i in 120:
			game.tick()
		check(game.wonder_progress[Skirmish.HUMAN] == 120 and game.result == "", "Wonder counts completed living ticks")
		var saved := Save.restore(Save.capture(game, "solo_0123456789abcdef0123456789abcdef"))
		check(saved.ok and saved.game.state_hash() == game.state_hash(), "Wonder save restores timer and hash")
		game.entities[wonder].hp = 0
		game.tick()
		check(game.wonder_progress[Skirmish.HUMAN] == 0 and game.result == "", "destroyed Wonder resets timer")
		var rebuild_balance := game.balance(Skirmish.HUMAN, "materiales")
		check(game.issue(Skirmish.HUMAN, "build", worker, target).ok, "destroyed Wonder can be rebuilt")
		check(game.balance(Skirmish.HUMAN, "materiales") == rebuild_balance - 20 and game.wonder_progress[Skirmish.HUMAN] == 0,
			"rebuild pays again and never inherits old countdown")
		var replay_game = Skirmish.new(faction, {}, 4, "standard", "la_roma", "", "", "wonder")
		for i in 30:
			replay_game.tick()
		check(Replay.verify(Replay.record(replay_game)).ok, "Wonder replay verifies")
	var finish = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", "", "", "wonder")
	finish.ai_enabled = false
	var human_wonder := finish._add_entity(Skirmish.HUMAN, "wonder", Vector2i(5, 8))
	finish.entities[human_wonder].complete = true
	finish.wonder_progress[Skirmish.HUMAN] = 899
	finish.tick()
	check(finish.result == "win" and finish.result_reason == "wonder", "Wonder terminal fires at 900")
	var simultaneous = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", "", "", "wonder")
	simultaneous.ai_enabled = false
	for side in [Skirmish.HUMAN, Skirmish.COMPUTER]:
		var project := simultaneous._add_entity(side, "wonder", Vector2i(5, 8) if side == Skirmish.HUMAN else Vector2i(16, 9))
		simultaneous.entities[project].complete = true
		simultaneous.wonder_progress[side] = 899
	simultaneous.tick()
	check(simultaneous.result == "draw" and simultaneous.result_reason == "simultaneous_wonders", "same-tick Wonder finishes draw")
	var post_first = Skirmish.new(Skirmish.REGIOS, {}, 1, "standard", "la_roma", "", "", "wonder")
	post_first.ai_enabled = false
	var post_project := post_first._add_entity(Skirmish.HUMAN, "wonder", Vector2i(5, 8))
	post_first.entities[post_project].complete = true
	post_first.wonder_progress[Skirmish.HUMAN] = 899
	post_first.entities[post_first._find(Skirmish.HUMAN, "command_post")].hp = 0
	post_first.tick()
	check(post_first.result == "loss" and post_first.result_reason == "command_post", "post defeat precedes Wonder finish")
	var rival = Skirmish.new(Skirmish.REGIOS, {}, 8, "standard", "la_roma", "", "", "wonder")
	for i in 4:
		rival._add_entity(Skirmish.COMPUTER, "worker", Vector2i(14 + i, 13))
	for pair in [["depot", Vector2i(16, 8)], ["housing", Vector2i(17, 10)],
		["barracks", Vector2i(17, 12)], ["registry", Vector2i(17, 17)]]:
		rival._add_entity(Skirmish.COMPUTER, pair[0], pair[1])
	rival._add_entity(Skirmish.COMPUTER, "melee", Vector2i(15, 12))
	rival._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(15, 13))
	rival.age_index[Skirmish.COMPUTER] = 2
	rival.researched[Skirmish.COMPUTER] = ["carry_capacity_i"]
	for resource_id in Skirmish.RESOURCE_IDS:
		rival._add_balance(Skirmish.COMPUTER, resource_id, 100)
	check(rival._ai_goal().get("id") == "wonder", "AI prioritizes a legal Wonder after reaching godin")
	rival._ai_step()
	check(rival._find(Skirmish.COMPUTER, "wonder") != -1 and rival.ai_rejections == 0, "AI builds using a legal paid order")
	var target_wonder := rival._add_entity(Skirmish.HUMAN, "wonder", Vector2i(14, 9))
	rival.entities[target_wonder].complete = true
	rival._refresh_visibility()
	rival.tick_number = maxi(rival.tick_number, int(rival.content.ai.levels.standard.attack_tick))
	rival._ai_step()
	var attacker := rival._find(Skirmish.COMPUTER, "melee")
	check(rival.entities[attacker].target_id == target_wonder, "AI targets an observed opposing Wonder")
	var outbox_path := "user://wonder-outbox-%d.json" % Time.get_ticks_usec()
	var outbox = Outbox.new(outbox_path)
	outbox.game_version = Skirmish.GAME_VERSION
	outbox.content_version = Skirmish.CONTENT_VERSION
	outbox.faction = "regios"
	var match_id := "solo_0123456789abcdef0123456789abcdef"
	check(outbox.queue("game_opened").ok, "Wonder session opens")
	outbox.content_version = "la-roma-wonder-1"
	check(not outbox.queue("match_started", match_id, "", false, "solo", "", "wonder").ok, "unversioned Wonder start is blocked")
	check(outbox.queue("match_started", match_id, "", false, "solo", "", "wonder", 1).ok, "served version is attached to Wonder start")
	check(outbox.queue("match_completed", match_id, "win", false, "solo", "", "wonder").ok, "Wonder result follows start")
	check(outbox.queue("wonder_match_completed", match_id, "win", false, "solo", "", "wonder").ok, "Wonder adoption follows result")
	check(outbox.state.events.size() == 4 and outbox.state.events[3].event.wonder_flag_version == 1, "Wonder version survives local event chain")
	if failed: quit(1)
	else:
		print("Wonder mode checks passed")
		quit(0)

func check(condition: bool, description: String) -> void:
	if not condition:
		failed = true
		push_error(description)
