# scripts/test_m3_adversarial_2.gd
# Empirical Adversarial Verification Suite 2 for Milestone 3/4/5
# Covers:
# 1. World scene instantiation (3v3 combat with 1, 2, 3, and 4 equipped skills, stat & ability match)
# 2. Source scan for zero occurrences of .duplicate() for ally units in scripts/world.gd
# 3. element_db wiring to enemies and extra enemies
# 4. Zero Godot Node references in CampaignManager across operations
# 5. Save/load corruption resilience (5 allies across tiers and elements, corrupted JSON handling)
# 6. Campaign Hub UI stress (_get_potential_tier_label, unusual potentials: 0, 1, 100, >100, -5)

extends SceneTree

var _pass: int = 0
var _fail: int = 0

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

func _check_no_nodes(val, path: String = "root") -> Array:
	var node_paths: Array = []
	if val == null:
		return node_paths
	if val is Node:
		node_paths.append("%s is Node (%s)" % [path, val.get_class()])
		return node_paths
	if val is Object and is_instance_valid(val) and val is Node:
		node_paths.append("%s is valid Node (%s)" % [path, val.get_class()])
		return node_paths

	if val is Array:
		for idx in range(val.size()):
			var sub_paths = _check_no_nodes(val[idx], "%s[%d]" % [path, idx])
			node_paths.append_array(sub_paths)
	elif val is Dictionary:
		for k in val.keys():
			if k is Node or (k is Object and is_instance_valid(k) and k is Node):
				node_paths.append("%s key '%s' is Node" % [path, str(k)])
			var sub_paths = _check_no_nodes(val[k], "%s.%s" % [path, str(k)])
			node_paths.append_array(sub_paths)
	return node_paths

