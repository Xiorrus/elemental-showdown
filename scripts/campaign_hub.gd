# campaign_hub.gd
# Pixel-faithful implementation of the Google Stitch prototype layout (media_1789304951399.png).
# Features tactical corner brackets, exact color palettes, and single-screen vertical proportions.
extends Control

const CareerCalendarPopupScript = preload("res://scripts/career_calendar_popup.gd")
const ScoutingCatalogScript = preload("res://scripts/scouting_catalog.gd")

# Top Header Bar
@onready var lbl_engine = $HeaderBar/LblEngine
@onready var lbl_district = $HeaderBar/PillDistrict/HBox/LblDistrict
@onready var lbl_ident = $HeaderBar/LblIdent
@onready var xp_bar = $HeaderBar/XPBox/XpBar
@onready var lbl_xp_val = $HeaderBar/XPBox/LblXPVal if has_node("HeaderBar/XPBox/LblXPVal") else get_node_or_null("HeaderBar/XPBox/LblXpVal")
@onready var lbl_gold = $HeaderBar/PillGold/HBox/LblGold
@onready var lbl_shards = $HeaderBar/PillShards/HBox/LblShards
@onready var lbl_stamina = $HeaderBar/PillStamina/HBox/LblStamina
@onready var btn_save_disk = $HeaderBar/BtnSaveDisk
@onready var btn_profile_icon = $HeaderBar/BtnProfileIcon

# Main Tabs Container
@onready var main_tabs = $MainTabs
@onready var tab_schedule = $MainTabs/TabSchedule
@onready var tab_team = $MainTabs/TabTeam
@onready var tab_battle = $MainTabs/TabBattle
@onready var tab_intel = $MainTabs/TabIntel
@onready var tab_skills = $MainTabs/TabSkills
@onready var tab_activities = $MainTabs/TabActivities

# Hub Elements
@onready var promotion_gauge = $MainTabs/TabSchedule/LeagueCampaignCard/PromotionHBox/PromotionGauge
@onready var lbl_promotion_val = $MainTabs/TabSchedule/LeagueCampaignCard/PromotionHBox/LblPromotionVal
@onready var badge_cp = $MainTabs/TabSchedule/LeagueCampaignCard/HBoxObj/BadgeCP
@onready var badge_streak = $MainTabs/TabSchedule/LeagueCampaignCard/HBoxObj/BadgeStreak
@onready var btn_swap_lineup = $MainTabs/TabSchedule/TrioHeader/BtnSwapLineup
@onready var btn_gear_runes = $MainTabs/TabSchedule/TrioHeader/BtnGearRunes
@onready var btn_skill_codex = $MainTabs/TabSchedule/TrioHeader/BtnSkillCodex

# Card 1 Nodes
@onready var card1_name = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/MidRow/VBInfo/Name
@onready var card1_role = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/MidRow/VBInfo/Role
@onready var card1_sprite = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/MidRow/AvatarFrame/Sprite
@onready var card1_hp = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/StatsGrid/ColHp/V
@onready var card1_move = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/StatsGrid/ColMove/V
@onready var card1_atk = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/StatsGrid/ColAtk/V
@onready var card1_banner = $MainTabs/TabSchedule/TrioCardsHBox/Card1/Margin/VB/Banner/Lbl

# Card 2 Nodes
@onready var card2_name = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/MidRow/VBInfo/Name
@onready var card2_role = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/MidRow/VBInfo/Role
@onready var card2_sprite = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/MidRow/AvatarFrame/Sprite
@onready var card2_hp = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/StatsGrid/ColHp/V
@onready var card2_move = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/StatsGrid/ColMove/V
@onready var card2_atk = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/StatsGrid/ColAtk/V
@onready var card2_banner = $MainTabs/TabSchedule/TrioCardsHBox/Card2/Margin/VB/Banner/Lbl

# Card 3 Nodes
@onready var card3_name = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/MidRow/VBInfo/Name
@onready var card3_role = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/MidRow/VBInfo/Role
@onready var card3_sprite = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/MidRow/AvatarFrame/Sprite
@onready var card3_hp = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/StatsGrid/ColHp/V
@onready var card3_move = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/StatsGrid/ColMove/V
@onready var card3_atk = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/StatsGrid/ColAtk/V
@onready var card3_banner = $MainTabs/TabSchedule/TrioCardsHBox/Card3/Margin/VB/Banner/Lbl

# Next Clash Card
@onready var lbl_next_match_tag = $MainTabs/TabSchedule/NextMatchCard/VBInfo/Tag
@onready var lbl_next_opp_name = $MainTabs/TabSchedule/NextMatchCard/VBInfo/OppName
@onready var lbl_next_xp_reward = $MainTabs/TabSchedule/NextMatchCard/VBInfo/PillsRow/PillExp/L
@onready var lbl_next_gold_reward = $MainTabs/TabSchedule/NextMatchCard/VBInfo/PillsRow/PillG/L
@onready var lbl_next_opp_details = $MainTabs/TabSchedule/NextMatchCard/VBInfo/PillsRow/OppDetails
@onready var lbl_next_opp_counter = $MainTabs/TabSchedule/NextMatchCard/VBInfo/TacticalAdv/MatchupCounter
@onready var btn_enter_match = $MainTabs/TabSchedule/NextMatchCard/BtnEnterMatch

# Timeline
@onready var timeline_days = [
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day1,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day2,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day3,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day4,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day5,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day6,
	$MainTabs/TabSchedule/TimelineSection/TimelineHBox/Day7
]
@onready var btn_open_calendar = $MainTabs/TabSchedule/TimelineSection/CalendarOpenButton

# Bottom Dock
@onready var dock_buttons = [
	$BottomDock/BtnDock0,
	$BottomDock/BtnDock1,
	$BottomDock/BtnDock2,
	$BottomDock/BtnDock3,
	$BottomDock/BtnDock4
]

# Battle Tab
@onready var btn_launch_arena = $MainTabs/TabBattle/VB/HBoxMain/IntelPanel/VB/BtnLaunchArena

# Player Tab
@onready var lbl_player_stats = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelStats/Margin/VB/LblStats
@onready var btn_save = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelActions/Margin/VB/BtnSave
@onready var btn_dev = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelActions/Margin/VB/BtnDevUnlock
@onready var btn_menu = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelActions/Margin/VB/BtnMainMenu
@onready var save_feedback = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelActions/Margin/VB/SaveFeedback
@onready var equipped_skills_box = $MainTabs/TabSkills/HBox/EquippedCol/VBox
@onready var unlocked_skills_box = $MainTabs/TabSkills/HBox/LibraryCol/Scroll/VBox
@onready var btn_item_draught = $MainTabs/TabSkills/HBox/LibraryCol/ConsumablesBox/BtnDraught
@onready var btn_item_elixir = $MainTabs/TabSkills/HBox/LibraryCol/ConsumablesBox/BtnElixir

# Test Compatibility Nodes
@onready var btn_act_train = $MainTabs/TabActivities/Grid/CardTrain/VBox/BtnTrain
@onready var btn_act_street = $MainTabs/TabActivities/Grid/CardStreet/VBox/BtnStreet
@onready var btn_act_rest = $MainTabs/TabActivities/Grid/CardRest/VBox/BtnRest
@onready var lbl_act_log = $MainTabs/TabActivities/ActivityLogCard/ActivityLog

var cm: Node = null
var edata: Node = null
var active_nav_index: int = 0
var cinzel_font: Font = null
var _pending_deployment_match: Dictionary = {}
var _portrait_textures: Dictionary = {}

func _get_element_data() -> Node:
	if edata == null:
		edata = get_node_or_null("/root/ElementData")
	return edata

func _ready():
	cm = get_node_or_null("/root/CampaignManager")
	edata = get_node_or_null("/root/ElementData")

	if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		cinzel_font = load("res://assets/fonts/Cinzel-Bold.ttf")

	if cm and not cm.has_active_campaign:
		cm.init_new_campaign({"player_name": "VALEN", "player_element": "earth", "start_solo": true})

	# Wire Dock Buttons
	for i in range(dock_buttons.size()):
		var btn = dock_buttons[i]
		btn.pressed.connect(func(): _switch_tab(i))

	# Quick link headers
	btn_swap_lineup.pressed.connect(func(): _switch_tab(1)) # Roster
	btn_gear_runes.pressed.connect(func(): _switch_tab(4)) # Player
	btn_skill_codex.pressed.connect(func(): _switch_tab(4)) # Player

	# Header top action buttons
	btn_save_disk.pressed.connect(_on_save_pressed)
	btn_profile_icon.pressed.connect(func(): _switch_tab(4))

	# Style Header Buttons
	_style_secondary_slate_button(btn_save_disk, 10)
	_style_secondary_slate_button(btn_profile_icon, 10)
	_style_secondary_slate_button(btn_swap_lineup, 10)
	_style_secondary_slate_button(btn_gear_runes, 10)
	_style_secondary_slate_button(btn_skill_codex, 10)
	if cinzel_font:
		btn_swap_lineup.add_theme_font_override("font", cinzel_font)
		btn_gear_runes.add_theme_font_override("font", cinzel_font)
		btn_skill_codex.add_theme_font_override("font", cinzel_font)

	# Battle Launching
	btn_enter_match.pressed.connect(_on_enter_tournament_match)
	btn_launch_arena.pressed.connect(_on_launch_battle_arena_direct)

	# Activities
	btn_act_train.pressed.connect(_on_activity_train)
	btn_act_street.pressed.connect(_on_activity_street)
	btn_act_rest.pressed.connect(_on_activity_rest)
	btn_open_calendar.pressed.connect(_open_calendar)
	if cinzel_font:
		btn_act_street.add_theme_font_override("font", cinzel_font)

	# Player Tab Actions
	btn_save.pressed.connect(_on_save_pressed)
	btn_dev.pressed.connect(_on_dev_unlock_pressed)
	btn_menu.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	_style_secondary_slate_button(btn_save, 11)
	_style_secondary_slate_button(btn_menu, 11)
	if cinzel_font:
		btn_save.add_theme_font_override("font", cinzel_font)
		btn_menu.add_theme_font_override("font", cinzel_font)
	_style_tactical_button(btn_dev, Color(0.06, 0.08, 0.12, 0.7), Color(0.22, 0.28, 0.38, 0.4), Color(0.5, 0.55, 0.65), 9, false)

	# Consumables
	# Consumables have no inventory yet; do not grant unlimited free resources.
	btn_item_draught.disabled = true
	btn_item_elixir.disabled = true

	# Refresh Timeline dynamically based on campaign day
	_refresh_timeline()

	# Style Enter Battle Button with radiant glow
	_style_enter_battle_button()

	_switch_tab(0)
	_refresh_all()

func _unhandled_input(event: InputEvent):
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	elif event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_S:
			_on_save_pressed()
		elif event.keycode >= KEY_1 and event.keycode <= KEY_5:
			var idx = event.keycode - KEY_1
			if idx < dock_buttons.size():
				_switch_tab(idx)

func _get_element_color(elem: String) -> Color:
	match elem.to_lower():
		"fire": return Color(0.95, 0.32, 0.22)
		"water": return Color(0.18, 0.65, 0.95)
		"earth": return Color(0.85, 0.65, 0.20)
		"air": return Color(0.20, 0.78, 0.65)
		_: return Color(0.75, 0.82, 0.92)

func _make_portrait(element: String) -> TextureRect:
	# Container-managed portraits stay inside their frame when the UI resizes.
	var portrait = TextureRect.new()
	portrait.name = "Portrait"
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if not _portrait_textures.has(element):
		var path = "res://assets/%s_walk.png" % element.to_lower()
		if ResourceLoader.exists(path):
			var sheet: Texture2D = load(path)
			var frame_size = Vector2i(sheet.get_width() / 4, sheet.get_height() / 4)
			var frame = sheet.get_image().get_region(Rect2i(Vector2i.ZERO, frame_size))
			var atlas = AtlasTexture.new()
			atlas.atlas = sheet
			atlas.region = Rect2(frame.get_used_rect().grow(4).intersection(Rect2i(Vector2i.ZERO, frame_size)))
			_portrait_textures[element] = atlas
	portrait.texture = _portrait_textures.get(element)
	return portrait

func _player_max_hp() -> int:
	var element = edata.ELEMENTS.get(cm.player_element, {}) if edata else {}
	return int(element.get("base_hp", 100)) + (cm.player_level - 1) * 10

func _player_featured_skill_label() -> String:
	var labels := PackedStringArray()
	for skill in cm.equipped_abilities:
		labels.append(str(skill).capitalize().replace("_", " "))
		if labels.size() == 2:
			break
	return " • ".join(labels) if not labels.is_empty() else "Strike"

func _style_tactical_button(btn: Button, normal_bg: Color, border_c: Color, font_c: Color, font_size: int = 11, glow: bool = false):
	if not btn: return
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", font_c)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", font_c)
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.45, 0.55))
	btn.focus_mode = Control.FOCUS_NONE

	var sb_n = StyleBoxFlat.new()
	sb_n.set_corner_radius_all(4)
	sb_n.bg_color = normal_bg
	sb_n.border_width_left = 1
	sb_n.border_width_top = 1
	sb_n.border_width_right = 1
	sb_n.border_width_bottom = 1
	sb_n.border_color = border_c
	sb_n.content_margin_left = 8
	sb_n.content_margin_right = 8
	sb_n.content_margin_top = 4
	sb_n.content_margin_bottom = 4

	if glow:
		sb_n.shadow_color = Color(border_c.r, border_c.g, border_c.b, 0.35)
		sb_n.shadow_size = 6

	var sb_h = sb_n.duplicate()
	sb_h.bg_color = normal_bg.lightened(0.12)
	sb_h.border_color = border_c.lightened(0.25)
	if glow:
		sb_h.shadow_size = 10

	var sb_p = sb_n.duplicate()
	sb_p.bg_color = normal_bg.darkened(0.1)

	btn.add_theme_stylebox_override("normal", sb_n)
	btn.add_theme_stylebox_override("hover", sb_h)
	btn.add_theme_stylebox_override("pressed", sb_p)
	btn.add_theme_stylebox_override("focus", sb_h)

func _style_primary_gold_button(btn: Button, font_size: int = 14):
	if not btn: return
	if cinzel_font:
		btn.add_theme_font_override("font", cinzel_font)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", UITheme.TEXT_DARK)
	btn.add_theme_color_override("font_hover_color", Color(0.02, 0.04, 0.06))
	btn.add_theme_color_override("font_pressed_color", Color(0.02, 0.04, 0.06))
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", UITheme.make_btn_primary(false, false))
	btn.add_theme_stylebox_override("hover", UITheme.make_btn_primary(true, false))
	btn.add_theme_stylebox_override("pressed", UITheme.make_btn_primary(false, true))
	btn.add_theme_stylebox_override("focus", UITheme.make_btn_primary(true, false))

func _style_secondary_slate_button(btn: Button, font_size: int = 11):
	if not btn: return
	btn.add_theme_font_size_override("font_size", font_size)
	btn.add_theme_color_override("font_color", UITheme.TEXT_PRIMARY)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	btn.add_theme_color_override("font_pressed_color", UITheme.TEXT_PRIMARY)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", UITheme.make_btn_secondary(false, false))
	btn.add_theme_stylebox_override("hover", UITheme.make_btn_secondary(true, false))
	btn.add_theme_stylebox_override("pressed", UITheme.make_btn_secondary(false, true))
	btn.add_theme_stylebox_override("focus", UITheme.make_btn_secondary(true, false))

func _get_season_summary() -> Dictionary:
	if cm and cm.has_method("get_season_summary"):
		var summary = cm.get_season_summary()
		if summary is Dictionary:
			return summary
	return {}

func _season_standings(summary: Dictionary) -> Array:
	var rows = summary.get("standings", [])
	if not (rows is Array):
		return []
	var result: Array = []
	for row in rows:
		if row is Dictionary:
			result.append(row)
	result.sort_custom(func(a, b):
		if int(a.get("points", 0)) != int(b.get("points", 0)):
			return int(a.get("points", 0)) > int(b.get("points", 0))
		if int(a.get("score_difference", 0)) != int(b.get("score_difference", 0)):
			return int(a.get("score_difference", 0)) > int(b.get("score_difference", 0))
		return str(a.get("team", "")) < str(b.get("team", ""))
	)
	return result

func _player_standing(summary: Dictionary) -> Dictionary:
	var rows = _season_standings(summary)
	for i in range(rows.size()):
		if str(rows[i].get("team", "")).to_lower() == cm.team_name.to_lower():
			var standing = rows[i].duplicate()
			standing["rank"] = i + 1
			standing["team_count"] = rows.size()
			return standing
	return {}

func _refresh_timeline():
	if not cm:
		return
	var summary = _get_season_summary()
	var club_season = cm.has_team and bool(summary.get("active", false))
	var current_slot = maxi(1, int(summary.get("week", 1))) if club_season else maxi(1, cm.campaign_day)
	var last_slot = 32 if club_season else current_slot + 3
	var first_slot = clampi(current_slot - 3, 1, maxi(1, last_slot - 6))
	var title = $MainTabs/TabSchedule/TimelineSection/Title
	if club_season:
		var season_number = maxi(1, int(summary.get("season_number", 1)))
		var month = clampi(int(summary.get("month", 1)), 1, 8)
		title.text = "◆ Season %d • Month %d/8 • Day %d/224 • Week %d/32" % [season_number, month, cm.get_season_day(), mini(current_slot, 32)]
		var national_window = summary.get("national_window", [])
		if national_window is Array and not national_window.is_empty():
			title.text += " • International window (future)"
	else:
		title.text = "◆ Street Circuit • Day %d" % current_slot
	btn_open_calendar.visible = club_season
	for i in range(timeline_days.size()):
		var day_node = timeline_days[i]
		if not day_node:
			continue
		var lbl = day_node.get_node_or_null("L")
		if not lbl:
			continue
		var slot = first_slot + i
		var prefix = "W" if club_season else "D"
		if slot < current_slot:
			lbl.text = "%s%d • Done" % [prefix, slot]
			lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.55, 0.9))
		elif slot == current_slot:
			lbl.text = "%s%d • Now" % [prefix, slot]
			lbl.add_theme_color_override("font_color", Color(0.04, 0.06, 0.08, 1.0))
		else:
			lbl.text = "%s%d" % [prefix, slot]
			lbl.add_theme_color_override("font_color", Color(0.55, 0.62, 0.72, 0.8))
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(4)
		sb.set_border_width_all(1)
		if slot < current_slot:
			sb.bg_color = Color(0.05, 0.08, 0.09, 0.85)
			sb.border_color = Color(0.18, 0.35, 0.28, 0.7)
		elif slot == current_slot:
			sb.bg_color = Color(0.85, 0.68, 0.22, 1.0)
			sb.border_color = Color(1.0, 0.88, 0.45, 0.9)
		else:
			sb.bg_color = Color(0.06, 0.08, 0.12, 0.90)
			sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
		day_node.add_theme_stylebox_override("panel", sb)

func _style_enter_battle_button():
	_style_primary_gold_button(btn_enter_match, 14)

func _switch_tab(index: int):
	if index != 2:
		_pending_deployment_match.clear()
	active_nav_index = index
	main_tabs.current_tab = index

	if index == 0:
		_refresh_all()
	elif index == 1:
		_refresh_team_tab()
	elif index == 2:
		_refresh_battle_tab()
		var tab_scroll = $MainTabs/TabBattle
		if tab_scroll is ScrollContainer:
			tab_scroll.scroll_horizontal = 0
			tab_scroll.scroll_vertical = 0
	elif index == 3:
		_refresh_intel_tab()
	elif index == 4:
		_refresh_skills_tab()

	for i in range(dock_buttons.size()):
		var btn = dock_buttons[i]
		if not btn: continue
		btn.focus_mode = Control.FOCUS_NONE
		if cinzel_font:
			btn.add_theme_font_override("font", cinzel_font)
		var is_active = (i == active_nav_index)

		if is_active:
			btn.add_theme_font_size_override("font_size", 12)
			btn.add_theme_color_override("font_color", Color(1.0, 0.95, 0.85))
			btn.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
			var sb_act = StyleBoxFlat.new()
			sb_act.bg_color = Color(0.12, 0.16, 0.24, 0.98)
			sb_act.border_width_bottom = 3
			sb_act.border_color = UITheme.GOLD_PRIMARY
			sb_act.set_corner_radius_all(4)
			sb_act.content_margin_top = 8
			sb_act.content_margin_bottom = 8
			sb_act.content_margin_left = 14
			sb_act.content_margin_right = 14
			sb_act.shadow_color = Color(UITheme.GOLD_PRIMARY.r, UITheme.GOLD_PRIMARY.g, UITheme.GOLD_PRIMARY.b, 0.25)
			sb_act.shadow_size = 4
			btn.add_theme_stylebox_override("normal", sb_act)
			btn.add_theme_stylebox_override("hover", sb_act)
			btn.add_theme_stylebox_override("pressed", sb_act)
			btn.add_theme_stylebox_override("focus", sb_act)
		else:
			btn.add_theme_font_size_override("font_size", 11)
			btn.add_theme_color_override("font_color", Color(0.55, 0.62, 0.74))
			btn.add_theme_color_override("font_hover_color", Color(0.85, 0.90, 0.98))
			var sb_inact = StyleBoxFlat.new()
			sb_inact.bg_color = Color(0.06, 0.08, 0.12, 0.85)
			sb_inact.border_width_left = 1
			sb_inact.border_width_top = 1
			sb_inact.border_width_right = 1
			sb_inact.border_width_bottom = 1
			sb_inact.border_color = Color(0.14, 0.18, 0.26, 0.5)
			sb_inact.set_corner_radius_all(4)
			sb_inact.content_margin_top = 8
			sb_inact.content_margin_bottom = 8
			sb_inact.content_margin_left = 14
			sb_inact.content_margin_right = 14
			btn.add_theme_stylebox_override("normal", sb_inact)
			var sb_hov = sb_inact.duplicate()
			sb_hov.bg_color = Color(0.09, 0.12, 0.18, 0.95)
			sb_hov.border_color = Color(0.25, 0.35, 0.50, 0.8)
			btn.add_theme_stylebox_override("hover", sb_hov)
			btn.add_theme_stylebox_override("pressed", sb_hov)
			btn.add_theme_stylebox_override("focus", sb_hov)

