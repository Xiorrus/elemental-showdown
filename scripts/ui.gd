extends CanvasLayer

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — TACTICAL METAPHOR / PERSONA HUD
#  High-contrast obsidian canvas | Gold & Ruby tactical corner brackets
#  Cinzel-Bold typography | Sleek filigree progress bars | Floating feedback
#  PAUSE MODAL with Squad Roster & Opponent Scouting Codex
#  POST-MATCH MODAL with full Game Loop (Restart, Hub, Main Menu)
# ──────────────────────────────────────────────

# ══════════════════════════════════════════════
#  CUSTOM CONTROLS
# ══════════════════════════════════════════════

# ── 1. Tactical Progress Bar with Sliding Diamond Cursor ──
class OrnateBar extends Control:
	var value: float = 100.0:
		set(v):
			value = v
			queue_redraw()
	var max_value: float = 100.0:
		set(v):
			max_value = max(1.0, v)
			queue_redraw()
	var bar_type: String = "hp": # "hp" (ruby), "mp" (sapphire), "xp" (gold)
		set(v):
			bar_type = v
			queue_redraw()
	var text: String = "":
		set(v):
			text = v
			queue_redraw()
	var icon_tex: Texture2D = null:
		set(v):
			icon_tex = v
			queue_redraw()
	var _custom_font: Font = null
	var _tween: Tween = null
	var label_prefix: String = ""
	var show_cursor: bool = false:
		set(v):
			show_cursor = v
			queue_redraw()

	func _draw():
		var w = size.x
		var h = size.y
		var font = _custom_font if _custom_font else ThemeDB.fallback_font
		var font_sz = 10

		# 1. Ambient drop shadow
		draw_rect(Rect2(0, 1.5, w, h), Color(0.02, 0.03, 0.05, 0.85), true)

		# 2. Dark obsidian frame
		draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.07, 0.11, 0.98), true)

		# 3. Inner track
		var inset_x = 3.0
		var track_rect = Rect2(inset_x, 2, w - inset_x * 2, h - 4)
		draw_rect(track_rect, Color(0.03, 0.04, 0.07, 1.0), true)
		draw_rect(track_rect, Color(0.18, 0.22, 0.32, 0.5), false, 1.0)

		# 4. Colored fill with radiant metallic gradient
		var ratio = clamp(value / max_value, 0.0, 1.0)
		var fill_w = track_rect.size.x * ratio
		if fill_w > 0:
			var fill_rect = Rect2(track_rect.position, Vector2(fill_w, track_rect.size.y))
			var col_base: Color
			var col_top: Color
			var col_gleam: Color

			if bar_type == "hp":
				col_base  = Color(0.68, 0.12, 0.18, 1.0)
				col_top   = Color(0.88, 0.20, 0.28, 1.0)
				col_gleam = Color(1.0, 0.65, 0.72, 0.85)
			elif bar_type == "mp":
				col_base  = Color(0.10, 0.30, 0.75, 1.0)
				col_top   = Color(0.18, 0.52, 0.92, 1.0)
				col_gleam = Color(0.65, 0.85, 1.0, 0.85)
			elif bar_type == "sta":
				col_base  = Color(0.12, 0.58, 0.30, 1.0)
				col_top   = Color(0.20, 0.82, 0.45, 1.0)
				col_gleam = Color(0.70, 0.98, 0.80, 0.85)
			else: # xp = gold
				col_base  = Color(0.72, 0.52, 0.08, 1.0)
				col_top   = Color(0.95, 0.80, 0.20, 1.0)
				col_gleam = Color(1.0, 0.92, 0.65, 0.85)

			var half_h = fill_rect.size.y * 0.5
			draw_rect(Rect2(fill_rect.position, Vector2(fill_w, half_h)), col_top, true)
			draw_rect(Rect2(fill_rect.position.x, fill_rect.position.y + half_h, fill_w, half_h), col_base, true)
			draw_line(fill_rect.position + Vector2(0, 1), fill_rect.position + Vector2(fill_w, 1), col_gleam, 1.0)

		# 5. Clean metallic border
		var border_col = Color(0.85, 0.70, 0.25, 0.8) if bar_type == "xp" else Color(0.22, 0.30, 0.44, 0.75)
		draw_rect(Rect2(0, 0, w, h), border_col, false, 1.0)

		# 6. Icon (left side)
		var icon_w = 0.0
		if icon_tex:
			var icon_sz = Vector2(h - 2, h - 2)
			var icon_pos = Vector2(inset_x + 2, 1)
			draw_texture_rect(icon_tex, Rect2(icon_pos, icon_sz), false)
			icon_w = icon_sz.x + 4

		# 7. Centered value text with crisp drop shadow
		if font and text != "":
			var text_area_x = inset_x + icon_w
			var text_area_w = w - text_area_x - inset_x
			var ts = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz)
			var tx = text_area_x + (text_area_w - ts.x) * 0.5
			var ty = (h + ts.y * 0.65) * 0.5
			draw_string(font, Vector2(tx, ty) + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, Color(0, 0, 0, 0.95))
			draw_string(font, Vector2(tx, ty), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_sz, Color(0.98, 0.99, 1.0, 1.0))

	func _draw_diamond(pos: Vector2, r: float, color: Color):
		var pts = PackedVector2Array([
			pos + Vector2(0, -r),
			pos + Vector2(r, 0),
			pos + Vector2(0, r),
			pos + Vector2(-r, 0)
		])
		draw_colored_polygon(pts, color)

	func tween_to(target_value: float, duration: float = 0.35):
		if _tween and _tween.is_valid():
			_tween.kill()
		_tween = create_tween()
		_tween.tween_property(self, "value", target_value, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		if label_prefix != "":
			var start_val = value
			_tween.parallel().tween_method(func(v: float):
				text = "%s: %d / %d" % [label_prefix, int(round(v)), int(round(max_value))]
			, start_val, target_value, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)


# ── 2. Tactical Panel with Sleek Borders ──
class OrnatePanel extends Control:
	var border_color: Color = Color(0.20, 0.26, 0.38, 0.6):
		set(v):
			border_color = v
			queue_redraw()
	var bracket_color: Color = Color(0.92, 0.68, 0.22, 1.0):
		set(v):
			bracket_color = v
			queue_redraw()
	var bg_color: Color = Color(0.05, 0.07, 0.11, 0.95):
		set(v):
			bg_color = v
			queue_redraw()
	var is_highlighted: bool = false:
		set(v):
			is_highlighted = v
			queue_redraw()
	var show_corner_spikes: bool = false:
		set(v):
			show_corner_spikes = v
			queue_redraw()
	var draw_brackets: bool = false:
		set(v):
			draw_brackets = v
			queue_redraw()
	var top_center_diamond: bool = false:
		set(v):
			top_center_diamond = v
			queue_redraw()
	var bracket_length: float = 0.0:
		set(v):
			bracket_length = v
			queue_redraw()
	var bracket_thickness: float = 1.0:
		set(v):
			bracket_thickness = v
			queue_redraw()

	func _draw():
		var w = size.x
		var h = size.y
		if w <= 4 or h <= 4:
			return

		var active_border_col = Color(1.0, 0.85, 0.30, 0.85) if is_highlighted else border_color

		# 1. Subtle amber glow if highlighted
		if is_highlighted:
			draw_rect(Rect2(-2, -2, w + 4, h + 4), Color(1.0, 0.85, 0.25, 0.16), true)

		# 2. Dark obsidian canvas fill
		draw_rect(Rect2(0, 0, w, h), bg_color, true)

		# 3. Subtle 1px box border
		draw_rect(Rect2(0, 0, w, h), active_border_col, false, 1.0)

		# 4. Optional Corner Brackets
		if draw_brackets and bracket_length > 0.0:
			var bl = bracket_length if not is_highlighted else bracket_length + 2.0
			var bt = bracket_thickness if not is_highlighted else bracket_thickness + 0.8
			var active_bracket_col = Color(1.0, 0.88, 0.32, 1.0) if is_highlighted else bracket_color

			# Top-Left
			draw_line(Vector2(0, bl), Vector2(0, 0), active_bracket_col, bt)
			draw_line(Vector2(0, 0), Vector2(bl, 0), active_bracket_col, bt)
			# Top-Right
			draw_line(Vector2(w - bl, 0), Vector2(w, 0), active_bracket_col, bt)
			draw_line(Vector2(w, 0), Vector2(w, bl), active_bracket_col, bt)
			# Bottom-Left
			draw_line(Vector2(0, h - bl), Vector2(0, h), active_bracket_col, bt)
			draw_line(Vector2(0, h), Vector2(bl, h), active_bracket_col, bt)
			# Bottom-Right
			draw_line(Vector2(w - bl, h), Vector2(w, h), active_bracket_col, bt)
			draw_line(Vector2(w, h), Vector2(w, h - bl), active_bracket_col, bt)

		# 5. Top & Bottom Center Diamond Pips (if enabled)
		if top_center_diamond:
			var mid_x = w * 0.5
			_draw_diamond(Vector2(mid_x, 0), 3.0, active_border_col)

	func _draw_diamond(pos: Vector2, r: float, color: Color):
		var pts = PackedVector2Array([
			pos + Vector2(0, -r),
			pos + Vector2(r, 0),
			pos + Vector2(0, r),
			pos + Vector2(-r, 0)
		])
		draw_colored_polygon(pts, color)


# ── 3. Ornate Ribbon Turn Indicator ──
class OrnateRibbon extends Control:
	var is_player_turn: bool = true:
		set(v):
			is_player_turn = v
			queue_redraw()
	var text: String = "":
		set(v):
			text = v
			queue_redraw()
	var icon_hourglass: Texture2D = null
	var _custom_font: Font = null

	func _draw():
		var w = size.x
		var h = size.y
		var font = _custom_font if _custom_font else ThemeDB.fallback_font

		# Drop shadow
		draw_rect(Rect2(0, 2, w, h), Color(0.02, 0.03, 0.05, 0.85), true)

		# Dark obsidian body
		draw_rect(Rect2(0, 0, w, h), Color(0.06, 0.08, 0.12, 0.96), true)

		# Border
		var trim_col = Color(0.35, 0.92, 0.55, 1.0) if is_player_turn else Color(0.95, 0.30, 0.38, 1.0)
		var border_col = Color(0.25, 0.32, 0.45, 0.75)
		draw_rect(Rect2(0, 0, w, h), border_col, false, 1.0)
		draw_line(Vector2(2, h - 2), Vector2(w - 2, h - 2), trim_col, 2.0)

		if icon_hourglass:
			var isz = Vector2(h - 8, h - 8)
			draw_texture_rect(icon_hourglass, Rect2(Vector2(10, 4), isz), false)

		if font and text != "":
			var ts = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11)
			var tp = Vector2((w - ts.x) * 0.5, (h + ts.y * 0.6) * 0.5)
			draw_string(font, tp + Vector2(1, 1), text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, Color(0, 0, 0, 0.95))
			draw_string(font, tp, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 11, trim_col)

	func _draw_diamond(pos: Vector2, r: float, color: Color):
		draw_colored_polygon(PackedVector2Array([
			pos + Vector2(0, -r), pos + Vector2(r, 0),
			pos + Vector2(0, r),  pos + Vector2(-r, 0)
		]), color)


