# skill_tree_canvas.gd
# Interactive radial celestial mandala and branching progression tree canvas for Elemental Showdown.
# Implements:
# 1. Authoritative progression gating (prerequisites, level requirements, SP deduction).
# 2. Celestial radial mandala: Center (Space/Time split), Inner Ring (4 Core), Outer Ring (6 Combination).
# 3. Push-out focus animation: selecting a discipline pushes other icons outward and unfolds branches.
# 4. Smooth pan & zoom navigation (mouse wheel zoom, drag pan, reset/fit view).
# 5. Full inspector panel with combat stats, form variations, prerequisites checklist, and explicit unlock button.
# 6. Strict dark-fantasy aesthetic with NO emojis and clean typography.
class_name SkillTreeCanvas
extends Control
const AbilityGeometry = preload("res://scripts/ability_geometry.gd")

signal skill_selected(skill_key: String)
signal skill_unlocked(skill_key: String)
signal discipline_selected(disc_key: String)
signal discipline_collapsed()

# ──────────────────────────────────────────────
#  CONSTANTS & GEOMETRY
# ──────────────────────────────────────────────
const R_INNER: float = 160.0          # Inner ring radius (Core elements)
const R_MIDDLE: float = 280.0         # Middle ring radius (Double combinations)
const R_OUTER: float = 410.0          # Outermost ring radius (Triple combinations)
const PUSH_OUT_MULT: float = 2.4      # Outward push multiplier when focused
const MIN_ZOOM: float = 0.25
const MAX_ZOOM: float = 1.60

const ELEMENT_SIGILS = {
	"fire": "res://assets/ui/icon_fire_sigil.png",
	"water": "res://assets/ui/icon_water_sigil.png",
	"earth": "res://assets/ui/icon_earth_sigil.png",
	"air": "res://assets/ui/icon_air_sigil.png",
	"space": "res://assets/ui/icon_space_sigil.png",
	"time": "res://assets/ui/icon_time_sigil.png",
}

const ELEMENT_COLORS = {
	"fire": Color(0.95, 0.35, 0.20),
	"earth": Color(0.40, 0.75, 0.45),
	"water": Color(0.25, 0.65, 0.98),
	"air": Color(0.30, 0.85, 0.80),
	"space": Color(0.70, 0.40, 0.95),
	"time": Color(0.88, 0.72, 0.22)
}

const CORE_DISCIPLINES = [
	{"key": "fire",  "name": "Fire",  "angle": -90.0, "color": Color(0.95, 0.35, 0.20), "sigil": "res://assets/ui/icon_fire_sigil.png"},
	{"key": "earth", "name": "Earth", "angle": 0.0,   "color": Color(0.40, 0.75, 0.45), "sigil": "res://assets/ui/icon_earth_sigil.png"},
	{"key": "water", "name": "Water", "angle": 90.0,  "color": Color(0.25, 0.65, 0.98), "sigil": "res://assets/ui/icon_water_sigil.png"},
	{"key": "air",   "name": "Air",   "angle": 180.0, "color": Color(0.30, 0.85, 0.80), "sigil": "res://assets/ui/icon_air_sigil.png"}
]

const COMBO_DISCIPLINES = [
	{"key": "fire_air",    "name": "Fire + Air",    "angle": -135.0, "color": Color(0.92, 0.40, 0.85), "reqs": ["fire", "air"], "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_air_sigil.png"]},
	{"key": "fire_earth",  "name": "Fire + Earth",  "angle": -45.0,  "color": Color(0.96, 0.48, 0.15), "reqs": ["fire", "earth"], "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_earth_sigil.png"]},
	{"key": "fire_water",  "name": "Fire + Water",  "angle": -15.0,  "color": Color(0.72, 0.50, 0.85), "reqs": ["fire", "water"], "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_water_sigil.png"]},
	{"key": "water_earth", "name": "Water + Earth", "angle": 45.0,   "color": Color(0.58, 0.62, 0.32), "reqs": ["water", "earth"], "sigils": ["res://assets/ui/icon_water_sigil.png", "res://assets/ui/icon_earth_sigil.png"]},
	{"key": "earth_air",   "name": "Earth + Air",   "angle": 135.0,  "color": Color(0.80, 0.72, 0.45), "reqs": ["earth", "air"], "sigils": ["res://assets/ui/icon_earth_sigil.png", "res://assets/ui/icon_air_sigil.png"]},
	{"key": "water_air",   "name": "Water + Air",   "angle": 165.0,  "color": Color(0.40, 0.78, 0.96), "reqs": ["water", "air"], "sigils": ["res://assets/ui/icon_water_sigil.png", "res://assets/ui/icon_air_sigil.png"]}
]

const TRIPLE_DISCIPLINES = [
	{"key": "fire_water_earth", "name": "Fire + Water + Earth", "angle": -30.0,  "color": Color(0.85, 0.48, 0.28), "reqs": ["fire", "water", "earth"], "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_water_sigil.png", "res://assets/ui/icon_earth_sigil.png"]},
	{"key": "fire_water_air",   "name": "Fire + Water + Air",   "angle": -150.0, "color": Color(0.55, 0.68, 0.95), "reqs": ["fire", "water", "air"],   "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_water_sigil.png", "res://assets/ui/icon_air_sigil.png"]},
	{"key": "fire_earth_air",   "name": "Fire + Earth + Air",   "angle": 30.0,   "color": Color(0.92, 0.58, 0.32), "reqs": ["fire", "earth", "air"],   "sigils": ["res://assets/ui/icon_fire_sigil.png", "res://assets/ui/icon_earth_sigil.png", "res://assets/ui/icon_air_sigil.png"]},
	{"key": "water_earth_air",  "name": "Water + Earth + Air",  "angle": 150.0,  "color": Color(0.38, 0.78, 0.65), "reqs": ["water", "earth", "air"],  "sigils": ["res://assets/ui/icon_water_sigil.png", "res://assets/ui/icon_earth_sigil.png", "res://assets/ui/icon_air_sigil.png"]}
]

# ──────────────────────────────────────────────
#  VIEWPORT & STATE
# ──────────────────────────────────────────────
var zoom_level: float = 0.68
var pan_offset: Vector2 = Vector2.ZERO
var is_panning: bool = false
var pan_start_mouse: Vector2 = Vector2.ZERO
var pan_start_offset: Vector2 = Vector2.ZERO

var focused_discipline: String = ""       # Empty = resting mandala; otherwise "fire", "space_time", etc.
var selected_skill_key: String = ""       # Inspected skill
var transition_progress: float = 0.0:      # 0.0 = resting, 1.0 = fully focused
	set(val):
		transition_progress = val
		_update_positions_and_redraw()

var current_tween: Tween = null

# Node tracking: key -> Control widget
var discipline_buttons: Dictionary = {}
var skill_node_widgets: Dictionary = {}
var skill_node_targets: Dictionary = {}

# Node references
var world_container: Control = null
var lines_canvas: Control = null
var nodes_container: Control = null
var nav_bar: HBoxContainer = null
var inspector_panel: PanelContainer = null
var inspector_vbox: VBoxContainer = null
var btn_back: Button = null
var zoom_lbl: Label = null
var sp_badge: Label = null

var cinzel_font: Font = null

func _ready():
	clip_contents = true
	cinzel_font = load("res://assets/fonts/Cinzel-Bold.ttf")
	_build_ui_layout()
	call_deferred("_initialize_mandala")

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		_update_viewport_transform()
		if lines_canvas:
			lines_canvas.queue_redraw()

