extends SceneTree

var passed := 0
var failed := 0


func _init() -> void:
	_run.call_deferred()


func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)


func _run() -> void:
	var model = load("res://scripts/season_calendar.gd").new()
	var teams := ["A", "B", "C", "D", "E", "F", "G", "H"]
	var season: Dictionary = model.create_season(teams, 1)
	check(season.get("weeks_total") == 32 and season["calendar"].size() == 32,
		"Eight four-week months make a 32-week season")
	check(season["fixtures"].size() == 56, "Eight clubs each receive 14 home-and-away fixtures")
	check(model.create_season(teams, 1) == season, "Schedule creation is deterministic")
	check(model.create_season(["A", "B"]).is_empty(), "A partial league is rejected")
	check(model.create_season(["A", "B", "C", "D", "E", "F", "G", "a"]).is_empty(),
		"Duplicate club names are rejected regardless of case")

	var club_counts: Dictionary = {}
	var home_counts: Dictionary = {}
	var pair_hosts: Dictionary = {}
	for team in teams:
		club_counts[team] = 0
		home_counts[team] = 0
	var valid_rounds := true
	for round_index in range(14):
		var week: int = model.REGULAR_WEEKS[round_index]
		var entry: Dictionary = model.get_week(season, week)
		var seen: Array[String] = []
		if entry["fixture_ids"].size() != 4 or entry["events"][0]["round"] != round_index + 1:
			valid_rounds = false
		for fixture_id in entry["fixture_ids"]:
			var fixture: Dictionary = season["fixtures"][fixture_id]
			if fixture["week"] != week or fixture["round"] != round_index + 1:
				valid_rounds = false
			if seen.has(fixture["home"]) or seen.has(fixture["away"]):
				valid_rounds = false
			seen.append(fixture["home"])
			seen.append(fixture["away"])
			club_counts[fixture["home"]] += 1
			club_counts[fixture["away"]] += 1
			home_counts[fixture["home"]] += 1
			var pair: Array = [fixture["home"], fixture["away"]]
			pair.sort()
			var key: String = pair[0] + "|" + pair[1]
			if not pair_hosts.has(key):
				pair_hosts[key] = []
			pair_hosts[key].append(fixture["home"])
		if seen.size() != 8:
			valid_rounds = false
	check(valid_rounds, "Each regular week has four matches and each club plays once")
	var balanced := true
	for team in teams:
		if club_counts[team] != 14 or home_counts[team] != 7:
			balanced = false
	for hosts in pair_hosts.values():
		if hosts.size() != 2 or hosts[0] == hosts[1]:
			balanced = false
	check(balanced and pair_hosts.size() == 28,
		"Every opponent appears once home and once away; every club has seven home games")

	var national_weeks := [7, 15, 23, 25]
	var valid_windows := true
	for week in national_weeks:
		var entry: Dictionary = model.get_week(season, week)
		if not entry["fixture_ids"].is_empty() or entry["events"][0]["type"] != "national_window":
			valid_windows = false
	check(valid_windows, "National-team windows never collide with club fixtures")
	check(model.get_week(season, 15)["events"][0]["competition"] == "continental_qualifier"
		and model.get_week(season, 23)["events"][0]["competition"] == "world_cup_qualifier",
		"First season reserves qualifier opportunities without launching cup matches")
	check(model.get_week(model.create_season(teams, 2), 15)["events"][0]["competition"] == "continental_cup"
		and model.get_week(model.create_season(teams, 4), 23)["events"][0]["competition"] == "world_cup",
		"Future seasons reserve continental and World Cup windows")
	check(model.get_week(season, 30)["events"][0]["type"] == "championship_semifinals"
		and model.get_week(season, 32)["events"][0]["type"] == "championship_final",
		"The final month contains championship semifinals and final")
	check(model.get_week(season, 0).is_empty() and model.get_week(season, 33).is_empty(),
		"Out-of-range week lookups are harmless")
	var detached_week: Dictionary = model.get_week(season, 1)
	detached_week["events"].clear()
	check(not model.get_week(season, 1)["events"].is_empty(), "Week lookups cannot mutate the saved calendar")

	var first: Dictionary = season["fixtures"][0]
	check(model.record_result(season, 0, 0, 0), "A drawn match can be recorded")
	var standings: Array[Dictionary] = model.get_standings(season)
	var tied_rows := []
	for row in standings:
		if row["team"] == first["home"] or row["team"] == first["away"]:
			tied_rows.append(row)
	check(tied_rows.size() == 2 and tied_rows[0]["points"] == 1 and tied_rows[1]["points"] == 1
		and tied_rows[0]["draws"] == 1 and tied_rows[1]["draws"] == 1,
		"Draws give each club one point")
	check(not model.record_result(season, 0, 2, 1) and not model.record_result(season, 1, -1, 0)
		and not model.record_result(season, 56, 1, 0),
		"Played fixtures, negative scores, and unknown fixture IDs are rejected")
	check(not model.get_postseason(season)["ready"], "Championship qualification waits for all regular fixtures")

	var tiebreak_season: Dictionary = model.create_season(teams)
	model.record_result(tiebreak_season, 0, 1, 0)
	model.record_result(tiebreak_season, 1, 3, 2)
	var tie_rows: Array[Dictionary] = model.get_standings(tiebreak_season)
	check(tie_rows[0]["team"] == tiebreak_season["fixtures"][1]["home"]
		and tie_rows[1]["team"] == tiebreak_season["fixtures"][0]["home"],
		"Equal points and score difference break by score for")

	var ranked: Dictionary = model.create_season(teams)
	for fixture in ranked["fixtures"]:
		var home_better: bool = teams.find(fixture["home"]) < teams.find(fixture["away"])
		if home_better:
			model.record_result(ranked, fixture["id"], 1, 0)
		else:
			model.record_result(ranked, fixture["id"], 0, 1)
	var final_table: Array[Dictionary] = model.get_standings(ranked)
	var ordered := true
	for index in range(teams.size()):
		if (final_table[index]["team"] != teams[index]
			or final_table[index]["played"] != 14
			or final_table[index]["points"] != (7 - index) * 6):
			ordered = false
	check(ordered, "Standings award three points per win and sort the full league")
	var postseason: Dictionary = model.get_postseason(ranked)
	check(postseason["ready"] and postseason["championship_qualifiers"] == ["A", "B", "C", "D"],
		"Top four qualify for the championship")
	check(postseason["semifinals"][0]["home"] == "A" and postseason["semifinals"][0]["away"] == "D"
		and postseason["semifinals"][1]["home"] == "B" and postseason["semifinals"][1]["away"] == "C"
		and postseason["semifinals"][0].get("best_of", 1) == 3
		and postseason["semifinals"][0].get("scheduled_days", []) == [199, 202, 205],
		"Championship seeds play first versus fourth and second versus third")
	check(postseason["promotion_candidates"] == ["A", "B"]
		and postseason["relegation_candidates"] == ["H", "G"],
		"Top two and bottom two are identified for promotion and relegation")

	print("Season calendar: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
