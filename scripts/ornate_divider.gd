# ornate_divider.gd
# Sleek horizontal section divider with a centered diamond pip.
@tool
extends Control

@export var diamond_color: Color = Color(0.95, 0.75, 0.2, 1.0):
	set(v):
		diamond_color = v
		queue_redraw()

@export var line_color: Color = Color(0.18, 0.22, 0.32, 0.6):
	set(v):
		line_color = v
		queue_redraw()

func _ready():
	queue_redraw()

func _draw():
	var w = size.x
	var mid_y = size.y / 2.0
	var mid_x = w / 2.0
	var dia_r = 4.5

	# Left and right line segments
	draw_line(Vector2(0, mid_y), Vector2(mid_x - dia_r - 4, mid_y), line_color, 1.0)
	draw_line(Vector2(mid_x + dia_r + 4, mid_y), Vector2(w, mid_y), line_color, 1.0)

	# Centered diamond
	var pts = PackedVector2Array([
		Vector2(mid_x, mid_y - dia_r),
		Vector2(mid_x + dia_r, mid_y),
		Vector2(mid_x, mid_y + dia_r),
		Vector2(mid_x - dia_r, mid_y)
	])
	draw_colored_polygon(pts, diamond_color)