func _refresh_all():
	if not cm: return

	# 1. Header Information
	var p_name = cm.player_name
	var elem_cap = cm.player_element.capitalize()
	lbl_ident.text = "%s • Lv. %d %s Striker" % [p_name, cm.player_level, elem_cap]

	if xp_bar:
		xp_bar.max_value = cm.player_xp_to_next
		xp_bar.set_value(cm.player_xp)
	if lbl_xp_val:
		lbl_xp_val.text = "%d/%d" % [cm.player_xp, cm.player_xp_to_next]

	# Currencies - Real persisted state
	var g_val = cm.gold if "gold" in cm else 150
	var s_val = cm.shards if "shards" in cm else 0
	lbl_gold.text = "%s G" % _format_number(g_val)
	lbl_shards.text = _format_number(s_val)
	lbl_stamina.text = "Energy %d/100" % cm.energy

	# District pill
	if not cm.has_team:
		lbl_district.text = "Street Circuit • Free Agent (1v1)"
	else:
		lbl_district.text = "%s • %s" % [cm.current_league, cm.team_name]

	# 2. League Campaign Card
	var card_eyebrow = $MainTabs/TabSchedule/LeagueCampaignCard/HBoxTop/Eyebrow
	var card_title = $MainTabs/TabSchedule/LeagueCampaignCard/Title
	var card_obj = $MainTabs/TabSchedule/LeagueCampaignCard/HBoxObj/Objective
	var pill_gauge_lbl = $MainTabs/TabSchedule/LeagueCampaignCard/PromotionHBox/PillGauge/Lbl
	var season_summary = _get_season_summary()
	var club_season = cm.has_team and bool(season_summary.get("active", false))
	var offer_ready = not cm.has_team and cm.recruitment_offer_pending

	if not cm.has_team:
		if card_eyebrow: card_eyebrow.text = "Unsanctioned Street Duels"
		if card_title: card_title.text = "Club Offer Ready" if offer_ready else "Street Circuit — Underground Brawls"
		if card_obj:
			card_obj.text = "Scout offer earned • Accept below to begin your club career" if offer_ready else "Win 3 street duels to earn a club offer (%d/3 Wins)" % cm.street_wins
		if pill_gauge_lbl: pill_gauge_lbl.text = "◆ Team Scout Progress"
		var progress_pct = minf(100.0, (float(cm.street_wins) / 3.0) * 100.0)
		if promotion_gauge:
			promotion_gauge.set_value(progress_pct)
		lbl_promotion_val.text = "%d/3 Wins ◆" % mini(cm.street_wins, 3)
		badge_cp.text = "Fighter CP: %d" % cm.get_combat_power()
	elif club_season:
		var season_num = maxi(1, int(season_summary.get("season_number", 1)))
		var week = clampi(int(season_summary.get("week", 1)), 1, 32)
		var month = clampi(int(season_summary.get("month", 1)), 1, 8)
		var phase = str(season_summary.get("phase", "club_regular"))
		var phase_label = "Club League"
		if phase == "club_semifinal":
			phase_label = "League Championship • Semifinal"
		elif phase == "club_final":
			phase_label = "National Cup • Final" if cm.league_tier == 3 else "League Championship • Final"
		elif phase == "offseason":
			phase_label = "Offseason"
		if card_eyebrow: card_eyebrow.text = "%s • Month %d of 8" % [phase_label, month]
		if card_title: card_title.text = "%s • Season %d" % [cm.current_league, season_num]
		var upcoming = season_summary.get("next_match", {})
		var opponent = str(upcoming.get("enemy_team", "To be announced")) if upcoming is Dictionary else "To be announced"
		var fixture_week = clampi(int(upcoming.get("week", week)), 1, 32) if upcoming is Dictionary else week
		if card_obj:
			card_obj.text = "Season complete • Final standings are in" if phase == "offseason" else "Next: vs %s • Week %d/32" % [opponent, fixture_week]
		if pill_gauge_lbl: pill_gauge_lbl.text = "◆ Season Progress"
		if promotion_gauge:
			promotion_gauge.set_value(100.0 * float(week) / 32.0)
		lbl_promotion_val.text = "Month %d/8 • W%d/32" % [month, week]
		badge_cp.text = "Crew CP: %d" % cm.get_combat_power()
	else:
		if card_eyebrow: card_eyebrow.text = "League Tournament Schedule"
		if card_title: card_title.text = "%s — Round %d" % [cm.current_league, cm.league_round]
		var next_m_obj = cm.get_next_scheduled_match()
		var opp_team = next_m_obj.get("enemy_team", "Rivals") if not next_m_obj.is_empty() else "Finals Rival"
		if card_obj: card_obj.text = "Objective: Defeat %s in Round %d to advance to tournament finals" % [opp_team, cm.league_round]
		if pill_gauge_lbl: pill_gauge_lbl.text = "◆ League Promotion Gauge"
		var round_pct = min(100.0, (float(cm.total_wins) / 4.0) * 100.0)
		if promotion_gauge:
			promotion_gauge.set_value(round_pct)
		lbl_promotion_val.text = "%d/4 Rounds ◆" % cm.total_wins
		badge_cp.text = "Crew CP: %d" % cm.get_combat_power()

	if badge_streak:
		if club_season:
			var standing = _player_standing(season_summary)
			if not standing.is_empty() and int(standing.get("played", 0)) > 0:
				badge_streak.text = "#%d/%d • %d PTS" % [standing.get("rank", 0), standing.get("team_count", 0), standing.get("points", 0)]
			else:
				badge_streak.text = "Unranked • 0 PTS"
		else:
			badge_streak.text = "Streak: %dW" % cm.win_streak if cm.win_streak > 0 else "Streak: --"

	# 3. Lineup Cards on Hub Schedule Tab
	var trio_header_title = $MainTabs/TabSchedule/TrioHeader/Title
	var trio_cards_hbox = $MainTabs/TabSchedule/TrioCardsHBox
	var card1 = $MainTabs/TabSchedule/TrioCardsHBox/Card1
	var card2 = $MainTabs/TabSchedule/TrioCardsHBox/Card2
	var card3 = $MainTabs/TabSchedule/TrioCardsHBox/Card3
	var card4 = $MainTabs/TabSchedule/TrioCardsHBox.get_node_or_null("Card4")
	var card5 = $MainTabs/TabSchedule/TrioCardsHBox.get_node_or_null("Card5")
	var all_cards = [card1, card2, card3, card4, card5]

	if trio_cards_hbox:
		trio_cards_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	if not cm.has_team:
		# Solo Fighter: show ONLY the player's card, centered, unexpanded!
		if trio_header_title:
			trio_header_title.text = "Solo Combatant (Free Agent)"
		card1.visible = true
		card1.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		card1.custom_minimum_size = Vector2(210, 175)
		for ci in range(1, all_cards.size()):
			if all_cards[ci]:
				all_cards[ci].visible = false

		_populate_fighter_card(card1, {
			"name": p_name,
			"element": cm.player_element,
			"level": cm.player_level,
			"role": "Striker",
			"archetype": "Striker",
			"hp": _player_max_hp(),
			"speed": cm.player_speed,
			"potency": cm.player_potency,
			"skill_label": _player_featured_skill_label(),
			"is_captain": true,
			"pos_tag": "◆ Solo Combatant: Free Agent"
		})
	else:
		# In a Team: Show 5 active starter slots side by side!
		if trio_header_title:
			trio_header_title.text = "Active Squad Lineup (5 Max)"
		for ci in range(all_cards.size()):
			if all_cards[ci]:
				all_cards[ci].visible = true
				all_cards[ci].size_flags_horizontal = Control.SIZE_EXPAND_FILL
				all_cards[ci].custom_minimum_size = Vector2(210, 175)

		# Slot 1: Captain (Player)
		_populate_fighter_card(card1, {
			"name": p_name,
			"element": cm.player_element,
			"level": cm.player_level,
			"role": "Captain",
			"archetype": "Striker",
			"hp": _player_max_hp(),
			"speed": cm.player_speed,
			"potency": cm.player_potency,
			"skill_label": _player_featured_skill_label(),
			"is_captain": true,
			"pos_tag": "◆ Pos. 1: Vanguard (Captain)"
		})

		# Slots 2 to 5: Allies or Open Slots
		var pos_tags = [
			"◆ Pos. 1: Vanguard (Captain)",
			"◆ Pos. 2: Controller",
			"◆ Pos. 3: Defender",
			"◆ Pos. 4: Striker / Flex",
			"◆ Pos. 5: Support / Anchor"
		]
		var active_allies = []
		for a in cm.allies:
			if a.get("name") != p_name:
				active_allies.append(a)

		for slot_idx in range(1, 5):
			var c_node = all_cards[slot_idx]
			if not c_node: continue
			var ally_idx = slot_idx - 1
			if ally_idx < active_allies.size():
				var ally_data = active_allies[ally_idx]
				var a_stats = ally_data.get("base_stats", {})
				var a_skills = ally_data.get("equipped_skills", [])
				_populate_fighter_card(c_node, {
					"name": ally_data.get("name", "Ally"),
					"element": ally_data.get("element", "water"),
					"level": ally_data.get("level", 1),
					"role": ally_data.get("archetype", ally_data.get("role", "Controller")),
					"archetype": ally_data.get("archetype", "Controller"),
					"hp": ally_data.get("hp", a_stats.get("hp", 100)),
					"speed": ally_data.get("speed", a_stats.get("speed", 3)),
					"potency": ally_data.get("potency", 30),
					"skill": a_skills[0] if a_skills.size() > 0 else "Guard",
					"is_captain": false,
					"pos_tag": pos_tags[slot_idx]
				})
			else:
				_populate_open_slot_card(c_node, pos_tags[slot_idx])

	# 4. Next Clash Details
	var next_m = cm.get_next_scheduled_match()
	if cm.pending_element_choice:
		lbl_next_match_tag.text = "Career Milestone • New Element"
		lbl_next_opp_name.text = "Choose your next elemental discipline"
		lbl_next_xp_reward.text = "SP Skills"
		lbl_next_gold_reward.text = "New Path"
		lbl_next_opp_details.text = "Learn its techniques in the skill tree with SP"
		lbl_next_opp_counter.text = "Your original element and skills stay available."
		btn_enter_match.text = "Choose Element"
		btn_enter_match.disabled = false
	elif cm.primordial_choice_pending:
		lbl_next_match_tag.text = "National Cup • Primordial Choice"
		lbl_next_opp_name.text = "Choose Space or Time"
		lbl_next_xp_reward.text = "Endgame Path"
		lbl_next_gold_reward.text = "Cup Title"
		lbl_next_opp_details.text = "A later World Cup and Club World Cup earn skill permits"
		lbl_next_opp_counter.text = "Techniques still cost SP in the skill tree."
		btn_enter_match.text = "Choose Space / Time"
		btn_enter_match.disabled = false
	elif cm.world_cup_reward_pending:
		lbl_next_match_tag.text = "World Cup • Champion Reward"
		lbl_next_opp_name.text = "Choose a primordial reward"
		lbl_next_xp_reward.text = "World Cup"
		lbl_next_gold_reward.text = "Choice"
		lbl_next_opp_details.text = "Unlock the other element or one extra skill permit"
		lbl_next_opp_counter.text = "New skills still require SP in the tree."
		btn_enter_match.text = "Choose Reward"
		btn_enter_match.disabled = false
	elif offer_ready:
		lbl_next_match_tag.text = "Scout Offer • Club Career"
		lbl_next_opp_name.text = "%s invite you to join" % cm.recruitment_offer_club
		lbl_next_xp_reward.text = "3/3 Wins"
		lbl_next_gold_reward.text = "3v3 Club"
		lbl_next_opp_details.text = "Your element stays %s through City level" % cm.player_element.capitalize()
		lbl_next_opp_counter.text = "Accept to start the eight-month club season."
		btn_enter_match.text = "Accept Club Offer"
		btn_enter_match.disabled = false
	elif not next_m.is_empty():
		if not cm.has_team:
			if lbl_next_match_tag:
				lbl_next_match_tag.text = "Next Street Duel: Match %d" % (cm.street_wins + 1)
			if lbl_next_xp_reward:
				lbl_next_xp_reward.text = "+60 XP"
			if lbl_next_gold_reward:
				lbl_next_gold_reward.text = "+75 G"
			lbl_next_opp_name.text = "vs %s • Scrapfield Arena" % [next_m.get("enemy_team", "Underground Syndicate")]
			lbl_next_opp_details.text = "Rival: %s (%s) • Street Duel %d" % [
				next_m.get("enemy_captain", "Rival"), next_m.get("enemy_element", "water").capitalize(), cm.street_wins + 1
			]
			lbl_next_opp_counter.text = _get_element_matchup_hint(cm.player_element, next_m.get("enemy_element", "water"))
			btn_enter_match.text = "Enter Street Duel"
			btn_enter_match.disabled = false
		elif club_season:
			var season_week = clampi(int(next_m.get("week", season_summary.get("week", 1))), 1, 32)
			var days_until = cm.get_days_until_next_match()
			var phase = str(season_summary.get("phase", "club_regular"))
			var match_label = "Club League"
			if phase == "club_semifinal":
				match_label = "Championship Semifinal"
			elif phase == "club_final":
				match_label = "National Cup Final" if cm.league_tier == 3 else "Championship Final"
			lbl_next_match_tag.text = "Week %d/32 • %s" % [season_week, match_label]
			lbl_next_xp_reward.text = "+60 XP"
			lbl_next_gold_reward.text = "+200 G"
			lbl_next_opp_name.text = "vs %s • Scrapfield Arena" % next_m.get("enemy_team", "Rival Club")
			lbl_next_opp_details.text = "%s • %s day(s) away" % [next_m.get("date_label", "Match day"), days_until] if days_until > 0 else "Today • Captain: %s" % next_m.get("enemy_captain", "Opponent")
			lbl_next_opp_counter.text = _get_element_matchup_hint(cm.player_element, next_m.get("enemy_element", "neutral"))
			btn_enter_match.text = "Match in %d days" % days_until if days_until > 0 else "Enter Match"
			btn_enter_match.disabled = days_until > 0
		else:
			if lbl_next_match_tag:
				lbl_next_match_tag.text = "Next Tournament Match: Round %d" % cm.league_round
			if lbl_next_xp_reward:
				lbl_next_xp_reward.text = "+60 XP"
			if lbl_next_gold_reward:
				lbl_next_gold_reward.text = "+200 G"
			lbl_next_opp_name.text = "vs %s • Scrapfield Arena" % [next_m.get("enemy_team", "Rival Crew")]
			lbl_next_opp_details.text = "Captain: %s (%s) • Round %d" % [
				next_m.get("enemy_captain", "Opponent"), next_m.get("enemy_element", "neutral").capitalize(), cm.league_round
			]
			lbl_next_opp_counter.text = _get_element_matchup_hint(cm.player_element, next_m.get("enemy_element", "neutral"))
			btn_enter_match.text = "Enter Battle"
			btn_enter_match.disabled = false
	else:
		if lbl_next_match_tag:
			lbl_next_match_tag.text = "Season Complete" if club_season else "Circuit Complete"
		var offseason = club_season and str(season_summary.get("phase", "")) == "offseason"
		lbl_next_opp_name.text = "Start the next club season" if offseason else ("No match currently scheduled" if club_season else "All clashes complete")
		lbl_next_xp_reward.text = ""
		lbl_next_gold_reward.text = ""
		lbl_next_opp_details.text = ""
		lbl_next_opp_counter.text = "Promotion and relegation are settled; your club continues." if offseason else ""
		btn_enter_match.text = "Next Season" if offseason else "No Match Available"
		btn_enter_match.disabled = not offseason

	# Refresh Timeline dynamically
	_refresh_timeline()

	# 5. Refresh Other Tabs
	_refresh_team_tab()
	_refresh_battle_tab()
	_refresh_intel_tab()
	_refresh_skills_tab()

func _populate_fighter_card(card_node: PanelContainer, data: Dictionary):
	if not card_node: return
	card_node.visible = true
	var pos_tag = card_node.get_node_or_null("Margin/VB/TopRow/PosTag")
	var c_name = card_node.get_node_or_null("Margin/VB/MidRow/VBInfo/Name")
	var c_role = card_node.get_node_or_null("Margin/VB/MidRow/VBInfo/Role")
	var c_sprite = card_node.get_node_or_null("Margin/VB/MidRow/AvatarFrame/Sprite")
	var c_arch = card_node.get_node_or_null("Margin/VB/MidRow/ArchetypePill/L")
	var c_move = card_node.get_node_or_null("Margin/VB/StatsGrid/ColMove/V")
	var c_hp = card_node.get_node_or_null("Margin/VB/StatsGrid/ColHp/V")
	var c_atk = card_node.get_node_or_null("Margin/VB/StatsGrid/ColAtk/V")
	var c_banner = card_node.get_node_or_null("Margin/VB/Banner/Lbl")

	if pos_tag: pos_tag.text = data.get("pos_tag", "◆ Fighter")
	if c_name:
		c_name.text = data.get("name", "Athlete")
		c_name.clip_text = true
	if c_role:
		c_role.text = "Lv. %d %s %s" % [data.get("level", 1), data.get("element", "fire").capitalize(), data.get("role", "Striker")]
		c_role.clip_text = true
	if c_arch: c_arch.text = data.get("archetype", "Striker")
	if c_move: c_move.text = str(int(round(float(data.get("speed", 3)))))
	if c_hp: c_hp.text = str(int(round(float(data.get("hp", 100)))))
	if c_atk: c_atk.text = str(int(round(float(data.get("potency", 30)))))
	if c_banner:
		c_banner.text = data.get("skill_label", str(data.get("skill", "Strike")).capitalize().replace("_", " "))
		c_banner.tooltip_text = c_banner.text

	if c_sprite:
		c_sprite.visible = true
		c_sprite.position = Vector2(19, 27)
		c_sprite.scale = Vector2(0.42, 0.42)
		var elem_walk = "res://assets/%s_walk.png" % data.get("element", "fire").to_lower()
		if ResourceLoader.exists(elem_walk):
			c_sprite.texture = load(elem_walk)

func _populate_open_slot_card(card_node: PanelContainer, pos_title: String):
	if not card_node: return
	card_node.visible = true
	var pos_tag = card_node.get_node_or_null("Margin/VB/TopRow/PosTag")
	var c_name = card_node.get_node_or_null("Margin/VB/MidRow/VBInfo/Name")
	var c_role = card_node.get_node_or_null("Margin/VB/MidRow/VBInfo/Role")
	var c_sprite = card_node.get_node_or_null("Margin/VB/MidRow/AvatarFrame/Sprite")
	var c_arch = card_node.get_node_or_null("Margin/VB/MidRow/ArchetypePill/L")
	var c_move = card_node.get_node_or_null("Margin/VB/StatsGrid/ColMove/V")
	var c_hp = card_node.get_node_or_null("Margin/VB/StatsGrid/ColHp/V")
	var c_atk = card_node.get_node_or_null("Margin/VB/StatsGrid/ColAtk/V")
	var c_banner = card_node.get_node_or_null("Margin/VB/Banner/Lbl")

	if pos_tag: pos_tag.text = pos_title
	if c_name:
		c_name.text = "[Open Slot]"
		c_name.clip_text = true
	if c_role:
		c_role.text = "Available Starter Slot"
		c_role.clip_text = true
	if c_arch: c_arch.text = "Open"
	if c_move: c_move.text = "--"
	if c_hp: c_hp.text = "--"
	if c_atk: c_atk.text = "--"
	if c_banner: c_banner.text = "Available Slot"
	if c_sprite: c_sprite.visible = false


func _format_number(val: int) -> String:
	var s = str(val)
	var res = ""
	var count = 0
	for i in range(s.length() - 1, -1, -1):
		res = s[i] + res
		count += 1
		if count == 3 and i > 0:
			res = "," + res
			count = 0
	return res

func _get_element_matchup_hint(p_elem: String, e_elem: String) -> String:
	if edata and edata.ELEMENTS.has(e_elem):
		var e_weak = edata.ELEMENTS[e_elem].get("weakness", [])
		if p_elem in e_weak:
			return "Tactical Advantage: Your %s counters enemy %s (+25%% damage bonus)" % [p_elem.capitalize(), e_elem.capitalize()]
	if edata and edata.ELEMENTS.has(p_elem):
		var p_weak = edata.ELEMENTS[p_elem].get("weakness", [])
		if e_elem in p_weak:
			return "Threat Warning: Enemy %s counters your %s! Guard closely!" % [e_elem.capitalize(), p_elem.capitalize()]
	return "Balanced Matchup: Neutral elemental affinity (+0%% bonus)"

func _get_potential_tier_label(potential: int) -> String:
	if cm and cm.has_method("get_potential_label"):
		return cm.get_potential_label(potential)
	if potential >= 75:
		return "Prodigy"
	elif potential >= 40:
		return "Rising Star"
	return "Journeyman"

# ══════════════════════════════════════════════════════════════════════════════
#  TAB 4: CULTIVATION SUBPAGE ARCHITECTURE
# ══════════════════════════════════════════════════════════════════════════════

var _cultivation_subpage: int = 0  # 0 = Overview, 1 = Techniques, 2 = Skill Tree, 3 = Proficiencies
var _roster_subtab: int = 0        # 0 = Profile, 1 = Skills, 2 = Training, 3 = Career
var _intel_view_roster: bool = false
var _skill_tab_mode: int = 0  # Legacy compatibility fallback
const SkillTreeCanvasScript = preload("res://scripts/skill_tree_canvas.gd")
var skill_tree_canvas = null

# ══════════════════════════════════════════════════════════════════════════════
#  EXPANDED FORM VARIATIONS & DISCIPLINE TREE DATA
# ══════════════════════════════════════════════════════════════════════════════

const SKILL_VARIATIONS = {
	"Combustion": [
		{"name": "Explosive Punch", "desc": "Melee impact (1 tile), +15% direct damage", "icon": ""},
		{"name": "Explosion Pulse", "desc": "Linear shockwave (4 tiles forward), pierces frontline", "icon": ""},
		{"name": "Explosion Outburst", "desc": "Radial burst (3-tile radius around caster), hits all adjacent foes", "icon": ""}
	],
	"Aqua_Mend": [
		{"name": "Hydration Touch", "desc": "Melee cellular restore (+45 HP single target)", "icon": ""},
		{"name": "Healing Vapor", "desc": "Linear mist spray (+25 HP to all allies in 3-tile line)", "icon": ""},
		{"name": "Spring Pool", "desc": "Creates restorative hazard puddle granting +10 HP/turn", "icon": ""}
	],
	"Stone_Plating": [
		{"name": "Stone Skin", "desc": "Self mineral fortification (+40 barrier armor)", "icon": ""},
		{"name": "Rock Pillar", "desc": "Summons solid stone barricade blocking enemy line-of-sight", "icon": ""},
		{"name": "Tremor Anchor", "desc": "Anchor posture: immune to knockbacks and blitz interceptions", "icon": ""}
	],
	"Gale_Step": [
		{"name": "Wind Slip", "desc": "+40% Evasion boost against all directions for 2 turns", "icon": ""},
		{"name": "Gale Dash", "desc": "3-tile disengage leap ignoring enemy flank penalties", "icon": ""},
		{"name": "Vortex Screen", "desc": "Deflective air barrier that bounces back projectile disciplines", "icon": ""}
	],
	"Laser": [
		{"name": "Photonic Lance", "desc": "High velocity focused beam piercing 1st target", "icon": ""},
		{"name": "Refraction Fan", "desc": "Split beam across 3 forward tiles in a cone", "icon": ""}
	],
	"Lightning": [
		{"name": "Chain Arc", "desc": "Electrical bolt that chains to 1 secondary adjacent enemy", "icon": ""},
		{"name": "Thunderclap", "desc": "Shock burst that strips 25 stamina from target", "icon": ""}
	],
	"Plasma": [
		{"name": "Magneto-Cutter", "desc": "Superheated plasma edge shredding enemy defensive barrier", "icon": ""},
		{"name": "Plasma Vortex", "desc": "Slow moving plasma sphere dealing continuous burn damage", "icon": ""}
	],
	"Destruction": [
		{"name": "Entropy Spike", "desc": "Rapid molecular breakdown: drains 30 enemy mana", "icon": ""},
		{"name": "Cataclysm Nova", "desc": "Massive 360° unmaking field dealing devastating pure damage", "icon": ""}
	]
}

func _refresh_skills_tab():
	if not tab_skills: return

	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")
	_render_cultivation_top_bar()

	var profile_col = $MainTabs/TabSkills/HBox/ProfileCol
	var eq_col = $MainTabs/TabSkills/HBox/EquippedCol
	var lib_col = $MainTabs/TabSkills/HBox/LibraryCol
	var consumables_box = $MainTabs/TabSkills/HBox/LibraryCol/ConsumablesBox
	if consumables_box:
		consumables_box.visible = false

	var scroll = $MainTabs/TabSkills/HBox/LibraryCol/Scroll
	var lib_title = $MainTabs/TabSkills/HBox/LibraryCol/Title
	if _cultivation_subpage == 2:
		if scroll: scroll.visible = false
		if lib_title: lib_title.visible = false
	else:
		if scroll: scroll.visible = true
		if lib_title: lib_title.visible = true
		if skill_tree_canvas and is_instance_valid(skill_tree_canvas):
			skill_tree_canvas.visible = false

	match _cultivation_subpage:
		0:
			if profile_col:
				profile_col.visible = true
				profile_col.custom_minimum_size = Vector2(500, 0)
				profile_col.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
			if eq_col: eq_col.visible = false
			if lib_col:
				lib_col.visible = true
				lib_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_render_cultivation_overview()
		1:
			if profile_col: profile_col.visible = false
			if eq_col:
				eq_col.visible = true
				eq_col.custom_minimum_size = Vector2(460, 0)
			if lib_col:
				lib_col.visible = true
				lib_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_render_cultivation_techniques()
		2:
			if profile_col: profile_col.visible = false
			if eq_col: eq_col.visible = false
			if lib_col:
				lib_col.visible = true
				lib_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_render_cultivation_tree()
		3:
			if profile_col: profile_col.visible = false
			if eq_col: eq_col.visible = false
			if lib_col:
				lib_col.visible = true
				lib_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_render_cultivation_proficiencies()

