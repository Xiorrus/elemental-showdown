extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")

func _init() -> void:
	_run.call_deferred()

func _run() -> void:
	if not CaptureOutput.prepare():
		quit(1)
		return
	var cm = root.get_node("CampaignManager")
	cm.init_new_campaign({"player_name": "VALEN", "player_element": "earth",
		"player_nationality": "Nigeria", "start_solo": true})
	for i in range(3):
		cm.record_street_win()
	cm.accept_recruitment_offer()
	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)
	for i in range(3):
		await process_frame
	hub._open_calendar()
	for i in range(3):
		await process_frame
	var success = CaptureOutput.save(root, "capture_career_calendar.png")
	hub.queue_free()
	await process_frame
	quit(0 if success else 1)
