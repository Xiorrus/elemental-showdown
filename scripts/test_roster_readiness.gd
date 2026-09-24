extends SceneTree

# Test suite for Phase 2: Roster Readiness, Emergency Loan/Signing, and 5v5 National Final.
const SeasonCalendarScript = preload("res://scripts/season_calendar.gd")
const SeriesStateScript = preload("res://scripts/series_state.gd")
const MatchRulesScript = preload("res://scripts/match_rules.gd")
const CompetitionRuleBookScript = preload("res://scripts/competition_rule_book.gd")
const CampaignManagerScript = preload("res://scripts/campaign_manager.gd")
const MatchContextScript = preload("res://scripts/match_context.gd")

var passed := 0
var failed := 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("  [PASS] " + label)
	else:
		failed += 1
		printerr("  [FAIL] " + label)

func _run() -> void:
	print("\n========================================================")
	print("   ROSTER READINESS & 5V5 NATIONAL FINAL TEST SUITE")
	print("========================================================\n")

	_test_roster_readiness_checks()
	_test_emergency_loan_signing()
	_test_tier_postseason_scheduling()
	_test_national_final_best_of_5_clinch()
	_test_lineup_validation_and_guards()
	_test_future_presets_and_no_placeholder_trophies()

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_roster_readiness_checks() -> void:
	print("--- SUITE 1: Roster Readiness Checks ---")
	var cm = CampaignManagerScript.new()
	cm.new_campaign("TestPlayer", "fire")

	# Solo street brawler: has_team is false, only player in roster
	var solo_readiness = cm.check_roster_readiness(5)
	check(not solo_readiness["ready"], "Solo player is not 5v5 ready")
	check(solo_readiness["current_count"] == 1, "Solo player has 1 fighter")
	check(solo_readiness["deficit"] == 4, "Solo player deficit is 4")
	check(not solo_readiness["emergency_available"], "Emergency signing unavailable without a team")
	check(not cm.can_sign_emergency_fighter(), "can_sign_emergency_fighter returns false for solo brawler")

	# Team with 3 fighters (Player, Kora, Gaius)
	cm.new_campaign("TestPlayer", "fire", "Phoenix Strikers")
	cm.league_tier = 1
	var trio_readiness = cm.check_roster_readiness(5)
	check(not trio_readiness["ready"], "3-fighter club is not 5v5 ready")
	check(trio_readiness["current_count"] == 3, "3-fighter club count is 3")
	check(trio_readiness["deficit"] == 2, "3-fighter club deficit is 2")
	check(trio_readiness["emergency_available"], "Emergency signing available for club needing fighters")
	check(cm.can_sign_emergency_fighter(), "can_sign_emergency_fighter returns true for 3-fighter club")

	# Warning active check: inactive at City tier (tier 1), active at National tier (tier 3)
	check(not trio_readiness["warning_active"], "Warning inactive at City tier (tier 1)")
	cm.league_tier = 3
	var national_readiness = cm.check_roster_readiness(5)
	check(national_readiness["warning_active"], "Warning active at National tier (tier 3)")
	cm.free()

func _test_emergency_loan_signing() -> void:
	print("\n--- SUITE 2: Emergency Loan / Signing Fallback ---")
	var cm = CampaignManagerScript.new()
	cm.new_campaign("TestPlayer", "fire", "Phoenix Strikers")
	cm.league_tier = 3

	check(cm.allies.size() == 3, "Initial club roster has 3 fighters")

	# Sign emergency fighter 1
	var f1 = cm.sign_emergency_fighter()
	check(not f1.is_empty(), "First emergency fighter successfully signed")
	check(cm.allies.size() == 4, "Roster now has 4 fighters")
	check(f1.get("emergency_loan", false), "Fighter marked with emergency_loan flag")
	check(f1.get("career_team", "") == "Phoenix Strikers", "Fighter assigned to player's team")
	check(cm.can_sign_emergency_fighter(), "Can still sign 5th fighter")

	# Sign emergency fighter 2
	var f2 = cm.sign_emergency_fighter()
	check(not f2.is_empty(), "Second emergency fighter successfully signed")
	check(cm.allies.size() == 5, "Roster now has exactly 5 fighters")
	check(f1["name"] != f2["name"], "Emergency fighters have distinct unique names")

	var readiness = cm.check_roster_readiness(5)
	check(readiness["ready"], "Roster is now 5v5 ready")
	check(readiness["deficit"] == 0, "Deficit is 0")
	check(not cm.can_sign_emergency_fighter(), "can_sign_emergency_fighter returns false when roster reaches 5")
	cm.free()