func _render_cultivation_top_bar():
	var top_bar = $MainTabs/TabSkills/TopFighterBar
	if not top_bar: return

	for c in top_bar.get_children():
		top_bar.remove_child(c)
		c.queue_free()

	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	# 1. Fighter Summary & Consumables Row
	var summary_card = PanelContainer.new()
	var sc_sb = StyleBoxFlat.new()
	sc_sb.set_corner_radius_all(6)
	sc_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	sc_sb.border_width_left = 1
	sc_sb.border_width_top = 1
	sc_sb.border_width_right = 1
	sc_sb.border_width_bottom = 1
	sc_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
	sc_sb.content_margin_left = 14
	sc_sb.content_margin_right = 14
	sc_sb.content_margin_top = 8
	sc_sb.content_margin_bottom = 8
	summary_card.add_theme_stylebox_override("panel", sc_sb)
	top_bar.add_child(summary_card)

	var s_hb = HBoxContainer.new()
	s_hb.add_theme_constant_override("separation", 16)
	summary_card.add_child(s_hb)

	# Avatar Pedestal
	var av_p = PanelContainer.new()
	av_p.custom_minimum_size = Vector2(44, 44)
	var av_sb = StyleBoxFlat.new()
	av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
	av_sb.set_corner_radius_all(4)
	av_sb.border_width_left = 1
	av_sb.border_width_top = 1
	av_sb.border_width_right = 1
	av_sb.border_width_bottom = 1
	av_sb.border_color = _get_element_color(cm.player_element)
	av_p.add_theme_stylebox_override("panel", av_sb)

	av_p.add_child(_make_portrait(cm.player_element))
	s_hb.add_child(av_p)

	# Identity VBox
	var id_vb = VBoxContainer.new()
	id_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	id_vb.add_theme_constant_override("separation", 2)
	s_hb.add_child(id_vb)

	var name_lbl = Label.new()
	name_lbl.text = cm.player_name
	name_lbl.add_theme_font_size_override("font_size", 13)
	name_lbl.modulate = Color(1.0, 0.95, 0.85)
	id_vb.add_child(name_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "Lv. %d %s Striker" % [cm.player_level, cm.player_element.capitalize()]
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.modulate = _get_element_color(cm.player_element)
	id_vb.add_child(sub_lbl)

	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(20, 0)
	s_hb.add_child(spacer1)

	# XP & Unspent Points
	var xp_vb = VBoxContainer.new()
	xp_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	xp_vb.add_theme_constant_override("separation", 3)
	s_hb.add_child(xp_vb)

	var xp_lbl = Label.new()
	xp_lbl.text = "Experience Progress: %d / %d XP" % [cm.player_xp, cm.player_xp_to_next]
	xp_lbl.add_theme_font_size_override("font_size", 9)
	xp_lbl.modulate = UITheme.GOLD_PRIMARY
	xp_vb.add_child(xp_lbl)

	var bar_xp = ProgressBar.new()
	bar_xp.custom_minimum_size = Vector2(160, 8)
	bar_xp.max_value = cm.player_xp_to_next
	bar_xp.value = cm.player_xp
	bar_xp.show_percentage = false
	var bx_bg = StyleBoxFlat.new()
	bx_bg.bg_color = Color(0.08, 0.10, 0.14)
	bx_bg.set_corner_radius_all(2)
	var bx_fg = StyleBoxFlat.new()
	bx_fg.bg_color = UITheme.GOLD_PRIMARY
	bx_fg.set_corner_radius_all(2)
	bar_xp.add_theme_stylebox_override("background", bx_bg)
	bar_xp.add_theme_stylebox_override("fill", bx_fg)
	xp_vb.add_child(bar_xp)

	# Points Chips
	var pts_hb = HBoxContainer.new()
	pts_hb.add_theme_constant_override("separation", 10)
	s_hb.add_child(pts_hb)

	var stat_pts_pill = PanelContainer.new()
	var sp_sb = StyleBoxFlat.new()
	sp_sb.set_corner_radius_all(4)
	sp_sb.content_margin_left = 8
	sp_sb.content_margin_right = 8
	sp_sb.content_margin_top = 4
	sp_sb.content_margin_bottom = 4
	sp_sb.bg_color = Color(0.08, 0.16, 0.12, 0.9) if cm.unspent_stat_points > 0 else Color(0.08, 0.10, 0.14, 0.8)
	sp_sb.border_width_left = 1
	sp_sb.border_width_top = 1
	sp_sb.border_width_right = 1
	sp_sb.border_width_bottom = 1
	sp_sb.border_color = Color(0.35, 0.85, 0.55, 0.8) if cm.unspent_stat_points > 0 else Color(0.20, 0.28, 0.38, 0.5)
	stat_pts_pill.add_theme_stylebox_override("panel", sp_sb)

	var l_spts = Label.new()
	l_spts.text = "Stat Points: %d" % cm.unspent_stat_points
	l_spts.add_theme_font_size_override("font_size", 9)
	l_spts.modulate = Color(0.4, 0.9, 0.6) if cm.unspent_stat_points > 0 else Color(0.60, 0.68, 0.78)
	stat_pts_pill.add_child(l_spts)
	pts_hb.add_child(stat_pts_pill)

	var skill_pts_pill = PanelContainer.new()
	var sk_sb = StyleBoxFlat.new()
	sk_sb.set_corner_radius_all(4)
	sk_sb.content_margin_left = 8
	sk_sb.content_margin_right = 8
	sk_sb.content_margin_top = 4
	sk_sb.content_margin_bottom = 4
	sk_sb.bg_color = Color(0.16, 0.12, 0.06, 0.9) if cm.unspent_skill_points > 0 else Color(0.08, 0.10, 0.14, 0.8)
	sk_sb.border_width_left = 1
	sk_sb.border_width_top = 1
	sk_sb.border_width_right = 1
	sk_sb.border_width_bottom = 1
	sk_sb.border_color = UITheme.GOLD_PRIMARY if cm.unspent_skill_points > 0 else Color(0.20, 0.28, 0.38, 0.5)
	skill_pts_pill.add_theme_stylebox_override("panel", sk_sb)

	var l_skpts = Label.new()
	l_skpts.text = "Skill Points: %d SP" % cm.unspent_skill_points
	l_skpts.add_theme_font_size_override("font_size", 9)
	l_skpts.modulate = UITheme.GOLD_PRIMARY if cm.unspent_skill_points > 0 else Color(0.60, 0.68, 0.78)
	skill_pts_pill.add_child(l_skpts)
	pts_hb.add_child(skill_pts_pill)

	var spacer2 = Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	s_hb.add_child(spacer2)

	# 2. Subpage Navigation Tabs Bar
	var subnav_hb = HBoxContainer.new()
	subnav_hb.add_theme_constant_override("separation", 8)
	top_bar.add_child(subnav_hb)

	var subpages = [
		{"idx": 0, "title": "Overview"},
		{"idx": 1, "title": "Techniques"},
		{"idx": 2, "title": "Skill Tree"},
		{"idx": 3, "title": "Proficiencies"}
	]

	for sp in subpages:
		var btn = Button.new()
		btn.text = sp["title"]
		if cinzel_font:
			btn.add_theme_font_override("font", cinzel_font)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(0, 34)
		if _cultivation_subpage == sp["idx"]:
			_style_tactical_button(btn, Color(0.12, 0.16, 0.26, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75), 11, true)
		else:
			_style_secondary_slate_button(btn, 11)
		var sp_i = sp["idx"]
		btn.pressed.connect(func():
			_cultivation_subpage = sp_i
			_refresh_skills_tab()
		)
		subnav_hb.add_child(btn)

func _render_cultivation_overview():
	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")
	var profile_col = $MainTabs/TabSkills/HBox/ProfileCol
	if not profile_col: return

	# 1. Update Profile & Real Combat Stats
	var p_stats_panel = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelStats
	if p_stats_panel:
		if p_stats_panel.get_script() != null:
			p_stats_panel.set_script(null)
			p_stats_panel.queue_redraw()
		var p_sb = StyleBoxFlat.new()
		p_sb.set_corner_radius_all(6)
		p_sb.bg_color = Color(0.07, 0.09, 0.14, 0.96)
		p_sb.border_width_left = 1
		p_sb.border_width_top = 1
		p_sb.border_width_right = 1
		p_sb.border_width_bottom = 1
		p_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
		p_sb.content_margin_left = 14
		p_sb.content_margin_right = 14
		p_sb.content_margin_top = 10
		p_sb.content_margin_bottom = 10
		p_stats_panel.add_theme_stylebox_override("panel", p_sb)

	var panel_stats = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelStats/Margin/VB
	var p_title = panel_stats.get_node_or_null("Title")
	if p_title:
		p_title.text = "Attribute Allocation"
		p_title.modulate = UITheme.GOLD_PRIMARY
		p_title.add_theme_font_size_override("font_size", 12)

	if lbl_player_stats:
		lbl_player_stats.text = "Unspent Stat Points: %d  |  Unspent SP: %d\nXP: %d / %d" % [
			cm.unspent_stat_points, cm.unspent_skill_points, cm.player_xp, cm.player_xp_to_next
		]
		lbl_player_stats.add_theme_font_size_override("font_size", 9)
		lbl_player_stats.modulate = Color(0.45, 0.85, 0.55) if (cm.unspent_stat_points > 0 or cm.unspent_skill_points > 0) else Color(0.65, 0.72, 0.85)

	# Interactive stat allocation buttons in ProfileCol
	var alloc_box = panel_stats.get_node_or_null("StatAllocBox")
	if not alloc_box:
		alloc_box = VBoxContainer.new()
		alloc_box.name = "StatAllocBox"
		alloc_box.add_theme_constant_override("separation", 4)
		panel_stats.add_child(alloc_box)

	var edata = _get_element_data()
	var p_base = {}
	if edata and edata.ELEMENTS.has(cm.player_element):
		p_base = edata.ELEMENTS[cm.player_element]

	var min_speed = p_base.get("base_speed", 3)
	var min_agility = p_base.get("base_agility", 28)
	var min_dexterity = p_base.get("base_dexterity", 32)
	var min_stamina = p_base.get("base_stamina", 100)
	var min_mana = p_base.get("base_mp", 100)
	var min_potency = 30
	var min_defense = p_base.get("base_defense", 20)

	var stats_list = [
		{"key": "Speed", "val": cm.player_speed, "min": min_speed, "step": 1},
		{"key": "Agility", "val": cm.player_agility, "min": min_agility, "step": 2},
		{"key": "Dexterity", "val": cm.player_dexterity, "min": min_dexterity, "step": 2},
		{"key": "Defense", "val": cm.player_defense, "min": min_defense, "step": 2},
		{"key": "Stamina", "val": cm.player_stamina, "min": min_stamina, "step": 10},
		{"key": "Mana", "val": cm.player_mana, "min": min_mana, "step": 10},
		{"key": "Potency", "val": cm.player_potency, "min": min_potency, "step": 3}
	]

	for st in stats_list:
		var row_id = "Row_" + st["key"]
		var s_row = alloc_box.get_node_or_null(row_id)
		if not s_row:
			s_row = HBoxContainer.new()
			s_row.name = row_id
			s_row.add_theme_constant_override("separation", 6)

			var s_name = Label.new()
			s_name.name = "Lbl"
			s_name.text = "%s: %d" % [st["key"], st["val"]]
			s_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			s_name.add_theme_font_size_override("font_size", 10)
			s_name.modulate = Color(0.9, 0.95, 1.0)
			s_row.add_child(s_name)

			var btn_minus = Button.new()
			btn_minus.name = "BtnMinus"
			btn_minus.text = "-"
			btn_minus.custom_minimum_size = Vector2(26, 20)
			_style_secondary_slate_button(btn_minus, 9)
			var k_min = st["key"]
			btn_minus.pressed.connect(func():
				if cm.revert_stat_point(k_min):
					_refresh_skills_tab()
			)
			s_row.add_child(btn_minus)

			var btn_plus = Button.new()
			btn_plus.name = "BtnPlus"
			btn_plus.text = "+"
			btn_plus.custom_minimum_size = Vector2(26, 20)
			_style_tactical_button(btn_plus, Color(0.18, 0.14, 0.08, 1.0), UITheme.GOLD_PRIMARY, Color(1.0, 0.9, 0.5), 10, false)
			var k_pls = st["key"]
			btn_plus.pressed.connect(func():
				if cm.spend_stat_point(k_pls):
					_refresh_skills_tab()
			)
			s_row.add_child(btn_plus)

			alloc_box.add_child(s_row)

		# Update values in-place
		var s_lbl = s_row.get_node_or_null("Lbl")
		if s_lbl:
			s_lbl.text = "%s: %d" % [st["key"], st["val"]]
		var btn_min = s_row.get_node_or_null("BtnMinus")
		if btn_min:
			btn_min.disabled = (st["val"] <= st["min"])
		var btn_pls = s_row.get_node_or_null("BtnPlus")
		if btn_pls:
			btn_pls.disabled = (cm.unspent_stat_points <= 0)

	# Style PanelActions
	var panel_actions_container = $MainTabs/TabSkills/HBox/ProfileCol/Content/PanelActions
	if panel_actions_container:
		if panel_actions_container.get_script() != null:
			panel_actions_container.set_script(null)
			panel_actions_container.queue_redraw()
		var pa_sb = StyleBoxFlat.new()
		pa_sb.set_corner_radius_all(6)
		pa_sb.bg_color = Color(0.06, 0.08, 0.12, 0.90)
		pa_sb.border_width_left = 1
		pa_sb.border_width_top = 1
		pa_sb.border_width_right = 1
		pa_sb.border_width_bottom = 1
		pa_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
		pa_sb.content_margin_left = 10
		pa_sb.content_margin_right = 10
		pa_sb.content_margin_top = 8
		pa_sb.content_margin_bottom = 8
		panel_actions_container.add_theme_stylebox_override("panel", pa_sb)

	if btn_save:
		btn_save.text = "Save Campaign"
		_style_secondary_slate_button(btn_save, 10)
	if btn_dev:
		btn_dev.text = "Dev: Unlock All & Lv. 30"
		_style_secondary_slate_button(btn_dev, 9)
	if btn_menu:
		btn_menu.text = "Main Menu"
		_style_secondary_slate_button(btn_menu, 10)

	var old_med = profile_col.get_node_or_null("PanelMeditation")
	if old_med:
		profile_col.remove_child(old_med)
		old_med.queue_free()

	# Right Column: Combat Attributes & Martial Harmony Cards in LibraryCol
	var lib_title = $MainTabs/TabSkills/HBox/LibraryCol/Title
	if lib_title:
		lib_title.text = "Combat Physiology & Martial Harmony"
		lib_title.modulate = UITheme.GOLD_PRIMARY
		lib_title.add_theme_font_size_override("font_size", 12)

	for c in unlocked_skills_box.get_children():
		unlocked_skills_box.remove_child(c)
		c.queue_free()

	# 1. Physical Condition & Martial Harmony Card
	var med_panel = PanelContainer.new()
	var med_sb = StyleBoxFlat.new()
	med_sb.set_corner_radius_all(6)
	med_sb.bg_color = Color(0.06, 0.08, 0.12, 0.92)
	med_sb.border_width_left = 1
	med_sb.border_width_top = 1
	med_sb.border_width_right = 1
	med_sb.border_width_bottom = 1
	med_sb.border_color = Color(0.18, 0.24, 0.35, 0.6)
	med_sb.content_margin_left = 16
	med_sb.content_margin_right = 16
	med_sb.content_margin_top = 12
	med_sb.content_margin_bottom = 12
	med_panel.add_theme_stylebox_override("panel", med_sb)
	unlocked_skills_box.add_child(med_panel)

	var med_vb = VBoxContainer.new()
	med_vb.add_theme_constant_override("separation", 6)
	med_panel.add_child(med_vb)

	var med_title = Label.new()
	med_title.text = "Physical Condition & Martial Harmony"
	med_title.add_theme_font_size_override("font_size", 11)
	med_title.modulate = UITheme.GOLD_PRIMARY
	med_vb.add_child(med_title)

	var med_notes = [
		"◆ Element Attunement: %s" % cm.player_element.capitalize(),
		"◆ Campaign Energy: %d / 100" % cm.energy,
		"◆ Training: Choose a stat; each session costs 1 day and 15 energy",
		"◆ Rest: Choose 1, 3, or 7 days to recover energy"
	]
	for n in med_notes:
		var n_lbl = Label.new()
		n_lbl.text = n
		n_lbl.add_theme_font_size_override("font_size", 9)
		n_lbl.modulate = Color(0.72, 0.80, 0.90)
		med_vb.add_child(n_lbl)

	# 2. Combat Efficiency & Ratings Grid
	var combat_panel = PanelContainer.new()
	var cb_sb = StyleBoxFlat.new()
	cb_sb.set_corner_radius_all(6)
	cb_sb.bg_color = Color(0.05, 0.07, 0.10, 0.90)
	cb_sb.border_width_left = 1
	cb_sb.border_width_top = 1
	cb_sb.border_width_right = 1
	cb_sb.border_width_bottom = 1
	cb_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
	cb_sb.content_margin_left = 16
	cb_sb.content_margin_right = 16
	cb_sb.content_margin_top = 12
	cb_sb.content_margin_bottom = 12
	combat_panel.add_theme_stylebox_override("panel", cb_sb)
	unlocked_skills_box.add_child(combat_panel)

	var cb_vb = VBoxContainer.new()
	cb_vb.add_theme_constant_override("separation", 8)
	combat_panel.add_child(cb_vb)

	var cb_title = Label.new()
	cb_title.text = "Combat Ratings & Tactical Parameters"
	cb_title.add_theme_font_size_override("font_size", 11)
	cb_title.modulate = UITheme.GOLD_PRIMARY
	cb_vb.add_child(cb_title)

	var grid_ratings = GridContainer.new()
	grid_ratings.columns = 3
	grid_ratings.add_theme_constant_override("h_separation", 10)
	grid_ratings.add_theme_constant_override("v_separation", 8)
	cb_vb.add_child(grid_ratings)

	var def_val = cm.player_defense if ("player_defense" in cm) else 20
	var def_reduction = mini(int(def_val * 0.5), 65)
	var p_hp = _player_max_hp()

	var rating_cards = [
		{"label": "Strike Potency", "val": "%d Potency" % cm.player_potency, "sub": "Elemental ability strength"},
		{"label": "Kinetic Agility", "val": "%d Agility" % cm.player_agility, "sub": "Directional evasion"},
		{"label": "Combat Dexterity", "val": "%d Dexterity" % cm.player_dexterity, "sub": "Attack accuracy"},
		{"label": "Fortified Armor", "val": "%d DEF (-%d%% Dmg)" % [def_val, def_reduction], "sub": "Incoming damage reduction"},
		{"label": "Tactical Mobility", "val": "%d Tiles / Turn" % cm.player_speed, "sub": "Arena grid range"},
		{"label": "Vitality Reserves", "val": "%d HP  |  %d STA" % [p_hp, cm.player_stamina], "sub": "Physical endurance pool"},
		{"label": "Aether Reservoir", "val": "%d MP" % cm.player_mana, "sub": "Technique channeling"}
	]

	for rc in rating_cards:
		var r_card = PanelContainer.new()
		r_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var r_sb = StyleBoxFlat.new()
		r_sb.set_corner_radius_all(4)
		r_sb.bg_color = Color(0.04, 0.05, 0.08, 0.8)
		r_sb.border_width_left = 1
		r_sb.border_color = Color(0.20, 0.28, 0.38, 0.4)
		r_sb.content_margin_left = 10
		r_sb.content_margin_right = 10
		r_sb.content_margin_top = 8
		r_sb.content_margin_bottom = 8
		r_card.add_theme_stylebox_override("panel", r_sb)

		var r_vb = VBoxContainer.new()
		r_vb.add_theme_constant_override("separation", 2)
		r_card.add_child(r_vb)

		var r_head = Label.new()
		r_head.text = rc["label"]
		r_head.add_theme_font_size_override("font_size", 9)
		r_head.modulate = UITheme.GOLD_PRIMARY
		r_vb.add_child(r_head)

		var r_val = Label.new()
		r_val.text = rc["val"]
		r_val.add_theme_font_size_override("font_size", 10)
		r_val.modulate = Color(0.92, 0.96, 1.0)
		r_vb.add_child(r_val)

		var r_sub = Label.new()
		r_sub.text = rc["sub"]
		r_sub.add_theme_font_size_override("font_size", 8)
		r_sub.modulate = UITheme.TEXT_MUTED
		r_vb.add_child(r_sub)

		grid_ratings.add_child(r_card)

func _render_cultivation_techniques():
	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	var eq_title = $MainTabs/TabSkills/HBox/EquippedCol/Title
	if eq_title:
		eq_title.text = "Equipped Techniques (4 Slots)"
		eq_title.modulate = UITheme.GOLD_PRIMARY
		eq_title.add_theme_font_size_override("font_size", 12)

	for c in equipped_skills_box.get_children():
		equipped_skills_box.remove_child(c)
		c.queue_free()

	for i in range(4):
		var slot_card = PanelContainer.new()
		slot_card.custom_minimum_size = Vector2(0, 56)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(5)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8

		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		slot_card.add_child(hb)

		var lbl = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 10)

		if i < cm.equipped_abilities.size():
			var sk = cm.equipped_abilities[i]
			var desc = ""
			if edata and edata.ABILITIES.has(sk):
				var info = edata.ABILITIES[sk]
				desc = "  (MP %d • %s)" % [info["mp_cost"], info["tier"].capitalize()]
			var cur_var = cm.skill_variations.get(sk, "") if ("skill_variations" in cm and cm.skill_variations != null) else ""
			var var_tag = (" [%s]" % cur_var) if cur_var != "" else ""
			lbl.text = "%d.  %s%s%s" % [i + 1, sk.replace("_", " ").capitalize(), desc, var_tag]
			sb.bg_color = Color(0.08, 0.11, 0.18, 0.95)
			sb.border_width_left = 3
			sb.border_color = UITheme.GOLD_PRIMARY
			lbl.modulate = Color(1.0, 0.95, 0.85)

			var btn_unequip = Button.new()
			btn_unequip.text = "Unequip"
			_style_secondary_slate_button(btn_unequip, 9)
			btn_unequip.custom_minimum_size = Vector2(74, 26)
			var unq_idx = i
			btn_unequip.pressed.connect(func(): _unequip_skill(unq_idx))
			hb.add_child(lbl)
			hb.add_child(btn_unequip)
		else:
			lbl.text = "%d.  [ Empty Technique Slot ]" % [i + 1]
			sb.bg_color = Color(0.04, 0.05, 0.08, 0.70)
			sb.border_width_left = 1
			sb.border_color = Color(0.18, 0.24, 0.35, 0.4)
			lbl.modulate = Color(0.40, 0.45, 0.55)
			hb.add_child(lbl)

		slot_card.add_theme_stylebox_override("panel", sb)
		equipped_skills_box.add_child(slot_card)

	# Right Column: Equippable Codex
	var lib_title = $MainTabs/TabSkills/HBox/LibraryCol/Title
	if lib_title:
		lib_title.text = "Equippable Martial Codex"
		lib_title.modulate = UITheme.GOLD_PRIMARY
		lib_title.add_theme_font_size_override("font_size", 12)

	for c in unlocked_skills_box.get_children():
		unlocked_skills_box.remove_child(c)
		c.queue_free()

	for sk in cm.unlocked_abilities:
		var row = PanelContainer.new()
		row.custom_minimum_size = Vector2(0, 48)
		var sb = StyleBoxFlat.new()
		sb.set_corner_radius_all(4)
		sb.content_margin_left = 12
		sb.content_margin_right = 12
		sb.content_margin_top = 8
		sb.content_margin_bottom = 8
		sb.bg_color = Color(0.06, 0.08, 0.12, 0.9)
		sb.border_width_left = 2
		sb.border_color = Color(0.2, 0.3, 0.45, 0.6)
		row.add_theme_stylebox_override("panel", sb)

		var hb = HBoxContainer.new()
		hb.add_theme_constant_override("separation", 10)
		row.add_child(hb)

		var ab_info = edata.ABILITIES.get(sk, {}) if edata else {}
		var mp_cost = ab_info.get("mp_cost", 10)
		var elem_tag = ab_info.get("element", cm.player_element).capitalize()
		var rng_tag = ab_info.get("range", 2)

		var cur_var = cm.skill_variations.get(sk, "") if ("skill_variations" in cm and cm.skill_variations != null) else ""
		var var_str = (" [%s]" % cur_var) if cur_var != "" else ""

		var lbl = Label.new()
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbl.add_theme_font_size_override("font_size", 10)
		lbl.modulate = Color(0.85, 0.92, 1.0)
		lbl.text = "%s [%s • MP %d • Range %d]%s" % [ab_info.get("name", sk).replace("_", " ").capitalize(), elem_tag, mp_cost, rng_tag, var_str]
		hb.add_child(lbl)

		var is_equipped = cm.equipped_abilities.has(sk)
		if is_equipped:
			var tag_eq = Label.new()
			tag_eq.text = "Equipped"
			tag_eq.add_theme_font_size_override("font_size", 9)
			tag_eq.modulate = Color(0.4, 0.9, 0.5)
			hb.add_child(tag_eq)
		else:
			var btn_eq = Button.new()
			btn_eq.text = "Equip"
			_style_secondary_slate_button(btn_eq, 9)
			btn_eq.custom_minimum_size = Vector2(70, 26)
			var eq_sk = sk
			btn_eq.pressed.connect(func(): _equip_skill(eq_sk))
			hb.add_child(btn_eq)

		unlocked_skills_box.add_child(row)

