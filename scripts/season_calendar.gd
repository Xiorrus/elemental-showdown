# A deterministic club-season model. The campaign decides when to advance weeks
# and which battles to play; this class only owns fixtures, results and standings.
extends RefCounted
class_name SeasonCalendar

const WEEKS_PER_SEASON := 32
const DAYS_PER_WEEK := 7
const DAYS_PER_SEASON := WEEKS_PER_SEASON * DAYS_PER_WEEK
const WEEKS_PER_MONTH := 4
const CLUB_COUNT := 8
const REGULAR_WEEKS := [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28]
const NATIONAL_WEEKS := [7, 15, 23, 31]
const CLUB_FRIENDLY_WEEKS := [1, 17]
const TRANSFER_WINDOW_WEEKS := [1, 17]
const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const DEFAULT_TEAMS := [
	"Phoenix Strikers", "Hydro Vipers", "Gale Force", "Terra Titans",
	"Ember Hawks", "Crystal Wardens", "Storm Runners", "Tidebreakers"
]


func create_season(team_names: Array = DEFAULT_TEAMS, season_number: int = 1) -> Dictionary:
	# Exactly eight distinct clubs keeps each week at four matches and gives every
	# club seven opponents to face once at home and once away.
	if team_names.size() != CLUB_COUNT or season_number < 1:
		return {}
	var teams: Array[String] = []
	var normalized_names: Array[String] = []
	for value in team_names:
		if not value is String or value.strip_edges().is_empty():
			return {}
		var name: String = value.strip_edges()
		if normalized_names.has(name.to_lower()):
			return {}
		teams.append(name)
		normalized_names.append(name.to_lower())

	var calendar: Array[Dictionary] = []
	for week in range(1, WEEKS_PER_SEASON + 1):
		calendar.append({
			"week": week,
			"month": int((week - 1) / WEEKS_PER_MONTH) + 1,
			"events": [],
			"fixture_ids": []
		})

	# Circle scheduling pairs every club exactly once per round. The return leg
	# reverses home and away for each pairing.
	var rotation: Array[String] = teams.duplicate()
	var first_leg: Array[Array] = []
	for round_index in range(CLUB_COUNT - 1):
		var pairings: Array[Dictionary] = []
		for slot in range(CLUB_COUNT / 2):
			var home: String = rotation[slot]
			var away: String = rotation[CLUB_COUNT - 1 - slot]
			if round_index % 2 == 1:
				var swap: String = home
				home = away
				away = swap
			pairings.append({"home": home, "away": away})
		first_leg.append(pairings)
		rotation.insert(1, rotation.pop_back())

	var fixtures: Array[Dictionary] = []
	for round_index in range(REGULAR_WEEKS.size()):
		var week: int = REGULAR_WEEKS[round_index]
		var week_entry: Dictionary = calendar[week - 1]
		week_entry["events"].append({"type": "club_round", "round": round_index + 1})
		for pairing in first_leg[round_index % (CLUB_COUNT - 1)]:
			var home: String = pairing["home"]
			var away: String = pairing["away"]
			if round_index >= CLUB_COUNT - 1:
				var swap: String = home
				home = away
				away = swap
			var fixture_id: int = fixtures.size()
			fixtures.append({
				"id": fixture_id,
				"round": round_index + 1,
				"week": week,
				"home": home,
				"away": away,
				"played": false,
				"home_score": -1,
				"away_score": -1
			})
			week_entry["fixture_ids"].append(fixture_id)

	for week in NATIONAL_WEEKS:
		calendar[week - 1]["events"].append(_national_window(week, season_number))
	for week in CLUB_FRIENDLY_WEEKS:
		calendar[week - 1]["events"].append({"type": "club_friendly", "optional": true})
	for week in TRANSFER_WINDOW_WEEKS:
		calendar[week - 1]["events"].append({"type": "transfer_window", "optional": true})
	calendar[29]["events"].append({"type": "championship_semifinals", "qualifiers": 4})
	calendar[31]["events"].append({"type": "championship_final"})
	for week_entry in calendar:
		if week_entry["events"].is_empty():
			week_entry["events"].append({"type": "rest_training"})

	return {
		"season_number": season_number,
		"weeks_total": WEEKS_PER_SEASON,
		"teams": teams,
		"fixtures": fixtures,
		"calendar": calendar
	}


func _national_window(week: int, season_number: int) -> Dictionary:
	# These are calendar opportunities, not simulated cup results. The campaign
	# can later decide whether a player is selected for a national squad.
	var competition := "friendly"
	if week == 15:
		competition = "continental_cup" if season_number % 2 == 0 else "continental_qualifier"
	elif week == 23:
		competition = "world_cup" if season_number % 4 == 0 else "world_cup_qualifier"
	return {"type": "national_window", "competition": competition, "optional": true}


func get_week(season: Dictionary, week: int) -> Dictionary:
	var calendar: Array = season.get("calendar", [])
	if week < 1 or week > calendar.size():
		return {}
	return calendar[week - 1].duplicate(true)


func get_fixture_day(week: int) -> int:
	return clampi(week, 1, WEEKS_PER_SEASON) * DAYS_PER_WEEK


