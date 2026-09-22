# character_customization.gd
# Character creation and martial awakening controller for Elemental Showdown.
# Adheres to strict OOP principles: coordinates user selection and delegates campaign
# initialization to CampaignManager.
extends Control

# Identity & Discipline Controls
@onready var name_input: LineEdit = $MainLayout/Columns/LeftCol/IdentityCard/Margin/VBox/NameEdit
@onready var btn_fire: Button = $MainLayout/Columns/CenterCol/GridElements/BtnFire
@onready var btn_water: Button = $MainLayout/Columns/CenterCol/GridElements/BtnWater
@onready var btn_earth: Button = $MainLayout/Columns/CenterCol/GridElements/BtnEarth
@onready var btn_air: Button = $MainLayout/Columns/CenterCol/GridElements/BtnAir

# Discipline Lore & Starter Technique
@onready var lbl_disc_title: Label = $MainLayout/Columns/CenterCol/LoreCard/LoreMargin/LoreVBox/DisciplineTitle
@onready var lbl_disc_desc: Label = $MainLayout/Columns/CenterCol/LoreCard/LoreMargin/LoreVBox/DisciplineDesc
@onready var lbl_starter_skill: Label = $MainLayout/Columns/CenterCol/LoreCard/LoreMargin/LoreVBox/StarterSkillLabel

# Live Sprite Preview & Directional Controls
@onready var preview_sprite: Sprite2D = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/PedestalBox/PreviewFrame/PreviewSprite
@onready var btn_dir_s: Button = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/DirControls/BtnSouth
@onready var btn_dir_e: Button = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/DirControls/BtnEast
@onready var btn_dir_w: Button = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/DirControls/BtnWest
@onready var btn_dir_n: Button = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/DirControls/BtnNorth

# Stats & Role Labels
@onready var lbl_hp: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/HPLabel
@onready var lbl_mp: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/MPLabel
@onready var lbl_sta: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/StaLabel
@onready var lbl_spd: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/SpdLabel
@onready var lbl_agi: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/AgiLabel
@onready var lbl_dex: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/StatsGrid/DexLabel
@onready var lbl_role: Label = $MainLayout/Columns/RightCol/PreviewCard/Margin/VBox/RolePill/RoleLabel

# Navigation
@onready var btn_back: Button = $MainLayout/BottomBar/BtnBack
@onready var btn_start: Button = $MainLayout/BottomBar/BtnStart

var current_element: String = "fire"
var current_dir_row: int = 0 # 0=South, 1=East, 2=West, 3=North
var anim_timer: float = 0.0
var walk_frame: int = 0

const ELEMENT_LORE = {
	"fire": {
		"title": "Discipline of the Blazing Fist",
		"desc": "Focuses on explosive momentum, high burst strikes, and burning destruction to break enemy lines.",
		"skill": "Starter Martial Art: Combustion (Damage: 35 • MP: 25 • Range: 2)",
		"role": "Combat Archetype: Striker (Aggressive Offense)"
	},
	"water": {
		"title": "Discipline of the Flowing Stream",
		"desc": "Focuses on fluid evasion, vital restoration, and tidal momentum that counters reckless strikes.",
		"skill": "Starter Martial Art: Aqua Mend (Healing: 30 • MP: 20 • Range: 3)",
		"role": "Combat Archetype: Tactician & Healer (Endurance & Flow)"
	},
	"earth": {
		"title": "Discipline of the Unmovable Peak",
		"desc": "Focuses on rock-solid stances, stone shielding, and punishing counter-blows that weather any storm.",
		"skill": "Starter Martial Art: Stone Plating (Shielding: +20 Def • MP: 15 • Self)",
		"role": "Combat Archetype: Defender & Anchor (Fortress Stance)"
	},
	"air": {
		"title": "Discipline of the Whispering Gale",
		"desc": "Focuses on lightning-swift footwork, elusive dodging, and sonic displacement across the arena.",
		"skill": "Starter Martial Art: Gale Step (Mobility: +2 Speed • MP: 15 • Self)",
		"role": "Combat Archetype: Scout & Vanguard (Speed & Evasion)"
	}
}

func _ready():
	_wire_signals()
	_select_element("fire")

func _get_campaign_manager() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("CampaignManager")
	return null

func _get_element_data() -> Node:
	if is_inside_tree():
		return get_tree().root.get_node_or_null("ElementData")
	return null

func _wire_signals():
	btn_fire.pressed.connect(func(): _select_element("fire"))
	btn_water.pressed.connect(func(): _select_element("water"))
	btn_earth.pressed.connect(func(): _select_element("earth"))
	btn_air.pressed.connect(func(): _select_element("air"))

	btn_dir_s.pressed.connect(func(): _set_preview_dir(0))
	btn_dir_e.pressed.connect(func(): _set_preview_dir(1))
	btn_dir_w.pressed.connect(func(): _set_preview_dir(2))
	btn_dir_n.pressed.connect(func(): _set_preview_dir(3))

	btn_back.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/MainMenu.tscn"))
	btn_start.pressed.connect(_on_start_campaign)

