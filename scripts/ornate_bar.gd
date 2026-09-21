# ornate_bar.gd
# Custom Ornate Progress Bar with pointed chevron caps, double borders, center diamond pip, and smooth tweens.
# Replicates the exact gothic fantasy progress bar aesthetic from media_1789247095105.jpg.
@tool
extends Control

var _value: float = 100.0
@export var value: float:
	get:
		return _value
	set(v):
		set_value(v, false)
@export var max_value: float = 100.0:
	set(v):
		max_value = max(1.0, v)
		queue_redraw()

@export_enum("ornate", "sleek") var bar_style: String = "ornate":
	set(v):
		bar_style = v
		queue_redraw()

@export_enum("gold", "ruby", "sapphire", "emerald") var bar_theme: String = "gold":
	set(v):
		bar_theme = v
		_update_theme_colors()
		queue_redraw()

@export var label_text: String = "":
	set(v):
		label_text = v
		queue_redraw()

@export var show_numbers: bool = true:
	set(v):
		show_numbers = v
		queue_redraw()

var display_value: float = 100.0
var fill_color: Color = Color(0.96, 0.78, 0.25)
var fill_glow: Color = Color(1.0, 0.90, 0.50, 0.4)
var border_outer: Color = Color(0.85, 0.88, 0.94)
var border_inner: Color = Color(0.35, 0.40, 0.52)
var bg_color: Color = Color(0.06, 0.07, 0.10, 0.95)

var font: Font = null
var tween: Tween = null

func _init():
	_update_theme_colors()


func _ready():
	font = load("res://assets/fonts/Cinzel-Bold.ttf")
	display_value = value
	_update_theme_colors()
	queue_redraw()

func _update_theme_colors():
	match bar_theme:
		"gold": # Energy / XP
			fill_color = Color(0.96, 0.78, 0.22)
			fill_glow = Color(1.0, 0.92, 0.55, 0.45)
		"ruby": # HP
			fill_color = Color(0.90, 0.20, 0.25)
			fill_glow = Color(1.0, 0.45, 0.50, 0.45)
		"sapphire": # MP
			fill_color = Color(0.22, 0.65, 1.0)
			fill_glow = Color(0.55, 0.85, 1.0, 0.45)
		"emerald": # Stamina / Buff
			fill_color = Color(0.25, 0.88, 0.45)
			fill_glow = Color(0.60, 1.0, 0.70, 0.45)

func set_value(v: float, animate: bool = true):
	_value = clamp(v, 0.0, max_value)
	if not is_inside_tree() or Engine.is_editor_hint() or not animate:
		display_value = _value
		queue_redraw()
		return

	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "display_value", _value, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_callback(queue_redraw)

