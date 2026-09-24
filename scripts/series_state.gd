# series_state.gd
# Encapsulates series ID, teams, dates, per-team wins, unique recorded game IDs, and clinch determination.
class_name SeriesState
extends RefCounted

const MatchRulesScript = preload("res://scripts/match_rules.gd")

var series_id: String = ""
var competition_id: String = ""
var home_team: String = ""
var away_team: String = ""
var best_of: int = 3 # 1, 3, or 5
var scheduled_days: Array = [] # Array of int season days
var current_game_index: int = 0
var wins: Array = [0, 0] # [home_wins, away_wins]
var recorded_games: Dictionary = {} # game_id -> Dictionary details
var winner: String = ""
var is_clinched: bool = false
var scouting_memory: Dictionary = {}
var game_results: Array = []
var rules: MatchRules = null

func _init(p_series_id: String = "", p_comp_id: String = "", p_home: String = "", p_away: String = "", p_best_of: int = 3, p_days: Array = []) -> void:
	series_id = p_series_id
	competition_id = p_comp_id
	home_team = p_home
	away_team = p_away
	best_of = p_best_of
	scheduled_days = p_days.duplicate()
	wins = [0, 0]
	recorded_games = {}
	game_results = []
	scouting_memory = {}
	is_clinched = false
	winner = ""
	current_game_index = 0

func wins_needed() -> int:
	return int(best_of / 2) + 1

func is_complete() -> bool:
	return is_clinched or (wins[0] >= wins_needed() or wins[1] >= wins_needed())

func get_winner() -> String:
	return winner

func get_next_scheduled_day() -> int:
	if is_complete():
		return -1
	if current_game_index < scheduled_days.size():
		return int(scheduled_days[current_game_index])
	return -1

func record_game(game_id: String, winning_side: int, details: Dictionary = {}) -> bool:
	if game_id.strip_edges().is_empty():
		return false
	if not (winning_side in [0, 1]):
		return false
	if recorded_games.has(game_id):
		return false
	if is_complete():
		return false

	var entry: Dictionary = details.duplicate(true) if not details.is_empty() else {}
	entry["game_id"] = game_id
	entry["winning_side"] = winning_side
	recorded_games[game_id] = entry
	wins[winning_side] += 1
	current_game_index += 1
	game_results.append(entry)

	if entry.has("scouting") and entry["scouting"] is Dictionary:
		for k in entry["scouting"]:
			scouting_memory[k] = entry["scouting"][k]

	if wins[winning_side] >= wins_needed():
		is_clinched = true
		winner = home_team if winning_side == 0 else away_team

	return true

func get_game_status(game_idx: int) -> String:
	if game_idx < 0 or game_idx >= best_of:
		return ""
	if game_idx < current_game_index:
		return "played"
	if is_complete():
		return "not_needed"
	if game_idx == current_game_index:
		return "next"
	return "if_needed"

func to_dict() -> Dictionary:
	return {
		"series_id": series_id,
		"competition_id": competition_id,
		"home_team": home_team,
		"away_team": away_team,
		"best_of": best_of,
		"scheduled_days": scheduled_days.duplicate(),
		"current_game_index": current_game_index,
		"wins": wins.duplicate(),
		"recorded_games": recorded_games.duplicate(true),
		"winner": winner,
		"is_clinched": is_clinched,
		"scouting_memory": scouting_memory.duplicate(true),
		"game_results": game_results.duplicate(true),
		"rules": rules.to_dict() if rules != null else {}
	}

static func from_dict(d: Dictionary) -> SeriesState:
	if d.is_empty():
		return null
	var bo := int(d.get("best_of", 3))
	if not (bo in [1, 3, 5]):
		return null

	var s := SeriesState.new()
	s.series_id = str(d.get("series_id", ""))
	s.competition_id = str(d.get("competition_id", ""))
	s.home_team = str(d.get("home_team", ""))
	s.away_team = str(d.get("away_team", ""))
	s.best_of = bo
	s.scheduled_days = []
	for day in d.get("scheduled_days", []):
		s.scheduled_days.append(int(day))
	s.current_game_index = int(d.get("current_game_index", 0))

	var raw_wins = d.get("wins", [0, 0])
	if raw_wins is Array and raw_wins.size() == 2:
		s.wins = [int(raw_wins[0]), int(raw_wins[1])]
	else:
		s.wins = [0, 0]

	if d.get("recorded_games") is Dictionary:
		s.recorded_games = d["recorded_games"].duplicate(true)
	else:
		s.recorded_games = {}

	s.winner = str(d.get("winner", ""))
	s.is_clinched = bool(d.get("is_clinched", false))

	if d.get("scouting_memory") is Dictionary:
		s.scouting_memory = d["scouting_memory"].duplicate(true)
	else:
		s.scouting_memory = {}

	if d.get("game_results") is Array:
		s.game_results = d["game_results"].duplicate(true)
	else:
		s.game_results = []

	if d.get("rules") is Dictionary and not d["rules"].is_empty():
		s.rules = MatchRulesScript.from_dict(d["rules"])

	# Re-verify clinch if wins reflect a clinch
	if s.wins[0] >= s.wins_needed() or s.wins[1] >= s.wins_needed():
		s.is_clinched = true
		if s.winner.is_empty():
			s.winner = s.home_team if s.wins[0] >= s.wins_needed() else s.away_team

	return s
