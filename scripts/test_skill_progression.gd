# test_skill_progression.gd
# Dedicated comprehensive test suite for the Skill Tree Radial Mandala & Branching Progression System.
# Verifies:
# 1. Level 1 basic skill gate (Tier 2/3/4 rejected at Lv 1).
# 2. Prerequisite enforcement (child cannot unlock before parent).
# 3. SP check and deduction (rejected at 0 SP, exact cost deducted).
# 4. Multiple prerequisites convergence (e.g. Destruction).
# 5. Space progression branch independence.
# 6. Time progression branch independence.
# 7. Core elements multi-branch independent progression.
# 8. Combination discipline access gate (e.g. Steam locked until Fire + Water available).
# 9. Combination internal tree independence once unlocked.
# 10. Form variation switching and storage.
# 11. Save/load persistence of unlocked abilities, SP, and affinities.
extends SceneTree

func _init():
	_run.call_deferred()

func _run():
	print("\n========================================================")
	print("   SKILL TREE RADIAL MANDALA & PROGRESSION TEST SUITE   ")
	print("========================================================\n")

	var counts = {"passed": 0, "failed": 0}

	var check = func(condition: bool, test_name: String, details: String = ""):
		if condition:
			print("  [PASS] %s" % test_name)
			counts["passed"] += 1
		else:
			print("  [FAIL] %s %s" % [test_name, details])
			counts["failed"] += 1

	await process_frame

	# Ensure autoloads
	var edata = root.get_node_or_null("ElementData")
	if edata == null:
		edata = load("res://scripts/element_data.gd").new()
		root.add_child(edata)

	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()
		root.add_child(cm)
		await process_frame

	# --- SUITE 1: LEVEL 1 BASIC SKILL GATE ---
	print("--- SUITE 1: Level 1 Basic Skill Gate & Tier Restrictions ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
	cm.unspent_skill_points = 10
	cm.player_level = 1

	# Level 1 player can unlock basic tier skill
	var chk_basic = cm.can_unlock_skill("Lightning")
	check.call(chk_basic.get("can_unlock", false), "T1.1 Level 1 player CAN unlock Tier 1 basic skill (Lightning)")

	# Level 1 player CANNOT unlock advanced tier skill (Plasma, requires Lv 6)
	var chk_adv = cm.can_unlock_skill("Plasma")
	check.call(not chk_adv.get("can_unlock", true) and chk_adv.get("reason", "").contains("Requires Player Level 6"),
		"T1.2 Level 1 player CANNOT unlock Advanced skill (Plasma requires Lv 6)",
		"reason: %s" % chk_adv.get("reason", ""))

	# Level 1 player CANNOT unlock mastery tier skill (Nuclear_Ignition, requires Lv 15)
	var chk_mast = cm.can_unlock_skill("Nuclear_Ignition")
	check.call(not chk_mast.get("can_unlock", true) and chk_mast.get("reason", "").contains("Requires Player Level 15"),
		"T1.3 Level 1 player CANNOT unlock Mastery skill (Nuclear Ignition requires Lv 15)",
		"reason: %s" % chk_mast.get("reason", ""))

	# Level 1 player CANNOT unlock pinnacle tier skill (Destruction, requires Lv 25)
	var chk_pinn = cm.can_unlock_skill("Destruction")
	check.call(not chk_pinn.get("can_unlock", true) and chk_pinn.get("reason", "").contains("Requires Player Level 25"),
		"T1.4 Level 1 player CANNOT unlock Pinnacle skill (Destruction requires Lv 25)",
		"reason: %s" % chk_pinn.get("reason", ""))

	# --- SUITE 2: PREREQUISITE ENFORCEMENT ---
	print("\n--- SUITE 2: Prerequisite Graph Enforcement ---")
	cm.player_level = 30 # Overcome level gate to isolate prerequisite checks

	# Laser is basic root. Plasma requires Laser.
	# With Laser locked, Plasma must be rejected
	cm.unlocked_abilities = ["Combustion"]
	var chk_plasma_no_laser = cm.can_unlock_skill("Plasma")
	check.call(not chk_plasma_no_laser.get("can_unlock", true) and chk_plasma_no_laser.get("reason", "").contains("Laser"),
		"T2.1 Cannot unlock Plasma without prerequisite Laser unlocked",
		"reason: %s" % chk_plasma_no_laser.get("reason", ""))

	# Unlock Laser -> Now Plasma becomes available
	var unl_laser = cm.unlock_skill_node("Laser")
	check.call(unl_laser and cm.unlocked_abilities.has("Laser"), "T2.2 Successfully unlocked prerequisite Laser")
	var chk_plasma_with_laser = cm.can_unlock_skill("Plasma")
	check.call(chk_plasma_with_laser.get("can_unlock", false), "T2.3 Plasma is now available to unlock after Laser is unlocked")

	# --- SUITE 3: SKILL POINT SUFFICIENCY & DEDUCTION ---
	print("\n--- SUITE 3: Skill Points (SP) Gating & Deduction ---")
	cm.unspent_skill_points = 0
	var chk_zero_sp = cm.can_unlock_skill("Plasma")
	check.call(not chk_zero_sp.get("can_unlock", true) and chk_zero_sp.get("reason", "").contains("Requires 1 SP"),
		"T3.1 Cannot unlock Plasma with 0 SP",
		"reason: %s" % chk_zero_sp.get("reason", ""))

	cm.unspent_skill_points = 1
	var unl_plasma = cm.unlock_skill_node("Plasma")
	check.call(unl_plasma and cm.unspent_skill_points == 0, "T3.2 Unlocking Plasma deducts 1 SP (Remaining: 0 SP)")

	# Pinnacle skills cost 2 SP
	cm.unspent_skill_points = 1
	cm.unlocked_abilities.append("Photonic_Burst") # satisfy second prereq for Destruction
	var chk_pinn_sp = cm.can_unlock_skill("Destruction")
	check.call(not chk_pinn_sp.get("can_unlock", true) and chk_pinn_sp.get("reason", "").contains("Requires 2 SP"),
		"T3.3 Pinnacle skill Destruction requires 2 SP (1 SP insufficient)",
		"reason: %s" % chk_pinn_sp.get("reason", ""))

	cm.unspent_skill_points = 2
	var unl_dest = cm.unlock_skill_node("Destruction")
	check.call(unl_dest and cm.unspent_skill_points == 0, "T3.4 Unlocking Destruction deducts 2 SP (Remaining: 0 SP)")

	# --- SUITE 4: MULTI-PREREQUISITE CONVERGENCE ---
	print("\n--- SUITE 4: Multi-Prerequisite Convergence ---")
	# Reset
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
	cm.player_level = 30
	cm.unspent_skill_points = 10
	# Destruction requires BOTH Plasma AND Photonic_Burst
	cm.unlocked_abilities = ["Combustion", "Laser", "Plasma"] # Missing Photonic_Burst
	var chk_missing_one = cm.can_unlock_skill("Destruction")
	check.call(not chk_missing_one.get("can_unlock", true) and chk_missing_one.get("reason", "").contains("Photonic Burst"),
		"T4.1 Destruction rejected when only 1 of 2 prerequisites is met (Missing Photonic Burst)",
		"reason: %s" % chk_missing_one.get("reason", ""))

	cm.unlocked_abilities.append("Photonic_Burst")
	var chk_all_met = cm.can_unlock_skill("Destruction")
	check.call(chk_all_met.get("can_unlock", false), "T4.2 Destruction allowed when ALL prerequisites (Plasma + Photonic Burst) are met")

	# --- SUITE 5: SPACE PROGRESSION BRANCH ---
	print("\n--- SUITE 5: Space Primordial Progression Branch ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
	cm.player_level = 30
	cm.unspent_skill_points = 10

	# Spatial_Shift is starter root (no prereqs)
	check.call(cm.can_unlock_skill("Spatial_Shift").get("can_unlock", false), "T5.1 Space root Spatial_Shift can be unlocked without prerequisites")
	cm.unlock_skill_node("Spatial_Shift")

	# Spatial_Compression and Spatial_Barrier both depend on Spatial_Shift
	check.call(cm.can_unlock_skill("Spatial_Compression").get("can_unlock", false), "T5.2 Spatial_Compression available after Spatial_Shift")
	check.call(cm.can_unlock_skill("Spatial_Barrier").get("can_unlock", false), "T5.3 Spatial_Barrier available after Spatial_Shift")
	cm.unlock_skill_node("Spatial_Compression")
	cm.unlock_skill_node("Spatial_Barrier")

	# Pinnacle Space requires Spatial_Compression and Spatial_Barrier
	check.call(cm.can_unlock_skill("Space").get("can_unlock", false), "T5.4 Pinnacle Space available after both Tier 2 space techniques unlocked")
	cm.unlock_skill_node("Space")
	check.call(cm.unlocked_abilities.has("Space"), "T5.5 Pinnacle Space successfully unlocked in player abilities")

	# --- SUITE 6: TIME PROGRESSION BRANCH ---
	print("\n--- SUITE 6: Time Primordial Progression Branch ---")
	# Time_Dilation is starter root (no prereqs)
	check.call(cm.can_unlock_skill("Time_Dilation").get("can_unlock", false), "T6.1 Time root Time_Dilation can be unlocked independently of Space")
	cm.unlock_skill_node("Time_Dilation")

	# Chrono_Acceleration and Temporal_Decay depend on Time_Dilation
	check.call(cm.can_unlock_skill("Chrono_Acceleration").get("can_unlock", false), "T6.2 Chrono_Acceleration available after Time_Dilation")
	check.call(cm.can_unlock_skill("Temporal_Decay").get("can_unlock", false), "T6.3 Temporal_Decay available after Time_Dilation")
	cm.unlock_skill_node("Chrono_Acceleration")
	cm.unlock_skill_node("Temporal_Decay")

	# Pinnacle Chrono_Stasis requires Chrono_Acceleration and Temporal_Decay
	check.call(cm.can_unlock_skill("Chrono_Stasis").get("can_unlock", false), "T6.4 Pinnacle Chrono_Stasis available after both Tier 2 time techniques unlocked")
	cm.unlock_skill_node("Chrono_Stasis")
	check.call(cm.unlocked_abilities.has("Chrono_Stasis"), "T6.5 Pinnacle Chrono_Stasis successfully unlocked in player abilities")

	# --- SUITE 7: COMBINATION DISCIPLINE ACCESS GATING ---
	print("\n--- SUITE 7: Combination Discipline Access Gating ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
	cm.unlocked_elements = ["fire"] # Player only has fire affinity

	# Steam requires ["fire", "water"]
	var chk_steam_locked = cm.can_access_discipline("steam")
	check.call(not chk_steam_locked.get("can_access", true) and chk_steam_locked.get("reason", "").contains("Water"),
		"T7.1 Steam discipline access LOCKED when player only has Fire (Missing: Water)",
		"reason: %s" % chk_steam_locked.get("reason", ""))

	# Attempting to unlock Steam skill directly fails discipline check
	var chk_steam_skill = cm.can_unlock_skill("Steam_Vent")
	check.call(not chk_steam_skill.get("can_unlock", true) and chk_steam_skill.get("reason", "").contains("Discipline locked"),
		"T7.2 Cannot unlock Steam_Vent skill while Steam discipline is locked",
		"reason: %s" % chk_steam_skill.get("reason", ""))

	# Now grant Water affinity (e.g. recruit water athlete)
	cm.unlocked_elements.append("water")
	var chk_steam_unlocked = cm.can_access_discipline("steam")
	check.call(chk_steam_unlocked.get("can_access", false), "T7.3 Steam discipline access UNLOCKED after acquiring Water affinity")

	# Now Steam_Vent can be unlocked!
	cm.unspent_skill_points = 5
	var chk_steam_skill_open = cm.can_unlock_skill("Steam_Vent")
	check.call(chk_steam_skill_open.get("can_unlock", false), "T7.4 Steam_Vent is now available for unlocking")

	# --- SUITE 8: COMBINATION INTERNAL PROGRESSION ---
	print("\n--- SUITE 8: Combination Internal Progression Tree ---")
	cm.player_level = 20
	cm.unlock_skill_node("Steam_Vent")
	check.call(cm.unlocked_abilities.has("Steam_Vent"), "T8.1 Unlocked Steam Tier 1 (Steam_Vent)")

	# Tier 2 Superheated_Scald requires Steam_Vent
	check.call(cm.can_unlock_skill("Superheated_Scald").get("can_unlock", false), "T8.2 Superheated_Scald available after Steam_Vent")
	cm.unlock_skill_node("Superheated_Scald")

	# Tier 3 Superheated_Steam requires Superheated_Scald
	check.call(cm.can_unlock_skill("Superheated_Steam").get("can_unlock", false), "T8.3 Superheated_Steam available after Superheated_Scald")
	cm.unlock_skill_node("Superheated_Steam")
	check.call(cm.unlocked_abilities.has("Superheated_Steam"), "T8.4 Mastery Superheated_Steam successfully unlocked")

	# --- SUITE 9: FORM VARIATION SWITCHING ---
	print("\n--- SUITE 9: Form Variation Selection & Persistence ---")
	cm.skill_variations["Combustion"] = "Explosion Outburst"
	check.call(cm.skill_variations.get("Combustion") == "Explosion Outburst", "T9.1 Active form variation set to 'Explosion Outburst'")

	# --- SUITE 10: SAVE & LOAD PERSISTENCE ---
	print("\n--- SUITE 10: Save & Load Persistence ---")
	cm.unspent_skill_points = 7
	var pre_skills = cm.unlocked_abilities.duplicate()
	var pre_elements = cm.unlocked_elements.duplicate()
	var pre_variations = cm.skill_variations.duplicate()

	var save_ok = cm.save_campaign()
	check.call(save_ok, "T10.1 Saved campaign state to disk")

	# Clear runtime state
	cm.unlocked_abilities = []
	cm.unlocked_elements = []
	cm.unspent_skill_points = 0
	cm.skill_variations = {}

	# Load state back
	var load_ok = cm.load_campaign()
	check.call(load_ok, "T10.2 Loaded campaign state from disk")
	check.call(cm.unspent_skill_points == 7, "T10.3 Unspent SP restored accurately (7 SP)")
	check.call(cm.unlocked_abilities == pre_skills, "T10.4 Unlocked abilities restored completely (%d skills)" % cm.unlocked_abilities.size())
	check.call(cm.unlocked_elements == pre_elements, "T10.5 Unlocked elements restored completely (%s)" % str(cm.unlocked_elements))
	check.call(cm.skill_variations == pre_variations, "T10.6 Skill variations restored completely")

	# --- SUITE 11: SKILL TREE CANVAS INSTANTIATION & RENDERING ---
	print("\n--- SUITE 11: SkillTreeCanvas Component Verification ---")
	var canvas = load("res://scripts/skill_tree_canvas.gd").new()
	root.add_child(canvas)
	await process_frame
	await process_frame

	check.call(canvas != null, "T11.1 SkillTreeCanvas successfully instantiated")
	check.call(canvas.discipline_buttons.has("space_time"), "T11.2 Center Space/Time split medallion initialized")
	check.call(canvas.discipline_buttons.has("fire"), "T11.3 Core discipline 'fire' button initialized")
	check.call(canvas.discipline_buttons.has("steam"), "T11.4 Combination discipline 'steam' button initialized")

	# Focus fire discipline
	canvas.focus_discipline("fire")
	await process_frame
	await process_frame

	check.call(canvas.focused_discipline == "fire", "T11.5 Canvas focused on 'fire' discipline")
	check.call(not canvas.skill_node_widgets.is_empty(), "T11.6 Procedural skill node widgets spawned for Fire (%d nodes)" % canvas.skill_node_widgets.size())
	check.call(canvas.btn_back.visible == true, "T11.7 'Back to Disciplines' button visible when focused")

	# Inspect skill without unlocking
	var sp_before_inspect = cm.unspent_skill_points
	canvas.inspect_skill("Combustion")
	check.call(cm.unspent_skill_points == sp_before_inspect, "T11.8 Inspecting skill does NOT deduct SP (Safety confirmed)")

	# --- SUITE 12: TRIPLE ELEMENT COMBINATIONS & EXPANDED MANDALA ---
	print("\n--- SUITE 12: Triple Element Combinations & Outermost Ring ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
	cm.allies = []
	cm.unlocked_elements = ["fire", "water"] # Missing earth
	cm.player_level = 30
	cm.unspent_skill_points = 10

	# 12.1 Gating: Fire + Water + Earth locked when missing Earth
	var chk_triple_locked = cm.can_access_discipline("fire_water_earth")
	check.call(not chk_triple_locked.get("can_access", true) and chk_triple_locked.get("reason", "").contains("Earth"),
		"T12.1 Triple discipline Fire + Water + Earth locked when missing Earth",
		"reason: %s" % chk_triple_locked.get("reason", ""))

	# 12.2 Unlock after acquiring all 3 elements
	cm.unlocked_elements.append("earth")
	var chk_triple_unlocked = cm.can_access_discipline("fire_water_earth")
	check.call(chk_triple_unlocked.get("can_access", false), "T12.2 Triple discipline unlocked after acquiring Earth")

	# 12.3 Internal triple tree progression: Ore Synthesis -> Acid Dissolution -> Geothermal Obsidian
	check.call(cm.can_unlock_skill("Ore_Synthesis").get("can_unlock", false), "T12.3 Ore Synthesis (Tier 1) available to unlock")
	cm.unlock_skill_node("Ore_Synthesis")
	check.call(cm.can_unlock_skill("Acid_Dissolution").get("can_unlock", false), "T12.4 Acid Dissolution (Tier 2) available after Ore Synthesis")
	cm.unlock_skill_node("Acid_Dissolution")
	check.call(cm.can_unlock_skill("Geothermal_Obsidian").get("can_unlock", false), "T12.5 Geothermal Obsidian (Tier 3) available after Acid Dissolution")
	cm.unlock_skill_node("Geothermal_Obsidian")
	check.call(cm.unlocked_abilities.has("Geothermal_Obsidian"), "T12.6 Geothermal Obsidian successfully unlocked")

	# 12.4 Outermost ring buttons in SkillTreeCanvas
	var canvas2 = load("res://scripts/skill_tree_canvas.gd").new()
	root.add_child(canvas2)
	await process_frame
	await process_frame
	check.call(canvas2.discipline_buttons.has("fire_water_earth"), "T12.7 Outermost ring has 'fire_water_earth' button")
	check.call(canvas2.discipline_buttons.has("fire_water_air"), "T12.8 Outermost ring has 'fire_water_air' button")
	check.call(canvas2.discipline_buttons.has("fire_earth_air"), "T12.9 Outermost ring has 'fire_earth_air' button")
	check.call(canvas2.discipline_buttons.has("water_earth_air"), "T12.10 Outermost ring has 'water_earth_air' button")
	
	# 12.5 Focus triple discipline
	canvas2.focus_discipline("fire_water_earth")
	await process_frame
	await process_frame
	check.call(canvas2.focused_discipline == "fire_water_earth", "T12.11 Canvas focused on triple discipline")
	check.call(canvas2.skill_node_widgets.has("Geothermal_Obsidian"), "T12.12 Geothermal Obsidian widget present in tree")
	
	canvas2.queue_free()
	await process_frame

	print("\n========================================================")
	print("  SKILL PROGRESSION RESULT: %d / %d PASSED (Failed: %d)" % [counts["passed"], counts["passed"] + counts["failed"], counts["failed"]])
	print("========================================================\n")

	if counts["failed"] == 0:
		print("[ALL SKILL PROGRESSION TESTS PASSED!]")
		quit(0)
	else:
		print("[SOME PROGRESSION TESTS FAILED!]")
		quit(1)
