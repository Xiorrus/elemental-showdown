# capture_master.gd
# Unified 1920x1080 visual QA capture tool for Elemental Showdown.
# Renders pixel-perfect captures for each of the 10 canonical screens.
extends SceneTree

const CaptureOutput = preload("res://scripts/capture_output.gd")
var capture_failed := false

const SCREEN_MAIN_MENU            = "capture_main_menu.png"
const SCREEN_SETTINGS_MODAL       = "capture_settings_modal.png"
const SCREEN_CHAR_CUSTOM          = "capture_char_custom.png"
const SCREEN_HUB_SCHEDULE         = "capture_hub_schedule.png"
const SCREEN_HUB_SCHEDULE_TEAM    = "capture_hub_schedule_team.png"
const SCREEN_HUB_ROSTER           = "capture_hub_roster.png"
const SCREEN_HUB_ROSTER_TRAINING  = "capture_hub_roster_training.png"
const SCREEN_HUB_DEPLOYMENT       = "capture_hub_deployment.png"
const SCREEN_HUB_INTEL            = "capture_hub_intel.png"
const SCREEN_HUB_INTEL_ROSTER     = "capture_hub_intel_roster.png"
const SCREEN_HUB_CULTIVATION      = "capture_hub_cultivation.png"
const SCREEN_HUB_CULTIVATION_TECH = "capture_hub_cultivation_techniques.png"
const SCREEN_HUB_CULTIVATION_TREE = "capture_hub_cultivation_tree.png"
const SCREEN_HUB_CULTIVATION_TREE_FOCUSED_CORE  = "capture_hub_cultivation_tree_focused_core.png"
const SCREEN_HUB_CULTIVATION_TREE_FOCUSED_SPACE = "capture_hub_cultivation_tree_focused_space.png"
const SCREEN_HUB_CULTIVATION_TREE_INSPECTOR     = "capture_hub_cultivation_tree_inspector.png"
const SCREEN_COMBAT_HUD           = "capture_combat_1v1_hud.png"
const SCREEN_COMBAT_VICTORY       = "capture_combat_victory.png"

func _init():
	_run.call_deferred()

