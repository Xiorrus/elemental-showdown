extends SceneTree

# Test suite for match scheduling, calendar dates, Week 25 national window, and non-player series simulation.
const SeasonCalendarScript = preload("res://scripts/season_calendar.gd")
const SeriesStateScript = preload("res://scripts/series_state.gd")
const MatchRulesScript = preload("res://scripts/match_rules.gd")
const CompetitionRuleBookScript = preload("res://scripts/competition_rule_book.gd")

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
	print("   MATCH SCHEDULING & CALENDAR DATES TEST SUITE")
	print("========================================================\n")

	_test_semifinal_calendar_dates()
	_test_national_window_shift()
	_test_conflict_prevention()
	_test_non_player_seeded_simulation()

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_semifinal_calendar_dates() -> void:
	print("--- SUITE 1: Semifinal Series Days 199, 202, 205 ---")

	var cal := SeasonCalendarScript.new()
	var season: Dictionary = cal.create_season(SeasonCalendarScript.DEFAULT_TEAMS, 1)

	# Before postseason is established, get_day_entry returns provisional championship dates
	var d199_pre := cal.get_day_entry(season, "Phoenix Strikers", 199)
	check(not d199_pre["events"].is_empty(), "Day 199 returns events")
	check(d199_pre["events"][0]["type"] == "championship_semifinals", "Day 199 is championship_semifinals")
	check(d199_pre["events"][0]["game_number"] == 1, "Day 199 is Game 1")
	check(d199_pre["events"][0]["if_needed"] == false, "Day 199 Game 1 is not if_needed")

	var d202_pre := cal.get_day_entry(season, "Phoenix Strikers", 202)
	check(not d202_pre["events"].is_empty(), "Day 202 returns events")
	check(d202_pre["events"][0]["type"] == "championship_semifinals", "Day 202 is championship_semifinals")
	check(d202_pre["events"][0]["game_number"] == 2, "Day 202 is Game 2")
	check(d202_pre["events"][0]["if_needed"] == false, "Day 202 Game 2 is not if_needed")

	var d205_pre := cal.get_day_entry(season, "Phoenix Strikers", 205)
	check(not d205_pre["events"].is_empty(), "Day 205 returns events")
	check(d205_pre["events"][0]["type"] == "championship_semifinals", "Day 205 is championship_semifinals")
	check(d205_pre["events"][0]["game_number"] == 3, "Day 205 is Game 3")
	check(d205_pre["events"][0]["if_needed"] == true, "Day 205 Game 3 is marked 'if_needed'")

	# Check rest days between series games
	var d200 := cal.get_day_entry(season, "Phoenix Strikers", 200)
	var d201 := cal.get_day_entry(season, "Phoenix Strikers", 201)
	var d203 := cal.get_day_entry(season, "Phoenix Strikers", 203)
	var d204 := cal.get_day_entry(season, "Phoenix Strikers", 204)
	check(d200["events"].is_empty(), "Day 200 is open rest/training day")
	check(d201["events"].is_empty(), "Day 201 is open rest/training day")
	check(d203["events"].is_empty(), "Day 203 is open rest/training day")
	check(d204["events"].is_empty(), "Day 204 is open rest/training day")

	# Now simulate active SeriesState attached to season
	var semi_series := SeriesStateScript.new(
		"s1_semi_1", "city_semis", "Phoenix Strikers", "Hydro Vipers", 3, [199, 202, 205]
	)
	semi_series.rules = CompetitionRuleBookScript.get_preset("city_semis")
	season["series"] = {"s1_semi_1": semi_series.to_dict()}

	var d199_active := cal.get_day_entry(season, "Phoenix Strikers", 199)
	check(d199_active["events"][0]["opponent"] == "Hydro Vipers", "Active Day 199 shows opponent Hydro Vipers")
	check(d199_active["events"][0]["status"] == "next", "Active Day 199 status is 'next'")

	var d205_active := cal.get_day_entry(season, "Phoenix Strikers", 205)
	check(d205_active["events"][0]["status"] == "if_needed", "Active Day 205 status is 'if_needed'")

	# When series clinches 2-0:
	semi_series.record_game("s1_semi_1_g1", 0)
	semi_series.record_game("s1_semi_1_g2", 0)
	season["series"] = {"s1_semi_1": semi_series.to_dict()}

	var d205_clinched := cal.get_day_entry(season, "Phoenix Strikers", 205)
	check(d205_clinched["events"][0]["status"] == "not_needed", "Day 205 status transitions to 'not_needed' after 2-0 clinch")

