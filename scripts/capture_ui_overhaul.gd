extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")
var capture_failed := false

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return

	var cm = root.get_node_or_null("CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "VALEN", "player_element": "earth", "start_solo": false})
		cm.player_level = 5
		cm.player_xp = 60
		cm.player_xp_to_next = 130
		cm.unspent_stat_points = 3
		cm.unspent_skill_points = 2
		cm.energy = 85
		cm.equipped_abilities = ["Gale_Step", "Wind", "Sound", "Oxygen"]
		cm.unlocked_abilities = ["Gale_Step", "Wind", "Sound", "Oxygen"]

	# 1. Training Pop-up
	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)
	for i in range(4): await process_frame
	hub._on_activity_train()
	for i in range(4): await process_frame
	_save_viewport("capture_training_popup.png")

	var train_pop = hub.get_node_or_null("TrainingFocusPopup")
	if train_pop: train_pop.queue_free()
	for i in range(2): await process_frame

	# 2. Rest Pop-up
	hub._on_activity_rest()
	for i in range(4): await process_frame
	_save_viewport("capture_rest_popup.png")

	var rest_pop = hub.get_node_or_null("RestDurationPopup")
	if rest_pop: rest_pop.queue_free()
	for i in range(2): await process_frame

	# 3. Deployment Tab with Custom Tooltip
	hub._switch_tab(2)
	for i in range(4): await process_frame
	var ally_tile = null
	for child in hub.find_children("*", "Button", true, false):
		if child.has_method("setup_ally") and child.ally_name != "":
			ally_tile = child
			break
	if ally_tile:
		var tt = ally_tile._make_custom_tooltip(ally_tile.tooltip_text)
		if tt:
			tt.position = Vector2(400, 250)
			tt.name = "TestTooltip"
			hub.add_child(tt)
	for i in range(4): await process_frame
	_save_viewport("capture_deployment_tooltip.png")

	hub.queue_free()
	for i in range(4): await process_frame

	# 4. In-Combat Tactical Battle Arena (3v3 format with log history and 2-part skill buttons)
	if cm:
		cm.active_match_format = "3v3"
		cm.active_match_type = "tournament"
		cm.active_enemy_name = "Nami"
		cm.active_enemy_element = "water"

	var world_scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(world_scn)
	for i in range(6): await process_frame

	var ui_node = world_scn.get_node_or_null("UI")
	if ui_node:
		ui_node.log_action("All squad units completed actions. Passing to enemy turn.")
		ui_node.log_action("[BLITZ STEAL] Timeline intercepted!")
		ui_node.log_action("Paced breath: +15% Stamina")
		ui_node.log_action("Skill: Wind (Range 3)")
		ui_node.log_action("[You] Gust Strike -> 49 dmg +25% close range")
		ui_node.log_action("All squad units completed actions. Passing to enemy turn.")
		ui_node.log_action("[Enemy] [Sustain] Hydration Touch recovered 40 HP!")
		ui_node.log_action("[Enemy] [Lethal] Geyser Eruption -> 38 dmg to Voss Edge!")
		ui_node.log_action("[Player] Braced Guard absorbed 15 impact damage!")
		ui_node.log_action("--- Round 2: Squad Action Phase ---")
		ui_node.update_squad_bar()
		ui_node.highlight_ability_slot(1)
	for i in range(6): await process_frame
	_save_viewport("capture_combat_3v3_hud.png")

	world_scn.queue_free()
	await process_frame
	quit(1 if capture_failed else 0)

func _save_viewport(file_name: String):
	if not CaptureOutput.save(root, file_name):
		capture_failed = true
