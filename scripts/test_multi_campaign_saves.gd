# test_multi_campaign_saves.gd
# Headless verification suite for multi-save campaign slots, archives UI, and backward compatibility.
extends SceneTree

var passed: int = 0
var failed: int = 0

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("  [PASS] " + label)
	else:
		failed += 1
		printerr("  [FAIL] " + label)

func _init():
	_run.call_deferred()

func _run():
	var safe_root = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(safe_root):
		printerr("Redirect APPDATA beneath this project's .godot directory before running save tests.")
		quit(2)
		return

	await process_frame
	print("\n========================================================")
	print("   ELEMENTAL SHOWDOWN — MULTI-SAVE CAMPAIGN TEST SUITE")
	print("========================================================")

	var cm = root.get_node_or_null("CampaignManager")
	check(cm != null, "T0.1 CampaignManager autoload is present in SceneTree")
	if not cm:
		quit(1)
		return

	# Clean up any test save files in user://saves/
	var dir = DirAccess.open(cm.SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var fn = dir.get_next()
		while fn != "":
			if fn.ends_with(".json") or fn.ends_with(".tmp"):
				DirAccess.remove_absolute(cm.SAVES_DIR + "/" + fn)
			fn = dir.get_next()
		dir.list_dir_end()
	if FileAccess.file_exists(cm.SAVE_PATH):
		DirAccess.remove_absolute(cm.SAVE_PATH)

	# --- SUITE 1: Independent Campaign Slot Allocation ---
	print("\n--- SUITE 1: Independent Campaign Slot Allocation ---")
	var slot_ignis = cm.create_new_campaign_slot("Ignis Blade")
	check(slot_ignis.begins_with("user://saves/campaign_") and slot_ignis.ends_with(".json"), "T1.1 Slot 1 path matches user://saves/ pattern")
	cm.init_new_campaign({
		"player_name": "Ignis Blade",
		"player_element": "fire",
		"team_name": "Phoenix Strikers",
		"start_solo": false
	})
	var save_1_ok = cm.save_campaign()
	check(save_1_ok and FileAccess.file_exists(slot_ignis), "T1.2 Ignis campaign saved to its own slot file")

	# Small wait to ensure distinct unix timestamps
	OS.delay_msec(1100)

	var slot_aqua = cm.create_new_campaign_slot("Aqua Torrent")
	check(slot_aqua != slot_ignis, "T1.3 Slot 2 receives unique distinct path")
	cm.init_new_campaign({
		"player_name": "Aqua Torrent",
		"player_element": "water",
		"team_name": "Tide Breakers",
		"start_solo": false
	})
	var save_2_ok = cm.save_campaign()
	check(save_2_ok and FileAccess.file_exists(slot_aqua), "T1.4 Aqua campaign saved to its own slot file")

	OS.delay_msec(1100)

	var slot_terra = cm.create_new_campaign_slot("Terra Bastion")
	check(slot_terra != slot_ignis and slot_terra != slot_aqua, "T1.5 Slot 3 receives unique distinct path")
	cm.init_new_campaign({
		"player_name": "Terra Bastion",
		"player_element": "earth",
		"team_name": "Stone Wardens",
		"start_solo": true
	})
	var save_3_ok = cm.save_campaign()
	check(save_3_ok and FileAccess.file_exists(slot_terra), "T1.6 Terra campaign saved to its own slot file")

	check(FileAccess.file_exists(slot_ignis), "T1.7 Ignis file exists and was not overwritten by subsequent campaigns")
	check(FileAccess.file_exists(slot_aqua), "T1.8 Aqua file exists and was not overwritten by subsequent campaigns")

	# --- SUITE 2: Independent Loading & State Isolation ---
	print("\n--- SUITE 2: Independent Loading & State Isolation ---")
	var load_ignis = cm.load_campaign(slot_ignis)
	check(load_ignis and cm.player_name == "Ignis Blade" and cm.player_element == "fire" and cm.team_name == "Phoenix Strikers", "T2.1 Ignis slot loaded with authentic identity and team")

	var load_aqua = cm.load_campaign(slot_aqua)
	check(load_aqua and cm.player_name == "Aqua Torrent" and cm.player_element == "water" and cm.team_name == "Tide Breakers", "T2.2 Aqua slot loaded with authentic identity and team")

	var load_terra = cm.load_campaign(slot_terra)
	check(load_terra and cm.player_name == "Terra Bastion" and cm.player_element == "earth", "T2.3 Terra slot loaded with authentic identity and team")

	# Mutate Aqua campaign only
	cm.load_campaign(slot_aqua)
	cm.gold = 7777
	cm.campaign_day = 42
	cm.player_level = 9
	cm.save_campaign()

	# Reload Ignis and verify zero cross-contamination
	cm.load_campaign(slot_ignis)
	check(cm.player_name == "Ignis Blade" and cm.gold != 7777 and cm.campaign_day != 42 and cm.player_level == 1, "T2.4 Ignis campaign remains completely isolated from Aqua mutations")

	# Reload Aqua and verify mutations persisted
	cm.load_campaign(slot_aqua)
	check(cm.player_name == "Aqua Torrent" and cm.gold == 7777 and cm.campaign_day == 42 and cm.player_level == 9, "T2.5 Aqua campaign mutations persisted faithfully")

	# --- SUITE 3: Catalog Listing & Metadata Retrieval ---
	print("\n--- SUITE 3: Catalog Listing & Metadata Retrieval ---")
	var saves_list = cm.get_saved_campaigns()
	check(saves_list.size() == 3, "T3.1 get_saved_campaigns() discovers all 3 independent slots")

	# Aqua was saved most recently, so it must be first in the sorted list
	check(saves_list[0]["player_name"] == "Aqua Torrent", "T3.2 Most recently saved campaign (Aqua) is sorted first")
	check(cm.get_latest_save_path() == slot_aqua, "T3.3 get_latest_save_path() returns the path to Aqua")

	var aqua_meta = saves_list[0]
	check(aqua_meta["player_element"] == "water" and aqua_meta["gold"] == 7777 and aqua_meta["player_level"] == 9, "T3.4 Header metadata includes accurate level, gold, and element")

	# --- SUITE 4: Deletion & Active Slot Recovery ---
	print("\n--- SUITE 4: Deletion & Active Slot Recovery ---")
	var del_ok = cm.delete_saved_campaign(slot_terra)
	check(del_ok, "T4.1 delete_saved_campaign() returns true for valid slot")
	check(not FileAccess.file_exists(slot_terra), "T4.2 Terra slot file deleted from disk")
	check(cm.get_saved_campaigns().size() == 2, "T4.3 Catalog now reports exactly 2 saves remaining")
	check(FileAccess.file_exists(slot_ignis) and FileAccess.file_exists(slot_aqua), "T4.4 Remaining save slots remain intact")

	# --- SUITE 5: Campaign Duplication (Branching Saves) ---
	print("\n--- SUITE 5: Campaign Duplication ---")
	var dup_path = cm.duplicate_saved_campaign(slot_ignis, "Ignis Branch")
	check(dup_path != "" and FileAccess.file_exists(dup_path), "T5.1 Duplicate slot created successfully")
	var dup_header = cm._read_campaign_header(dup_path)
	check(dup_header.get("player_name", "") == "Ignis Branch" and dup_header.get("player_element", "") == "fire", "T5.2 Duplicated campaign retains element and receives new character name")
	check(cm.get_saved_campaigns().size() == 3, "T5.3 Catalog now reflects original plus duplicated slot")

	# Clean up duplicate
	cm.delete_saved_campaign(dup_path)

	# --- SUITE 6: Legacy Save Compatibility ---
	print("\n--- SUITE 6: Legacy Save Compatibility ---")
	# Create legacy user://campaign_save.json
	cm.create_new_campaign_slot("Legacy Champion")
	cm.init_new_campaign({
		"player_name": "Legacy Champion",
		"player_element": "air",
		"team_name": "Cloud Striders"
	})
	cm.save_campaign(cm.SAVE_PATH)
	check(FileAccess.file_exists(cm.SAVE_PATH), "T6.1 Legacy save file successfully written to root user://")

	var legacy_header = cm._read_campaign_header(cm.SAVE_PATH)
	check(legacy_header.get("is_legacy", false) == true and legacy_header.get("player_element", "") == "air", "T6.2 Legacy header accurately identified with is_legacy=true")

	var all_saves = cm.get_saved_campaigns()
	var has_legacy_in_list = false
	for s in all_saves:
		if s.get("path") == cm.SAVE_PATH:
			has_legacy_in_list = true
			break
	check(has_legacy_in_list, "T6.3 Legacy save is seamlessly included in Campaign Archives catalog")

	# --- SUITE 7: Main Menu UI Integration ---
	print("\n--- SUITE 7: Main Menu UI Integration ---")
	var menu_scene = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu_scene)
	await process_frame

	var btn_archives = menu_scene.get_node_or_null("MainLayout/NavDeck/BtnSelectCampaign")
	check(btn_archives != null, "T7.1 BtnSelectCampaign exists in MainMenu NavDeck")

	var archives_modal = menu_scene.get_node_or_null("CampaignsModal")
	check(archives_modal != null and archives_modal.visible == false, "T7.2 CampaignsModal exists in MainMenu and starts hidden")

	var btn_continue = menu_scene.get_node_or_null("MainLayout/NavDeck/BtnContinue")
	check(btn_continue != null and btn_continue.disabled == false, "T7.3 BtnContinue is enabled when saves exist")
	check("continue" in btn_continue.text.to_lower(), "T7.4 BtnContinue contains 'Continue' text")

	# Open the archives modal
	menu_scene._on_open_campaigns_modal()
	check(archives_modal.visible == true, "T7.5 CampaignsModal opens upon request")

	var cards_container = menu_scene.get_node_or_null("CampaignsModal/DialogPanel/Margin/VBox/ScrollContainer/CardsContainer")
	check(cards_container != null, "T7.6 CardsContainer found in CampaignsModal")
	var visible_cards = 0
	for child in cards_container.get_children():
		if child is PanelContainer:
			visible_cards += 1
	check(visible_cards >= 2, "T7.7 Campaign archive cards populated in UI modal (found %d cards)" % visible_cards)

	# Close the modal
	menu_scene._on_close_campaigns_modal()
	check(archives_modal.visible == false, "T7.8 CampaignsModal closes upon request")

	menu_scene.queue_free()
	await process_frame

	# Cleanup test saves
	cm.delete_saved_campaign(slot_ignis)
	cm.delete_saved_campaign(slot_aqua)
	if FileAccess.file_exists(cm.SAVE_PATH):
		DirAccess.remove_absolute(cm.SAVE_PATH)

	print("\n========================================================")
	print("  MULTI-SAVE SUITE RESULT: %d / %d PASSED (Failed: %d)" % [passed, passed + failed, failed])
	print("========================================================")
	if failed == 0:
		print("[ALL MULTI-SAVE TESTS PASSED SUCCESSFULLY!]")
		quit(0)
	else:
		printerr("[SOME MULTI-SAVE TESTS FAILED]")
		quit(1)
