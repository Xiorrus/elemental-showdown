# tactical_bracket_panel.gd
# Procedural tactical card panel with L-shaped corner brackets (┌ ┐ └ ┘),
# optional top center diamond pip, and customizable border & background.
@tool
extends Control

@export var bracket_color: Color = Color(0.9, 0.65, 0.2, 1.0):
	set(v):
		bracket_color = v
		queue_redraw()

@export var bracket_length: float = 12.0:
	set(v):
		bracket_length = v
		queue_redraw()

@export var bracket_thickness: float = 2.0:
	set(v):
		bracket_thickness = v
		queue_redraw()

@export var draw_box_border: bool = true:
	set(v):
		draw_box_border = v
		queue_redraw()

@export var box_border_color: Color = Color(0.2, 0.25, 0.35, 0.5):
	set(v):
		box_border_color = v
		queue_redraw()

@export var bg_color: Color = Color(0.06, 0.08, 0.12, 0.95):
	set(v):
		bg_color = v
		queue_redraw()

@export var top_center_diamond: bool = true:
	set(v):
		top_center_diamond = v
		queue_redraw()

func _ready():
	queue_redraw()

func _draw():
	var w = size.x
	var h = size.y
	if w <= 4 or h <= 4:
		return

	# 1. Background fill
	draw_rect(Rect2(0, 0, w, h), bg_color)

	# 2. Subtle box border
	if draw_box_border:
		draw_rect(Rect2(0, 0, w, h), box_border_color, false, 1.0)

	# 3. 4 Corner L-Brackets
	var bl = bracket_length
	var bt = bracket_thickness

	# Top-Left Bracket
	draw_line(Vector2(0, bl), Vector2(0, 0), bracket_color, bt)
	draw_line(Vector2(0, 0), Vector2(bl, 0), bracket_color, bt)

	# Top-Right Bracket
	draw_line(Vector2(w - bl, 0), Vector2(w, 0), bracket_color, bt)
	draw_line(Vector2(w, 0), Vector2(w, bl), bracket_color, bt)

	# Bottom-Left Bracket
	draw_line(Vector2(0, h - bl), Vector2(0, h), bracket_color, bt)
	draw_line(Vector2(0, h), Vector2(bl, h), bracket_color, bt)

	# Bottom-Right Bracket
	draw_line(Vector2(w - bl, h), Vector2(w, h), bracket_color, bt)
	draw_line(Vector2(w, h), Vector2(w, h - bl), bracket_color, bt)

	# 4. Top Center Diamond Pip
	if top_center_diamond:
		var mid_x = w / 2.0
		var r = 4.0
		var pts = PackedVector2Array([
			Vector2(mid_x, -r),
			Vector2(mid_x + r, 0),
			Vector2(mid_x, r),
			Vector2(mid_x - r, 0)
		])
		draw_colored_polygon(pts, bracket_color)