func _render_cultivation_tree():
	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")
	var lib_col = $MainTabs/TabSkills/HBox/LibraryCol
	if not lib_col: return

	var lib_title = lib_col.get_node_or_null("Title")
	if lib_title:
		lib_title.visible = false

	var scroll = lib_col.get_node_or_null("Scroll")
	if scroll:
		scroll.visible = false

	if not skill_tree_canvas or not is_instance_valid(skill_tree_canvas):
		skill_tree_canvas = SkillTreeCanvasScript.new()
		skill_tree_canvas.name = "SkillTreeCanvas"
		skill_tree_canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skill_tree_canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
		skill_tree_canvas.custom_minimum_size = Vector2(0, 360)
		lib_col.add_child(skill_tree_canvas)
		skill_tree_canvas.skill_unlocked.connect(func(_sk):
			_render_cultivation_top_bar()
		)
	else:
		skill_tree_canvas.visible = true
		skill_tree_canvas._update_sp_badge()
		if skill_tree_canvas.selected_skill_key != "":
			skill_tree_canvas.inspect_skill(skill_tree_canvas.selected_skill_key)
		else:
			skill_tree_canvas._update_positions_and_redraw()

func _render_cultivation_proficiencies():
	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	var lib_title = $MainTabs/TabSkills/HBox/LibraryCol/Title
	if lib_title:
		lib_title.text = "Martial Proficiencies & Combat Doctrines"
		lib_title.modulate = UITheme.GOLD_PRIMARY
		lib_title.add_theme_font_size_override("font_size", 12)

	for c in unlocked_skills_box.get_children():
		unlocked_skills_box.remove_child(c)
		c.queue_free()

	# Card 1: Passive Martial Proficiencies
	var prof_card = PanelContainer.new()
	var prof_sb = StyleBoxFlat.new()
	prof_sb.set_corner_radius_all(6)
	prof_sb.bg_color = Color(0.06, 0.08, 0.12, 0.90)
	prof_sb.border_width_left = 1
	prof_sb.border_width_top = 1
	prof_sb.border_width_right = 1
	prof_sb.border_width_bottom = 1
	prof_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
	prof_sb.content_margin_left = 16
	prof_sb.content_margin_right = 16
	prof_sb.content_margin_top = 12
	prof_sb.content_margin_bottom = 12
	prof_card.add_theme_stylebox_override("panel", prof_sb)
	unlocked_skills_box.add_child(prof_card)

	var prof_vb = VBoxContainer.new()
	prof_vb.add_theme_constant_override("separation", 6)
	prof_card.add_child(prof_vb)

	var prof_hdr = Label.new()
	prof_hdr.text = "Passive Martial Proficiencies"
	prof_hdr.add_theme_font_size_override("font_size", 11)
	prof_hdr.modulate = UITheme.GOLD_PRIMARY
	prof_vb.add_child(prof_hdr)

	var prof_lines = [
		"◆ Inner Focus: +10% max aether capacity",
		"◆ Elemental Conductance: +12% technique potency",
		"◆ Aether Recovery: 8 MP regeneration per turn",
		"◆ Martial Reflexes: +8% evasion probability",
		"◆ Leyline Attunement: +5% critical strike multiplier",
		"◆ Resilient Stance: -10% knockback displacement distance",
		"◆ Terra Harmony: +15% poise and stability on reinforced granite arenas"
	]
	for pl in prof_lines:
		var pl_lbl = Label.new()
		pl_lbl.text = pl
		pl_lbl.add_theme_font_size_override("font_size", 9)
		pl_lbl.modulate = Color(0.70, 0.78, 0.88)
		prof_vb.add_child(pl_lbl)

	# Card 2: Form Synergy & Combat Doctrine
	var syn_card = PanelContainer.new()
	var syn_sb = StyleBoxFlat.new()
	syn_sb.set_corner_radius_all(6)
	syn_sb.bg_color = Color(0.05, 0.07, 0.10, 0.90)
	syn_sb.border_width_left = 1
	syn_sb.border_width_top = 1
	syn_sb.border_width_right = 1
	syn_sb.border_width_bottom = 1
	syn_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
	syn_sb.content_margin_left = 16
	syn_sb.content_margin_right = 16
	syn_sb.content_margin_top = 12
	syn_sb.content_margin_bottom = 12
	syn_card.add_theme_stylebox_override("panel", syn_sb)
	unlocked_skills_box.add_child(syn_card)

	var syn_vb = VBoxContainer.new()
	syn_vb.add_theme_constant_override("separation", 6)
	syn_card.add_child(syn_vb)

	var syn_hdr = Label.new()
	syn_hdr.text = "Form Synergy & Combat Doctrine"
	syn_hdr.add_theme_font_size_override("font_size", 11)
	syn_hdr.modulate = UITheme.GOLD_PRIMARY
	syn_vb.add_child(syn_hdr)

	var syn_lines = [
		"◆ Active Formation: Solid Earth Bastion (Frontline anchoring with high stagger resistance)",
		"◆ Combination Rotation: Metal Strike -> Stone Plating (+20% barrier armor gain)",
		"◆ Elemental Counter: Dominates Water & Wind kinetics; vulnerable to Lightning shockwaves",
		"◆ Tactical Advice: Deploy alongside Water ally for conduct suppression and lane control"
	]
	for sl in syn_lines:
		var sl_lbl = Label.new()
		sl_lbl.text = sl
		sl_lbl.add_theme_font_size_override("font_size", 9)
		sl_lbl.modulate = Color(0.70, 0.78, 0.88)
		syn_vb.add_child(sl_lbl)

func _equip_skill(sk: String):
	if cm.equipped_abilities.size() < 4:
		cm.equipped_abilities.append(sk)
	else:
		cm.equipped_abilities[3] = sk
	_refresh_skills_tab()

func _unequip_skill(idx: int):
	if idx < cm.equipped_abilities.size() and cm.equipped_abilities.size() > 1:
		cm.equipped_abilities.remove_at(idx)
		_refresh_skills_tab()


# ══════════════════════════════════════════════════════════════════════════════
#  TAB 3: LADDER & STANDINGS (2-COLUMN MASTER-DETAIL WITH SEARCH & ROSTER)
# ══════════════════════════════════════════════════════════════════════════════

var _ladder_league: String = "city"
var _ladder_mode: String = "teams"    # teams, players
var _ladder_search: String = ""
var _ladder_elem_filter: String = "all"
var _selected_ladder_team_idx: int = 0
var _selected_ladder_player_idx: int = 0

const LADDER_TEAMS_DATA = {
	"bronze": [
		{
			"name": "Phoenix Strikers", "captain": "Ignis", "element": "fire", "rank": 1, "tier": "Bronze",
			"wins": 3, "losses": 0, "points": 90, "playstyle": "Explosive Rushdown & Frontline Flanking",
			"strengths": ["High single-target burst", "Chain shockwaves", "Fast blitz initiations"],
			"weaknesses": ["Water suppression", "Stamina burn"],
			"roster": [
				{"name": "Ignis", "role": "Captain / Striker", "level": 5, "element": "fire", "skill": "Combustion"},
				{"name": "Kora", "role": "Scout / Tactician", "level": 4, "element": "air", "skill": "Gale_Step"},
				{"name": "Gaius", "role": "Defender / Anchor", "level": 4, "element": "earth", "skill": "Stone_Plating"}
			]
		},
		{
			"name": "Hydro Vipers", "captain": "Nami", "element": "water", "rank": 2, "tier": "Bronze",
			"wins": 2, "losses": 1, "points": 60, "playstyle": "Crowd Control & Sustained Attrition",
			"strengths": ["Freeze crowd control", "Sustained hydration healing", "High MP pool"],
			"weaknesses": ["Earth mass disruption", "Fire thermal combustion"],
			"roster": [
				{"name": "Nami", "role": "Captain / Controller", "level": 4, "element": "water", "skill": "Ice"},
				{"name": "Marina", "role": "Medic / Support", "level": 3, "element": "water", "skill": "Aqua_Mend"},
				{"name": "Tide", "role": "Defender", "level": 3, "element": "water", "skill": "Pressure_Wave"}
			]
		},
		{
			"name": "Terra Titans", "captain": "Brock", "element": "earth", "rank": 3, "tier": "Bronze",
			"wins": 1, "losses": 2, "points": 30, "playstyle": "Heavy Fortification & Density Anchors",
			"strengths": ["Highest base HP", "Armor fortification", "Gravity crowd control"],
			"weaknesses": ["Air vacuum strikes", "Water erosion"],
			"roster": [
				{"name": "Brock", "role": "Captain / Defender", "level": 4, "element": "earth", "skill": "Metal"},
				{"name": "Rubble", "role": "Striker", "level": 3, "element": "earth", "skill": "Sand"},
				{"name": "Bismuth", "role": "Anchor", "level": 3, "element": "earth", "skill": "Crystal"}
			]
		},
		{
			"name": "Gale Force", "captain": "Zephyr", "element": "air", "rank": 4, "tier": "Bronze",
			"wins": 0, "losses": 3, "points": 10, "playstyle": "Kiting & Sonic Disruption",
			"strengths": ["Fastest movement", "Sonic ranged kiting", "Displacement"],
			"weaknesses": ["Earth density anchors", "Fire explosive burst"],
			"roster": [
				{"name": "Zephyr", "role": "Captain / Scout", "level": 4, "element": "air", "skill": "Wind"},
				{"name": "Breeze", "role": "Striker", "level": 3, "element": "air", "skill": "Sound_Sonic"},
				{"name": "Aero", "role": "Skirmisher", "level": 3, "element": "air", "skill": "Vacuum"}
			]
		}
	],
	"silver": [
		{
			"name": "Volcano Reapers", "captain": "Drakon", "element": "fire", "rank": 1, "tier": "Silver",
			"wins": 6, "losses": 1, "points": 180, "playstyle": "Magma Assault",
			"strengths": ["Molten hazard tiles", "High burning DoT"],
			"weaknesses": ["Cold freezing locks"],
			"roster": [
				{"name": "Drakon", "role": "Captain / Berserker", "level": 12, "element": "fire", "skill": "Magma"},
				{"name": "Ignis Jr", "role": "Striker", "level": 11, "element": "fire", "skill": "Combustion"},
				{"name": "Cinder", "role": "Support", "level": 10, "element": "fire", "skill": "Thermal_Radiation"}
			]
		},
		{
			"name": "Frost Fang Legion", "captain": "Kallum", "element": "water", "rank": 2, "tier": "Silver",
			"wins": 5, "losses": 2, "points": 150, "playstyle": "Cryo Zone Denial",
			"strengths": ["Permafrost slowing", "Shatter combos"],
			"weaknesses": ["Thermal shock bursts"],
			"roster": [
				{"name": "Kallum", "role": "Captain / Controller", "level": 12, "element": "water", "skill": "Ice"},
				{"name": "Blizzard", "role": "Sniper", "level": 11, "element": "water", "skill": "Flash_Blizzard"},
				{"name": "Sleet", "role": "Defender", "level": 10, "element": "water", "skill": "Aqua_Mend"}
			]
		}
	],
	"gold": [
		{
			"name": "Solar Flare Dynasty", "captain": "Helios", "element": "fire", "rank": 1, "tier": "Gold",
			"wins": 14, "losses": 2, "points": 420, "playstyle": "Photonic Beam Dominance",
			"strengths": ["Extreme range photonic lances", "Blinding flashes"],
			"weaknesses": ["Earth reflection shields"],
			"roster": [
				{"name": "Helios", "role": "Captain / Radiant God", "level": 22, "element": "fire", "skill": "Photonic_Burst"},
				{"name": "Corona", "role": "Artillery", "level": 20, "element": "fire", "skill": "Laser"},
				{"name": "Ray", "role": "Scout", "level": 20, "element": "fire", "skill": "Plasma"}
			]
		}
	],
	"apex": [
		{
			"name": "Shadow Faction", "captain": "Zero (The Rival)", "element": "zero", "rank": 1, "tier": "Apex Boss",
			"wins": 28, "losses": 0, "points": 840, "playstyle": "Null Void & Entropic Unmaking",
			"strengths": ["Unmaking entropy spikes", "Immunity to elemental weakness", "Lethal blitz aggression"],
			"weaknesses": ["Resource depletion", "Point-blank counter-attacks"],
			"roster": [
				{"name": "Zero", "role": "Rival Overlord", "level": 30, "element": "zero", "skill": "Destruction"},
				{"name": "Null", "role": "Void Anchor", "level": 28, "element": "zero", "skill": "Nuclear_Ignition"},
				{"name": "Eclipse", "role": "Assassin", "level": 28, "element": "zero", "skill": "Pressure_Wave"}
			]
		}
	],
	"world": []
}

func _active_league_key() -> String:
	if not cm:
		return "city"
	var keys = ["city", "regional", "national"]
	return keys[clampi(cm.league_tier, 1, keys.size()) - 1]

func _live_player_roster() -> Array:
	var roster: Array = []
	var captain_found = false
	for ally in cm.allies:
		if not (ally is Dictionary) or ally.get("status", "Active") == "Retired":
			continue
		var ally_name = str(ally.get("name", ""))
		if ally_name == "":
			continue
		var is_captain = ally_name.to_lower() == cm.player_name.to_lower()
		captain_found = captain_found or is_captain
		var skills = ally.get("equipped_skills", [])
		var signature = str(skills[0]) if skills is Array and not skills.is_empty() else "Guard"
		roster.append({
			"name": ally_name,
			"role": "Captain / Striker" if is_captain else str(ally.get("archetype", ally.get("role", "Fighter"))),
			"level": int(ally.get("level", 1)),
			"element": str(ally.get("element", cm.player_element)),
			"skill": signature
		})
	if not captain_found:
		roster.push_front({"name": cm.player_name, "role": "Captain / Striker", "level": int(cm.player_level),
			"element": cm.player_element, "skill": str(cm.equipped_abilities[0]) if not cm.equipped_abilities.is_empty() else "Guard"})
	return roster

func _live_ladder_teams(static_teams: Array, summary: Dictionary) -> Array:
	var live_teams: Array = []
	var rows = _season_standings(summary)
	for i in range(rows.size()):
		var row = rows[i]
		var team_name = str(row.get("team", "Club %d" % (i + 1)))
		var template: Dictionary = {}
		for old_team in static_teams:
			if old_team is Dictionary and str(old_team.get("name", "")).to_lower() == team_name.to_lower():
				template = old_team.duplicate(true)
				break
		if template.is_empty():
			var fallback_element = ["fire", "water", "earth", "air"][i % 4]
			template = {"name": team_name, "captain": "Unknown", "element": fallback_element,
				"tier": _active_league_key().capitalize(), "playstyle": "Scouting in progress",
				"strengths": ["Season opponent"], "weaknesses": ["Scout them in battle"], "roster": []}
		if team_name.to_lower() == cm.team_name.to_lower():
			template["captain"] = cm.player_name
			template["element"] = cm.player_element
			template["element_label"] = cm.player_element.capitalize()
			template["roster"] = _live_player_roster()
			template["playstyle"] = "Your club's current squad"
		template["name"] = team_name
		template["scouting_only"] = false
		template["rank"] = i + 1
		template["played"] = int(row.get("played", 0))
		template["wins"] = int(row.get("wins", 0))
		template["draws"] = int(row.get("draws", 0))
		template["losses"] = int(row.get("losses", 0))
		template["score_difference"] = int(row.get("score_difference", 0))
		template["points"] = int(row.get("points", 0))
		live_teams.append(template)
	return live_teams

