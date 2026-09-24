# competition_rule_book.gd
# Factory producing named rule presets copied into scheduled fixtures.
class_name CompetitionRuleBook
extends RefCounted

const MatchRulesScript = preload("res://scripts/match_rules.gd")

static func create_rules(preset_id: String) -> MatchRules:
	return get_preset(preset_id)

func get_rules(preset_id: String) -> MatchRules:
	return CompetitionRuleBook.get_preset(preset_id)

static func has_preset(preset_id: String) -> bool:
	return _PRESET_DEFINITIONS.has(preset_id)

static func get_preset(preset_id: String) -> MatchRules:
	if not _PRESET_DEFINITIONS.has(preset_id):
		push_error("[CompetitionRuleBook] Unknown preset ID: %s" % preset_id)
		return null
	var def: Dictionary = _PRESET_DEFINITIONS[preset_id]
	return MatchRulesScript.from_dict(def)

static func get_all_presets() -> Dictionary:
	var result := {}
	for k in _PRESET_DEFINITIONS:
		result[k] = get_preset(k)
	return result

const _PRESET_DEFINITIONS = {
	"street_duel": {
		"competition_id": "street_duel",
		"stage": "Street Clash",
		"team_size": 1,
		"best_of": 1,
		"max_substitutions": 0,
		"arena_preset": "street_backlot",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 1,
		"is_knockout": false,
		"reward_policy": {
			"win_gold": 75,
			"loss_gold": 20,
			"win_xp": 60,
			"loss_xp": 10
		}
	},
	"club_friendly": {
		"competition_id": "club_friendly",
		"stage": "Mid-Season Scrimmage",
		"team_size": 3,
		"best_of": 1,
		"max_substitutions": 1,
		"arena_preset": "training_ground",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 1,
		"is_knockout": false,
		"reward_policy": {
			"win_gold": 40,
			"loss_gold": 10,
			"win_xp": 30,
			"loss_xp": 10,
			"xp_multiplier": 0.5
		}
	},
	"city_league": {
		"competition_id": "city_league",
		"stage": "City Club League",
		"team_size": 3,
		"best_of": 1,
		"max_substitutions": 1,
		"arena_preset": "standard_stadium",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 14,
		"is_knockout": false,
		"reward_policy": {
			"win_gold": 200,
			"loss_gold": 40,
			"win_xp": 60,
			"loss_xp": 24,
			"shards": 5,
			"league_points_win": 3,
			"league_points_draw": 1
		}
	},
	"regional_league": {
		"competition_id": "regional_league",
		"stage": "Regional Club League",
		"team_size": 3,
		"best_of": 1,
		"max_substitutions": 1,
		"arena_preset": "standard_stadium",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 14,
		"is_knockout": false,
		"reward_policy": {
			"win_gold": 200,
			"loss_gold": 40,
			"win_xp": 60,
			"loss_xp": 24,
			"shards": 5,
			"league_points_win": 3,
			"league_points_draw": 1
		}
	},
	"national_league": {
		"competition_id": "national_league",
		"stage": "National Club League",
		"team_size": 3,
		"best_of": 1,
		"max_substitutions": 1,
		"arena_preset": "standard_stadium",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 14,
		"is_knockout": false,
		"reward_policy": {
			"win_gold": 200,
			"loss_gold": 40,
			"win_xp": 60,
			"loss_xp": 24,
			"shards": 5,
			"league_points_win": 3,
			"league_points_draw": 1
		}
	},
	"city_semis": {
		"competition_id": "city_semis",
		"stage": "City Championship Semifinal",
		"team_size": 3,
		"best_of": 3,
		"max_substitutions": 1,
		"arena_preset": "championship_arena",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 250,
			"loss_gold": 50,
			"win_xp": 75,
			"loss_xp": 30
		}
	},
	"city_final": {
		"competition_id": "city_final",
		"stage": "City Championship Final",
		"team_size": 3,
		"best_of": 3,
		"max_substitutions": 1,
		"arena_preset": "championship_arena",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 500,
			"loss_gold": 100,
			"win_xp": 100,
			"loss_xp": 40,
			"trophy": "city_cup"
		}
	},
	"regional_semis": {
		"competition_id": "regional_semis",
		"stage": "Regional Championship Semifinal",
		"team_size": 3,
		"best_of": 3,
		"max_substitutions": 1,
		"arena_preset": "championship_arena",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 350,
			"loss_gold": 75,
			"win_xp": 90,
			"loss_xp": 35
		}
	},
	"regional_final": {
		"competition_id": "regional_final",
		"stage": "Regional Championship Final",
		"team_size": 3,
		"best_of": 3,
		"max_substitutions": 1,
		"arena_preset": "championship_arena",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 750,
			"loss_gold": 150,
			"win_xp": 120,
			"loss_xp": 50,
			"trophy": "regional_cup"
		}
	},
	"national_semis": {
		"competition_id": "national_semis",
		"stage": "National Championship Semifinal",
		"team_size": 3,
		"best_of": 3,
		"max_substitutions": 1,
		"arena_preset": "grand_colosseum",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 500,
			"loss_gold": 100,
			"win_xp": 100,
			"loss_xp": 40
		}
	},
	"national_final": {
		"competition_id": "national_final",
		"stage": "National Cup Final",
		"team_size": 5,
		"best_of": 5,
		"max_substitutions": 2,
		"arena_preset": "apex_colosseum",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {
			"win_gold": 1000,
			"loss_gold": 250,
			"win_xp": 150,
			"loss_xp": 60,
			"trophy": "national_cup"
		}
	},
	"continental_cup_knockout": {
		"competition_id": "continental_cup_knockout",
		"stage": "Continental Club Knockout",
		"team_size": 5,
		"best_of": 3,
		"max_substitutions": 2,
		"arena_preset": "continental_dome",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {}
	},
	"club_world_cup_knockout": {
		"competition_id": "club_world_cup_knockout",
		"stage": "Club World Championship",
		"team_size": 5,
		"best_of": 3,
		"max_substitutions": 2,
		"arena_preset": "world_stadium",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {}
	},
	"national_friendly": {
		"competition_id": "national_friendly",
		"stage": "International Friendly",
		"team_size": 3,
		"best_of": 1,
		"max_substitutions": 1,
		"arena_preset": "national_park",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 0,
		"date_spacing": 1,
		"is_knockout": false,
		"reward_policy": {}
	},
	"national_world_cup_knockout": {
		"competition_id": "national_world_cup_knockout",
		"stage": "National-Team World Cup",
		"team_size": 5,
		"best_of": 3,
		"max_substitutions": 2,
		"arena_preset": "olympic_colosseum",
		"edge_rule": "collision",
		"round_limit": 12,
		"overtime_max_rounds": 2,
		"date_spacing": 3,
		"is_knockout": true,
		"reward_policy": {}
	}
}