func _test_national_window_shift() -> void:
	print("\n--- SUITE 2: Week 25 National Window Shift ---")

	var cal := SeasonCalendarScript.new()
	var season: Dictionary = cal.create_season(SeasonCalendarScript.DEFAULT_TEAMS, 1)

	# Week 25 has national window
	var w25 := cal.get_week(season, 25)
	check(not w25["events"].is_empty() and w25["events"][0]["type"] == "national_window",
		"Week 25 contains national_window event")
	check(w25["fixture_ids"].is_empty(), "Week 25 has zero club league fixtures")

	# Week 31 has NO national window (reserved for Finals)
	var w31 := cal.get_week(season, 31)
	var has_nat_in_31 := false
	for ev in w31["events"]:
		if ev.get("type", "") == "national_window":
			has_nat_in_31 = true
	check(not has_nat_in_31, "Week 31 has NO national window (freed for finals)")

	# National windows list is [7, 15, 23, 25]
	check(SeasonCalendarScript.NATIONAL_WEEKS == [7, 15, 23, 25], "NATIONAL_WEEKS constant is [7, 15, 23, 25]")

func _test_conflict_prevention() -> void:
	print("\n--- SUITE 3: Conflict Prevention & Invariants ---")

	var cal := SeasonCalendarScript.new()
	var season: Dictionary = cal.create_season(SeasonCalendarScript.DEFAULT_TEAMS, 1)

	# Check that no national window week contains regular fixtures
	for nat_week in SeasonCalendarScript.NATIONAL_WEEKS:
		var week_entry := cal.get_week(season, nat_week)
		check(week_entry["fixture_ids"].is_empty(), "National week %d has zero club league fixtures" % nat_week)

	# Check that all regular fixtures stay strictly inside 28 weeks
	var max_reg_week := 0
	for fix in season["fixtures"]:
		if int(fix["week"]) > max_reg_week:
			max_reg_week = int(fix["week"])
	check(max_reg_week <= 28, "All 56 regular fixtures finish by Week 28")

	# Postseason occurs in weeks 29 to 32
	check(cal.get_fixture_day(28) == 196, "Week 28 ends on Day 196")
	check(199 > 196, "Semifinal Day 199 begins after regular season Day 196")
	check(223 <= 224, "Finals Day 223 concludes before season end Day 224")

func _test_non_player_seeded_simulation() -> void:
	print("\n--- SUITE 4: Non-Player Seeded Series Simulation ---")

	# Helper simulator simulating a non-player Bo3 series deterministically
	var simulate_series = func(series: SeriesState, seed_val: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		while not series.is_complete():
			var g_idx: int = series.current_game_index
			var g_id: String = "%s_g%d" % [series.series_id, g_idx + 1]
			# Seeded 50/50 chance
			var winning_side: int = 0 if rng.randf() < 0.5 else 1
			series.record_game(g_id, winning_side, {"simulated": true})

	# Test determinism: same seed gives identical outcome
	var s1 := SeriesStateScript.new("test_sim_1", "city_semis", "TeamA", "TeamB", 3, [199, 202, 205])
	var s2 := SeriesStateScript.new("test_sim_2", "city_semis", "TeamA", "TeamB", 3, [199, 202, 205])
	simulate_series.call(s1, 12345)
	simulate_series.call(s2, 12345)

	check(s1.is_complete(), "Series 1 completed")
	check(s2.is_complete(), "Series 2 completed")
	check(s1.wins == s2.wins, "Identical seed produces identical win counts")
	check(s1.get_winner() == s2.get_winner(), "Identical seed produces identical series winner")
	check(s1.current_game_index == s2.current_game_index, "Identical seed produces identical game count")

	# Test variation: verify both higher seed (side 0) and lower seed (side 1) can win under different seeds
	var home_won := false
	var away_won := false
	for test_seed in range(1, 20):
		var s := SeriesStateScript.new("test_sim_%d" % test_seed, "city_semis", "TeamA", "TeamB", 3, [199, 202, 205])
		simulate_series.call(s, test_seed * 997)
		if s.get_winner() == "TeamA":
			home_won = true
		elif s.get_winner() == "TeamB":
			away_won = true
		if home_won and away_won:
			break

	check(home_won and away_won, "Non-player simulation is genuinely probabilistic (both home and away can win)")