func _test_tier_postseason_scheduling() -> void:
	print("\n--- SUITE 3: Tier-Specific Postseason Scheduling ---")
	var cal := SeasonCalendarScript.new()

	# 1. City division (tier 1)
	var city_season = cal.create_season(SeasonCalendarScript.DEFAULT_TEAMS, 1, 1)
	for i in range(city_season["fixtures"].size()):
		cal.record_result(city_season, i, 2, 0)
	var city_post = cal.get_postseason(city_season)
	check(city_post["ready"], "City postseason ready")
	check(city_post["semifinals"][0]["competition_id"] == "city_semis", "City semis use 'city_semis' preset")
	check(city_post["semifinals"][0]["best_of"] == 3, "City semis are Best-of-3")

	# Check calendar entries for City final: Days 210, 213, 216 exist, Days 220 and 223 have no final event
	var d210_city = cal.get_day_entry(city_season, "Phoenix Strikers", 210)
	var d216_city = cal.get_day_entry(city_season, "Phoenix Strikers", 216)
	var d220_city = cal.get_day_entry(city_season, "Phoenix Strikers", 220)
	var d223_city = cal.get_day_entry(city_season, "Phoenix Strikers", 223)
	check(not d210_city["events"].is_empty() and d210_city["events"][0]["type"] == "championship_final", "Day 210 has final event in City")
	check(not d216_city["events"].is_empty() and d216_city["events"][0]["type"] == "championship_final", "Day 216 has final event in City")
	check(d220_city["events"].is_empty(), "Day 220 has NO final event in City (Bo3 final ends Day 216)")
	check(d223_city["events"].is_empty(), "Day 223 has NO final event in City (Bo3 final ends Day 216)")

	# 2. National division (tier 3)
	var nat_season = cal.create_season(SeasonCalendarScript.DEFAULT_TEAMS, 1, 3)
	for i in range(nat_season["fixtures"].size()):
		cal.record_result(nat_season, i, 2, 0)
	var nat_post = cal.get_postseason(nat_season)
	check(nat_post["ready"], "National postseason ready")
	check(nat_post["semifinals"][0]["competition_id"] == "national_semis", "National semis use 'national_semis' preset")
	check(nat_post["semifinals"][0]["best_of"] == 3, "National semis are Best-of-3")

	# Check calendar entries for National final: Days 210, 213, 216, 220, 223 ALL exist
	var d210_nat = cal.get_day_entry(nat_season, "Phoenix Strikers", 210)
	var d220_nat = cal.get_day_entry(nat_season, "Phoenix Strikers", 220)
	var d223_nat = cal.get_day_entry(nat_season, "Phoenix Strikers", 223)
	check(not d210_nat["events"].is_empty() and d210_nat["events"][0]["type"] == "championship_final", "Day 210 has final event in National")
	check(not d220_nat["events"].is_empty() and d220_nat["events"][0]["type"] == "championship_final", "Day 220 has final event in National")
	check(not d223_nat["events"].is_empty() and d223_nat["events"][0]["type"] == "championship_final", "Day 223 has final event in National")
	check(d220_nat["events"][0]["if_needed"] == true, "Day 220 Game 4 is marked if_needed")
	check(d223_nat["events"][0]["if_needed"] == true, "Day 223 Game 5 is marked if_needed")

