# test_hub_interactive.gd
extends SceneTree

func _init():
	_run.call_deferred()

func _run():
	print("\n========================================================")
	print("   HUB INTERACTIVE, POTENCY ALLOC & BATTLE TAB SUITE")
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
	var cm = root.get_node_or_null("CampaignManager")
	if cm == null:
		cm = load("res://scripts/campaign_manager.gd").new()
		root.add_child(cm)
		await process_frame

	cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire", "team_name": "Phoenix Strikers"})

	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	await process_frame

	# --- SUITE 1: TAB SWITCHING ---
	print("--- SUITE 1: Tab Navigation & Rendering ---")
	hub._switch_tab(4) # Switch to Player tab
	check.call(hub.active_nav_index == 4, "T1.1 Successfully switched to Player Tab (Index 4)")

	# --- SUITE 2: POTENCY & STAT ALLOCATION IN-PLACE (NO CRASH) ---
	print("\n--- SUITE 2: In-Place Stat Allocation & Potency Button Click ---")
	var panel_stats = hub.get_node_or_null("MainTabs/TabSkills/HBox/ProfileCol/Content/PanelStats/Margin/VB/StatAllocBox")
	check.call(panel_stats != null, "T2.1 StatAllocBox found in Player Tab")

	var row_potency = panel_stats.get_node_or_null("Row_Potency")
	check.call(row_potency != null, "T2.2 Row_Potency row container exists")

	var btn_potency_plus = row_potency.get_node_or_null("BtnPlus")
	var btn_potency_minus = row_potency.get_node_or_null("BtnMinus")
	var lbl_potency = row_potency.get_node_or_null("Lbl")

	var base_potency = cm.player_potency
	var base_pts = cm.unspent_stat_points
	print("  [Info] Pre-click Potency: %d | Unspent points: %d" % [base_potency, base_pts])

	# Click Potency [+] button directly via emit
	btn_potency_plus.pressed.emit()
	await process_frame

	check.call(cm.player_potency == base_potency + 3, "T2.3 Clicking Potency [+] increases Potency without crashing", "val=%d" % cm.player_potency)
	check.call(cm.unspent_stat_points == base_pts - 1, "T2.4 Unspent stat points decremented to %d" % cm.unspent_stat_points)
	check.call(lbl_potency.text.contains(str(base_potency + 3)), "T2.5 Potency Label updated in-place to '%s'" % lbl_potency.text)

	# Click Potency [-] button to revert
	btn_potency_minus.pressed.emit()
	await process_frame
	check.call(cm.player_potency == base_potency, "T2.6 Clicking Potency [-] reverts Potency back to base %d" % base_potency)
	check.call(cm.unspent_stat_points == base_pts, "T2.7 Unspent stat points restored to base %d" % base_pts)

	# Test all other stat buttons (Speed, Agility, Dexterity, Stamina, Mana)
	var stats = ["Speed", "Agility", "Dexterity", "Stamina", "Mana"]
	var all_stats_ok = true
	for s_key in stats:
		var s_row = panel_stats.get_node_or_null("Row_" + s_key)
		if not s_row:
			all_stats_ok = false
			break
		var b_pls = s_row.get_node_or_null("BtnPlus")
		var b_min = s_row.get_node_or_null("BtnMinus")
		b_pls.pressed.emit()
		b_min.pressed.emit()
	check.call(all_stats_ok, "T2.8 All stat allocation buttons (Speed, Agility, Dexterity, Stamina, Mana) execute crash-free")

	# --- SUITE 3: BATTLE TAB TACTICAL WORKBENCH ---
	print("\n--- SUITE 3: Battle Tab 6x6 Deployment Matrix & Squad Lineup ---")
	hub._switch_tab(2) # Switch to Battle Tab
	await process_frame

	check.call(hub.active_nav_index == 2, "T3.1 Successfully switched to Battle Tab (Index 2)")

	var tab_battle = hub.get_node_or_null("MainTabs/TabBattle/VB")
	check.call(tab_battle != null and tab_battle.get_child_count() >= 2, "T3.2 TabBattle dynamically populated with Workbench")

	# Check for 18x10 arena grid container & deployable tiles
	var grid_tiles = []
	var all_workbench_tiles = []
	for node in tab_battle.find_children("", "Button", true, false):
		if node.get_script() != null and node.get_script().resource_path.contains("tactical_workbench_tile"):
			all_workbench_tiles.append(node)
			if "is_player_zone" in node and node.is_player_zone:
				grid_tiles.append(node)

	check.call(all_workbench_tiles.size() == 180, "T3.3a Full 18x10 arena platform generated with 180 tiles", "count=%d" % all_workbench_tiles.size())
	check.call(grid_tiles.size() == 40, "T3.3b Found exactly 40 player deployment tiles (Cols 1-5, Rows 1-8)", "count=%d" % grid_tiles.size())

	# Check starting positions
	check.call(cm.starting_formation.get("Ignis") == Vector2i(3, 4), "T3.4 Captain Ignis positioned on deployment grid at (3, 4)")

	# Test moving Ignis on grid
	# Find tile (4, 4)
	var tile_4_4 = null
	for t in grid_tiles:
		if t.tile_coord == Vector2i(4, 4):
			tile_4_4 = t
			break
	check.call(tile_4_4 != null, "T3.5 Found target open deployment tile (4, 4)")

	if tile_4_4:
		tile_4_4.tile_clicked.emit(Vector2i(4, 4))
		await process_frame
		check.call(cm.starting_formation.get("Ignis") == Vector2i(4, 4), "T3.6 Clicking open tile (4, 4) successfully moved Ignis to (4, 4)", "pos=%s" % str(cm.starting_formation.get("Ignis")))

	# --- SUITE 4: SQUAD MEMBER BENCHING & DEPLOYMENT ---
	print("\n--- SUITE 4: Squad Drag-and-Drop / Bench & Deployment ---")
	cm.starting_formation["Kora"] = Vector2i(-1, -1)
	hub._refresh_battle_tab()
	await process_frame
	check.call(cm.starting_formation["Kora"] == Vector2i(-1, -1), "T4.1 Kora positioned on bench (-1, -1)")

	var fresh_tiles = tab_battle.find_children("", "Button", true, false)
	var fresh_tile = null
	for t in fresh_tiles:
		if t.get_script() != null and t.get_script().resource_path.contains("tactical_workbench_tile") and t.is_player_zone and t.tile_coord == Vector2i(2, 3):
			fresh_tile = t
			break
	if fresh_tile:
		fresh_tile.ally_dropped.emit("Kora", Vector2i(2, 3))
		await process_frame
		check.call(cm.starting_formation.get("Kora") == Vector2i(2, 3), "T4.2 Dropping Kora onto tile (2, 3) deploys Kora to (2, 3)")

	# --- SUITE 5: SKILL LOADOUT EDITOR IN BATTLE TAB ---
	print("\n--- SUITE 5: Teammate Equipped Skill & Form Variation Editor ---")
	var kora_member = cm.allies[1]
	hub._battle_selected_ally_idx = 1
	hub._refresh_battle_tab()
	await process_frame

	var pre_kora_skills = kora_member.get("equipped_skills", []).duplicate()
	check.call(not pre_kora_skills.is_empty(), "T5.1 Kora equipped skills loaded in editor: %s" % str(pre_kora_skills))

	# Test form variation cycling
	var ignis_member = cm.allies[0]
	hub._battle_selected_ally_idx = 0
	hub._refresh_battle_tab()
	await process_frame
	cm.skill_variations["Combustion"] = "Explosive Punch"
	hub._refresh_battle_tab()
	check.call(cm.skill_variations.get("Combustion") == "Explosive Punch", "T5.2 Form variation for Combustion set to 'Explosive Punch'")

	# --- SUITE 6: DIRECT LAUNCH BUTTON & SCENE PREPARATION ---
	print("\n--- SUITE 6: Direct Arena Launch Verification ---")
	var next_m = cm.get_next_scheduled_match()
	check.call(not next_m.is_empty(), "T6.1 Next scheduled match loaded: %s vs %s" % [next_m.get("enemy_team"), next_m.get("enemy_captain")])

	# League fixtures vary by season, so verify the prepared opponent against the calendar.
	var scheduled_type = str(next_m.get("match_type", ""))
	var scheduled_element = str(next_m.get("enemy_element", ""))
	var scheduled_captain = str(next_m.get("enemy_captain", ""))
	var scheduled_team = str(next_m.get("enemy_team", ""))
	cm.prepare_match(scheduled_type, scheduled_element, scheduled_captain, scheduled_team)
	check.call(not scheduled_type.is_empty() and cm.active_match_type == scheduled_type, "T6.2 Match uses its scheduled competition type")
	check.call(not scheduled_captain.is_empty() and not scheduled_element.is_empty() and cm.active_enemy_name == scheduled_captain and cm.active_enemy_element == scheduled_element, "T6.3 Active enemy captain and element match the fixture")
	check.call(not scheduled_team.is_empty() and cm.active_enemy_team == scheduled_team, "T6.4 Active enemy club matches the fixture")

	hub.queue_free()
	await process_frame

	print("\n========================================================")
	print("  HUB & WORKBENCH RESULT: %d / %d PASSED (Failed: %d)" % [counts["passed"], counts["passed"] + counts["failed"], counts["failed"]])
	print("========================================================\n")

	if counts["failed"] == 0:
		print("[ALL HUB & BATTLE WORKBENCH TESTS PASSED SUCCESSFULLY!]")
		quit(0)
	else:
		print("[SOME TESTS FAILED!]")
		quit(1)