func _refresh_intel_tab():
	var tab_scroll = $MainTabs/TabIntel
	if tab_scroll is ScrollContainer:
		tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var root_vbox = $MainTabs/TabIntel/VBox
	for c in root_vbox.get_children():
		root_vbox.remove_child(c)
		c.queue_free()

	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	# 1. Top League Selector Bar
	var league_scroll = ScrollContainer.new()
	league_scroll.custom_minimum_size = Vector2(0, 34)
	league_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root_vbox.add_child(league_scroll)
	var league_hb = HBoxContainer.new()
	league_hb.add_theme_constant_override("separation", 8)
	league_scroll.add_child(league_hb)

	var leagues = ScoutingCatalogScript.DIVISIONS

	for l in leagues:
		var btn = Button.new()
		btn.text = l["label"] + (" • Active" if cm and cm.has_team and _active_league_key() == l["id"] else "")
		if cinzel_font:
			btn.add_theme_font_override("font", cinzel_font)
		btn.custom_minimum_size = Vector2(100, 30)
		if _ladder_league == l["id"]:
			_style_tactical_button(btn, Color(0.12, 0.16, 0.24, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75, 1.0), 10, true)
		else:
			_style_secondary_slate_button(btn, 10)
		btn.pressed.connect(func():
			_ladder_league = l["id"]
			_ladder_elem_filter = "all"
			_selected_ladder_team_idx = 0
			_selected_ladder_player_idx = 0
			_refresh_intel_tab()
		)
		league_hb.add_child(btn)

	# 2. Main 2-Column Container
	var main_cols = HBoxContainer.new()
	main_cols.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_cols.add_theme_constant_override("separation", 16)
	root_vbox.add_child(main_cols)

	# LEFT COLUMN: Master List with Search, Filters & Circuit Overview (~520px)
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(500, 480)
	left_col.add_theme_constant_override("separation", 8)
	main_cols.add_child(left_col)

	# Sub-tabs: TEAMS vs PLAYERS
	var mode_hb = HBoxContainer.new()
	mode_hb.add_theme_constant_override("separation", 8)
	left_col.add_child(mode_hb)

	var btn_teams = Button.new()
	btn_teams.text = "National Teams" if _ladder_league == "national_teams" else "Teams Ladder"
	if cinzel_font:
		btn_teams.add_theme_font_override("font", cinzel_font)
	btn_teams.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _ladder_mode == "teams":
		_style_tactical_button(btn_teams, Color(0.12, 0.16, 0.24, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75, 1.0), 11, true)
	else:
		_style_secondary_slate_button(btn_teams, 11)
	btn_teams.pressed.connect(func(): _ladder_mode = "teams"; _refresh_intel_tab())
	mode_hb.add_child(btn_teams)

	var btn_players = Button.new()
	btn_players.text = "Individual Fighters"
	if cinzel_font:
		btn_players.add_theme_font_override("font", cinzel_font)
	btn_players.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if _ladder_mode == "players":
		_style_tactical_button(btn_players, Color(0.12, 0.16, 0.24, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75, 1.0), 11, true)
	else:
		_style_secondary_slate_button(btn_players, 11)
	btn_players.pressed.connect(func(): _ladder_mode = "players"; _refresh_intel_tab())
	mode_hb.add_child(btn_players)

	# Search input & Element Filters
	var search_hb = HBoxContainer.new()
	search_hb.add_theme_constant_override("separation", 6)
	left_col.add_child(search_hb)

	var line_edit = LineEdit.new()
	line_edit.placeholder_text = "Search by team or fighter..."
	line_edit.text = _ladder_search
	line_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line_edit.add_theme_font_size_override("font_size", 10)
	var le_sb = StyleBoxFlat.new()
	le_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	le_sb.border_width_left = 1
	le_sb.border_width_top = 1
	le_sb.border_width_right = 1
	le_sb.border_width_bottom = 1
	le_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
	le_sb.set_corner_radius_all(4)
	le_sb.content_margin_left = 8
	le_sb.content_margin_right = 8
	line_edit.add_theme_stylebox_override("normal", le_sb)
	line_edit.text_changed.connect(func(new_text):
		_ladder_search = new_text.to_lower()
		_refresh_intel_tab()
	)
	search_hb.add_child(line_edit)

	var elem_filters = ["all"] if _ladder_league == "national_teams" else ["all", "fire", "water", "earth", "air"]
	for ef in elem_filters:
		var ef_btn = Button.new()
		ef_btn.text = ef.capitalize()
		ef_btn.custom_minimum_size = Vector2(46, 26)
		if _ladder_elem_filter == ef:
			var e_color = _get_element_color(ef) if ef != "all" else UITheme.GOLD_PRIMARY
			_style_tactical_button(ef_btn, Color(0.12, 0.16, 0.24, 0.98), e_color, Color(1.0, 1.0, 1.0), 9, true)
		else:
			_style_secondary_slate_button(ef_btn, 9)
		ef_btn.pressed.connect(func():
			_ladder_elem_filter = ef
			_refresh_intel_tab()
		)
		search_hb.add_child(ef_btn)

	# Scrollable List Container
	var scroll_list = ScrollContainer.new()
	scroll_list.custom_minimum_size = Vector2(0, 260)
	scroll_list.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_list.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(scroll_list)

	var list_vb = VBoxContainer.new()
	list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_vb.add_theme_constant_override("separation", 6)
	scroll_list.add_child(list_vb)

	# Aggregate Data for Active League
	var raw_teams = ScoutingCatalogScript.teams_for(_ladder_league, cm)
	var season_summary = _get_season_summary()
	var showing_live_season = cm and cm.has_team and bool(season_summary.get("active", false)) and _ladder_league == _active_league_key()
	if showing_live_season:
		raw_teams = _live_ladder_teams(raw_teams, season_summary)

	# RIGHT COLUMN: Detail Dossier (~580px)
	var right_col = PanelContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r_sb = StyleBoxFlat.new()
	r_sb.set_corner_radius_all(6)
	r_sb.bg_color = Color(0.07, 0.09, 0.14, 0.96)
	r_sb.border_width_left = 1
	r_sb.border_width_top = 1
	r_sb.border_width_right = 1
	r_sb.border_width_bottom = 1
	r_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
	right_col.add_theme_stylebox_override("panel", r_sb)
	main_cols.add_child(right_col)

	var r_margin = MarginContainer.new()
	r_margin.add_theme_constant_override("margin_left", 18)
	r_margin.add_theme_constant_override("margin_top", 14)
	r_margin.add_theme_constant_override("margin_right", 18)
	r_margin.add_theme_constant_override("margin_bottom", 14)
	right_col.add_child(r_margin)

	var r_vb = VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 10)
	r_margin.add_child(r_vb)

	if _ladder_mode == "teams":
		var matching_teams = []
		for t in raw_teams:
			if _ladder_search != "" and not _ladder_search in t["name"].to_lower() and not _ladder_search in t["captain"].to_lower():
				continue
			if _ladder_league != "national_teams" and _ladder_elem_filter != "all" and t["element"].to_lower() != _ladder_elem_filter:
				continue
			matching_teams.append(t)

		for i in range(matching_teams.size()):
			var team = matching_teams[i]
			var is_selected = (i == _selected_ladder_team_idx)

			var team_card = PanelContainer.new()
			team_card.custom_minimum_size = Vector2(0, 54)
			var c_sb = StyleBoxFlat.new()
			c_sb.set_corner_radius_all(4)
			c_sb.content_margin_left = 10
			c_sb.content_margin_right = 12
			c_sb.content_margin_top = 6
			c_sb.content_margin_bottom = 6
			if is_selected:
				c_sb.bg_color = Color(0.12, 0.16, 0.24, 0.98)
				c_sb.border_width_left = 3
				c_sb.border_width_top = 1
				c_sb.border_width_right = 1
				c_sb.border_width_bottom = 1
				c_sb.border_color = UITheme.GOLD_PRIMARY
				c_sb.shadow_color = Color(UITheme.GOLD_PRIMARY.r, UITheme.GOLD_PRIMARY.g, UITheme.GOLD_PRIMARY.b, 0.2)
				c_sb.shadow_size = 4
			else:
				c_sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
				c_sb.border_width_left = 1
				c_sb.border_width_top = 1
				c_sb.border_width_right = 1
				c_sb.border_width_bottom = 1
				c_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
			team_card.add_theme_stylebox_override("panel", c_sb)

			var row_hb = HBoxContainer.new()
			row_hb.add_theme_constant_override("separation", 10)
			team_card.add_child(row_hb)

			# Rank badge
			var rank_lbl = Label.new()
			var team_unranked = bool(team.get("scouting_only", false)) or (showing_live_season and int(team.get("played", 0)) == 0)
			rank_lbl.text = "—" if team_unranked else "#%d" % team["rank"]
			rank_lbl.add_theme_font_size_override("font_size", 14)
			var rank_color = Color(0.55, 0.62, 0.72) if team_unranked else (UITheme.GOLD_PRIMARY if team["rank"] == 1 else (Color(0.8, 0.85, 0.95) if team["rank"] == 2 else (Color(0.8, 0.55, 0.35) if team["rank"] == 3 else Color(0.5, 0.55, 0.65))))
			rank_lbl.modulate = rank_color
			rank_lbl.custom_minimum_size = Vector2(30, 0)
			row_hb.add_child(rank_lbl)

			# Captain Avatar
			var av_p = PanelContainer.new()
			av_p.custom_minimum_size = Vector2(38, 38)
			var av_sb = StyleBoxFlat.new()
			av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
			av_sb.set_corner_radius_all(3)
			av_sb.border_width_left = 1
			av_sb.border_width_top = 1
			av_sb.border_width_right = 1
			av_sb.border_width_bottom = 1
			av_sb.border_color = _get_element_color(team["element"])
			av_p.add_theme_stylebox_override("panel", av_sb)

			av_p.add_child(_make_portrait(team["element"]))
			row_hb.add_child(av_p)

			# Team Info
			var info_vb = VBoxContainer.new()
			info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
			info_vb.add_theme_constant_override("separation", 2)
			row_hb.add_child(info_vb)

			var t_name = Label.new()
			t_name.text = team["name"]
			t_name.add_theme_font_size_override("font_size", 11)
			t_name.modulate = Color(1.0, 0.95, 0.85) if is_selected else Color(0.90, 0.92, 0.96)
			info_vb.add_child(t_name)

			var t_sub = Label.new()
			t_sub.text = "Captain: %s • %s" % [team["captain"].capitalize(), team.get("element_label", team["element"].capitalize())]
			t_sub.add_theme_font_size_override("font_size", 8)
			t_sub.modulate = _get_element_color(team["element"])
			info_vb.add_child(t_sub)

			# Record and points chip
			var rec_vb = VBoxContainer.new()
			rec_vb.alignment = BoxContainer.ALIGNMENT_CENTER
			rec_vb.add_theme_constant_override("separation", 2)
			row_hb.add_child(rec_vb)

			var r_lbl = Label.new()
			r_lbl.text = "UNSCOUTED" if team.get("scouting_only", false) else "%dW %dD %dL" % [team["wins"], team.get("draws", 0), team["losses"]]
			r_lbl.add_theme_font_size_override("font_size", 9)
			r_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			r_lbl.modulate = Color(0.40, 0.90, 0.55)
			rec_vb.add_child(r_lbl)

			var pt_lbl = Label.new()
			pt_lbl.text = "—" if team.get("scouting_only", false) else "%d PTS" % team["points"]
			pt_lbl.add_theme_font_size_override("font_size", 9)
			pt_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			pt_lbl.modulate = UITheme.GOLD_PRIMARY
			rec_vb.add_child(pt_lbl)

			# Make clickable via invisible overlay button
			var click_btn = Button.new()
			click_btn.flat = true
			click_btn.focus_mode = Control.FOCUS_NONE
			click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var cur_idx = i
			click_btn.pressed.connect(func():
				_selected_ladder_team_idx = cur_idx
				_intel_view_roster = false
				_refresh_intel_tab()
			)
			team_card.add_child(click_btn)

			list_vb.add_child(team_card)

		# Left Column Footer: Circuit Status & Promotion Directive Card
		var status_card = PanelContainer.new()
		var sc_sb = StyleBoxFlat.new()
		sc_sb.set_corner_radius_all(6)
		sc_sb.bg_color = Color(0.06, 0.08, 0.12, 0.92)
		sc_sb.border_width_left = 1
		sc_sb.border_width_top = 1
		sc_sb.border_width_right = 1
		sc_sb.border_width_bottom = 1
		sc_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
		sc_sb.content_margin_left = 12
		sc_sb.content_margin_right = 12
		sc_sb.content_margin_top = 10
		sc_sb.content_margin_bottom = 10
		status_card.add_theme_stylebox_override("panel", sc_sb)
		left_col.add_child(status_card)

		var sc_vb = VBoxContainer.new()
		sc_vb.add_theme_constant_override("separation", 5)
		status_card.add_child(sc_vb)

		var sc_hdr = Label.new()
		sc_hdr.text = "Live Club Standings" if showing_live_season else ("National Team Directory" if _ladder_league == "national_teams" else "Division Scouting Preview")
		sc_hdr.add_theme_font_size_override("font_size", 10)
		sc_hdr.modulate = UITheme.GOLD_PRIMARY
		sc_vb.add_child(sc_hdr)

		var sc_lines: Array = []
		if showing_live_season:
			var player_standing = _player_standing(season_summary)
			var player_rank = "#%d of %d" % [player_standing.get("rank", 0), player_standing.get("team_count", 0)] if int(player_standing.get("played", 0)) > 0 else "Unranked"
			sc_lines = [
				"Season %d • Month %d/8 • Week %d/32" % [season_summary.get("season_number", 1), season_summary.get("month", 1), season_summary.get("week", 1)],
				"Your club: %s • %d points" % [player_rank, player_standing.get("points", 0)],
				"Standings update after each club fixture",
				"Championship and promotion follow the regular season"
			]
		else:
			sc_lines = ["Call-ups and records are not yet available"] if _ladder_league == "national_teams" else ["Scouting records for this division", "Live standings appear in your active club league"]
		for sl in sc_lines:
			var s_lbl = Label.new()
			s_lbl.text = "◆  %s" % sl
			s_lbl.add_theme_font_size_override("font_size", 8)
			s_lbl.modulate = Color(0.65, 0.72, 0.85)
			sc_vb.add_child(s_lbl)

		# Render Selected Team Dossier in Right Column
		if matching_teams.size() > 0:
			var sel_team = matching_teams[min(_selected_ladder_team_idx, matching_teams.size() - 1)]

			# Header Row
			var d_top_hb = HBoxContainer.new()
			d_top_hb.add_theme_constant_override("separation", 10)
			r_vb.add_child(d_top_hb)

			var d_title = Label.new()
			d_title.text = sel_team["name"]
			d_title.add_theme_font_size_override("font_size", 16)
			d_title.modulate = Color(1.0, 0.95, 0.85)
			d_top_hb.add_child(d_title)

			# Tier pill
			var tp = PanelContainer.new()
			var tp_sb = StyleBoxFlat.new()
			tp_sb.set_corner_radius_all(10)
			tp_sb.bg_color = Color(0.06, 0.08, 0.12, 0.9)
			tp_sb.border_width_left = 1
			tp_sb.border_width_top = 1
			tp_sb.border_width_right = 1
			tp_sb.border_width_bottom = 1
			tp_sb.border_color = UITheme.GOLD_PRIMARY
			tp_sb.content_margin_left = 8
			tp_sb.content_margin_right = 8
			tp.add_theme_stylebox_override("panel", tp_sb)
			var tl = Label.new()
			tl.text = "Tier: %s" % sel_team["tier"].capitalize()
			tl.add_theme_font_size_override("font_size", 8)
			tl.modulate = UITheme.GOLD_PRIMARY
			tp.add_child(tl)
			d_top_hb.add_child(tp)

			var d_stats = Label.new()
			var standing_label = "Unranked" if showing_live_season and int(sel_team.get("played", 0)) == 0 else "#%d (%d PTS)" % [sel_team["rank"], sel_team["points"]]
			d_stats.text = "Captain: %s (%s)  |  Scouting profile; no official result yet" % [sel_team["captain"], sel_team.get("element_label", sel_team["element"].capitalize())] if sel_team.get("scouting_only", false) else "Captain: %s (%s)  |  %dW %dD %dL  |  %s" % [
				sel_team["captain"].capitalize(), sel_team["element"].capitalize(),
				sel_team["wins"], sel_team.get("draws", 0), sel_team["losses"], standing_label
			]
			d_stats.add_theme_font_size_override("font_size", 10)
			d_stats.modulate = Color(0.4, 0.85, 1.0)
			r_vb.add_child(d_stats)

			if not _intel_view_roster:
				# --- 1. TACTICAL OVERVIEW (5 CORE QUESTIONS) ---
				# Tactical Playstyle & Doctrine Card
				var doc_card = PanelContainer.new()
				var doc_sb = StyleBoxFlat.new()
				doc_sb.set_corner_radius_all(4)
				doc_sb.bg_color = Color(0.05, 0.07, 0.10, 0.85)
				doc_sb.border_width_left = 1
				doc_sb.border_width_top = 1
				doc_sb.border_width_right = 1
				doc_sb.border_width_bottom = 1
				doc_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
				doc_sb.content_margin_left = 14
				doc_sb.content_margin_right = 14
				doc_sb.content_margin_top = 10
				doc_sb.content_margin_bottom = 10
				doc_card.add_theme_stylebox_override("panel", doc_sb)
				r_vb.add_child(doc_card)

				var doc_vb = VBoxContainer.new()
				doc_vb.add_theme_constant_override("separation", 6)
				doc_card.add_child(doc_vb)

				var doc_hdr = Label.new()
				doc_hdr.text = "Tactical Playstyle & Doctrine: %s" % sel_team["playstyle"]
				doc_hdr.add_theme_font_size_override("font_size", 10)
				doc_hdr.modulate = UITheme.GOLD_PRIMARY
				doc_vb.add_child(doc_hdr)

				var sw_hb = HBoxContainer.new()
				sw_hb.add_theme_constant_override("separation", 16)
				doc_vb.add_child(sw_hb)

				var s_vb = VBoxContainer.new()
				s_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				s_vb.add_theme_constant_override("separation", 3)
				sw_hb.add_child(s_vb)

				var s_hdr = Label.new()
				s_hdr.text = "Key Strengths:"
				s_hdr.add_theme_font_size_override("font_size", 9)
				s_hdr.modulate = Color(0.40, 0.85, 0.55)
				s_vb.add_child(s_hdr)

				for st in sel_team["strengths"]:
					var l = Label.new()
					l.text = "•  %s" % st
					l.add_theme_font_size_override("font_size", 8)
					l.modulate = Color(0.85, 0.92, 0.98)
					s_vb.add_child(l)

				var w_vb = VBoxContainer.new()
				w_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				w_vb.add_theme_constant_override("separation", 3)
				sw_hb.add_child(w_vb)

				var w_hdr = Label.new()
				w_hdr.text = "Vulnerabilities & Counters:"
				w_hdr.add_theme_font_size_override("font_size", 9)
				w_hdr.modulate = Color(0.95, 0.45, 0.45)
				w_vb.add_child(w_hdr)

				for wk in sel_team["weaknesses"]:
					var l = Label.new()
					l.text = "•  %s" % wk
					l.add_theme_font_size_override("font_size", 8)
					l.modulate = Color(0.85, 0.92, 0.98)
					w_vb.add_child(l)

				# Coach Briefing and Scrimmage Launcher
				var coach_card = PanelContainer.new()
				var cc_sb = StyleBoxFlat.new()
				cc_sb.set_corner_radius_all(4)
				cc_sb.bg_color = Color(0.05, 0.07, 0.10, 0.85)
				cc_sb.border_width_left = 1
				cc_sb.border_width_top = 1
				cc_sb.border_width_right = 1
				cc_sb.border_width_bottom = 1
				cc_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
				cc_sb.content_margin_left = 14
				cc_sb.content_margin_right = 14
				cc_sb.content_margin_top = 10
				cc_sb.content_margin_bottom = 10
				coach_card.add_theme_stylebox_override("panel", cc_sb)
				r_vb.add_child(coach_card)

				var cc_vb = VBoxContainer.new()
				cc_vb.add_theme_constant_override("separation", 6)
				coach_card.add_child(cc_vb)

				var cc_hdr = Label.new()
				cc_hdr.text = "Scout Analysis & Tactical Countermeasures"
				cc_hdr.add_theme_font_size_override("font_size", 10)
				cc_hdr.modulate = UITheme.GOLD_PRIMARY
				cc_vb.add_child(cc_hdr)

				var cc_desc = Label.new()
				cc_desc.text = "National selection and international fixtures are not yet playable." if _ladder_league == "national_teams" else "Advice: Exploit element weaknesses during deployment. Position heavy anchors against their captain to absorb rushdown."
				cc_desc.add_theme_font_size_override("font_size", 8)
				cc_desc.modulate = Color(0.80, 0.88, 0.95)
				cc_vb.add_child(cc_desc)

				var scrim_btn = Button.new()
				var scheduled_match = cm.get_next_scheduled_match()
				var is_next_opponent = str(scheduled_match.get("enemy_team", "")).to_lower() == str(sel_team["name"]).to_lower()
				scrim_btn.text = "National fixtures coming later" if _ladder_league == "national_teams" else ("Prepare for Scheduled Match" if is_next_opponent else "No Scheduled Match vs This Club")
				scrim_btn.custom_minimum_size = Vector2(0, 32)
				scrim_btn.disabled = not is_next_opponent or (scheduled_match.has("season_day") and not cm.can_play_next_match())
				_style_secondary_slate_button(scrim_btn, 10)
				scrim_btn.pressed.connect(func():
					_pending_deployment_match.clear()
					cm.prepare_match(str(scheduled_match.get("match_type", "tournament")),
						str(scheduled_match.get("enemy_element", "water")),
						str(scheduled_match.get("enemy_captain", "Opponent")),
						str(scheduled_match.get("enemy_team", "Rival Club")))
					_switch_tab(2)
				)
				cc_vb.add_child(scrim_btn)

				# Prominent Full Athlete Roster Toggle Button
				var btn_toggle_roster = Button.new()
				btn_toggle_roster.text = "Roster not yet scouted" if sel_team["roster"].is_empty() else "View Full Roster & Athlete Intel (%d Combatants) →" % sel_team["roster"].size()
				btn_toggle_roster.custom_minimum_size = Vector2(0, 36)
				btn_toggle_roster.disabled = sel_team["roster"].is_empty()
				_style_tactical_button(btn_toggle_roster, Color(0.10, 0.14, 0.22, 0.95), UITheme.GOLD_PRIMARY, Color(1.0, 0.92, 0.75), 10, true)
				btn_toggle_roster.pressed.connect(func():
					_intel_view_roster = true
					_refresh_intel_tab()
				)
				r_vb.add_child(btn_toggle_roster)

			else:
				# --- 2. FULL ATHLETE ROSTER VIEW ---
				var roster_nav_hb = HBoxContainer.new()
				roster_nav_hb.add_theme_constant_override("separation", 10)
				r_vb.add_child(roster_nav_hb)

				var btn_back = Button.new()
				btn_back.text = "← Back to Tactical Overview"
				btn_back.custom_minimum_size = Vector2(200, 30)
				_style_secondary_slate_button(btn_back, 10)
				btn_back.pressed.connect(func():
					_intel_view_roster = false
					_refresh_intel_tab()
				)
				roster_nav_hb.add_child(btn_back)

				var r_nav_title = Label.new()
				r_nav_title.text = "Official Squad Members & Scouting Dossier"
				r_nav_title.add_theme_font_size_override("font_size", 10)
				r_nav_title.modulate = UITheme.GOLD_PRIMARY
				roster_nav_hb.add_child(r_nav_title)

				var r_scroll = ScrollContainer.new()
				r_scroll.custom_minimum_size = Vector2(0, 300)
				r_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
				r_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
				r_vb.add_child(r_scroll)

				var r_list_vb = VBoxContainer.new()
				r_list_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				r_list_vb.add_theme_constant_override("separation", 8)
				r_scroll.add_child(r_list_vb)

				for member in sel_team["roster"]:
					var m_card = PanelContainer.new()
					m_card.custom_minimum_size = Vector2(0, 54)
					var m_sb = StyleBoxFlat.new()
					m_sb.set_corner_radius_all(4)
					m_sb.content_margin_left = 12
					m_sb.content_margin_right = 12
					m_sb.content_margin_top = 6
					m_sb.content_margin_bottom = 6
					m_sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
					m_sb.border_width_left = 3
					m_sb.border_color = _get_element_color(member["element"])
					m_card.add_theme_stylebox_override("panel", m_sb)

					var m_hb = HBoxContainer.new()
					m_hb.add_theme_constant_override("separation", 10)
					m_card.add_child(m_hb)

					# Member avatar
					var m_av = PanelContainer.new()
					m_av.custom_minimum_size = Vector2(40, 40)
					var m_av_sb = StyleBoxFlat.new()
					m_av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
					m_av_sb.set_corner_radius_all(3)
					m_av_sb.border_width_left = 1
					m_av_sb.border_width_top = 1
					m_av_sb.border_width_right = 1
					m_av_sb.border_width_bottom = 1
					m_av_sb.border_color = _get_element_color(member["element"])
					m_av.add_theme_stylebox_override("panel", m_av_sb)

					m_av.add_child(_make_portrait(member["element"]))
					m_hb.add_child(m_av)

					var m_info_vb = VBoxContainer.new()
					m_info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
					m_info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
					m_info_vb.add_theme_constant_override("separation", 2)
					m_hb.add_child(m_info_vb)

					var m_name_lbl = Label.new()
					m_name_lbl.text = member["name"]
					m_name_lbl.add_theme_font_size_override("font_size", 11)
					m_name_lbl.modulate = Color(0.95, 0.95, 1.0)
					m_info_vb.add_child(m_name_lbl)

					var m_sub_lbl = Label.new()
					m_sub_lbl.text = "Lv. %d %s  |  Role: %s" % [member["level"], member["element"].capitalize(), member["role"]]
					m_sub_lbl.add_theme_font_size_override("font_size", 9)
					m_sub_lbl.modulate = _get_element_color(member["element"])
					m_info_vb.add_child(m_sub_lbl)

					var sk_pill = PanelContainer.new()
					sk_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
					var sk_sb = StyleBoxFlat.new()
					sk_sb.set_corner_radius_all(3)
					sk_sb.bg_color = Color(0.04, 0.06, 0.09, 0.9)
					sk_sb.content_margin_left = 8
					sk_sb.content_margin_right = 8
					sk_sb.content_margin_top = 4
					sk_sb.content_margin_bottom = 4
					sk_pill.add_theme_stylebox_override("panel", sk_sb)

					var sk_lbl = Label.new()
					sk_lbl.text = "Signature: %s" % member["skill"]
					sk_lbl.add_theme_font_size_override("font_size", 8)
					sk_lbl.modulate = Color(1.0, 0.85, 0.4)
					sk_pill.add_child(sk_lbl)
					m_hb.add_child(sk_pill)

					r_list_vb.add_child(m_card)

				var btn_back_bottom = Button.new()
				btn_back_bottom.text = "← Back to Tactical Overview"
				btn_back_bottom.custom_minimum_size = Vector2(0, 32)
				_style_secondary_slate_button(btn_back_bottom, 10)
				btn_back_bottom.pressed.connect(func():
					_intel_view_roster = false
					_refresh_intel_tab()
				)
				r_vb.add_child(btn_back_bottom)

	else:
		# Render Individual Players List
		var all_players = []
		for t in raw_teams:
			for m in t["roster"]:
				var p_entry = m.duplicate()
				p_entry["team_name"] = t["name"]
				all_players.append(p_entry)

		var matching_players = []
		for p in all_players:
			if _ladder_search != "" and not _ladder_search in p["name"].to_lower() and not _ladder_search in p["team_name"].to_lower():
				continue
			if _ladder_elem_filter != "all" and p["element"].to_lower() != _ladder_elem_filter:
				continue
			matching_players.append(p)

		for i in range(matching_players.size()):
			var p = matching_players[i]
			var is_selected = (i == _selected_ladder_player_idx)

			var p_card = PanelContainer.new()
			p_card.custom_minimum_size = Vector2(0, 50)
			var c_sb = StyleBoxFlat.new()
			c_sb.set_corner_radius_all(4)
			c_sb.content_margin_left = 10
			c_sb.content_margin_right = 12
			c_sb.content_margin_top = 6
			c_sb.content_margin_bottom = 6
			if is_selected:
				c_sb.bg_color = Color(0.12, 0.16, 0.24, 0.98)
				c_sb.border_width_left = 3
				c_sb.border_width_top = 1
				c_sb.border_width_right = 1
				c_sb.border_width_bottom = 1
				c_sb.border_color = UITheme.GOLD_PRIMARY
			else:
				c_sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
				c_sb.border_width_left = 1
				c_sb.border_width_top = 1
				c_sb.border_width_right = 1
				c_sb.border_width_bottom = 1
				c_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
			p_card.add_theme_stylebox_override("panel", c_sb)

			var row_hb = HBoxContainer.new()
			row_hb.add_theme_constant_override("separation", 10)
			p_card.add_child(row_hb)

			var av_p = PanelContainer.new()
			av_p.custom_minimum_size = Vector2(36, 36)
			var av_sb = StyleBoxFlat.new()
			av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
			av_sb.set_corner_radius_all(3)
			av_sb.border_width_left = 1
			av_sb.border_width_top = 1
			av_sb.border_width_right = 1
			av_sb.border_width_bottom = 1
			av_sb.border_color = _get_element_color(p["element"])
			av_p.add_theme_stylebox_override("panel", av_sb)

			av_p.add_child(_make_portrait(p["element"]))
			row_hb.add_child(av_p)

			var info_vb = VBoxContainer.new()
			info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
			info_vb.add_theme_constant_override("separation", 2)
			row_hb.add_child(info_vb)

			var p_name = Label.new()
			p_name.text = p["name"]
			p_name.add_theme_font_size_override("font_size", 11)
			p_name.modulate = Color(1.0, 0.95, 0.85) if is_selected else Color(0.90, 0.92, 0.96)
			info_vb.add_child(p_name)

			var p_sub = Label.new()
			p_sub.text = "%s  •  Lv. %d %s %s" % [p["team_name"], p["level"], p["element"].capitalize(), p["role"]]
			p_sub.add_theme_font_size_override("font_size", 8)
			p_sub.modulate = _get_element_color(p["element"])
			info_vb.add_child(p_sub)

			var click_btn = Button.new()
			click_btn.flat = true
			click_btn.focus_mode = Control.FOCUS_NONE
			click_btn.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			var cur_p_idx = i
			click_btn.pressed.connect(func():
				_selected_ladder_player_idx = cur_p_idx
				_refresh_intel_tab()
			)
			p_card.add_child(click_btn)

			list_vb.add_child(p_card)

		if matching_players.size() > 0:
			var sel_p = matching_players[min(_selected_ladder_player_idx, matching_players.size() - 1)]

			var p_title = Label.new()
			p_title.text = "%s (%s)" % [sel_p["name"], sel_p["team_name"]]
			p_title.add_theme_font_size_override("font_size", 16)
			p_title.modulate = Color(0.98, 0.88, 0.52)
			r_vb.add_child(p_title)

			var p_meta = Label.new()
			p_meta.text = "Element: %s  |  Level: %d  |  Role: %s  |  Signature: %s" % [
				sel_p["element"].capitalize(), sel_p["level"], sel_p["role"], sel_p["skill"]
			]
			p_meta.add_theme_font_size_override("font_size", 10)
			p_meta.modulate = Color(0.4, 0.85, 1.0)
			r_vb.add_child(p_meta)

			var p_panel = PanelContainer.new()
			var pp_sb = StyleBoxFlat.new()
			pp_sb.set_corner_radius_all(4)
			pp_sb.bg_color = Color(0.08, 0.10, 0.16, 0.90)
			pp_sb.content_margin_left = 12
			pp_sb.content_margin_right = 12
			pp_sb.content_margin_top = 8
			pp_sb.content_margin_bottom = 8
			p_panel.add_theme_stylebox_override("panel", pp_sb)
			r_vb.add_child(p_panel)

			var p_stats = Label.new()
			p_stats.text = "Combat Attributes\nSpeed: %d Tiles  •  Agility: %d EVA  •  Dexterity: %d CRT\nStamina: %d STA  •  Mana: %d MP  •  Potency: %d ATK" % [
				3 + (sel_p["level"] / 8), 26 + (sel_p["level"] * 2), 30 + (sel_p["level"] * 2),
				100 + (sel_p["level"] * 5), 100 + (sel_p["level"] * 5), 30 + (sel_p["level"] * 3)
			]
			p_stats.add_theme_font_size_override("font_size", 10)
			p_stats.modulate = Color(0.9, 0.95, 1.0)
			p_panel.add_child(p_stats)


# ══════════════════════════════════════════════════════════════════════════════
#  TAB 2: BATTLE DEPLOYMENT WORKBENCH (INTERACTIVE 6X6 MAP — NO POPUP!)
# ══════════════════════════════════════════════════════════════════════════════

var _battle_selected_ally_idx: int = 0

