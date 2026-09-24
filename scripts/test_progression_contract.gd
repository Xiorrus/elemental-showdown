extends SceneTree

# Match results alone grant saved career XP. Skills come from the SP tree.
var passed := 0
var failed := 0

class ProgressUI extends Node:
	var latest_level := 0
	var latest_xp := -1
	var latest_threshold := 0
	var result_xp := -1
	func update_xp(level: int, xp: int, threshold: int):
		latest_level = level
		latest_xp = xp
		latest_threshold = threshold
	func show_battle_result(_victory: bool, xp_gained: int, _turns: int):
		result_xp = xp_gained

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _run():
	var safe_root = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(safe_root):
		printerr("Redirect APPDATA beneath this project's .godot directory before running save tests.")
		quit(2)
		return

	var cm = root.get_node("CampaignManager")
	cm.init_new_campaign({"player_name": "Progression", "player_element": "fire", "start_solo": true})
	cm.player_xp = 90
	var starter_skills: Array = cm.unlocked_abilities.duplicate()

	var arena = Node2D.new()
	root.add_child(arena)
	var ui = ProgressUI.new()
	ui.name = "UI"
	arena.add_child(ui)
	var player = load("res://scenes/Player.tscn").instantiate()
	arena.add_child(player)
	player.ui = ui
	player.unlocked_abilities = cm.unlocked_abilities.duplicate()
	player.equipped_abilities = cm.equipped_abilities.duplicate()
	player.sync_campaign_progression(cm)
	var bm = load("res://scripts/battle_manager.gd").new()
	arena.add_child(bm)
	bm.player = player

	check(not player.has_method("gain_xp") and not player.has_method("accept_skill_offer") and not ui.has_method("show_skill_offer"),
		"Combat has no XP or free-skill offer path")
	player.equip_ability("Laser")
	check(player.equipped_abilities == starter_skills, "Combat cannot equip a skill that was not bought")

	bm.player_wins()
	check(cm.player_level == 2 and cm.player_xp == 50 and cm.unspent_skill_points == 3,
		"Victory grants 60 XP once and one SP at the campaign level threshold")
	check(player.level == cm.player_level and player.xp == cm.player_xp and player.xp_to_next_level == cm.player_xp_to_next,
		"Combat player mirrors the saved campaign level and XP")
	check(ui.latest_level == 2 and ui.latest_xp == 50 and ui.latest_threshold == cm.player_xp_to_next and ui.result_xp == 60,
		"Battle HUD and result display the same progression")
	check(cm.unlocked_abilities == starter_skills and player.unlocked_abilities == starter_skills,
		"A level-up does not grant a skill")
	check(cm.load_campaign() and cm.player_level == 2 and cm.player_xp == 50 and cm.unspent_skill_points == 3,
		"Campaign level, XP, and SP survive reload")

	cm.init_new_campaign({"player_name": "Defeat XP", "player_element": "water", "start_solo": true})
	cm.player_xp = 95
	player.sync_campaign_progression(cm)
	bm.current_state = bm.State.PLAYER_MOVE
	bm.player_loses()
	check(cm.player_level == 2 and cm.player_xp == 5 and cm.unspent_skill_points == 3 and ui.result_xp == 10,
		"Defeat grants and displays the actual 10 XP rather than the nominal 25")
	check(player.level == 2 and player.xp == 5,
		"The player mirror also updates after defeat")

	arena.free()
	print("PROGRESSION CONTRACT: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