# ── 4. Floating Damage Popup ──
class DamagePopup extends Label:
	var _font: Font = null

	func setup(txt: String, color: Color, pos: Vector2, _arg4 = null, _arg5 = null, font_size: int = 18):
		var screen_pos = pos
		var font_sz = font_size
		if _arg4 is Viewport:
			screen_pos = _arg4.get_canvas_transform() * (pos - Vector2(0, 52))
		elif typeof(_arg4) == TYPE_INT or typeof(_arg4) == TYPE_FLOAT:
			font_sz = int(_arg4)

		text = txt
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		z_index = 50
		horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vertical_alignment = VERTICAL_ALIGNMENT_CENTER

		add_theme_color_override("font_color", color)
		add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		add_theme_constant_override("shadow_offset_x", 1)
		add_theme_constant_override("shadow_offset_y", 1)
		add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08, 0.95))
		add_theme_constant_override("outline_size", 2)
		if _font:
			add_theme_font_override("font", _font)
		add_theme_font_size_override("font_size", font_sz)

		size = Vector2(160, 32)
		pivot_offset = size * 0.5
		position = screen_pos - pivot_offset

		for child in get_children():
			if child is Control:
				child.mouse_filter = Control.MOUSE_FILTER_IGNORE

		_animate()

	func _animate():
		scale = Vector2(1.25, 1.25)
		var tw = create_tween()
		tw.tween_property(self, "scale", Vector2(1.0, 1.0), 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "position:y", position.y - 40.0, 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(self, "modulate:a", 0.0, 0.5).set_delay(0.3)
		tw.chain().tween_callback(queue_free)


# ══════════════════════════════════════════════
#  STATE & REFERENCES
# ══════════════════════════════════════════════

const ELEMENT_UI_COLORS = {
	"fire":  Color(1.0, 0.55, 0.25),
	"water": Color(0.35, 0.78, 1.0),
	"earth": Color(0.90, 0.72, 0.28),
	"air":   Color(0.78, 0.94, 1.0),
	"zero":  Color(0.85, 0.35, 0.95)
}

var player_hp_bar:  OrnateBar
var player_mp_bar:  OrnateBar
var player_sta_bar: OrnateBar
var player_xp_bar:  OrnateBar
var btn_sub:        Button = null
var btn_pause:      Button = null
var squad_bar:      HBoxContainer = null
var squad_buttons:  Array = []
var player_name:    Label
var player_icon:    TextureRect
var level_label:    Label
var moves_label:    Label
var xp_label:       Label

var enemy_hp_bar:   OrnateBar
var enemy_mp_bar:   OrnateBar
var enemy_sta_bar:  OrnateBar
var enemy_name:     Label
var enemy_icon:     TextureRect

var player_panel:         OrnatePanel
var enemy_panel:          OrnatePanel
var turn_indicator_panel: OrnateRibbon
var action_log_panel:     OrnatePanel
var action_log:           RichTextLabel
var ability_panels:       Array = []
var ability_slots:        Array = []

var skill_offer_panel: OrnatePanel
var offer_buttons:     Array = []

# Pause Screen
var pause_modal_root: Control = null
var pause_panel: OrnatePanel = null
var is_game_paused: bool = false
var pause_tab_idx: int = 0
var pause_roster_box: Control = null
var pause_codex_box: Control = null
var btn_tab_roster: Button = null
var btn_tab_codex: Button = null

# Post-Match Modal
var result_modal_root: Control = null
var result_panel: OrnatePanel = null
var result_label: Label = null
var result_match_lbl: Label = null
var result_stats_lbl: Label = null
var result_energy_lbl: Label = null

# Sub Selection Modal (R2)
var sub_modal_root:     Control = null
var sub_modal_backdrop: ColorRect = null
var sub_panel:          OrnatePanel = null
var sub_entries_vbox:   VBoxContainer = null

var _log_lines:        Array = []
var _skill_offer_keys: Array = []
var _element_db               = null
var _player_ref               = null
var _cinzel_font:      Font   = null

# Hit-Stop & Screen Shake (Polish & Game Feel)
var _shake_intensity: float = 0.0
var _shake_timer: float = 0.0
var _shake_duration: float = 0.0
var _target_shake_node: Node2D = null
var _orig_shake_node_pos: Vector2 = Vector2.ZERO
var _is_hit_stopping: bool = false

const MAX_LOG_LINES = 7
const PAD     = 10
const PANEL_W = 270
const BAR_H   = 18
const AB_W    = 180
const AB_H    = 54

var SW: float = 1152.0
var SH: float = 648.0


# ══════════════════════════════════════════════
#  LIFECYCLE
# ══════════════════════════════════════════════

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS

	_element_db = get_node_or_null("/root/ElementData")

	if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		_cinzel_font = load("res://assets/fonts/Cinzel-Bold.ttf")
		print("[UI] Cinzel-Bold font loaded.")

	var vr = get_viewport().get_visible_rect()
	SW = vr.size.x
	SH = vr.size.y

	_build_player_panel()
	_build_enemy_panel()
	_build_turn_indicator()
	_build_squad_bar()
	_build_action_log()
	_build_ability_bar()
	_build_skill_offer_panel()
	_build_pause_modal()
	_build_result_panel()
	_build_sub_modal()

	log_action("[color=#d4a017]Match commenced.[/color] Select movement tile or right-click to act.")

	get_viewport().size_changed.connect(_reflow_ui)

func _process(delta: float):
	if _shake_timer > 0.0:
		_shake_timer -= delta
		if _target_shake_node == null or not is_instance_valid(_target_shake_node):
			var cam = get_viewport().get_camera_2d() if get_viewport() else null
			if cam:
				_target_shake_node = cam
				_orig_shake_node_pos = cam.offset
			elif get_parent() is Node2D:
				_target_shake_node = get_parent() as Node2D
				_orig_shake_node_pos = _target_shake_node.position

		if _target_shake_node and is_instance_valid(_target_shake_node):
			var factor = clampf(_shake_timer / max(_shake_duration, 0.001), 0.0, 1.0)
			var current_amt = _shake_intensity * factor
			var rand_vec = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * (randf() * current_amt)
			if _target_shake_node is Camera2D:
				(_target_shake_node as Camera2D).offset = _orig_shake_node_pos + rand_vec
			else:
				_target_shake_node.position = _orig_shake_node_pos + rand_vec

			if _shake_timer <= 0.0:
				if _target_shake_node is Camera2D:
					(_target_shake_node as Camera2D).offset = _orig_shake_node_pos
				else:
					_target_shake_node.position = _orig_shake_node_pos
				_shake_intensity = 0.0

func trigger_screen_shake(intensity: float = 5.0, duration: float = 0.20):
	if DisplayServer.get_name() == "headless":
		return
	_shake_intensity = max(_shake_intensity, intensity)
	_shake_duration = max(_shake_duration, duration)
	_shake_timer = _shake_duration

func trigger_hit_stop(duration_ms: float = 30.0):
	if DisplayServer.get_name() == "headless":
		return
	if _is_hit_stopping:
		return
	_is_hit_stopping = true
	var orig_scale = Engine.time_scale
	Engine.time_scale = 0.04
	await get_tree().create_timer(duration_ms / 1000.0, true, false, true).timeout
	Engine.time_scale = orig_scale
	_is_hit_stopping = false

func _unhandled_input(event: InputEvent):
	if event is InputEventKey and event.is_pressed() and not event.is_echo():
		if event.keycode == KEY_ESCAPE:
			if sub_modal_root and sub_modal_root.visible:
				_close_sub_modal()
				get_viewport().set_input_as_handled()
				return
			if result_modal_root and result_modal_root.visible:
				return
			_toggle_pause()

func _reflow_ui(custom_size: Vector2 = Vector2.ZERO):
	if custom_size != Vector2.ZERO:
		SW = custom_size.x; SH = custom_size.y
	else:
		var vr = get_viewport().get_visible_rect()
		SW = vr.size.x; SH = vr.size.y

	if player_panel:
		player_panel.position = Vector2(PAD, PAD)
	if enemy_panel:
		enemy_panel.position = Vector2(SW - PANEL_W - PAD, PAD)
	if turn_indicator_panel:
		turn_indicator_panel.position = Vector2((SW - turn_indicator_panel.size.x) / 2.0, PAD)
	if btn_pause:
		if btn_sub and btn_sub.visible:
			btn_sub.position = Vector2(SW / 2.0 - 105, PAD + 36)
			btn_pause.position = Vector2(SW / 2.0 + 5, PAD + 36)
		else:
			btn_pause.position = Vector2((SW - btn_pause.size.x) / 2.0, PAD + 36)
	if squad_bar:
		squad_bar.position = Vector2((SW - squad_bar.size.x) / 2.0, PAD + 68)

	var bar_y = SH - AB_H - PAD
	var total = (AB_W + 8) * 5 - 8
	var start = (SW - total) / 2.0
	for i in range(ability_panels.size()):
		ability_panels[i].position = Vector2(start + i * (AB_W + 8), bar_y)

	if action_log_panel:
		action_log_panel.position = Vector2(PAD, SH - action_log_panel.size.y - AB_H - PAD * 2)
	if skill_offer_panel:
		skill_offer_panel.position = Vector2((SW - skill_offer_panel.size.x) / 2.0, (SH - skill_offer_panel.size.y) / 2.0)
	if pause_panel:
		pause_panel.position = Vector2((SW - pause_panel.size.x) / 2.0, (SH - pause_panel.size.y) / 2.0)
	if result_panel:
		result_panel.position = Vector2((SW - result_panel.size.x) / 2.0, (SH - result_panel.size.y) / 2.0)
	if sub_panel:
		sub_panel.position = Vector2((SW - sub_panel.size.x) / 2.0, (SH - sub_panel.size.y) / 2.0)


# ══════════════════════════════════════════════
#  TACTICAL STYLING HELPERS
# ══════════════════════════════════════════════

func _make_cinzel_label(text: String, parent: Control, pos: Vector2, sz: Vector2, font_sz: int = 12, _bold: bool = false) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = sz
	if _cinzel_font:
		lbl.add_theme_font_override("font", _cinzel_font)
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(lbl)
	return lbl

func _label(text: String, parent: Control, pos: Vector2, sz: Vector2, font_sz: int = 11, _bold: bool = false) -> Label:
	var lbl = Label.new()
	lbl.text = text
	lbl.position = pos
	lbl.size = sz
	lbl.add_theme_font_size_override("font_size", font_sz)
	lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("shadow_offset_x", 1)
	lbl.add_theme_constant_override("shadow_offset_y", 1)
	parent.add_child(lbl)
	return lbl

func _style_tactical_button(btn: Button, bg_col: Color, border_col: Color, text_col: Color, font_sz: int = 11, glow: bool = false):
	var sb_normal = StyleBoxFlat.new()
	sb_normal.bg_color = bg_col
	sb_normal.border_color = border_col
	sb_normal.border_width_left = 1
	sb_normal.border_width_top = 1
	sb_normal.border_width_right = 1
	sb_normal.border_width_bottom = 1
	sb_normal.set_corner_radius_all(3)
	if glow:
		sb_normal.shadow_color = Color(border_col.r, border_col.g, border_col.b, 0.45)
		sb_normal.shadow_size = 6

	var sb_hover = sb_normal.duplicate()
	sb_hover.border_color = Color(1.0, 0.88, 0.35, 1.0)
	sb_hover.bg_color = bg_col.lightened(0.12)
	sb_hover.shadow_color = Color(1.0, 0.85, 0.25, 0.6)
	sb_hover.shadow_size = 8

	var sb_pressed = sb_normal.duplicate()
	sb_pressed.bg_color = bg_col.darkened(0.1)

	btn.add_theme_stylebox_override("normal", sb_normal)
	btn.add_theme_stylebox_override("hover", sb_hover)
	btn.add_theme_stylebox_override("pressed", sb_pressed)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.95, 0.7))
	btn.add_theme_font_size_override("font_size", font_sz)


# ══════════════════════════════════════════════
#  PANEL BUILDERS
# ══════════════════════════════════════════════

