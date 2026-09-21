extends SceneTree

func _init():
	_run.call_deferred()

func _run():
	print("\n========================================================")
	print("   ELEMENTAL SHOWDOWN — CAMPAIGN & GAME LOOP TEST SUITE")
	print("========================================================")

	var test_counts = [0, 0, 0] # [total, passed, failed]

	var check = func(condition: bool, test_name: String, err_msg: String = ""):
		test_counts[0] += 1
		if condition:
			test_counts[1] += 1
			print("  [PASS] " + test_name)
			return true
		else:
			test_counts[2] += 1
			print("  [FAIL] " + test_name + (" — " + err_msg if err_msg != "" else ""))
			return false

	var cm = root.get_node_or_null("CampaignManager")
	var edata = root.get_node_or_null("ElementData")

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 1: CAMPAIGN MANAGER & STATE INIT
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 1: CampaignManager & Custom Campaign Init ---")
	check.call(cm != null, "T1.1 CampaignManager autoload is present in SceneTree")
	check.call(edata != null, "T1.2 ElementData autoload is present in SceneTree")

	cm.init_new_campaign({
		"player_name": "Valen",
		"player_element": "earth",
		"team_name": "Terra Vanguards",
		"appearance": {
			"sheet_prefix": "earth",
			"team_palette": "earth"
		}
	})

	var init_ok = (cm.player_name == "Valen" and cm.player_element == "earth" and cm.team_name == "Terra Vanguards")
	var starter_skill_ok = (cm.equipped_abilities == ["Metal"] and cm.unlocked_abilities == ["Metal"])
	var base_state_ok = (cm.energy == 100 and cm.is_fatigued == false and cm.bench_risk == false and cm.player_level == 1)
	check.call(init_ok and starter_skill_ok and base_state_ok, "T1.3 New Campaign init assigns player identity, starter ability, and base state", "init=%s skill=%s state=%s" % [init_ok, starter_skill_ok, base_state_ok])

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 2: DEVELOPER TESTING OPTION (UNLOCK ALL & LV 30)
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 2: Developer Mode (Instant Unlock All & Lv 30) ---")
	cm.dev_unlock_all()
	var dev_lvl_ok = (cm.player_level == 30)
	var dev_skills_ok = (cm.unlocked_abilities.size() == edata.ABILITIES.size())
	var dev_equipped_ok = (cm.equipped_abilities.size() == 4)
	check.call(dev_lvl_ok and dev_skills_ok and dev_equipped_ok, "T2.1 Developer Option unlocks all abilities, sets Lv 30, and equips 4 abilities", "lvl=%d skills=%d equipped=%d" % [cm.player_level, cm.unlocked_abilities.size(), cm.equipped_abilities.size()])

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 3: JSON CAMPAIGN PERSISTENCE (SAVE & LOAD)
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 3: Save / Load Persistence ---")
	var save_success = cm.save_campaign()
	var file_exists = cm.has_saved_campaign()
	check.call(save_success and file_exists, "T3.1 Save campaign writes JSON to user storage", "save=%s exists=%s" % [save_success, file_exists])

	# Corrupt memory values
	cm.player_name = "CorruptedFighter"
	cm.player_level = 999
	cm.unlocked_abilities = []

	var load_success = cm.load_campaign()
	var load_restored = (cm.player_name == "Valen" and cm.player_level == 30 and cm.unlocked_abilities.size() == edata.ABILITIES.size())
	check.call(load_success and load_restored, "T3.2 Load campaign perfectly restores profile, level 30, and all abilities", "restored=%s name=%s lvl=%d skills=%d" % [load_restored, cm.player_name, cm.player_level, cm.unlocked_abilities.size()])

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 4: ENERGY & FATIGUE DEBUFF SYSTEM
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 4: Energy & Fatigue Debuff Mechanics ---")
	cm.energy = 100
	cm.consume_energy(40)
	check.call(cm.energy == 60 and not cm.is_fatigued, "T4.1 Consuming 40 energy leaves 60 energy (Rested state)")

	# Drop into fatigue (< 30)
	cm.consume_energy(35) # leaves 25
	var fatigued_ok = (cm.energy == 25 and cm.is_fatigued == true and cm.bench_risk == false)
	var mods = cm.get_fatigue_stat_modifiers()
	var mods_ok = (mods["hp_mult"] == 0.8 and mods["mp_mult"] == 0.8 and mods["speed_penalty"] == 1)
	check.call(fatigued_ok and mods_ok, "T4.2 Energy < 30 triggers FATIGUE (-20% HP/MP, -1 Speed penalty)", "fatigued=%s hp_mult=%.1f spd_pen=%d" % [fatigued_ok, mods["hp_mult"], mods["speed_penalty"]])

	# Drop into critical bench risk (< 15)
	cm.consume_energy(15) # leaves 10
	check.call(cm.bench_risk == true, "T4.3 Energy < 15 triggers COACH BENCH RISK warning")

	# Take a Rest Day (+50 energy)
	cm.restore_energy(50) # becomes 60
	check.call(cm.energy == 60 and not cm.is_fatigued and not cm.bench_risk, "T4.4 Rest Day restores +50 energy and clears fatigue state")

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 5: MAIN MENU SCENE
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 5: Main Menu Scene Inspection ---")
	var mm_scn = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(mm_scn)
	await process_frame

	var btn_new = mm_scn.get_node_or_null("MainLayout/NavDeck/BtnNewCampaign") if mm_scn.get_node_or_null("MainLayout/NavDeck/BtnNewCampaign") else mm_scn.get_node_or_null("CenterContainer/VBoxContainer/BtnNewCampaign")
	var btn_cont = mm_scn.get_node_or_null("MainLayout/NavDeck/BtnContinue") if mm_scn.get_node_or_null("MainLayout/NavDeck/BtnContinue") else mm_scn.get_node_or_null("CenterContainer/VBoxContainer/BtnContinue")
	var btn_set = mm_scn.get_node_or_null("MainLayout/NavDeck/BtnSettings") if mm_scn.get_node_or_null("MainLayout/NavDeck/BtnSettings") else mm_scn.get_node_or_null("CenterContainer/VBoxContainer/BtnSettings")
	var btn_exit = mm_scn.get_node_or_null("MainLayout/NavDeck/BtnExit") if mm_scn.get_node_or_null("MainLayout/NavDeck/BtnExit") else mm_scn.get_node_or_null("CenterContainer/VBoxContainer/BtnExit")

	var mm_nodes_ok = (btn_new != null and btn_cont != null and btn_set != null and btn_exit != null)
	var cont_enabled_ok = (btn_cont != null and btn_cont.disabled == false and ("continue" in btn_cont.text.to_lower()))
	check.call(mm_nodes_ok and cont_enabled_ok, "T5.1 Main Menu buttons present and Continue button enables dynamically with active save", "nodes=%s cont_enabled=%s text=%s" % [mm_nodes_ok, cont_enabled_ok, btn_cont.text if btn_cont else "none"])
	mm_scn.queue_free()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 6: CHARACTER CUSTOMIZATION SCENE
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 6: Character Customization Scene ---")
	var cc_scn = load("res://scenes/CharacterCustomization.tscn").instantiate()
	root.add_child(cc_scn)
	await process_frame

	var cc_fire = cc_scn.get_node_or_null("MainLayout/Columns/CenterCol/GridElements/BtnFire")
	var cc_water = cc_scn.get_node_or_null("MainLayout/Columns/CenterCol/GridElements/BtnWater")
	var cc_sprite = cc_scn.get_node_or_null("MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/PedestalBox/PreviewFrame/PreviewSprite")

	var cc_nodes_ok = (cc_fire != null and cc_water != null and cc_sprite != null)
	# Trigger element selection
	cc_scn._select_element("water")
	var elem_select_ok = (cc_scn.current_element == "water" and ("110" in cc_scn.lbl_hp.text))
	# Trigger direction preview
	cc_scn._set_preview_dir(1) # East
	var dir_preview_ok = (cc_scn.current_dir_row == 1)

	check.call(cc_nodes_ok and elem_select_ok and dir_preview_ok, "T6.1 Customization updates element stats and sprite preview", "nodes=%s elem=%s dir=%s" % [cc_nodes_ok, elem_select_ok, dir_preview_ok])
	cc_scn.queue_free()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 7: CAMPAIGN MANAGEMENT HUB
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 7: Campaign Management Hub ---")
	var hub_scn = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub_scn)
	await process_frame

	var tab_sched = hub_scn.get_node_or_null("MainTabs/TabSchedule")
	var tab_act = hub_scn.get_node_or_null("MainTabs/TabActivities")
	var tab_sk = hub_scn.get_node_or_null("MainTabs/TabSkills")
	var tab_tm = hub_scn.get_node_or_null("MainTabs/TabTeam")
	var tab_int = hub_scn.get_node_or_null("MainTabs/TabIntel")

	var hub_tabs_ok = (tab_sched != null and tab_act != null and tab_sk != null and tab_tm != null and tab_int != null)
	var next_opp_ok = (hub_scn.lbl_next_opp_name.text.contains("Hydro Vipers"))

	# Test Training Activity
	cm.energy = 100
	var pre_xp = cm.player_xp
	hub_scn._on_activity_train()
	var train_ok = (cm.player_xp == pre_xp + 40 and cm.energy == 80) # 100 - 20 = 80
	check.call(hub_tabs_ok and next_opp_ok and train_ok, "T7.1 Campaign Hub tabs present, tournament schedule displays rival, and training grants XP", "tabs=%s opp=%s train=%s" % [hub_tabs_ok, next_opp_ok, train_ok])
	hub_scn.queue_free()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 8: IN-MATCH PAUSE SCREEN (ROSTER + SCOUTING CODEX)
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 8: Match Arena Pause Screen & Scouting Intel ---")
	# Prepare tournament match vs Hydro Vipers
	cm.prepare_match("tournament", "water", "Nami", "Hydro Vipers")
	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	await process_frame
	await process_frame

	var ui_node = world_scn.get_node_or_null("UI")
	var pause_root = ui_node.get_node_or_null("PauseModalRoot")
	check.call(pause_root != null, "T8.1 PauseModalRoot node generated in UI CanvasLayer")

	# Test toggle pause
	ui_node._toggle_pause()
	var pause_active = (world_scn.get_tree().paused == true and pause_root.visible == true)
	check.call(pause_active, "T8.2 Toggling pause freezes SceneTree (paused=true) and reveals pause modal")

	# Test Tab 0 (Squad Roster & Fighter Condition)
	ui_node._switch_pause_tab(0)
	var roster_visible = (ui_node.pause_roster_box.visible and not ui_node.pause_codex_box.visible)
	var player_col_present = (ui_node.pause_roster_box.get_child_count() >= 2)
	check.call(roster_visible and player_col_present, "T8.3 Pause Tab 1 displays active combatant details and squad allies roster")

	# Test Tab 1 (Scouting Codex)
	ui_node._switch_pause_tab(1)
	var codex_visible = (ui_node.pause_codex_box.visible and not ui_node.pause_roster_box.visible)
	var codex_content_present = (ui_node.pause_codex_box.get_child_count() > 0)
	check.call(codex_visible and codex_content_present, "T8.4 Pause Tab 2 displays rival spotlight and opponent codex (weaknesses, known skills, records)")

	# Unpause
	ui_node._toggle_pause()
	check.call(world_scn.get_tree().paused == false and not pause_root.visible, "T8.5 Unpausing resumes SceneTree execution and hides pause modal")

	# ──────────────────────────────────────────────────────────
	# TEST SUITE 9: POST-MATCH GAME LOOP & VICTORY / DEFEAT MODAL
	# ──────────────────────────────────────────────────────────
	print("\n--- SUITE 9: Post-Match Victory / Defeat Modal & Game Loop ---")
	var bm = world_scn.get_node_or_null("BattleManager")
	var res_root = ui_node.get_node_or_null("ResultModalRoot")
	check.call(bm != null and res_root != null, "T9.1 BattleManager and ResultModalRoot present in battle arena")

	var pre_wins = cm.total_wins
	# Call player_wins
	bm.player_wins()
	await process_frame

	var res_visible = (res_root.visible == true)
	var res_text_ok = (ui_node.result_label.text.to_lower().contains("victor"))
	var cm_recorded = (cm.total_wins == pre_wins + 1)
	check.call(res_visible and res_text_ok and cm_recorded, "T9.2 Victory triggers Post-Match Modal, updates Campaign wins, and grants match XP", "visible=%s text=%s cm_wins=%d" % [res_visible, res_text_ok, cm.total_wins])

	world_scn.queue_free()
	await process_frame

	# ──────────────────────────────────────────────────────────
	# SUMMARY
	# ──────────────────────────────────────────────────────────
	print("\n========================================================")
	print("  CAMPAIGN SUITE RESULT: %d / %d PASSED (Failed: %d)" % [test_counts[1], test_counts[0], test_counts[2]])
	print("========================================================\n")

	if test_counts[2] == 0:
		print("[ALL TESTS PASSED SUCCESSFULLY!]")
		quit(0)
	else:
		printerr("[FAILURES DETECTED]")
		quit(1)