func _run():
	if not CaptureOutput.prepare():
		quit(1)
		return
	print("[CaptureMaster] Initializing 1920x1080 visual QA capture sequence...")

	# Parse target filter if specified
	var target_screen = ""
	var args = OS.get_cmdline_user_args()
	for a in args:
		if a.begins_with("--screen="):
			target_screen = a.substr(9).strip_edges().to_lower()
	var valid_targets = [
		"main_menu", "settings", "customization", "char_custom", "hub",
		"schedule", "hub_schedule", "roster", "hub_roster", "deployment", "hub_deployment",
		"intel", "hub_intel", "cultivation", "hub_cultivation",
		"combat", "hud", "victory", "combat_hud", "combat_victory"
	]
	if target_screen != "" and not valid_targets.has(target_screen):
		printerr("[CaptureMaster] Unknown screen: ", target_screen)
		quit(2)
		return

	# Set up mock campaign data
	var cm = root.get_node_or_null("CampaignManager")
	if cm:
		cm.init_new_campaign({"player_name": "Valen", "player_element": "earth", "start_solo": true})
		cm.player_level = 1
		cm.player_xp = 0
		cm.player_xp_to_next = 100
		cm.unspent_stat_points = 5
		cm.unspent_skill_points = 2
		cm.energy = 100
		cm.total_wins = 0
		cm.total_losses = 0
		cm.win_streak = 0
		cm.gold = 150
		cm.shards = 0
		cm.campaign_day = 1
		cm.equipped_abilities = ["Metal"]
		cm.unlocked_abilities = ["Metal"]
		cm.starting_formation = {"Valen": Vector2i(3, 4)}

	# ── 1. Main Menu & Settings ───────────────────────────────────────────────
	if target_screen == "" or target_screen == "main_menu" or target_screen == "settings":
		var menu_scn = load("res://scenes/MainMenu.tscn").instantiate()
		root.add_child(menu_scn)
		for i in range(6): await process_frame

		if target_screen == "" or target_screen == "main_menu":
			_capture(SCREEN_MAIN_MENU)

		if target_screen == "" or target_screen == "settings":
			if menu_scn.has_method("_on_open_settings"):
				menu_scn._on_open_settings()
			elif menu_scn.has_node("SettingsModal"):
				menu_scn.get_node("SettingsModal").visible = true
			for i in range(6): await process_frame
			_capture(SCREEN_SETTINGS_MODAL)

		menu_scn.queue_free()
		await process_frame

	# ── 2. Character Customization ────────────────────────────────────────────
	if target_screen == "" or target_screen == "customization" or target_screen == "char_custom":
		var custom_scn = load("res://scenes/CharacterCustomization.tscn").instantiate()
		root.add_child(custom_scn)
		for i in range(8): await process_frame
		_capture(SCREEN_CHAR_CUSTOM)
		custom_scn.queue_free()
		await process_frame

	# ── 3. Campaign Hub Tabs ──────────────────────────────────────────────────
	if target_screen == "" or target_screen.begins_with("hub") or target_screen in ["schedule", "roster", "deployment", "intel", "cultivation"]:
		var hub_scn = load("res://scenes/CampaignHub.tscn").instantiate()
		root.add_child(hub_scn)
		for i in range(6): await process_frame

		# Tab 0: Schedule / Tournament
		if target_screen == "" or target_screen in ["hub", "schedule", "hub_schedule"]:
			hub_scn._switch_tab(0)
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_SCHEDULE)

			# Also capture 5-card team lineup
			if cm:
				var prev_has_team = cm.has_team
				var prev_team_name = cm.team_name
				var prev_allies = cm.allies.duplicate(true)
				cm.has_team = true
				cm.team_name = "Phoenix Strikers"
				cm.allies = [
					{"name": "Valen", "element": "earth", "role": "Captain", "archetype": "Striker", "level": 1, "hp": 90, "speed": 4, "potency": 30, "equipped_skills": ["Metal"]},
					{"name": "Ignis", "element": "fire", "role": "Attacker", "archetype": "Striker", "level": 1, "hp": 80, "speed": 4, "potency": 35, "equipped_skills": ["Fireball"]},
					{"name": "Kora", "element": "water", "role": "Support", "archetype": "Controller", "level": 1, "hp": 75, "speed": 3, "potency": 25, "equipped_skills": ["Healing Rain"]},
				]
				hub_scn._refresh_all()
				for i in range(6): await process_frame
				_capture(SCREEN_HUB_SCHEDULE_TEAM)
				cm.has_team = prev_has_team
				cm.team_name = prev_team_name
				cm.allies = prev_allies
				hub_scn._refresh_all()
				for i in range(6): await process_frame

		# Tab 1: Dojo & Roster
		if target_screen == "" or target_screen in ["hub", "roster", "hub_roster"]:
			hub_scn._switch_tab(1)
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_ROSTER)

			# Also capture Training subtab
			hub_scn._roster_subtab = 2
			hub_scn._refresh_team_tab()
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_ROSTER_TRAINING)
			hub_scn._roster_subtab = 0
			hub_scn._refresh_team_tab()

		# Tab 2: Deployment Workbench
		if target_screen == "" or target_screen in ["hub", "deployment", "hub_deployment"]:
			hub_scn._switch_tab(2)
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_DEPLOYMENT)

		# Tab 3: Scouting Intel
		if target_screen == "" or target_screen in ["hub", "intel", "hub_intel"]:
			hub_scn._switch_tab(3)
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_INTEL)

			# Also capture Full Roster view
			hub_scn._intel_view_roster = true
			hub_scn._refresh_intel_tab()
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_INTEL_ROSTER)
			hub_scn._intel_view_roster = false
			hub_scn._refresh_intel_tab()

		# Tab 4: Cultivation & Skills
		if target_screen == "" or target_screen in ["hub", "cultivation", "hub_cultivation"]:
			hub_scn._switch_tab(4)
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_CULTIVATION)

			# Also capture Techniques subpage
			hub_scn._cultivation_subpage = 1
			hub_scn._refresh_skills_tab()
			for i in range(6): await process_frame
			_capture(SCREEN_HUB_CULTIVATION_TECH)

			# Also capture Discipline Skill Tree subpage
			hub_scn._cultivation_subpage = 2
			hub_scn._refresh_skills_tab()
			for i in range(10): await process_frame
			_capture(SCREEN_HUB_CULTIVATION_TREE)

			# Focus Core Fire discipline
			if hub_scn.skill_tree_canvas:
				hub_scn.skill_tree_canvas.focus_discipline("fire")
				hub_scn.skill_tree_canvas.transition_progress = 1.0
				hub_scn.skill_tree_canvas._update_positions_and_redraw()
				for i in range(12): await process_frame
				_capture(SCREEN_HUB_CULTIVATION_TREE_FOCUSED_CORE)

				# Inspect skill with form variations
				hub_scn.skill_tree_canvas.inspect_skill("Combustion")
				for i in range(10): await process_frame
				_capture(SCREEN_HUB_CULTIVATION_TREE_INSPECTOR)

				# Focus Primordial Space/Time
				hub_scn.skill_tree_canvas.focus_discipline("space")
				hub_scn.skill_tree_canvas.transition_progress = 1.0
				hub_scn.skill_tree_canvas._update_positions_and_redraw()
				for i in range(12): await process_frame
				_capture(SCREEN_HUB_CULTIVATION_TREE_FOCUSED_SPACE)

				# Collapse back
				hub_scn.skill_tree_canvas.collapse_to_mandala()
				hub_scn.skill_tree_canvas.transition_progress = 0.0
				hub_scn.skill_tree_canvas._update_positions_and_redraw()
				for i in range(10): await process_frame

			hub_scn._cultivation_subpage = 0
			hub_scn._refresh_skills_tab()

		hub_scn.queue_free()
		await process_frame

	# ── 4. Combat HUD & Victory Ceremony ──────────────────────────────────────
	if target_screen == "" or target_screen in ["combat", "hud", "victory", "combat_hud", "combat_victory"]:
		if cm:
			cm.active_match_format = "1v1"
			cm.active_match_type = "street"
			cm.active_enemy_name = "Zero (The Rival)"
			cm.active_enemy_element = "zero"

		var world_scn = load("res://scenes/World.tscn").instantiate()
		root.add_child(world_scn)
		for i in range(8): await process_frame

		var ui_node = world_scn.get_node_or_null("UI")

		# In-combat HUD
		if target_screen == "" or target_screen in ["combat", "hud", "combat_hud"]:
			_capture(SCREEN_COMBAT_HUD)

		# Victory modal
		if target_screen == "" or target_screen in ["combat", "victory", "combat_victory"]:
			if ui_node:
				ui_node.show_battle_result(true, 75, 5)
				for i in range(6): await process_frame
				_capture(SCREEN_COMBAT_VICTORY)

		world_scn.queue_free()
		await process_frame

	print("[CaptureMaster] All requested captures complete.")
	quit(1 if capture_failed else 0)

func _capture(file_name: String):
	if not CaptureOutput.save(root, file_name):
		capture_failed = true