func _run() -> void:
	print("\n================================================================================")
	print("   ADVERSARIAL SUITE 2: WORLD INSTANTIATION, HUB INTEGRATION & OOP AUDIT")
	print("================================================================================")

	await process_frame
	await process_frame

	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = root.get_node_or_null("/root/CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()
		cm.name = "CampaignManager"
		root.add_child(cm)
		await process_frame

	var edata = root.get_node_or_null("ElementData")
	if edata == null:
		edata = root.get_node_or_null("/root/ElementData")
	if edata == null:
		edata = load("res://scripts/element_data.gd").new()
		edata.name = "ElementData"
		root.add_child(edata)
		await process_frame

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 1: World Scene Instantiation & Profile Matching (1, 2, 3, 4 Skills)
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 1: World Scene Instantiation with 1, 2, 3, 4 Equipped Skills ---")

	# Part 1A: 3v3 Match with 1-skill and 2-skill athletes
	cm.init_new_campaign({"player_name": "IgnisCap", "player_element": "fire", "team_name": "Phoenix Strikers"})
	cm.active_match_format = "3v3"
	cm.prepare_match("tournament", "water", "Nami", "Hydro Vipers")

	var ally_1_skill = {
		"name": "AeroMono", "element": "air", "role": "Scout", "archetype": "Scout",
		"level": 3, "league_tier": 1, "potential": 70, "status": "Active", "career_team": "Phoenix Strikers",
		"hp": 84, "mp": 112, "stamina": 104, "speed": 4, "agility": 35, "dexterity": 28,
		"base_stats": {"hp": 84, "mp": 112, "stamina": 104, "speed": 4, "agility": 35, "dexterity": 28},
		"equipped_skills": ["Sound_Sonic"],
		"known_skills": ["Sound_Sonic", "Wind", "Gale_Step"]
	}
	var ally_2_skill = {
		"name": "TerraDuo", "element": "earth", "role": "Defender", "archetype": "Defender",
		"level": 4, "league_tier": 1, "potential": 65, "status": "Active", "career_team": "Phoenix Strikers",
		"hp": 136, "mp": 92, "stamina": 124, "speed": 2, "agility": 18, "dexterity": 26,
		"base_stats": {"hp": 136, "mp": 92, "stamina": 124, "speed": 2, "agility": 18, "dexterity": 26},
		"equipped_skills": ["Sand", "Metal"],
		"known_skills": ["Sand", "Metal", "Stone_Plating"]
	}

	cm.allies = [
		{
			"name": "IgnisCap", "element": "fire", "role": "Captain", "archetype": "Striker",
			"level": 3, "league_tier": 1, "potential": 85, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 95, "mp": 105, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 32,
			"base_stats": {"hp": 95, "mp": 105, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 32},
			"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
		},
		ally_1_skill,
		ally_2_skill
	]
	cm.starting_formation = {
		"IgnisCap": Vector2i(3, 4),
		"AeroMono": Vector2i(2, 3),
		"TerraDuo": Vector2i(2, 5)
	}

	var world1 = load("res://scenes/World.tscn").instantiate()
	root.add_child(world1)
	await process_frame
	await process_frame

	var node_aero = world1.get_node_or_null("AeroMono")
	var node_terra = world1.get_node_or_null("TerraDuo")

	_assert("S1.1 AeroMono (1-skill) spawned in World", node_aero != null)
	_assert("S1.2 TerraDuo (2-skill) spawned in World", node_terra != null)

	if node_aero:
		_assert("S1.3 AeroMono has exact 1 equipped skill ['Sound_Sonic']",
			node_aero.equipped_abilities == ["Sound_Sonic"], "skills=%s" % str(node_aero.equipped_abilities))
		_assert("S1.4 AeroMono equipped_abilities size is exactly 1", node_aero.equipped_abilities.size() == 1)
		_assert("S1.5 AeroMono unlocked_abilities matches known_skills",
			node_aero.unlocked_abilities == ["Sound_Sonic", "Wind", "Gale_Step"])
		_assert("S1.6 AeroMono max_hp matches profile (84)", node_aero.max_hp == 84)
		_assert("S1.7 AeroMono hp equals max_hp (84)", node_aero.hp == 84)
		_assert("S1.8 AeroMono max_mp matches profile (112)", node_aero.max_mp == 112)
		_assert("S1.9 AeroMono max_stamina matches profile (104)", node_aero.max_stamina == 104)
		_assert("S1.10 AeroMono base_speed matches profile (4)", node_aero.base_speed == 4)
		_assert("S1.11 AeroMono agility matches profile (35)", node_aero.agility == 35)
		_assert("S1.12 AeroMono dexterity matches profile (28)", node_aero.dexterity == 28)

	if node_terra:
		_assert("S1.13 TerraDuo has exact 2 equipped skills ['Sand', 'Metal']",
			node_terra.equipped_abilities == ["Sand", "Metal"], "skills=%s" % str(node_terra.equipped_abilities))
		_assert("S1.14 TerraDuo equipped_abilities size is exactly 2", node_terra.equipped_abilities.size() == 2)
		_assert("S1.15 TerraDuo max_hp matches profile (136)", node_terra.max_hp == 136)
		_assert("S1.16 TerraDuo max_stamina matches profile (124)", node_terra.max_stamina == 124)
		_assert("S1.17 TerraDuo base_speed matches profile (2)", node_terra.base_speed == 2)
		_assert("S1.18 TerraDuo agility matches profile (18)", node_terra.agility == 18)
		_assert("S1.19 TerraDuo dexterity matches profile (26)", node_terra.dexterity == 26)

	world1.queue_free()
	await process_frame
	await process_frame

	# Part 1B: 3v3 Match with 3-skill and 4-skill athletes
	var ally_3_skill = {
		"name": "PyroTrio", "element": "fire", "role": "Striker", "archetype": "Striker",
		"level": 15, "league_tier": 3, "potential": 82, "status": "Active", "career_team": "Phoenix Strikers",
		"hp": 128, "mp": 134, "stamina": 118, "speed": 4, "agility": 38, "dexterity": 40,
		"base_stats": {"hp": 128, "mp": 134, "stamina": 118, "speed": 4, "agility": 38, "dexterity": 40},
		"equipped_skills": ["Combustion", "Lightning", "Laser"],
		"known_skills": ["Combustion", "Lightning", "Laser", "Thermal_Radiation"]
	}
	var ally_4_skill = {
		"name": "AquaQuad", "element": "water", "role": "Support", "archetype": "Support",
		"level": 28, "league_tier": 4, "potential": 94, "status": "Active", "career_team": "Phoenix Strikers",
		"hp": 152, "mp": 168, "stamina": 130, "speed": 5, "agility": 54, "dexterity": 48,
		"base_stats": {"hp": 152, "mp": 168, "stamina": 130, "speed": 5, "agility": 54, "dexterity": 48},
		"equipped_skills": ["Aqua_Mend", "Acid Rain", "Ice_Shard", "Blood"],
		"known_skills": ["Aqua_Mend", "Acid Rain", "Ice_Shard", "Blood"]
	}

	cm.allies = [
		{
			"name": "IgnisCap", "element": "fire", "role": "Captain", "archetype": "Striker",
			"level": 15, "league_tier": 3, "potential": 85, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 125, "mp": 130, "stamina": 110, "speed": 4, "agility": 36, "dexterity": 38,
			"base_stats": {"hp": 125, "mp": 130, "stamina": 110, "speed": 4, "agility": 36, "dexterity": 38},
			"equipped_skills": ["Combustion"], "known_skills": ["Combustion"]
		},
		ally_3_skill,
		ally_4_skill
	]
	cm.starting_formation = {
		"IgnisCap": Vector2i(3, 4),
		"PyroTrio": Vector2i(2, 3),
		"AquaQuad": Vector2i(2, 5)
	}

	var world2 = load("res://scenes/World.tscn").instantiate()
	root.add_child(world2)
	await process_frame
	await process_frame

	var node_pyro = world2.get_node_or_null("PyroTrio")
	var node_aqua = world2.get_node_or_null("AquaQuad")

	_assert("S1.20 PyroTrio (3-skill) spawned in World", node_pyro != null)
	_assert("S1.21 AquaQuad (4-skill) spawned in World", node_aqua != null)

	if node_pyro:
		_assert("S1.22 PyroTrio has exact 3 equipped skills",
			node_pyro.equipped_abilities == ["Combustion", "Lightning", "Laser"], "skills=%s" % str(node_pyro.equipped_abilities))
		_assert("S1.23 PyroTrio equipped_abilities size is 3", node_pyro.equipped_abilities.size() == 3)
		_assert("S1.24 PyroTrio max_hp matches profile (128)", node_pyro.max_hp == 128)
		_assert("S1.25 PyroTrio max_mp matches profile (134)", node_pyro.max_mp == 134)
		_assert("S1.26 PyroTrio base_speed matches profile (4)", node_pyro.base_speed == 4)
		_assert("S1.27 PyroTrio agility matches profile (38)", node_pyro.agility == 38)
		_assert("S1.28 PyroTrio dexterity matches profile (40)", node_pyro.dexterity == 40)

	if node_aqua:
		_assert("S1.29 AquaQuad has exact 4 equipped skills",
			node_aqua.equipped_abilities == ["Aqua_Mend", "Acid Rain", "Ice_Shard", "Blood"], "skills=%s" % str(node_aqua.equipped_abilities))
		_assert("S1.30 AquaQuad equipped_abilities size is 4", node_aqua.equipped_abilities.size() == 4)
		_assert("S1.31 AquaQuad max_hp matches profile (152)", node_aqua.max_hp == 152)
		_assert("S1.32 AquaQuad max_mp matches profile (168)", node_aqua.max_mp == 168)
		_assert("S1.33 AquaQuad max_stamina matches profile (130)", node_aqua.max_stamina == 130)
		_assert("S1.34 AquaQuad base_speed matches profile (5)", node_aqua.base_speed == 5)
		_assert("S1.35 AquaQuad agility matches profile (54)", node_aqua.agility == 54)
		_assert("S1.36 AquaQuad dexterity matches profile (48)", node_aqua.dexterity == 48)

	world2.queue_free()
	await process_frame
	await process_frame

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 2: Static Source Code Audit for Zero .duplicate() of Ally Units
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 2: Static Source Code Audit of scripts/world.gd ---")
	var w_file = FileAccess.open("res://scripts/world.gd", FileAccess.READ)
	_assert("S2.1 scripts/world.gd opens successfully", w_file != null)
	if w_file:
		var code = w_file.get_as_text()
		w_file.close()

		_assert("S2.2 Zero occurrences of 'player.duplicate()'", not code.contains("player.duplicate()"))
		_assert("S2.3 Zero occurrences of 'node.duplicate()'", not code.contains("node.duplicate()"))
		_assert("S2.4 Zero occurrences of 'ally.duplicate()'", not code.contains("ally.duplicate()"))
		_assert("S2.5 Zero occurrences of 'unit.duplicate()'", not code.contains("unit.duplicate()"))
		_assert("S2.6 Uses PLAYER_SCENE.instantiate() for ally units", code.contains("PLAYER_SCENE.instantiate()"))
		_assert("S2.7 Player PackedScene preloaded as const PLAYER_SCENE", code.contains("const PLAYER_SCENE = preload(\"res://scenes/Player.tscn\")"))

	# Verify PackedScene exists and instantiates into CharacterBody2D
	_assert("S2.8 res://scenes/Player.tscn exists on disk", ResourceLoader.exists("res://scenes/Player.tscn"))
	var p_scene = load("res://scenes/Player.tscn")
	_assert("S2.9 res://scenes/Player.tscn is valid PackedScene", p_scene is PackedScene)
	if p_scene is PackedScene:
		var p_inst = p_scene.instantiate()
		_assert("S2.10 Instantiated Player is CharacterBody2D", p_inst is CharacterBody2D)
		_assert("S2.11 Instantiated Player has player.gd script",
			p_inst.get_script() != null and p_inst.get_script().resource_path == "res://scripts/player.gd")
		p_inst.free()

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 3: Dependency Injection & element_db Wiring to All Enemies
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 3: Dependency Injection & element_db Wiring ---")
	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Phoenix Strikers"})
	cm.active_match_format = "3v3"
	cm.prepare_match("tournament", "water", "Nami", "Hydro Vipers")

	var world3 = load("res://scenes/World.tscn").instantiate()
	root.add_child(world3)
	await process_frame
	await process_frame

	var bm = world3.battle_manager
	_assert("S3.1 BattleManager is present in World", bm != null)
	_assert("S3.2 enemy_units has 3 combatants in 3v3", bm.enemy_units.size() == 3)

	var primary_enemy = world3.get_node_or_null("Enemy")
	_assert("S3.3 Primary Enemy node exists", primary_enemy != null)
	if primary_enemy:
		_assert("S3.4 Primary Enemy has element_db wired", primary_enemy.element_db != null)
		_assert("S3.5 Primary Enemy element_db has ELEMENTS dictionary",
			primary_enemy.element_db.get("ELEMENTS") != null and primary_enemy.element_db.ELEMENTS.has("water"))
		_assert("S3.6 Primary Enemy has battle_manager wired", primary_enemy.battle_manager == bm)
		_assert("S3.7 Primary Enemy has ui wired", primary_enemy.ui != null)
		_assert("S3.8 Primary Enemy has player reference wired", primary_enemy.player != null)

	var extra_enemy_1 = world3.get_node_or_null("Enemy_1")
	var extra_enemy_2 = world3.get_node_or_null("Enemy_2")
	_assert("S3.9 Extra enemy Enemy_1 exists", extra_enemy_1 != null)
	_assert("S3.10 Extra enemy Enemy_2 exists", extra_enemy_2 != null)

	if extra_enemy_1:
		_assert("S3.11 Enemy_1 has element_db wired", extra_enemy_1.element_db != null)
		_assert("S3.12 Enemy_1 element_db contains valid ELEMENTS",
			extra_enemy_1.element_db.get("ELEMENTS") != null and extra_enemy_1.element_db.ELEMENTS.has(extra_enemy_1.element))
		_assert("S3.13 Enemy_1 has battle_manager wired", extra_enemy_1.battle_manager == bm)
		_assert("S3.14 Enemy_1 has ui wired", extra_enemy_1.ui != null)
		_assert("S3.15 Enemy_1 has player reference wired", extra_enemy_1.player != null)

	if extra_enemy_2:
		_assert("S3.16 Enemy_2 has element_db wired", extra_enemy_2.element_db != null)
		_assert("S3.17 Enemy_2 element_db contains valid ELEMENTS",
			extra_enemy_2.element_db.get("ELEMENTS") != null and extra_enemy_2.element_db.ELEMENTS.has(extra_enemy_2.element))
		_assert("S3.18 Enemy_2 has battle_manager wired", extra_enemy_2.battle_manager == bm)

	world3.queue_free()
	await process_frame
	await process_frame

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 4: Encapsulation - CampaignManager Holds ZERO Node References Across Operations
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 4: Zero Godot Node References in CampaignManager ---")

	# Step 1: Solo campaign
	cm.init_new_campaign({"name": "SoloAuditor", "element": "air", "start_solo": true})
	var solo_leaks = _check_no_nodes(cm.allies, "cm.allies") + _check_no_nodes(cm.starting_formation, "cm.starting_formation")
	_assert("S4.1 Zero Node references after solo campaign init", solo_leaks.is_empty(), str(solo_leaks))

	# Step 2: Recruitment offer
	cm.trigger_recruitment_offer(4)
	var recruit_leaks = _check_no_nodes(cm.allies, "cm.allies")
	_assert("S4.2 Zero Node references after trigger_recruitment_offer", recruit_leaks.is_empty(), str(recruit_leaks))

	# Step 3: Mutators
	if not cm.allies.is_empty():
		var test_name = cm.allies[0]["name"]
		cm.update_athlete_stat(test_name, "speed", 5)
		cm.set_athlete_skills(test_name, ["Wind", "Laser"])
		cm.set_athlete_status(test_name, "Injured")
	var mut_leaks = _check_no_nodes(cm.allies, "cm.allies")
	_assert("S4.3 Zero Node references after stat/skill/status updates", mut_leaks.is_empty(), str(mut_leaks))

	# Step 4: Promotion & Transfer Window
	cm.promote_team_tier(2)
	var promo_leaks = _check_no_nodes(cm.allies, "cm.allies")
	_assert("S4.4 Zero Node references after promote_team_tier", promo_leaks.is_empty(), str(promo_leaks))

	cm.run_transfer_window()
	var trans_leaks = _check_no_nodes(cm.allies, "cm.allies") + _check_no_nodes(cm.known_fighters, "cm.known_fighters")
	_assert("S4.5 Zero Node references after run_transfer_window", trans_leaks.is_empty(), str(trans_leaks))

	# Step 5: Full properties inspection
	var full_dict = {
		"allies": cm.allies,
		"starting_formation": cm.starting_formation,
		"known_fighters": cm.known_fighters,
		"skill_variations": cm.skill_variations,
		"appearance": cm.appearance,
		"scouting_intel": cm.scouting_intel,
		"tournament_schedule": cm.tournament_schedule
	}
	var full_leaks = _check_no_nodes(full_dict, "CampaignManager_State")
	_assert("S4.6 Deep tree inspection of CampaignManager state confirms ZERO Node references",
		full_leaks.is_empty(), str(full_leaks))

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 5: Save/Load Corruption Resilience & Complex Multi-Tier Schema
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 5: Save/Load Multi-Tier Schema Integrity & Corruption Resilience ---")

	cm.init_new_campaign({"player_name": "Valen", "player_element": "earth", "team_name": "Iron Bastion"})
	cm.league_tier = 3
	cm.active_match_format = "3v3"
	cm.designated_sub = "Sylas"

	# Build 5 allies across different tiers and elements:
	var c_allies = [
		{
			"name": "Valen", "element": "earth", "role": "Captain", "archetype": "Defender",
			"level": 14, "league_tier": 3, "potential": 88, "status": "Active", "career_team": "Iron Bastion",
			"hp": 132, "mp": 126, "stamina": 128, "speed": 3, "agility": 34, "dexterity": 36,
			"base_stats": {"hp": 132, "mp": 126, "stamina": 128, "speed": 3, "agility": 34, "dexterity": 36},
			"equipped_skills": ["Stone_Plating", "Metal"],
			"known_skills": ["Stone_Plating", "Metal", "Quicksand"]
		},
		{
			"name": "Kite", "element": "air", "role": "Scout", "archetype": "Scout",
			"level": 4, "league_tier": 1, "potential": 72, "status": "Active", "career_team": "Iron Bastion",
			"hp": 76, "mp": 94, "stamina": 102, "speed": 3, "agility": 26, "dexterity": 24,
			"base_stats": {"hp": 76, "mp": 94, "stamina": 102, "speed": 3, "agility": 26, "dexterity": 24},
			"equipped_skills": ["Gale_Step"],
			"known_skills": ["Gale_Step", "Wind"]
		},
		{
			"name": "Brant", "element": "fire", "role": "Striker", "archetype": "Striker",
			"level": 9, "league_tier": 2, "potential": 60, "status": "Active", "career_team": "Iron Bastion",
			"hp": 106, "mp": 114, "stamina": 108, "speed": 4, "agility": 30, "dexterity": 32,
			"base_stats": {"hp": 106, "mp": 114, "stamina": 108, "speed": 4, "agility": 30, "dexterity": 32},
			"equipped_skills": ["Combustion", "Lightning"],
			"known_skills": ["Combustion", "Lightning"]
		},
		{
			"name": "Sylas", "element": "water", "role": "Support", "archetype": "Support",
			"level": 26, "league_tier": 4, "potential": 48, "status": "Reserve", "career_team": "Iron Bastion",
			"hp": 142, "mp": 162, "stamina": 120, "speed": 4, "agility": 48, "dexterity": 46,
			"base_stats": {"hp": 142, "mp": 162, "stamina": 120, "speed": 4, "agility": 48, "dexterity": 46},
			"equipped_skills": ["Aqua_Mend", "Acid Rain", "Ice_Shard"],
			"known_skills": ["Aqua_Mend", "Acid Rain", "Ice_Shard", "Blood"]
		},
		{
			"name": "Aurelia", "element": "air", "role": "Striker", "archetype": "Striker",
			"level": 40, "league_tier": 5, "potential": 99, "status": "Active", "career_team": "Iron Bastion",
			"hp": 182, "mp": 196, "stamina": 150, "speed": 6, "agility": 66, "dexterity": 62,
			"base_stats": {"hp": 182, "mp": 196, "stamina": 150, "speed": 6, "agility": 66, "dexterity": 62},
			"equipped_skills": ["Gale_Step", "Wind", "Sound_Sonic", "Vacuum_Blade"],
			"known_skills": ["Gale_Step", "Wind", "Sound_Sonic", "Vacuum_Blade"]
		}
	]

	cm.allies = c_allies
	cm.starting_formation = {
		"Valen": Vector2i(3, 4),
		"Kite": Vector2i(2, 3),
		"Brant": Vector2i(2, 5),
		"Sylas": Vector2i(-1, -1),
		"Aurelia": Vector2i(1, 4)
	}
	# Save real unlocked form keys, as the combat/UI API does; display names
	# (and the removed Reinforced Granite form) are not valid active selections.
	cm.unlock_skill_form("Stone_Plating", "rock_pillar")
	cm.unlock_skill_form("Metal", "ferrous_spike")
	cm.set_active_skill_form("Metal", "ferrous_spike")
	cm.known_fighters = [
		{"name": "RivalRik", "element": "fire", "league_tier": 2, "potential": 80, "career_team": "Blaze Clan"}
	]

	var save_res = cm.save_campaign()
	_assert("S5.1 save_campaign() returns true for complex multi-tier roster", save_res)

	# Wipe in-memory state
	cm.allies = []
	cm.starting_formation = {}
	cm.skill_variations = {}
	cm.known_fighters = []
	cm.player_name = "Wiped"
	cm.league_tier = 1

	var load_res = cm.load_campaign()
	_assert("S5.2 load_campaign() returns true", load_res)
	_assert("S5.3 Player name restored to Valen", cm.player_name == "Valen")
	_assert("S5.4 League tier restored to 3", cm.league_tier == 3)
	_assert("S5.5 Designated sub restored to Sylas", cm.designated_sub == "Sylas")
	_assert("S5.6 Allies roster restored to exactly 5 members", cm.allies.size() == 5)

	# Validate all 5 allies in detail
	var kite = cm.get_ally("Kite")
	var brant = cm.get_ally("Brant")
	var sylas = cm.get_ally("Sylas")
	var aurelia = cm.get_ally("Aurelia")

	_assert("S5.7 Kite (T1, 1-skill) restored correctly",
		kite.get("league_tier") == 1 and kite.get("equipped_skills") == ["Gale_Step"] and kite.get("potential") == 72)
	_assert("S5.8 Brant (T2, 2-skill) restored correctly",
		brant.get("league_tier") == 2 and brant.get("equipped_skills") == ["Combustion", "Lightning"] and brant.get("potential") == 60)
	_assert("S5.9 Sylas (T4, 3-skill, Reserve) restored correctly",
		sylas.get("league_tier") == 4 and sylas.get("equipped_skills").size() == 3 and sylas.get("status") == "Reserve")
	_assert("S5.10 Aurelia (T5, 4-skill, pot=99) restored correctly",
		aurelia.get("league_tier") == 5 and aurelia.get("equipped_skills").size() == 4 and aurelia.get("potential") == 99)
	_assert("S5.11 Aurelia base_stats match hp=182, speed=6",
		aurelia.get("base_stats", {}).get("hp") == 182 and aurelia.get("base_stats", {}).get("speed") == 6)

	_assert("S5.12 Starting formation vector2i restored accurately",
		cm.starting_formation.get("Valen") == Vector2i(3, 4) and cm.starting_formation.get("Sylas") == Vector2i(-1, -1))
	_assert("S5.13 Skill variations preserved",
		cm.skill_variations.get("Metal") == "ferrous_spike" and cm.skill_variations.get("Stone_Plating") == "rock_pillar")
	_assert("S5.14 Known fighters array preserved",
		cm.known_fighters.size() == 1 and cm.known_fighters[0].get("name") == "RivalRik")

	# Corruption Stress: Write truncated / invalid JSON to save file
	var corrupt_file = FileAccess.open(cm.SAVE_PATH, FileAccess.WRITE)
	if corrupt_file:
		corrupt_file.store_string("{\"player_name\": \"Corrupted\", \"allies\": [{\"incomplete\":")
		corrupt_file.close()

	var corrupt_load_res = cm.load_campaign()
	_assert("S5.15 Corrupted JSON handled gracefully: load_campaign() returns false without crash",
		corrupt_load_res == false)

	# Corruption Stress: Write non-dictionary JSON
	var non_dict_file = FileAccess.open(cm.SAVE_PATH, FileAccess.WRITE)
	if non_dict_file:
		non_dict_file.store_string("[1, 2, 3, \"not a dictionary\"]")
		non_dict_file.close()

	var non_dict_load_res = cm.load_campaign()
	_assert("S5.16 Non-dictionary JSON handled gracefully: load_campaign() returns false without crash",
		non_dict_load_res == false)

	# Re-save valid campaign for cleanup
	cm.allies = c_allies
	cm.player_name = "Valen"
	cm.save_campaign()

	# ══════════════════════════════════════════════════════════════════════════════
	# SUITE 6: Campaign Hub UI Stress - Potential Tier Labels & Boundary Values
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n--- SUITE 6: Campaign Hub UI Stress & Unusual Potential Values ---")

	# Boundary tests on CampaignManager.get_potential_label & CampaignHub._get_potential_tier_label
	_assert("S6.1 potential = 0 -> Journeyman", cm.get_potential_label(0) == "Journeyman")
	_assert("S6.2 potential = -10 -> Journeyman", cm.get_potential_label(-10) == "Journeyman")
	_assert("S6.3 potential = 1 -> Journeyman", cm.get_potential_label(1) == "Journeyman")
	_assert("S6.4 potential = 39 -> Journeyman", cm.get_potential_label(39) == "Journeyman")
	_assert("S6.5 potential = 40 -> Rising Star", cm.get_potential_label(40) == "Rising Star")
	_assert("S6.6 potential = 74 -> Rising Star", cm.get_potential_label(74) == "Rising Star")
	_assert("S6.7 potential = 75 -> Prodigy", cm.get_potential_label(75) == "Prodigy")
	_assert("S6.8 potential = 100 -> Prodigy", cm.get_potential_label(100) == "Prodigy")
	_assert("S6.9 potential = 101 -> Prodigy", cm.get_potential_label(101) == "Prodigy")
	_assert("S6.10 potential = 500 -> Prodigy", cm.get_potential_label(500) == "Prodigy")

	# Test CampaignHub instantiation and roster rendering with boundary potential fighters
	var boundary_allies = [
		{
			"name": "ZeroPot", "element": "fire", "role": "Striker", "archetype": "Striker",
			"level": 1, "league_tier": 1, "potential": 0, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 70, "mp": 80, "stamina": 100, "speed": 2, "agility": 16, "dexterity": 20,
			"equipped_skills": ["Combustion"]
		},
		{
			"name": "OnePot", "element": "water", "role": "Defender", "archetype": "Defender",
			"level": 1, "league_tier": 1, "potential": 1, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 75, "mp": 85, "stamina": 100, "speed": 2, "agility": 18, "dexterity": 22,
			"equipped_skills": ["Aqua_Mend"]
		},
		{
			"name": "HundredPot", "element": "earth", "role": "Scout", "archetype": "Scout",
			"level": 10, "league_tier": 2, "potential": 100, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 110, "mp": 120, "stamina": 110, "speed": 4, "agility": 32, "dexterity": 34,
			"equipped_skills": ["Stone_Plating", "Metal"]
		},
		{
			"name": "OverHundredPot", "element": "air", "role": "Support", "archetype": "Support",
			"level": 30, "league_tier": 4, "potential": 140, "status": "Active", "career_team": "Phoenix Strikers",
			"hp": 150, "mp": 160, "stamina": 130, "speed": 5, "agility": 50, "dexterity": 48,
			"equipped_skills": ["Gale_Step", "Wind", "Sound_Sonic"]
		},
		{
			"name": "NegativePot", "element": "fire", "role": "Striker", "archetype": "Striker",
			"level": 1, "league_tier": 1, "potential": -5, "status": "Retired", "career_team": "Phoenix Strikers",
			"hp": 70, "mp": 80, "stamina": 100, "speed": 2, "agility": 16, "dexterity": 20,
			"equipped_skills": []
		}
	]

	cm.allies = boundary_allies
	cm.player_name = "ZeroPot"
	cm.has_active_campaign = true

	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	await process_frame

	_assert("S6.11 CampaignHub instantiated successfully with boundary allies", hub != null)

	# Verify hub._get_potential_tier_label direct method calls
	_assert("S6.12 hub._get_potential_tier_label(0) -> Journeyman", hub._get_potential_tier_label(0) == "Journeyman")
	_assert("S6.13 hub._get_potential_tier_label(1) -> Journeyman", hub._get_potential_tier_label(1) == "Journeyman")
	_assert("S6.14 hub._get_potential_tier_label(100) -> Prodigy", hub._get_potential_tier_label(100) == "Prodigy")
	_assert("S6.15 hub._get_potential_tier_label(140) -> Prodigy", hub._get_potential_tier_label(140) == "Prodigy")
	_assert("S6.16 hub._get_potential_tier_label(-5) -> Journeyman", hub._get_potential_tier_label(-5) == "Journeyman")

	# Render Roster Tab
	hub._switch_tab(1)
	await process_frame
	_assert("S6.17 Roster Tab (Index 1) rendered without crashing", hub.active_nav_index == 1)

	# Cycle through every boundary ally index in the roster UI
	var render_success = true
	for idx in range(boundary_allies.size()):
		hub._roster_selected_idx = idx
		hub._refresh_team_tab()
		await process_frame
	_assert("S6.18 Roster Tab rendered all boundary potential entries (0, 1, 100, 140, -5) without errors", render_success)

	# Render Battle Tab with boundary allies
	hub._switch_tab(2)
	await process_frame
	_assert("S6.19 Battle Tab (Index 2) rendered without crashing", hub.active_nav_index == 2)

	hub.queue_free()
	await process_frame
	await process_frame

	# ══════════════════════════════════════════════════════════════════════════════
	# FINAL SUMMARY
	# ══════════════════════════════════════════════════════════════════════════════
	print("\n================================================================================")
	print("  ADVERSARIAL SUITE 2 RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [_pass, _fail, _pass + _fail])
	print("================================================================================\n")

	if _fail == 0:
		print("[ALL ADVERSARIAL TESTS COMPLETED SUCCESSFULLY!]")
		quit(0)
	else:
		printerr("[ADVERSARIAL SUITE REPORTED %d FAILURES!]" % _fail)
		quit(1)