# ──────────────────────────────────────────────
#  UI STRUCTURE SETUP
# ──────────────────────────────────────────────
func _build_ui_layout():
	# Background surface
	var bg = ColorRect.new()
	bg.color = Color(0.025, 0.035, 0.055, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	# World container subjected to Pan & Zoom
	world_container = Control.new()
	world_container.name = "WorldContainer"
	world_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	world_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(world_container)

	# Custom drawing layer for mandala rings & skill branch lines
	lines_canvas = Control.new()
	lines_canvas.name = "LinesCanvas"
	lines_canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	lines_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lines_canvas.draw.connect(_on_lines_canvas_draw)
	world_container.add_child(lines_canvas)

	# Container for interactive buttons/nodes inside the world
	nodes_container = Control.new()
	nodes_container.name = "NodesContainer"
	nodes_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	nodes_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world_container.add_child(nodes_container)

	# Fixed Navigation Bar (top)
	_build_nav_bar()

	# Fixed Inspector Panel (right)
	_build_inspector_panel()

func _build_nav_bar():
	nav_bar = HBoxContainer.new()
	nav_bar.name = "NavBar"
	nav_bar.anchor_left = 0.0
	nav_bar.anchor_top = 0.0
	nav_bar.anchor_right = 1.0
	nav_bar.offset_left = 12
	nav_bar.offset_top = 10
	nav_bar.offset_right = -318   # Leave room for inspector on right
	nav_bar.offset_bottom = 42
	nav_bar.add_theme_constant_override("separation", 6)
	add_child(nav_bar)

	# Back button (visible when focused)
	btn_back = Button.new()
	btn_back.text = "Back to Disciplines"
	btn_back.custom_minimum_size = Vector2(130, 28)
	btn_back.add_theme_font_size_override("font_size", 9)
	btn_back.visible = false
	_style_nav_button(btn_back, Color(0.12, 0.16, 0.24, 0.95), UITheme.BORDER_GOLD, UITheme.GOLD_PRIMARY)
	btn_back.pressed.connect(collapse_to_mandala)
	nav_bar.add_child(btn_back)

	# Reset View button
	var btn_reset = Button.new()
	btn_reset.text = "Reset"
	btn_reset.custom_minimum_size = Vector2(68, 28)
	btn_reset.add_theme_font_size_override("font_size", 9)
	_style_nav_button(btn_reset, Color(0.08, 0.10, 0.16, 0.9), UITheme.BORDER_SUBTLE, UITheme.TEXT_SECONDARY)
	btn_reset.pressed.connect(reset_view)
	nav_bar.add_child(btn_reset)

	# Fit Tree button
	var btn_fit = Button.new()
	btn_fit.text = "Fit Tree"
	btn_fit.custom_minimum_size = Vector2(68, 28)
	btn_fit.add_theme_font_size_override("font_size", 9)
	_style_nav_button(btn_fit, Color(0.08, 0.10, 0.16, 0.9), UITheme.BORDER_SUBTLE, UITheme.TEXT_SECONDARY)
	btn_fit.pressed.connect(fit_tree)
	nav_bar.add_child(btn_fit)

	# Zoom controls
	var btn_zoom_out = Button.new()
	btn_zoom_out.text = "-"
	btn_zoom_out.custom_minimum_size = Vector2(26, 28)
	btn_zoom_out.add_theme_font_size_override("font_size", 10)
	_style_nav_button(btn_zoom_out, Color(0.08, 0.10, 0.16, 0.9), UITheme.BORDER_SUBTLE, UITheme.TEXT_PRIMARY)
	btn_zoom_out.pressed.connect(func(): _adjust_zoom(-0.15, size * 0.5))
	nav_bar.add_child(btn_zoom_out)

	zoom_lbl = Label.new()
	zoom_lbl.text = "%d%%" % int(round(zoom_level * 100))
	zoom_lbl.custom_minimum_size = Vector2(40, 28)
	zoom_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	zoom_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	zoom_lbl.add_theme_font_size_override("font_size", 9)
	zoom_lbl.modulate = UITheme.TEXT_SECONDARY
	nav_bar.add_child(zoom_lbl)

	var btn_zoom_in = Button.new()
	btn_zoom_in.text = "+"
	btn_zoom_in.custom_minimum_size = Vector2(26, 28)
	btn_zoom_in.add_theme_font_size_override("font_size", 10)
	_style_nav_button(btn_zoom_in, Color(0.08, 0.10, 0.16, 0.9), UITheme.BORDER_SUBTLE, UITheme.TEXT_PRIMARY)
	btn_zoom_in.pressed.connect(func(): _adjust_zoom(0.15, size * 0.5))
	nav_bar.add_child(btn_zoom_in)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nav_bar.add_child(spacer)

	# Available SP Badge
	sp_badge = Label.new()
	sp_badge.text = "Available: 0 SP"
	sp_badge.custom_minimum_size = Vector2(110, 28)
	sp_badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sp_badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	sp_badge.add_theme_font_size_override("font_size", 9)
	if cinzel_font:
		sp_badge.add_theme_font_override("font", cinzel_font)
	sp_badge.modulate = UITheme.GOLD_PRIMARY
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.12, 0.10, 0.06, 0.95)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = UITheme.BORDER_GOLD
	sb.set_corner_radius_all(14)
	sp_badge.add_theme_stylebox_override("normal", sb)
	nav_bar.add_child(sp_badge)

func _build_inspector_panel():
	inspector_panel = PanelContainer.new()
	inspector_panel.name = "InspectorPanel"
	inspector_panel.anchor_left = 1.0
	inspector_panel.anchor_top = 0.0
	inspector_panel.anchor_right = 1.0
	inspector_panel.anchor_bottom = 1.0
	inspector_panel.offset_left = -310
	inspector_panel.offset_top = 10
	inspector_panel.offset_right = -8
	inspector_panel.offset_bottom = -10
	inspector_panel.custom_minimum_size = Vector2(300, 0)
	inspector_panel.clip_contents = true

	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.07, 0.11, 0.96)
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.border_color = UITheme.BORDER_SUBTLE
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	inspector_panel.add_theme_stylebox_override("panel", sb)

	var scroll = ScrollContainer.new()
	scroll.name = "ScrollContainer"
	scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.clip_contents = true
	inspector_panel.add_child(scroll)

	inspector_vbox = VBoxContainer.new()
	inspector_vbox.name = "InspectorVBox"
	inspector_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	inspector_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(inspector_vbox)

	add_child(inspector_panel)
	_render_empty_inspector()

# ──────────────────────────────────────────────
#  MANDALA INITIALIZATION
# ──────────────────────────────────────────────
func _initialize_mandala():
	_clear_all_nodes()
	_update_sp_badge()

	# 1. Center Primordial Medallion (Space / Time)
	_create_center_space_time_medallion()

	# 2. Inner Ring: 4 Core Elements
	for c_data in CORE_DISCIPLINES:
		_create_discipline_icon(c_data["key"], c_data["name"], R_INNER, c_data["angle"], c_data["color"], "core", [], [c_data["sigil"]])

	# 3. Middle Ring: 6 Double Combination Elements
	for combo in COMBO_DISCIPLINES:
		_create_discipline_icon(combo["key"], combo["name"], R_MIDDLE, combo["angle"], combo["color"], "combination", combo["reqs"], combo["sigils"])

	# 4. Outermost Ring: 4 Triple Combination Elements
	for triple in TRIPLE_DISCIPLINES:
		_create_discipline_icon(triple["key"], triple["name"], R_OUTER, triple["angle"], triple["color"], "triple", triple["reqs"], triple["sigils"])

	# Setup backward-compatibility aliases in discipline_buttons
	var aliases = {
		"steam": "fire_water",
		"magma": "fire_earth",
		"plasma": "fire_air",
		"quicksand": "water_earth",
		"blizzard": "water_air",
		"dust_devil": "earth_air",
		"hydrothermal_forge": "fire_water_earth",
		"tempest_flame": "fire_water_air",
		"pyroclastic_storm": "fire_earth_air",
		"lifeweave": "water_earth_air"
	}
	for al in aliases:
		var target_k = aliases[al]
		if discipline_buttons.has(target_k):
			discipline_buttons[al] = discipline_buttons[target_k]

	# A new Control has its minimum size but has not finished container layout yet.
	# Wait for that layout before measuring the cards for the initial fit.
	_fit_after_layout()
	lines_canvas.queue_redraw()

