# game_result.gd
# RefCounted immutable single-game result record returned to CampaignManager.
class_name GameResult
extends RefCounted

var game_id: String = ""
var series_id: String = ""
var fixture_id: Variant = -1
var winner_name: String = ""
var loser_name: String = ""
var is_draw: bool = false
var winning_side: int = -1 # 0 = home, 1 = away, -1 = draw
var turns_played: int = 0
var judge_score: Dictionary = {}
var was_overtime: bool = false
var was_judge_decision: bool = false
var is_skipped: bool = false
var xp_awarded: int = 0
var gold_awarded: int = 0
var details: Dictionary = {}

func _init(p_game_id: String = "", p_series_id: String = "", p_winning_side: int = -1, p_winner_name: String = "", p_loser_name: String = "", p_turns: int = 0) -> void:
	game_id = p_game_id
	series_id = p_series_id
	winning_side = p_winning_side
	winner_name = p_winner_name
	loser_name = p_loser_name
	turns_played = p_turns
	is_draw = (winning_side == -1)

func to_dict() -> Dictionary:
	return {
		"game_id": game_id,
		"series_id": series_id,
		"fixture_id": fixture_id,
		"winner_name": winner_name,
		"loser_name": loser_name,
		"is_draw": is_draw,
		"winning_side": winning_side,
		"turns_played": turns_played,
		"judge_score": judge_score.duplicate(true),
		"was_overtime": was_overtime,
		"was_judge_decision": was_judge_decision,
		"is_skipped": is_skipped,
		"xp_awarded": xp_awarded,
		"gold_awarded": gold_awarded,
		"details": details.duplicate(true)
	}

static func from_dict(d: Dictionary) -> GameResult:
	if d.is_empty():
		return null
	var res := GameResult.new()
	res.game_id = str(d.get("game_id", ""))
	res.series_id = str(d.get("series_id", ""))
	res.fixture_id = d.get("fixture_id", -1)
	res.winner_name = str(d.get("winner_name", ""))
	res.loser_name = str(d.get("loser_name", ""))
	res.winning_side = int(d.get("winning_side", -1))
	res.is_draw = bool(d.get("is_draw", res.winning_side == -1))
	res.turns_played = int(d.get("turns_played", 0))
	if d.get("judge_score") is Dictionary:
		res.judge_score = d["judge_score"].duplicate(true)
	res.was_overtime = bool(d.get("was_overtime", false))
	res.was_judge_decision = bool(d.get("was_judge_decision", false))
	res.is_skipped = bool(d.get("is_skipped", false))
	res.xp_awarded = int(d.get("xp_awarded", 0))
	res.gold_awarded = int(d.get("gold_awarded", 0))
	if d.get("details") is Dictionary:
		res.details = d["details"].duplicate(true)
	return res
