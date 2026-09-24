# capture_campaign_screens.gd
extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")
var capture_failed := false

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return
	await process_frame
	var cm = root.get_node_or_null("CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "Ignis", "player_element": "fire"})
		cm.player_level = 14
		cm.player_xp = 85
		cm.player_xp_to_next = 150
		cm.energy = 90
		cm.total_wins = 3
		cm.total_losses = 0
		cm.equipped_abilities = ["Combustion", "Laser", "Lightning", "Plasma"]
		cm.unlocked_abilities = ["Combustion", "Laser", "Lightning", "Plasma", "Thermal_Radiation", "Superheated_Blast", "Magma", "Steam"]
		cm.starting_formation["Ignis"] = Vector2i(3, 4)
		cm.starting_formation["Kora"] = Vector2i(2, 3)
		cm.starting_formation["Gaius"] = Vector2i(2, 5)

	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)

	for i in range(4):
		await process_frame

	# 1. Tab 0: Hub
	hub._switch_tab(0)
	for i in range(3): await process_frame
	_capture("capture_hub_overview.png")

	# 2. Tab 1: Roster
	hub._switch_tab(1)
	for i in range(3): await process_frame
	_capture("capture_hub_roster.png")

	# 3. Tab 2: Battle Blueprint 6x6
	hub._switch_tab(2)
	for i in range(3): await process_frame
	_capture("capture_hub_battle_map.png")

	# 4. Tab 3: Ladder & Scouting
	hub._switch_tab(3)
	for i in range(3): await process_frame
	_capture("capture_hub_ladder.png")

	# 5. Tab 4: Player (Skills, Stats, Consumables, Dev Mode)
	hub._switch_tab(4)
	for i in range(3): await process_frame
	_capture("capture_hub_player.png")

	hub.queue_free()
	await process_frame
	quit(1 if capture_failed else 0)

func _capture(file_name: String):
	if not CaptureOutput.save(root, file_name):
		capture_failed = true