func _test_national_final_best_of_5_clinch() -> void:
	print("\n--- SUITE 4: National Final Best-of-5 Clinch at 3 Wins ---")
	var final_rules = CompetitionRuleBookScript.get_preset("national_final")
	check(final_rules.team_size == 5, "National final requires team size 5")
	check(final_rules.best_of == 5, "National final is Best-of-5")
	check(final_rules.max_substitutions == 2, "National final allows 2 substitutions")

	var days = [210, 213, 216, 220, 223]
	var s := SeriesStateScript.new("s1_national_final", "national_final", "Phoenix Strikers", "Hydro Vipers", 5, days)
	s.rules = final_rules
	check(s.wins_needed() == 3, "Wins needed for Bo5 is 3")

	# Game 1: Win
	check(s.record_game("s1_national_final_g1", 0), "Game 1 recorded")
	check(s.wins == [1, 0], "Score 1-0")
	check(not s.is_complete(), "Series not complete at 1-0")
	check(s.get_next_scheduled_day() == 213, "Next game is Day 213")

	# Game 2: Win
	check(s.record_game("s1_national_final_g2", 0), "Game 2 recorded")
	check(s.wins == [2, 0], "Score 2-0")
	check(not s.is_complete(), "Series not complete at 2-0")
	check(s.get_next_scheduled_day() == 216, "Next game is Day 216")

	# Game 3: Win -> 3-0 Sweep Clinch!
	check(s.record_game("s1_national_final_g3", 0), "Game 3 recorded")
	check(s.wins == [3, 0], "Score 3-0")
	check(s.is_complete(), "Series completes at 3-0")
	check(s.get_winner() == "Phoenix Strikers", "Winner is Phoenix Strikers")

	# Games 4 and 5 become not_needed
	check(s.get_game_status(3) == "not_needed", "Game 4 (Day 220) is 'not_needed'")
	check(s.get_game_status(4) == "not_needed", "Game 5 (Day 223) is 'not_needed'")

	# Rejecting any further games after clinch
	check(not s.record_game("s1_national_final_g4", 0), "Cannot record game after series clinch")

	# Test CampaignManager integration with National Cup victory
	var cm = CampaignManagerScript.new()
	cm.new_campaign("TestPlayer", "fire")
	cm.has_team = true
	cm.team_name = "Phoenix Strikers"
	cm.league_tier = 3
	cm.season_phase = "club_final"
	cm.championship_state = {
		"player_series_id": "s1_national_final",
		"player_opponent": "Hydro Vipers"
	}
	cm.series["s1_national_final"] = s

	# Clinch triggers champion award in _record_championship_result
	cm._record_championship_result(true)
	check(cm.championship_state["champion"] == "Phoenix Strikers", "Campaign recorded Phoenix Strikers as champion")
	check(cm.national_cup_titles == 1, "National Cup title awarded once on 3-win clinch")
	check(cm.primordial_choice_pending, "Primordial choice pending for Space/Time gate")
	cm.free()

func _test_lineup_validation_and_guards() -> void:
	print("\n--- SUITE 5: Lineup Validation & Guards ---")
	var cm = CampaignManagerScript.new()
	cm.new_campaign("TestPlayer", "fire", "Phoenix Strikers")
	cm.league_tier = 3

	# Prepare a national_final match
	cm.season_phase = "club_final"
	var final_s = SeriesStateScript.new("s1_final", "national_final", "Phoenix Strikers", "Hydro Vipers", 5, [210, 213, 216, 220, 223])
	final_s.rules = CompetitionRuleBookScript.get_preset("national_final")
	cm.series["s1_final"] = final_s
	cm.championship_state["player_series_id"] = "s1_final"

	cm.prepare_match("championship", "water", "Hydro Captain", "Hydro Vipers")
	check(cm.active_match_format == "5v5", "active_match_format is set to 5v5 for national final")
	check(cm.active_match_context != null, "active_match_context is created")
	check(cm.active_match_context.rules.team_size == 5, "Context rules require 5 fighters")

	# Check deployment match dictionary
	var match_dict = cm.get_next_scheduled_match()
	check(match_dict["team_size"] == 5, "Scheduled match specifies team_size 5")
	check(match_dict["match_format"] == "5v5", "Scheduled match specifies match_format 5v5")
	cm.free()

func _test_future_presets_and_no_placeholder_trophies() -> void:
	print("\n--- SUITE 6: Future Presets & No Placeholder Trophies ---")
	check(CompetitionRuleBookScript.has_preset("continental_cup_knockout"), "continental_cup_knockout preset exists")
	check(CompetitionRuleBookScript.has_preset("national_world_cup_knockout"), "national_world_cup_knockout preset exists")
	check(CompetitionRuleBookScript.has_preset("national_friendly"), "national_friendly preset exists")

	var cont_rules = CompetitionRuleBookScript.get_preset("continental_cup_knockout")
	check(cont_rules.team_size == 5, "Continental cup knockout team size is 5")
	check(cont_rules.reward_policy.is_empty(), "Continental cup knockout has no placeholder trophy in reward policy")

	var wc_rules = CompetitionRuleBookScript.get_preset("national_world_cup_knockout")
	check(wc_rules.team_size == 5, "World cup knockout team size is 5")
	check(wc_rules.reward_policy.is_empty(), "World cup knockout has no placeholder trophy in reward policy")