func get_day_entry(season: Dictionary, club_name: String, season_day: int, season_year: int = 2026) -> Dictionary:
	if season_day < 1 or season_day > DAYS_PER_SEASON:
		return {}
	var week := int((season_day - 1) / DAYS_PER_WEEK) + 1
	var day_in_week := (season_day - 1) % DAYS_PER_WEEK + 1
	var stamp := Time.get_unix_time_from_datetime_dict({
		"year": season_year, "month": 9, "day": 1,
		"hour": 0, "minute": 0, "second": 0
	}) + (season_day - 1) * 86400
	var date := Time.get_datetime_dict_from_unix_time(stamp)
	var events: Array = []
	if day_in_week == DAYS_PER_WEEK:
		for fixture in season.get("fixtures", []):
			if int(fixture.get("week", -1)) == week and club_name in [fixture.get("home", ""), fixture.get("away", "")]:
				var opponent: String = fixture["away"] if fixture["home"] == club_name else fixture["home"]
				events.append({"type": "club_match", "opponent": opponent,
					"fixture_id": fixture["id"], "played": fixture.get("played", false),
					"home": fixture["home"] == club_name})
		for event in get_week(season, week).get("events", []):
			if event.get("type", "") in ["national_window", "club_friendly", "championship_semifinals", "championship_final"]:
				events.append(event.duplicate(true))
	return {
		"season_day": season_day,
		"week": week,
		"day_in_week": day_in_week,
		"year": int(date["year"]),
		"month_number": int(date["month"]),
		"day_of_month": int(date["day"]),
		"weekday": int(date["weekday"]),
		"date_label": "%s %02d, %d" % [MONTH_NAMES[int(date["month"]) - 1], int(date["day"]), int(date["year"])],
		"transfer_window": week in TRANSFER_WINDOW_WEEKS,
		"events": events
	}


func get_calendar_days(season: Dictionary, club_name: String, season_year: int = 2026) -> Array:
	var days: Array = []
	for day in range(1, DAYS_PER_SEASON + 1):
		days.append(get_day_entry(season, club_name, day, season_year))
	return days


func record_result(season: Dictionary, fixture_id: int, home_score: int, away_score: int) -> bool:
	var fixtures: Array = season.get("fixtures", [])
	if fixture_id < 0 or fixture_id >= fixtures.size() or home_score < 0 or away_score < 0:
		return false
	var fixture: Dictionary = fixtures[fixture_id]
	if fixture.get("played", false):
		return false
	fixture["played"] = true
	fixture["home_score"] = home_score
	fixture["away_score"] = away_score
	return true


func get_standings(season: Dictionary) -> Array[Dictionary]:
	var table: Dictionary = {}
	for team in season.get("teams", []):
		table[team] = {
			"team": team, "played": 0, "wins": 0, "draws": 0, "losses": 0,
			"score_for": 0, "score_against": 0, "score_difference": 0, "points": 0
		}
	for fixture in season.get("fixtures", []):
		if not fixture.get("played", false):
			continue
		var home: Dictionary = table.get(fixture["home"], {})
		var away: Dictionary = table.get(fixture["away"], {})
		if home.is_empty() or away.is_empty():
			continue
		var home_score: int = fixture["home_score"]
		var away_score: int = fixture["away_score"]
		home["played"] += 1
		away["played"] += 1
		home["score_for"] += home_score
		home["score_against"] += away_score
		away["score_for"] += away_score
		away["score_against"] += home_score
		if home_score > away_score:
			home["wins"] += 1
			home["points"] += 3
			away["losses"] += 1
		elif home_score < away_score:
			away["wins"] += 1
			away["points"] += 3
			home["losses"] += 1
		else:
			home["draws"] += 1
			away["draws"] += 1
			home["points"] += 1
			away["points"] += 1
	var standings: Array[Dictionary] = []
	for team in table:
		var row: Dictionary = table[team]
		row["score_difference"] = row["score_for"] - row["score_against"]
		standings.append(row)
	standings.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		for key in ["points", "score_difference", "score_for", "wins"]:
			if a[key] != b[key]:
				return a[key] > b[key]
		return a["team"] < b["team"]
	)
	return standings


func get_postseason(season: Dictionary) -> Dictionary:
	var summary := {
		"ready": false,
		"championship_qualifiers": [],
		"semifinals": [],
		"promotion_candidates": [],
		"relegation_candidates": []
	}
	var fixtures: Array = season.get("fixtures", [])
	if fixtures.size() != CLUB_COUNT * (CLUB_COUNT - 1):
		return summary
	for fixture in fixtures:
		if not fixture.get("played", false):
			return summary
	var standings := get_standings(season)
	if standings.size() != CLUB_COUNT:
		return summary
	for rank in range(4):
		summary["championship_qualifiers"].append(standings[rank]["team"])
	for rank in range(2):
		summary["promotion_candidates"].append(standings[rank]["team"])
		summary["relegation_candidates"].append(standings[CLUB_COUNT - 1 - rank]["team"])
	summary["semifinals"] = [
		{"home": standings[0]["team"], "away": standings[3]["team"]},
		{"home": standings[1]["team"], "away": standings[2]["team"]}
	]
	summary["ready"] = true
	return summary
