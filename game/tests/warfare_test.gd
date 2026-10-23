extends SceneTree

const Skirmish = preload("res://skirmish.gd")
const Save = preload("res://skirmish_persistence.gd")
const Replay = preload("res://skirmish_replay.gd")
var failures := 0

func _initialize() -> void:
	var game = Skirmish.new()
	game.ai_enabled = false
	check(game.map_width == 28 and game.map_height == 28, "authored larger map loads")
	check(not game.is_visible(Skirmish.HUMAN, game.entities[game._find(Skirmish.COMPUTER, "command_post")].pos), "enemy post starts hidden")
	var human := game._add_entity(Skirmish.HUMAN, "melee", Vector2i(13, 16))
	var enemy := game._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(15, 16))
	check(game.issue(Skirmish.HUMAN, "attack", human, enemy).reason == "target_not_visible", "hidden enemy cannot be targeted")
	game._refresh_visibility()
	check(game.is_visible(Skirmish.HUMAN, Vector2i(15, 16)), "scout reveals an enemy")
	check(game.issue(Skirmish.HUMAN, "attack", human, enemy).ok, "visible enemy can be targeted")
	game.entities[human].pos = Vector2i(3, 16)
	game._refresh_visibility()
	check(not game.is_visible(Skirmish.HUMAN, Vector2i(15, 16)) and game.is_explored(Skirmish.HUMAN, Vector2i(15, 16)), "explored tile remains after vision leaves")
	game.tick()
	check(game.entities[human].job == "idle", "lost target cancels attack")
	var crowd = Skirmish.new()
	crowd.ai_enabled = false
	var first := crowd._add_entity(Skirmish.HUMAN, "melee", Vector2i(4, 10))
	var second := crowd._add_entity(Skirmish.HUMAN, "melee", Vector2i(4, 11))
	check(crowd.issue(Skirmish.HUMAN, "move", first, Vector2i(6, 10)).ok, "first crowded move accepted")
	check(crowd.issue(Skirmish.HUMAN, "move", second, Vector2i(6, 11)).ok, "second crowded move accepted")
	for i in range(30):
		crowd.tick()
		check(crowd.entities[first].pos != crowd.entities[second].pos, "fighters never overlap")
	var detour = Skirmish.new()
	detour.ai_enabled = false
	var walker := detour._add_entity(Skirmish.HUMAN, "melee", Vector2i(4, 10))
	var parked := detour._add_entity(Skirmish.HUMAN, "melee", Vector2i(5, 10))
	check(detour.issue(Skirmish.HUMAN, "move", walker, Vector2i(6, 10)).ok, "crowded route order accepted")
	for i in range(55):
		detour.tick()
		check(detour.entities[walker].pos != detour.entities[parked].pos, "detour never overlaps parked unit")
	check(detour.entities[walker].pos == Vector2i(6, 10) and detour.entities[walker].job == "idle", "walker routes around stationary friendly unit and completes order")
	var worker_detour = Skirmish.new()
	worker_detour.ai_enabled = false
	var gathering_worker := worker_detour._add_entity(Skirmish.HUMAN, "worker", Vector2i(5, 7))
	var parked_worker := worker_detour._add_entity(Skirmish.HUMAN, "worker", Vector2i(6, 7))
	check(worker_detour.issue(Skirmish.HUMAN, "gather", gathering_worker, Vector2i(7, 7)).ok, "worker order accepts crowded source approach")
	for i in range(75):
		worker_detour.tick()
		check(worker_detour.entities[gathering_worker].pos != worker_detour.entities[parked_worker].pos, "worker detour never overlaps parked worker")
	check(worker_detour.entities[gathering_worker].carry > 0 or worker_detour.balance(Skirmish.HUMAN, "terrenos") > 0,
		"gatherer reaches a free side of the source and resumes collection")
	var opponents = Skirmish.new()
	opponents.ai_enabled = false
	var human_opponent := opponents._add_entity(Skirmish.HUMAN, "melee", Vector2i(5, 20))
	var computer_opponent := opponents._add_entity(Skirmish.COMPUTER, "melee", Vector2i(6, 20))
	opponents.entities[human_opponent].path = [Vector2i(6, 20)]
	opponents.entities[computer_opponent].path = [Vector2i(5, 20)]
	opponents.entities[human_opponent].job = "move"
	opponents.entities[computer_opponent].job = "move"
	for i in range(3):
		opponents.tick()
	check(opponents.entities[human_opponent].pos == Vector2i(5, 20) and opponents.entities[computer_opponent].pos == Vector2i(6, 20),
		"opposing units cannot swap through each other")
	var edge_sight = Skirmish.new()
	edge_sight.ai_enabled = false
	var enemy_post: int = edge_sight._find(Skirmish.COMPUTER, "command_post")
	var edge_siege := edge_sight._add_entity(Skirmish.HUMAN, "siege", Vector2i(19, 17))
	edge_sight.visible_tiles[Skirmish.HUMAN] = {Vector2i(17, 17): true}
	check(not edge_sight.is_visible(Skirmish.HUMAN, edge_sight.entities[enemy_post].pos) and edge_sight.is_entity_visible(Skirmish.HUMAN, edge_sight.entities[enemy_post]),
		"a visible building footprint reveals its hidden anchor")
	check(enemy_post in edge_sight._visible_enemy_ids(Skirmish.HUMAN) and edge_sight.issue(Skirmish.HUMAN, "attack", edge_siege, enemy_post).ok,
		"building is targetable from a visible south-east footprint tile")
	var slain_target = Skirmish.new()
	slain_target.ai_enabled = false
	var pursuer := slain_target._add_entity(Skirmish.HUMAN, "melee", Vector2i(13, 16))
	var doomed := slain_target._add_entity(Skirmish.COMPUTER, "ranged", Vector2i(15, 16))
	slain_target._refresh_visibility()
	check(slain_target.issue(Skirmish.HUMAN, "attack", pursuer, doomed).ok, "pursuer starts a legal attack")
	slain_target.entities[doomed].hp = 0
	slain_target.tick()
	check(slain_target.entities[pursuer].job == "idle" and slain_target.entities[pursuer].path.is_empty(),
		"pursuit ends immediately when visible target dies")
	var fight = Skirmish.new()
	fight.ai_enabled = false
	var armored := fight._add_entity(Skirmish.COMPUTER, "armored", Vector2i(13, 9))
	var melee := fight._add_entity(Skirmish.HUMAN, "melee", Vector2i(12, 9))
	fight._refresh_visibility()
	check(fight.issue(Skirmish.HUMAN, "attack", melee, armored).ok, "armored target visible")
	var hp: int = fight.entities[armored].hp
	fight.tick()
	check(fight.entities[armored].hp == hp - 1, "armor reduces blunt damage to floor one")
	var blunt_duel = Skirmish.new()
	blunt_duel.ai_enabled = false
	var lone_melee := blunt_duel._add_entity(Skirmish.HUMAN, "melee", Vector2i(12, 21))
	var defended_armor := blunt_duel._add_entity(Skirmish.COMPUTER, "armored", Vector2i(13, 21))
	blunt_duel._refresh_visibility()
	check(blunt_duel.issue(Skirmish.HUMAN, "attack", lone_melee, defended_armor).ok and blunt_duel.issue(Skirmish.COMPUTER, "attack", defended_armor, lone_melee).ok,
		"controlled blunt duel uses legal attacks")
	for i in range(250):
		blunt_duel.tick()
	check(not blunt_duel.entities.has(lone_melee) and blunt_duel.entities.has(defended_armor), "armored fighter withstands unsupported melee")
	var piercing_team = Skirmish.new()
	piercing_team.ai_enabled = false
	var first_ranged := piercing_team._add_entity(Skirmish.HUMAN, "ranged", Vector2i(12, 21))
	var second_ranged := piercing_team._add_entity(Skirmish.HUMAN, "ranged", Vector2i(12, 22))
	var countered_armor := piercing_team._add_entity(Skirmish.COMPUTER, "armored", Vector2i(14, 21))
	piercing_team._refresh_visibility()
	check(piercing_team.issue(Skirmish.HUMAN, "attack", first_ranged, countered_armor).ok and piercing_team.issue(Skirmish.HUMAN, "attack", second_ranged, countered_armor).ok and piercing_team.issue(Skirmish.COMPUTER, "attack", countered_armor, first_ranged).ok,
		"piercing counter team uses legal attacks")
	for i in range(250):
		piercing_team.tick()
	check(not piercing_team.entities.has(countered_armor) and (piercing_team.entities.has(first_ranged) or piercing_team.entities.has(second_ranged)),
		"two screened ranged fighters reverse the armored matchup")
	var siege := fight._add_entity(Skirmish.HUMAN, "siege", Vector2i(14, 14))
	var post := fight._find(Skirmish.COMPUTER, "command_post")
	fight._refresh_visibility()
	check(fight.issue(Skirmish.HUMAN, "attack", siege, post).ok, "siege can target visible post")
	var post_hp: int = fight.entities[post].hp
	fight.tick()
	check(fight.entities[post].hp == post_hp and fight.projectiles.size() > 0, "siege projectile travels before impact")
	var payload := Save.capture(fight, "solo_0123456789abcdef0123456789abcdef")
	var restored: Dictionary = Save.restore(payload)
	check(restored.ok and restored.game.projectiles.size() == fight.projectiles.size(), "in-flight projectile and fog survive save")
	for i in range(5):
		fight.tick()
		restored.game.tick()
	check(fight.entities[post].hp < post_hp and restored.game.entities[post].hp == fight.entities[post].hp,
		"restored siege projectile impacts after travel")
	var ballistics = Skirmish.new()
	ballistics.ai_enabled = false
	var shooter := ballistics._add_entity(Skirmish.HUMAN, "ranged", Vector2i(12, 9))
	var runner := ballistics._add_entity(Skirmish.COMPUTER, "worker", Vector2i(14, 9))
	ballistics._refresh_visibility()
	check(ballistics.issue(Skirmish.HUMAN, "attack", shooter, runner).ok, "visible moving target can be attacked")
	ballistics.tick()
	var runner_hp: int = ballistics.entities[runner].hp
	ballistics.entities[runner].pos = Vector2i(14, 10)
	ballistics.entities[shooter].hp = 0
	for i in range(3):
		ballistics.tick()
	check(ballistics.entities[runner].hp == runner_hp and ballistics.projectiles.is_empty(), "in-flight shot misses a moved target even after shooter death")
	var conquest = Skirmish.new()
	conquest.ai_enabled = false
	conquest._add_entity(Skirmish.COMPUTER, "melee", Vector2i(13, 9))
	conquest.entities[conquest._find(Skirmish.COMPUTER, "command_post")].hp = 0
	conquest.tick()
	check(conquest.result == "win" and conquest.result_reason == "command_post" and conquest._find(Skirmish.COMPUTER, "melee") != -1, "last post loss ends Conquest with surviving enemy units")
	var recruitment = Skirmish.new()
	recruitment.ai_enabled = false
	recruitment.age_index[Skirmish.HUMAN] = 2
	for resource_id in Skirmish.RESOURCE_IDS:
		recruitment._add_balance(Skirmish.HUMAN, resource_id, 100)
	var barracks := recruitment._add_entity(Skirmish.HUMAN, "barracks", Vector2i(5, 6))
	check(recruitment.issue(Skirmish.HUMAN, "train", barracks, "armored").ok, "armored role uses normal recruitment")
	check(recruitment.issue(Skirmish.HUMAN, "train", barracks, "siege").ok, "siege role uses normal recruitment")
	for i in range(180):
		recruitment.tick()
	check(recruitment._find(Skirmish.HUMAN, "armored") != -1 and recruitment._find(Skirmish.HUMAN, "siege") != -1, "both roles spawn through production")
	var armored_id := recruitment._find(Skirmish.HUMAN, "armored")
	check(recruitment.issue(Skirmish.HUMAN, "hold", armored_id, "").ok, "hold order uses command validation")
	check(recruitment.issue(Skirmish.HUMAN, "stop", armored_id, "").ok, "stop order uses command validation")
	check(recruitment.issue(Skirmish.HUMAN, "attack_move", armored_id, Vector2i(8, 6)).ok, "attack-move uses path validation")
	var replay = Skirmish.new()
	for i in range(12):
		replay.tick()
	check(Replay.verify(Replay.record(replay)).ok, "versioned rules replay deterministically")
	print("Warfare checks: ", "PASS" if failures == 0 else "%d failures" % failures)
	quit(1 if failures > 0 else 0)

func check(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: ", description)
