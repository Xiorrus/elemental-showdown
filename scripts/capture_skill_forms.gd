extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")
var capture_failed := false

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return
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
		if not cm.unlocked_abilities.has("Stone_Plating"):
			cm.unlock_skill_node("Stone_Plating")
		cm.unlock_skill_form("Stone_Plating", "rock_pillar")
		cm.set_active_skill_form("Stone_Plating", "rock_pillar")

	# 1. Capture Skill Tree Inspector showing 3 forms with status badges and unlock buttons
	var ch = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(ch)
	for i in range(4): await process_frame

	ch._switch_tab(4)
	ch._cultivation_subpage = 2
	ch._refresh_skills_tab()
	for i in range(4): await process_frame

	if ch.skill_tree_canvas:
		ch.skill_tree_canvas.focus_discipline("earth")
		for i in range(4): await process_frame
		ch.skill_tree_canvas.inspect_skill("Stone_Plating")
		for i in range(6): await process_frame

	_save_viewport("capture_skill_tree_forms_inspector.png")

	ch.queue_free()
	for i in range(4): await process_frame

	# 2. Capture Combat HUD with Form Switching Controls
	if cm:
		cm.active_match_format = "1v1"
		cm.active_match_type = "tournament"
		cm.active_enemy_name = "Nami"
		cm.active_enemy_element = "water"
		cm.equipped_abilities = ["Stone_Plating", "Metal"]
		if not cm.unlocked_abilities.has("Metal"):
			cm.unlock_skill_node("Metal")

	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	for i in range(8): await process_frame

	var player = world_scn.get_node_or_null("Player")
	var ui = world_scn.get_node_or_null("UI")
	if player and ui:
		player.select_ability(0)
		for i in range(4): await process_frame

	_save_viewport("capture_combat_form_switching.png")

	world_scn.queue_free()
	for i in range(4): await process_frame

	print("[Capture] 3-Form visual artifacts captured successfully!")
	quit(1 if capture_failed else 0)

func _save_viewport(file_name: String):
	if not CaptureOutput.save(root, file_name):
		capture_failed = true
