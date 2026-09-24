extends SceneTree

# Test suite for SeriesState domain model.
const SeriesStateScript = preload("res://scripts/series_state.gd")
const MatchRulesScript = preload("res://scripts/match_rules.gd")

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
	print("   SERIES STATE DOMAIN MODEL TEST SUITE")
	print("========================================================\n")

	_test_bo3_sweep()
	_test_bo3_decider()
	_test_rejection_rules()
	_test_serialization()

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_bo3_sweep() -> void:
	print("--- SUITE 1: Best-of-3 Series Sweep (2-0) ---")

	var series := SeriesStateScript.new(
		"s1_semi_1", "city_semis", "Phoenix Strikers", "Hydro Vipers", 3, [199, 202, 205]
	)

	check(series.wins_needed() == 2, "Bo3 requires 2 wins to clinch")
	check(not series.is_complete(), "Initial series is not complete")
	check(series.get_game_status(0) == "next", "Game 1 status is 'next'")
	check(series.get_game_status(1) == "if_needed", "Game 2 status is 'if_needed'")
	check(series.get_game_status(2) == "if_needed", "Game 3 status is 'if_needed'")
	check(series.get_next_scheduled_day() == 199, "Next scheduled day is 199 for Game 1")

	# Game 1: Home win
	var res1: bool = series.record_game("s1_semi_1_g1", 0, {"score": "2-0", "turns": 6})
	check(res1, "Game 1 recorded successfully")
	check(series.wins == [1, 0], "Score is 1 - 0 after Game 1")
	check(not series.is_complete(), "Series is not complete at 1 - 0")
	check(series.get_game_status(0) == "played", "Game 1 status is 'played'")
	check(series.get_game_status(1) == "next", "Game 2 status is 'next'")
	check(series.get_game_status(2) == "if_needed", "Game 3 status is 'if_needed'")
	check(series.get_next_scheduled_day() == 202, "Next scheduled day is 202 for Game 2")

	# Game 2: Home win (Clinch 2-0)
	var res2: bool = series.record_game("s1_semi_1_g2", 0, {"score": "2-1", "turns": 8})
	check(res2, "Game 2 recorded successfully")
	check(series.wins == [2, 0], "Score is 2 - 0 after Game 2")
	check(series.is_complete(), "Series is complete at 2 - 0")
	check(series.is_clinched, "is_clinched is true")
	check(series.get_winner() == "Phoenix Strikers", "Winner is home team Phoenix Strikers")
	check(series.get_game_status(0) == "played", "Game 1 status is 'played'")
	check(series.get_game_status(1) == "played", "Game 2 status is 'played'")
	check(series.get_game_status(2) == "not_needed", "Game 3 is cancelled: status is 'not_needed'")
	check(series.get_next_scheduled_day() == -1, "get_next_scheduled_day() returns -1 after clinch")

func _test_bo3_decider() -> void:
	print("\n--- SUITE 2: Best-of-3 Series Decider (1-1 -> Game 3) ---")

	var series := SeriesStateScript.new(
		"s1_semi_2", "city_semis", "Terra Titans", "Gale Force", 3, [199, 202, 205]
	)

	# Game 1: Home win (1-0)
	series.record_game("s1_semi_2_g1", 0)
	check(series.wins == [1, 0], "Game 1 home win -> 1-0")

	# Game 2: Away win (1-1)
	var res2: bool = series.record_game("s1_semi_2_g2", 1)
	check(res2, "Game 2 recorded successfully")
	check(series.wins == [1, 1], "Game 2 away win -> 1-1")
	check(not series.is_complete(), "Series is not complete at 1-1")
	check(series.get_game_status(2) == "next", "Game 3 status transitions to 'next'")
	check(series.get_next_scheduled_day() == 205, "Next scheduled day is 205 for Game 3")

	# Game 3: Away win (1-2 Clinch)
	var res3: bool = series.record_game("s1_semi_2_g3", 1)
	check(res3, "Game 3 recorded successfully")
	check(series.wins == [1, 2], "Final score is 1-2")
	check(series.is_complete(), "Series is complete at 1-2")
	check(series.get_winner() == "Gale Force", "Winner is away team Gale Force")
	check(series.get_game_status(2) == "played", "Game 3 status is 'played'")

func _test_rejection_rules() -> void:
	print("\n--- SUITE 3: Rejection Rules & Clinch Idempotency ---")

	var series := SeriesStateScript.new(
		"s1_semi_test", "city_semis", "Ember Hawks", "Crystal Wardens", 3, [199, 202, 205]
	)

	# Rejects empty game ID
	check(not series.record_game("", 0), "Rejects empty game_id")
	check(not series.record_game("   ", 0), "Rejects whitespace game_id")

	# Rejects invalid winning side
	check(not series.record_game("g1", -1), "Rejects winning_side -1")
	check(not series.record_game("g1", 2), "Rejects winning_side 2")

	# Records valid Game 1
	check(series.record_game("g1", 0), "Records valid Game 1")

	# Duplicate game ID rejection
	check(not series.record_game("g1", 0), "Rejects duplicate game_id 'g1'")
	check(not series.record_game("g1", 1), "Rejects duplicate game_id 'g1' even with different side")
	check(series.wins == [1, 0], "Wins array not incremented by rejected duplicate")

	# Clinch the series with Game 2
	check(series.record_game("g2", 0), "Records Game 2 -> 2-0 clinch")
	check(series.is_complete(), "Series is now complete")

	# Post-clinch rejection
	check(not series.record_game("g3", 0), "Rejects Game 3 after series is already clinched")
	check(not series.record_game("g4", 1), "Rejects Game 4 after series is already clinched")
	check(series.wins == [2, 0], "Wins remain unchanged at 2-0 after post-clinch attempts")
	check(series.get_winner() == "Ember Hawks", "Winner remains unchanged")

func _test_serialization() -> void:
	print("\n--- SUITE 4: SeriesState Serialization ---")

	var series := SeriesStateScript.new(
		"s1_semi_save", "city_semis", "Phoenix Strikers", "Hydro Vipers", 3, [199, 202, 205]
	)
	series.record_game("g1", 0, {"turns": 7, "scouting": {"lane": "mid"}})

	var dict_repr := series.to_dict()
	check(dict_repr.is_empty() == false, "to_dict() returns populated Dictionary")

	var restored := SeriesStateScript.from_dict(dict_repr)
	check(restored != null, "from_dict() restores SeriesState")
	check(restored.series_id == "s1_semi_save", "Restored series_id matches")
	check(restored.competition_id == "city_semis", "Restored competition_id matches")
	check(restored.home_team == "Phoenix Strikers", "Restored home_team matches")
	check(restored.away_team == "Hydro Vipers", "Restored away_team matches")
	check(restored.best_of == 3, "Restored best_of matches")
	check(restored.scheduled_days == [199, 202, 205], "Restored scheduled_days matches")
	check(restored.wins == [1, 0], "Restored wins matches [1, 0]")
	check(restored.current_game_index == 1, "Restored current_game_index matches 1")
	check(restored.recorded_games.has("g1"), "Restored recorded_games contains 'g1'")
	check(restored.scouting_memory.get("lane") == "mid", "Restored scouting_memory matches")

	# Continue restored series to completion
	check(restored.record_game("g2", 0), "Can continue restored series: records Game 2")
	check(restored.is_complete(), "Restored series clinches at 2-0")
	check(restored.get_winner() == "Phoenix Strikers", "Restored series winner is Phoenix Strikers")