func _fit_after_layout() -> void:
	await get_tree().process_frame
	if is_inside_tree():
		fit_tree()

func _clear_all_nodes():
	for k in discipline_buttons:
		var btn = discipline_buttons[k]
		if is_instance_valid(btn):
			btn.queue_free()
	discipline_buttons.clear()

	for k in skill_node_widgets:
		var w = skill_node_widgets[k]
		if is_instance_valid(w):
			w.queue_free()
	skill_node_widgets.clear()
	skill_node_targets.clear()

func _create_center_space_time_medallion():
	var center_box = HBoxContainer.new()
	center_box.name = "Medallion_Space_Time"
	center_box.custom_minimum_size = Vector2(210, 72)
	center_box.add_theme_constant_override("separation", 4)

	# Left Half: Space
	var btn_space = Button.new()
	btn_space.name = "Btn_Space"
	btn_space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_space.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_medallion_half(btn_space, Color(0.18, 0.10, 0.28, 0.95), Color(0.70, 0.40, 0.95), true)

	var space_vbox = VBoxContainer.new()
	space_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	space_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	space_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_vbox.add_theme_constant_override("separation", 2)

	var space_icon = TextureRect.new()
	space_icon.texture = load("res://assets/ui/icon_space_sigil.png")
	space_icon.custom_minimum_size = Vector2(22, 22)
	space_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	space_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	space_icon.modulate = Color(0.70, 0.40, 0.95)
	space_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_vbox.add_child(space_icon)

	var space_lbl = Label.new()
	space_lbl.text = "Space"
	space_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	space_lbl.add_theme_font_size_override("font_size", 10)
	if cinzel_font: space_lbl.add_theme_font_override("font", cinzel_font)
	space_lbl.modulate = Color(0.85, 0.65, 1.0)
	space_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_vbox.add_child(space_lbl)

	var space_sub = Label.new()
	space_sub.text = "[ Primordial ]"
	space_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	space_sub.add_theme_font_size_override("font_size", 8)
	space_sub.modulate = Color(0.65, 0.55, 0.80, 0.85)
	space_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	space_vbox.add_child(space_sub)

	btn_space.add_child(space_vbox)
	btn_space.pressed.connect(func(): focus_discipline("space"))
	center_box.add_child(btn_space)

	# Right Half: Time
	var btn_time = Button.new()
	btn_time.name = "Btn_Time"
	btn_time.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn_time.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_style_medallion_half(btn_time, Color(0.24, 0.18, 0.08, 0.95), UITheme.GOLD_PRIMARY, false)

	var time_vbox = VBoxContainer.new()
	time_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	time_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	time_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_vbox.add_theme_constant_override("separation", 2)

	var time_icon = TextureRect.new()
	time_icon.texture = load("res://assets/ui/icon_time_sigil.png")
	time_icon.custom_minimum_size = Vector2(22, 22)
	time_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	time_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	time_icon.modulate = UITheme.GOLD_PRIMARY
	time_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_vbox.add_child(time_icon)

	var time_lbl = Label.new()
	time_lbl.text = "Time"
	time_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_lbl.add_theme_font_size_override("font_size", 10)
	if cinzel_font: time_lbl.add_theme_font_override("font", cinzel_font)
	time_lbl.modulate = UITheme.GOLD_PRIMARY
	time_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_vbox.add_child(time_lbl)

	var time_sub = Label.new()
	time_sub.text = "[ Primordial ]"
	time_sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_sub.add_theme_font_size_override("font_size", 8)
	time_sub.modulate = Color(0.85, 0.75, 0.50, 0.85)
	time_sub.mouse_filter = Control.MOUSE_FILTER_IGNORE
	time_vbox.add_child(time_sub)

	btn_time.add_child(time_vbox)
	btn_time.pressed.connect(func(): focus_discipline("time"))
	center_box.add_child(btn_time)

	nodes_container.add_child(center_box)
	discipline_buttons["space_time"] = center_box

func _create_discipline_icon(disc_key: String, disc_name: String, radius: float, angle_deg: float, accent_color: Color, category: String, reqs: Array = [], sigils: Array = []):
	var cm = get_node_or_null("/root/CampaignManager")
	var is_accessible = true
	var lock_reason = ""
	if cm and cm.has_method("can_access_discipline"):
		var access = cm.can_access_discipline(disc_key)
		is_accessible = access.get("can_access", true)
		lock_reason = access.get("reason", "")

	var btn = Button.new()
	btn.name = "Disc_" + disc_key

	var width = 114
	if category == "combination":
		width = 136
	elif category == "triple":
		width = 166
	btn.custom_minimum_size = Vector2(width, 62)

	# Content container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)

	# Sigils row
	var sigil_row = HBoxContainer.new()
	sigil_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sigil_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sigil_row.add_theme_constant_override("separation", 4)

	var icon_sz = Vector2(22, 22)
	if category == "combination":
		icon_sz = Vector2(18, 18)
	elif category == "triple":
		icon_sz = Vector2(16, 16)

	if not sigils.is_empty():
		for idx in range(sigils.size()):
			var s_path = sigils[idx]
			var tr = TextureRect.new()
			tr.texture = load(s_path)
			tr.custom_minimum_size = icon_sz
			tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
			if category == "core":
				tr.modulate = accent_color
			elif reqs.size() > idx:
				tr.modulate = ELEMENT_COLORS.get(reqs[idx], accent_color)
			else:
				tr.modulate = accent_color
			sigil_row.add_child(tr)
	vbox.add_child(sigil_row)

	# Name Label
	var title_lbl = Label.new()
	title_lbl.text = disc_name
	title_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var font_sz = 10
	if category == "combination":
		font_sz = 9
	elif category == "triple":
		font_sz = 8
	title_lbl.add_theme_font_size_override("font_size", font_sz)
	if cinzel_font:
		title_lbl.add_theme_font_override("font", cinzel_font)
	title_lbl.modulate = Color(1.0, 1.0, 1.0, 1.0) if is_accessible else Color(0.70, 0.72, 0.78, 0.70)
	title_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(title_lbl)

	# Category or Lock Subtitle Label
	var sub_lbl = Label.new()
	var cat_label = "[ %s ]" % category.capitalize()
	if category == "triple":
		cat_label = "[ Triple Fusion ]"
	if not is_accessible:
		var req_names = []
		for r in reqs:
			req_names.append(r.capitalize())
		cat_label = "[ %s ]" % (" + ".join(req_names))
	sub_lbl.text = cat_label
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 7 if category == "triple" else 8)
	sub_lbl.modulate = accent_color if is_accessible else Color(0.50, 0.55, 0.65, 0.60)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	btn.add_child(vbox)

	# Styling based on accessible state
	var sb = StyleBoxFlat.new()
	if is_accessible:
		sb.bg_color = Color(0.07, 0.09, 0.14, 0.95)
		sb.border_color = accent_color
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	else:
		sb.bg_color = Color(0.04, 0.05, 0.07, 0.85)
		sb.border_color = Color(0.25, 0.28, 0.35, 0.70)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		btn.modulate = Color(0.65, 0.68, 0.75, 0.65)

	sb.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

	btn.set_meta("resting_radius", radius)
	btn.set_meta("resting_angle", angle_deg)
	btn.set_meta("disc_key", disc_key)
	btn.set_meta("is_accessible", is_accessible)
	btn.set_meta("lock_reason", lock_reason)

	btn.pressed.connect(func(): _on_discipline_button_pressed(disc_key, is_accessible, lock_reason))

	nodes_container.add_child(btn)
	discipline_buttons[disc_key] = btn

