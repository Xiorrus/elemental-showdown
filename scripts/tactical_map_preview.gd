# tactical_map_preview.gd
# Renders the 6x6 Tactical Map Blueprint matching Image 2 & 3 from the Stitch prototype.
@tool
extends Control

var font: Font = null
var hazard_cells = [Vector2i(2, 0), Vector2i(3, 0), Vector2i(4, 1)] # C1, D1, E2
var power_cells = [Vector2i(1, 2), Vector2i(3, 3)] # B3, D4
var cover_cells = [Vector2i(1, 1), Vector2i(3, 2), Vector2i(2, 3), Vector2i(1, 4)] # B2, D3, C4, B5
var deploy_cells = [Vector2i(0, 5), Vector2i(1, 5), Vector2i(3, 5), Vector2i(4, 5)] # Row 6

func _ready():
	font = load("res://assets/fonts/Cinzel-Bold.ttf")
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	if w <= 60 or h <= 60:
		return

	var cols = 6
	var rows = 6
	var cell_w = (w - (cols - 1) * 6.0) / cols
	var cell_h = (h - (rows - 1) * 6.0) / rows

	var col_letters = ["A", "B", "C", "D", "E", "F"]

	for r in range(rows):
		for c in range(cols):
			var pos = Vector2(c * (cell_w + 6.0), r * (cell_h + 6.0))
			var rect = Rect2(pos, Vector2(cell_w, cell_h))
			var cell_coord = Vector2i(c, r)

			var bg_col = Color(0.09, 0.11, 0.16, 0.95)
			var border_col = Color(0.20, 0.24, 0.32, 0.8)
			var is_hazard = cell_coord in hazard_cells
			var is_power = cell_coord in power_cells
			var is_cover = cell_coord in cover_cells
			var is_deploy = cell_coord in deploy_cells

			if is_hazard:
				bg_col = Color(0.28, 0.12, 0.12, 0.95)
				border_col = Color(0.85, 0.35, 0.30, 0.9)
			elif is_power:
				bg_col = Color(0.08, 0.22, 0.26, 0.95)
				border_col = Color(0.0, 0.80, 0.85, 0.9)
			elif is_cover:
				bg_col = Color(0.14, 0.16, 0.22, 0.95)
				border_col = Color(0.40, 0.45, 0.55, 0.9)
			elif is_deploy:
				bg_col = Color(0.08, 0.18, 0.24, 0.95)
				border_col = Color(0.20, 0.75, 0.90, 0.95)

			draw_rect(rect, bg_col)
			draw_rect(rect, border_col, false, 1.5 if is_deploy or is_hazard else 1.0)

			# Draw coordinate label
			if font:
				var coord_name = "%s%d" % [col_letters[c], r + 1]
				var text_col = Color(0.5, 0.55, 0.65, 0.7)
				if is_hazard: text_col = Color(1.0, 0.6, 0.5)
				elif is_power: text_col = Color(0.4, 0.9, 1.0)
				elif is_deploy: text_col = Color(0.6, 0.95, 1.0)

				draw_string(font, pos + Vector2(6, 16), coord_name, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, text_col)

			# Draw Icon marker
			var center_pt = rect.get_center()
			if is_hazard:
				# Hazard Skull marker
				draw_circle(center_pt, 6.0, Color(0.95, 0.35, 0.30))
				draw_circle(center_pt, 3.0, Color(0.28, 0.12, 0.12))
			elif is_power:
				# Energy spark marker
				draw_circle(center_pt, 5.0, Color(0.0, 0.85, 0.90))
			elif is_cover:
				# Cover barricade hash
				draw_line(center_pt - Vector2(6, 0), center_pt + Vector2(6, 0), Color(0.6, 0.65, 0.75), 2.0)
				draw_line(center_pt - Vector2(0, 6), center_pt + Vector2(0, 6), Color(0.6, 0.65, 0.75), 2.0)