func _build_player_panel():
	player_panel = OrnatePanel.new()
	player_panel.size = Vector2(PANEL_W, 160)
	player_panel.position = Vector2(PAD, PAD)
	player_panel.bracket_color = Color(0.95, 0.72, 0.22, 1.0) # Gold tactical bracket
	add_child(player_panel)

	player_icon = TextureRect.new()
	player_icon.position = Vector2(10, 10)
	player_icon.size = Vector2(28, 28)
	player_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	player_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/icon_fire.png"):
		player_icon.texture = load("res://assets/icon_fire.png")
	player_panel.add_child(player_icon)

	player_name = _label("Player", player_panel, Vector2(44, 8), Vector2(150, 20), 13, true)
	player_name.modulate = ELEMENT_UI_COLORS["fire"]

	level_label = _label("Lv. 1", player_panel, Vector2(PANEL_W - 68, 8), Vector2(58, 20), 11, true)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	level_label.modulate = Color(1.0, 0.85, 0.2)

	player_hp_bar = OrnateBar.new()
	player_hp_bar.position = Vector2(10, 36)
	player_hp_bar.size = Vector2(PANEL_W - 20, BAR_H)
	player_hp_bar.bar_type = "hp"
	player_hp_bar.label_prefix = "HP"
	player_hp_bar.text = "HP: 100 / 100"
	if ResourceLoader.exists("res://assets/icon_hp.png"):
		player_hp_bar.icon_tex = load("res://assets/icon_hp.png")
	player_panel.add_child(player_hp_bar)

	player_mp_bar = OrnateBar.new()
	player_mp_bar.position = Vector2(10, 58)
	player_mp_bar.size = Vector2(PANEL_W - 20, BAR_H)
	player_mp_bar.bar_type = "mp"
	player_mp_bar.label_prefix = "MP"
	player_mp_bar.text = "MP: 100 / 100"
	if ResourceLoader.exists("res://assets/icon_mp.png"):
		player_mp_bar.icon_tex = load("res://assets/icon_mp.png")
	player_panel.add_child(player_mp_bar)

	player_sta_bar = OrnateBar.new()
	player_sta_bar.position = Vector2(10, 80)
	player_sta_bar.size = Vector2(PANEL_W - 20, BAR_H)
	player_sta_bar.bar_type = "sta"
	player_sta_bar.label_prefix = "STA"
	player_sta_bar.text = "STA: 100 / 100"
	player_panel.add_child(player_sta_bar)

	player_xp_bar = OrnateBar.new()
	player_xp_bar.position = Vector2(10, 102)
	player_xp_bar.size = Vector2(PANEL_W - 20, BAR_H - 2)
	player_xp_bar.bar_type = "xp"
	player_xp_bar.label_prefix = "XP"
	player_xp_bar.text = "XP: 0 / 100"
	player_panel.add_child(player_xp_bar)

	moves_label = _label("Moves: 3", player_panel, Vector2(12, 128), Vector2(110, 20), 10)
	moves_label.modulate = Color(0.7, 0.9, 1.0)

	xp_label = _label("Phoenix Strikers", player_panel, Vector2(130, 128), Vector2(128, 20), 10)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	xp_label.modulate = Color(0.9, 0.85, 0.4)

func _build_enemy_panel():
	enemy_panel = OrnatePanel.new()
	enemy_panel.size = Vector2(PANEL_W, 118)
	enemy_panel.position = Vector2(SW - PANEL_W - PAD, PAD)
	enemy_panel.bracket_color = Color(0.92, 0.22, 0.38, 1.0) # Ruby tactical bracket
	add_child(enemy_panel)

	enemy_icon = TextureRect.new()
	enemy_icon.position = Vector2(10, 10)
	enemy_icon.size = Vector2(28, 28)
	enemy_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	enemy_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists("res://assets/icon_water.png"):
		enemy_icon.texture = load("res://assets/icon_water.png")
	enemy_panel.add_child(enemy_icon)

	enemy_name = _label("Enemy", enemy_panel, Vector2(44, 8), Vector2(216, 20), 13, true)
	enemy_name.modulate = ELEMENT_UI_COLORS["water"]

	enemy_hp_bar = OrnateBar.new()
	enemy_hp_bar.position = Vector2(10, 36)
	enemy_hp_bar.size = Vector2(PANEL_W - 20, BAR_H)
	enemy_hp_bar.bar_type = "hp"
	enemy_hp_bar.label_prefix = "HP"
	enemy_hp_bar.text = "HP: 100 / 100"
	if ResourceLoader.exists("res://assets/icon_hp.png"):
		enemy_hp_bar.icon_tex = load("res://assets/icon_hp.png")
	enemy_panel.add_child(enemy_hp_bar)

	enemy_mp_bar = OrnateBar.new()
	enemy_mp_bar.position = Vector2(10, 58)
	enemy_mp_bar.size = Vector2(PANEL_W - 20, BAR_H)
	enemy_mp_bar.bar_type = "mp"
	enemy_mp_bar.label_prefix = "MP"
	enemy_mp_bar.text = "MP: 100 / 100"
	if ResourceLoader.exists("res://assets/icon_mp.png"):
		enemy_mp_bar.icon_tex = load("res://assets/icon_mp.png")
	enemy_panel.add_child(enemy_mp_bar)

	enemy_sta_bar = OrnateBar.new()
	enemy_sta_bar.position = Vector2(10, 80)
	enemy_sta_bar.size = Vector2(PANEL_W - 20, BAR_H)
	enemy_sta_bar.bar_type = "sta"
	enemy_sta_bar.label_prefix = "STA"
	enemy_sta_bar.text = "STA: 100 / 100"
	enemy_panel.add_child(enemy_sta_bar)

func _build_turn_indicator():
	var rib_w = 500.0
	var rib_h = 32.0
	turn_indicator_panel = OrnateRibbon.new()
	turn_indicator_panel.size = Vector2(rib_w, rib_h)
	turn_indicator_panel.position = Vector2(326, PAD)
	turn_indicator_panel.text = "Move Phase: Select blue tile  |  Right-Click: Attack Phase"
	if ResourceLoader.exists("res://assets/icon_hourglass.png"):
		turn_indicator_panel.icon_hourglass = load("res://assets/icon_hourglass.png")
	add_child(turn_indicator_panel)

	# Direct Tactical Sub Button (Centered beneath turn ribbon)
	btn_sub = Button.new()
	btn_sub.text = "Sub (1)"
	btn_sub.size = Vector2(100, 26)
	btn_sub.position = Vector2(470, PAD + 36)
	_style_tactical_button(btn_sub, Color(0.08, 0.12, 0.18, 0.95), Color(0.35, 0.65, 0.95, 0.75), Color(0.75, 0.90, 1.0), 10)
	if _cinzel_font:
		btn_sub.add_theme_font_override("font", _cinzel_font)
	btn_sub.pressed.connect(_on_hud_sub_pressed)
	add_child(btn_sub)

	# Direct Pause Button for Mouse Interaction
	btn_pause = Button.new()
	btn_pause.text = "Pause"
	btn_pause.size = Vector2(100, 26)
	btn_pause.position = Vector2(580, PAD + 36)
	_style_tactical_button(btn_pause, Color(0.08, 0.10, 0.16, 0.95), Color(0.85, 0.65, 0.22, 0.75), Color(0.95, 0.85, 0.35), 10)
	if _cinzel_font:
		btn_pause.add_theme_font_override("font", _cinzel_font)
	btn_pause.pressed.connect(_toggle_pause)
	add_child(btn_pause)

func _build_squad_bar():
	squad_bar = HBoxContainer.new()
	squad_bar.name = "SquadBar"
	squad_bar.position = Vector2(250, 70)
	squad_bar.size = Vector2(652, 28)
	squad_bar.add_theme_constant_override("separation", 6)
	squad_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(squad_bar)

func update_squad_bar():
	if not squad_bar: return
	for c in squad_bar.get_children():
		squad_bar.remove_child(c)
		c.queue_free()
	squad_buttons.clear()

	var bm = get_node_or_null("../BattleManager")
	if not bm: return

	var players = []
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(p):
				players.append(p)
	if players.is_empty() and _player_ref:
		players.append(_player_ref)

	if players.size() <= 1 and bm.match_format == "1v1":
		squad_bar.visible = false
		return
	squad_bar.visible = true

	for i in range(players.size()):
		var p = players[i]
		var btn = Button.new()
		var p_name = p.name
		var is_ko = ("hp" in p and p.hp <= 0)
		var is_active = (bm.active_player_unit == p)
		var has_acted = p.get("has_acted") if "has_acted" in p else false

		var badge = "[READY]"
		var txt_color = Color(0.9, 0.95, 1.0)
		var bg_col = Color(0.08, 0.12, 0.18, 0.92)
		var border_col = Color(0.3, 0.5, 0.8, 0.7)

		if is_ko:
			badge = "[DOWN]"
			txt_color = Color(1.0, 0.4, 0.4)
			border_col = Color(0.8, 0.2, 0.2, 0.7)
			btn.disabled = true
		elif is_active:
			badge = "[ACTIVE]"
			txt_color = Color(1.2, 1.1, 0.5)
			border_col = Color(1.0, 0.85, 0.2, 1.0)
			bg_col = Color(0.15, 0.20, 0.30, 0.95)
		elif has_acted:
			badge = "[DONE]"
			txt_color = Color(0.6, 0.65, 0.7)
			border_col = Color(0.25, 0.3, 0.4, 0.6)

		var cur_hp = p.hp if "hp" in p else 100
		var elem_str = p.element.capitalize() if "element" in p else "Fire"
		btn.text = "%d: %s (%s) %d HP %s" % [i + 1, p_name, elem_str, cur_hp, badge]
		btn.add_theme_font_size_override("font_size", 9)
		_style_tactical_button(btn, bg_col, border_col, txt_color, 9)

		var unit_ref = p
		btn.pressed.connect(func():
			if bm and not is_ko:
				bm.select_active_player_unit(unit_ref)
		)
		squad_bar.add_child(btn)
		squad_buttons.append(btn)

	if players.size() > 1 and bm.current_state != bm.State.ENEMY_TURN and bm.current_state != bm.State.BATTLE_OVER:
		var end_btn = Button.new()
		end_btn.text = "End Squad Turn"
		end_btn.add_theme_font_size_override("font_size", 9)
		_style_tactical_button(end_btn, Color(0.20, 0.08, 0.08, 0.92), Color(0.9, 0.4, 0.2, 0.8), Color(1.0, 0.8, 0.6), 9)
		end_btn.pressed.connect(func():
			if bm and bm.current_state != bm.State.ENEMY_TURN and bm.current_state != bm.State.BATTLE_OVER:
				bm.end_squad_turn()
		)
		squad_bar.add_child(end_btn)

func _build_action_log():
	var log_w = 340.0
	var log_h = 130.0
	action_log_panel = OrnatePanel.new()
	action_log_panel.size = Vector2(log_w, log_h)
	action_log_panel.position = Vector2(PAD, SH - log_h - AB_H - PAD * 2)
	action_log_panel.bg_color = Color(0.04, 0.06, 0.10, 0.85)
	action_log_panel.border_color = Color(0.20, 0.28, 0.42, 0.65)
	action_log_panel.bracket_color = Color(0.35, 0.65, 0.95, 0.85) # Sapphire tactical bracket
	add_child(action_log_panel)

	var log_title = _label("Combat Chronicle", action_log_panel, Vector2(10, 6), Vector2(log_w - 60, 16), 10, true)
	log_title.modulate = Color(0.75, 0.85, 1.0)

	var btn_toggle = Button.new()
	btn_toggle.text = "-"
	btn_toggle.position = Vector2(log_w - 30, 4)
	btn_toggle.size = Vector2(22, 18)
	btn_toggle.flat = true
	btn_toggle.focus_mode = Control.FOCUS_NONE
	btn_toggle.add_theme_font_size_override("font_size", 9)
	btn_toggle.add_theme_color_override("font_color", Color(0.65, 0.75, 0.90))
	action_log_panel.add_child(btn_toggle)

	action_log = RichTextLabel.new()
	action_log.position = Vector2(8, 24)
	action_log.size = Vector2(log_w - 16, log_h - 30)
	action_log.scroll_following = true
	action_log.bbcode_enabled = true
	action_log.add_theme_font_size_override("normal_font_size", 10)
	action_log.add_theme_color_override("default_color", Color(0.85, 0.88, 0.95))
	action_log_panel.add_child(action_log)

	var is_collapsed = false
	btn_toggle.pressed.connect(func():
		is_collapsed = !is_collapsed
		if is_collapsed:
			btn_toggle.text = "+"
			action_log.visible = false
			action_log_panel.size = Vector2(log_w, 26)
			action_log_panel.position = Vector2(PAD, SH - 26 - AB_H - PAD * 2)
		else:
			btn_toggle.text = "-"
			action_log.visible = true
			action_log_panel.size = Vector2(log_w, log_h)
			action_log_panel.position = Vector2(PAD, SH - log_h - AB_H - PAD * 2)
	)

