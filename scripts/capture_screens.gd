extends SceneTree

func _init():
	_run.call_deferred()

func _run():
	print("[Capture] Starting comprehensive visual capture sequence for all Elemental Showdown UIs...")

	var cm = root.get_node_or_null("CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "VALEN", "player_element": "earth"})
		cm.player_level = 5
		cm.player_xp = 60
		cm.player_xp_to_next = 130
		cm.unspent_stat_points = 3
		cm.unspent_skill_points = 2
		cm.energy = 40
		cm.total_wins = 3
		cm.total_losses = 0
		if cm.tournament_schedule.size() > 0:
			cm.tournament_schedule[0]["completed"] = true
			cm.tournament_schedule[0]["result"] = "VICTORY"
		cm.equipped_abilities = ["Metal", "Stone_Plating"]
		cm.unlocked_abilities = ["Metal", "Stone_Plating", "Sand", "Crystal"]

	var art_dir = "C:/Users/alexj/.gemini/antigravity/brain/3f3e849a-f15b-4bb0-ba75-7761da16036e/screenshots_new_ui/"

	# 1. Campaign Hub Tabs
	var ch = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(ch)
	for i in range(4): await process_frame

	# Tab 4: Player Management & Stat Allocation
	ch._switch_tab(4)
	for i in range(4): await process_frame
	_save_viewport(art_dir + "capture_hub_player.png")

	# Tab 2: Tactical Deployment Workbench
	ch._switch_tab(2)
	for i in range(4): await process_frame
	_save_viewport(art_dir + "capture_hub_deployment.png")

	ch.queue_free()
	await process_frame

	# 2. In-Combat Tactical Battle Arena (1v1 Duel Format)
	if cm:
		cm.active_match_format = "1v1"
		cm.active_match_type = "street"
		cm.active_enemy_name = "Zero (The Rival)"
		cm.active_enemy_element = "zero"

	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	for i in range(6): await process_frame

	var ui_node = world_scn.get_node_or_null("UI")

	# 2a. Tactical HUD in 1v1 battle (showing NO SUBS (1v1) disabled button)
	_save_viewport(art_dir + "capture_combat_1v1_hud.png")

	# 2b. Post-Match Victory Modal
	if ui_node:
		ui_node.show_battle_result(true, 75, 5)
		for i in range(4): await process_frame
		_save_viewport(art_dir + "capture_combat_victory.png")

	world_scn.queue_free()
	await process_frame

	print("[Capture] ALL SCREENS captured successfully!")
	quit(0)

func _save_viewport(dest_path: String):
	var img = root.get_texture().get_image()
	if img:
		var err = img.save_png(dest_path)
		print("[Capture] Saved: ", dest_path, " (Err: ", err, ")")
		var file_name = dest_path.get_file()
		var proj_path = "C:/Users/alexj/Documents/elemental-showdown/screenshots/new_ui/" + file_name
		img.save_png(proj_path)
	else:
		printerr("[Capture] Failed to capture image for: ", dest_path)