# ──────────────────────────────────────────────
#  INTERACTION: DISCIPLINE SELECTION & FOCUS
# ──────────────────────────────────────────────
func _on_discipline_button_pressed(disc_key: String, is_accessible: bool, lock_reason: String):
	if not is_accessible:
		_inspect_locked_discipline(disc_key, lock_reason)
		return
	focus_discipline(disc_key)

func focus_discipline(disc_key: String):
	if focused_discipline == disc_key and transition_progress >= 0.95:
		return

	focused_discipline = disc_key
	btn_back.visible = true
	emit_signal("discipline_selected", disc_key)

	# Build and populate procedural skill nodes for this discipline
	_spawn_skill_nodes_for_discipline(disc_key)

	# Animate push-out transition smoothly without freeze
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_method(func(v: float): transition_progress = v, transition_progress, 1.0, 0.35)
	current_tween.tween_callback(fit_tree)

	# Auto-inspect the root or first skill
	if not skill_node_widgets.is_empty():
		var first_key = skill_node_widgets.keys()[0]
		inspect_skill(first_key)

func collapse_to_mandala():
	if focused_discipline == "" and transition_progress <= 0.05:
		return

	btn_back.visible = false
	emit_signal("discipline_collapsed")

	if current_tween and current_tween.is_valid():
		current_tween.kill()

	current_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	current_tween.tween_method(func(v: float): transition_progress = v, transition_progress, 0.0, 0.30)
	current_tween.tween_callback(Callable(self, "_on_collapse_completed"))

func _on_collapse_completed():
	focused_discipline = ""
	selected_skill_key = ""
	for k in skill_node_widgets:
		var w = skill_node_widgets[k]
		if is_instance_valid(w):
			w.queue_free()
	skill_node_widgets.clear()
	skill_node_targets.clear()
	_render_empty_inspector()
	_update_positions_and_redraw()
	fit_tree()

# ──────────────────────────────────────────────
#  PROCEDURAL SKILL NODES SPAWNING
# ──────────────────────────────────────────────
func _spawn_skill_nodes_for_discipline(disc_key: String):
	# Clear previous skill nodes
	for k in skill_node_widgets:
		var w = skill_node_widgets[k]
		if is_instance_valid(w):
			w.queue_free()
	skill_node_widgets.clear()
	skill_node_targets.clear()

	var edata = get_node_or_null("/root/ElementData")
	if not edata: return

	# Space / Time dual primordial layout
	if disc_key == "space" or disc_key == "time" or disc_key == "space_time":
		_spawn_space_time_nodes(edata)
		return

	# Core or Combination disciplines
	var nodes_data = edata.get_skill_tree_nodes(disc_key)
	if nodes_data.is_empty():
		return

	for n in nodes_data:
		var s_key = n.get("key", "")
		var b_tier = int(n.get("branch_tier", 1))
		var b_angle = float(n.get("branch_angle", 0.0))
		var b_idx = int(n.get("branch_index", 0))

		# Horizontal branches need more separation than each 148px-wide card.
		var dist = 190.0 + (b_tier - 1) * 180.0
		var rad = deg_to_rad(b_angle)
		var target_pos = Vector2(cos(rad), sin(rad)) * dist

		# Directional anchor offset per element category
		match disc_key:
			"fire":
				target_pos += Vector2(0, 60)
			"water":
				target_pos += Vector2(0, -60)
			"earth":
				target_pos += Vector2(-60, 0)
			"air":
				target_pos += Vector2(60, 0)
			_:
				target_pos += Vector2(-40, 0)

		var widget = _create_skill_node_widget(n)
		nodes_container.add_child(widget)
		skill_node_widgets[s_key] = widget
		skill_node_targets[s_key] = target_pos

func _spawn_space_time_nodes(edata: Node):
	var space_nodes = edata.get_skill_tree_nodes("space")
	var time_nodes = edata.get_skill_tree_nodes("time")

	# Space branches unfold to the LEFT (x < 0)
	for n in space_nodes:
		var s_key = n.get("key", "")
		var b_tier = int(n.get("branch_tier", 1))
		var target_pos = Vector2.ZERO
		match s_key:
			"Spatial_Shift":
				target_pos = Vector2(-190, 0)
			"Spatial_Compression":
				target_pos = Vector2(-370, -75)
			"Spatial_Barrier":
				target_pos = Vector2(-370, 75)
			"Space":
				target_pos = Vector2(-550, 0)
			_:
				target_pos = Vector2(-190.0 - (b_tier - 1) * 180.0, 0)

		var widget = _create_skill_node_widget(n)
		nodes_container.add_child(widget)
		skill_node_widgets[s_key] = widget
		skill_node_targets[s_key] = target_pos

	# Time branches unfold to the RIGHT (x > 0)
	for n in time_nodes:
		var s_key = n.get("key", "")
		var b_tier = int(n.get("branch_tier", 1))
		var target_pos = Vector2.ZERO
		match s_key:
			"Time_Dilation":
				target_pos = Vector2(190, 0)
			"Chrono_Acceleration":
				target_pos = Vector2(370, -75)
			"Temporal_Decay":
				target_pos = Vector2(370, 75)
			"Chrono_Stasis":
				target_pos = Vector2(550, 0)
			_:
				target_pos = Vector2(190.0 + (b_tier - 1) * 180.0, 0)

		var widget = _create_skill_node_widget(n)
		nodes_container.add_child(widget)
		skill_node_widgets[s_key] = widget
		skill_node_targets[s_key] = target_pos

func _create_skill_node_widget(node_data: Dictionary) -> Control:
	var s_key = node_data.get("key", "")
	var s_name = node_data.get("display_name", s_key.replace("_", " "))
	var tier = node_data.get("tier", "basic")

	var btn = Button.new()
	btn.name = "SkillNode_" + s_key
	btn.custom_minimum_size = Vector2(148, 52)

	var cm = get_node_or_null("/root/CampaignManager")
	var is_unlocked = false
	var can_unlock = false
	if cm:
		is_unlocked = cm.unlocked_abilities.has(s_key)
		if not is_unlocked and cm.has_method("can_unlock_skill"):
			var chk = cm.can_unlock_skill(s_key)
			can_unlock = chk.get("can_unlock", false)

	# Visual state badge
	var status_tag = "Locked"
	if is_unlocked:
		status_tag = "Unlocked"
	elif can_unlock:
		status_tag = "Available"

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)

	var name_lbl = Label.new()
	name_lbl.text = s_name
	name_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_lbl.add_theme_font_size_override("font_size", 9)
	if cinzel_font:
		name_lbl.add_theme_font_override("font", cinzel_font)
	name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_lbl)

	var sub_lbl = Label.new()
	sub_lbl.text = "[ %s • %s ]" % [tier.capitalize(), status_tag]
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub_lbl.add_theme_font_size_override("font_size", 8)
	sub_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(sub_lbl)

	btn.add_child(vbox)

	_style_skill_node_button(btn, is_unlocked, can_unlock, (s_key == selected_skill_key))

	btn.pressed.connect(func(): inspect_skill(s_key))
	btn.set_meta("node_data", node_data)
	return btn

# ──────────────────────────────────────────────
#  STYLING HELPERS
# ──────────────────────────────────────────────
func _style_medallion_half(btn: Button, bg_col: Color, border_col: Color, is_left: bool):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.border_width_left = 2 if is_left else 1
	sb.border_width_right = 1 if is_left else 2
	sb.border_width_top = 2
	sb.border_width_bottom = 2
	if is_left:
		sb.corner_radius_top_left = 12
		sb.corner_radius_bottom_left = 12
	else:
		sb.corner_radius_top_right = 12
		sb.corner_radius_bottom_right = 12
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_font_size_override("font_size", 9)
	if cinzel_font:
		btn.add_theme_font_override("font", cinzel_font)