func _build_ability_bar():
	var bar_y = SH - AB_H - PAD
	var total = (AB_W + 8) * 5 - 8
	var start = (SW - total) / 2.0

	var key_labels = ["1", "2", "3", "4", "A"]
	for i in range(5):
		var p = OrnatePanel.new()
		p.size = Vector2(AB_W, AB_H)
		p.position = Vector2(start + i * (AB_W + 8), bar_y)
		p.bracket_color = Color(0.20, 0.26, 0.38, 0.5) # Dimmed slate default
		p.bracket_length = 10.0
		p.top_center_diamond = false
		add_child(p)
		ability_panels.append(p)

		var badge = _label("[%s]" % key_labels[i], p, Vector2(6, 3), Vector2(24, 16), 9, true)
		badge.modulate = Color(0.45, 0.50, 0.60)

		var n_lbl = _label("---", p, Vector2(30, 3), Vector2(AB_W - 36, 16), 10, true)
		n_lbl.modulate = Color(0.35, 0.40, 0.50)

		var c_lbl = _label("MP: --", p, Vector2(26, 20), Vector2(65, 14), 9)
		c_lbl.modulate = Color(0.25, 0.30, 0.40)

		var r_lbl = _label("Rng: --", p, Vector2(96, 20), Vector2(65, 14), 9)
		r_lbl.modulate = Color(0.25, 0.30, 0.40)

		var f_lbl = _label("", p, Vector2(6, 36), Vector2(118, 14), 8)
		f_lbl.modulate = Color(1.0, 0.82, 0.35)

		var cycle_btn: Button = null
		if i < 4:
			cycle_btn = Button.new()
			cycle_btn.text = "⟳ Form"
			cycle_btn.size = Vector2(48, 18)
			cycle_btn.position = Vector2(126, 31)
			cycle_btn.add_theme_font_size_override("font_size", 8)
			cycle_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			cycle_btn.visible = false
			var btn_s_idx = i
			cycle_btn.pressed.connect(func():
				if _player_ref and _player_ref.has_method("cycle_skill_form"):
					_player_ref.cycle_skill_form(btn_s_idx)
			)

		ability_slots.append({
			"panel": p,
			"name":  n_lbl,
			"cost":  c_lbl,
			"range": r_lbl,
			"form":  f_lbl,
			"cycle_btn": cycle_btn,
			"badge": badge
		})

		var slot_btn = Button.new()
		slot_btn.flat = true
		slot_btn.size = Vector2(AB_W, AB_H)
		slot_btn.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var s_idx = i
		slot_btn.pressed.connect(func():
			if s_idx < 4:
				if _player_ref and _player_ref.has_method("select_ability"):
					_player_ref.select_ability(s_idx)
			elif s_idx == 4:
				if _player_ref and _player_ref.has_method("use_artifact"):
					_player_ref.use_artifact()
		)
		slot_btn.gui_input.connect(func(ev):
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
				if s_idx < 4 and _player_ref and _player_ref.has_method("cycle_skill_form"):
					_player_ref.cycle_skill_form(s_idx)
		)
		p.add_child(slot_btn)
		if cycle_btn:
			p.add_child(cycle_btn)

func _build_skill_offer_panel():
	var panel_w = 520.0
	var panel_h = 240.0
	skill_offer_panel = OrnatePanel.new()
	skill_offer_panel.size = Vector2(panel_w, panel_h)
	skill_offer_panel.position = Vector2(316, (SH - panel_h) / 2.0)
	skill_offer_panel.bracket_color = Color(0.95, 0.72, 0.22, 1.0) # Gold brackets
	skill_offer_panel.visible = false
	add_child(skill_offer_panel)

	var title = _label("Choose a New Tactical Ability", skill_offer_panel, Vector2(20, 12), Vector2(panel_w - 40, 24), 13, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.85, 0.3)

	for i in range(3):
		var btn = Button.new()
		btn.position = Vector2(20, 42 + i * 62)
		btn.size = Vector2(panel_w - 40, 54)
		btn.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_style_tactical_button(btn, Color(0.08, 0.10, 0.16, 0.95), Color(0.85, 0.65, 0.22, 0.6), Color(0.95, 0.98, 1.0), 10)
		btn.connect("pressed", _on_skill_offer_chosen.bind(i))
		skill_offer_panel.add_child(btn)
		offer_buttons.append(btn)


# ══════════════════════════════════════════════
#  PAUSE MODAL (Roster & Scouting Codex)
# ══════════════════════════════════════════════

func _build_pause_modal():
	pause_modal_root = Control.new()
	pause_modal_root.name = "PauseModalRoot"
	pause_modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_modal_root.process_mode = Node.PROCESS_MODE_ALWAYS
	pause_modal_root.visible = false
	add_child(pause_modal_root)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.05, 0.90)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	pause_modal_root.add_child(bg)

	var pw = 880.0
	var ph = 530.0
	pause_panel = OrnatePanel.new()
	pause_panel.size = Vector2(pw, ph)
	pause_panel.position = Vector2((SW - pw) / 2.0, (SH - ph) / 2.0)
	pause_panel.bracket_color = Color(0.95, 0.72, 0.22, 1.0) # Gold brackets
	pause_modal_root.add_child(pause_panel)

	var title = _label("Tactical Pause & Intel", pause_panel, Vector2(20, 14), Vector2(pw - 40, 26), 18, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.85, 0.3)
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)

	var subtitle = _label("Combatant Conditions  •  Squad Roster  •  Opponent Scouting Codex", pause_panel, Vector2(20, 40), Vector2(pw - 40, 18), 10)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.70, 0.78, 0.90)

	var tab_bar = HBoxContainer.new()
	tab_bar.position = Vector2(24, 66)
	tab_bar.size = Vector2(pw - 48, 36)
	tab_bar.add_theme_constant_override("separation", 16)
	pause_panel.add_child(tab_bar)

	btn_tab_roster = Button.new()
	btn_tab_roster.text = "Squad & Fighter Condition"
	btn_tab_roster.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_tab_roster, Color(0.09, 0.12, 0.18, 0.95), Color(0.95, 0.72, 0.22, 0.9), Color(1.0, 0.88, 0.35), 11, true)
	if _cinzel_font:
		btn_tab_roster.add_theme_font_override("font", _cinzel_font)
	btn_tab_roster.pressed.connect(func(): _switch_pause_tab(0))
	tab_bar.add_child(btn_tab_roster)

	btn_tab_codex = Button.new()
	btn_tab_codex.text = "Opponent Scouting Codex"
	btn_tab_codex.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_tab_codex, Color(0.06, 0.08, 0.12, 0.85), Color(0.25, 0.32, 0.45, 0.6), Color(0.70, 0.78, 0.90), 11)
	if _cinzel_font:
		btn_tab_codex.add_theme_font_override("font", _cinzel_font)
	btn_tab_codex.pressed.connect(func(): _switch_pause_tab(1))
	tab_bar.add_child(btn_tab_codex)

	pause_roster_box = HBoxContainer.new()
	pause_roster_box.position = Vector2(24, 112)
	pause_roster_box.size = Vector2(pw - 48, 348)
	pause_roster_box.add_theme_constant_override("separation", 18)
	pause_panel.add_child(pause_roster_box)

	pause_codex_box = VBoxContainer.new()
	pause_codex_box.position = Vector2(24, 112)
	pause_codex_box.size = Vector2(pw - 48, 348)
	pause_codex_box.visible = false
	pause_panel.add_child(pause_codex_box)

	var bottom_bar = HBoxContainer.new()
	bottom_bar.position = Vector2(24, ph - 54)
	bottom_bar.size = Vector2(pw - 48, 40)
	bottom_bar.add_theme_constant_override("separation", 14)
	pause_panel.add_child(bottom_bar)

	var btn_resume = Button.new()
	btn_resume.text = "Resume (Esc)"
	btn_resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_resume, Color(0.88, 0.65, 0.15, 1.0), Color(1.0, 0.88, 0.35, 1.0), Color(0.05, 0.07, 0.11, 1.0), 11, true)
	if _cinzel_font:
		btn_resume.add_theme_font_override("font", _cinzel_font)
	btn_resume.pressed.connect(_toggle_pause)
	bottom_bar.add_child(btn_resume)

	var btn_restart = Button.new()
	btn_restart.text = "Restart Match"
	btn_restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_restart, Color(0.08, 0.11, 0.17, 0.95), Color(0.35, 0.45, 0.62, 0.75), Color(0.90, 0.95, 1.0), 11)
	if _cinzel_font:
		btn_restart.add_theme_font_override("font", _cinzel_font)
	btn_restart.pressed.connect(_on_pause_restart)
	bottom_bar.add_child(btn_restart)

	var btn_concede = Button.new()
	btn_concede.text = "Surrender"
	btn_concede.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_concede, Color(0.42, 0.10, 0.15, 0.95), Color(0.85, 0.25, 0.35, 0.8), Color(1.0, 0.82, 0.85), 11)
	if _cinzel_font:
		btn_concede.add_theme_font_override("font", _cinzel_font)
	btn_concede.pressed.connect(_on_pause_concede)
	bottom_bar.add_child(btn_concede)

	var btn_menu = Button.new()
	btn_menu.text = "Main Menu"
	btn_menu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_style_tactical_button(btn_menu, Color(0.08, 0.11, 0.17, 0.95), Color(0.35, 0.45, 0.62, 0.75), Color(0.90, 0.95, 1.0), 11)
	if _cinzel_font:
		btn_menu.add_theme_font_override("font", _cinzel_font)
	btn_menu.pressed.connect(_on_pause_main_menu)
	bottom_bar.add_child(btn_menu)

func _switch_pause_tab(tab_idx: int):
	pause_tab_idx = tab_idx
	if pause_roster_box: pause_roster_box.visible = (tab_idx == 0)
	if pause_codex_box: pause_codex_box.visible = (tab_idx == 1)

	if btn_tab_roster:
		if tab_idx == 0:
			_style_tactical_button(btn_tab_roster, Color(0.09, 0.12, 0.18, 0.95), Color(0.95, 0.72, 0.22, 0.9), Color(1.0, 0.88, 0.35), 11, true)
		else:
			_style_tactical_button(btn_tab_roster, Color(0.06, 0.08, 0.12, 0.85), Color(0.25, 0.32, 0.45, 0.6), Color(0.70, 0.78, 0.90), 11)

	if btn_tab_codex:
		if tab_idx == 1:
			_style_tactical_button(btn_tab_codex, Color(0.09, 0.12, 0.18, 0.95), Color(0.95, 0.72, 0.22, 0.9), Color(1.0, 0.88, 0.35), 11, true)
		else:
			_style_tactical_button(btn_tab_codex, Color(0.06, 0.08, 0.12, 0.85), Color(0.25, 0.32, 0.45, 0.6), Color(0.70, 0.78, 0.90), 11)

