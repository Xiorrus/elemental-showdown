extends SceneTree

# Test suite for MatchRules and CompetitionRuleBook.
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
	print("   MATCH RULES & COMPETITION RULE BOOK TEST SUITE")
	print("========================================================\n")

	_test_presets()
	_test_validation()
	_test_serialization()

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	if failed > 0:
		quit(1)
	else:
		quit(0)

func _test_presets() -> void:
	print("--- SUITE 1: CompetitionRuleBook Presets ---")

	var required_presets := [
		"street_duel", "club_friendly",
		"city_league", "regional_league", "national_league",
		"city_semis", "city_final",
		"regional_semis", "regional_final",
		"national_semis", "national_final",
		"continental_cup_knockout", "club_world_cup_knockout", "national_world_cup_knockout"
	]

	for preset_id in required_presets:
		check(CompetitionRuleBookScript.has_preset(preset_id), "Preset exists: %s" % preset_id)
		var rules: MatchRules = CompetitionRuleBookScript.get_preset(preset_id)
		check(rules != null and rules.is_valid(), "Preset %s produces valid MatchRules" % preset_id)

	# Verify specific preset requirements
	var street: MatchRules = CompetitionRuleBookScript.get_preset("street_duel")
	check(street.team_size == 1 and street.best_of == 1 and street.max_substitutions == 0,
		"street_duel is 1v1 Bo1 with 0 substitutions")

	var friendly: MatchRules = CompetitionRuleBookScript.get_preset("club_friendly")
	check(friendly.team_size == 3 and friendly.best_of == 1 and friendly.max_substitutions == 1,
		"club_friendly is 3v3 Bo1 default with 1 substitution")

	var city_semis: MatchRules = CompetitionRuleBookScript.get_preset("city_semis")
	check(city_semis.team_size == 3 and city_semis.best_of == 3 and city_semis.wins_needed() == 2,
		"city_semis is 3v3 Bo3 requiring 2 wins")
	check(city_semis.is_knockout and city_semis.overtime_max_rounds == 2,
		"city_semis is knockout with 2 overtime rounds")

	var nat_final: MatchRules = CompetitionRuleBookScript.get_preset("national_final")
	check(nat_final.team_size == 5 and nat_final.best_of == 5 and nat_final.wins_needed() == 3,
		"national_final is 5v5 Bo5 requiring 3 wins")
	check(nat_final.max_substitutions == 2 and nat_final.arena_preset == "apex_colosseum",
		"national_final has 2 subs and apex_colosseum arena")

func _test_validation() -> void:
	print("\n--- SUITE 2: MatchRules Validation Boundaries ---")

	# Valid team sizes: 1, 3, 5
	var r1 := MatchRules.new("test", "Test", 1, 1)
	check(r1.is_valid(), "team_size 1 is valid")
	var r3 := MatchRules.new("test", "Test", 3, 3)
	check(r3.is_valid(), "team_size 3 is valid")
	var r5 := MatchRules.new("test", "Test", 5, 5)
	check(r5.is_valid(), "team_size 5 is valid")

	# Invalid team sizes: 2, 4, 6
	var r2 := MatchRules.new("test", "Test", 2, 1)
	check(not r2.is_valid(), "team_size 2 is rejected")
	var r4 := MatchRules.new("test", "Test", 4, 1)
	check(not r4.is_valid(), "team_size 4 is rejected")
	var r6 := MatchRules.new("test", "Test", 6, 1)
	check(not r6.is_valid(), "team_size 6 is rejected")

	# Valid best_of: 1, 3, 5
	check(r1.wins_needed() == 1, "Bo1 wins_needed is 1")
	check(r3.wins_needed() == 2, "Bo3 wins_needed is 2")
	check(r5.wins_needed() == 3, "Bo5 wins_needed is 3")

	# Invalid best_of: 2, 4, 7
	var rb2 := MatchRules.new("test", "Test", 3, 2)
	check(not rb2.is_valid(), "best_of 2 is rejected")
	var rb4 := MatchRules.new("test", "Test", 3, 4)
	check(not rb4.is_valid(), "best_of 4 is rejected")
	var rb7 := MatchRules.new("test", "Test", 3, 7)
	check(not rb7.is_valid(), "best_of 7 is rejected")

	# Empty competition ID rejected
	var rempty := MatchRules.new("", "Test", 3, 1)
	check(not rempty.is_valid(), "Empty competition_id is rejected")

	# Invalid edge rule rejected
	var redge := MatchRules.new("test", "Test", 3, 1)
	redge.edge_rule = "teleport"
	check(not redge.is_valid(), "Invalid edge_rule 'teleport' is rejected")

func _test_serialization() -> void:
	print("\n--- SUITE 3: Serialization & from_dict Strictness ---")

	var original := CompetitionRuleBookScript.get_preset("city_semis")
	var dict_repr := original.to_dict()
	check(dict_repr.is_empty() == false, "to_dict() returns populated Dictionary")

	var restored := MatchRulesScript.from_dict(dict_repr)
	check(restored != null, "from_dict() successfully restores MatchRules")
	check(restored.competition_id == original.competition_id, "Restored competition_id matches")
	check(restored.stage == original.stage, "Restored stage matches")
	check(restored.team_size == original.team_size, "Restored team_size matches")
	check(restored.best_of == original.best_of, "Restored best_of matches")
	check(restored.max_substitutions == original.max_substitutions, "Restored max_substitutions matches")
	check(restored.arena_preset == original.arena_preset, "Restored arena_preset matches")
	check(restored.edge_rule == original.edge_rule, "Restored edge_rule matches")
	check(restored.round_limit == original.round_limit, "Restored round_limit matches")
	check(restored.overtime_max_rounds == original.overtime_max_rounds, "Restored overtime_max_rounds matches")
	check(restored.is_knockout == original.is_knockout, "Restored is_knockout matches")

	# from_dict rejects invalid dictionaries
	var bad_dict := dict_repr.duplicate()
	bad_dict["team_size"] = 4
	check(MatchRulesScript.from_dict(bad_dict) == null, "from_dict rejects invalid team_size 4")

	var bad_dict_bo := dict_repr.duplicate()
	bad_dict_bo["best_of"] = 2
	check(MatchRulesScript.from_dict(bad_dict_bo) == null, "from_dict rejects invalid best_of 2")

	check(MatchRulesScript.from_dict({}) == null, "from_dict rejects empty dictionary")
