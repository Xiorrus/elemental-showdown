# metaphor_bg.gd
# Metaphor: ReFantazio inspired dynamic background with technical compass reticles,
# angled guide lines, and dramatic crimson / cyan contrast banners.
@tool
extends Control

func _draw():
	var w = size.x
	var h = size.y

	# 1. Base gradient fill (deep obsidian/charcoal)
	draw_rect(Rect2(0, 0, w, h), Color(0.05, 0.06, 0.09, 1.0))

	# 2. Slanted guide lines across canvas
	var line_col = Color(1.0, 1.0, 1.0, 0.035)
	for i in range(12):
		var y_pos = i * 60.0 + 30.0
		draw_line(Vector2(0, y_pos), Vector2(w, y_pos - 40.0), line_col, 1.0)

	# 3. Geometric compass / target dial reticle (matching Metaphor SYSTEM screen)
	var center = Vector2(w * 0.75, h * 0.42)
	var reticle_col = Color(0.2, 0.5, 0.7, 0.05)
	var reticle_bright = Color(0.2, 0.6, 0.8, 0.09)

	# Concentric rings
	draw_arc(center, 280.0, 0, TAU, 72, reticle_col, 1.0)
	draw_arc(center, 180.0, 0, TAU, 64, reticle_col, 1.0)
	draw_arc(center, 110.0, 0, TAU, 48, reticle_bright, 1.2)
	draw_arc(center, 40.0, 0, TAU, 24, reticle_col, 1.0)

	# Crosshair axes
	draw_line(center - Vector2(320, 0), center + Vector2(320, 0), reticle_col, 1.0)
	draw_line(center - Vector2(0, 320), center + Vector2(0, 320), reticle_col, 1.0)
	# Diagonal tick marks
	for angle_deg in [30, 45, 60, 120, 135, 150, 210, 225, 240, 300, 315, 330]:
		var rad = deg_to_rad(angle_deg)
		var dir = Vector2(cos(rad), sin(rad))
		draw_line(center + dir * 100.0, center + dir * 120.0, reticle_bright, 1.0)