func _toggle_pause():
	if sub_modal_root and sub_modal_root.visible:
		_close_sub_modal()
	is_game_paused = !is_game_paused
	get_tree().paused = is_game_paused
	if pause_modal_root:
		pause_modal_root.visible = is_game_paused
		if is_game_paused:
			_switch_pause_tab(pause_tab_idx)
			_refresh_pause_modal()

func _refresh_pause_modal():
	if not pause_roster_box or not pause_codex_box: return

	for c in pause_roster_box.get_children(): c.queue_free()
	for c in pause_codex_box.get_children(): c.queue_free()

	var cm = get_node_or_null("/root/CampaignManager")
	var edata = get_node_or_null("/root/ElementData")

	var card_sb = StyleBoxFlat.new()
	card_sb.bg_color = Color(0.06, 0.08, 0.12, 0.96)
	card_sb.border_color = Color(0.22, 0.28, 0.40, 0.65)
	card_sb.border_width_left = 1
	card_sb.border_width_top = 1
	card_sb.border_width_right = 1
	card_sb.border_width_bottom = 1
	card_sb.set_corner_radius_all(4)
	card_sb.content_margin_left = 14
	card_sb.content_margin_top = 12
	card_sb.content_margin_right = 14
	card_sb.content_margin_bottom = 12

	# LEFT COL: Player Status
	var p_col = PanelContainer.new()
	p_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p_col.add_theme_stylebox_override("panel", card_sb)
	var p_vb = VBoxContainer.new()
	p_vb.add_theme_constant_override("separation", 6)
	p_col.add_child(p_vb)
	pause_roster_box.add_child(p_col)

	var p_name_str = "Ignis (Fire Master)"
	var p_lvl = 1
	var p_energy = 100
	var is_fat = false
	var bench_risk = false
	var eq_skills = ["Combustion"]

	if cm and cm.has_active_campaign:
		p_name_str = "%s (%s Master)" % [cm.player_name, cm.player_element.capitalize()]
		p_lvl = cm.player_level
		p_energy = cm.energy
		is_fat = cm.is_fatigued
		bench_risk = cm.bench_risk
		eq_skills = cm.equipped_abilities

	var p_title = Label.new()
	p_title.text = "Active Combatant: %s" % p_name_str
	p_title.add_theme_font_size_override("font_size", 13)
	p_title.modulate = Color(1.0, 0.85, 0.3)
	p_vb.add_child(p_title)

	var p_stats = Label.new()
	p_stats.text = "Rank: Level %d  |  Team: %s" % [p_lvl, cm.team_name if cm else "Phoenix Strikers"]
	p_stats.add_theme_font_size_override("font_size", 11)
	p_stats.modulate = Color(0.85, 0.90, 1.0)
	p_vb.add_child(p_stats)

	var p_energy_lbl = Label.new()
	p_energy_lbl.add_theme_font_size_override("font_size", 11)
	if is_fat:
		p_energy_lbl.text = "Energy: %d/100  [Fatigued: -20%% HP/MP, -1 Speed!]" % p_energy
		p_energy_lbl.modulate = Color(1.0, 0.4, 0.4)
	else:
		p_energy_lbl.text = "Energy: %d/100  [Rested: Full Effectiveness]" % p_energy
		p_energy_lbl.modulate = Color(0.4, 1.0, 0.5)
	p_vb.add_child(p_energy_lbl)

	if bench_risk:
		var bench_lbl = Label.new()
		bench_lbl.add_theme_font_size_override("font_size", 11)
		bench_lbl.text = "[Warning] Coach Bench: Severe exhaustion. Rest required!"
		bench_lbl.modulate = Color(1.0, 0.25, 0.25)
		p_vb.add_child(bench_lbl)

	var div = HSeparator.new()
	div.add_theme_constant_override("separation", 8)
	p_vb.add_child(div)

	var sk_hdr = Label.new()
	sk_hdr.text = "Equipped Tactical Abilities (Slots 1-4):"
	sk_hdr.add_theme_font_size_override("font_size", 11)
	sk_hdr.modulate = Color(0.8, 0.9, 1.0)
	p_vb.add_child(sk_hdr)

	for i in range(eq_skills.size()):
		var sk = eq_skills[i]
		var sk_lbl = Label.new()
		sk_lbl.add_theme_font_size_override("font_size", 10)
		var desc = ""
		if edata and edata.ABILITIES.has(sk):
			var info = edata.ABILITIES[sk]
			desc = " [MP:%d  Rng:%d  Tier:%s]" % [info["mp_cost"], info["range"], info["tier"].capitalize()]
		sk_lbl.text = "• Slot %d: %s%s" % [i + 1, sk.replace("_", " "), desc]
		sk_lbl.modulate = Color(0.92, 0.95, 1.0)
		p_vb.add_child(sk_lbl)

	# RIGHT COL: Squad & Teammates
	var t_col = PanelContainer.new()
	t_col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	t_col.add_theme_stylebox_override("panel", card_sb)
	var t_vb = VBoxContainer.new()
	t_vb.add_theme_constant_override("separation", 8)
	t_col.add_child(t_vb)
	pause_roster_box.add_child(t_col)

	var t_title = Label.new()
	t_title.text = "Squad Roster & Bench Reserves"
	t_title.add_theme_font_size_override("font_size", 13)
	t_title.modulate = Color(0.4, 0.85, 1.0)
	t_vb.add_child(t_title)

	var allies = cm.allies if (cm and cm.has_active_campaign) else [
		{"name": "Ignis", "element": "fire", "role": "Team Captain (Player)", "level": 1, "status": "Active"},
		{"name": "Kora", "element": "air", "role": "Scout / Tactician", "level": 1, "status": "Reserve"},
		{"name": "Gaius", "element": "earth", "role": "Defender / Anchor", "level": 1, "status": "Reserve"}
	]

	for a in allies:
		var ally_panel = PanelContainer.new()
		var ally_sb = StyleBoxFlat.new()
		ally_sb.bg_color = Color(0.08, 0.11, 0.16, 0.92)
		ally_sb.border_color = Color(0.30, 0.38, 0.52, 0.5)
		ally_sb.border_width_left = 3
		ally_sb.border_width_top = 1
		ally_sb.border_width_right = 1
		ally_sb.border_width_bottom = 1
		ally_sb.set_corner_radius_all(4)
		ally_sb.content_margin_left = 12
		ally_sb.content_margin_top = 8
		ally_sb.content_margin_right = 12
		ally_sb.content_margin_bottom = 8
		ally_panel.add_theme_stylebox_override("panel", ally_sb)

		var avb = VBoxContainer.new()
		avb.add_theme_constant_override("separation", 3)
		ally_panel.add_child(avb)

		var aname = Label.new()
		var role_str = a.get("role", a.get("archetype", "Fighter"))
		aname.text = "%s — %s (%s)" % [a.get("name", "Ally"), role_str, a.get("element", "fire").capitalize()]
		aname.add_theme_font_size_override("font_size", 11)
		aname.modulate = Color(1.0, 0.95, 0.7) if a.get("status", "Active") == "Active" else Color(0.85, 0.88, 0.95)
		avb.add_child(aname)

		var cur_hp = a.get("hp", 100)
		var cur_mp = a.get("mp", 100)
		if is_inside_tree():
			for p_node in get_tree().get_nodes_in_group("players"):
				if is_instance_valid(p_node):
					var is_match = (p_node.name == a.get("name", ""))
					if not is_match and cm and a.get("name", "") == cm.player_name and p_node.name == "Player":
						is_match = true
					if is_match:
						cur_hp = p_node.hp if "hp" in p_node else cur_hp
						cur_mp = p_node.mp if "mp" in p_node else cur_mp
						break

		var ainfo = Label.new()
		ainfo.text = "Status: %s  •  Level %d  •  HP %d / MP %d" % [
			a.get("status", "Active"), a.get("level", 1), cur_hp, cur_mp
		]
		ainfo.add_theme_font_size_override("font_size", 10)
		ainfo.modulate = Color(0.45, 0.98, 0.60) if a.get("status", "Active") == "Active" else Color(0.65, 0.75, 0.85)
		avb.add_child(ainfo)

		t_vb.add_child(ally_panel)

	# ── Refresh Codex Tab ──
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	pause_codex_box.add_child(scroll)

	var cvb = VBoxContainer.new()
	cvb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cvb.add_theme_constant_override("separation", 10)
	scroll.add_child(cvb)

	var cur_enemy_elem = cm.active_enemy_element if cm else "water"
	var cur_enemy_name = cm.active_enemy_name if cm else "Nami"
	var cur_enemy_team = cm.active_enemy_team if cm else "Hydro Vipers"

	var spot_panel = PanelContainer.new()
	var spot_sb = StyleBoxFlat.new()
	spot_sb.bg_color = Color(0.12, 0.06, 0.09, 0.95)
	spot_sb.border_color = Color(0.88, 0.25, 0.38, 0.8)
	spot_sb.border_width_left = 3
	spot_sb.border_width_top = 1
	spot_sb.border_width_right = 1
	spot_sb.border_width_bottom = 1
	spot_sb.set_corner_radius_all(4)
	spot_sb.content_margin_left = 14
	spot_sb.content_margin_top = 10
	spot_sb.content_margin_right = 14
	spot_sb.content_margin_bottom = 10
	spot_panel.add_theme_stylebox_override("panel", spot_sb)

	var svb = VBoxContainer.new()
	svb.add_theme_constant_override("separation", 4)
	spot_panel.add_child(svb)

	var s_title = Label.new()
	s_title.text = "Current Arena Opponent: %s (%s) — %s" % [cur_enemy_name, cur_enemy_elem.capitalize(), cur_enemy_team]
	s_title.add_theme_font_size_override("font_size", 12)
	s_title.modulate = Color(1.0, 0.4, 0.4)
	svb.add_child(s_title)
	cvb.add_child(spot_panel)

	if cm and cm.scouting_intel:
		for elem_key in cm.scouting_intel.keys():
			var inf = cm.scouting_intel[elem_key]
			var f_panel = PanelContainer.new()
			var f_sb = StyleBoxFlat.new()
			f_sb.bg_color = Color(0.07, 0.09, 0.14, 0.94)
			f_sb.border_color = Color(0.24, 0.30, 0.44, 0.6)
			f_sb.border_width_left = 2
			f_sb.border_width_top = 1
			f_sb.border_width_right = 1
			f_sb.border_width_bottom = 1
			f_sb.set_corner_radius_all(4)
			f_sb.content_margin_left = 12
			f_sb.content_margin_top = 8
			f_sb.content_margin_right = 12
			f_sb.content_margin_bottom = 8
			f_panel.add_theme_stylebox_override("panel", f_sb)

			var f_vb = VBoxContainer.new()
			f_vb.add_theme_constant_override("separation", 4)
			f_panel.add_child(f_vb)

			var fname = Label.new()
			fname.text = "%s  •  Captain: %s (%s)" % [inf["team_name"], inf["captain"], inf["element"].capitalize()]
			fname.add_theme_font_size_override("font_size", 11)
			fname.modulate = Color(1.0, 0.85, 0.3)
			f_vb.add_child(fname)

			var frecord = Label.new()
			frecord.text = "Head-to-Head Record: %d Fought  |  %d Wins - %d Losses" % [
				inf["matches_fought"], inf["wins_against"], inf["losses_against"]
			]
			frecord.add_theme_font_size_override("font_size", 10)
			frecord.modulate = Color(0.85, 0.90, 1.0)
			f_vb.add_child(frecord)

			var fvuln = Label.new()
			fvuln.text = "Vulnerabilities: %s" % ", ".join(inf["weaknesses"])
			fvuln.add_theme_font_size_override("font_size", 10)
			fvuln.modulate = Color(1.0, 0.45, 0.45)
			f_vb.add_child(fvuln)

			var fskills = Label.new()
			fskills.text = "Known Abilities: %s" % ", ".join(inf["known_skills"])
			fskills.add_theme_font_size_override("font_size", 10)
			fskills.modulate = Color(0.45, 0.85, 1.0)
			f_vb.add_child(fskills)

			cvb.add_child(f_panel)