func _style_nav_button(btn: Button, bg_col: Color, border_col: Color, text_col: Color):
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_col
	sb.border_color = border_col
	sb.border_width_left = 1
	sb.border_width_top = 1
	sb.border_width_right = 1
	sb.border_width_bottom = 1
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)
	btn.add_theme_font_size_override("font_size", 10)
	btn.modulate = text_col

func _style_skill_node_button(btn: Button, is_unlocked: bool, can_unlock: bool, is_selected: bool):
	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(6)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6

	if is_selected:
		sb.bg_color = Color(0.14, 0.16, 0.22, 0.98)
		sb.border_color = UITheme.BORDER_GOLD
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif is_unlocked:
		sb.bg_color = Color(0.08, 0.12, 0.18, 0.95)
		sb.border_color = Color(0.35, 0.70, 0.95, 0.90)
		sb.border_width_left = 2
		sb.border_width_top = 2
		sb.border_width_right = 2
		sb.border_width_bottom = 2
		btn.modulate = Color(0.92, 0.96, 1.0, 1.0)
	elif can_unlock:
		sb.bg_color = Color(0.12, 0.10, 0.05, 0.92)
		sb.border_color = UITheme.GOLD_PRIMARY
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		btn.modulate = Color(1.0, 0.90, 0.60, 1.0)
	else:
		sb.bg_color = Color(0.04, 0.05, 0.07, 0.85)
		sb.border_color = Color(0.20, 0.24, 0.32, 0.60)
		sb.border_width_left = 1
		sb.border_width_top = 1
		sb.border_width_right = 1
		sb.border_width_bottom = 1
		btn.modulate = Color(0.55, 0.60, 0.70, 0.65)

	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("pressed", sb)

# ──────────────────────────────────────────────
#  VIEWPORT TRANSFORM & POSITION UPDATES
# ──────────────────────────────────────────────
func _update_viewport_transform():
	if not world_container: return

	world_container.scale = Vector2(zoom_level, zoom_level)
	# Center in the available view area to the left of the inspector panel
	var avail_w = maxf(size.x - 350.0, 100.0)
	var c = Vector2(avail_w * 0.5, size.y * 0.5) + pan_offset
	world_container.position = c

	_update_positions_and_redraw()

func _update_positions_and_redraw():
	# Update positions of discipline buttons (deduplicated by instance)
	var processed_buttons = {}
	for k in discipline_buttons:
		var btn = discipline_buttons[k]
		if not is_instance_valid(btn) or processed_buttons.has(btn): continue
		processed_buttons[btn] = true

		if k == "space_time":
			var sz = btn.custom_minimum_size
			var target_pos = -sz * 0.5
			# If focusing a different discipline, push center out or hide
			if focused_discipline != "" and focused_discipline != "space" and focused_discipline != "time" and focused_discipline != "space_time":
				btn.modulate.a = lerp(1.0, 0.0, transition_progress)
				btn.visible = (transition_progress < 0.95)
			else:
				btn.modulate.a = 1.0
				btn.visible = true
			btn.position = target_pos
			continue

		var resting_r = float(btn.get_meta("resting_radius", R_INNER))
		var angle_deg = float(btn.get_meta("resting_angle", 0.0))
		var is_focused = (focused_discipline == k)

		var current_r = resting_r
		var alpha = 1.0

		var rad = deg_to_rad(angle_deg)
		var center_offset = Vector2(cos(rad), sin(rad)) * current_r

		if focused_discipline != "":
			if is_focused:
				# Selected discipline moves to center anchor
				var anchor = Vector2.ZERO
				match k:
					"fire": anchor = Vector2(0, 60)
					"water": anchor = Vector2(0, -60)
					"earth": anchor = Vector2(-60, 0)
					"air": anchor = Vector2(60, 0)
					_: anchor = Vector2(-40, 0)
				center_offset = lerp(center_offset, anchor, transition_progress)
				alpha = 1.0
				btn.visible = true
			else:
				# Non-selected disciplines push outward and fade
				current_r = lerp(resting_r, resting_r * PUSH_OUT_MULT + 200.0, transition_progress)
				center_offset = Vector2(cos(rad), sin(rad)) * current_r
				alpha = lerp(1.0, 0.04, transition_progress)
				btn.visible = (transition_progress < 0.95)
		else:
			btn.visible = true

		var b_sz = btn.custom_minimum_size
		btn.position = center_offset - b_sz * 0.5
		btn.modulate.a = alpha

	# Update positions of skill node widgets
	for s_key in skill_node_widgets:
		var w = skill_node_widgets[s_key]
		if not is_instance_valid(w): continue
		var target_pos = skill_node_targets.get(s_key, Vector2.ZERO)
		var anchor = Vector2.ZERO
		match focused_discipline:
			"fire": anchor = Vector2(0, 60)
			"water": anchor = Vector2(0, -60)
			"earth": anchor = Vector2(-60, 0)
			"air": anchor = Vector2(60, 0)
			_: anchor = Vector2(-40, 0)

		var cur_pos = lerp(anchor, target_pos, transition_progress)
		var w_sz = w.custom_minimum_size
		w.position = cur_pos - w_sz * 0.5
		w.modulate.a = transition_progress

	if lines_canvas:
		lines_canvas.queue_redraw()

# ──────────────────────────────────────────────
#  CANVAS DRAWING: MANDALA RINGS & BRANCH LINES
# ──────────────────────────────────────────────
func _on_lines_canvas_draw():
	# 1. Subtle Celestial Rings & Spokes (fades when focused)
	var mandala_alpha = lerp(0.35, 0.05, transition_progress)
	if mandala_alpha > 0.02:
		var ring_col_inner = Color(0.40, 0.50, 0.65, mandala_alpha * 0.5)
		var ring_col_middle = Color(0.70, 0.55, 0.80, mandala_alpha * 0.45)
		var ring_col_outer = Color(0.85, 0.70, 0.30, mandala_alpha * 0.40)
		lines_canvas.draw_arc(Vector2.ZERO, R_INNER, 0, TAU, 64, ring_col_inner, 1.2)
		lines_canvas.draw_arc(Vector2.ZERO, R_MIDDLE, 0, TAU, 64, ring_col_middle, 1.2)
		lines_canvas.draw_arc(Vector2.ZERO, R_OUTER, 0, TAU, 64, ring_col_outer, 1.4)

		# Faint radial spokes to cardinal and diagonal directions
		for angle in [-90, -45, 0, 45, 90, 135, 180, -135]:
			var r = deg_to_rad(angle)
			var v1 = Vector2(cos(r), sin(r)) * (R_INNER + 25)
			var v2 = Vector2(cos(r), sin(r)) * (R_OUTER - 25)
			lines_canvas.draw_line(v1, v2, Color(0.40, 0.50, 0.65, mandala_alpha * 0.3), 1.0)

	# 2. Skill Branch Lines (only when focused discipline active)
	if transition_progress > 0.05 and not skill_node_widgets.is_empty():
		var cm = get_node_or_null("/root/CampaignManager")
		var edata = get_node_or_null("/root/ElementData")
		if not edata: return

		var anchor_pos = Vector2.ZERO
		match focused_discipline:
			"fire": anchor_pos = Vector2(0, 60)
			"water": anchor_pos = Vector2(0, -60)
			"earth": anchor_pos = Vector2(-60, 0)
			"air": anchor_pos = Vector2(60, 0)
			"space", "time", "space_time": anchor_pos = Vector2.ZERO
			_: anchor_pos = Vector2(-40, 0)

		for s_key in skill_node_widgets:
			var w = skill_node_widgets[s_key]
			if not is_instance_valid(w): continue

			var node_data = w.get_meta("node_data", {})
			var prereqs = node_data.get("prerequisites", [])
			var child_pos = lerp(anchor_pos, skill_node_targets.get(s_key, anchor_pos), transition_progress)

			# Progression status of child
			var is_unlocked = false
			var can_unlock = false
			if cm:
				is_unlocked = cm.unlocked_abilities.has(s_key)
				if not is_unlocked and cm.has_method("can_unlock_skill"):
					can_unlock = cm.can_unlock_skill(s_key).get("can_unlock", false)

			# Determine line color
			var glow_col = Color(0.25, 0.30, 0.40, 0.4 * transition_progress)
			var core_col = Color(0.35, 0.40, 0.52, 0.6 * transition_progress)
			var width = 1.8

			if is_unlocked:
				glow_col = Color(0.20, 0.65, 1.0, 0.40 * transition_progress)
				core_col = Color(0.40, 0.85, 1.0, 0.95 * transition_progress)
				width = 2.4
			elif can_unlock:
				glow_col = Color(0.92, 0.76, 0.30, 0.35 * transition_progress)
				core_col = Color(1.00, 0.88, 0.45, 0.90 * transition_progress)
				width = 2.2

			if prereqs.is_empty():
				# Draw from discipline anchor to root node
				_draw_antialiased_branch(anchor_pos, child_pos, core_col, glow_col, width)
			else:
				# Draw from each prerequisite parent to this child
				for p_key in prereqs:
					var p_target = skill_node_targets.get(p_key, anchor_pos)
					var p_pos = lerp(anchor_pos, p_target, transition_progress)
					_draw_antialiased_branch(p_pos, child_pos, core_col, glow_col, width)