func _process(delta: float):
	anim_timer += delta
	if anim_timer >= 0.22:
		anim_timer = 0.0
		walk_frame = (walk_frame + 1) % 4
		if preview_sprite:
			preview_sprite.frame = current_dir_row * 4 + walk_frame

func _select_element(elem: String):
	current_element = elem
	var edata = _get_element_data()
	if edata and edata.ELEMENTS.has(elem):
		var d = edata.ELEMENTS[elem]
		lbl_hp.text = "Health (HP): %d" % d.get("base_hp", 100)
		lbl_mp.text = "Mana (MP): %d" % d.get("base_mp", 100)
		lbl_sta.text = "Stamina: %d" % d.get("base_stamina", 100)
		lbl_spd.text = "Movement Speed: %d tiles" % d.get("base_speed", 3)
		lbl_agi.text = "Agility (Evasion): %d" % d.get("base_agility", 28)
		lbl_dex.text = "Dexterity (Crit): %d" % d.get("base_dexterity", 32)

	# Update Lore & Starter Technique
	if ELEMENT_LORE.has(elem):
		var lore = ELEMENT_LORE[elem]
		lbl_disc_title.text = lore["title"]
		lbl_disc_desc.text = lore["desc"]
		lbl_starter_skill.text = lore["skill"]
		lbl_role.text = lore["role"]

	# Update button focus highlights
	_highlight_selected_element_button()

	# Load element walk sprite sheet
	var sheet_path = "res://assets/%s_walk.png" % elem
	if ResourceLoader.exists(sheet_path):
		preview_sprite.texture = load(sheet_path)
		preview_sprite.hframes = 4
		preview_sprite.vframes = 4
		preview_sprite.frame = current_dir_row * 4

func _highlight_selected_element_button():
	var buttons = {
		"fire": btn_fire,
		"water": btn_water,
		"earth": btn_earth,
		"air": btn_air
	}
	var elem_colors = {
		"fire": Color(0.95, 0.40, 0.30),
		"water": Color(0.35, 0.65, 0.95),
		"earth": Color(0.40, 0.85, 0.50),
		"air": Color(0.30, 0.85, 0.80)
	}
	for e in buttons.keys():
		var btn: Button = buttons[e]
		var col = elem_colors[e]
		var sb = StyleBoxFlat.new()
		sb.corner_radius_top_left = 4
		sb.corner_radius_top_right = 4
		sb.corner_radius_bottom_right = 4
		sb.corner_radius_bottom_left = 4
		sb.content_margin_left = 12
		sb.content_margin_top = 8
		sb.content_margin_right = 12
		sb.content_margin_bottom = 8

		if e == current_element:
			sb.bg_color = Color(col.r * 0.16, col.g * 0.16, col.b * 0.16, 0.95)
			sb.border_width_left = 3
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = col
			sb.shadow_color = Color(col.r, col.g, col.b, 0.25)
			sb.shadow_size = 6
			btn.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		else:
			sb.bg_color = Color(0.06, 0.08, 0.12, 0.85)
			sb.border_width_left = 1
			sb.border_width_top = 1
			sb.border_width_right = 1
			sb.border_width_bottom = 1
			sb.border_color = Color(0.18, 0.23, 0.32, 0.60)
			btn.add_theme_color_override("font_color", Color(0.65, 0.72, 0.82))

		btn.add_theme_stylebox_override("normal", sb)
		btn.add_theme_stylebox_override("hover", sb)
		btn.add_theme_stylebox_override("pressed", sb)

func _set_preview_dir(row: int):
	current_dir_row = row
	if preview_sprite:
		preview_sprite.frame = current_dir_row * 4 + walk_frame

func _on_start_campaign():
	var cm = _get_campaign_manager()
	var p_name = name_input.text.strip_edges()
	if p_name.is_empty():
		p_name = "Ignis"

	var starter_skills = {
		"fire": ["Combustion"],
		"water": ["Aqua_Mend"],
		"earth": ["Stone_Plating"],
		"air": ["Gale_Step"]
	}
	var equipped = starter_skills.get(current_element, ["Combustion"])

	if cm:
		cm.init_new_campaign({
			"player_name": p_name,
			"player_element": current_element,
			"team_name": "", # Solo Street Brawler
			"start_solo": true,
			"appearance": {
				"sheet_prefix": current_element,
				"team_palette": current_element
			}
		})
		cm.equipped_abilities = equipped.duplicate()
		cm.unlocked_abilities = equipped.duplicate()
		var edata = _get_element_data()
		for sk in equipped:
			var f_keys = edata.get_skill_form_keys(sk) if edata else []
			var first_f = f_keys[0] if not f_keys.is_empty() else "form_1"
			cm.unlocked_skill_forms[sk] = [first_f]
			cm.skill_variations[sk] = first_f
		cm.save_campaign()

	get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
			get_viewport().set_input_as_handled()