func _on_pause_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()

func _on_pause_concede():
	var cm = get_node_or_null("/root/CampaignManager")
	if cm and cm.has_active_campaign:
		cm.record_match_result(false, 15)
		cm.save_campaign()
	get_tree().paused = false
	if cm and cm.has_active_campaign:
		get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_pause_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# ══════════════════════════════════════════════
#  POST-MATCH MODAL (Game Loop)
# ══════════════════════════════════════════════

func _build_result_panel():
	result_modal_root = Control.new()
	result_modal_root.name = "ResultModalRoot"
	result_modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	result_modal_root.process_mode = Node.PROCESS_MODE_ALWAYS
	result_modal_root.visible = false
	add_child(result_modal_root)

	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.02, 0.03, 0.05, 0.88)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	result_modal_root.add_child(bg)

	var rw = 620.0
	var rh = 420.0
	result_panel = OrnatePanel.new()
	result_panel.size = Vector2(rw, rh)
	result_panel.position = Vector2((SW - rw) / 2.0, (SH - rh) / 2.0)
	result_panel.border_color = Color(0.85, 0.70, 0.22, 0.85)
	result_panel.bg_color = Color(0.06, 0.08, 0.13, 0.97)
	result_modal_root.add_child(result_panel)

	result_label = _label("Victory Achieved", result_panel, Vector2(20, 24), Vector2(rw - 40, 36), 22, true)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_label.modulate = UITheme.GOLD_PRIMARY
	if _cinzel_font:
		result_label.add_theme_font_override("font", _cinzel_font)

	result_match_lbl = _label("Match Concluded", result_panel, Vector2(30, 66), Vector2(rw - 60, 22), 11)
	result_match_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_match_lbl.modulate = Color(0.75, 0.82, 0.95)

	# Stats breakdown card
	var stats_card = PanelContainer.new()
	stats_card.position = Vector2(40, 98)
	stats_card.size = Vector2(rw - 80, 110)
	var sc_sb = StyleBoxFlat.new()
	sc_sb.bg_color = Color(0.04, 0.05, 0.08, 0.90)
	sc_sb.border_width_left = 1
	sc_sb.border_width_top = 1
	sc_sb.border_width_right = 1
	sc_sb.border_width_bottom = 1
	sc_sb.border_color = Color(0.20, 0.26, 0.38, 0.6)
	sc_sb.set_corner_radius_all(4)
	sc_sb.content_margin_left = 16
	sc_sb.content_margin_right = 16
	sc_sb.content_margin_top = 12
	sc_sb.content_margin_bottom = 12
	stats_card.add_theme_stylebox_override("panel", sc_sb)
	result_panel.add_child(stats_card)

	var sc_vb = VBoxContainer.new()
	sc_vb.add_theme_constant_override("separation", 8)
	stats_card.add_child(sc_vb)

	result_stats_lbl = Label.new()
	result_stats_lbl.text = "Turns: 6  •  XP: +60 XP"
	result_stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_stats_lbl.add_theme_font_size_override("font_size", 13)
	result_stats_lbl.modulate = Color(1.0, 0.88, 0.35)
	sc_vb.add_child(result_stats_lbl)

	result_energy_lbl = Label.new()
	result_energy_lbl.text = "Energy Consumed: -20"
	result_energy_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_energy_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_energy_lbl.add_theme_font_size_override("font_size", 10)
	result_energy_lbl.modulate = Color(0.65, 0.85, 1.0)
	sc_vb.add_child(result_energy_lbl)

	var btn_vbox = VBoxContainer.new()
	btn_vbox.position = Vector2(60, 226)
	btn_vbox.size = Vector2(rw - 120, 160)
	btn_vbox.add_theme_constant_override("separation", 10)
	result_panel.add_child(btn_vbox)

	var btn_hub = Button.new()
	btn_hub.text = "Continue to Campaign Hub"
	btn_hub.custom_minimum_size = Vector2(0, 42)
	_style_tactical_button(btn_hub, Color(0.18, 0.14, 0.08, 1.0), UITheme.GOLD_PRIMARY, Color(1.0, 0.92, 0.55), 12, true)
	if _cinzel_font:
		btn_hub.add_theme_font_override("font", _cinzel_font)
	btn_hub.pressed.connect(func():
		get_tree().paused = false
		var cm = get_node_or_null("/root/CampaignManager")
		if cm and cm.has_active_campaign:
			get_tree().change_scene_to_file("res://scenes/CampaignHub.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_vbox.add_child(btn_hub)

	var btn_restart = Button.new()
	btn_restart.text = "Restart Match"
	btn_restart.custom_minimum_size = Vector2(0, 34)
	_style_tactical_button(btn_restart, Color(0.08, 0.11, 0.17, 0.95), Color(0.25, 0.35, 0.50, 0.75), Color(0.85, 0.92, 1.0), 10)
	if _cinzel_font:
		btn_restart.add_theme_font_override("font", _cinzel_font)
	btn_restart.pressed.connect(func():
		get_tree().paused = false
		get_tree().reload_current_scene()
	)
	btn_vbox.add_child(btn_restart)

	var btn_main_menu = Button.new()
	btn_main_menu.text = "Main Menu"
	btn_main_menu.custom_minimum_size = Vector2(0, 34)
	_style_tactical_button(btn_main_menu, Color(0.08, 0.11, 0.17, 0.95), Color(0.25, 0.35, 0.50, 0.75), Color(0.85, 0.92, 1.0), 10)
	if _cinzel_font:
		btn_main_menu.add_theme_font_override("font", _cinzel_font)
	btn_main_menu.pressed.connect(func():
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	)
	btn_vbox.add_child(btn_main_menu)

func show_battle_result(victory: bool, xp_gained: int = 60, turns: int = 0):
	if result_modal_root == null or result_panel == null:
		return

	var cm = get_node_or_null("/root/CampaignManager")
	result_modal_root.visible = true

	if victory:
		result_panel.bracket_color = Color(0.95, 0.72, 0.22, 1.0) # Gold
	else:
		result_panel.bracket_color = Color(0.92, 0.22, 0.38, 1.0) # Ruby

	if result_label:
		result_label.text = "Victory Achieved" if victory else "Defeat"
		result_label.modulate = Color(1.0, 0.88, 0.2) if victory else Color(1.0, 0.35, 0.35)
		if _cinzel_font:
			result_label.add_theme_font_override("font", _cinzel_font)

	if result_match_lbl:
		var opp = cm.active_enemy_name if cm else "Enemy"
		var team = cm.active_enemy_team if cm else ""
		var team_str = " (%s)" % team if team != "" else ""
		result_match_lbl.text = "Exhibition / Tournament Arena vs %s%s" % [opp, team_str]

	if result_stats_lbl:
		var turn_str = "Turns: %d" % turns if turns > 0 else "Match Completed"
		result_stats_lbl.text = "%s  •  XP Rewarded: +%d XP" % [turn_str, xp_gained]

	if result_energy_lbl:
		if cm and cm.has_active_campaign:
			var fat_msg = ""
			if cm.is_fatigued:
				fat_msg = "\n[Warning] Low Energy! Combatant is Fatigued (-20% stats). Rest at the Campaign Hub!"
			result_energy_lbl.text = "Remaining Energy: %d/100 (-20 Energy spent)%s" % [cm.energy, fat_msg]
			result_energy_lbl.modulate = Color(1.0, 0.45, 0.45) if cm.is_fatigued else Color(0.70, 0.90, 1.0)
		else:
			result_energy_lbl.text = "Exhibition Match Completed."


# ══════════════════════════════════════════════
#  PUBLIC API
# ══════════════════════════════════════════════

func set_player_name(new_name: String, element_key: String = ""):
	if player_name:
		player_name.text = new_name
		if ELEMENT_UI_COLORS.has(element_key.to_lower()):
			player_name.modulate = ELEMENT_UI_COLORS[element_key.to_lower()]
	if element_key != "" and player_icon:
		var icon_path = "res://assets/icon_%s.png" % element_key.to_lower()
		if ResourceLoader.exists(icon_path):
			player_icon.texture = load(icon_path)

func set_enemy_name(new_name: String, element_key: String = ""):
	if enemy_name:
		enemy_name.text = new_name
		if ELEMENT_UI_COLORS.has(element_key.to_lower()):
			enemy_name.modulate = ELEMENT_UI_COLORS[element_key.to_lower()]
	if element_key != "" and enemy_icon:
		var icon_path = "res://assets/icon_%s.png" % element_key.to_lower()
		if ResourceLoader.exists(icon_path):
			enemy_icon.texture = load(icon_path)

func update_player_stats(hp: int, max_hp: int, mp: int, max_mp: int, sta: int = -1, max_sta: int = -1):
	if player_hp_bar:
		player_hp_bar.tween_to(hp)
		player_hp_bar.max_value = max_hp
		player_hp_bar.text = "HP: %d / %d" % [hp, max_hp]
	if player_mp_bar:
		player_mp_bar.tween_to(mp)
		player_mp_bar.max_value = max_mp
		player_mp_bar.text = "MP: %d / %d" % [mp, max_mp]
	if sta != -1 and player_sta_bar:
		player_sta_bar.tween_to(sta)
		player_sta_bar.max_value = max_sta if max_sta > 0 else 100
		player_sta_bar.text = "STA: %d / %d" % [sta, player_sta_bar.max_value]

func update_enemy_stats(hp: int, max_hp: int, mp: int, max_mp: int, sta: int = -1, max_sta: int = -1):
	if enemy_hp_bar:
		enemy_hp_bar.tween_to(hp)
		enemy_hp_bar.max_value = max_hp
		enemy_hp_bar.text = "HP: %d / %d" % [hp, max_hp]
	if enemy_mp_bar:
		enemy_mp_bar.tween_to(mp)
		enemy_mp_bar.max_value = max_mp
		enemy_mp_bar.text = "MP: %d / %d" % [mp, max_mp]
	if sta != -1 and enemy_sta_bar:
		enemy_sta_bar.tween_to(sta)
		enemy_sta_bar.max_value = max_sta if max_sta > 0 else 100
		enemy_sta_bar.text = "STA: %d / %d" % [sta, enemy_sta_bar.max_value]

# ══════════════════════════════════════════════
#  SUB SELECTION MODAL & BENCH MANAGEMENT (R2)
# ══════════════════════════════════════════════

func _build_sub_modal():
	if sub_modal_root != null:
		return
	sub_modal_root = Control.new()
	sub_modal_root.name = "SubModalRoot"
	sub_modal_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_modal_root.mouse_filter = Control.MOUSE_FILTER_STOP
	sub_modal_root.process_mode = Node.PROCESS_MODE_ALWAYS
	sub_modal_root.visible = false
	add_child(sub_modal_root)

	sub_modal_backdrop = ColorRect.new()
	sub_modal_backdrop.name = "SubModalBackdrop"
	sub_modal_backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	sub_modal_backdrop.color = Color(0.02, 0.03, 0.05, 0.80)
	sub_modal_backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	sub_modal_backdrop.gui_input.connect(_on_sub_backdrop_gui_input)
	sub_modal_root.add_child(sub_modal_backdrop)

	var pw = 580.0
	var ph = 360.0
	sub_panel = OrnatePanel.new()
	sub_panel.name = "SubPanel"
	sub_panel.size = Vector2(pw, ph)
	sub_panel.position = Vector2((SW - pw) / 2.0, (SH - ph) / 2.0)
	sub_panel.bracket_color = Color(0.95, 0.72, 0.22, 1.0) # Gold brackets
	sub_panel.bg_color = Color(0.05, 0.07, 0.11, 0.96)      # Dark obsidian
	sub_panel.top_center_diamond = true
	sub_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	sub_modal_root.add_child(sub_panel)

	var title = _label("Tactical Bench Substitution", sub_panel, Vector2(20, 14), Vector2(pw - 40, 24), 14, true)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color(1.0, 0.85, 0.3)
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)

	var subtitle = _label("Select reserve fighter to deploy  •  Esc or click outside to cancel", sub_panel, Vector2(20, 40), Vector2(pw - 40, 16), 9)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.modulate = Color(0.70, 0.78, 0.90)

	var scroll = ScrollContainer.new()
	scroll.position = Vector2(20, 66)
	scroll.size = Vector2(pw - 40, ph - 120)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sub_panel.add_child(scroll)

	sub_entries_vbox = VBoxContainer.new()
	sub_entries_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_entries_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(sub_entries_vbox)

	var btn_cancel = Button.new()
	btn_cancel.name = "CancelButton"
	btn_cancel.text = "Cancel (Esc)"
	btn_cancel.position = Vector2(20, ph - 44)
	btn_cancel.size = Vector2(pw - 40, 32)
	btn_cancel.focus_mode = Control.FOCUS_NONE
	_style_tactical_button(btn_cancel, Color(0.14, 0.08, 0.08, 0.95), Color(0.85, 0.3, 0.3, 0.8), Color(1.0, 0.8, 0.8), 11)
	if _cinzel_font:
		btn_cancel.add_theme_font_override("font", _cinzel_font)
	btn_cancel.pressed.connect(_close_sub_modal)
	sub_panel.add_child(btn_cancel)

func _on_sub_backdrop_gui_input(event: InputEvent):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_close_sub_modal()
		get_viewport().set_input_as_handled()

func _open_sub_modal(bench_fighters: Array[Dictionary]):
	if not sub_modal_root:
		_build_sub_modal()
	_populate_sub_modal(bench_fighters)
	sub_modal_root.visible = true

func _close_sub_modal():
	if sub_modal_root:
		sub_modal_root.visible = false

func _populate_sub_modal(bench_fighters: Array[Dictionary]):
	if not sub_entries_vbox:
		return
	for c in sub_entries_vbox.get_children():
		c.queue_free()

	var card_w = (sub_panel.size.x if sub_panel else 580.0) - 40.0 - 12.0
	for ally_data in bench_fighters:
		var card = Button.new()
		card.custom_minimum_size = Vector2(card_w, 64)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.focus_mode = Control.FOCUS_NONE
		_style_tactical_button(card, Color(0.08, 0.11, 0.16, 0.95), Color(0.35, 0.45, 0.60, 0.7), Color.WHITE, 11)

		var a_name: String = ally_data.get("name", "Reserve")
		var a_elem: String = ally_data.get("element", "fire")
		var cur_hp: int = ally_data.get("hp", ally_data.get("current_hp", 100))
		var max_hp: int = ally_data.get("max_hp", cur_hp)
		var cur_mp: int = ally_data.get("mp", ally_data.get("current_mp", 100))
		var max_mp: int = ally_data.get("max_mp", cur_mp)
		var cur_sta: int = ally_data.get("stamina", 100)
		var skills: Array = ally_data.get("equipped_skills", ally_data.get("equipped_abilities", []))

		var elem_col: Color = ELEMENT_UI_COLORS.get(a_elem.to_lower(), Color(1.0, 0.85, 0.3))

		# Fighter name (in elemental color) + element
		var name_lbl = Label.new()
		name_lbl.text = "%s  •  %s" % [a_name, a_elem.capitalize()]
		name_lbl.position = Vector2(14, 8)
		name_lbl.size = Vector2(250, 22)
		name_lbl.add_theme_font_size_override("font_size", 13)
		name_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		name_lbl.add_theme_constant_override("shadow_offset_x", 1)
		name_lbl.add_theme_constant_override("shadow_offset_y", 1)
		name_lbl.modulate = elem_col
		name_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(name_lbl)

		# Current HP/MP from campaign data
		var stats_lbl = Label.new()
		stats_lbl.text = "HP: %d/%d   MP: %d/%d   STA: %d" % [cur_hp, max_hp, cur_mp, max_mp, cur_sta]
		stats_lbl.position = Vector2(270, 9)
		stats_lbl.size = Vector2(card_w - 284, 20)
		stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		stats_lbl.add_theme_font_size_override("font_size", 10)
		stats_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		stats_lbl.add_theme_constant_override("shadow_offset_x", 1)
		stats_lbl.add_theme_constant_override("shadow_offset_y", 1)
		stats_lbl.modulate = Color(0.85, 0.90, 0.98)
		stats_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(stats_lbl)

		# Equipped skills list
		var skills_lbl = Label.new()
		var skill_items: Array[String] = []
		for s in skills:
			skill_items.append("[%s]" % str(s))
		var skills_str = "Skills: " + (" ".join(skill_items) if not skill_items.is_empty() else "None")
		skills_lbl.text = skills_str
		skills_lbl.position = Vector2(14, 34)
		skills_lbl.size = Vector2(card_w - 28, 20)
		skills_lbl.add_theme_font_size_override("font_size", 10)
		skills_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.85))
		skills_lbl.add_theme_constant_override("shadow_offset_x", 1)
		skills_lbl.add_theme_constant_override("shadow_offset_y", 1)
		skills_lbl.modulate = Color(0.70, 0.78, 0.88)
		skills_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(skills_lbl)

		var target_data = ally_data.duplicate()
		card.pressed.connect(func():
			_execute_sub(target_data)
		)

		sub_entries_vbox.add_child(card)

