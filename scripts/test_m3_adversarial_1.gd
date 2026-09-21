# test_m3_adversarial_1.gd
# Empirical Adversarial Stress Test Suite for Milestone 3/4/5:
# - Statistical distribution of generated stats across Tiers 1-5 (100+ fighters per tier)
# - Potential distribution and exact boundary values (1, 39, 40, 74, 75, 100)
# - Extreme career lifecycle tests (multiple tier promotions, demotions, repeated transfer windows, stat evolution)
# - Solo start edge cases (attempting 3v3 match when solo, street win counter, squad transition)
# - AST / Source code verification (scan world.gd for ANY duplicate() calls, verify Player.tscn instantiation)
#
# Run with: Godot_console.exe --headless -s scripts/test_m3_adversarial_1.gd
extends SceneTree

var _pass := 0
var _fail := 0

func _assert(label: String, condition: bool, details: String = "") -> void:
	if condition:
		print("  [PASS] %s" % label)
		_pass += 1
	else:
		var err_msg = "  [FAIL] %s" % label
		if details != "":
			err_msg += " (" + details + ")"
		print(err_msg)
		_fail += 1

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	print("\n========================================================")
	print("   ADVERSARIAL STRESS TEST SUITE — MILESTONE 3 / 4 / 5")
	print("========================================================")

	await process_frame
	await process_frame

	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = root.get_node_or_null("/root/CampaignManager")
	if cm == null:
		printerr("[ERROR] CampaignManager AutoLoad not found — aborting.")
		quit(1)
		return

	# ──────────────────────────────────────────────────────────
	# SECTION 1: Statistical Distribution Across Tiers 1–5
	# ──────────────────────────────────────────────────────────
	print("\n--- SECTION 1: Statistical Distribution Across Tiers 1–5 (120 fighters/tier) ---")
	var expected_tier_bounds = {
		1: {"hp_min": 70,  "hp_max": 100, "mp_min": 80,  "mp_max": 110, "spd_min": 2, "spd_max": 3, "agi_min": 16, "agi_max": 28, "dex_min": 20, "dex_max": 30, "sta_min": 80,  "sta_max": 110, "lvl_min": 1,  "lvl_max": 5},
		2: {"hp_min": 90,  "hp_max": 120, "mp_min": 100, "mp_max": 130, "spd_min": 3, "spd_max": 4, "agi_min": 24, "agi_max": 36, "dex_min": 26, "dex_max": 38, "sta_min": 100, "sta_max": 130, "lvl_min": 6,  "lvl_max": 12},
		3: {"hp_min": 110, "hp_max": 145, "mp_min": 120, "mp_max": 150, "spd_min": 3, "spd_max": 5, "agi_min": 32, "agi_max": 48, "dex_min": 32, "dex_max": 46, "sta_min": 120, "sta_max": 150, "lvl_min": 13, "lvl_max": 22},
		4: {"hp_min": 130, "hp_max": 170, "mp_min": 140, "mp_max": 180, "spd_min": 4, "spd_max": 5, "agi_min": 44, "agi_max": 60, "dex_min": 42, "dex_max": 55, "sta_min": 140, "sta_max": 170, "lvl_min": 23, "lvl_max": 35},
		5: {"hp_min": 160, "hp_max": 200, "mp_min": 170, "mp_max": 210, "spd_min": 5, "spd_max": 6, "agi_min": 56, "agi_max": 72, "dex_min": 52, "dex_max": 68, "sta_min": 160, "sta_max": 200, "lvl_min": 36, "lvl_max": 50},
	}

	var archetypes = ["Striker", "Scout", "Defender", "Support"]
	var elements = ["fire", "water", "earth", "air"]

	for tier in range(1, 6):
		var tb = expected_tier_bounds[tier]
		var total_samples = 120
		var all_within_bounds = true
		var violation_detail = ""
		var base_stats_mirrored = true
		var archetype_covered = {}
		var element_covered = {}

		var min_obs = {"hp": 9999, "mp": 9999, "spd": 9999, "agi": 9999, "dex": 9999, "sta": 9999, "lvl": 9999, "pot": 9999}
		var max_obs = {"hp": -1, "mp": -1, "spd": -1, "agi": -1, "dex": -1, "sta": -1, "lvl": -1, "pot": -1}

		for i in range(total_samples):
			var arch = archetypes[i % archetypes.size()]
			var elem = elements[i % elements.size()]
			var f = cm.generate_athlete(tier, arch, elem)

			archetype_covered[f.get("archetype", "")] = true
			element_covered[f.get("element", "")] = true

			var hp = f["hp"]
			var mp = f["mp"]
			var spd = f["speed"]
			var agi = f["agility"]
			var dex = f["dexterity"]
			var sta = f["stamina"]
			var lvl = f["level"]
			var pot = f["potential"]

			# Record min/max observed
			min_obs["hp"] = min(min_obs["hp"], hp)
			max_obs["hp"] = max(max_obs["hp"], hp)
			min_obs["mp"] = min(min_obs["mp"], mp)
			max_obs["mp"] = max(max_obs["mp"], mp)
			min_obs["spd"] = min(min_obs["spd"], spd)
			max_obs["spd"] = max(max_obs["spd"], spd)
			min_obs["agi"] = min(min_obs["agi"], agi)
			max_obs["agi"] = max(max_obs["agi"], agi)
			min_obs["dex"] = min(min_obs["dex"], dex)
			max_obs["dex"] = max(max_obs["dex"], dex)
			min_obs["sta"] = min(min_obs["sta"], sta)
			max_obs["sta"] = max(max_obs["sta"], sta)
			min_obs["lvl"] = min(min_obs["lvl"], lvl)
			max_obs["lvl"] = max(max_obs["lvl"], lvl)
			min_obs["pot"] = min(min_obs["pot"], pot)
			max_obs["pot"] = max(max_obs["pot"], pot)

			# Strict bounds check
			if hp < tb.hp_min or hp > tb.hp_max:
				all_within_bounds = false
				violation_detail = "Tier %d HP %d out of [%d, %d]" % [tier, hp, tb.hp_min, tb.hp_max]
				break
			if mp < tb.mp_min or mp > tb.mp_max:
				all_within_bounds = false
				violation_detail = "Tier %d MP %d out of [%d, %d]" % [tier, mp, tb.mp_min, tb.mp_max]
				break
			if spd < tb.spd_min or spd > tb.spd_max:
				all_within_bounds = false
				violation_detail = "Tier %d Speed %d out of [%d, %d]" % [tier, spd, tb.spd_min, tb.spd_max]
				break
			if agi < tb.agi_min or agi > tb.agi_max:
				all_within_bounds = false
				violation_detail = "Tier %d Agility %d out of [%d, %d]" % [tier, agi, tb.agi_min, tb.agi_max]
				break
			if dex < tb.dex_min or dex > tb.dex_max:
				all_within_bounds = false
				violation_detail = "Tier %d Dex %d out of [%d, %d]" % [tier, dex, tb.dex_min, tb.dex_max]
				break
			if sta < tb.sta_min or sta > tb.sta_max:
				all_within_bounds = false
				violation_detail = "Tier %d Sta %d out of [%d, %d]" % [tier, sta, tb.sta_min, tb.sta_max]
				break
			if lvl < tb.lvl_min or lvl > tb.lvl_max:
				all_within_bounds = false
				violation_detail = "Tier %d Level %d out of [%d, %d]" % [tier, lvl, tb.lvl_min, tb.lvl_max]
				break
			if pot < 1 or pot > 100:
				all_within_bounds = false
				violation_detail = "Tier %d Potential %d out of [1, 100]" % [tier, pot]
				break

			# base_stats dictionary parity check
			var bs = f.get("base_stats", {})
			if bs.get("hp", -1) != hp or bs.get("mp", -1) != mp or bs.get("speed", -1) != spd \
				or bs.get("agility", -1) != agi or bs.get("dexterity", -1) != dex or bs.get("stamina", -1) != sta:
				base_stats_mirrored = false

		_assert("S1.T%d.1 All 120 Tier %d fighters respect min/max stat constraints strictly" % [tier, tier],
			all_within_bounds, violation_detail)
		_assert("S1.T%d.2 Tier %d base_stats dictionary perfectly mirrors top-level keys" % [tier, tier],
			base_stats_mirrored)
		_assert("S1.T%d.3 Tier %d stats demonstrate dynamic range (non-constant distribution)" % [tier, tier],
			max_obs["hp"] > min_obs["hp"] and max_obs["mp"] > min_obs["mp"] and max_obs["lvl"] > min_obs["lvl"],
			"Obs HP: [%d, %d], MP: [%d, %d]" % [min_obs["hp"], max_obs["hp"], min_obs["mp"], max_obs["mp"]])

	# ──────────────────────────────────────────────────────────
	# SECTION 2: Potential Distribution and Boundary Values
	# ──────────────────────────────────────────────────────────
	print("\n--- SECTION 2: Potential Distribution & Boundary Value Invariants ---")
	# Boundary value exact mapping:
	# Journeyman: 1 to 39
	# Rising Star: 40 to 74
	# Prodigy: 75 to 100
	_assert("S2.1 Potential = 1 -> Journeyman (floor)", cm.get_potential_label(1) == "Journeyman")
	_assert("S2.2 Potential = 39 -> Journeyman (ceiling)", cm.get_potential_label(39) == "Journeyman")
	_assert("S2.3 Potential = 40 -> Rising Star (floor)", cm.get_potential_label(40) == "Rising Star")
	_assert("S2.4 Potential = 74 -> Rising Star (ceiling)", cm.get_potential_label(74) == "Rising Star")
	_assert("S2.5 Potential = 75 -> Prodigy (floor)", cm.get_potential_label(75) == "Prodigy")
	_assert("S2.6 Potential = 100 -> Prodigy (ceiling)", cm.get_potential_label(100) == "Prodigy")

	# Boundary edge cases (0, out-of-range):
	_assert("S2.7 Potential = 0 maps safely to Journeyman", cm.get_potential_label(0) == "Journeyman")
	_assert("S2.8 Potential = -10 maps safely to Journeyman", cm.get_potential_label(-10) == "Journeyman")
	_assert("S2.9 Potential = 150 maps safely to Prodigy", cm.get_potential_label(150) == "Prodigy")
	_assert("S2.10 get_potential_tier_label alias matches get_potential_label exactly",
		cm.get_potential_tier_label(50) == cm.get_potential_label(50))

	# Potential Distribution Across Large Sample (300 athletes):
	var pot_counts = {"Journeyman": 0, "Rising Star": 0, "Prodigy": 0}
	var min_pot_found = 999
	var max_pot_found = -1

	for _i in range(300):
		var f = cm.generate_athlete(1)
		var p = f["potential"]
		min_pot_found = min(min_pot_found, p)
		max_pot_found = max(max_pot_found, p)
		var lbl = cm.get_potential_label(p)
		if pot_counts.has(lbl):
			pot_counts[lbl] += 1

	_assert("S2.11 All potential categories populated in 300-fighter generation sample",
		pot_counts["Journeyman"] > 30 and pot_counts["Rising Star"] > 30 and pot_counts["Prodigy"] > 20,
		"Counts: Journeyman=%d, RisingStar=%d, Prodigy=%d" % [pot_counts["Journeyman"], pot_counts["Rising Star"], pot_counts["Prodigy"]])
	_assert("S2.12 Potential bounds strictly observed across 300 samples [1, 100]",
		min_pot_found >= 1 and max_pot_found <= 100,
		"Min pot: %d, Max pot: %d" % [min_pot_found, max_pot_found])

	# ──────────────────────────────────────────────────────────
	# SECTION 3: Extreme Career Lifecycle Tests
	# ──────────────────────────────────────────────────────────
	print("\n--- SECTION 3: Extreme Career Lifecycle & Stat Evolution ---")

	# Successive Promotions: Tier 1 -> 2 -> 3 -> 4 -> 5
	cm.init_new_campaign({"name": "ApexCaptain", "element": "fire"})
	cm.allies.clear()
	# Seed 5 fighters with distinct potentials:
	# Captain: 95 (survives all)
	# Low1: 15 (retires at T2, cutoff 40 and pot < 20)
	# Low2: 35 (free agent at T2, cutoff 40)
	# Mid: 50 (survives T2, departs at T3 cutoff 60)
	# High: 80 (survives T2, T3, T4 cutoff 75, departs at T5 cutoff 85)
	# Super: 90 (survives all tiers T2, T3, T4, T5)
	var captain = {
		"name": "ApexCaptain", "element": "fire", "role": "Captain", "archetype": "Striker",
		"level": 1, "league_tier": 1, "potential": 95, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 85, "mp": 90, "stamina": 95, "speed": 3, "agility": 22, "dexterity": 25},
		"hp": 85, "mp": 90, "stamina": 95, "speed": 3, "agility": 22, "dexterity": 25,
		"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
	}
	var low1 = {
		"name": "LowPot1", "element": "water", "role": "Support", "archetype": "Support",
		"level": 1, "league_tier": 1, "potential": 15, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 75, "mp": 85, "stamina": 85, "speed": 2, "agility": 18, "dexterity": 21},
		"hp": 75, "mp": 85, "stamina": 85, "speed": 2, "agility": 18, "dexterity": 21,
		"equipped_skills": ["Aqua_Mend"], "known_skills": ["Aqua_Mend"]
	}
	var low2 = {
		"name": "LowPot2", "element": "earth", "role": "Defender", "archetype": "Defender",
		"level": 2, "league_tier": 1, "potential": 35, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 95, "mp": 80, "stamina": 100, "speed": 2, "agility": 17, "dexterity": 22},
		"hp": 95, "mp": 80, "stamina": 100, "speed": 2, "agility": 17, "dexterity": 22,
		"equipped_skills": ["Stone_Plating"], "known_skills": ["Stone_Plating"]
	}
	var mid = {
		"name": "MidPot", "element": "air", "role": "Scout", "archetype": "Scout",
		"level": 3, "league_tier": 1, "potential": 50, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 80, "mp": 95, "stamina": 90, "speed": 3, "agility": 25, "dexterity": 24},
		"hp": 80, "mp": 95, "stamina": 90, "speed": 3, "agility": 25, "dexterity": 24,
		"equipped_skills": ["Gale_Step"], "known_skills": ["Gale_Step"]
	}
	var high = {
		"name": "HighPot", "element": "fire", "role": "Striker", "archetype": "Striker",
		"level": 4, "league_tier": 1, "potential": 80, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 90, "mp": 100, "stamina": 95, "speed": 3, "agility": 26, "dexterity": 28},
		"hp": 90, "mp": 100, "stamina": 95, "speed": 3, "agility": 26, "dexterity": 28,
		"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
	}
	var super_pot = {
		"name": "SuperPot", "element": "earth", "role": "Anchor", "archetype": "Defender",
		"level": 4, "league_tier": 1, "potential": 90, "status": "Active", "career_team": "Phoenix Strikers",
		"base_stats": {"hp": 98, "mp": 85, "stamina": 105, "speed": 2, "agility": 20, "dexterity": 26},
		"hp": 98, "mp": 85, "stamina": 105, "speed": 2, "agility": 20, "dexterity": 26,
		"equipped_skills": ["Stone_Plating"], "known_skills": ["Stone_Plating"]
	}

	cm.allies = [captain, low1, low2, mid, high, super_pot]

	# Step 1: Promote to Tier 2 (Silver, threshold = 40)
	var p2 = cm.promote_team_tier(2)
	_assert("S3.1 Promotion to Tier 2 succeeds", p2["success"] and cm.league_tier == 2)
	_assert("S3.2 LowPot1 (< 40) left in Tier 2 promotion", p2["left"].has("LowPot1"))
	_assert("S3.3 LowPot2 (< 40) left in Tier 2 promotion", p2["left"].has("LowPot2"))
	_assert("S3.4 MidPot (50 >= 40) stayed in Tier 2 promotion", p2["stayed"].has("MidPot"))
	_assert("S3.5 HighPot (80 >= 40) stayed in Tier 2 promotion", p2["stayed"].has("HighPot"))
	_assert("S3.6 SuperPot (90 >= 40) stayed in Tier 2 promotion", p2["stayed"].has("SuperPot"))

	# Step 2: Promote to Tier 3 (Gold, threshold = 60)
	var p3 = cm.promote_team_tier(3)
	_assert("S3.7 Promotion to Tier 3 succeeds", p3["success"] and cm.league_tier == 3)
	_assert("S3.8 MidPot (50 < 60) left in Tier 3 promotion", p3["left"].has("MidPot"))
	_assert("S3.9 HighPot (80 >= 60) stayed in Tier 3 promotion", p3["stayed"].has("HighPot"))
	_assert("S3.10 SuperPot (90 >= 60) stayed in Tier 3 promotion", p3["stayed"].has("SuperPot"))

	# Step 3: Promote to Tier 4 (Diamond, threshold = 75)
	var p4 = cm.promote_team_tier(4)
	_assert("S3.11 Promotion to Tier 4 succeeds", p4["success"] and cm.league_tier == 4)
	_assert("S3.12 HighPot (80 >= 75) stayed in Tier 4 promotion", p4["stayed"].has("HighPot"))
	_assert("S3.13 SuperPot (90 >= 75) stayed in Tier 4 promotion", p4["stayed"].has("SuperPot"))

	# Step 4: Promote to Tier 5 (Apex, threshold = 85)
	var p5 = cm.promote_team_tier(5)
	_assert("S3.14 Promotion to Tier 5 succeeds", p5["success"] and cm.league_tier == 5)
	_assert("S3.15 HighPot (80 < 85) left in Tier 5 promotion", p5["left"].has("HighPot"))
	_assert("S3.16 SuperPot (90 >= 85) stayed in Tier 5 promotion", p5["stayed"].has("SuperPot"))
	_assert("S3.17 ApexCaptain (Player) stayed across all promotions", p5["stayed"].has("ApexCaptain"))

	# Verify Tier 5 stats of surviving SuperPot and Captain
	var super_t5 = cm.get_ally("SuperPot")
	_assert("S3.18 SuperPot evolved to Tier 5 stats (HP in [160, 200])",
		super_t5["hp"] >= 160 and super_t5["hp"] <= 200, "HP=%d" % super_t5["hp"])
	_assert("S3.19 SuperPot evolved to Tier 5 Level (Level in [36, 50])",
		super_t5["level"] >= 36 and super_t5["level"] <= 50, "Level=%d" % super_t5["level"])

	# Demotion test: promote_team_tier(1) clamps safely
	var demote_res = cm.promote_team_tier(1)
	_assert("S3.20 Calling promote_team_tier(1) clamps without crash and retains team",
		demote_res["success"] and cm.league_tier == 1)

	# Repeated transfer windows: 10 consecutive executions
	print("\n--- Repeated Transfer Windows (10 cycles) ---")
	var transfer_ok = true
	var min_roster_size = 99
	var max_roster_size = -1
	for window_idx in range(10):
		var tw = cm.run_transfer_window()
		if not tw.get("success", false):
			transfer_ok = false
			break
		var cur_size = cm.allies.size()
		min_roster_size = min(min_roster_size, cur_size)
		max_roster_size = max(max_roster_size, cur_size)

		# Ensure player is never lost
		var player_found = false
		for a in cm.allies:
			if a["name"] == cm.player_name:
				player_found = true
				break
		if not player_found:
			transfer_ok = false
			break

	_assert("S3.21 10 consecutive transfer windows complete successfully", transfer_ok)
	_assert("S3.22 Roster size never exceeds MAX_ROSTER_SIZE (10) or drops below 3",
		max_roster_size <= 10 and min_roster_size >= 3,
		"Min size: %d, Max size: %d" % [min_roster_size, max_roster_size])

	# Stat evolution test via evolve_athlete
	var raw_fighter = cm.generate_athlete(1)
	var evolved_t4 = cm.evolve_athlete(raw_fighter, 4)
	_assert("S3.23 evolve_athlete(fighter, 4) produces Tier 4 athlete",
		evolved_t4["league_tier"] == 4)
	_assert("S3.24 evolve_athlete strictly bounds evolved HP into Tier 4 range [130, 170]",
		evolved_t4["hp"] >= 130 and evolved_t4["hp"] <= 170, "Evolved HP=%d" % evolved_t4["hp"])
	_assert("S3.25 evolve_athlete does not mutate input athlete dictionary",
		raw_fighter["league_tier"] == 1, "Raw Tier=%d" % raw_fighter["league_tier"])

	# ──────────────────────────────────────────────────────────
	# SECTION 4: Solo Start Edge Cases
	# ──────────────────────────────────────────────────────────
	print("\n--- SECTION 4: Solo Start Edge Cases & Win Progression ---")
	cm.init_new_campaign({"name": "LoneBrawler", "element": "earth", "start_solo": true})

	_assert("S4.1 Solo start correctly initializes 0 allies", cm.allies.size() == 0)
	_assert("S4.2 Solo start match format defaults to '1v1'", cm.active_match_format == "1v1")
	_assert("S4.3 Solo start career_team is 'Free Agent'", cm.career_team == "Free Agent")

	# Edge Case A: Attempting 3v3 match when solo
	# Even if active_match_format is artificially set to "3v3", World scene should instantiate cleanly
	# and fallback logic should safely supply allies without crash
	cm.active_match_format = "3v3"
	var world_scene = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scene)
	await process_frame
	await process_frame

	var world_valid = is_instance_valid(world_scene)
	var bm = world_scene.get_node_or_null("BattleManager")
	_assert("S4.4 World scene instantiates cleanly in 3v3 even when campaign started solo",
		world_valid and bm != null)
	_assert("S4.5 World spawns combatants without null errors during solo 3v3 launch",
		bm != null and bm.player_units.size() >= 1)

	world_scene.queue_free()
	await process_frame

	# Edge Case B: Street Win Counter Progression
	cm.init_new_campaign({"name": "SoloStreak", "element": "fire", "start_solo": true})
	var win1 = cm.record_street_win()
	_assert("S4.6 Street win 1 returns false and increments counter", not win1 and cm.street_wins == 1)
	_assert("S4.7 has_team remains false after win 1", not cm.has_team)

	var win2 = cm.record_street_win()
	_assert("S4.8 Street win 2 returns false and increments counter", not win2 and cm.street_wins == 2)
	_assert("S4.9 has_team remains false after win 2", not cm.has_team)

	var win3 = cm.record_street_win()
	_assert("S4.10 Street win 3 triggers recruitment and returns true", win3 and cm.street_wins == 3)
	_assert("S4.11 has_team transitions to true after win 3", cm.has_team)
	_assert("S4.12 active_match_format transitions to '3v3'", cm.active_match_format == "3v3")
	_assert("S4.13 Roster populated with 3–5 allies after recruitment",
		cm.allies.size() >= 3 and cm.allies.size() <= 5)
	_assert("S4.14 designated_sub assigned to an athlete on the roster",
		cm.designated_sub != "" and cm.get_ally(cm.designated_sub).size() > 0)

	var win4 = cm.record_street_win()
	_assert("S4.15 Subsequent win 4 returns false (does not re-trigger recruitment)",
		not win4 and cm.street_wins == 4)
	var win5 = cm.record_street_win()
	_assert("S4.16 Subsequent win 5 returns false", not win5 and cm.street_wins == 5)

	# ──────────────────────────────────────────────────────────
	# SECTION 5: AST / Source Code Verification
	# ──────────────────────────────────────────────────────────
	print("\n--- SECTION 5: AST / Source Code Verification (scripts/world.gd) ---")
	var world_file = FileAccess.open("res://scripts/world.gd", FileAccess.READ)
	_assert("S5.1 scripts/world.gd opened successfully", world_file != null)

	if world_file:
		var world_text = world_file.get_as_text()
		world_file.close()

		# Check 1: Zero player.duplicate() calls
		_assert("S5.2 scripts/world.gd contains zero 'player.duplicate()'",
			not world_text.contains("player.duplicate()"))

		# Check 2: Zero node.duplicate() calls
		_assert("S5.3 scripts/world.gd contains zero 'node.duplicate()'",
			not world_text.contains("node.duplicate()"))

		# Check 3: Detailed scan for ANY .duplicate() calls
		var lines = world_text.split("\n")
		var duplicate_calls: Array = []
		for line_idx in range(lines.size()):
			var line = lines[line_idx]
			if line.contains(".duplicate("):
				duplicate_calls.append({"line_num": line_idx + 1, "text": line.strip_edges()})

		print("  [INFO] Found %d .duplicate() calls in scripts/world.gd" % duplicate_calls.size())
		var node_duplicates_found = 0
		for dc in duplicate_calls:
			print("    Line %d: %s" % [dc.line_num, dc.text])
			# Extract the receiver token immediately preceding .duplicate(
			var dup_idx = dc.text.find(".duplicate(")
			var prefix = dc.text.substr(0, dup_idx).strip_edges()
			# If there is an assignment '=', take right-hand side
			if prefix.contains("="):
				var eq_parts = prefix.split("=")
				prefix = eq_parts[eq_parts.size() - 1].strip_edges()
			
			var is_node = prefix == "player" or prefix == "enemy" or prefix == "node" \
				or prefix == "self" or prefix == "ally_unit" or prefix == "extra_enemy"
			if is_node:
				node_duplicates_found += 1
				print("    [ALERT] Node duplicate detected at Line %d: receiver='%s'" % [dc.line_num, prefix])
			else:
				print("    [OK] Data collection duplicate at Line %d: receiver='%s'" % [dc.line_num, prefix])

		_assert("S5.4 All .duplicate() calls in world.gd are strictly data/array copies, ZERO node duplicates",
			node_duplicates_found == 0, "Found %d node duplicates" % node_duplicates_found)

		# Check 4: Preload and instantiation of Player.tscn
		_assert("S5.5 scripts/world.gd preloads 'res://scenes/Player.tscn'",
			world_text.contains('preload("res://scenes/Player.tscn")'))
		_assert("S5.6 scripts/world.gd instantiates PLAYER_SCENE via .instantiate()",
			world_text.contains("PLAYER_SCENE.instantiate()"))

		# Check 5: Player.tscn existence and cleanliness
		_assert("S5.7 res://scenes/Player.tscn exists on disk",
			ResourceLoader.exists("res://scenes/Player.tscn"))

		var player_scene_res = load("res://scenes/Player.tscn")
		_assert("S5.8 res://scenes/Player.tscn loads as PackedScene",
			player_scene_res is PackedScene)

		if player_scene_res:
			var player_instance = player_scene_res.instantiate()
			_assert("S5.9 Player.tscn instance is a CharacterBody2D",
				player_instance is CharacterBody2D)
			var script_path = player_instance.get_script().resource_path if player_instance.get_script() else ""
			_assert("S5.10 Player.tscn script is res://scripts/player.gd",
				script_path == "res://scripts/player.gd")
			player_instance.queue_free()

		# Check 6: Enemy element_db wiring strictly after add_child()
		var add_child_enemy_pos = world_text.find("add_child(extra_enemy)")
		var wire_edata_enemy_pos = world_text.find("extra_enemy.element_db = edata")
		_assert("S5.11 extra_enemy wired with element_db strictly AFTER add_child()",
			add_child_enemy_pos > 0 and wire_edata_enemy_pos > add_child_enemy_pos,
			"add_child pos: %d, wire pos: %d" % [add_child_enemy_pos, wire_edata_enemy_pos])

	print("\n========================================================")
	print("  ADVERSARIAL SUITE RESULT: %d PASS / %d FAIL / %d TOTAL" % [_pass, _fail, _pass + _fail])
	print("========================================================")

	if _fail == 0:
		print(">> [ADVERSARIAL VERDICT: ALL TESTS PASSED EMPIRICALLY]")
	else:
		printerr(">> [ADVERSARIAL VERDICT: FAILURES DETECTED (%d failed)]" % _fail)

	quit(_fail)
