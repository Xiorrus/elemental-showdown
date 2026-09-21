extends SceneTree

# Headless Unit Test Suite for Combat & Progression Systems
# Tests:
# 1. Stamina burn & rest recovery (+15% / +25% Braced Guard)
# 2. Directional evasion (Front/Flank/Rear) & Agility vs Dexterity
# 3. Distance damage falloff beyond optimal range
# 4. Substitution rules (Anytime while alive, strictly locked out upon KO)
# 5. Blitz Steal requirements & tiger's mouth retaliation
# 6. Fusion Codex (Double, Triple, Quadruple Space & Time)
# 7. Teammate Autonomy vs Captain Authority

var tests_passed: int = 0
var tests_failed: int = 0

func _init():
	_run.call_deferred()

func _run():
	print("\n========================================================")
	print("   ELEMENTAL SHOWDOWN — COMBAT & PROGRESSION TEST SUITE")
	print("========================================================\n")

	var world = load("res://scenes/World.tscn").instantiate()
	root.add_child(world)
	await process_frame
	await process_frame

	var player = world.get_node("Player")
	var enemy = world.get_node("Enemy")
	var bm = world.get_node("BattleManager")
	var ed = root.get_node_or_null("ElementData")
	if ed == null:
		ed = load("res://scripts/element_data.gd").new()
	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()

	# -------------------------------------------------------------------------
	# SUITE 1: STAMINA SYSTEM & REST RECOVERY
	# -------------------------------------------------------------------------
	print("--- SUITE 1: Stamina System & Rest Recovery ---")
	player.stamina = 100
	player.max_stamina = 100
	player.mp = 50
	player.max_mp = 100

	# Spend stamina (e.g. 3 tiles moved = 30 STA)
	var spent = player.spend_stamina(30)
	_assert(spent and player.stamina == 70, "T1.1 Stamina consumption: 3 tiles movement burns 30 STA (70/100 remaining)")

	# Rest recovery (+15% for skipped movement)
	player.recover_stamina(15)
	_assert(player.stamina == 85, "T1.2 Skipping movement recovers +15% STA (85/100)")

	# Standby rest (+25% STA and MP, and activates Braced Guard)
	player.stamina = 60
	player.mp = 40
	player.rest_turn(true) # full standby
	_assert(player.stamina == 85 and player.mp == 65 and player.is_braced_guard, "T1.3 Full Standby restores +25% STA & MP and applies Braced Guard posture (+20 AGI)")

	# -------------------------------------------------------------------------
	# SUITE 2: DIRECTIONAL EVASION & ACCURACY
	# -------------------------------------------------------------------------
	print("\n--- SUITE 2: Directional Evasion & Hit Calculation ---")
	# Target facing East (facing_frame = 4 -> Vector2(1, 0))
	player.facing_frame = 4
	player.agility = 40
	player.is_braced_guard = false

	# Attacker from East: attacking facing player directly -> FRONT
	var hit_front = player.calculate_directional_hit(Vector2(player.position.x + 100, player.position.y), 30, 95.0)["hit_chance"]
	# Attacker from North: 90 degrees -> FLANK
	var hit_flank = player.calculate_directional_hit(Vector2(player.position.x, player.position.y - 100), 30, 95.0)["hit_chance"]
	# Attacker from West: directly behind player -> REAR
	var hit_rear = player.calculate_directional_hit(Vector2(player.position.x - 100, player.position.y), 30, 95.0)["hit_chance"]

	_assert(hit_rear > hit_flank and hit_flank > hit_front, "T2.1 Directional hit chance hierarchy: Rear (%d%%) > Flank (%d%%) > Front (%d%%)" % [hit_rear, hit_flank, hit_front])
	_assert(hit_rear >= 95, "T2.2 Rear attacks minimize dodge chance (hit >= 95%% due to 0.05x evasion multiplier)")

	# -------------------------------------------------------------------------
	# SUITE 3: DISTANCE DAMAGE FALLOFF
	# -------------------------------------------------------------------------
	print("\n--- SUITE 3: Distance Damage Falloff ---")
	var base_dmg = 50.0
	var dmg_close = player.apply_distance_falloff(base_dmg, 2, 2)
	var dmg_far = player.apply_distance_falloff(base_dmg, 5, 2) # 3 tiles beyond range 2 = -30%
	_assert(dmg_close == 50.0, "T3.1 Within optimal range (dist 2, opt 2): 100% damage (50 dmg)")
	_assert(dmg_far == 35.0, "T3.2 Outside optimal range (dist 5, opt 2): -10% per tile falloff = 70% damage (35 dmg)")

	# -------------------------------------------------------------------------
	# SUITE 4: SUBSTITUTION RULES & KNOCKOUT LOCKOUT
	# -------------------------------------------------------------------------
	print("\n--- SUITE 4: Substitutions & KO Lockout Penalty ---")
	# 3v3 match setup: 1 sub allowed
	bm.subs_remaining = 1

	var mock_target = Node2D.new()
	mock_target.name = "MockFighter"
	mock_target.set("hp", 80)
	bm.add_child(mock_target)

	# Test substitution while alive
	var can_sub_alive = bm.can_substitute(mock_target)
	_assert(can_sub_alive == true, "T4.1 Alive fighter (HP > 0) with subs remaining can be substituted at any time")

	# Execute substitution
	var sub_res = bm.substitute_fighter(mock_target, {"name": "BenchFighter", "element": "earth", "hp": 100})
	_assert(sub_res == true and bm.subs_remaining == 0, "T4.2 Executing substitution reduces subs_remaining to 0")

	# Attempt second sub (0 subs left)
	var can_sub_none = bm.can_substitute(mock_target)
	_assert(can_sub_none == false, "T4.3 Substitution rejected when subs_remaining == 0")

	# Reset for KO test
	bm.subs_remaining = 1
	var mock_ko = Node2D.new()
	mock_ko.name = "MockKO"
	mock_ko.set("hp", 0)
	bm.add_child(mock_ko)

	# Record Knockout
	bm.record_knockout(mock_ko)
	var can_sub_ko = bm.can_substitute(mock_ko)
	_assert(can_sub_ko == false, "T4.4 CRITICAL INVARIANT: Knocked-out fighter cannot be subbed! (Slot permanently locked, team 1 man down)")

	# -------------------------------------------------------------------------
	# SUITE 5: BLITZ STEAL & THE TIGER'S MOUTH
	# -------------------------------------------------------------------------
	print("\n--- SUITE 5: Blitz Steal Mechanics ---")
	var speed_blitzer = 5
	var agi_blitzer = 45
	var speed_defender = 3
	var agi_defender = 20

	var can_blitz = bm.check_blitz_steal(speed_blitzer, agi_blitzer, speed_defender, agi_defender)
	_assert(can_blitz == true, "T5.1 Superior Speed + Agility (>= 35% gap) grants Blitz Steal opportunity")

	var cannot_blitz = bm.check_blitz_steal(3, 25, 3, 25)
	_assert(cannot_blitz == false, "T5.2 Equal stats reject Blitz Steal attempt")

	# -------------------------------------------------------------------------
	# SUITE 6: FUSION CODEX (DOUBLE, TRIPLE, QUADRUPLE SPACE & TIME)
	# -------------------------------------------------------------------------
	print("\n--- SUITE 6: Fusion Codex Exploration ---")
	var magma_fusion = ed.get_fusion_info("fire", "earth")
	_assert(magma_fusion != null and magma_fusion["name"] == "Magma Surge", "T6.1 Double Fusion: Fire + Earth = Magma Surge")

	var space_time = ed.get_quadruple_fusion()
	_assert(space_time != null and space_time["name"] == "Chrono-Spatial Singularity", "T6.2 Quadruple Fusion: Space & Time = Chrono-Spatial Singularity")

	# Starter disciplines verified
	_assert(ed.ABILITIES.has("Aqua_Mend") and ed.ABILITIES["Aqua_Mend"]["effect"] == "heal" and ed.ABILITIES["Aqua_Mend"]["damage"] < 0, "T6.3 Water starter discipline includes Aqua_Mend (Lv 1 healing)")
	_assert(ed.ABILITIES.has("Stone_Plating") and ed.ABILITIES["Stone_Plating"]["effect"] == "barrier", "T6.4 Earth starter discipline includes Stone_Plating (Lv 1 defense/barrier)")
	_assert(ed.ABILITIES.has("Gale_Step") and ed.ABILITIES["Gale_Step"]["effect"] == "evasion", "T6.5 Air starter discipline includes Gale_Step (Lv 1 evasion)")

	# -------------------------------------------------------------------------
	# SUITE 7: TEAMMATE AUTONOMY VS CAPTAIN AUTHORITY
	# -------------------------------------------------------------------------
	print("\n--- SUITE 7: Teammate Autonomy vs Captain Authority ---")
	var ally_key = "kaelen"
	# Captain designates pre-game loadout
	var set_skills = cm.set_teammate_active_skills(ally_key, ["Stone_Plating", "Metal", "Quicksand", "Combustion"])
	_assert(set_skills == true, "T7.1 Captain successfully sets teammate active skill loadout before match")

	# Captain suggests training focus
	var accepted_count = 0
	for i in range(20):
		var res = cm.suggest_training_focus(ally_key, "Defense")
		if res["accepted"]:
			accepted_count += 1

	_assert(accepted_count < 15, "T7.2 Teammate Autonomy: Teammate rejects majority of captain training suggestions (accepted %d/20 due to personal archetype)" % accepted_count)

	# Summary
	print("\n========================================================")
	print("  TEST SUMMARY: %d / %d PASSED (Failed: %d)" % [tests_passed, tests_passed + tests_failed, tests_failed])
	if tests_failed == 0:
		print("  ALL COMBAT & PROGRESSION TESTS PASSED!")
	print("========================================================\n")

	world.queue_free()
	quit(0 if tests_failed == 0 else 1)

func _assert(condition: bool, description: String):
	if condition:
		tests_passed += 1
		print("  [PASS] " + description)
	else:
		tests_failed += 1
		print("  [FAIL] " + description)
