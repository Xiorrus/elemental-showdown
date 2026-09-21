# tactical_bracket_frame.gd
# Draws outer tactical corner brackets (┌ ┐ └ ┘) around containers without changing hierarchy
@tool
extends HBoxContainer

@export var bracket_color: Color = Color(0.13, 0.72, 0.85, 1.0)
@export var bracket_length: float = 14.0
@export var bracket_thickness: float = 2.0

func _draw():
	var w = size.x
	var h = size.y
	var bl = bracket_length
	var bt = bracket_thickness
	var col = bracket_color

	# Top-Left Bracket
	draw_line(Vector2(-4, bl), Vector2(-4, -4), col, bt)
	draw_line(Vector2(-4, -4), Vector2(bl, -4), col, bt)

	# Top-Right Bracket
	draw_line(Vector2(w + 4 - bl, -4), Vector2(w + 4, -4), col, bt)
	draw_line(Vector2(w + 4, -4), Vector2(w + 4, bl), col, bt)

	# Bottom-Left Bracket
	draw_line(Vector2(-4, h + 4 - bl), Vector2(-4, h + 4), col, bt)
	draw_line(Vector2(-4, h + 4), Vector2(bl, h + 4), col, bt)

	# Bottom-Right Bracket
	draw_line(Vector2(w + 4 - bl, h + 4), Vector2(w + 4, h + 4), col, bt)
	draw_line(Vector2(w + 4, h + 4), Vector2(w + 4, h + 4 - bl), col, bt)