func _draw_antialiased_branch(from: Vector2, to: Vector2, core_col: Color, glow_col: Color, width: float):
	# Soft outer glow
	lines_canvas.draw_line(from, to, glow_col, width + 2.5)
	# Crisp core line
	lines_canvas.draw_line(from, to, core_col, width)
	# Subtle end indicator dot
	lines_canvas.draw_circle(to, 2.5, core_col)

# ──────────────────────────────────────────────
#  INSPECTOR PANEL IMPLEMENTATION
# ──────────────────────────────────────────────
func _render_empty_inspector():
	if not inspector_vbox: return
	for c in inspector_vbox.get_children():
		c.queue_free()

	var lbl_title = Label.new()
	lbl_title.text = "Celestial Mandala"
	lbl_title.add_theme_font_size_override("font_size", 12)
	if cinzel_font:
		lbl_title.add_theme_font_override("font", cinzel_font)
	lbl_title.modulate = UITheme.GOLD_PRIMARY
	inspector_vbox.add_child(lbl_title)

	var lbl_desc = Label.new()
	lbl_desc.text = "Select any discipline icon to unfold its branching martial progression.\n\nInner Ring: Core Elements (Fire, Earth, Water, Air)\n\nOuter Ring: Combination Disciplines (Requires squad elemental affinities)\n\nCenter: Primordial Space & Time"
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 10)
	lbl_desc.modulate = UITheme.TEXT_SECONDARY
	inspector_vbox.add_child(lbl_desc)

func _inspect_locked_discipline(disc_key: String, reason: String):
	if not inspector_vbox: return
	for c in inspector_vbox.get_children():
		c.queue_free()

	var lbl_title = Label.new()
	lbl_title.text = "%s Discipline" % disc_key.capitalize()
	lbl_title.add_theme_font_size_override("font_size", 12)
	if cinzel_font:
		lbl_title.add_theme_font_override("font", cinzel_font)
	lbl_title.modulate = Color(0.9, 0.45, 0.45)
	inspector_vbox.add_child(lbl_title)

	var lbl_status = Label.new()
	lbl_status.text = "Status: Locked"
	lbl_status.add_theme_font_size_override("font_size", 10)
	lbl_status.modulate = Color(1.0, 0.5, 0.5)
	inspector_vbox.add_child(lbl_status)

	var div = HSeparator.new()
	div.modulate = UITheme.BORDER_SUBTLE
	inspector_vbox.add_child(div)

	var lbl_req = Label.new()
	lbl_req.text = "Access Requirement:\n%s" % reason
	lbl_req.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_req.add_theme_font_size_override("font_size", 10)
	lbl_req.modulate = UITheme.TEXT_SECONDARY
	inspector_vbox.add_child(lbl_req)

	var lbl_hint = Label.new()
	lbl_hint.text = "\nTo unlock combination disciplines, recruit teammates with the required base elements or unlock elemental affinities through tournament progression."
	lbl_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_hint.add_theme_font_size_override("font_size", 9)
	lbl_hint.modulate = UITheme.TEXT_MUTED
	inspector_vbox.add_child(lbl_hint)