func _execute_sub(fighter_data: Dictionary):
	var bm = get_node_or_null("../BattleManager")
	var target_sub = bm.active_player_unit if (bm and "active_player_unit" in bm and bm.active_player_unit != null) else _player_ref
	if not bm or not target_sub:
		return

	var skills = fighter_data.get("equipped_skills", fighter_data.get("equipped_abilities", []))
	var sub_payload = {
		"name": fighter_data.get("name", "Reserve Fighter"),
		"element": fighter_data.get("element", "fire"),
		"hp": fighter_data.get("hp", 100),
		"max_hp": fighter_data.get("max_hp", fighter_data.get("hp", 100)),
		"mp": fighter_data.get("mp", 100),
		"max_mp": fighter_data.get("max_mp", fighter_data.get("mp", 100)),
		"stamina": fighter_data.get("stamina", 100),
		"max_stamina": fighter_data.get("max_stamina", fighter_data.get("stamina", 100)),
		"base_speed": fighter_data.get("speed", fighter_data.get("base_speed", 3)),
		"speed": fighter_data.get("speed", fighter_data.get("base_speed", 3)),
		"agility": fighter_data.get("agility", 25),
		"dexterity": fighter_data.get("dexterity", 25),
		"equipped_abilities": skills.duplicate(),
		"equipped_skills": skills.duplicate()
	}

	var success = bm.substitute_fighter(target_sub, sub_payload)
	if success:
		_close_sub_modal()
		update_sub_count(bm.subs_remaining)

func get_available_bench_fighters() -> Array[Dictionary]:
	var available: Array[Dictionary] = []
	var cm = get_node_or_null("/root/CampaignManager")
	var bm = get_node_or_null("../BattleManager")

	var on_field_names: Array[String] = []
	if bm and "player_units" in bm and not bm.player_units.is_empty():
		for u in bm.player_units:
			if is_instance_valid(u):
				on_field_names.append(u.name)
	elif _player_ref and is_instance_valid(_player_ref):
		on_field_names.append(_player_ref.name)

	if cm and cm.has_active_campaign and cm.player_name != "":
		for name in on_field_names:
			if name == "Player":
				on_field_names.append(cm.player_name)
				break

	var candidate_roster: Array = []
	if cm and cm.has_active_campaign and not cm.allies.is_empty():
		candidate_roster = cm.allies
	else:
		# Fallback roster for standalone/sandbox testing
		candidate_roster = [
			{"name": "Kora", "element": "air", "hp": 80, "max_hp": 80, "mp": 110, "max_mp": 110, "stamina": 105, "max_stamina": 105, "speed": 4, "agility": 38, "dexterity": 28, "equipped_skills": ["Gale_Step", "Wind"], "status": "Reserve"},
			{"name": "Gaius", "element": "earth", "hp": 130, "max_hp": 130, "mp": 90, "max_mp": 90, "stamina": 120, "max_stamina": 120, "speed": 2, "agility": 16, "dexterity": 24, "equipped_skills": ["Stone_Plating", "Metal"], "status": "Reserve"},
			{"name": "Torque", "element": "fire", "hp": 100, "max_hp": 100, "mp": 100, "max_mp": 100, "stamina": 100, "max_stamina": 100, "speed": 3, "agility": 28, "dexterity": 32, "equipped_skills": ["Combustion", "Lightning"], "status": "Reserve"},
			{"name": "Mira", "element": "water", "hp": 95, "max_hp": 95, "mp": 120, "max_mp": 120, "stamina": 95, "max_stamina": 95, "speed": 3, "agility": 25, "dexterity": 25, "equipped_skills": ["Aqua_Mend", "Ice"], "status": "Reserve"}
		]

	for ally in candidate_roster:
		var a_name = ally.get("name", "")
		if a_name == "":
			continue
		if a_name in on_field_names:
			continue
		if cm and cm.has_active_campaign and a_name == cm.player_name:
			continue
		var cur_hp = ally.get("hp", ally.get("current_hp", 100))
		if cur_hp <= 0:
			continue
		var status = ally.get("status", "Reserve")
		if status.to_lower() in ["ko", "injured", "retired", "inactive"]:
			continue

		available.append(ally)

	return available

func update_sub_count(count: int):
	if not btn_sub:
		return
	var bm = get_node_or_null("../BattleManager")
	if bm and bm.max_subs == 0:
		btn_sub.text = "No Subs (1v1)"
		btn_sub.disabled = true
		btn_sub.visible = false
		return

	btn_sub.visible = true
	if count <= 0:
		btn_sub.text = "Sub (0)"
		btn_sub.disabled = true
		return

	var bench = get_available_bench_fighters()
	if bench.is_empty():
		btn_sub.text = "No Bench"
		btn_sub.disabled = true
	else:
		btn_sub.text = "Sub (%d)" % count
		btn_sub.disabled = false

func _on_hud_sub_pressed():
	var bm = get_node_or_null("../BattleManager")
	var target_sub = bm.active_player_unit if (bm and "active_player_unit" in bm and bm.active_player_unit != null) else _player_ref
	if not bm or not target_sub:
		return

	if not bm.can_substitute(target_sub):
		if bm.max_subs == 0:
			log_action("Substitutions disabled in 1v1 Duels!")
		else:
			log_action("Cannot substitute: 0 subs remaining or fighter is KO'd!")
		return

	var bench = get_available_bench_fighters()
	# Condition 1: If 0 bench fighters are available: SUB button text shows "NO BENCH" and is disabled
	if bench.is_empty():
		log_action("No bench reserves available to sub in!")
		update_sub_count(bm.subs_remaining)
		return

	# Condition 2: If only 1 bench fighter is available: skip modal, execute sub directly
	if bench.size() == 1:
		_execute_sub(bench[0])
		return

	# Condition 3: If >1 bench fighters are available: open SubModalRoot
	_open_sub_modal(bench)

func update_xp(level: int, xp: int, xp_to_next: int):
	if level_label:
		level_label.text = "Lv. %d" % level
	if player_xp_bar:
		player_xp_bar.tween_to(xp)
		player_xp_bar.max_value = max(1, xp_to_next)
		player_xp_bar.text = "XP: %d / %d" % [xp, xp_to_next]

func update_moves(moves: int):
	if moves_label:
		moves_label.text = "Moves: %d" % moves

