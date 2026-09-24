# A deterministic club-season model. The campaign decides when to advance weeks
# and which battles to play; this class only owns fixtures, results and standings.
extends RefCounted
class_name SeasonCalendar

const CompetitionRuleBookScript = preload("res://scripts/competition_rule_book.gd")
const SeriesStateScript = preload("res://scripts/series_state.gd")

const WEEKS_PER_SEASON := 32
const DAYS_PER_WEEK := 7
const DAYS_PER_SEASON := WEEKS_PER_SEASON * DAYS_PER_WEEK
const WEEKS_PER_MONTH := 4
const CLUB_COUNT := 8
const REGULAR_WEEKS := [2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28]
const NATIONAL_WEEKS := [7, 15, 23, 25]
const CLUB_FRIENDLY_WEEKS := [1, 17]
const TRANSFER_WINDOW_WEEKS := [1, 17]
const MONTH_NAMES := ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const DEFAULT_TEAMS := [
	"Phoenix Strikers", "Hydro Vipers", "Gale Force", "Terra Titans",
	"Ember Hawks", "Crystal Wardens", "Storm Runners", "Tidebreakers"
]


func create_season(team_names: Array = DEFAULT_TEAMS, season_number: int = 1, tier: int = 1) -> Dictionary:
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
		"league_tier": tier,
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
			if event.get("type", "") in ["national_window", "club_friendly"]:
				events.append(event.duplicate(true))

	var tier: int = int(season.get("league_tier", 1))
	var final_days := [210, 213, 216] if tier < 3 else [210, 213, 216, 220, 223]
	if season_day in [199, 202, 205]:
		_append_semifinal_event(events, season, club_name, season_day)
	elif season_day in final_days:
		_append_final_event(events, season, club_name, season_day)
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
		"relegation_candidates": [],
		"series": {}
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

	var season_num: int = int(season.get("season_number", 1))
	var tier: int = int(season.get("league_tier", 1))
	var semi_preset := "city_semis"
	if tier == 2:
		semi_preset = "regional_semis"
	elif tier >= 3:
		semi_preset = "national_semis"
	var semi1_id: String = "s%d_semi_1" % season_num
	var semi2_id: String = "s%d_semi_2" % season_num
	var semi_rules := CompetitionRuleBookScript.get_preset(semi_preset)
	var semi_days := [199, 202, 205]

	var semi1_state := SeriesStateScript.new(semi1_id, semi_preset, standings[0]["team"], standings[3]["team"], 3, semi_days)
	semi1_state.rules = semi_rules
	var semi2_state := SeriesStateScript.new(semi2_id, semi_preset, standings[1]["team"], standings[2]["team"], 3, semi_days)
	semi2_state.rules = semi_rules

	summary["semifinals"] = [
		{
			"home": standings[0]["team"],
			"away": standings[3]["team"],
			"series_id": semi1_id,
			"competition_id": semi_preset,
			"best_of": 3,
			"scheduled_days": semi_days,
			"rules": semi_rules.to_dict(),
			"series_state": semi1_state.to_dict()
		},
		{
			"home": standings[1]["team"],
			"away": standings[2]["team"],
			"series_id": semi2_id,
			"competition_id": semi_preset,
			"best_of": 3,
			"scheduled_days": semi_days,
			"rules": semi_rules.to_dict(),
			"series_state": semi2_state.to_dict()
		}
	]
	summary["series"] = {
		semi1_id: semi1_state.to_dict(),
		semi2_id: semi2_state.to_dict()
	}
	summary["ready"] = true
	return summary


func _append_semifinal_event(events: Array, season: Dictionary, club_name: String, season_day: int) -> void:
	var semi_days := [199, 202, 205]
	var g_idx := semi_days.find(season_day)
	var series_info := _find_series_entry(season, club_name, season_day, "semi")
	if not series_info.is_empty():
		events.append(series_info)
	else:
		events.append({
			"type": "championship_semifinals",
			"game_index": g_idx,
			"game_number": g_idx + 1,
			"game_label": "G%d" % (g_idx + 1),
			"if_needed": (g_idx == 2),
			"status": "if_needed" if g_idx == 2 else "scheduled",
			"qualifiers": 4
		})


func _append_final_event(events: Array, season: Dictionary, club_name: String, season_day: int) -> void:
	var tier: int = int(season.get("league_tier", 1))
	var series_info := _find_series_entry(season, club_name, season_day, "final")
	if not series_info.is_empty():
		events.append(series_info)
	else:
		var final_days := [210, 213, 216] if tier < 3 else [210, 213, 216, 220, 223]
		if not season_day in final_days:
			return
		var g_idx := final_days.find(season_day)
		var best_of: int = 3 if tier < 3 else 5
		var wins_needed: int = int(best_of / 2) + 1
		events.append({
			"type": "championship_final",
			"game_index": g_idx,
			"game_number": g_idx + 1,
			"game_label": "G%d" % (g_idx + 1),
			"if_needed": (g_idx >= wins_needed),
			"status": "if_needed" if g_idx >= wins_needed else "scheduled"
		})


func _find_series_entry(season: Dictionary, club_name: String, season_day: int, kind: String) -> Dictionary:
	var series_pool := {}
	if season.get("series") is Dictionary:
		for k in season["series"]:
			series_pool[k] = season["series"][k]
	if season.get("championship_state") is Dictionary and season["championship_state"].get("series") is Dictionary:
		for k in season["championship_state"]["series"]:
			series_pool[k] = season["championship_state"]["series"][k]
	if season.get("postseason") is Dictionary and season["postseason"].get("series") is Dictionary:
		for k in season["postseason"]["series"]:
			series_pool[k] = season["postseason"]["series"][k]

	for s_id in series_pool:
		var s_data = series_pool[s_id]
		var s: SeriesState = s_data if s_data is SeriesState else SeriesStateScript.from_dict(s_data)
		if s == null:
			continue
		if not (club_name in [s.home_team, s.away_team]):
			continue
		if season_day in s.scheduled_days:
			var g_idx: int = s.scheduled_days.find(season_day)
			var status: String = s.get_game_status(g_idx)
			var is_home: bool = (s.home_team == club_name)
			var opponent: String = s.away_team if is_home else s.home_team
			var event_type: String = "championship_semifinals" if kind == "semi" else "championship_final"
			return {
				"type": event_type,
				"series_id": s.series_id,
				"competition_id": s.competition_id,
				"opponent": opponent,
				"home": is_home,
				"game_index": g_idx,
				"game_number": g_idx + 1,
				"game_label": "G%d" % (g_idx + 1),
				"status": status,
				"if_needed": (g_idx >= s.wins_needed()),
				"best_of": s.best_of,
				"played": (status == "played"),
				"series_state": s.to_dict()
			}
	return {}