func inspect_skill(skill_key: String):
	selected_skill_key = skill_key
	emit_signal("skill_selected", skill_key)

	# Update node widget visual borders
	for k in skill_node_widgets:
		var w = skill_node_widgets[k]
		if is_instance_valid(w):
			var cm = get_node_or_null("/root/CampaignManager")
			var is_unl = cm.unlocked_abilities.has(k) if cm else false
			var can_unl = cm.can_unlock_skill(k).get("can_unlock", false) if (cm and not is_unl) else false
			_style_skill_node_button(w, is_unl, can_unl, (k == selected_skill_key))

	if not inspector_vbox: return
	for c in inspector_vbox.get_children():
		c.queue_free()

	var edata = get_node_or_null("/root/ElementData")
	var cm = get_node_or_null("/root/CampaignManager")
	if not edata or not cm: return

	var s_node = edata.get_skill_node(skill_key)
	var ab_data = edata.ABILITIES.get(skill_key, {})
	var s_name = s_node.get("display_name", ab_data.get("name", skill_key.replace("_", " ")))
	var tier = s_node.get("tier", ab_data.get("tier", "basic"))
	var element = ab_data.get("element", s_node.get("discipline", "fire"))

	# Header: Name & Badges
	var lbl_name = Label.new()
	lbl_name.text = s_name
	lbl_name.add_theme_font_size_override("font_size", 13)
	if cinzel_font:
		lbl_name.add_theme_font_override("font", cinzel_font)
	lbl_name.modulate = UITheme.GOLD_PRIMARY
	inspector_vbox.add_child(lbl_name)

	var sub_lbl = Label.new()
	sub_lbl.text = "%s Discipline • %s Tier" % [element.capitalize(), tier.capitalize()]
	sub_lbl.add_theme_font_size_override("font_size", 9)
	sub_lbl.modulate = UITheme.TEXT_SECONDARY
	inspector_vbox.add_child(sub_lbl)

	var div = HSeparator.new()
	div.modulate = UITheme.BORDER_SUBTLE
	inspector_vbox.add_child(div)

	# Stats Summary Grid
	var grid = GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 4)
	inspector_vbox.add_child(grid)

	_add_stat_row(grid, "Damage/Effect:", "%d Dmg (%s)" % [ab_data.get("damage", 0), ab_data.get("effect", "Direct").capitalize()] if ab_data.get("damage", 0) > 0 else "Support/Tactical")
	_add_stat_row(grid, "MP Cost:", "%d MP" % ab_data.get("mp_cost", 10))
	_add_stat_row(grid, "Range:", "%d Tiles" % ab_data.get("range", 2))
	_add_stat_row(grid, "Accuracy:", "%d%%" % ab_data.get("accuracy", 90))

	# Description
	var lbl_desc = Label.new()
	lbl_desc.text = ab_data.get("desc", s_node.get("desc", "Martial elemental technique."))
	lbl_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl_desc.add_theme_font_size_override("font_size", 10)
	lbl_desc.modulate = UITheme.TEXT_SECONDARY
	inspector_vbox.add_child(lbl_desc)

	# Form Variations (3 Forms Progression)
	var forms = ab_data.get("forms", {})
	if not forms.is_empty():
		var is_skill_unlocked = cm.unlocked_abilities.has(skill_key) if cm else false
		var div2 = HSeparator.new()
		div2.modulate = UITheme.BORDER_SUBTLE
		inspector_vbox.add_child(div2)

		var f_title = Label.new()
		f_title.text = "Technique Form Variations (3 Forms):"
		f_title.add_theme_font_size_override("font_size", 10)
		f_title.modulate = Color(0.40, 0.85, 1.0)
		inspector_vbox.add_child(f_title)

		var unlocked_forms = cm.get_unlocked_forms_for_skill(skill_key) if cm else []
		var active_form = cm.skill_variations.get(skill_key, forms.keys()[0]) if cm else forms.keys()[0]
		var form_keys = forms.keys()

		for f_idx in range(form_keys.size()):
			var f_key = form_keys[f_idx]
			var f_info = forms[f_key]
			var is_form_unlocked = unlocked_forms.has(f_key)
			var is_active = (active_form == f_key or active_form == f_info.get("name", ""))

			var form_box = VBoxContainer.new()
			form_box.add_theme_constant_override("separation", 2)

			var header_hbox = HBoxContainer.new()
			var lbl_f_num = Label.new()
			lbl_f_num.text = "Form %d/3: %s" % [f_idx + 1, f_info.get("name", f_key.capitalize())]
			lbl_f_num.add_theme_font_size_override("font_size", 10)
			if is_active:
				lbl_f_num.modulate = UITheme.GOLD_PRIMARY
			elif is_form_unlocked:
				lbl_f_num.modulate = Color(0.9, 0.9, 0.95)
			else:
				lbl_f_num.modulate = UITheme.TEXT_MUTED
			header_hbox.add_child(lbl_f_num)

			var spacer = Control.new()
			spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			header_hbox.add_child(spacer)

			var status_tag = Label.new()
			if is_active:
				status_tag.text = "[ACTIVE]"
				status_tag.modulate = UITheme.GOLD_PRIMARY
			elif is_form_unlocked:
				status_tag.text = "[UNLOCKED]"
				status_tag.modulate = Color(0.40, 0.95, 0.65)
			else:
				status_tag.text = "[LOCKED]"
				status_tag.modulate = Color(0.75, 0.45, 0.50)
			status_tag.add_theme_font_size_override("font_size", 9)
			header_hbox.add_child(status_tag)
			form_box.add_child(header_hbox)

			# Stats & tactical description
			var f_shape = f_info.get("shape", "cardinal")
			var form_reach: int = AbilityGeometry.effective_reach(str(f_info.get("name", "")), int(f_info.get("range", 2)))
			var form_band: String = AbilityGeometry.preferred_band(str(f_info.get("name", "")), form_reach)
			var f_stats = "Rng: %d • Dmg: %.2fx • MP: %.2fx • Shape: %s" % [
				form_reach,
				f_info.get("dmg_mult", 1.0),
				f_info.get("mp_mult", 1.0),
				AbilityGeometry.shape_for(str(f_info.get("name", "")), f_shape).capitalize()
			]
			var form_effect: String = f_info.get("effect", ab_data.get("effect", ""))
			if float(ab_data.get("damage", 0)) * float(f_info.get("dmg_mult", 1.0)) > 0.0 and not form_effect in ["dodge_buff", "evasion", "defense_buff", "armor_buff", "guard", "heal", "cleanse", "anchor"]:
				f_stats += "\n%s +25%% at %s" % [form_band.capitalize(), AbilityGeometry.ideal_range_label(form_band, form_reach)]
			var lbl_f_stats = Label.new()
			lbl_f_stats.text = f_stats + "\n" + f_info.get("desc", "")
			lbl_f_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			lbl_f_stats.add_theme_font_size_override("font_size", 8)
			lbl_f_stats.modulate = UITheme.TEXT_MUTED if not is_form_unlocked else UITheme.TEXT_SECONDARY
			form_box.add_child(lbl_f_stats)

			# Action Button
			var f_action_btn = Button.new()
			f_action_btn.custom_minimum_size = Vector2(0, 24)
			f_action_btn.add_theme_font_size_override("font_size", 9)
			var cur_f = f_key
			if is_form_unlocked:
				if is_active:
					f_action_btn.text = "Selected Default Form"
					_style_nav_button(f_action_btn, Color(0.18, 0.22, 0.16, 0.95), UITheme.BORDER_GOLD, UITheme.GOLD_PRIMARY)
				else:
					f_action_btn.text = "Set as Default Form"
					_style_nav_button(f_action_btn, Color(0.08, 0.10, 0.15, 0.85), UITheme.BORDER_SUBTLE, UITheme.TEXT_SECONDARY)
					f_action_btn.pressed.connect(func():
						if cm:
							cm.skill_variations[skill_key] = cur_f
						inspect_skill(skill_key)
					)
			else:
				var can_unl = cm.can_unlock_skill_form(skill_key, cur_f) if cm else {"can_unlock": false}
				if can_unl.get("can_unlock", false):
					f_action_btn.text = "Unlock Form (-1 SP)"
					_style_nav_button(f_action_btn, Color(0.25, 0.20, 0.08, 0.95), UITheme.BORDER_GOLD, UITheme.GOLD_PRIMARY)
					f_action_btn.pressed.connect(func():
						if cm and cm.unlock_skill_form(skill_key, cur_f):
							_update_sp_badge()
							inspect_skill(skill_key)
							_update_positions_and_redraw()
					)
				elif not is_skill_unlocked:
					f_action_btn.text = "Locked (Unlock Skill First)"
					f_action_btn.disabled = true
					_style_nav_button(f_action_btn, Color(0.06, 0.07, 0.10, 0.7), UITheme.BORDER_SUBTLE, UITheme.TEXT_MUTED)
				else:
					f_action_btn.text = "Locked (Requires 1 SP)"
					f_action_btn.disabled = true
					_style_nav_button(f_action_btn, Color(0.06, 0.07, 0.10, 0.7), UITheme.BORDER_SUBTLE, UITheme.TEXT_MUTED)

			form_box.add_child(f_action_btn)
			inspector_vbox.add_child(form_box)

	# Progression Requirements Checklist
	var div3 = HSeparator.new()
	div3.modulate = UITheme.BORDER_SUBTLE
	inspector_vbox.add_child(div3)

	var req_title = Label.new()
	req_title.text = "Progression Requirements:"
	req_title.add_theme_font_size_override("font_size", 10)
	req_title.modulate = UITheme.GOLD_PRIMARY
	inspector_vbox.add_child(req_title)

	var check = cm.can_unlock_skill(skill_key)
	var is_unlocked = cm.unlocked_abilities.has(skill_key)

	var lvl_req = int(s_node.get("level_req", edata.get_skill_level_req(tier)))
	var sp_cost = int(s_node.get("sp_cost", edata.get_skill_sp_cost(tier)))
	var prereqs = s_node.get("prerequisites", [])

	# Level Check
	var lvl_pass = (cm.player_level >= lvl_req)
	_add_checklist_row(inspector_vbox, "Player Level", "Lv. %d Required (Current: Lv. %d)" % [lvl_req, cm.player_level], lvl_pass)

	# SP Check
	var sp_pass = (cm.unspent_skill_points >= sp_cost)
	_add_checklist_row(inspector_vbox, "Skill Points", "%d SP Required (Available: %d SP)" % [sp_cost, cm.unspent_skill_points], sp_pass)

	# Prerequisites Check
	if prereqs.is_empty():
		_add_checklist_row(inspector_vbox, "Prerequisites", "None (Starter Root)", true)
	else:
		for p in prereqs:
			var p_node = edata.get_skill_node(p)
			var p_name = p_node.get("display_name", p.replace("_", " "))
			var p_unl = cm.unlocked_abilities.has(p)
			_add_checklist_row(inspector_vbox, "Prerequisite", "%s (%s)" % [p_name, ("Unlocked" if p_unl else "Locked")], p_unl)

	# Action Button
	var div4 = HSeparator.new()
	div4.modulate = UITheme.BORDER_SUBTLE
	inspector_vbox.add_child(div4)

	var btn_action = Button.new()
	btn_action.custom_minimum_size = Vector2(0, 36)
	btn_action.add_theme_font_size_override("font_size", 10)
	if cinzel_font:
		btn_action.add_theme_font_override("font", cinzel_font)

	if is_unlocked:
		var is_equipped = cm.equipped_abilities.has(skill_key)
		btn_action.text = "Equipped in Combat Slot" if is_equipped else "Equip to Combat Slot"
		_style_nav_button(btn_action, Color(0.12, 0.16, 0.24, 0.95), UITheme.BORDER_GOLD, UITheme.GOLD_PRIMARY)
		btn_action.add_theme_color_override("font_color", UITheme.GOLD_PRIMARY)
		btn_action.modulate = Color(1.0, 1.0, 1.0, 1.0)
		btn_action.pressed.connect(func():
			if not is_equipped:
				if cm.equipped_abilities.size() >= 4:
					cm.equipped_abilities.pop_back()
				cm.equipped_abilities.append(skill_key)
			inspect_skill(skill_key)
		)
	elif check.get("can_unlock", false):
		btn_action.text = "Unlock Technique (-%d SP)" % sp_cost
		var sb_gold = StyleBoxFlat.new()
		sb_gold.bg_color = UITheme.GOLD_PRIMARY
		sb_gold.border_color = Color(1.0, 0.92, 0.6, 1.0)
		sb_gold.border_width_left = 1
		sb_gold.border_width_top = 1
		sb_gold.border_width_right = 1
		sb_gold.border_width_bottom = 1
		sb_gold.set_corner_radius_all(4)
		btn_action.add_theme_stylebox_override("normal", sb_gold)
		btn_action.add_theme_stylebox_override("hover", sb_gold)
		btn_action.add_theme_stylebox_override("pressed", sb_gold)
		btn_action.add_theme_color_override("font_color", Color(0.12, 0.09, 0.02, 1.0))
		btn_action.add_theme_color_override("font_hover_color", Color(0.05, 0.04, 0.01, 1.0))
		btn_action.add_theme_color_override("font_pressed_color", Color(0.0, 0.0, 0.0, 1.0))
		btn_action.modulate = Color(1.0, 1.0, 1.0, 1.0)
		btn_action.pressed.connect(func():
			if cm.unlock_skill_node(skill_key):
				emit_signal("skill_unlocked", skill_key)
				_update_sp_badge()
				inspect_skill(skill_key)
				_update_positions_and_redraw()
		)
	else:
		btn_action.text = "Locked (%s)" % check.get("reason", "Requirements not met")
		btn_action.disabled = true
		var sb_dis = StyleBoxFlat.new()
		sb_dis.bg_color = Color(0.08, 0.10, 0.14, 0.85)
		sb_dis.border_color = Color(0.25, 0.28, 0.35, 0.6)
		sb_dis.border_width_left = 1
		sb_dis.border_width_top = 1
		sb_dis.border_width_right = 1
		sb_dis.border_width_bottom = 1
		sb_dis.set_corner_radius_all(4)
		btn_action.add_theme_stylebox_override("disabled", sb_dis)
		btn_action.add_theme_color_override("font_disabled_color", Color(0.65, 0.70, 0.80, 0.8))
		btn_action.modulate = Color(1.0, 1.0, 1.0, 1.0)

	inspector_vbox.add_child(btn_action)

