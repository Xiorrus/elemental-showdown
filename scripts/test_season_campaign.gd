extends SceneTree

# Full career contract: street recruitment, a club season, playoffs, promotion,
# a chosen second element, and relegation. Uses an isolated user:// save.
var passed := 0
var failed := 0

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _played_count(season: Dictionary) -> int:
	var count := 0
	for fixture in season.get("fixtures", []):
		if fixture.get("played", false):
			count += 1
	return count

func _team_row(standings: Array, team_name: String) -> Dictionary:
	for row in standings:
		if row.get("team", "") == team_name:
			return row
	return {}

func _play_next(cm, victory: bool) -> Dictionary:
	var match_info: Dictionary = cm.get_next_scheduled_match()
	if match_info.is_empty():
		check(false, "A scheduled match exists before recording a result")
		return {}
	var match_type: String = match_info.get("match_type", "street")
	cm.prepare_match(match_type, match_info["enemy_element"], match_info["enemy_captain"], match_info["enemy_team"])
	cm.record_match_result(victory, 60 if victory else 25)
	return match_info

func _run():
	var safe_root = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(safe_root):
		printerr("Redirect APPDATA beneath this project's .godot directory before running save tests.")
		quit(2)
		return

	var cm = root.get_node("CampaignManager")
	cm.init_new_campaign({"player_name": "Season Captain", "player_element": "fire", "start_solo": true})
	check(not cm.has_team and cm.season_phase == "street" and cm.season_state.is_empty(),
		"A solo career starts on the street before a club season")
	check(cm.get_unlocked_elements() == ["fire"] and not cm.unlock_next_element("water")
		and not cm.can_access_discipline("water")["can_access"],
		"The captain has only one element throughout the street tier")

	_play_next(cm, false)
	check(cm.street_wins == 0 and not cm.recruitment_offer_pending and not cm.has_team,
		"A street defeat does not advance the three-win recruitment milestone")
	for win_index in range(3):
		_play_next(cm, true)
		check(cm.street_wins == win_index + 1 and cm.recruitment_offer_pending == (win_index == 2),
			"Street victory %d advances the visible recruitment milestone" % (win_index + 1))
	check(cm.get_next_scheduled_match().is_empty() and not cm.has_team,
		"After three wins, the player chooses whether to join a club")
	check(cm.save_campaign(), "The pending offer saves")
	cm.recruitment_offer_pending = false
	check(cm.load_campaign() and cm.recruitment_offer_pending and cm.street_wins == 3,
		"The pending offer survives reload")
	check(cm.accept_recruitment_offer(), "The player can accept the club offer")
	check(cm.has_team and cm.active_match_format == "3v3" and cm.season_phase == "club_regular",
		"Accepting the offer starts a club season and 3v3 league play")
	check(cm.season_state.get("calendar", []).size() == 32
		and cm.season_state.get("fixtures", []).size() == 56
		and cm.season_week == 1,
		"A club season spans 32 weeks and 14 rounds for eight clubs")
	check(cm.get_unlocked_elements() == ["fire"] and not cm.unlock_next_element("water")
		and not cm.can_access_discipline("water")["can_access"],
		"Joining a Bronze club does not grant a second element")
	check(not cm.set_teammate_active_skills(cm.player_name, ["Laser"])
		and not cm.set_athlete_skills(cm.player_name, ["Laser"])
		and cm.equipped_abilities == ["Thermal_Radiation", "Combustion"],
		"Roster skill APIs cannot equip a captain skill that has not been bought with SP")

	var first_match: Dictionary = cm.get_next_scheduled_match()
	check(first_match.get("round", -1) == 1 and first_match.get("week", -1) == 2
		and first_match.get("match_type", "") == "league", "The first fixture occurs in week two")
	_play_next(cm, false)
	var first_standings: Array = cm.get_season_summary()["standings"]
	var captain_row: Dictionary = _team_row(first_standings, cm.team_name)
	check(_played_count(cm.season_state) == 4 and captain_row.get("played", 0) == 1
		and captain_row.get("losses", 0) == 1 and captain_row.get("points", -1) == 0,
		"A league loss is recorded alongside the other three clubs' results")
	check(cm.get_next_scheduled_match().get("round", -1) == 2
		and cm.get_next_scheduled_match().get("week", -1) == 4 and cm.season_week == 3,
		"The hub shows a rest week before the next two-week league fixture")

	for round_index in range(2, 15):
		var upcoming: Dictionary = cm.get_next_scheduled_match()
		if upcoming.is_empty():
			check(false, "Regular fixture %d remains available" % round_index)
			break
		check(upcoming.get("round", -1) == round_index
			and upcoming.get("week", -1) == round_index * 2,
			"Regular fixture %d is scheduled in its two-week slot" % round_index)
		_play_next(cm, true)
		if round_index == 3:
			check(cm.season_week == 7 and not cm.get_season_summary()["national_window"].is_empty(),
				"The season reaches the first international window between club fixtures")
		if round_index == 7:
			var next_before: Dictionary = cm.get_next_scheduled_match()
			var played_before := _played_count(cm.season_state)
			check(cm.save_campaign(), "A half-season saves")
			cm.season_state = {}
			check(cm.load_campaign() and cm.get_next_scheduled_match() == next_before
				and _played_count(cm.season_state) == played_before,
				"Midseason reload preserves fixture results and the next opponent")

	check(_played_count(cm.season_state) == 56 and cm.season_week == 29,
		"Four results per round complete all 56 regular fixtures before postseason week 30")
	var postseason: Dictionary = cm.championship_state
	check(postseason.get("ready", false) and postseason.get("championship_qualifiers", []).has(cm.team_name)
		and postseason.get("promotion_candidates", []).has(cm.team_name),
		"Standings qualify the winning club for the championship and promotion")
	check(cm.season_phase == "club_semifinal" and cm.get_next_scheduled_match().get("match_type", "") == "championship",
		"The club receives a semifinal match after regular season qualification")
	if cm.season_phase == "club_semifinal":
		_play_next(cm, true)
	check(cm.season_phase == "club_final" and cm.season_week == 31
		and cm.get_next_scheduled_match().get("week", -1) == 32,
		"A semifinal win reaches the week-31 window before the week-32 final")
	if cm.season_phase == "club_final":
		_play_next(cm, true)
	check(cm.season_phase == "offseason" and cm.championship_state.get("champion", "") == cm.team_name,
		"The final winner is recorded as club champion")
	check(cm.league_tier == 2 and cm.season_history.size() == 1
		and cm.season_history[0].get("placement", "") == "promoted",
		"A top-two Bronze club is promoted at season end")
	var captain_profile: Dictionary = cm.get_ally(cm.player_name)
	check(cm.unlocked_abilities == ["Thermal_Radiation", "Combustion"]
		and captain_profile.get("known_skills", []) == cm.unlocked_abilities
		and captain_profile.get("level", -1) == cm.player_level,
		"Promotion never grants the captain a free skill or separate roster level")
	check(cm.get_unlocked_elements() == ["fire"] and cm.pending_element_choice,
		"Promotion opens an element choice without granting one automatically")
	check(cm.save_campaign(), "Offseason promotion saves")
	cm.pending_element_choice = false
	check(cm.load_campaign() and cm.pending_element_choice and cm.league_tier == 2,
		"Offseason promotion and the pending choice survive reload")
	check(cm.unlock_next_element("water") and cm.get_unlocked_elements() == ["fire", "water"]
		and cm.can_access_discipline("water")["can_access"],
		"The player explicitly chooses a second element only after promotion")
	check(not cm.unlock_next_element("earth"), "A second promotion is required for a third element")
	check(cm.advance_to_next_season(), "The player can start the next season from offseason")
	check(cm.season_number == 2 and cm.season_week == 1 and cm.season_phase == "club_regular"
		and _played_count(cm.season_state) == 0 and cm.season_history.size() == 1,
		"A new 32-week season starts with fresh fixtures and preserved history")
	check(cm.season_state.get("teams", []).has("Frost Fang Legion")
		and cm.season_state.get("teams", []).has("Iron Bastion")
		and cm.season_state.get("teams", []).has(cm.team_name),
		"Regional fixtures use the clubs shown in Regional scouting")
	check(cm.get_unlocked_elements() == ["fire", "water"],
		"The chosen element remains available in the higher league")
	check(cm.load_campaign() and cm.season_number == 2 and cm.get_unlocked_elements() == ["fire", "water"],
		"New-season calendar and chosen element survive reload")

	for _round in range(14):
		if cm.get_next_scheduled_match().is_empty():
			break
		_play_next(cm, false)
	check(_played_count(cm.season_state) == 56 and cm.season_phase == "offseason"
		and cm.league_tier == 1 and cm.season_history.size() == 2
		and cm.season_history[1].get("placement", "") == "relegated",
		"A bottom-two club is relegated after its next season")
	check(cm.get_unlocked_elements() == ["fire", "water"] and cm.can_access_discipline("water")["can_access"],
		"Relegation does not erase the captain's previously earned element")

	print("SEASON CAMPAIGN: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
