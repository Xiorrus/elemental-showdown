# test_fighter_generation.gd
# Headless test suite for the Fighter Generation & Career Lifecycle system (R3).
# Verifies all 7 Acceptance Criteria from ORIGINAL_REQUEST.md (lines 206–213).
# Run with: Godot_console.exe --headless -s scripts/test_fighter_generation.gd
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
	print("   FIGHTER GENERATION & CAREER LIFECYCLE ACCEPTANCE SUITE")
	print("========================================================")

	# Wait frames so AutoLoads are ready
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
	# CRITERION 1: New campaign -> player solo, no allies, tier 1
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 1: Solo Start Initialization ---")
	cm.init_new_campaign({"name": "SoloHero", "element": "fire", "start_solo": true})

	_assert("C1.1 Solo start sets has_team = false", cm.has_team == false)
	_assert("C1.2 Solo start initializes empty allies roster", cm.allies.is_empty())
	_assert("C1.3 Solo start sets league_tier = 1", cm.league_tier == 1)
	_assert("C1.4 Solo start sets career_team = 'Free Agent'", cm.career_team == "Free Agent")
	_assert("C1.5 Solo start sets active_match_format = '1v1'", cm.active_match_format == "1v1")
	_assert("C1.6 Solo start sets street_wins = 0", cm.street_wins == 0)

	# Also verify init_new_campaign positional overload with start_solo = true
	cm.init_new_campaign("PosHero", "air", "", true)
	_assert("C1.7 Positional init with start_solo=true sets allies.is_empty()", cm.allies.is_empty())
	_assert("C1.8 Positional init sets has_team = false and tier = 1", cm.has_team == false and cm.league_tier == 1)

	# ──────────────────────────────────────────────────────────