func _refresh_battle_tab():
	var tab_scroll = $MainTabs/TabBattle
	if tab_scroll is ScrollContainer:
		tab_scroll.follow_focus = false
		tab_scroll.scroll_horizontal = 0
		tab_scroll.scroll_vertical = 0
		tab_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		tab_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var tab_b = $MainTabs/TabBattle/VB
	for c in tab_b.get_children():
		tab_b.remove_child(c)
		c.queue_free()

	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	# Top Header Bar
	var hb_top = HBoxContainer.new()
	tab_b.add_child(hb_top)

	var title_vb = VBoxContainer.new()
	title_vb.add_theme_constant_override("separation", 2)
	hb_top.add_child(title_vb)

	var title_lbl = Label.new()
	title_lbl.text = "Tactical Deployment Workbench"
	title_lbl.add_theme_font_size_override("font_size", 14)
	title_lbl.modulate = UITheme.GOLD_PRIMARY
	title_vb.add_child(title_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "18x10 Arena Platform  |  Tactical Squad Formation"
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.modulate = UITheme.TEXT_MUTED
	title_vb.add_child(sub_lbl)

	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb_top.add_child(spacer)

	var next_m = _get_deployment_match()
	var has_scheduled_match = not next_m.is_empty()

	var target_panel = PanelContainer.new()
	var target_sb = StyleBoxFlat.new()
	target_sb.bg_color = Color(0.08, 0.11, 0.18, 0.95)
	target_sb.border_width_left = 1
	target_sb.border_width_top = 1
	target_sb.border_width_right = 1
	target_sb.border_width_bottom = 1
	target_sb.border_color = Color(0.25, 0.35, 0.50, 0.6)
	target_sb.set_corner_radius_all(4)
	target_sb.content_margin_left = 12
	target_sb.content_margin_right = 12
	target_sb.content_margin_top = 6
	target_sb.content_margin_bottom = 6
	target_panel.add_theme_stylebox_override("panel", target_sb)
	hb_top.add_child(target_panel)

	var target_hb = HBoxContainer.new()
	target_hb.add_theme_constant_override("separation", 8)
	target_panel.add_child(target_hb)

	var target_tag = Label.new()
	target_tag.text = "Scheduled Rival: %s (%s) • %s" % [
		next_m.get("enemy_captain", "Opponent").capitalize(),
		next_m.get("enemy_element", "water").capitalize(),
		next_m.get("enemy_team", "Rival Club")
	] if has_scheduled_match else "No match scheduled • Return to the club calendar"
	target_tag.add_theme_font_size_override("font_size", 10)
	target_tag.modulate = Color(0.4, 0.85, 1.0)
	target_hb.add_child(target_tag)

	# Main 2-Column Section: Left = 18x10 Arena Platform, Right = Squad Manager & Skill Editor
	var main_hb = HBoxContainer.new()
	main_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_hb.add_theme_constant_override("separation", 12)
	tab_b.add_child(main_hb)

	# LEFT: 18x10 Authentic Arena Platform (612x340 Platform + Padding)
	var map_panel = PanelContainer.new()
	map_panel.custom_minimum_size = Vector2(624, 400)
	var map_sb = StyleBoxFlat.new()
	map_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	map_sb.border_width_left = 1
	map_sb.border_width_top = 1
	map_sb.border_width_right = 1
	map_sb.border_width_bottom = 1
	map_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
	map_sb.set_corner_radius_all(6)
	map_sb.content_margin_left = 6
	map_sb.content_margin_right = 6
	map_sb.content_margin_top = 6
	map_sb.content_margin_bottom = 6
	map_panel.add_theme_stylebox_override("panel", map_sb)
	main_hb.add_child(map_panel)

	var map_vb = VBoxContainer.new()
	map_vb.add_theme_constant_override("separation", 6)
	map_panel.add_child(map_vb)

	# Arena Platform Header Strip with tactical zone indicators
	var map_hdr_hb = HBoxContainer.new()
	map_vb.add_child(map_hdr_hb)

	var map_hdr_lbl = Label.new()
	map_hdr_lbl.text = "Arena Combat Platform"
	map_hdr_lbl.add_theme_font_size_override("font_size", 10)
	map_hdr_lbl.modulate = UITheme.GOLD_PRIMARY
	map_hdr_hb.add_child(map_hdr_lbl)

	var map_spacer = Control.new()
	map_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	map_hdr_hb.add_child(map_spacer)

	var zone_info = Label.new()
	zone_info.text = "Allied (Cols 1-5)  |  Midfield (Col 6)  |  Opponent (Cols 7-11)"
	zone_info.add_theme_font_size_override("font_size", 8)
	zone_info.modulate = Color(0.65, 0.75, 0.90)
	map_hdr_hb.add_child(zone_info)

	# Arena Platform Frame with matching match background (612x340)
	var arena_stage_frame = MarginContainer.new()
	arena_stage_frame.custom_minimum_size = Vector2(612, 340)
	arena_stage_frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	map_vb.add_child(arena_stage_frame)

	# 1. Background Arena Floor Texture (res://assets/arena_floor.png)
	var floor_tex = load("res://assets/arena_floor.png")
	if floor_tex:
		var floor_bg = TextureRect.new()
		floor_bg.texture = floor_tex
		floor_bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		floor_bg.stretch_mode = TextureRect.STRETCH_SCALE
		floor_bg.custom_minimum_size = Vector2(612, 340)
		arena_stage_frame.add_child(floor_bg)

	# 2. Overlaid 18x10 Interactive Grid
	var grid_ui = GridContainer.new()
	grid_ui.columns = 18
	grid_ui.custom_minimum_size = Vector2(612, 340)
	grid_ui.add_theme_constant_override("h_separation", 0)
	grid_ui.add_theme_constant_override("v_separation", 0)
	arena_stage_frame.add_child(grid_ui)

	# Resolve Enemy Squad positions matching World.gd combat spawning
	var enemy_coords = {}
	var cap_name = next_m.get("enemy_captain", "Nami")
	var cap_elem = next_m.get("enemy_element", "water")

	if cm.active_match_format == "1v1":
		enemy_coords[Vector2i(7, 4)] = {"name": cap_name, "element": cap_elem}
	elif cm.active_match_format == "5v5":
		enemy_coords[Vector2i(7, 4)] = {"name": cap_name, "element": cap_elem}
		enemy_coords[Vector2i(8, 3)] = {"name": "Scout", "element": "air"}
		enemy_coords[Vector2i(8, 5)] = {"name": "Anchor", "element": "earth"}
		enemy_coords[Vector2i(9, 4)] = {"name": "Vanguard", "element": "fire"}
		enemy_coords[Vector2i(9, 2)] = {"name": "Artillery", "element": "water"}
	else: # 3v3 default
		enemy_coords[Vector2i(7, 4)] = {"name": cap_name, "element": cap_elem}
		enemy_coords[Vector2i(8, 3)] = {"name": "Scout", "element": "air"}
		enemy_coords[Vector2i(8, 5)] = {"name": "Anchor", "element": "earth"}

	# Ensure cm.starting_formation has positions for allies and coords are Vector2i:
	if cm.starting_formation.is_empty():
		cm.starting_formation[cm.player_name] = Vector2i(3, 4)
		if cm.allies.size() > 1:
			cm.starting_formation[cm.allies[1]["name"]] = Vector2i(2, 3)
		if cm.allies.size() > 2:
			cm.starting_formation[cm.allies[2]["name"]] = Vector2i(2, 5)
	else:
		for k in cm.starting_formation.keys():
			if k != "type" and not (cm.starting_formation[k] is Vector2i):
				if cm.has_method("parse_vector2i"):
					cm.starting_formation[k] = cm.parse_vector2i(cm.starting_formation[k])
				elif cm.starting_formation[k] is String:
					var s = cm.starting_formation[k].replace("(", "").replace(")", "").strip_edges()
					var p = s.split(",")
					if p.size() >= 2:
						cm.starting_formation[k] = Vector2i(int(p[0].strip_edges()), int(p[1].strip_edges()))

	# Validate selected ally index using active roster
	var b_roster = _get_active_roster()
	_battle_selected_ally_idx = clampi(_battle_selected_ally_idx, 0, max(0, b_roster.size() - 1))
	var sel_ally_name = b_roster[_battle_selected_ally_idx]["name"]

	# Build 18 columns x 10 rows (180 tiles total)
	for row in range(10):
		for col in range(18):
			var tile_coord = Vector2i(col, row)
			var tile_node = load("res://scripts/tactical_workbench_tile.gd").new()
			tile_node.tile_coord = tile_coord

			# Check if ally placed here
			var ally_placed = ""
			var ally_elem = ""
			for a in b_roster:
				var pos = cm.starting_formation.get(a["name"], Vector2i(-1, -1))
				if pos is Vector2i and pos == tile_coord and pos != Vector2i(-1, -1):
					ally_placed = a["name"]
					ally_elem = a.get("element", "fire")
					break

			# Check if player deployable zone: columns 1..5, rows 1..8
			var is_player_zone = (col >= 1 and col <= 5 and row >= 1 and row <= 8)

			if is_player_zone:
				if ally_placed != "":
					tile_node.setup_ally(ally_placed, ally_elem, ally_placed == sel_ally_name)
				else:
					tile_node.setup_empty_player_zone(tile_coord)

				# Click to Select / Move / Swap
				tile_node.tile_clicked.connect(func(clicked_coord: Vector2i):
					if tile_node.ally_name != "":
						for idx in range(b_roster.size()):
							if b_roster[idx]["name"] == tile_node.ally_name:
								_battle_selected_ally_idx = idx
								break
						_refresh_battle_tab()
					else:
						var active_ally = b_roster[_battle_selected_ally_idx]["name"]
						for other in cm.starting_formation.keys():
							var pos_other = cm.starting_formation[other]
							if pos_other is Vector2i and pos_other == clicked_coord:
								cm.starting_formation[other] = cm.starting_formation.get(active_ally, Vector2i(-1, -1))
								break
						cm.starting_formation[active_ally] = clicked_coord
						_refresh_battle_tab()
				)

				# Drop to Move / Swap via Drag-and-Drop
				tile_node.ally_dropped.connect(func(dropped_name: String, target_coord: Vector2i):
					if dropped_name == "": return
					var old_pos = cm.starting_formation.get(dropped_name, Vector2i(-1, -1))
					if not (old_pos is Vector2i):
						old_pos = Vector2i(-1, -1)
					for other in cm.starting_formation.keys():
						var other_pos = cm.starting_formation[other]
						if other_pos is Vector2i and other_pos == target_coord and other != dropped_name:
							cm.starting_formation[other] = old_pos
							break
					cm.starting_formation[dropped_name] = target_coord
					_refresh_battle_tab()
				)

			elif enemy_coords.has(tile_coord):
				var e_info = enemy_coords[tile_coord]
				tile_node.setup_enemy(e_info["name"], e_info["element"])

			elif col == 6 and row >= 1 and row <= 8:
				var h_tag = ""
				if row == 2 or row == 7:
					h_tag = "Surge"
				elif row == 4 or row == 5:
					h_tag = "Cover"
				tile_node.setup_neutral_or_hazard(tile_coord, h_tag)

			else:
				tile_node.setup_neutral_or_hazard(tile_coord, "")

			grid_ui.add_child(tile_node)

	# Tactical Venue Info footer below Arena Floor
	var info_hb = HBoxContainer.new()
	info_hb.add_theme_constant_override("separation", 8)
	map_vb.add_child(info_hb)

	var lbl_venue = Label.new()
	lbl_venue.text = "Venue: Grand Coliseum (18x10)  •  Directives: Cardinal Strikes Only  •  Terrain: Reinforced Granite"
	lbl_venue.add_theme_font_size_override("font_size", 8)
	lbl_venue.modulate = Color(0.5, 0.65, 0.85)
	info_hb.add_child(lbl_venue)

	# RIGHT: Squad Manager & Inspector (~470px)
	var right_col = VBoxContainer.new()
	right_col.custom_minimum_size = Vector2(470, 0)
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_col.add_theme_constant_override("separation", 6)
	main_hb.add_child(right_col)

	# 1. Format Selector
	var fmt_panel = PanelContainer.new()
	var fmt_sb = StyleBoxFlat.new()
	fmt_sb.set_corner_radius_all(4)
	fmt_sb.content_margin_left = 8
	fmt_sb.content_margin_right = 8
	fmt_sb.content_margin_top = 4
	fmt_sb.content_margin_bottom = 4
	fmt_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	fmt_sb.border_width_left = 1
	fmt_sb.border_width_top = 1
	fmt_sb.border_width_right = 1
	fmt_sb.border_width_bottom = 1
	fmt_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
	fmt_panel.add_theme_stylebox_override("panel", fmt_sb)
	right_col.add_child(fmt_panel)

	var fmt_vb = VBoxContainer.new()
	fmt_vb.add_theme_constant_override("separation", 4)
	fmt_panel.add_child(fmt_vb)

	# Count deployed
	var deployed_count = 0
	for a in b_roster:
		var pos = cm.starting_formation.get(a["name"], Vector2i(-1, -1))
		if pos is Vector2i and pos != Vector2i(-1, -1):
			deployed_count += 1

	var target_count = 1 if cm.active_match_format == "1v1" else (3 if cm.active_match_format == "3v3" else 5)

	var fmt_hdr_hb = HBoxContainer.new()
	fmt_vb.add_child(fmt_hdr_hb)

	var fmt_hdr = Label.new()
	fmt_hdr.text = "1. Match Format & Rules"
	fmt_hdr.add_theme_font_size_override("font_size", 10)
	fmt_hdr.modulate = UITheme.GOLD_PRIMARY
	fmt_hdr_hb.add_child(fmt_hdr)

	var fmt_sp = Control.new()
	fmt_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fmt_hdr_hb.add_child(fmt_sp)

	var fmt_count_lbl = Label.new()
	fmt_count_lbl.text = "Deployed: %d / %d Target" % [deployed_count, target_count]
	fmt_count_lbl.add_theme_font_size_override("font_size", 8)
	fmt_count_lbl.modulate = Color(0.5, 0.85, 0.6) if deployed_count == target_count else Color(0.95, 0.75, 0.35)
	fmt_hdr_hb.add_child(fmt_count_lbl)

	var fmt_hb = HBoxContainer.new()
	fmt_hb.add_theme_constant_override("separation", 6)
	fmt_vb.add_child(fmt_hb)

	var f_options = [
		{"id": "1v1", "name": "1v1 Duel", "req_team": false},
		{"id": "3v3", "name": "3v3 Trio", "req_team": true},
		{"id": "5v5", "name": "5v5 Squad", "req_team": true}
	]
	for fo in f_options:
		var f_btn = Button.new()
		var is_locked = (fo["req_team"] and not cm.has_team)
		if is_locked:
			f_btn.text = fo["name"] + " (Locked)"
			f_btn.tooltip_text = "Join a team in the Street Circuit to unlock team battles."
			f_btn.disabled = true
			_style_secondary_slate_button(f_btn, 8)
			f_btn.add_theme_color_override("font_color", Color(0.4, 0.45, 0.55))
		else:
			f_btn.text = fo["name"]
			if cinzel_font:
				f_btn.add_theme_font_override("font", cinzel_font)
			if cm.active_match_format == fo["id"]:
				_style_tactical_button(f_btn, Color(0.12, 0.16, 0.24, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75, 1.0), 9, true)
			else:
				_style_secondary_slate_button(f_btn, 9)
			f_btn.pressed.connect(func():
				cm.active_match_format = fo["id"]
				_refresh_battle_tab()
			)
		f_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		f_btn.custom_minimum_size = Vector2(0, 24)
		fmt_hb.add_child(f_btn)

	# 2. Squad Members Lineup (Cards with live avatar, Drag-in / Drag-out & Bench Drop Zone)
	var squad_lbl = Label.new()
	squad_lbl.text = "2. Squad Lineup (Drag to Grid or Click to Inspect)"
	squad_lbl.add_theme_font_size_override("font_size", 10)
	squad_lbl.modulate = UITheme.GOLD_PRIMARY
	right_col.add_child(squad_lbl)

	var squad_hb = HBoxContainer.new()
	squad_hb.add_theme_constant_override("separation", 6)
	right_col.add_child(squad_hb)

	for i in range(b_roster.size()):
		var ally = b_roster[i]
		var is_sel = (i == _battle_selected_ally_idx)
		var a_pos = cm.starting_formation.get(ally["name"], Vector2i(-1, -1))
		var is_on_grid = (a_pos is Vector2i and a_pos != Vector2i(-1, -1))
		var a_elem = ally.get("element", "fire")
		var a_role = ally.get("archetype", ally.get("role", "Striker"))

		var card = load("res://scripts/tactical_workbench_card.gd").new()
		card.ally_name = ally["name"]
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var c_sb = StyleBoxFlat.new()
		c_sb.set_corner_radius_all(4)
		c_sb.content_margin_left = 6
		c_sb.content_margin_right = 6
		c_sb.content_margin_top = 4
		c_sb.content_margin_bottom = 4
		if is_sel:
			c_sb.bg_color = Color(0.12, 0.16, 0.24, 0.98)
			c_sb.border_width_left = 2
			c_sb.border_width_top = 2
			c_sb.border_width_right = 2
			c_sb.border_width_bottom = 2
			c_sb.border_color = UITheme.GOLD_PRIMARY
			c_sb.shadow_color = Color(UITheme.GOLD_PRIMARY.r, UITheme.GOLD_PRIMARY.g, UITheme.GOLD_PRIMARY.b, 0.2)
			c_sb.shadow_size = 4
		else:
			c_sb.bg_color = Color(0.06, 0.08, 0.12, 0.90)
			c_sb.border_width_left = 1
			c_sb.border_width_top = 1
			c_sb.border_width_right = 1
			c_sb.border_width_bottom = 1
			c_sb.border_color = Color(0.18, 0.24, 0.35, 0.5)
		card.add_theme_stylebox_override("panel", c_sb)

		var c_vb = VBoxContainer.new()
		c_vb.add_theme_constant_override("separation", 4)
		card.add_child(c_vb)

		var top_row = HBoxContainer.new()
		top_row.add_theme_constant_override("separation", 6)
		c_vb.add_child(top_row)

		# Avatar slot
		var av_p = PanelContainer.new()
		av_p.custom_minimum_size = Vector2(30, 30)
		var av_sb = StyleBoxFlat.new()
		av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
		av_sb.set_corner_radius_all(3)
		av_sb.border_width_left = 1
		av_sb.border_width_top = 1
		av_sb.border_width_right = 1
		av_sb.border_width_bottom = 1
		av_sb.border_color = Color(0.25, 0.35, 0.50, 0.5)
		av_p.add_theme_stylebox_override("panel", av_sb)

		av_p.add_child(_make_portrait(a_elem))
		top_row.add_child(av_p)

		# Info column
		var info_vb = VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vb.add_theme_constant_override("separation", 1)
		top_row.add_child(info_vb)

		var name_lbl = Label.new()
		name_lbl.text = ally["name"].capitalize()
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.modulate = UITheme.GOLD_PRIMARY if is_sel else Color(0.92, 0.95, 1.0)
		info_vb.add_child(name_lbl)

		var meta_lbl = Label.new()
		meta_lbl.text = "Lv. %d %s • %s" % [ally.get("level", 1), a_elem.capitalize(), a_role]
		meta_lbl.add_theme_font_size_override("font_size", 7)
		meta_lbl.modulate = _get_element_color(a_elem)
		info_vb.add_child(meta_lbl)

		var st_lbl = Label.new()
		st_lbl.text = "Grid (%d,%d)" % [a_pos.x, a_pos.y] if is_on_grid else "Bench"
		st_lbl.add_theme_font_size_override("font_size", 7)
		st_lbl.modulate = Color(0.35, 0.90, 0.50) if is_on_grid else Color(0.95, 0.70, 0.30)
		info_vb.add_child(st_lbl)

		# Action button inside card
		var btn_act = Button.new()
		btn_act.text = "Bench" if is_on_grid else "Deploy"
		_style_secondary_slate_button(btn_act, 8)
		btn_act.custom_minimum_size = Vector2(0, 18)
		var a_k = ally["name"]
		btn_act.pressed.connect(func():
			if is_on_grid:
				cm.starting_formation[a_k] = Vector2i(-1, -1)
			else:
				var placed = false
				for c in range(1, 6):
					for r in range(1, 9):
						var cand = Vector2i(c, r)
						var is_occupied = false
						for v in cm.starting_formation.values():
							var v_pos = v
							if not (v_pos is Vector2i) and cm.has_method("parse_vector2i"):
								v_pos = cm.parse_vector2i(v_pos)
							if v_pos is Vector2i and v_pos == cand:
								is_occupied = true
								break
						if not is_occupied:
							cm.starting_formation[a_k] = cand
							placed = true
							break
					if placed:
						break
			_refresh_battle_tab()
		)
		c_vb.add_child(btn_act)

		card.card_clicked.connect(func(_ignored):
			_battle_selected_ally_idx = i
			_refresh_battle_tab()
		)
		card.bench_dropped.connect(func(b_name: String):
			cm.starting_formation[b_name] = Vector2i(-1, -1)
			_refresh_battle_tab()
		)

		squad_hb.add_child(card)

	# 3. Selected Member Skill & Loadout Editor (Lower Section)
	var sel_member = b_roster[min(_battle_selected_ally_idx, b_roster.size() - 1)]
	var insp_panel = PanelContainer.new()
	var insp_sb = StyleBoxFlat.new()
	insp_sb.set_corner_radius_all(4)
	insp_sb.content_margin_left = 8
	insp_sb.content_margin_right = 8
	insp_sb.content_margin_top = 6
	insp_sb.content_margin_bottom = 6
	insp_sb.bg_color = Color(0.06, 0.08, 0.12, 0.95)
	insp_sb.border_width_left = 1
	insp_sb.border_width_top = 1
	insp_sb.border_width_right = 1
	insp_sb.border_width_bottom = 1
	insp_sb.border_color = Color(0.20, 0.28, 0.40, 0.6)
	insp_panel.add_theme_stylebox_override("panel", insp_sb)
	right_col.add_child(insp_panel)

	var insp_vb = VBoxContainer.new()
	insp_vb.add_theme_constant_override("separation", 4)
	insp_panel.add_child(insp_vb)

	var insp_top_hb = HBoxContainer.new()
	insp_vb.add_child(insp_top_hb)

	var s_pot = sel_member.get("potential", 50)
	var s_tier = sel_member.get("league_tier", 1)
	var s_pot_lbl = _get_potential_tier_label(s_pot)

	var insp_title = Label.new()
	insp_title.text = "3. Combatant: %s (%s %s)  |  Lv. %d  |  Tier %d (%s)" % [
		sel_member["name"], sel_member.get("element", "fire").capitalize(),
		sel_member.get("archetype", "Striker"),
		sel_member.get("level", 1), s_tier, s_pot_lbl
	]
	insp_title.add_theme_font_size_override("font_size", 10)
	insp_title.modulate = UITheme.GOLD_PRIMARY
	insp_top_hb.add_child(insp_title)

	var insp_sp = Control.new()
	insp_sp.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	insp_top_hb.add_child(insp_sp)

	# Sunken stats strip
	var stat_strip_hb = HBoxContainer.new()
	stat_strip_hb.add_theme_constant_override("separation", 4)
	insp_vb.add_child(stat_strip_hb)

	var stat_items = [
		{"label": "Health", "val": "%d HP" % sel_member.get("hp", 100), "color": Color(0.95, 0.45, 0.45)},
		{"label": "Mana", "val": "%d MP" % sel_member.get("mp", 100), "color": Color(0.40, 0.75, 1.0)},
		{"label": "Stamina", "val": "%d STA" % sel_member.get("stamina", 100), "color": Color(0.45, 0.90, 0.60)},
		{"label": "Speed", "val": "%d Tiles" % sel_member.get("speed", 3), "color": UITheme.GOLD_PRIMARY}
	]
	for si in stat_items:
		var s_chip = PanelContainer.new()
		s_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var s_chip_sb = StyleBoxFlat.new()
		s_chip_sb.bg_color = Color(0.04, 0.05, 0.08, 0.8)
		s_chip_sb.set_corner_radius_all(3)
		s_chip_sb.content_margin_left = 4
		s_chip_sb.content_margin_right = 4
		s_chip_sb.content_margin_top = 2
		s_chip_sb.content_margin_bottom = 2
		s_chip.add_theme_stylebox_override("panel", s_chip_sb)

		var chip_hb = HBoxContainer.new()
		chip_hb.alignment = BoxContainer.ALIGNMENT_CENTER
		chip_hb.add_theme_constant_override("separation", 4)
		s_chip.add_child(chip_hb)

		var c_lbl = Label.new()
		c_lbl.text = si["label"] + ":"
		c_lbl.add_theme_font_size_override("font_size", 7)
		c_lbl.modulate = UITheme.TEXT_MUTED
		chip_hb.add_child(c_lbl)

		var c_val = Label.new()
		c_val.text = si["val"]
		c_val.add_theme_font_size_override("font_size", 8)
		c_val.modulate = si["color"]
		chip_hb.add_child(c_val)

		stat_strip_hb.add_child(s_chip)

	# Equipped Skills List (4 Slots)
	var eq_skills = sel_member.get("equipped_skills", ["Combustion"]).duplicate()
	var eq_hb = HBoxContainer.new()
	eq_hb.add_theme_constant_override("separation", 4)
	insp_vb.add_child(eq_hb)

	for slot_i in range(4):
		var slot_panel = PanelContainer.new()
		slot_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot_panel.custom_minimum_size = Vector2(0, 42)
		var s_sb = StyleBoxFlat.new()
		s_sb.set_corner_radius_all(4)
		s_sb.content_margin_left = 6
		s_sb.content_margin_right = 6
		s_sb.content_margin_top = 3
		s_sb.content_margin_bottom = 3
		s_sb.bg_color = Color(0.08, 0.11, 0.16, 0.9)
		s_sb.border_width_left = 1
		s_sb.border_width_top = 1
		s_sb.border_width_right = 1
		s_sb.border_width_bottom = 1
		s_sb.border_color = Color(0.20, 0.28, 0.40, 0.5)
		slot_panel.add_theme_stylebox_override("panel", s_sb)

		var s_vb = VBoxContainer.new()
		s_vb.add_theme_constant_override("separation", 2)
		slot_panel.add_child(s_vb)

		if slot_i < eq_skills.size():
			var sk_name = eq_skills[slot_i]
			var forms = edata.get_skill_forms(sk_name) if edata else {}
			var unlocked_forms = cm.get_unlocked_forms_for_skill(sk_name)
			var cur_var = cm.skill_variations.get(sk_name, "")
			if not forms.has(cur_var) and not forms.is_empty():
				cur_var = forms.keys()[0]
			var lbl_sk = Label.new()
			lbl_sk.text = "%d. %s" % [slot_i + 1, sk_name.replace("_", " ")]
			lbl_sk.add_theme_font_size_override("font_size", 9)
			lbl_sk.modulate = Color(1.0, 0.92, 0.65)
			s_vb.add_child(lbl_sk)

			var btn_var = Button.new()
			btn_var.name = "Form_" + sk_name
			btn_var.text = forms.get(cur_var, {}).get("name", "Form")
			btn_var.disabled = unlocked_forms.size() < 2
			btn_var.tooltip_text = "Cycle unlocked forms. Unlock additional forms in Cultivation."
			_style_secondary_slate_button(btn_var, 8)
			btn_var.custom_minimum_size = Vector2(0, 18)
			btn_var.pressed.connect(func():
				if unlocked_forms.size() > 1:
					var next_idx = (unlocked_forms.find(cur_var) + 1) % unlocked_forms.size()
					cm.set_active_skill_form(sk_name, unlocked_forms[next_idx])
					_refresh_battle_tab()
			)
			s_vb.add_child(btn_var)

			var btn_uneq = Button.new()
			btn_uneq.text = "Unequip"
			_style_secondary_slate_button(btn_uneq, 8)
			btn_uneq.custom_minimum_size = Vector2(0, 18)
			btn_uneq.disabled = (eq_skills.size() <= 1)
			btn_uneq.pressed.connect(func():
				eq_skills.remove_at(slot_i)
				cm.set_teammate_active_skills(sel_member["name"], eq_skills)
				if sel_member["name"] == cm.player_name:
					cm.equipped_abilities = eq_skills.duplicate()
				_refresh_battle_tab()
			)
			s_vb.add_child(btn_uneq)
		else:
			var lbl_empty = Label.new()
			lbl_empty.text = "%d. [ Empty ]" % [slot_i + 1]
			lbl_empty.add_theme_font_size_override("font_size", 8)
			lbl_empty.modulate = Color(0.4, 0.45, 0.55)
			lbl_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			s_vb.add_child(lbl_empty)

		eq_hb.add_child(slot_panel)

	# Available Skills to Equip
	var avail_hdr = Label.new()
	avail_hdr.text = "Available %s Discipline Skills (Click to Equip):" % sel_member["element"].capitalize()
	avail_hdr.add_theme_font_size_override("font_size", 8)
	avail_hdr.modulate = UITheme.TEXT_MUTED
	insp_vb.add_child(avail_hdr)

	var avail_scroll = ScrollContainer.new()
	avail_scroll.custom_minimum_size = Vector2(0, 38)
	avail_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avail_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	avail_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	insp_vb.add_child(avail_scroll)

	var avail_flow = HFlowContainer.new()
	avail_flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	avail_flow.add_theme_constant_override("h_separation", 6)
	avail_flow.add_theme_constant_override("v_separation", 4)
	avail_scroll.add_child(avail_flow)

	var known_pool = sel_member.get("known_skills", []).duplicate()
	if sel_member["name"] == cm.player_name:
		for ua in cm.unlocked_abilities:
			if not known_pool.has(ua): known_pool.append(ua)

	var unequipped_avail = []
	for sk in known_pool:
		if not sk in eq_skills:
			unequipped_avail.append(sk)

	if unequipped_avail.is_empty():
		var all_eq_lbl = Label.new()
		all_eq_lbl.text = "All known skills for %s are currently equipped." % sel_member["name"]
		all_eq_lbl.add_theme_font_size_override("font_size", 8)
		all_eq_lbl.modulate = Color(0.5, 0.8, 0.6)
		avail_flow.add_child(all_eq_lbl)
	else:
		for sk in unequipped_avail:
			var btn_add = Button.new()
			btn_add.text = "+ %s" % sk
			_style_secondary_slate_button(btn_add, 8)
			var sk_to_add = sk
			btn_add.pressed.connect(func():
				if eq_skills.size() < 4:
					eq_skills.append(sk_to_add)
				else:
					eq_skills[3] = sk_to_add
				cm.set_teammate_active_skills(sel_member["name"], eq_skills)
				if sel_member["name"] == cm.player_name:
					cm.equipped_abilities = eq_skills.duplicate()
				_refresh_battle_tab()
			)
			avail_flow.add_child(btn_add)

	# 4. BIG DIRECT DEPLOY BUTTON
	var btn_direct_deploy = Button.new()
	btn_direct_deploy.text = "Confirm Strategy & Start Match"
	btn_direct_deploy.custom_minimum_size = Vector2(0, 38)
	btn_direct_deploy.disabled = not has_scheduled_match or (cm.get_next_scheduled_match().has("season_day") and not cm.can_play_next_match() and _pending_deployment_match.is_empty())
	_style_primary_gold_button(btn_direct_deploy, 12)
	btn_direct_deploy.pressed.connect(func():
		var cap_pos = cm.starting_formation.get(cm.player_name, Vector2i(-1, -1))
		if not cap_pos is Vector2i or cap_pos == Vector2i(-1, -1):
			cm.starting_formation[cm.player_name] = Vector2i(3, 4)

		_on_launch_battle_arena_direct()
	)
	right_col.add_child(btn_direct_deploy)

# ══════════════════════════════════════════════════════════════════════════════
#  TAB 1: ROSTER & SQUAD MANAGEMENT (2-COLUMN LAYOUT)
# ══════════════════════════════════════════════════════════════════════════════

var _roster_selected_idx: int = 0
var _roster_dialogue_quote: String = ""

func _get_player_roster_data() -> Dictionary:
	var p_lvl = cm.player_level if cm else 1
	var p_elem = cm.player_element if cm else "fire"
	var edata = _get_element_data()
	var p_base_hp = 90
	if edata and edata.ELEMENTS.has(p_elem):
		p_base_hp = edata.ELEMENTS[p_elem].get("base_hp", 90)
	var p_hp = p_base_hp + (p_lvl - 1) * 10
	var p_mana = cm.player_mana if cm else 100
	var p_sta = cm.player_stamina if cm else 100
	var p_spd = cm.player_speed if cm else 3
	var p_agi = cm.player_agility if cm else 28
	var p_dex = cm.player_dexterity if cm else 32
	var p_def = cm.player_defense if cm else 20
	var p_pot = cm.player_potency if cm else 30
	return {
		"name": cm.player_name if cm else "Player",
		"element": p_elem,
		"role": "Team Captain (Player)" if (cm and cm.has_team) else "Solo Street Brawler",
		"archetype": "Striker",
		"level": p_lvl,
		"league_tier": cm.league_tier if cm else 1,
		"base_stats": {
			"hp": p_hp, "mp": p_mana, "stamina": p_sta, "speed": p_spd, "agility": p_agi, "dexterity": p_dex, "defense": p_def
		},
		"hp": p_hp,
		"mana": p_mana,
		"stamina": p_sta,
		"speed": p_spd,
		"agility": p_agi,
		"dexterity": p_dex,
		"defense": p_def,
		"potency": p_pot,
		"potential": 85,
		"status": "Active",
		"career_team": cm.career_team if cm else "Free Agent",
		"equipped_skills": cm.equipped_abilities if cm else ["Combustion"],
		"known_skills": cm.unlocked_abilities if cm else ["Combustion"]
	}

func _get_active_roster() -> Array:
	if cm and cm.has_team and cm.allies.size() > 0:
		return cm.allies
	return [_get_player_roster_data()]

func _refresh_team_tab():
	var team_box = $MainTabs/TabTeam/AlliesContainer
	for c in team_box.get_children():
		team_box.remove_child(c)
		c.queue_free()

	# Sync captain ally data with cm.player_level and attributes
	if cm and cm.has_team and cm.allies.size() > 0:
		var cap = cm.allies[0]
		cap["name"] = cm.player_name
		cap["element"] = cm.player_element
		cap["level"] = cm.player_level
		cap["hp"] = _player_max_hp()
		cap["mana"] = cm.player_mana
		cap["stamina"] = cm.player_stamina
		cap["speed"] = cm.player_speed
		cap["agility"] = cm.player_agility
		cap["dexterity"] = cm.player_dexterity
		cap["potency"] = cm.player_potency

	# 2-Column Layout
	var cols_hb = HBoxContainer.new()
	cols_hb.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cols_hb.add_theme_constant_override("separation", 20)
	team_box.add_child(cols_hb)

	var cinzel = load("res://assets/fonts/Cinzel-Bold.ttf")

	# LEFT COLUMN: Roster Members List & Dojo Overview (~400px)
	var left_col = VBoxContainer.new()
	left_col.custom_minimum_size = Vector2(400, 520)
	left_col.add_theme_constant_override("separation", 10)
	cols_hb.add_child(left_col)

	var t_name_header = cm.team_name if (cm and cm.has_team and cm.team_name != "") else "Solo Fighter"
	var list_header = Label.new()
	list_header.text = "%s Dojo Roster" % t_name_header if (cm and cm.has_team) else "Free Agent Dossier"
	list_header.add_theme_font_size_override("font_size", 13)
	list_header.modulate = Color(0.92, 0.78, 0.35, 1.0)
	left_col.add_child(list_header)

	var active_roster = _get_active_roster()

	# Scrollable roster cards container
	var roster_scroll = ScrollContainer.new()
	roster_scroll.custom_minimum_size = Vector2(0, 360)
	roster_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	roster_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_col.add_child(roster_scroll)

	var r_cards_vb = VBoxContainer.new()
	r_cards_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	r_cards_vb.add_theme_constant_override("separation", 8)
	roster_scroll.add_child(r_cards_vb)

	# Group 1: Active Battle Lineup Header
	var act_hdr = Label.new()
	act_hdr.text = "Active Fighter" if (cm and not cm.has_team) else "Active Battle Lineup"
	act_hdr.add_theme_font_size_override("font_size", 10)
	act_hdr.modulate = UITheme.GOLD_PRIMARY
	r_cards_vb.add_child(act_hdr)

	for i in range(active_roster.size()):
		var ally = active_roster[i]
		var is_sel = (i == _roster_selected_idx)
		var a_name = ally.get("name", "Fighter")
		var a_elem = ally.get("element", "fire")
		var a_lvl = ally.get("level", 1)
		var a_pot = ally.get("potential", 50)
		var a_pot_label = _get_potential_tier_label(a_pot)
		var a_status = ally.get("status", "Active")
		var a_arch = ally.get("archetype", ally.get("role", "Striker"))

		# Card container for each fighter
		var card_p = PanelContainer.new()
		card_p.custom_minimum_size = Vector2(0, 72)
		var card_sb = StyleBoxFlat.new()
		card_sb.set_corner_radius_all(4)
		card_sb.content_margin_left = 10
		card_sb.content_margin_top = 8
		card_sb.content_margin_right = 12
		card_sb.content_margin_bottom = 8
		if is_sel:
			card_sb.bg_color = Color(0.12, 0.16, 0.24, 0.98)
			card_sb.border_width_left = 3
			card_sb.border_width_top = 1
			card_sb.border_width_right = 1
			card_sb.border_width_bottom = 1
			card_sb.border_color = UITheme.GOLD_PRIMARY
			card_sb.shadow_color = Color(UITheme.GOLD_PRIMARY.r, UITheme.GOLD_PRIMARY.g, UITheme.GOLD_PRIMARY.b, 0.2)
			card_sb.shadow_size = 4
		else:
			card_sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
			card_sb.border_width_left = 1
			card_sb.border_width_top = 1
			card_sb.border_width_right = 1
			card_sb.border_width_bottom = 1
			card_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
		card_p.add_theme_stylebox_override("panel", card_sb)

		var row_hb = HBoxContainer.new()
		row_hb.add_theme_constant_override("separation", 10)
		card_p.add_child(row_hb)

		# Avatar slot
		var av_p = PanelContainer.new()
		av_p.custom_minimum_size = Vector2(48, 48)
		var av_sb = StyleBoxFlat.new()
		av_sb.bg_color = Color(0.04, 0.05, 0.08, 0.9)
		av_sb.set_corner_radius_all(4)
		av_sb.border_width_left = 1
		av_sb.border_width_top = 1
		av_sb.border_width_right = 1
		av_sb.border_width_bottom = 1
		av_sb.border_color = Color(0.20, 0.28, 0.40, 0.5)
		av_p.add_theme_stylebox_override("panel", av_sb)

		av_p.add_child(_make_portrait(a_elem))
		row_hb.add_child(av_p)

		# Info VBox
		var info_vb = VBoxContainer.new()
		info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
		info_vb.add_theme_constant_override("separation", 2)

		var n_lbl = Label.new()
		n_lbl.text = a_name
		n_lbl.add_theme_font_size_override("font_size", 12)
		n_lbl.modulate = Color(1.0, 0.95, 0.85) if is_sel else Color(0.90, 0.92, 0.96)
		info_vb.add_child(n_lbl)

		var sub_lbl = Label.new()
		sub_lbl.text = "Lv. %d %s • %s" % [a_lvl, a_elem.capitalize(), a_arch.capitalize()]
		sub_lbl.add_theme_font_size_override("font_size", 9)
		sub_lbl.modulate = _get_element_color(a_elem)
		info_vb.add_child(sub_lbl)

		var pot_lbl = Label.new()
		pot_lbl.text = "%s Potential (%d/100)" % [a_pot_label, a_pot]
		pot_lbl.add_theme_font_size_override("font_size", 8)
		pot_lbl.modulate = Color(0.55, 0.62, 0.72)
		info_vb.add_child(pot_lbl)

		row_hb.add_child(info_vb)

		# Status Badge Pill
		var stat_p = PanelContainer.new()
		stat_p.custom_minimum_size = Vector2(65, 20)
		stat_p.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var stat_sb = StyleBoxFlat.new()
		stat_sb.set_corner_radius_all(10)
		stat_sb.content_margin_left = 6
		stat_sb.content_margin_right = 6
		stat_sb.content_margin_top = 2
		stat_sb.content_margin_bottom = 2
		var is_active_status = (a_status.to_lower() == "active")
		stat_sb.bg_color = Color(0.04, 0.10, 0.06, 0.9) if is_active_status else Color(0.08, 0.10, 0.14, 0.9)
		stat_sb.border_width_left = 1
		stat_sb.border_width_top = 1
		stat_sb.border_width_right = 1
		stat_sb.border_width_bottom = 1
		stat_sb.border_color = Color(0.20, 0.50, 0.35, 0.8) if is_active_status else Color(0.20, 0.26, 0.38, 0.6)
		stat_p.add_theme_stylebox_override("panel", stat_sb)

		var stat_lbl = Label.new()
		stat_lbl.text = a_status.capitalize()
		stat_lbl.add_theme_font_size_override("font_size", 8)
		stat_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stat_lbl.modulate = Color(0.35, 0.85, 0.55) if is_active_status else Color(0.60, 0.68, 0.78)
		stat_p.add_child(stat_lbl)
		row_hb.add_child(stat_p)

		# Click button overlay
		var click_btn = Button.new()
		click_btn.layout_mode = 1
		click_btn.anchors_preset = Control.PRESET_FULL_RECT
		click_btn.flat = true
		click_btn.focus_mode = Control.FOCUS_NONE
		var idx_cap = i
		click_btn.pressed.connect(func():
			_roster_selected_idx = idx_cap
			_roster_dialogue_quote = ""
			_refresh_team_tab()
		)
		card_p.add_child(click_btn)
		r_cards_vb.add_child(card_p)

	# Dojo Facility Overview card below list
	var dojo_card = PanelContainer.new()
	var dj_sb = StyleBoxFlat.new()
	dj_sb.set_corner_radius_all(4)
	dj_sb.bg_color = Color(0.05, 0.07, 0.10, 0.85)
	dj_sb.border_width_left = 1
	dj_sb.border_width_top = 1
	dj_sb.border_width_right = 1
	dj_sb.border_width_bottom = 1
	dj_sb.border_color = Color(0.14, 0.18, 0.26, 0.5)
	dj_sb.content_margin_left = 14
	dj_sb.content_margin_top = 10
	dj_sb.content_margin_right = 14
	dj_sb.content_margin_bottom = 10
	dojo_card.add_theme_stylebox_override("panel", dj_sb)

	var dj_vb = VBoxContainer.new()
	dj_vb.add_theme_constant_override("separation", 5)
	dojo_card.add_child(dj_vb)

	var dj_title = Label.new()
	dj_title.text = "Dojo Facility Overview"
	dj_title.add_theme_font_size_override("font_size", 10)
	dj_title.modulate = Color(0.92, 0.78, 0.35, 1.0)
	dj_vb.add_child(dj_title)

	var dj_details = [
		"Division: %s" % (cm.current_league if cm else "Street Circuit"),
		"Active Lineup: %d %s" % [active_roster.size(), "Combatant (Solo Fighter)" if active_roster.size() == 1 else "Combatants"],
		"Dojo Facility: Standard Training Mat",
		"Tactical Morale: High (+0% bonus)"
	]
	for d in dj_details:
		var d_lbl = Label.new()
		d_lbl.text = "◆  %s" % d
		d_lbl.add_theme_font_size_override("font_size", 9)
		d_lbl.modulate = Color(0.60, 0.68, 0.80)
		dj_vb.add_child(d_lbl)

	left_col.add_child(dojo_card)

	# RIGHT COLUMN: Selected Member Dossier
	var right_col = PanelContainer.new()
	right_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var r_sb = StyleBoxFlat.new()
	r_sb.set_corner_radius_all(6)
	r_sb.bg_color = Color(0.07, 0.09, 0.14, 0.96)
	r_sb.border_width_left = 1
	r_sb.border_width_top = 1
	r_sb.border_width_right = 1
	r_sb.border_width_bottom = 1
	r_sb.border_color = Color(0.18, 0.24, 0.35, 0.6)
	right_col.add_theme_stylebox_override("panel", r_sb)
	cols_hb.add_child(right_col)

	var r_margin = MarginContainer.new()
	r_margin.add_theme_constant_override("margin_left", 20)
	r_margin.add_theme_constant_override("margin_top", 16)
	r_margin.add_theme_constant_override("margin_right", 20)
	r_margin.add_theme_constant_override("margin_bottom", 16)
	right_col.add_child(r_margin)

	var r_vb = VBoxContainer.new()
	r_vb.add_theme_constant_override("separation", 12)
	r_margin.add_child(r_vb)

	_roster_selected_idx = clampi(_roster_selected_idx, 0, max(0, active_roster.size() - 1))
	var sel_ally = active_roster[_roster_selected_idx]
	var is_ignis = (_roster_selected_idx == 0 or sel_ally["name"] == cm.player_name)
	var sel_elem = sel_ally.get("element", "fire")
	var sel_pot = sel_ally.get("potential", 50)
	var sel_pot_label = _get_potential_tier_label(sel_pot)
	var sel_tier = sel_ally.get("league_tier", 1)
	var sel_status = sel_ally.get("status", "Active")
	var sel_arch = sel_ally.get("archetype", sel_ally.get("role", "Striker"))

	# Dossier Header Row: Portrait Pedestal + Fighter Profile
	var head_hb = HBoxContainer.new()
	head_hb.add_theme_constant_override("separation", 16)
	r_vb.add_child(head_hb)

	var ped_p = PanelContainer.new()
	ped_p.custom_minimum_size = Vector2(72, 72)
	var ped_sb = StyleBoxFlat.new()
	ped_sb.set_corner_radius_all(6)
	ped_sb.bg_color = Color(0.04, 0.05, 0.08, 0.95)
	ped_sb.border_width_left = 1
	ped_sb.border_width_top = 1
	ped_sb.border_width_right = 1
	ped_sb.border_width_bottom = 1
	ped_sb.border_color = _get_element_color(sel_elem)
	ped_p.add_theme_stylebox_override("panel", ped_sb)

	ped_p.add_child(_make_portrait(sel_elem))
	head_hb.add_child(ped_p)

	var head_info_vb = VBoxContainer.new()
	head_info_vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head_info_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	head_info_vb.add_theme_constant_override("separation", 4)
	head_hb.add_child(head_info_vb)

	var title_row = HBoxContainer.new()
	title_row.add_theme_constant_override("separation", 10)
	head_info_vb.add_child(title_row)

	var d_title = Label.new()
	d_title.text = sel_ally["name"]
	d_title.add_theme_font_size_override("font_size", 18)
	d_title.modulate = Color(1.0, 1.0, 1.0)
	title_row.add_child(d_title)

	# Element / Archetype chips
	var arch_pill = PanelContainer.new()
	arch_pill.custom_minimum_size = Vector2(85, 20)
	arch_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var arch_sb = StyleBoxFlat.new()
	arch_sb.set_corner_radius_all(10)
	arch_sb.bg_color = Color(0.06, 0.08, 0.12, 0.9)
	arch_sb.border_width_left = 1
	arch_sb.border_width_top = 1
	arch_sb.border_width_right = 1
	arch_sb.border_width_bottom = 1
	arch_sb.border_color = UITheme.BORDER_GOLD if is_ignis else Color(0.25, 0.35, 0.50, 0.7)
	arch_sb.content_margin_left = 8
	arch_sb.content_margin_right = 8
	arch_pill.add_theme_stylebox_override("panel", arch_sb)

	var arch_l = Label.new()
	arch_l.text = sel_arch.capitalize()
	arch_l.add_theme_font_size_override("font_size", 8)
	arch_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	arch_l.modulate = UITheme.GOLD_PRIMARY if is_ignis else Color(0.75, 0.85, 0.95)
	arch_pill.add_child(arch_l)
	title_row.add_child(arch_pill)

	var elem_pill = PanelContainer.new()
	elem_pill.custom_minimum_size = Vector2(75, 20)
	elem_pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var elem_sb = StyleBoxFlat.new()
	elem_sb.set_corner_radius_all(10)
	elem_sb.bg_color = Color(0.06, 0.08, 0.12, 0.9)
	elem_sb.border_width_left = 1
	elem_sb.border_width_top = 1
	elem_sb.border_width_right = 1
	elem_sb.border_width_bottom = 1
	elem_sb.border_color = _get_element_color(sel_elem)
	elem_sb.content_margin_left = 8
	elem_sb.content_margin_right = 8
	elem_pill.add_theme_stylebox_override("panel", elem_sb)

	var elem_l = Label.new()
	elem_l.text = "%s Element" % sel_elem.capitalize()
	elem_l.add_theme_font_size_override("font_size", 8)
	elem_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elem_l.modulate = _get_element_color(sel_elem)
	elem_pill.add_child(elem_l)
	title_row.add_child(elem_pill)

	var d_profile = Label.new()
	d_profile.text = "League Tier: %d  •  Potential: %s (%d/100)  •  Status: %s" % [
		sel_tier, sel_pot_label, sel_pot, sel_status.capitalize()
	]
	d_profile.add_theme_font_size_override("font_size", 10)
	d_profile.modulate = Color(0.70, 0.78, 0.90)
	head_info_vb.add_child(d_profile)

	# Sub-Tabs Navigation for Dossier: [Profile] [Skills] [Training] [Career]
	var subtab_hb = HBoxContainer.new()
	subtab_hb.add_theme_constant_override("separation", 8)
	r_vb.add_child(subtab_hb)

	var dossier_subtabs = [
		{"idx": 0, "title": "Profile"},
		{"idx": 1, "title": "Skills"},
		{"idx": 2, "title": "Training"},
		{"idx": 3, "title": "Career"}
	]

	for st in dossier_subtabs:
		var st_btn = Button.new()
		st_btn.text = st["title"]
		if cinzel_font:
			st_btn.add_theme_font_override("font", cinzel_font)
		st_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		st_btn.custom_minimum_size = Vector2(0, 30)
		if _roster_subtab == st["idx"]:
			_style_tactical_button(st_btn, Color(0.12, 0.16, 0.24, 0.98), UITheme.GOLD_PRIMARY, Color(1.0, 0.95, 0.75), 10, true)
		else:
			_style_secondary_slate_button(st_btn, 10)
		var st_i = st["idx"]
		st_btn.pressed.connect(func():
			_roster_subtab = st_i
			_refresh_team_tab()
		)
		subtab_hb.add_child(st_btn)

	# Sub-Tab Content Rendering
	match _roster_subtab:
		0:
			# SUB-TAB 0: Profile (Attributes Matrix & Status)
			var b_stats = sel_ally.get("base_stats", {})
			var s_hp = sel_ally.get("hp", b_stats.get("hp", 100))
			var s_mp = sel_ally.get("mana", b_stats.get("mana", 100))
			var s_sta = sel_ally.get("stamina", b_stats.get("stamina", 100))
			var s_spd = sel_ally.get("speed", b_stats.get("speed", 3))
			var s_agi = sel_ally.get("agility", b_stats.get("agility", 28))
			var s_dex = sel_ally.get("dexterity", b_stats.get("dexterity", 32))
			var s_def = sel_ally.get("defense", b_stats.get("defense", 20))
			var s_pot_stat = sel_ally.get("potency", 30)

			var stats_grid = GridContainer.new()
			stats_grid.columns = 4
			stats_grid.add_theme_constant_override("h_separation", 10)
			stats_grid.add_theme_constant_override("v_separation", 8)
			r_vb.add_child(stats_grid)

			var attr_entries = [
				{"name": "Health", "val": "%d HP" % s_hp, "col": Color(0.92, 0.45, 0.45)},
				{"name": "Mana", "val": "%d MP" % s_mp, "col": Color(0.35, 0.65, 0.95)},
				{"name": "Stamina", "val": "%d STA" % s_sta, "col": Color(0.35, 0.85, 0.50)},
				{"name": "Speed", "val": "%d Tiles" % s_spd, "col": Color(0.92, 0.82, 0.40)},
				{"name": "Defense", "val": "%d DEF" % s_def, "col": Color(0.70, 0.85, 0.55)},
				{"name": "Agility", "val": "%d EVA" % s_agi, "col": Color(0.40, 0.85, 0.80)},
				{"name": "Dexterity", "val": "%d CRT" % s_dex, "col": Color(0.85, 0.55, 0.90)},
				{"name": "Potency", "val": "%d ATK" % s_pot_stat, "col": Color(0.95, 0.65, 0.30)}
			]

			for att in attr_entries:
				var chip_p = PanelContainer.new()
				chip_p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				chip_p.custom_minimum_size = Vector2(110, 48)
				var chip_sb = StyleBoxFlat.new()
				chip_sb.set_corner_radius_all(4)
				chip_sb.bg_color = Color(0.05, 0.07, 0.10, 0.90)
				chip_sb.border_width_left = 1
				chip_sb.border_width_top = 1
				chip_sb.border_width_right = 1
				chip_sb.border_width_bottom = 1
				chip_sb.border_color = Color(0.16, 0.22, 0.32, 0.5)
				chip_sb.content_margin_left = 10
				chip_sb.content_margin_right = 10
				chip_sb.content_margin_top = 6
				chip_sb.content_margin_bottom = 6
				chip_p.add_theme_stylebox_override("panel", chip_sb)

				var chip_vb = VBoxContainer.new()
				chip_vb.alignment = BoxContainer.ALIGNMENT_CENTER
				chip_vb.add_theme_constant_override("separation", 2)
				chip_p.add_child(chip_vb)

				var c_h = Label.new()
				c_h.text = att["name"]
				c_h.add_theme_font_size_override("font_size", 9)
				c_h.modulate = Color(0.55, 0.62, 0.74)
				chip_vb.add_child(c_h)

				var c_v = Label.new()
				c_v.text = att["val"]
				c_v.add_theme_font_size_override("font_size", 13)
				c_v.modulate = att["col"]
				chip_vb.add_child(c_v)

				stats_grid.add_child(chip_p)

		1:
			# SUB-TAB 1: Skills (Equipped Techniques & Mastery Pool)
			var skills_box = VBoxContainer.new()
			skills_box.add_theme_constant_override("separation", 8)
			r_vb.add_child(skills_box)

			var eq_title = Label.new()
			eq_title.text = "Equipped Martial Techniques"
			eq_title.add_theme_font_size_override("font_size", 11)
			eq_title.modulate = Color(0.92, 0.78, 0.35)
			skills_box.add_child(eq_title)

			var eq_row = HBoxContainer.new()
			eq_row.add_theme_constant_override("separation", 8)
			skills_box.add_child(eq_row)

			var eq_skills_list = sel_ally.get("equipped_skills", ["Combustion"])
			for sk in eq_skills_list:
				var sk_pill = PanelContainer.new()
				var sk_sb = StyleBoxFlat.new()
				sk_sb.set_corner_radius_all(4)
				sk_sb.bg_color = Color(0.06, 0.08, 0.12, 0.9)
				sk_sb.border_width_left = 1
				sk_sb.border_width_top = 1
				sk_sb.border_width_right = 1
				sk_sb.border_width_bottom = 1
				sk_sb.border_color = Color(0.22, 0.32, 0.45, 0.7)
				sk_sb.content_margin_left = 10
				sk_sb.content_margin_right = 10
				sk_sb.content_margin_top = 6
				sk_sb.content_margin_bottom = 6
				sk_pill.add_theme_stylebox_override("panel", sk_sb)

				var sk_l = Label.new()
				sk_l.text = sk.replace("_", " ").capitalize()
				sk_l.add_theme_font_size_override("font_size", 10)
				sk_l.modulate = Color(0.92, 0.95, 1.0)
				sk_pill.add_child(sk_l)
				eq_row.add_child(sk_pill)

			var known_pool_lbl = Label.new()
			known_pool_lbl.text = "Discipline Mastery Pool: %s" % [", ".join(sel_ally.get("known_skills", ["Combustion", "Laser"])).replace("_", " ")]
			known_pool_lbl.add_theme_font_size_override("font_size", 9)
			known_pool_lbl.modulate = Color(0.55, 0.62, 0.74)
			skills_box.add_child(known_pool_lbl)

		2:
			# SUB-TAB 2: Training (Directives & Daily Regimen)
			if not is_ignis:
				var dir_title = Label.new()
				dir_title.text = "Captain Directive: Suggest Training Focus"
				dir_title.add_theme_font_size_override("font_size", 11)
				dir_title.modulate = Color(0.92, 0.78, 0.35)
				r_vb.add_child(dir_title)

				var btn_grid = GridContainer.new()
				btn_grid.columns = 2
				btn_grid.add_theme_constant_override("h_separation", 10)
				btn_grid.add_theme_constant_override("v_separation", 8)
				r_vb.add_child(btn_grid)

				var focuses = ["Speed & Mobility", "Agility & Evasion", "Stamina & Bulwark", "Mana & Potency"]
				for foc in focuses:
					var f_btn = Button.new()
					f_btn.text = "Suggest %s" % foc
					f_btn.custom_minimum_size = Vector2(0, 34)
					_style_secondary_slate_button(f_btn, 10)
					var foc_name = foc
					f_btn.pressed.connect(func():
						var res = cm.suggest_training_focus(sel_ally["name"], foc_name)
						_roster_dialogue_quote = res["quote"]
						_refresh_team_tab()
					)
					btn_grid.add_child(f_btn)
			else:
				var reg_hdr = Label.new()
				reg_hdr.text = "Captain Martial Conditioning"
				reg_hdr.add_theme_font_size_override("font_size", 11)
				reg_hdr.modulate = Color(0.92, 0.78, 0.35)
				r_vb.add_child(reg_hdr)

			var act_title = Label.new()
			act_title.text = "Daily Regimen: Sparring & Recovery"
			act_title.add_theme_font_size_override("font_size", 11)
			act_title.modulate = Color(0.92, 0.78, 0.35)
			r_vb.add_child(act_title)

			var act_hb = HBoxContainer.new()
			act_hb.add_theme_constant_override("separation", 10)
			r_vb.add_child(act_hb)

			var b_train = Button.new()
			b_train.text = "Train Stat (1 Day | -15 ENG)"
			b_train.custom_minimum_size = Vector2(0, 36)
			b_train.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_slate_button(b_train, 10)
			b_train.pressed.connect(_on_activity_train)
			act_hb.add_child(b_train)

			var b_street = Button.new()
			b_street.text = "Street Scrimmage (-20 ENG)"
			b_street.custom_minimum_size = Vector2(0, 36)
			b_street.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_slate_button(b_street, 10)
			b_street.pressed.connect(_on_activity_street)
			act_hb.add_child(b_street)

			var b_rest = Button.new()
			b_rest.text = "Choose Rest Duration"
			b_rest.custom_minimum_size = Vector2(0, 36)
			b_rest.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_slate_button(b_rest, 10)
			b_rest.pressed.connect(_on_activity_rest)
			act_hb.add_child(b_rest)

		3:
			# SUB-TAB 3: Career (Recognition, Promotion & Transfers)
			var cap_title = Label.new()
			cap_title.text = "Career Directives & League Recognition"
			cap_title.add_theme_font_size_override("font_size", 11)
			cap_title.modulate = Color(0.92, 0.78, 0.35)
			r_vb.add_child(cap_title)

			var actions_hb = HBoxContainer.new()
			actions_hb.add_theme_constant_override("separation", 12)
			r_vb.add_child(actions_hb)

			var btn_promo = Button.new()
			btn_promo.text = "Request League Promotion Assessment"
			btn_promo.custom_minimum_size = Vector2(0, 36)
			btn_promo.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_slate_button(btn_promo, 10)
			btn_promo.pressed.connect(func():
				_roster_dialogue_quote = "League Officials: 'Your competitive record qualifies you for Silver Tier placement. Win your next clash to finalize promotion.'"
				_refresh_team_tab()
			)
			actions_hb.add_child(btn_promo)

			var btn_transfer = Button.new()
			btn_transfer.text = "Explore Team Transfer Offers"
			btn_transfer.custom_minimum_size = Vector2(0, 36)
			btn_transfer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_style_secondary_slate_button(btn_transfer, 10)
			btn_transfer.pressed.connect(func():
				_roster_dialogue_quote = "Scout Report: 'Volcano Reapers (Silver) offer 25,000 G signing bonus for a Vanguard Striker!'"
				_refresh_team_tab()
			)
			actions_hb.add_child(btn_transfer)

			if _roster_dialogue_quote != "":
				var quote_box = PanelContainer.new()
				var q_sb = StyleBoxFlat.new()
				q_sb.set_corner_radius_all(4)
				q_sb.content_margin_left = 14
				q_sb.content_margin_right = 14
				q_sb.content_margin_top = 10
				q_sb.content_margin_bottom = 10
				q_sb.bg_color = Color(0.08, 0.12, 0.18, 0.95)
				q_sb.border_width_left = 3
				q_sb.border_color = Color(0.92, 0.78, 0.35, 0.9)
				quote_box.add_theme_stylebox_override("panel", q_sb)

				var q_lbl = Label.new()
				q_lbl.text = _roster_dialogue_quote
				q_lbl.add_theme_font_size_override("font_size", 10)
				q_lbl.modulate = Color(1.0, 0.92, 0.70)
				quote_box.add_child(q_lbl)
				r_vb.add_child(quote_box)

func _on_save_pressed():
	if cm and cm.save_campaign():
		if save_feedback:
			save_feedback.text = "Campaign saved successfully!"
			save_feedback.modulate = Color(0.4, 1.0, 0.4)
	else:
		if save_feedback:
			save_feedback.text = "Save failed."
			save_feedback.modulate = Color(1.0, 0.4, 0.4)

func _on_dev_unlock_pressed():
	if cm:
		cm.dev_unlock_all()
		_refresh_all()

func _choose_next_element(element_key: String, popup: PopupPanel) -> void:
	if cm and cm.unlock_next_element(element_key):
		popup.hide()
		popup.queue_free()
		_refresh_all()

func _show_element_choice_popup() -> void:
	if not cm or not cm.pending_element_choice:
		return
	var existing = get_node_or_null("ElementChoicePopup")
	if existing:
		existing.popup_centered(Vector2i(440, 270))
		return
	var popup = PopupPanel.new()
	popup.name = "ElementChoicePopup"
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 16
	panel.content_margin_top = 16
	panel.content_margin_right = 16
	panel.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", panel)
	add_child(popup)
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 20)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_bottom", 16)
	popup.add_child(margin)
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content = VBoxContainer.new()
	content.add_theme_constant_override("separation", 8)
	margin.add_child(content)
	var heading = Label.new()
	heading.text = "Choose Your Next Element"
	heading.add_theme_font_size_override("font_size", 17)
	heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	if cinzel_font:
		heading.add_theme_font_override("font", cinzel_font)
	content.add_child(heading)
	var explanation = Label.new()
	explanation.text = "This unlocks a new discipline. Spend SP in the skill tree to learn its techniques."
	explanation.add_theme_font_size_override("font_size", 10)
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content.add_child(explanation)
	for element_key in ["fire", "water", "earth", "air"]:
		if cm.get_unlocked_elements().has(element_key):
			continue
		var choice = Button.new()
		choice.text = element_key.capitalize()
		choice.custom_minimum_size = Vector2(0, 34)
		_style_secondary_slate_button(choice, 11)
		choice.pressed.connect(_choose_next_element.bind(element_key, popup))
		content.add_child(choice)
	popup.popup_centered(Vector2i(440, 270))

