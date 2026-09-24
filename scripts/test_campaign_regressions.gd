extends SceneTree

# Run with APPDATA redirected beneath this project's .godot directory.
# These tests deliberately replace saves, so refuse to touch normal player data.
var passed := 0
var failed := 0

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func write_save(data: Dictionary):
	var file = FileAccess.open("user://campaign_save.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func read_save() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string("user://campaign_save.json"))

func _run():
	var safe_root = ProjectSettings.globalize_path("res://.godot/").replace("\\", "/").to_lower()
	if not OS.get_user_data_dir().replace("\\", "/").to_lower().begins_with(safe_root):
		printerr("Redirect APPDATA beneath this project's .godot directory before running save tests.")
		quit(2)
		return
	await process_frame
	var cm = root.get_node("CampaignManager")
	var detached_manager = load("res://scripts/campaign_manager.gd").new()
	check(detached_manager._get_element_data() == root.get_node("ElementData"), "Detached save managers reuse ElementData without leaking new nodes")
	detached_manager.free()
	cm.init_new_campaign({"player_name": "Previous", "player_element": "fire"})
	cm.tournament_schedule[0]["completed"] = true
	cm.tournament_schedule[0]["result"] = "VICTORY"
	cm.scouting_intel["air"]["matches_fought"] = 4
	cm.known_fighters = [{"name": "Old Rival"}]
	cm.appearance["hair_color"] = "violet"
	cm.prepare_match("street", "earth", "Old Rival", "Old Team")
	cm.init_new_campaign({"player_name": "Fresh", "player_element": "earth"})
	check(cm.get_next_scheduled_match().get("round") == 1, "New campaign starts at the first tournament round")
	check(cm.tournament_schedule[0]["result"] == "", "New campaign clears previous match results")
	check(cm.known_fighters.is_empty(), "New campaign clears encounter history")
	check(cm.scouting_intel["air"]["matches_fought"] == 0, "New campaign clears scouting records")
	check(cm.scouting_intel["water"]["matches_fought"] == 0, "New campaign has no invented water win")
	check(cm.appearance["hair_color"] == "crimson", "New campaign resets unspecified appearance")
	check(cm.active_match_type == "tournament", "New campaign clears the previous match type")
	check(cm.get_ally("Fresh")["equipped_skills"] == cm.equipped_abilities, "Roster and player share the same starter skill")

	cm.init_new_campaign({"player_name": "Saved", "player_element": "fire"})
	cm.save_campaign()
	check(cm.unlock_skill_node("Laser"), "A valid skill purchase succeeds")
	cm.load_campaign()
	check(cm.unlocked_abilities.has("Laser") and cm.unspent_skill_points == 1, "Skill purchase and deducted SP survive immediate reload")
	check(cm.get_unlocked_forms_for_skill("Laser") == ["needle"], "Purchased skill's first form survives reload")
	check(not cm.set_active_skill_form("Laser", "flash_flare"), "Cannot select a locked form")
	var old_roster = cm.allies.duplicate(true)
	check(not cm.set_teammate_active_skills("Missing Teammate", ["Laser"]), "Unknown teammate is rejected")
	check(cm.allies == old_roster, "Unknown teammate does not overwrite someone else's skills")

	# Save validation must finish before any in-memory state changes.
	var valid_save = read_save()
	var malformed = valid_save.duplicate(true)
	malformed["player_name"] = "Should Never Load"
	malformed["allies"] = [null]
	write_save(malformed)
	var load_result = cm.load_campaign()
	check(load_result == false, "Malformed nested save data is rejected")
	check(cm.player_name == "Saved", "Rejected save leaves the active campaign intact")
	for bad_fields in [
		{"appearance": {"sheet_prefix": []}},
		{"starting_formation": {"Saved": [null, {}]}},
		{"starting_formation": {"Saved": {"x": "bad", "y": 4}}},
		{"scouting_intel": {"fire": {"matches_fought": 0, "wins_against": 0, "losses_against": 0}}},
		{"unlocked_skill_forms": {"Laser": "needle"}},
		{"player_element": "void"},
		{"player_level": "one"}
	]:
		malformed = valid_save.duplicate(true)
		malformed.merge(bad_fields, true)
		malformed["player_name"] = "Should Never Load"
		write_save(malformed)
		check(not cm.load_campaign() and cm.player_name == "Saved", "Reject invalid %s before mutating campaign" % str(bad_fields.keys()))

	# Removed or invented forms cannot become active, even in an old save.
	var obsolete_forms = valid_save.duplicate(true)
	obsolete_forms["unlocked_skill_forms"]["Laser"] = ["removed_form", "removed_form"]
	obsolete_forms["skill_variations"]["Laser"] = "removed_form"
	write_save(obsolete_forms)
	check(cm.load_campaign() and cm.get_unlocked_forms_for_skill("Laser") == ["needle"], "Obsolete forms migrate to the skill's first valid form")
	check(cm.skill_variations["Laser"] == "needle", "Obsolete active form is repaired on load")
	cm.unlocked_skill_forms["Metal"] = ["forged_fist"]
	check(not cm.set_active_skill_form("Metal", "forged_fist"), "A locked skill cannot select a stale saved form")

	# Old saves can omit newer fields and contain stale derived fatigue flags.
	var legacy = valid_save.duplicate(true)
	legacy.erase("has_team")
	legacy.erase("league_tier")
	legacy["energy"] = 10
	legacy["is_fatigued"] = false
	legacy["bench_risk"] = false
	legacy["player_xp_to_next"] = 0
	write_save(legacy)
	check(cm.load_campaign(), "Legacy save loads with missing optional fields")
	check(cm.has_team, "Legacy team roster remains a team")
	check(cm.is_fatigued and cm.bench_risk, "Fatigue is recalculated from saved energy")
	check(cm.player_xp_to_next > 0, "Invalid XP threshold cannot create an infinite level-up loop")

	# A valid save writes over an existing file and preserves formation vectors.
	cm.starting_formation = {"Saved": Vector2i(2, 4)}
	check(cm.save_campaign(), "Save replacement succeeds")
	cm.starting_formation.clear()
	check(cm.load_campaign() and cm.starting_formation["Saved"] == Vector2i(2, 4), "Formation coordinates round-trip through JSON")
	check(not FileAccess.file_exists("user://campaign_save.json.tmp"), "Successful save leaves no pending temporary file")
	var previous_file = FileAccess.get_file_as_string("user://campaign_save.json")
	DirAccess.make_dir_absolute("user://campaign_save.json.tmp")
	cm.player_name = "Unsaved Change"
	check(not cm.save_campaign(), "A failed temporary write reports save failure")
	check(FileAccess.get_file_as_string("user://campaign_save.json") == previous_file, "A failed write preserves the previous complete save")
	DirAccess.remove_absolute("user://campaign_save.json.tmp")

	# Every element needs a defensive option and a way to win its first solo fight.
	var expected_loadouts = {
		"fire": ["Thermal_Radiation", "Combustion"],
		"water": ["Aqua_Mend", "Ice"],
		"earth": ["Stone_Plating", "Metal"],
		"air": ["Gale_Step", "Wind"]
	}
	var element_data = root.get_node("ElementData")
	for element in expected_loadouts:
		cm.init_new_campaign({"player_name": "Starter", "player_element": element, "start_solo": true})
		var expected = expected_loadouts[element]
		check(cm.equipped_abilities == expected and cm.unlocked_abilities == expected,
			"%s begins solo with support and attack equipped" % element)
		for index in range(2):
			var ability_key = expected[index]
			var form_key = element_data.get_skill_form_keys(ability_key)[0]
			var form = element_data.get_skill_form_info(ability_key, form_key)
			var ability = element_data.ABILITIES[ability_key]
			var effective_damage = float(ability["damage"]) * float(form.get("dmg_mult", 1.0))
			var effective_effect = form.get("effect", ability.get("effect", ""))
			check(cm.get_unlocked_forms_for_skill(ability_key) == [form_key] and cm.skill_variations[ability_key] == form_key,
				"%s %s starter form is usable" % [element, ability_key])
			var is_support = effective_damage <= 0.0 or effective_effect in ["dodge_buff", "evasion", "defense_buff", "armor_buff", "guard", "heal", "cleanse", "anchor"]
			var correct_role = is_support if index == 0 else not is_support
			check(correct_role, "%s %s starts as %s" % [element, ability_key, "support" if index == 0 else "attack"])
		check(cm.save_campaign(), "%s solo loadout saves" % element)
		cm.equipped_abilities.clear()
		check(cm.load_campaign() and cm.equipped_abilities == expected,
			"%s solo loadout reloads" % element)
		var world = load("res://scenes/World.tscn").instantiate()
		root.add_child(world)
		await process_frame
		check(world.get_node("Player").equipped_abilities == expected,
			"%s solo loadout reaches combat" % element)
		world.queue_free()
		await process_frame
		var older_save = read_save()
		var original_skill = expected[1] if element == "fire" else expected[0]
		var missing_skill = expected[0] if element == "fire" else expected[1]
		older_save["equipped_abilities"] = [original_skill]
		older_save["unlocked_abilities"] = [original_skill]
		older_save["unlocked_skill_forms"].erase(missing_skill)
		older_save["skill_variations"].erase(missing_skill)
		for fighter in older_save["allies"]:
			if fighter["name"] == "Starter":
				fighter["equipped_skills"] = [original_skill]
				fighter["known_skills"] = [original_skill]
		write_save(older_save)
		check(cm.load_campaign() and cm.equipped_abilities.has(missing_skill) and cm.unlocked_abilities.has(missing_skill),
			"%s old one-skill save gains its missing starter" % element)
		check(cm.get_unlocked_forms_for_skill(missing_skill).size() == 1,
			"%s migrated starter form is usable" % element)
	cm.init_new_campaign({"player_name": "Captain", "player_element": "fire"})
	check(cm.save_campaign(), "Team campaign saves for legacy roster migration")
	var old_team_save = read_save()
	old_team_save["equipped_abilities"] = ["Combustion"]
	old_team_save["unlocked_abilities"] = ["Combustion"]
	for fighter in old_team_save["allies"]:
		if fighter["name"] == "Captain":
			fighter["equipped_skills"] = ["Combustion"]
			fighter["known_skills"] = ["Combustion"]
	write_save(old_team_save)
	check(cm.load_campaign() and cm.get_ally("Captain")["known_skills"].has("Thermal_Radiation")
		and cm.get_ally("Captain")["equipped_skills"] == cm.equipped_abilities,
		"Legacy captain roster displays the new starter loadout")
	print("CAMPAIGN REGRESSIONS: %d passed, %d failed" % [passed, failed])
	quit(0 if failed == 0 else 1)