# CRITERION 2: Recruitment offer -> explicit acceptance -> 3–5 tier-1 fighters
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 2: Team Recruitment & Tier-1 Stat Ranges ---")
	# Start fresh solo campaign
	cm.init_new_campaign({"name": "Rookie", "element": "fire", "start_solo": true})

	# Win 3 street matches to reach recruitment threshold
	var w1 = cm.record_street_win()
	var w2 = cm.record_street_win()
	var w3 = cm.record_street_win()

	_assert("C2.1 Win 1 & 2 do not trigger an offer", not w1 and not w2)
	_assert("C2.2 Win 3 creates a pending offer", w3 and cm.recruitment_offer_pending)
	_assert("C2.3 A pending offer does not silently recruit fighters", cm.allies.is_empty() and not cm.has_team)
	_assert("C2.4 A pending offer keeps solo format", cm.active_match_format == "1v1")
	var accepted_offer = cm.accept_recruitment_offer()
	_assert("C2.5 Player can explicitly accept the recruitment offer", accepted_offer and not cm.recruitment_offer_pending)
	_assert("C2.6 Accepted offer creates a captain plus recruited teammates", cm.allies.size() >= 4 and cm.allies.size() <= 6
		and not cm.get_ally(cm.player_name).is_empty(), "size=%d" % cm.allies.size())
	_assert("C2.7 Acceptance joins a team and changes to 3v3", cm.has_team and cm.active_match_format == "3v3")
	_assert("C2.8 The same offer cannot be accepted twice", not cm.accept_recruitment_offer())

	# Verify the generated recruits adhere to Tier 1 bounds. The captain keeps
	# their existing player stats, which have a separate progression curve.
	# Tier 1 bounds from ORIGINAL_REQUEST.md line 130:
	# HP: 70–100, MP: 80–110, Speed: 2–3, Agility: 16–28, Dex: 20–30, Stamina: 80–110, Level: 1–5
	var all_stats_valid = true
	var stat_failure_detail = ""
	for f in cm.allies:
		if f.get("name", "") == cm.player_name:
			continue
		if f.get("league_tier", 0) != 1:
			all_stats_valid = false
			stat_failure_detail = "%s invalid tier %s" % [f.get("name"), str(f.get("league_tier"))]
			break
		if f["hp"] < 70 or f["hp"] > 100:
			all_stats_valid = false
			stat_failure_detail = "%s HP %d out of [70, 100]" % [f.get("name"), f["hp"]]
			break
		if f["mp"] < 80 or f["mp"] > 110:
			all_stats_valid = false
			stat_failure_detail = "%s MP %d out of [80, 110]" % [f.get("name"), f["mp"]]
			break
		if f["speed"] < 2 or f["speed"] > 3:
			all_stats_valid = false
			stat_failure_detail = "%s Speed %d out of [2, 3]" % [f.get("name"), f["speed"]]
			break
		if f["agility"] < 16 or f["agility"] > 28:
			all_stats_valid = false
			stat_failure_detail = "%s Agility %d out of [16, 28]" % [f.get("name"), f["agility"]]
			break
		if f["dexterity"] < 20 or f["dexterity"] > 30:
			all_stats_valid = false
			stat_failure_detail = "%s Dexterity %d out of [20, 30]" % [f.get("name"), f["dexterity"]]
			break
		if f["stamina"] < 80 or f["stamina"] > 110:
			all_stats_valid = false
			stat_failure_detail = "%s Stamina %d out of [80, 110]" % [f.get("name"), f["stamina"]]
			break
		if f["level"] < 1 or f["level"] > 5:
			all_stats_valid = false
			stat_failure_detail = "%s Level %d out of [1, 5]" % [f.get("name"), f["level"]]
			break
	_assert("C2.9 All recruited fighters have stats strictly inside Tier 1 ranges", all_stats_valid, stat_failure_detail)

	# ──────────────────────────────────────────────────────────
	# CRITERION 3: Each fighter has a unique name and potential score in 1–100
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 3: Unique Names, Potential Scores & Tier Labels ---")
	var names_dict = {}
	var names_unique = true
	var potential_in_range = true
	var potential_failure_detail = ""

	for f in cm.allies:
		var n = f.get("name", "")
		if n == "" or names_dict.has(n):
			names_unique = false
		names_dict[n] = true

		var pot = f.get("potential", -1)
		if pot < 1 or pot > 100:
			potential_in_range = false
			potential_failure_detail = "%s potential %d out of [1, 100]" % [n, pot]

	_assert("C3.1 All fighters have unique names", names_unique)
	_assert("C3.2 All fighters have potential score in 1–100", potential_in_range, potential_failure_detail)

	# Also test a larger roster generation batch for uniqueness
	var batch = cm.generate_team_roster(1, 5)
	var batch_names = {}
	var batch_unique = true
	for f in batch:
		if batch_names.has(f["name"]):
			batch_unique = false
		batch_names[f["name"]] = true
	_assert("C3.3 Batch generation of 5 fighters produces 5 unique names", batch_unique and batch.size() == 5)

	# Verify potential tier labels per specification:
	# Journeyman: 1–39, Rising Star: 40–74, Prodigy: 75–100
	_assert("C3.4 get_potential_label(1) -> Journeyman", cm.get_potential_label(1) == "Journeyman")
	_assert("C3.5 get_potential_label(39) -> Journeyman", cm.get_potential_label(39) == "Journeyman")
	_assert("C3.6 get_potential_label(40) -> Rising Star", cm.get_potential_label(40) == "Rising Star")
	_assert("C3.7 get_potential_label(74) -> Rising Star", cm.get_potential_label(74) == "Rising Star")
	_assert("C3.8 get_potential_label(75) -> Prodigy", cm.get_potential_label(75) == "Prodigy")
	_assert("C3.9 get_potential_label(100) -> Prodigy", cm.get_potential_label(100) == "Prodigy")

	# ──────────────────────────────────────────────────────────
	# CRITERION 4: Save/load cycle preserves all profiles including potential
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 4: Save/Load Preservation of Athlete Profiles ---")
	cm.init_new_campaign({"name": "SaveHero", "element": "earth", "team_name": "TerraGuard"})
	cm.league_tier = 2
	cm.street_wins = 5
	cm.has_team = true

	# Set up specific known athletes in allies with distinct potentials
	cm.allies = [
		{
			"name": "SaveHero", "element": "earth", "role": "Captain", "archetype": "Defender",
			"level": 6, "league_tier": 2, "potential": 92, "status": "Active", "career_team": "TerraGuard",
			"hp": 110, "mp": 105, "stamina": 120, "speed": 3, "agility": 26, "dexterity": 28,
			"base_stats": {"hp": 110, "mp": 105, "stamina": 120, "speed": 3, "agility": 26, "dexterity": 28},
			"equipped_skills": ["Stone_Plating", "Metal"], "known_skills": ["Stone_Plating", "Metal", "Crystal"]
		},
		{
			"name": "Aria", "element": "air", "role": "Scout", "archetype": "Scout",
			"level": 8, "league_tier": 2, "potential": 45, "status": "Active", "career_team": "TerraGuard",
			"hp": 95, "mp": 120, "stamina": 105, "speed": 4, "agility": 34, "dexterity": 30,
			"base_stats": {"hp": 95, "mp": 120, "stamina": 105, "speed": 4, "agility": 34, "dexterity": 30},
			"equipped_skills": ["Gale_Step"], "known_skills": ["Gale_Step", "Wind"]
		},
		{
			"name": "Boran", "element": "water", "role": "Support", "archetype": "Support",
			"level": 7, "league_tier": 2, "potential": 81, "status": "Reserve", "career_team": "TerraGuard",
			"hp": 100, "mp": 125, "stamina": 110, "speed": 3, "agility": 28, "dexterity": 26,
			"base_stats": {"hp": 100, "mp": 125, "stamina": 110, "speed": 3, "agility": 28, "dexterity": 26},
			"equipped_skills": ["Aqua_Mend"], "known_skills": ["Aqua_Mend", "Ice"]
		}
	]
	cm.known_fighters = [
		{"name": "VeteranRival", "element": "fire", "potential": 77, "career_team": "BlazeCorp"}
	]
	cm.skill_variations["Combustion"] = "Explosive Punch"

	var save_res = cm.save_campaign()
	_assert("C4.1 save_campaign() returns true", save_res)

	# Wipe state
	cm.allies = []
	cm.known_fighters = []
	cm.league_tier = 1
	cm.has_team = false
	cm.skill_variations = {}

	var load_res = cm.load_campaign()
	_assert("C4.2 load_campaign() returns true", load_res)
	_assert("C4.3 league_tier restored to 2", cm.league_tier == 2)
	_assert("C4.4 has_team restored to true", cm.has_team == true)
	_assert("C4.5 allies roster size restored (3)", cm.allies.size() == 3)

	# Check individual athlete profiles and potentials
	var hero = cm.get_ally("SaveHero")
	var aria = cm.get_ally("Aria")
	var boran = cm.get_ally("Boran")

	_assert("C4.6 SaveHero potential preserved (92)", hero.get("potential") == 92)
	_assert("C4.7 Aria potential preserved (45)", aria.get("potential") == 45)
	_assert("C4.8 Boran potential preserved (81)", boran.get("potential") == 81)
	_assert("C4.9 Aria stats and equipped skills preserved", aria.get("speed") == 4 and aria.get("equipped_skills") == ["Gale_Step"])
	_assert("C4.10 known_fighters preserved", cm.known_fighters.size() == 1 and cm.known_fighters[0]["potential"] == 77)

	# ──────────────────────────────────────────────────────────
	# CRITERION 5: Tier promotion removes below-threshold fighters and adds higher-tier replacements
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 5: Career Lifecycle Tier Promotion ---")
	# Set up tier 1 team:
	# Tier 2 promotion threshold is potential >= 40.
	# LowPot (< 40) must leave. HighPot (>= 40) must stay and develop.
	cm.league_tier = 1
	cm.allies = [
		{
			"name": "CaptainHero", "element": "fire", "role": "Captain", "archetype": "Striker",
			"level": 4, "league_tier": 1, "potential": 90, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 90, "mp": 100, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 30,
			"base_stats": {"hp": 90, "mp": 100, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 30},
			"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
		},
		{
			"name": "LowPotFighter", "element": "water", "role": "Scout", "archetype": "Scout",
			"level": 3, "league_tier": 1, "potential": 25, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 75, "mp": 85, "stamina": 85, "speed": 2, "agility": 20, "dexterity": 22,
			"base_stats": {"hp": 75, "mp": 85, "stamina": 85, "speed": 2, "agility": 20, "dexterity": 22},
			"equipped_skills": ["Aqua_Mend"], "known_skills": ["Aqua_Mend"]
		},
		{
			"name": "HighPotFighter", "element": "earth", "role": "Defender", "archetype": "Defender",
			"level": 5, "league_tier": 1, "potential": 78, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 98, "mp": 90, "stamina": 105, "speed": 2, "agility": 18, "dexterity": 24,
			"base_stats": {"hp": 98, "mp": 90, "stamina": 105, "speed": 2, "agility": 18, "dexterity": 24},
			"equipped_skills": ["Stone_Plating"], "known_skills": ["Stone_Plating"]
		}
	]

	var prev_roster_count = cm.allies.size()
	var promo_result = cm.promote_team_tier(2)

	_assert("C5.1 promote_team_tier returns promotion summary", promo_result.has("stayed") and promo_result.has("left") and promo_result.has("joined"))
	_assert("C5.2 LowPotFighter (pot=25 < 40) is in left list", promo_result["left"].has("LowPotFighter"))
	_assert("C5.3 HighPotFighter (pot=78 >= 40) is in stayed list", promo_result["stayed"].has("HighPotFighter"))
	_assert("C5.4 CaptainHero is in stayed list", promo_result["stayed"].has("CaptainHero"))
	_assert("C5.5 New higher-tier replacement is in joined list", promo_result["joined"].size() >= 1)
	_assert("C5.6 Roster size is preserved", cm.allies.size() == prev_roster_count)
	_assert("C5.7 cm.league_tier updated to 2", cm.league_tier == 2)

	# Verify replacement fighters have tier 2 stats:
	# Tier 2 HP: 90–120, MP: 100–130, Speed: 3–4, Agi: 24–36, Dex: 26–38, Sta: 100–130, Lvl: 6–12
	var replacements = cm.allies.filter(func(a): return promo_result["joined"].has(a["name"]))
	var repl_valid = true
	var repl_detail = ""
	for r in replacements:
		if r["league_tier"] != 2:
			repl_valid = false
			repl_detail = "%s tier %d != 2" % [r["name"], r["league_tier"]]
			break
		if r["hp"] < 90 or r["hp"] > 120:
			repl_valid = false
			repl_detail = "%s HP %d not in [90, 120]" % [r["name"], r["hp"]]
			break
		if r["speed"] < 3 or r["speed"] > 4:
			repl_valid = false
			repl_detail = "%s Speed %d not in [3, 4]" % [r["name"], r["speed"]]
			break
		if r["level"] < 6 or r["level"] > 12:
			repl_valid = false
			repl_detail = "%s Level %d not in [6, 12]" % [r["name"], r["level"]]
			break
	_assert("C5.8 Replacement fighters have valid Tier 2 stats and level", repl_valid, repl_detail)

	# Verify surviving HighPotFighter developed stats into Tier 2
	var surviving_high = cm.get_ally("HighPotFighter")
	_assert("C5.9 HighPotFighter updated to league_tier 2", surviving_high.get("league_tier") == 2)
	_assert("C5.10 HighPotFighter level increased into Tier 2 range (>= 6)", surviving_high.get("level") >= 6)

	# ──────────────────────────────────────────────────────────
	# CRITERION 6: Ally units spawned in world.gd match stored profile, not _ready() defaults
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 6: World Scene Spawning & Athlete Profile Stat Sync ---")
	cm.init_new_campaign({"player_name": "CaptainIgnis", "player_element": "fire", "team_name": "Phoenix Strikers"})
	cm.active_match_format = "3v3"
	cm.prepare_match("tournament", "water", "Nami", "Hydro Vipers")

	# Configure allies with custom non-default stats and non-default equipped skills:
	# Air element default basic skill is "Gale_Step", default stamina is 100, default HP is 80.
	# We assign custom: HP 88, MP 118, Stamina 112, Speed 4, Agility 36, Dexterity 29, equipped: ["Sound_Sonic", "Wind"]
	# Earth element default basic skill is "Stone_Plating", default stamina is 100, default HP is 130.
	# We assign custom: HP 138, MP 94, Stamina 126, Speed 2, Agility 17, Dexterity 25, equipped: ["Sand", "Metal"]
	cm.allies = [
		{
			"name": "CaptainIgnis", "element": "fire", "role": "Captain", "archetype": "Striker",
			"level": 2, "league_tier": 1, "potential": 85, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 92, "mp": 102, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 32,
			"base_stats": {"hp": 92, "mp": 102, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 32},
			"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
		},
		{
			"name": "Kora", "element": "air", "role": "Scout", "archetype": "Scout",
			"level": 2, "league_tier": 1, "potential": 78, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 88, "mp": 118, "stamina": 112, "speed": 4, "agility": 36, "dexterity": 29,
			"base_stats": {"hp": 88, "mp": 118, "stamina": 112, "speed": 4, "agility": 36, "dexterity": 29},
			"equipped_skills": ["Sound_Sonic", "Wind"], "known_skills": ["Sound_Sonic", "Wind", "Gale_Step"]
		},
		{
			"name": "Gaius", "element": "earth", "role": "Defender", "archetype": "Defender",
			"level": 2, "league_tier": 1, "potential": 72, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 138, "mp": 94, "stamina": 126, "speed": 2, "agility": 17, "dexterity": 25,
			"base_stats": {"hp": 138, "mp": 94, "stamina": 126, "speed": 2, "agility": 17, "dexterity": 25},
			"equipped_skills": ["Sand", "Metal"], "known_skills": ["Sand", "Metal", "Stone_Plating"]
		}
	]
	cm.starting_formation = {
		"CaptainIgnis": Vector2i(3, 4),
		"Kora": Vector2i(2, 3),
		"Gaius": Vector2i(2, 5)
	}

	var world_node = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_node)
	await process_frame
	await process_frame

	var kora_unit = world_node.get_node_or_null("Kora")
	var gaius_unit = world_node.get_node_or_null("Gaius")

	_assert("C6.1 Ally Kora node spawned in World scene", kora_unit != null)
	_assert("C6.2 Ally Gaius node spawned in World scene", gaius_unit != null)

	if kora_unit:
		_assert("C6.3 Kora max_hp matches profile (88)", kora_unit.max_hp == 88, "hp=%d" % kora_unit.max_hp)
		_assert("C6.4 Kora hp matches max_hp (88)", kora_unit.hp == 88)
		_assert("C6.5 Kora max_mp matches profile (118)", kora_unit.max_mp == 118, "mp=%d" % kora_unit.max_mp)
		_assert("C6.6 Kora max_stamina matches profile (112)", kora_unit.max_stamina == 112, "sta=%d" % kora_unit.max_stamina)
		_assert("C6.7 Kora base_speed matches profile (4)", kora_unit.base_speed == 4)
		_assert("C6.8 Kora agility matches profile (36)", kora_unit.agility == 36)
		_assert("C6.9 Kora dexterity matches profile (29)", kora_unit.dexterity == 29)
		_assert("C6.10 Kora equipped_abilities matches profile ['Sound_Sonic', 'Wind'] (not default 'Gale_Step')",
			kora_unit.equipped_abilities == ["Sound_Sonic", "Wind"], "skills=%s" % str(kora_unit.equipped_abilities))

	if gaius_unit:
		_assert("C6.11 Gaius max_hp matches profile (138)", gaius_unit.max_hp == 138, "hp=%d" % gaius_unit.max_hp)
		_assert("C6.12 Gaius max_stamina matches profile (126, not default 100)", gaius_unit.max_stamina == 126, "sta=%d" % gaius_unit.max_stamina)
		_assert("C6.13 Gaius equipped_abilities matches profile ['Sand', 'Metal'] (not default 'Stone_Plating')",
			gaius_unit.equipped_abilities == ["Sand", "Metal"], "skills=%s" % str(gaius_unit.equipped_abilities))

	# Clean up World scene
	world_node.queue_free()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# CRITERION 7: No script calls node.duplicate() to create ally units
	# ──────────────────────────────────────────────────────────
	print("\n--- CRITERION 7: Zero node.duplicate() for Ally Creation ---")
	var world_file = FileAccess.open("res://scripts/world.gd", FileAccess.READ)
	_assert("C7.1 scripts/world.gd is readable", world_file != null)

	if world_file:
		var world_code = world_file.get_as_text()
		world_file.close()

		var has_player_duplicate = world_code.contains("player.duplicate()")
		var has_node_duplicate = world_code.contains("node.duplicate()")
		_assert("C7.2 scripts/world.gd contains zero 'player.duplicate()' calls", not has_player_duplicate)
		_assert("C7.3 scripts/world.gd contains zero 'node.duplicate()' calls", not has_node_duplicate)
		_assert("C7.4 scripts/world.gd uses PLAYER_SCENE.instantiate() for ally units",
			world_code.contains("PLAYER_SCENE.instantiate()"))
		_assert("C7.5 res://scenes/Player.tscn PackedScene exists",
			ResourceLoader.exists("res://scenes/Player.tscn"))

	# ──────────────────────────────────────────────────────────
	# SUITE 8: OOP Encapsulation & CampaignManager Accessors
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 8: OOP Encapsulation & Mutators ---")
	cm.init_new_campaign({"name": "Hero", "element": "fire"})
	var kora_entry = cm.get_ally("Kora")
	_assert("C8.1 get_ally('Kora') returns valid profile", not kora_entry.is_empty() and kora_entry["name"] == "Kora")

	var stat_upd = cm.update_athlete_stat("Kora", "hp", 777)
	_assert("C8.2 update_athlete_stat('Kora', 'hp', 777) succeeds", stat_upd)
	_assert("C8.3 get_ally('Kora')['hp'] reflects updated value 777", cm.get_ally("Kora")["hp"] == 777)
	_assert("C8.4 get_ally('Kora')['base_stats']['hp'] reflects updated value 777", cm.get_ally("Kora")["base_stats"]["hp"] == 777)

	var skill_upd = cm.set_athlete_skills("Kora", ["Wind", "Laser"])
	_assert("C8.5 set_athlete_skills succeeds", skill_upd)
	_assert("C8.6 get_ally('Kora') equipped_skills updated", cm.get_ally("Kora")["equipped_skills"] == ["Wind", "Laser"])

	var status_upd = cm.set_athlete_status("Kora", "Injured")
	_assert("C8.7 set_athlete_status succeeds", status_upd)
	_assert("C8.8 get_ally('Kora') status is 'Injured'", cm.get_ally("Kora")["status"] == "Injured")

	# Check CampaignManager holds zero Node references
	var holds_nodes = false
	for a in cm.allies:
		for val in a.values():
			if val is Node:
				holds_nodes = true
	_assert("C8.9 CampaignManager allies hold zero Godot Node references", not holds_nodes)

	# ──────────────────────────────────────────────────────────
	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [_pass, _fail, _pass + _fail])
	print("========================================================\n")
	quit(0 if _fail == 0 else 1)