func _show_primordial_choice_popup() -> void:
	if not cm or not cm.primordial_choice_pending:
		return
	var popup := PopupPanel.new()
	popup.name = "PrimordialChoicePopup"
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 16
	panel.content_margin_top = 16
	panel.content_margin_right = 16
	panel.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", panel)
	add_child(popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)
	var heading := Label.new()
	heading.text = "National Cup Reward • Choose Space or Time"
	if cinzel_font:
		heading.add_theme_font_override("font", cinzel_font)
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	box.add_child(heading)
	var explanation := Label.new()
	explanation.text = "The discipline opens now. Win a national-team World Cup, then a Club World Cup to earn one skill permit. Every technique still costs SP."
	explanation.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(explanation)
	for element in ["space", "time"]:
		if cm.primordial_choices.has(element):
			continue
		var choice := Button.new()
		choice.text = element.capitalize()
		choice.custom_minimum_size = Vector2(0, 32)
		_style_secondary_slate_button(choice, 11)
		choice.pressed.connect(func():
			if cm.choose_primordial_element(element):
				popup.queue_free()
				_refresh_all()
		)
		box.add_child(choice)
	popup.popup_centered(Vector2i(460, 220))

func _show_world_cup_reward_popup() -> void:
	if not cm or not cm.world_cup_reward_pending:
		return
	var popup := PopupPanel.new()
	popup.name = "WorldCupRewardPopup"
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 16
	panel.content_margin_top = 16
	panel.content_margin_right = 16
	panel.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", panel)
	add_child(popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)
	var heading := Label.new()
	heading.text = "World Cup Reward"
	if cinzel_font:
		heading.add_theme_font_override("font", cinzel_font)
	heading.add_theme_font_size_override("font_size", 14)
	heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	box.add_child(heading)
	for choice in ["space", "time", "skill"]:
		if cm.primordial_choices.has(choice) or (choice != "skill" and cm.primordial_choices.is_empty()):
			continue
		var option := Button.new()
		option.text = "One more primordial skill permit" if choice == "skill" else "Unlock %s" % choice.capitalize()
		option.custom_minimum_size = Vector2(0, 32)
		_style_secondary_slate_button(option, 11)
		option.pressed.connect(func():
			if cm.choose_world_cup_reward(choice):
				popup.queue_free()
				_refresh_all()
		)
		box.add_child(option)
	popup.popup_centered(Vector2i(380, 180))

