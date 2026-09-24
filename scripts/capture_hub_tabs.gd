extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")
var capture_failed := false

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return
	print("[Capture] Starting Hub tabs visual capture sequence...")

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

	var ch = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(ch)
	for i in range(4): await process_frame

	# Tab 0: Schedule / Tournament
	ch._switch_tab(0)
	for i in range(4): await process_frame
	_save_viewport("capture_hub_schedule.png")

	# Tab 1: Dojo & Roster
	ch._switch_tab(1)
	for i in range(4): await process_frame
	_save_viewport("capture_hub_roster.png")

	# Tab 2: Deployment Matrix
	ch._switch_tab(2)
	for i in range(4): await process_frame
	_save_viewport("capture_hub_deployment.png")

	# Tab 3: Scouting Intel
	ch._switch_tab(3)
	for i in range(4): await process_frame
	_save_viewport("capture_hub_intel.png")
	ch._ladder_league = "national_teams"
	ch._refresh_intel_tab()
	for i in range(4): await process_frame
	_save_viewport("capture_hub_national_teams.png")

	# Tab 4: Cultivation & Profile
	ch._switch_tab(4)
	for i in range(4): await process_frame
	_save_viewport("capture_hub_cultivation.png")

	ch.queue_free()
	await process_frame

	print("[Capture] Hub tabs captured successfully!")
	quit(1 if capture_failed else 0)

func _save_viewport(file_name: String):
	if not CaptureOutput.save(root, file_name):
		capture_failed = true
