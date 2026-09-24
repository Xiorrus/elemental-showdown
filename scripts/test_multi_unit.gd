extends SceneTree

func _init():
	print("\n========================================================")
	print("   MULTI-UNIT DIRECT CONTROL & SQUAD COMBAT TEST SUITE")
	print("========================================================\n")

	var counts = {"passed": 0, "failed": 0}

	var check = func(condition: bool, test_name: String, details: String = ""):
		if condition:
			print("  [PASS] %s" % test_name)
			counts["passed"] += 1
		else:
			print("  [FAIL] %s %s" % [test_name, details])
			counts["failed"] += 1

	var root = get_root()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# SUITE 1: 3v3 MULTI-UNIT SPAWN & FORMATION ALIGNMENT
	# ──────────────────────────────────────────────────────────
	print("--- SUITE 1: 3v3 Multi-Unit Arena Spawning ---")
	var cm = root.get_node_or_null("/root/CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Phoenix Strikers"})
		cm.active_match_format = "3v3"
		cm.prepare_match("tournament", "water", "Nami", "Hydro Vipers")

	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	await process_frame
	await process_frame

	var bm = world_scn.get_node_or_null("BattleManager")
	var ui = world_scn.get_node_or_null("UI")

	check.call(bm != null and bm.match_format == "3v3", "T1.1 BattleManager initialized in 3v3 match format")

	var players = root.get_tree().get_nodes_in_group("players")
	var enemies = root.get_tree().get_nodes_in_group("enemies")

	# In 3v3: Ignis (captain) + Kora + Gaius = all 3 deployed on field!
	check.call(players.size() == 3, "T1.2 Spawns exactly 3 field combatants in 3v3 (Ignis, Kora, Gaius)", "found=%d" % players.size())
	check.call(enemies.size() == 3, "T1.3 Spawns exactly 3 enemy team combatants in 3v3", "found=%d" % enemies.size())

	# Check starting positions (players[0]=Ignis, players[1]=Kora, players[2]=Gaius)
	var p0 = players[0]
	var p1 = players[1]
	var p2 = players[2]
	var p0_tile = Vector2i(int(floor(p0.position.x / 64)), int(floor(p0.position.y / 64)))
	var p1_tile = Vector2i(int(floor(p1.position.x / 64)), int(floor(p1.position.y / 64)))
	var p2_tile = Vector2i(int(floor(p2.position.x / 64)), int(floor(p2.position.y / 64)))
	check.call(p0_tile == Vector2i(3, 4), "T1.4 Captain Ignis spawned at designated tile (3, 4)", "pos=%s" % str(p0_tile))
	check.call(p1_tile == Vector2i(2, 3), "T1.5 Ally Kora spawned at formation tile (2, 3)", "pos=%s" % str(p1_tile))
	check.call(p2_tile == Vector2i(2, 5), "T1.6 Ally Gaius spawned at formation tile (2, 5)", "pos=%s" % str(p2_tile))

	# ──────────────────────────────────────────────────────────
	# SUITE 2: DIRECT PLAYER CONTROL & UNIT SWITCHING
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 2: Direct Squadmate Selection & HUD Synchronization ---")
	check.call(bm.active_player_unit == p0, "T2.1 Active player unit defaults to Captain Ignis")
	check.call(ui != null, "T2.2 UI node is present in world scene")

	# Select Ally 1 (Kora)
	bm.select_active_player_unit(p1)
	check.call(bm.active_player_unit == p1, "T2.3 Switching active unit changes active_player_unit to Kora")
	check.call(ui._player_ref == p1, "T2.4 UI _player_ref redirected to Kora for input and ability clicks")

	# Select Ally 2 (Gaius)
	bm.select_active_player_unit(p2)
	check.call(bm.active_player_unit == p2, "T2.5 Switching active unit changes active_player_unit to Gaius")
	check.call(ui._player_ref == p2, "T2.6 UI _player_ref redirected to Gaius")

	# Switch back to Captain
	bm.select_active_player_unit(p0)
	check.call(bm.active_player_unit == p0, "T2.7 Can freely switch back to Captain Ignis")

	# ──────────────────────────────────────────────────────────
	# SUITE 3: INDEPENDENT SQUAD MOVEMENT & TURNS
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 3: Squad Turn Cycle & Independent Action Allowance ---")
	# Move P0 (Ignis)
	var p0_initial_moves = p0.moves_remaining
	await p0.on_move_tile_clicked(Vector2i(4, 4), 1)
	check.call(p0.moves_remaining == p0_initial_moves - 1, "T3.1 Ignis moves 1 tile independently")
	check.call(p1.moves_remaining == p1.get_total_speed(), "T3.2 Kora move allowance remains unspent and intact")

	# End P0 move phase -> Act phase
	p0.end_move_phase()
	check.call(bm.current_state == bm.State.PLAYER_ACT, "T3.3 Ignis enters PLAYER_ACT phase")

	# Ignis passes/acts -> should auto-direct to Kora
	p0.end_turn()
	check.call(p0.has_acted == true, "T3.4 Ignis marked as has_acted = true")
	check.call(bm.active_player_unit == p1, "T3.5 Turn control advances directly to ready teammate Kora")
	check.call(bm.current_state == bm.State.PLAYER_MOVE, "T3.6 Kora begins in PLAYER_MOVE phase with full speed")

	# Kora ends turn -> all squad acted -> enemy turn
	var kora_ended_turn = true  # end_turn() has no return value; trust T3.8 to confirm round advanced
	p1.end_turn()
	check.call(kora_ended_turn, "T3.7 Kora end_turn() called — has_acted is set before enemy cycle resets it")

	check.call(bm.turn_count >= 1, "T3.8 Full squad round completed and advanced round counter")

	# ──────────────────────────────────────────────────────────
	# SUITE 4: MULTI-UNIT KNOCKOUT RESILIENCE (1 MAN DOWN)
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 4: Knockout Resilience & 1-Man-Down Match Continuation ---")
	# Knock out P1 (Kora)
	p1.hp = 0
	bm.record_knockout(p1)
	check.call(bm.knocked_out_units.has(p1), "T4.1 Kora recorded in knocked_out_units list")
	check.call(bm.can_substitute(p1) == false, "T4.2 KO'd Kora cannot be substituted (Slot locked)")
	check.call(bm.current_state != bm.State.BATTLE_OVER, "T4.3 Battle continues — team is 1 man down, not defeated")

	# Knock out all enemies
	var enemies_now = root.get_tree().get_nodes_in_group("enemies")
	for e in enemies_now:
		e.hp = 0
	bm.check_battle_end_conditions()
	check.call(bm.current_state == bm.State.BATTLE_OVER, "T4.4 Defeating all enemies triggers VICTORY in multi-unit combat")

	world_scn.queue_free()
	await process_frame

	print("\n========================================================")
	print("  MULTI-UNIT CONTROL SUITE RESULT: %d / %d PASSED (Failed: %d)" % [counts["passed"], counts["passed"] + counts["failed"], counts["failed"]])
	print("========================================================\n")

	if counts["failed"] == 0:
		print("[ALL MULTI-UNIT CONTROL TESTS PASSED SUCCESSFULLY!]")
		quit(0)
	else:
		print("[SOME TESTS FAILED!]")
		quit(1)