func update_abilities(equipped: Array, element_db, player_ref_opt = null):
	var p_ref = player_ref_opt if player_ref_opt != null else _player_ref
	for i in range(min(4, ability_slots.size())):
		var slot = ability_slots[i]
		var badge = slot.get("badge")
		var f_lbl = slot.get("form")
		var c_btn = slot.get("cycle_btn")
		if i < equipped.size():
			var key = equipped[i]
			if element_db and element_db.ABILITIES.has(key):
				var ab = element_db.ABILITIES[key]
				var var_info = {}
				if p_ref and p_ref.has_method("get_ability_variation_info"):
					var_info = p_ref.get_ability_variation_info(key)

				var form_name = var_info.get("name", ab["name"])
				var eff_r = var_info["range_override"] if var_info.get("range_override", -1) > 0 else ab["range"]
				var eff_mp = int(round(ab["mp_cost"] * var_info.get("mp_mult", 1.0)))

				slot["name"].text = ab["name"]
				slot["name"].modulate = Color(1.0, 0.95, 0.85)
				slot["cost"].text = "MP: %d" % eff_mp
				slot["cost"].modulate = Color(0.35, 0.80, 1.0)
				slot["range"].text = "Rng: %d" % eff_r
				slot["range"].modulate = Color(0.40, 0.95, 0.65)
				if f_lbl:
					f_lbl.text = "Form: %s" % form_name
					f_lbl.modulate = Color(1.0, 0.82, 0.35)
				if c_btn:
					c_btn.visible = true
				slot["panel"].bracket_color = Color(0.45, 0.60, 0.85, 0.85)
				if badge: badge.modulate = Color(1.0, 0.85, 0.3)
			else:
				slot["name"].text = "---"
				slot["name"].modulate = Color(0.35, 0.40, 0.50)
				slot["cost"].text = "MP: --"
				slot["cost"].modulate = Color(0.25, 0.30, 0.40)
				slot["range"].text = "Rng: --"
				slot["range"].modulate = Color(0.25, 0.30, 0.40)
				if f_lbl: f_lbl.text = ""
				if c_btn: c_btn.visible = false
				slot["panel"].bracket_color = Color(0.20, 0.26, 0.38, 0.5)
				if badge: badge.modulate = Color(0.45, 0.50, 0.60)
		else:
			slot["name"].text = "---"
			slot["name"].modulate = Color(0.35, 0.40, 0.50)
			slot["cost"].text = "MP: --"
			slot["cost"].modulate = Color(0.25, 0.30, 0.40)
			slot["range"].text = "Rng: --"
			slot["range"].modulate = Color(0.25, 0.30, 0.40)
			if f_lbl: f_lbl.text = ""
			if c_btn: c_btn.visible = false
			slot["panel"].bracket_color = Color(0.20, 0.26, 0.38, 0.5)
			if badge: badge.modulate = Color(0.45, 0.50, 0.60)

func update_artifact(artifact: Dictionary, charges: int):
	if ability_slots.size() >= 5:
		var slot = ability_slots[4]
		var badge = slot.get("badge")
		var f_lbl = slot.get("form")
		var c_btn = slot.get("cycle_btn")
		if f_lbl: f_lbl.text = ""
		if c_btn: c_btn.visible = false
		if artifact.is_empty():
			slot["name"].text = "Artifact"
			slot["name"].modulate = Color(0.35, 0.40, 0.50)
			slot["cost"].size = Vector2(AB_W - 32, 16)
			slot["cost"].text = "No artifact"
			slot["cost"].modulate = Color(0.25, 0.30, 0.40)
			slot["range"].text = ""
			slot["panel"].bracket_color = Color(0.20, 0.26, 0.38, 0.5)
			if badge: badge.modulate = Color(0.45, 0.50, 0.60)
		else:
			slot["name"].text = artifact.get("name", "Artifact")
			slot["name"].modulate = Color(1.0, 0.85, 0.3)
			slot["cost"].size = Vector2(AB_W - 32, 16)
			slot["cost"].text = "Charges: %d" % charges
			slot["cost"].modulate = Color(0.9, 0.7, 1.0)
			slot["range"].text = ""
			slot["panel"].bracket_color = Color(0.85, 0.55, 0.95, 0.85)
			if badge: badge.modulate = Color(1.0, 0.85, 0.3)

func highlight_ability_slot(idx: int):
	for i in range(ability_panels.size()):
		ability_panels[i].is_highlighted = (i == idx)

func update_turn_indicator(label_text: String, is_player: bool):
	if turn_indicator_panel:
		turn_indicator_panel.text = label_text
		turn_indicator_panel.is_player_turn = is_player

func log_action(message: String):
	_log_lines.append(message)
	if _log_lines.size() > MAX_LOG_LINES:
		_log_lines.pop_front()
	if action_log:
		action_log.clear()
		for line in _log_lines:
			action_log.append_text(line + "\n")

func show_skill_offer(offers: Array, element_db):
	if skill_offer_panel == null:
		return
	_skill_offer_keys = offers
	_element_db = element_db
	for i in range(offer_buttons.size()):
		if i < offers.size() and element_db.ABILITIES.has(offers[i]):
			var ab = element_db.ABILITIES[offers[i]]
			offer_buttons[i].text = "%s  [MP:%d  Rng:%d]  — %s" % [ab["name"], ab["mp_cost"], ab["range"], ab.get("desc", "")]
			offer_buttons[i].visible = true
		else:
			offer_buttons[i].visible = false
	skill_offer_panel.visible = true

func _on_skill_offer_chosen(idx: int):
	if idx < _skill_offer_keys.size():
		var key = _skill_offer_keys[idx]
		if _player_ref and _player_ref.has_method("accept_skill_offer"):
			_player_ref.accept_skill_offer(key)
	skill_offer_panel.visible = false
	_skill_offer_keys = []

func spawn_damage_popup(world_pos: Vector2, amount: Variant, popup_type: String = "damage", skill_elem: String = ""):
	var popup = DamagePopup.new()
	popup._font = _cinzel_font
	add_child(popup)

	var txt: String = ""
	var color: Color = Color(1.0, 0.9, 0.4)
	var font_sz: int = 18

	var sfx = get_node_or_null("/root/SoundFX")

	match popup_type:
		"damage":
			txt = "-%d" % abs(int(amount))
			color = Color(1.0, 0.3, 0.3)
			font_sz = 18
			trigger_screen_shake(3.5, 0.16)
			trigger_hit_stop(25.0)
			if sfx:
				sfx.play_element_impact(skill_elem, false, false)
		"heal":
			txt = "+%d" % abs(int(amount))
			color = Color(0.2, 1.0, 0.4)
			font_sz = 18
			if sfx:
				sfx.play_sfx("heal")
		"crit":
			txt = "CRIT! -%d" % abs(int(amount))
			color = Color(1.0, 0.85, 0.1)
			font_sz = 22
			trigger_screen_shake(9.0, 0.28)
			trigger_hit_stop(50.0)
			if sfx:
				sfx.play_element_impact(skill_elem, true, false)
		"status":
			txt = str(amount).to_upper()
			color = Color(0.9, 0.7, 1.0)
			font_sz = 16
			if "WEAKNESS" in txt:
				color = Color(1.0, 0.45, 0.15)
				trigger_screen_shake(7.5, 0.24)
				trigger_hit_stop(45.0)
				if sfx:
					sfx.play_element_impact(skill_elem, false, true)
			elif "CRITICAL" in txt or "BACKSTAB" in txt:
				color = Color(1.0, 0.88, 0.2)
				trigger_screen_shake(9.5, 0.30)
				trigger_hit_stop(50.0)
				if sfx:
					sfx.play_sfx("crit")
			elif "BRACED" in txt or "BLOCK" in txt:
				color = Color(0.4, 0.8, 1.0)
				trigger_screen_shake(5.0, 0.18)
				if sfx:
					sfx.play_sfx("block")
			elif "RIPOSTE" in txt:
				color = Color(1.0, 0.7, 0.2)
				trigger_screen_shake(6.5, 0.22)
				trigger_hit_stop(35.0)
				if sfx:
					sfx.play_sfx("block")
			elif "EVADED" in txt:
				if sfx:
					sfx.play_sfx("air", -3.0, 1.25)
		"mp":
			txt = "MP -%d" % abs(int(amount))
			color = Color(0.3, 0.6, 1.0)
			font_sz = 16
		_:
			txt = str(amount)
			color = Color(1.0, 0.9, 0.4)
			font_sz = 18

	var vp = get_viewport()
	var screen_pos = world_pos
	if vp:
		screen_pos = vp.get_canvas_transform() * (world_pos - Vector2(0, 52))
	else:
		screen_pos = world_pos - Vector2(0, 52)
	screen_pos.x += randf_range(-12.0, 12.0)

	popup.setup(txt, color, screen_pos, font_sz)

func show_fusion_banner(fusion_name: String, elem1: String, elem2: String, bonus_dmg: int = 12):
	var banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bw = 380.0
	var bh = 48.0
	banner.size = Vector2(bw, bh)
	banner.position = Vector2((SW - bw) / 2.0, 72.0)

	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.bg_color = Color(0.05, 0.08, 0.14, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = UITheme.GOLD_PRIMARY
	sb.shadow_color = Color(0.95, 0.72, 0.22, 0.5)
	sb.shadow_size = 10
	banner.add_theme_stylebox_override("panel", sb)

	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	banner.add_child(vb)

	var title = Label.new()
	title.text = "⚡ ELEMENTAL FUSION: %s" % fusion_name.to_upper()
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = UITheme.GOLD_PRIMARY
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)
	vb.add_child(title)

	var sub = Label.new()
	sub.text = "%s + %s  •  +%d Bonus Damage!" % [elem1.capitalize(), elem2.capitalize(), bonus_dmg]
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.modulate = Color(0.85, 0.92, 1.0)
	vb.add_child(sub)

	add_child(banner)

	banner.modulate = Color(1, 1, 1, 0)
	banner.position.y = 52.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_property(banner, "position:y", 72.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var fade_tween = create_tween()
	fade_tween.tween_interval(2.2)
	fade_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	fade_tween.tween_callback(banner.queue_free)

func show_resonance_banner():
	var banner = PanelContainer.new()
	banner.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bw = 360.0
	var bh = 44.0
	banner.size = Vector2(bw, bh)
	banner.position = Vector2((SW - bw) / 2.0, 72.0)

	var sb = StyleBoxFlat.new()
	sb.set_corner_radius_all(4)
	sb.bg_color = Color(0.08, 0.06, 0.14, 0.96)
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.border_color = Color(0.45, 0.85, 1.0)
	sb.shadow_color = Color(0.20, 0.60, 1.0, 0.5)
	sb.shadow_size = 12
	banner.add_theme_stylebox_override("panel", sb)

	var vb = VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 2)
	banner.add_child(vb)

	var title = Label.new()
	title.text = "🌟 RESONANCE SURGE MAXED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 12)
	title.modulate = Color(0.45, 0.90, 1.0)
	if _cinzel_font:
		title.add_theme_font_override("font", _cinzel_font)
	vb.add_child(title)

	var sub = Label.new()
	sub.text = "All Elemental Attacks Empowered: +20% Damage"
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.add_theme_font_size_override("font_size", 9)
	sub.modulate = Color(1.0, 0.92, 0.70)
	vb.add_child(sub)

	add_child(banner)

	banner.modulate = Color(1, 1, 1, 0)
	banner.position.y = 52.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(banner, "modulate:a", 1.0, 0.25)
	tween.tween_property(banner, "position:y", 72.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	var fade_tween = create_tween()
	fade_tween.tween_interval(2.2)
	fade_tween.tween_property(banner, "modulate:a", 0.0, 0.4)
	fade_tween.tween_callback(banner.queue_free)