func _process(_delta):
	if tween and tween.is_running():
		queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	if w <= 10 or h <= 4:
		return

	var mid_y = h * 0.5
	var ratio = clamp(display_value / max_value, 0.0, 1.0)

	# Sleek horizontal gauge for slim bars (e.g. XP bar, Promotion gauge) matching media_1789304951399.png
	if bar_style == "sleek" or h < 20:
		# 1. Dark background
		draw_rect(Rect2(0, 1, w, h - 2), bg_color)
		# 2. Outer border
		draw_rect(Rect2(0, 1, w, h - 2), border_outer, false, 1.2)
		# 3. Inner border
		draw_rect(Rect2(2, 3, w - 4, h - 6), border_inner, false, 1.0)

		# 4. Fill track
		if ratio > 0.005:
			var fill_w = (w - 4) * ratio
			draw_rect(Rect2(2, 3, fill_w, h - 6), fill_color)
			draw_rect(Rect2(2, 3, fill_w, (h - 6) * 0.45), fill_glow)

			# 5. Sliding diamond cursor at the progress tip (as seen in media_1789304951399.png)
			var cur_x = clamp(2 + fill_w, 4.0, w - 4.0)
			var d_sz = min(5.0, (h - 2) * 0.5)
			var diamond = PackedVector2Array([
				Vector2(cur_x, mid_y - d_sz),
				Vector2(cur_x + d_sz, mid_y),
				Vector2(cur_x, mid_y + d_sz),
				Vector2(cur_x - d_sz, mid_y),
				Vector2(cur_x, mid_y - d_sz)
			])
			draw_colored_polygon(diamond, Color(0.1, 0.12, 0.16, 0.95))
			draw_polyline(diamond, Color(1.0, 1.0, 1.0, 0.9), 1.2)
			var inner_d = PackedVector2Array([
				Vector2(cur_x, mid_y - d_sz * 0.5),
				Vector2(cur_x + d_sz * 0.5, mid_y),
				Vector2(cur_x, mid_y + d_sz * 0.5),
				Vector2(cur_x - d_sz * 0.5, mid_y)
			])
			draw_colored_polygon(inner_d, fill_color)
		return

	var cap_w = min(12.0, h * 0.5)

	# 1. Outer background track (Chevron shape)
	var bg_points = PackedVector2Array([
		Vector2(2, mid_y),
		Vector2(cap_w + 2, 2),
		Vector2(w - cap_w - 2, 2),
		Vector2(w - 2, mid_y),
		Vector2(w - cap_w - 2, h - 2),
		Vector2(cap_w + 2, h - 2)
	])
	draw_colored_polygon(bg_points, bg_color)

	# 2. Fill Track
	if ratio > 0.005:
		var fill_w = (w - 8) * ratio
		var f_right = 4 + fill_w
		var f_cap = min(cap_w * 0.8, fill_w * 0.5)

		var fill_points: PackedVector2Array
		if f_right < w - cap_w - 4:
			fill_points = PackedVector2Array([
				Vector2(4, mid_y),
				Vector2(f_cap + 4, 4),
				Vector2(f_right, 4),
				Vector2(f_right, h - 4),
				Vector2(f_cap + 4, h - 4)
			])
		else:
			fill_points = PackedVector2Array([
				Vector2(4, mid_y),
				Vector2(f_cap + 4, 4),
				Vector2(min(f_right, w - cap_w - 4), 4),
				Vector2(f_right, mid_y),
				Vector2(min(f_right, w - cap_w - 4), h - 4),
				Vector2(f_cap + 4, h - 4)
			])
		draw_colored_polygon(fill_points, fill_color)

		var sheen_points = PackedVector2Array([
			Vector2(4, mid_y),
			Vector2(f_cap + 4, 4),
			Vector2(f_right, 4),
			Vector2(f_right, mid_y - 1),
			Vector2(f_cap + 4, mid_y - 1)
		])
		draw_colored_polygon(sheen_points, fill_glow)

	# 3. Inner border line
	var in_points = PackedVector2Array([
		Vector2(4, mid_y),
		Vector2(cap_w + 3, 4),
		Vector2(w - cap_w - 3, 4),
		Vector2(w - 4, mid_y),
		Vector2(w - cap_w - 3, h - 4),
		Vector2(cap_w + 3, h - 4),
		Vector2(4, mid_y)
	])
	draw_polyline(in_points, border_inner, 1.0)

	# 4. Outer border line
	var out_points = PackedVector2Array([
		Vector2(1, mid_y),
		Vector2(cap_w + 1, 1),
		Vector2(w - cap_w - 1, 1),
		Vector2(w - 1, mid_y),
		Vector2(w - cap_w - 1, h - 1),
		Vector2(cap_w + 1, h - 1),
		Vector2(1, mid_y)
	])
	draw_polyline(out_points, border_outer, 1.5)

	# 5. Left and right chevron spearhead accent dots
	draw_circle(Vector2(2, mid_y), 1.5, border_outer)
	draw_circle(Vector2(w - 2, mid_y), 1.5, border_outer)

	# 6. Center Diamond Pip Marker
	var center_x = w * 0.5
	var d_size = min(6.0, h * 0.35)
	var diamond_outer = PackedVector2Array([
		Vector2(center_x, mid_y - d_size - 1.5),
		Vector2(center_x + d_size + 1.5, mid_y),
		Vector2(center_x, mid_y + d_size + 1.5),
		Vector2(center_x - d_size - 1.5, mid_y),
		Vector2(center_x, mid_y - d_size - 1.5)
	])
	draw_colored_polygon(diamond_outer, Color(0.08, 0.10, 0.14, 0.9))
	draw_polyline(diamond_outer, border_outer, 1.2)

	var diamond_inner = PackedVector2Array([
		Vector2(center_x, mid_y - d_size * 0.6),
		Vector2(center_x + d_size * 0.6, mid_y),
		Vector2(center_x, mid_y + d_size * 0.6),
		Vector2(center_x - d_size * 0.6, mid_y)
	])
	draw_colored_polygon(diamond_inner, fill_color)

	# 7. Text readout (Label left, Numbers right, Center diamond pip clear)
	if font:
		var f_size = int(clamp(h * 0.52, 10, 13))
		var y_baseline = mid_y + f_size * 0.35

		# Left Label
		if label_text != "":
			draw_string(font, Vector2(16, y_baseline) + Vector2(1, 1), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(16, y_baseline), label_text, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, Color(1, 1, 1, 0.95))

		# Right Numbers
		if show_numbers:
			var num_str = "%d/%d" % [int(round(display_value)), int(round(max_value))]
			var num_sz = font.get_string_size(num_str, HORIZONTAL_ALIGNMENT_RIGHT, -1, f_size)
			var num_x = w - num_sz.x - 16
			draw_string(font, Vector2(num_x, y_baseline) + Vector2(1, 1), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, Color(0, 0, 0, 0.9))
			draw_string(font, Vector2(num_x, y_baseline), num_str, HORIZONTAL_ALIGNMENT_LEFT, -1, f_size, Color(1, 1, 1, 0.95))
