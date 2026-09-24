# match_context.gd
# Immutable launch snapshot injected into World, BattleManager, and UI.
class_name MatchContext
extends RefCounted

const MatchRulesScript = preload("res://scripts/match_rules.gd")

var fixture_id: Variant = -1
var series_id: String = ""
var game_id: String = ""
var game_index: int = 0
var season_day: int = 0
var home_team: String = ""
var away_team: String = ""
var rules: MatchRules = null
var seed_value: int = 0
var arena_id: String = "standard_stadium"

# Property aliases
var match_seed: int:
	get:
		return seed_value
	set(val):
		seed_value = val

var arena_preset: String:
	get:
		return arena_id
	set(val):
		arena_id = val

func _init(p_fixture_id: Variant = -1, p_series_id: String = "", p_game_id: String = "", p_day: int = 0, p_home: String = "", p_away: String = "", p_rules: MatchRules = null, p_seed: int = 0, p_arena: String = "standard_stadium") -> void:
	fixture_id = p_fixture_id
	series_id = p_series_id
	game_id = p_game_id
	season_day = p_day
	home_team = p_home
	away_team = p_away
	rules = p_rules
	seed_value = p_seed
	arena_id = p_arena

func to_dict() -> Dictionary:
	return {
		"fixture_id": fixture_id,
		"series_id": series_id,
		"game_id": game_id,
		"game_index": game_index,
		"season_day": season_day,
		"home_team": home_team,
		"away_team": away_team,
		"seed_value": seed_value,
		"match_seed": seed_value,
		"arena_id": arena_id,
		"arena_preset": arena_id,
		"rules": rules.to_dict() if rules != null else {}
	}

static func from_dict(d: Dictionary) -> MatchContext:
	if d.is_empty():
		return null
	var ctx := MatchContext.new()
	ctx.fixture_id = d.get("fixture_id", -1)
	ctx.series_id = str(d.get("series_id", ""))
	ctx.game_id = str(d.get("game_id", ""))
	ctx.game_index = int(d.get("game_index", 0))
	ctx.season_day = int(d.get("season_day", 0))
	ctx.home_team = str(d.get("home_team", ""))
	ctx.away_team = str(d.get("away_team", ""))
	ctx.seed_value = int(d.get("seed_value", d.get("match_seed", 0)))
	ctx.arena_id = str(d.get("arena_id", d.get("arena_preset", "standard_stadium")))
	if d.get("rules") is Dictionary and not d["rules"].is_empty():
		ctx.rules = MatchRulesScript.from_dict(d["rules"])
	return ctx
