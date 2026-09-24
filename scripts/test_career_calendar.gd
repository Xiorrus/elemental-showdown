extends SceneTree

var passed := 0
var failed := 0

func _init():
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _run() -> void:
	var safe_root = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(safe_root):
		printerr("Redirect APPDATA beneath this project's .godot directory before running save tests.")
		quit(2)
		return
	var cm = root.get_node("CampaignManager")
	cm.init_new_campaign({"player_name": "Calendar Captain", "player_element": "air",
		"player_nationality": "Japan", "start_solo": true})
	check(cm.player_nationality == "Japan" and cm.get_recruitment_weights()["Hydro Vipers"] == 5
		and cm.get_recruitment_weights()["Phoenix Strikers"] == 1,
		"Nationality determines the national side and weights home-country recruitment")
	for i in range(3):
		cm.record_street_win()
	check(cm.recruitment_offer_pending and cm.CLUB_TEAM_COUNTRIES[cm.recruitment_offer_club] in cm.NATIONALITIES,
		"A scout offer names a real club with a country")
	check(cm.accept_recruitment_offer(), "A club offer starts the scheduled career")
	var first = cm.get_next_scheduled_match()
	var days = cm.get_calendar_days()
	check(days.size() == 224 and first.get("season_day", -1) == 14
		and days[13]["events"].any(func(event): return event.get("type", "") == "club_match"),
		"The eight-month calendar fixes the first club match on day 14")
	check(not cm.can_play_next_match() and cm.get_days_until_next_match() == 13,
		"The first club match is unavailable before its date")
	cm.energy = 30
	var rest = cm.rest_for_days(3)
	check(rest.get("success", false) and cm.energy == 80 and cm.get_season_day() == 4,
		"Three rest days move the clock and restore fifty energy")
	var old_xp = cm.player_xp
	var old_stat = cm.player_agility
	for i in range(4):
		cm.energy = 100
		cm.train_stat("agility")
	check(cm.player_agility == old_stat + 1 and cm.player_xp == old_xp
		and cm.training_gains.get("agility", 0) == 1,
		"Four focused sessions grant one stat without awarding XP or skills")
	var training_day = cm.campaign_day
	cm.player_speed = cm.TRAINING_CAPS["speed"]
	check(not cm.train_stat("speed").get("success", false) and cm.campaign_day == training_day,
		"Training cannot push movement beyond its balance cap")
	var before = cm.campaign_day
	check(not cm.advance_days(7).get("success", false) and cm.campaign_day == before,
		"Time cannot pass an unresolved fixture")
	check(cm.advance_days(6).get("success", false) and cm.can_play_next_match(),
		"The player can advance exactly to the scheduled match day")
	var rewards_before = [cm.player_xp, cm.gold, cm.shards]
	var skipped = cm.skip_next_match()
	check(skipped.get("success", false) and cm.get_season_summary()["standings"].any(
		func(row): return row.get("team", "") == cm.team_name and row.get("played", 0) == 1)
		and [cm.player_xp, cm.gold, cm.shards] == rewards_before,
		"Explicitly skipping a match simulates standings without player rewards")
	var day_before = cm.campaign_day
	check(cm.save_campaign(), "The calendar career saves")
	cm.player_nationality = "France"
	cm.training_gains.clear()
	cm.campaign_day = 1
	check(cm.load_campaign() and cm.player_nationality == "Japan"
		and cm.training_gains.get("agility", 0) == 1 and cm.campaign_day == day_before,
		"Nationality, training gains, and day survive reload")
	cm.record_national_cup_title()
	cm.choose_primordial_element("space")
	check(not cm.can_unlock_skill("Spatial_Shift").get("can_unlock", true),
		"A National Cup choice does not grant a primordial ability")
	cm.record_national_world_cup_title()
	cm.record_club_world_cup_title()
	cm.record_national_world_cup_title()
	check(cm.choose_world_cup_reward("skill") and cm.primordial_skill_permits == 2,
		"A later World Cup can pay an extra skill permit instead of the other element")
	cm.primordial_skill_permits = 0
	check(cm.load_campaign() and cm.primordial_choices == ["space"]
		and cm.primordial_skill_permits == 2 and cm.national_world_cup_titles == 2,
		"Trophy choices and primordial permits survive reload")
	var rival = load("res://scenes/enemy.tscn").instantiate()
	root.add_child(rival)
	rival.apply_element_stats("fire")
	var base_hp = rival.max_hp
	var base_damage = rival.ability_pool[0]["damage"]
	rival.apply_career_scaling(2, 3)
	check(rival.max_hp > base_hp and rival.ability_pool[0]["damage"] > base_damage,
		"Rivals grow in health and attack power with division and season")
	rival.queue_free()
	await process_frame
	cm.init_new_campaign({"player_name": "Friendly Captain", "player_element": "water", "start_solo": true})
	for i in range(3):
		cm.record_street_win()
	cm.accept_recruitment_offer()
	cm.advance_days(6)
	var friendly = cm.get_optional_friendly_on_day(cm.get_season_day())
	var standings_before = cm.get_season_summary()["standings"]
	var gold_before = cm.gold
	cm.prepare_match("friendly", friendly.get("enemy_element", "water"),
		friendly.get("enemy_captain", "Captain"), friendly.get("enemy_team", "Rival"))
	cm.record_match_result(true, 60)
	check(not friendly.is_empty() and cm.get_season_day() == 8
		and cm.season_state.get("friendly_results", {}).has("7")
		and cm.get_optional_friendly_on_day(7).is_empty()
		and cm.get_season_summary()["standings"] == standings_before
		and cm.gold == gold_before + 40,
		"Optional club friendlies advance a day and leave league standings untouched")
	var hub = load("res://scenes/CampaignHub.tscn").instantiate()
	root.add_child(hub)
	await process_frame
	hub._open_calendar()
	var popup = hub.get_node_or_null("CareerCalendarPopup")
	check(popup != null and popup._day_nodes.size() == 224,
		"The hub opens a scrollable popup with all 224 dated days")
	check(popup._rows.get_child(0).get_child(1) is GridContainer
		and popup._rows.get_child(0).get_child(1).columns == 7,
		"Calendar dates are laid out in seven weekday columns")
	popup._jump_to_match_day()
	check(cm.get_season_day() == 14 and cm.can_play_next_match(),
		"Jump to Match advances to the scheduled fixture without crossing it")
	var xp_before_popup_skip = cm.player_xp
	popup._confirm_skip()
	check(popup._skip_armed and popup._skip_button.text == "Confirm Skip",
		"Skip requires an explicit second click in the popup")
	popup._confirm_skip()
	check(not popup._skip_armed and cm.get_season_summary()["standings"].any(
		func(row): return row.get("team", "") == cm.team_name and int(row.get("played", 0)) == 1)
		and cm.player_xp == xp_before_popup_skip,
		"The popup can simulate and skip a match on match day")
	popup.hide()
	hub._on_activity_train()
	var training_popup = hub.get_node_or_null("TrainingFocusPopup")
	var train_button = training_popup.get_child(0).get_child(1) if training_popup else null
	if train_button:
		train_button.pressed.emit()
	check(cm.training_progress.get("speed", 0) == 1,
		"The first training choice really focuses Speed rather than another stat")
	hub.queue_free()
	await process_frame
	print("CAREER CALENDAR: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
