# capture_multi_saves_ui.gd
# Captures visual snapshots of MainMenu and the Campaign Archives modal.
extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return

	await process_frame
	var cm = root.get_node_or_null("CampaignManager")
	if not cm:
		quit(1)
		return

	# Setup 3 sample campaigns in saves dir
	cm._ensure_saves_dir()

	# 1. Ignis
	var p1 = cm.create_new_campaign_slot("Ignis")
	cm.init_new_campaign({
		"player_name": "Ignis",
		"player_element": "fire",
		"team_name": "Phoenix Strikers",
		"start_solo": false
	})
	cm.player_level = 8
	cm.league_tier = 2
	cm.campaign_day = 14
	cm.season_number = 1
	cm.season_week = 3
	cm.total_wins = 12
	cm.total_losses = 2
	cm.gold = 750
	cm.save_campaign(p1)

	OS.delay_msec(100)

	# 2. Aqua
	var p2 = cm.create_new_campaign_slot("Aqua")
	cm.init_new_campaign({
		"player_name": "Aqua",
		"player_element": "water",
		"team_name": "Tide Breakers",
		"start_solo": false
	})
	cm.player_level = 5
	cm.league_tier = 1
	cm.campaign_day = 8
	cm.season_number = 1
	cm.season_week = 2
	cm.total_wins = 6
	cm.total_losses = 1
	cm.gold = 420
	cm.save_campaign(p2)

	OS.delay_msec(100)

	# 3. Terra
	var p3 = cm.create_new_campaign_slot("Terra")
	cm.init_new_campaign({
		"player_name": "Terra",
		"player_element": "earth",
		"team_name": "",
		"start_solo": true
	})
	cm.player_level = 3
	cm.league_tier = 1
	cm.campaign_day = 4
	cm.total_wins = 3
	cm.total_losses = 0
	cm.gold = 210
	cm.save_campaign(p3)

	var menu = load("res://scenes/MainMenu.tscn").instantiate()
	root.add_child(menu)

	for i in range(5):
		await process_frame

	CaptureOutput.save(root, "capture_main_menu_archives.png")

	# Open the archives modal
	menu._on_open_campaigns_modal()
	for i in range(5):
		await process_frame

	CaptureOutput.save(root, "capture_campaign_archives_modal.png")

	# Clean up
	cm.delete_saved_campaign(p1)
	cm.delete_saved_campaign(p2)
	cm.delete_saved_campaign(p3)

	menu.queue_free()
	await process_frame
	quit(0)