func _on_enter_tournament_match():
	if cm and cm.pending_element_choice:
		_show_element_choice_popup()
		return
	if cm and cm.primordial_choice_pending:
		_show_primordial_choice_popup()
		return
	if cm and cm.world_cup_reward_pending:
		_show_world_cup_reward_popup()
		return
	if cm and cm.recruitment_offer_pending:
		if cm.accept_recruitment_offer():
			_pending_deployment_match.clear()
			_refresh_all()
		return
	var season_summary = _get_season_summary()
	if cm and str(season_summary.get("phase", "")) == "offseason":
		if cm.advance_to_next_season():
			_pending_deployment_match.clear()
			_refresh_all()
		return
	_pending_deployment_match.clear()
	var next_m = cm.get_next_scheduled_match()
	if next_m.is_empty(): return
	if next_m.has("season_day") and not cm.can_play_next_match():
		_open_calendar()
		return
	var m_type = str(next_m.get("match_type", "street" if (cm and not cm.has_team) else "tournament"))
	cm.prepare_match(m_type, next_m.get("enemy_element", "water"), next_m.get("enemy_captain", "Nami"), next_m.get("enemy_team", "Hydro Vipers"))
	# Switch directly to battle deployment tab so player can adjust grid and deploy without popups!
	_switch_tab(2)

func _get_deployment_match() -> Dictionary:
	if not _pending_deployment_match.is_empty():
		return _pending_deployment_match.duplicate()
	var match_data = cm.get_next_scheduled_match().duplicate()
	if not match_data.has("match_type"):
		match_data["match_type"] = "tournament" if cm.has_team else "street"
	return match_data

func _prepare_deployment_match() -> void:
	var match_data = _get_deployment_match()
	cm.prepare_match(match_data.get("match_type", "street"), match_data.get("enemy_element", "water"),
		match_data.get("enemy_captain", "Street Brawler"), match_data.get("enemy_team", "Underground Syndicate"))

func _on_launch_battle_arena_direct():
	if _get_deployment_match().is_empty():
		return
	if _pending_deployment_match.is_empty() and cm.get_next_scheduled_match().has("season_day") and not cm.can_play_next_match():
		_open_calendar()
		return
	_prepare_deployment_match()
	get_tree().change_scene_to_file("res://scenes/World.tscn")

func _on_activity_train():
	var popup := PopupPanel.new()
	popup.name = "TrainingFocusPopup"
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 16
	panel.content_margin_top = 16
	panel.content_margin_right = 16
	panel.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", panel)
	add_child(popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)
	var heading := Label.new()
	heading.text = "Choose a stat to train • 1 day / 15 energy"
	if cinzel_font:
		heading.add_theme_font_override("font", cinzel_font)
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	box.add_child(heading)
	for stat in cm.TRAINING_STATS:
		var gains = int(cm.training_gains.get(stat, 0))
		var threshold = 4 + mini(8, gains * 2)
		var progress = int(cm.training_progress.get(stat, 0))
		var choice := Button.new()
		var at_cap = int(cm.get("player_%s" % stat)) >= int(cm.TRAINING_CAPS[stat])
		choice.text = "%s • Training cap reached" % stat.capitalize() if at_cap else "%s • %d/%d sessions to +1" % [stat.capitalize(), progress, threshold]
		choice.disabled = at_cap
		choice.custom_minimum_size = Vector2(0, 32)
		_style_secondary_slate_button(choice, 11)
		if at_cap:
			choice.add_theme_color_override("font_color", UITheme.TEXT_MUTED)
		choice.pressed.connect(func():
			var result = cm.train_stat(stat)
			_set_activity_result("%s +1!" % stat.capitalize() if result.get("improved", false) else "%s training • %d/%d sessions" % [stat.capitalize(), result.get("progress", progress), result.get("threshold", threshold)] if result.get("success", false) else result.get("reason", "Could not train."))
			popup.queue_free()
		)
		box.add_child(choice)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 28)
	_style_secondary_slate_button(cancel_btn, 10)
	cancel_btn.pressed.connect(func(): popup.queue_free())
	box.add_child(cancel_btn)
	popup.popup_centered(Vector2i(420, 395))

func _on_activity_street():
	if cm.has_team and cm.get_days_until_next_match() == 0:
		_set_activity_result("A club match is due today. Play or skip it before a street brawl.")
		return
	if cm.energy < 20:
		if lbl_act_log:
			lbl_act_log.text = "Too exhausted for street fighting! Rest first."
			lbl_act_log.modulate = Color(1, 0.4, 0.4)
		return
	var random_elements = ["water", "earth", "air"]
	var e_elem = random_elements.pick_random()
	# Opening deployment is reversible. Match results charge the energy once.
	_pending_deployment_match = {"match_type": "street", "enemy_element": e_elem,
		"enemy_captain": "Street Brawler", "enemy_team": "Underground Syndicate"}
	_prepare_deployment_match()
	_switch_tab(2)

func _on_activity_rest():
	var popup := PopupPanel.new()
	popup.name = "RestDurationPopup"
	var panel := StyleBoxFlat.new()
	panel.bg_color = Color(0.04, 0.05, 0.09, 0.98)
	panel.border_color = Color(0.82, 0.65, 0.24, 0.85)
	panel.set_border_width_all(2)
	panel.set_corner_radius_all(8)
	panel.content_margin_left = 16
	panel.content_margin_top = 16
	panel.content_margin_right = 16
	panel.content_margin_bottom = 16
	popup.add_theme_stylebox_override("panel", panel)
	add_child(popup)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	popup.add_child(box)
	var heading := Label.new()
	heading.text = "Choose Rest Duration"
	if cinzel_font:
		heading.add_theme_font_override("font", cinzel_font)
	heading.add_theme_font_size_override("font_size", 13)
	heading.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
	box.add_child(heading)
	for days in [1, 3, 7]:
		var option := Button.new()
		option.text = "%d day(s) • +%d energy" % [days, {1: 20, 3: 50, 7: 90}[days]]
		option.custom_minimum_size = Vector2(0, 32)
		_style_secondary_slate_button(option, 11)
		option.pressed.connect(func():
			var result = cm.rest_for_days(days)
			_set_activity_result("Rested %d day(s) • Energy %d/100" % [days, cm.energy] if result.get("success", false) else result.get("reason", "Could not rest."))
			popup.queue_free()
		)
		box.add_child(option)
	var cancel_btn := Button.new()
	cancel_btn.text = "Cancel"
	cancel_btn.custom_minimum_size = Vector2(0, 28)
	_style_secondary_slate_button(cancel_btn, 10)
	cancel_btn.pressed.connect(func(): popup.queue_free())
	box.add_child(cancel_btn)
	popup.popup_centered(Vector2i(360, 230))

func _set_activity_result(message: String) -> void:
	if lbl_act_log:
		lbl_act_log.text = message
		lbl_act_log.modulate = Color(0.6, 0.9, 1.0)
	_refresh_all()

func _open_calendar() -> void:
	if not cm or not cm.has_team:
		return
	var popup = get_node_or_null("CareerCalendarPopup")
	if popup == null:
		popup = CareerCalendarPopupScript.new()
		popup.name = "CareerCalendarPopup"
		add_child(popup)
		popup.state_changed.connect(_set_activity_result)
		popup.play_requested.connect(_on_enter_tournament_match)
		popup.friendly_requested.connect(_on_friendly_requested)
	popup.open_for(cm)

func _on_friendly_requested(match_data: Dictionary) -> void:
	if cm.get_season_day() != int(match_data.get("season_day", -1)):
		return
	_pending_deployment_match = match_data.duplicate()
	_prepare_deployment_match()
	_switch_tab(2)
