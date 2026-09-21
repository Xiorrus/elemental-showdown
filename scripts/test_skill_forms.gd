extends SceneTree

# ==============================================================================
#   TEST SUITE: 3-FORM SKILL PROGRESSION & MID-GAME FORM SWITCHING
#   Elemental Showdown automated verification suite
# ==============================================================================

var total_tests: int = 0
var passed_tests: int = 0
var failed_tests: int = 0

func assert_test(condition: bool, test_name: String):
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % test_name)
	else:
		failed_tests += 1
		printerr("  [FAIL] %s" % test_name)

func _init():
	print("\n========================================================")
	print("   3-FORM SKILL PROGRESSION & MID-GAME SWITCHING SUITE  ")
	print("========================================================\n")
	call_deferred("_run_tests")

func _run_tests():
	await process_frame
	var edata = root.get_node_or_null("ElementData")
	if edata == null:
		edata = load("res://scripts/element_data.gd").new()
		root.add_child(edata)
	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()
		root.add_child(cm)

	# --------------------------------------------------------------------------
	# SUITE 1: 3-Form Integrity Across All 72 Abilities in ElementData
	# --------------------------------------------------------------------------
	print("--- SUITE 1: 3-Form Integrity Across All Abilities ---")
	assert_test(edata.ABILITIES.size() == 72, "T1.1 Exactly 72 abilities defined in ElementData (Found: %d)" % edata.ABILITIES.size())

	var all_have_3_forms = true
	var missing_forms = []
	var invalid_forms = []

	for ab_key in edata.ABILITIES:
		var ab = edata.ABILITIES[ab_key]
		var forms = ab.get("forms", {})
		if forms.size() != 3:
			all_have_3_forms = false
			missing_forms.append("%s (%d forms)" % [ab_key, forms.size()])
		for f_k in forms:
			var f = forms[f_k]
			var has_name = f.has("name") and str(f["name"]).length() > 0
			var has_range = f.has("range") and int(f["range"]) >= 1
			var has_dmg = f.has("dmg_mult") and float(f["dmg_mult"]) >= 0.0
			var has_mp = f.has("mp_mult") and float(f["mp_mult"]) > 0.0
			var has_shape = f.has("shape") and (f["shape"] in ["cardinal", "linear_front", "radial"])
			var has_desc = f.has("desc") and str(f["desc"]).length() > 0
			if not (has_name and has_range and has_dmg and has_mp and has_shape and has_desc):
				invalid_forms.append("%s:%s" % [ab_key, f_k])

	assert_test(all_have_3_forms, "T1.2 Every ability has exactly 3 forms (Missing: %s)" % str(missing_forms))
	assert_test(invalid_forms.is_empty(), "T1.3 All forms have valid name, range, dmg_mult, mp_mult, shape, desc (Invalid: %s)" % str(invalid_forms))

	# Specific key checks
	var gale_step_f = edata.get_skill_forms("Gale_Step")
	assert_test(gale_step_f.keys()[0] == "wind_slip" and gale_step_f["wind_slip"]["name"] == "Wind Slip", "T1.4 Gale Step first form is 'Wind Slip'")
	assert_test(gale_step_f.keys()[1] == "gale_dash", "T1.5 Gale Step second form is 'Gale Dash'")
	assert_test(gale_step_f.keys()[2] == "vortex_screen", "T1.6 Gale Step third form is 'Vortex Screen'")

	var comb_f = edata.get_skill_forms("Combustion")
	assert_test(comb_f.keys()[0] == "punch" and comb_f["punch"]["name"] == "Explosive Punch", "T1.7 Combustion first form is 'Explosive Punch'")

	# --------------------------------------------------------------------------
	# SUITE 2: Starter Skill Form Unlocking in CampaignManager
	# --------------------------------------------------------------------------
	print("\n--- SUITE 2: Campaign Starter Skill Auto-Form Unlock ---")
	cm.new_campaign("Ignis", "fire", "Phoenix Strikers")
	assert_test(cm.unlocked_abilities.has("Combustion"), "T2.1 Starter skill 'Combustion' is unlocked")
	var ignis_unl_forms = cm.get_unlocked_forms_for_skill("Combustion")
	assert_test(ignis_unl_forms.size() == 1 and ignis_unl_forms[0] == "punch", "T2.2 Combustion automatically unlocked with Form 1 ('punch') only")
	assert_test(cm.skill_variations.get("Combustion") == "punch", "T2.3 Active variation initialized to Form 1 ('punch')")

	# --------------------------------------------------------------------------
	# SUITE 3: Unlocking New Skill Node Grants Form 1 Automatically (Free)
	# --------------------------------------------------------------------------
	print("\n--- SUITE 3: New Skill Node Unlocks Form 1 Free ---")
	cm.unspent_skill_points = 5
	assert_test(not cm.unlocked_abilities.has("Laser"), "T3.1 'Laser' is initially locked")
	var unl_res = cm.unlock_skill_node("Laser")
	assert_test(unl_res == true, "T3.2 Successfully unlocked 'Laser' node")
	assert_test(cm.unspent_skill_points == 4, "T3.3 Deducted 1 SP for basic node unlock (Remaining: 4 SP)")
	var laser_unl_forms = cm.get_unlocked_forms_for_skill("Laser")
	assert_test(laser_unl_forms.size() == 1 and laser_unl_forms[0] == "needle", "T3.4 Form 1 ('needle') granted automatically for free")
	assert_test(not laser_unl_forms.has("prism_sweep"), "T3.5 Form 2 ('prism_sweep') remains locked")
	assert_test(not laser_unl_forms.has("flash_flare"), "T3.6 Form 3 ('flash_flare') remains locked")

	# --------------------------------------------------------------------------
	# SUITE 4: Extra SP Spending to Unlock Form 2 and Form 3
	# --------------------------------------------------------------------------
	print("\n--- SUITE 4: Extra SP Spending for Forms 2 & 3 ---")
	# Check unlock validation
	var check_f2 = cm.can_unlock_skill_form("Laser", "prism_sweep")
	assert_test(check_f2.get("can_unlock", false) == true, "T4.1 Can unlock Form 2 ('prism_sweep') with available SP")

	# Unlock Form 2
	var unl_f2 = cm.unlock_skill_form("Laser", "prism_sweep")
	assert_test(unl_f2 == true, "T4.2 Successfully unlocked Form 2 ('prism_sweep')")
	assert_test(cm.unspent_skill_points == 3, "T4.3 SP decremented by 1 (Remaining: 3 SP)")
	assert_test(cm.get_unlocked_forms_for_skill("Laser").has("prism_sweep"), "T4.4 Form 2 now registered in unlocked_skill_forms")
	assert_test(cm.skill_variations.get("Laser") == "prism_sweep", "T4.5 Active variation updated to newly unlocked form")

	# Cannot re-unlock Form 2
	var re_check = cm.can_unlock_skill_form("Laser", "prism_sweep")
	assert_test(re_check.get("can_unlock", false) == false, "T4.6 Cannot re-unlock already unlocked Form 2")

	# Unlock Form 3
	var unl_f3 = cm.unlock_skill_form("Laser", "flash_flare")
	assert_test(unl_f3 == true, "T4.7 Successfully unlocked Form 3 ('flash_flare')")
	assert_test(cm.unspent_skill_points == 2, "T4.8 SP decremented by 1 (Remaining: 2 SP)")
	assert_test(cm.get_unlocked_forms_for_skill("Laser").size() == 3, "T4.9 All 3 forms now unlocked for 'Laser'")

	# --------------------------------------------------------------------------
	# SUITE 5: Form Unlock Restrictions (Locked Skills & Insufficient SP)
	# --------------------------------------------------------------------------
	print("\n--- SUITE 5: Form Unlock Restrictions ---")
	# Cannot unlock form of a locked skill
	var locked_skill_check = cm.can_unlock_skill_form("Destruction", "annihilation_ray")
	assert_test(locked_skill_check.get("can_unlock", false) == false, "T5.1 Cannot unlock form for a locked skill ('Destruction')")

	# Deplete SP to 0
	cm.unspent_skill_points = 0
	var no_sp_check = cm.can_unlock_skill_form("Combustion", "pulse")
	assert_test(no_sp_check.get("can_unlock", false) == false, "T5.2 Cannot unlock form when SP == 0")
	var no_sp_res = cm.unlock_skill_form("Combustion", "pulse")
	assert_test(no_sp_res == false, "T5.3 unlock_skill_form rejected when SP == 0")

	# --------------------------------------------------------------------------
	# SUITE 6: Mid-Combat Dynamic Form Switching (Player Entity)
	# --------------------------------------------------------------------------
	print("\n--- SUITE 6: Mid-Combat Dynamic Form Switching ---")
	var player_script = load("res://scripts/player.gd")
	var player = player_script.new()
	root.add_child(player)
	player.element_db = edata
	player.equipped_abilities = ["Laser"]

	# Case A: Only 1 form unlocked
	cm.unlocked_skill_forms["Laser"] = ["needle"]
	cm.skill_variations["Laser"] = "needle"
	player.active_skill_forms = {"Laser": "needle"}

	var info_f1 = player.get_ability_variation_info("Laser")
	assert_test(info_f1["name"] == "Needle Beam", "T6.1 Initial form is 'Needle Beam'")
	assert_test(info_f1["range_override"] == 5, "T6.2 Needle Beam range is 5")
	assert_test(info_f1["shape"] == "linear_front", "T6.3 Needle Beam shape is 'linear_front'")

	# Attempt cycling with only 1 form unlocked
	player.cycle_skill_form(0)
	var info_after_1 = player.get_ability_variation_info("Laser")
	assert_test(info_after_1["name"] == "Needle Beam", "T6.4 Cycling with 1 form unlocked maintains current form")

	# Case B: All 3 forms unlocked mid-combat
	cm.unlocked_skill_forms["Laser"] = ["needle", "prism_sweep", "flash_flare"]

	# Cycle 1: needle -> prism_sweep
	player.cycle_skill_form(0)
	var info_f2 = player.get_ability_variation_info("Laser")
	assert_test(info_f2["name"] == "Prism Sweep", "T6.5 Cycled form 1 -> form 2 ('Prism Sweep')")
	assert_test(info_f2["range_override"] == 3, "T6.6 Prism Sweep range updated to 3")
	assert_test(info_f2["shape"] == "cardinal", "T6.7 Prism Sweep shape updated to 'cardinal'")
	assert_test(is_equal_approx(info_f2["dmg_mult"], 0.85), "T6.8 Prism Sweep dmg_mult is 0.85")

	# Cycle 2: prism_sweep -> flash_flare
	player.cycle_skill_form(0)
	var info_f3 = player.get_ability_variation_info("Laser")
	assert_test(info_f3["name"] == "Flash Flare", "T6.9 Cycled form 2 -> form 3 ('Flash Flare')")
	assert_test(info_f3["range_override"] == 2, "T6.10 Flash Flare range updated to 2")
	assert_test(info_f3["shape"] == "radial", "T6.11 Flash Flare shape updated to 'radial'")

	# Cycle 3: flash_flare -> needle (wrap around)
	player.cycle_skill_form(0)
	var info_f_wrap = player.get_ability_variation_info("Laser")
	assert_test(info_f_wrap["name"] == "Needle Beam", "T6.12 Cycled form 3 -> form 1 (wrap around)")
	assert_test(info_f_wrap["range_override"] == 5, "T6.13 Needle Beam range restored to 5")

	# --------------------------------------------------------------------------
	# SUITE 7: Save & Load Persistence for Forms
	# --------------------------------------------------------------------------
	print("\n--- SUITE 7: Save & Load Form Persistence ---")
	cm.unlocked_abilities = ["Combustion", "Laser", "Gale_Step"]
	cm.unlocked_skill_forms = {
		"Combustion": ["punch", "pulse"],
		"Laser": ["needle", "prism_sweep", "flash_flare"],
		"Gale_Step": ["wind_slip"]
	}
	cm.skill_variations = {
		"Combustion": "pulse",
		"Laser": "flash_flare",
		"Gale_Step": "wind_slip"
	}
	cm.save_campaign()

	# Create fresh campaign manager to simulate cold boot
	var cm2 = load("res://scripts/campaign_manager.gd").new()
	cm2.load_campaign()

	assert_test(cm2.unlocked_skill_forms.has("Combustion"), "T7.1 Loaded unlocked_skill_forms has 'Combustion'")
	assert_test(cm2.unlocked_skill_forms["Combustion"] == ["punch", "pulse"], "T7.2 Combustion unlocked forms preserved (2 forms)")
	assert_test(cm2.unlocked_skill_forms["Laser"].size() == 3, "T7.3 Laser unlocked forms preserved (3 forms)")
	assert_test(cm2.skill_variations["Laser"] == "flash_flare", "T7.4 Active variation preserved ('flash_flare')")

	# Backward compatibility test: state without unlocked_skill_forms
	var cm3 = load("res://scripts/campaign_manager.gd").new()
	cm3.unlocked_abilities = ["Gale_Step", "Wind"]
	cm3.unlocked_skill_forms = {} # Simulating legacy state
	var legacy_forms = cm3.get_unlocked_forms_for_skill("Gale_Step")
	assert_test(legacy_forms.has("wind_slip"), "T7.5 Legacy state auto-populates Form 1 ('wind_slip') for unlocked skill")

	# --------------------------------------------------------------------------
	# RESULTS SUMMARY
	# --------------------------------------------------------------------------
	print("\n========================================================")
	print("  SKILL FORMS TEST RESULT: %d / %d PASSED (Failed: %d)" % [passed_tests, total_tests, failed_tests])
	print("========================================================\n")

	if failed_tests == 0:
		print("[ALL 3-FORM PROGRESSION TESTS PASSED!]")
		quit(0)
	else:
		printerr("[TEST FAILURES DETECTED!]")
		quit(1)
