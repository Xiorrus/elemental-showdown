# ornate_panel.gd
# Gothic fantasy ornate panel with corner spikes, diamond accents, and Metaphor-style crimson header ribbons.
# Matches the banner frames in media_1789247095105.jpg.
@tool
extends PanelContainer

@export var border_color: Color = Color(0.72, 0.78, 0.88, 0.85)
@export var bg_color: Color = Color(0.07, 0.08, 0.12, 0.95)
@export var header_title: String = "":
	set(v):
		header_title = v
		queue_redraw()

@export_enum("none", "crimson", "gold", "cyan", "dark") var ribbon_theme: String = "none":
	set(v):
		ribbon_theme = v
		queue_redraw()

@export var icon_texture: Texture2D = null:
	set(v):
		icon_texture = v
		queue_redraw()

var font: Font = null

func _ready():
	font = load("res://assets/fonts/Cinzel-Bold.ttf")
	var top_pad = 36 if ribbon_theme != "none" else 14
	add_theme_constant_override("margin_top", top_pad)
	add_theme_constant_override("margin_left", 14)
	add_theme_constant_override("margin_right", 14)
	add_theme_constant_override("margin_bottom", 14)
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	if w <= 10 or h <= 10:
		return

	# 1. Background
	draw_rect(Rect2(0, 0, w, h), bg_color)

	# 2. Ornate Corner Cuts and Double Border
	var c = 8.0 # corner bevel size
	var outer_poly = PackedVector2Array([
		Vector2(c, 0),
		Vector2(w - c, 0),
		Vector2(w, c),
		Vector2(w, h - c),
		Vector2(w - c, h),
		Vector2(c, h),
		Vector2(0, h - c),
		Vector2(0, c),
		Vector2(c, 0)
	])
	draw_polyline(outer_poly, border_color, 1.5)

	# Inner hairline border
	var inner_poly = PackedVector2Array([
		Vector2(c + 2, 3),
		Vector2(w - c - 2, 3),
		Vector2(w - 3, c + 2),
		Vector2(w - 3, h - c - 2),
		Vector2(w - c - 2, h - 3),
		Vector2(c + 2, h - 3),
		Vector2(3, h - c - 2),
		Vector2(3, c + 2),
		Vector2(c + 2, 3)
	])
	draw_polyline(inner_poly, Color(border_color.r, border_color.g, border_color.b, 0.35), 1.0)

	# 3. Corner Diamond Pips (from reference image)
	for pt in [Vector2(c, c), Vector2(w - c, c), Vector2(c, h - c), Vector2(w - c, h - c)]:
		_draw_diamond(pt, 3.5, border_color)

	# 4. Optional Top Ribbon Banner (Metaphor style)
	if ribbon_theme != "none":
		var r_col: Color
		match ribbon_theme:
			"crimson": r_col = Color(0.88, 0.12, 0.22, 0.95)
			"gold": r_col = Color(0.92, 0.74, 0.18, 0.95)
			"cyan": r_col = Color(0.0, 0.82, 0.85, 0.95)
			"dark": r_col = Color(0.12, 0.15, 0.22, 0.95)

		# Slanted ribbon banner polygon
		var banner_h = 28.0
		var r_points = PackedVector2Array([
			Vector2(0, 0),
			Vector2(w - 20, 0),
			Vector2(w - 35, banner_h),
			Vector2(0, banner_h)
		])
		draw_colored_polygon(r_points, r_col)
		draw_line(Vector2(0, banner_h), Vector2(w - 35, banner_h), Color(1, 1, 1, 0.6), 1.0)

		# Draw icon if present
		var text_x = 12.0
		if icon_texture:
			var icon_h = 20.0
			var icon_w = icon_texture.get_width() * (icon_h / max(1.0, icon_texture.get_height()))
			draw_texture_rect(icon_texture, Rect2(10, 4, icon_w, icon_h), false)
			text_x = 18.0 + icon_w

		# Draw title on ribbon
		if header_title != "" and font:
			draw_string(font, Vector2(text_x, 20), header_title, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.98))

func _draw_diamond(pos: Vector2, radius: float, col: Color):
	var pts = PackedVector2Array([
		pos + Vector2(0, -radius),
		pos + Vector2(radius, 0),
		pos + Vector2(0, radius),
		pos + Vector2(-radius, 0),
		pos + Vector2(0, -radius)
	])
	draw_colored_polygon(pts, col)
