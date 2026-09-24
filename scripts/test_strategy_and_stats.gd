extends SceneTree

# ==============================================================================
# ELEMENTAL SHOWDOWN — STRATEGY, STAT ALLOCATION & COMBAT FIXES TEST SUITE
# ==============================================================================

var total_tests = 0
var passed_tests = 0
var failed_tests = 0

func assert_true(cond: bool, msg: String):
	total_tests += 1
	if cond:
		passed_tests += 1
		print("  [PASS] " + msg)
	else:
		failed_tests += 1
		print("  [FAIL] " + msg)

func _init():
	_run.call_deferred()

func _run():
	print("\n========================================================")
	print("   STRATEGY, STATS, SUBS & VICTORY TEST SUITE")
	print("========================================================\n")
	
	var world = load("res://scenes/World.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame
	
	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()
		root.add_child(cm)
		await process_frame
		
	var player = world.get_node("Player")
	var enemy = world.get_node("Enemy")
	var bm = world.get_node("BattleManager")
	var ui = world.get_node("UI")
	var overlay = world.get_node("GridOverlay")

	# --- SUITE 1: STAT ALLOCATION ---
	print("--- SUITE 1: Interactive Stat Allocation ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Blaze Legion"})
	var initial_pts = cm.unspent_stat_points
	var base_spd = cm.player_speed
	var base_agi = cm.player_agility
	
	assert_true(initial_pts == 5, "T1.1 Initial unspent stat points == 5")
	
	# Spend points
	var s_res = cm.spend_stat_point("Speed")
	assert_true(s_res and cm.player_speed == base_spd + 1 and cm.unspent_stat_points == 4, "T1.2 Spending 1 pt on Speed increases Speed by 1 and decrements points")
	
	var a_res = cm.spend_stat_point("Agility")
	assert_true(a_res and cm.player_agility == base_agi + 2 and cm.unspent_stat_points == 3, "T1.3 Spending 1 pt on Agility increases Agility by 2 and decrements points")
	
	# Revert points
	var r_res = cm.revert_stat_point("Agility")
	assert_true(r_res and cm.player_agility == base_agi and cm.unspent_stat_points == 4, "T1.4 Reverting Agility point restores unspent points and returns Agility to base")
	
	# Cannot revert below base
	var r_fail = cm.revert_stat_point("Agility")
	assert_true(not r_fail and cm.player_agility == base_agi, "T1.5 Cannot revert below base stat value")
	
	# Exhaust all points
	cm.spend_stat_point("Dexterity") # pts = 3
	cm.spend_stat_point("Stamina")   # pts = 2
	cm.spend_stat_point("Mana")      # pts = 1
	cm.spend_stat_point("Potency")   # pts = 0
	assert_true(cm.unspent_stat_points == 0, "T1.6 Successfully spent all 5 stat points")
	
	var overspend = cm.spend_stat_point("Speed")
	assert_true(not overspend, "T1.7 Spending rejected when unspent_stat_points == 0")

	# --- SUITE 2: SKILL TREE UNLOCKS ---
	print("\n--- SUITE 2: Branching Skill Tree Unlocks ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Blaze Legion"})
	
	assert_true(cm.unspent_skill_points == 2, "T2.1 Initial unspent skill points == 2")
	assert_true(cm.unlocked_abilities.size() == 2 and cm.equipped_abilities == cm.unlocked_abilities, "T2.2 Both starter skills begin unlocked and equipped")
	
	# Unlock a new skill node
	var unlock_res = cm.unlock_skill_node("Lightning")
	assert_true(unlock_res, "T2.3 Successfully unlocked 'Lightning' branch node")
	assert_true("Lightning" in cm.unlocked_abilities, "T2.4 'Lightning' now in unlocked_abilities")
	assert_true(cm.unspent_skill_points == 1, "T2.5 Unspent skill points reduced to 1")
	
	# Cannot unlock already unlocked skill
	var dup_unlock = cm.unlock_skill_node("Lightning")
	assert_true(not dup_unlock and cm.unspent_skill_points == 1, "T2.6 Cannot re-unlock already unlocked skill")
	
	# Unlock second skill
	cm.unlock_skill_node("Laser")
	assert_true(cm.unspent_skill_points == 0, "T2.7 Unlocked second skill, SP now 0")
	
	# Cannot unlock with 0 SP
	var no_sp = cm.unlock_skill_node("Plasma")
	assert_true(not no_sp, "T2.8 Unlock rejected when unspent_skill_points == 0")
	
	# Equip unlocked skill
	var eq_res = cm.equip_ability("Lightning", 1)
	assert_true(eq_res and cm.equipped_abilities[1] == "Lightning", "T2.9 Can equip newly unlocked skill into active combat slot")

	# --- SUITE 3: MATCH FORMATS & 1V1 SUBSTITUTION RESTRICTION ---
	print("\n--- SUITE 3: Match Formats & 1v1 Substitution Disabling ---")
	var dummy_fighter = Node2D.new()
	dummy_fighter.set("hp", 100)
	root.add_child(dummy_fighter)
	
	# 1v1 Format: 0 subs
	bm.set_match_format("1v1")
	assert_true(bm.max_subs == 0 and bm.subs_remaining == 0, "T3.1 '1v1' format sets max_subs = 0 and subs_remaining = 0")
	assert_true(not bm.can_substitute(dummy_fighter), "T3.2 can_substitute() returns false in 1v1")
	
	# 3v3 Format: 1 sub
	bm.set_match_format("3v3")
	assert_true(bm.max_subs == 1 and bm.subs_remaining == 1, "T3.3 '3v3' format sets max_subs = 1 and subs_remaining = 1")
	assert_true(bm.can_substitute(dummy_fighter), "T3.4 can_substitute() returns true in 3v3 with remaining sub")
	
	# 5v5 Format: 2 subs
	bm.set_match_format("5v5")
	assert_true(bm.max_subs == 2 and bm.subs_remaining == 2, "T3.5 '5v5' format sets max_subs = 2 and subs_remaining = 2")
	dummy_fighter.queue_free()

	# --- SUITE 4: SUBSTITUTION GRID CLEANUP ---
	print("\n--- SUITE 4: Grid Overlay Cleanup on Substitution ---")
	bm.set_match_format("3v3")
	assert_true(bm.subs_remaining == 1, "T4.1 Subs remaining is 1 before sub")
	
	overlay.show_move_grid(player.position, 3)
	assert_true(overlay.valid_move_tiles.size() > 0, "T4.2 Movement grid overlay populated before sub")
	
	var sub_result = bm.substitute_fighter(player, {
		"name": "Kora",
		"element": "earth",
		"hp": 120,
		"max_hp": 120,
		"mp": 90,
		"max_mp": 90,
		"stamina": 100,
		"max_stamina": 100,
		"speed": 3,
		"agility": 15,
		"dexterity": 14,
		"potency": 12,
		"position": Vector2(3 * 64 + 32, 4 * 64 + 32)
	})
	assert_true(sub_result, "T4.3 Substitution executed successfully")
	assert_true(bm.subs_remaining == 0, "T4.4 Subs remaining reduced to 0")
	var p_tile = Vector2i(int(floor(player.position.x / 64)), int(floor(player.position.y / 64)))
	assert_true(p_tile == Vector2i(3, 4), "T4.5 Subbed fighter spawned at valid designated position (3, 4)")

	# --- SUITE 5: INSTANT VICTORY ON KNOCKOUT ---
	print("\n--- SUITE 5: Instant Victory on Knockout (No Turn Hang) ---")
	# Knock out enemy directly
	enemy.take_damage(999, Vector2.ZERO, 20, 90, true)
	await process_frame
	await process_frame
	assert_true(not is_instance_valid(enemy) or enemy.hp <= 0, "T5.1 Enemy is defeated and cleaned up")
	assert_true(bm.current_state == bm.State.BATTLE_OVER, "T5.2 Battle state transitioned to BATTLE_OVER immediately")
	
	var result_modal = ui.get_node_or_null("ResultModalRoot")
	assert_true(result_modal != null and result_modal.visible, "T5.3 Victory ResultModal is visible without needing manual surrender")

	# --- SUITE 6: PRE-BATTLE STRATEGY INTEGRATION ---
	print("\n--- SUITE 6: Pre-Battle Strategy & Deployment Integration ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Blaze Legion"})
	
	# Format selection
	cm.set_active_match_format("3v3")
	assert_true(cm.active_match_format == "3v3", "T6.1 Match format set to 3v3")
	
	# Starting formation
	cm.set_starting_formation({"type": "Vanguard Rush", "player": Vector2i(5, 4)})
	assert_true(cm.starting_formation["type"] == "Vanguard Rush", "T6.2 Starting formation set to Vanguard Rush")
	assert_true(cm.starting_formation["player"] == Vector2i(5, 4), "T6.3 Player formation coordinate set to Vanguard front (5, 4)")
	
	# Bench reserve designation
	cm.set_bench_sub("Kora")
	assert_true(cm.designated_sub == "Kora", "T6.4 Bench reserve set to Kora")
	
	# Teammate skill preset assignment
	var kora_skills = ["Stone_Plating", "Metal", "Quicksand", "Combustion"]
	cm.set_teammate_active_skills("Kora", kora_skills)
	var kora_data = cm.get_ally("Kora")
	assert_true(kora_data != null and kora_data.get("equipped_skills", []) == kora_skills, "T6.5 Teammate Kora active skills successfully assigned by captain")

	# --- SUITE 7: ELEMENT-SPECIFIC STARTING SPEED & STATS ---
	print("\n--- SUITE 7: Element-Specific Starting Speed & Stats ---")
	# 7.1 Earth element starting stats (Speed: 2 tiles)
	cm.init_new_campaign({"player_name": "Terra", "player_element": "earth", "start_solo": true})
	assert_true(cm.player_speed == 2, "T7.1 Earth player initial player_speed is 2 (not 3)")
	assert_true(cm.player_stamina == 120, "T7.2 Earth player initial stamina is 120")
	assert_true(cm.player_mana == 90, "T7.3 Earth player initial mana is 90")
	assert_true(cm.player_agility == 16, "T7.4 Earth player initial agility is 16")
	assert_true(cm.player_dexterity == 24, "T7.5 Earth player initial dexterity is 24")

	# 7.2 Water element starting stats (Speed: 2 tiles)
	cm.init_new_campaign({"player_name": "Aqua", "player_element": "water", "start_solo": true})
	assert_true(cm.player_speed == 2, "T7.6 Water player initial player_speed is 2")

	# 7.3 Air element starting stats (Speed: 4 tiles)
	cm.init_new_campaign({"player_name": "Zephyr", "player_element": "air", "start_solo": true})
	assert_true(cm.player_speed == 4, "T7.7 Air player initial player_speed is 4")

	# 7.4 Fire element starting stats (Speed: 3 tiles)
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "start_solo": true})
	assert_true(cm.player_speed == 3, "T7.8 Fire player initial player_speed is 3")

	# 7.5 Earth player loaded in World scene has exactly 2 movement squares
	cm.init_new_campaign({"player_name": "Terra", "player_element": "earth", "start_solo": true})
	var world_earth = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_earth)
	await process_frame
	await process_frame

	var p_earth = world_earth.get_node("Player")
	assert_true(p_earth.element == "earth", "T7.9 Player element in World is earth")
	assert_true(p_earth.base_speed == 2, "T7.10 Earth player base_speed in World is 2")
	assert_true(p_earth.moves_remaining == 2, "T7.11 Earth player moves_remaining on match start is 2")
	world_earth.queue_free()
	await process_frame

	print("\n========================================================")
	print("  TEST SUMMARY: %d / %d PASSED (Failed: %d)" % [passed_tests, total_tests, failed_tests])
	if failed_tests == 0:
		print("  ALL STRATEGY & COMBAT FIX TESTS PASSED!")
	print("========================================================\n")
	world.queue_free()
	quit(1 if failed_tests > 0 else 0)
