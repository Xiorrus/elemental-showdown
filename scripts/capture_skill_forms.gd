extends SceneTree

func _init():
	_run.call_deferred()

func _run():
	print("[Capture] Starting 3-Form Progression & Combat HUD capture...")

	var cm = root.get_node_or_null("CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "VALEN", "player_element": "earth"})
		cm.player_level = 10
		cm.player_xp = 120
		cm.player_xp_to_next = 200
		cm.unspent_stat_points = 5
		cm.unspent_skill_points = 4
		cm.energy = 85
		cm.total_wins = 4
		cm.total_losses = 0

		# Unlock Stone Plating and Form 2, leave Form 3 locked to show both states
		cm.unlock_skill_node("Stone_Plating")
		cm.unlock_skill_form("Stone_Plating", "rock_pillar")
		cm.set_active_skill_form("Stone_Plating", "rock_pillar")

	var art_dir = "C:/Users/alexj/.gemini/antigravity/brain/3f3e849a-f15b-4bb0-ba75-7761da16036e/"
	var proj_dir = "C:/Users/alexj/Documents/elemental-showdown/screenshots/"

	# 1. Capture Skill Tree Inspector showing 3 forms with status badges and unlock buttons
	var ch = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(ch)
	for i in range(4): await process_frame

	ch._switch_tab(4)
	for i in range(4): await process_frame

	if ch.skill_tree_canvas:
		ch.skill_tree_canvas.focus_discipline("earth")
		for i in range(4): await process_frame
		ch.skill_tree_canvas.inspect_skill("Stone_Plating")
		for i in range(6): await process_frame

	_save_viewport(art_dir + "capture_skill_tree_forms_inspector.png", proj_dir + "capture_skill_tree_forms_inspector.png")

	ch.queue_free()
	for i in range(4): await process_frame

	# 2. Capture Combat HUD with Form Switching Controls
	if cm:
		cm.active_match_format = "1v1"
		cm.active_match_type = "tournament"
		cm.active_enemy_name = "Nami"
		cm.active_enemy_element = "water"
		cm.equipped_abilities = ["Stone_Plating", "Metal"]
		cm.unlock_skill_node("Metal")

	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	for i in range(8): await process_frame

	var player = world_scn.get_node_or_null("Player")
	var ui = world_scn.get_node_or_null("UI")
	if player and ui:
		player.select_ability(0)
		for i in range(4): await process_frame

	_save_viewport(art_dir + "capture_combat_form_switching.png", proj_dir + "capture_combat_form_switching.png")

	world_scn.queue_free()
	for i in range(4): await process_frame

	print("[Capture] 3-Form visual artifacts captured successfully!")
	quit(0)

func _save_viewport(dest_art: String, dest_proj: String):
	var img = root.get_texture().get_image()
	if img:
		var err1 = img.save_png(dest_art)
		var err2 = img.save_png(dest_proj)
		print("[Capture] Saved artifact: ", dest_art, " (Err: ", err1, ")")
		print("[Capture] Saved project: ", dest_proj, " (Err: ", err2, ")")
	else:
		printerr("[Capture] Failed to grab viewport image!")
