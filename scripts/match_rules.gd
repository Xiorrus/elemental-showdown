# match_rules.gd
# RefCounted object holding an immutable rules snapshot for a match or series.
class_name MatchRules
extends RefCounted

var competition_id: String = ""
var stage: String = ""
var team_size: int = 3 # Exactly 1, 3, or 5
var best_of: int = 1 # Exactly 1, 3, or 5
var max_substitutions: int = 1
var arena_preset: String = "standard_stadium"
var edge_rule: String = "collision" # "collision", "ring_out", "shock_fence"
var round_limit: int = 12
var overtime_max_rounds: int = 2
var date_spacing: int = 3
var reward_policy: Dictionary = {}
var is_knockout: bool = false

# Backward-compat and property aliases
var stage_name: String:
	get:
		return stage
	set(value):
		stage = value

var overtime_rounds: int:
	get:
		return overtime_max_rounds
	set(value):
		overtime_max_rounds = value

func _init(p_competition_id: String = "", p_stage: String = "", p_team_size: int = 3, p_best_of: int = 1) -> void:
	competition_id = p_competition_id
	stage = p_stage
	team_size = p_team_size
	best_of = p_best_of

func wins_needed() -> int:
	return int(best_of / 2) + 1

func is_valid() -> bool:
	if not (team_size in [1, 3, 5]):
		return false
	if not (best_of in [1, 3, 5]):
		return false
	if max_substitutions < 0:
		return false
	if round_limit <= 0:
		return false
	if overtime_max_rounds < 0:
		return false
	if date_spacing < 0:
		return false
	if not (edge_rule in ["collision", "ring_out", "shock_fence"]):
		return false
	if competition_id.strip_edges().is_empty():
		return false
	return true

func to_dict() -> Dictionary:
	return {
		"competition_id": competition_id,
		"stage": stage,
		"stage_name": stage,
		"team_size": team_size,
		"best_of": best_of,
		"max_substitutions": max_substitutions,
		"arena_preset": arena_preset,
		"edge_rule": edge_rule,
		"round_limit": round_limit,
		"overtime_max_rounds": overtime_max_rounds,
		"overtime_rounds": overtime_max_rounds,
		"date_spacing": date_spacing,
		"reward_policy": reward_policy.duplicate(true),
		"is_knockout": is_knockout
	}

static func from_dict(d: Dictionary) -> MatchRules:
	if d.is_empty():
		return null
	var r := MatchRules.new()
	r.competition_id = str(d.get("competition_id", ""))
	r.stage = str(d.get("stage", d.get("stage_name", "")))
	r.team_size = int(d.get("team_size", 3))
	r.best_of = int(d.get("best_of", 1))
	r.max_substitutions = int(d.get("max_substitutions", 1))
	r.arena_preset = str(d.get("arena_preset", "standard_stadium"))
	r.edge_rule = str(d.get("edge_rule", "collision"))
	r.round_limit = int(d.get("round_limit", 12))
	r.overtime_max_rounds = int(d.get("overtime_max_rounds", d.get("overtime_rounds", 2)))
	r.date_spacing = int(d.get("date_spacing", 3))
	r.is_knockout = bool(d.get("is_knockout", false))
	if d.has("reward_policy") and d["reward_policy"] is Dictionary:
		r.reward_policy = d["reward_policy"].duplicate(true)
	
	if not r.is_valid():
		return null
	return r