func _add_stat_row(grid: GridContainer, label_text: String, val_text: String):
	var l = Label.new()
	l.text = label_text
	l.add_theme_font_size_override("font_size", 9)
	l.modulate = UITheme.TEXT_MUTED
	grid.add_child(l)

	var v = Label.new()
	v.text = val_text
	v.add_theme_font_size_override("font_size", 9)
	v.modulate = UITheme.TEXT_PRIMARY
	grid.add_child(v)

func _add_checklist_row(vb: VBoxContainer, tag: String, detail: String, is_met: bool):
	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 6)

	var icon_lbl = Label.new()
	icon_lbl.text = "[OK]" if is_met else "[--]"
	icon_lbl.add_theme_font_size_override("font_size", 9)
	icon_lbl.modulate = Color(0.4, 0.85, 0.5) if is_met else Color(0.9, 0.4, 0.4)
	hb.add_child(icon_lbl)

	var text_lbl = Label.new()
	text_lbl.text = "%s: %s" % [tag, detail]
	text_lbl.add_theme_font_size_override("font_size", 9)
	text_lbl.modulate = UITheme.TEXT_PRIMARY if is_met else UITheme.TEXT_MUTED
	hb.add_child(text_lbl)

	vb.add_child(hb)

func _update_sp_badge():
	var cm = get_node_or_null("/root/CampaignManager")
	if sp_badge and cm:
		sp_badge.text = "Available: %d SP" % cm.unspent_skill_points

# ──────────────────────────────────────────────
#  INPUT HANDLING: PAN & ZOOM
# ──────────────────────────────────────────────
func _gui_input(event: InputEvent):
	if event is InputEventMouseButton:
		var mb = event as InputEventMouseButton
		# Mouse Wheel Zoom
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			_adjust_zoom(0.08, mb.position)
			accept_event()
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			_adjust_zoom(-0.08, mb.position)
			accept_event()
		# Drag Pan (Middle Click or Left Click on background)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE or mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				is_panning = true
				pan_start_mouse = mb.position
				pan_start_offset = pan_offset
			else:
				is_panning = false

	elif event is InputEventMouseMotion and is_panning:
		var mm = event as InputEventMouseMotion
		pan_offset = pan_start_offset + (mm.position - pan_start_mouse)
		_update_viewport_transform()

func _adjust_zoom(delta: float, pivot: Vector2):
	var old_zoom = zoom_level
	zoom_level = clampf(zoom_level + delta, MIN_ZOOM, MAX_ZOOM)
	if is_equal_approx(old_zoom, zoom_level):
		return

	var avail_w = maxf(size.x - 350.0, 100.0)
	var center = Vector2(avail_w * 0.5, size.y * 0.5) + pan_offset
	var diff = pivot - center
	pan_offset -= diff * (zoom_level / old_zoom - 1.0)

	if zoom_lbl:
		zoom_lbl.text = "%d%%" % int(round(zoom_level * 100))

	_update_viewport_transform()

func reset_view():
	pan_offset = Vector2.ZERO
	zoom_level = 0.85
	if zoom_lbl:
		zoom_lbl.text = "85%"
	_update_viewport_transform()

func fit_tree():
	_update_positions_and_redraw()
	# Measure the current cards in world coordinates, reserving the fixed toolbar
	# and inspector. A fixed zoom value cannot fit both tall and wide trees.
	var bounds = Rect2()
	var has_bounds = false
	var seen = {}
	var widgets = skill_node_widgets.values() if focused_discipline != "" else discipline_buttons.values()
	if focused_discipline != "":
		var root_key = "space_time" if focused_discipline in ["space", "time", "space_time"] else focused_discipline
		if discipline_buttons.has(root_key):
			widgets.append(discipline_buttons[root_key])
	for widget in widgets:
		if not is_instance_valid(widget) or seen.has(widget):
			continue
		seen[widget] = true
		var rect = Rect2(widget.position, widget.size)
		bounds = bounds.merge(rect) if has_bounds else rect
		has_bounds = true
	if not has_bounds or bounds.size.x <= 0 or bounds.size.y <= 0:
		return
	var available = Rect2(16, 54, maxf(size.x - 350, 100), maxf(size.y - 70, 100))
	zoom_level = clampf(minf(available.size.x / bounds.size.x, available.size.y / bounds.size.y), MIN_ZOOM, MAX_ZOOM)
	var default_center = Vector2(maxf(size.x - 350, 100) * 0.5, size.y * 0.5)
	pan_offset = available.get_center() - bounds.get_center() * zoom_level - default_center
	if zoom_lbl:
		zoom_lbl.text = "%d%%" % int(round(zoom_level * 100))
	_update_viewport_transform()
