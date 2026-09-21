# tactical_workbench_tile.gd
# Pixel-faithful interactive tile for the 18x10 arena deployment matrix.
# Reflects in-match combat appearance: real character walk sprites facing combat directions,
# tactical corner brackets, and drag-and-drop / click-to-deploy support.
extends Button

signal tile_clicked(coord: Vector2i)
signal ally_dropped(ally_name: String, target_coord: Vector2i)

var tile_coord: Vector2i = Vector2i(-1, -1)
var is_player_zone: bool = false
var ally_name: String = ""
var ally_element: String = ""
var is_selected: bool = false

var is_enemy: bool = false
var enemy_name: String = ""
var enemy_element: String = ""

var is_midfield: bool = false
var hazard_label: String = ""

var _sprite_rect: TextureRect = null
var _badge_lbl: Label = null

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(34, 34)
	flat = true
	focus_mode = Control.FOCUS_NONE

	# Clear default button theme borders/backgrounds to let arena floor show through
	var empty_sb = StyleBoxEmpty.new()
	add_theme_stylebox_override("normal", empty_sb)
	add_theme_stylebox_override("hover", empty_sb)
	add_theme_stylebox_override("pressed", empty_sb)
	add_theme_stylebox_override("disabled", empty_sb)

func setup_ally(p_name: String, p_elem: String, p_sel: bool):
	is_player_zone = true
	is_enemy = false
	ally_name = p_name
	ally_element = p_elem if p_elem != "" else "fire"
	is_selected = p_sel

	tooltip_text = "%s (%s)%s\nArena Tile: (%d, %d)\nClick to select • Drag to reposition" % [
		ally_name.capitalize(),
		ally_element.capitalize(),
		" [Selected]" if is_selected else "",
		tile_coord.x, tile_coord.y
	]
	_setup_sprite(ally_element, 4) # Frame 4: Facing Right towards enemies
	_setup_badge(ally_name.capitalize().substr(0, 3), Color(1.2, 1.0, 0.4) if is_selected else Color(0.4, 0.9, 1.0))
	queue_redraw()

func setup_empty_player_zone(p_coord: Vector2i):
	tile_coord = p_coord
	is_player_zone = true
	is_enemy = false
	ally_name = ""
	ally_element = ""
	is_selected = false

	tooltip_text = "Deployable Arena Square (%d, %d)\nClick or drop squadmate here" % [p_coord.x, p_coord.y]
	if _sprite_rect and is_instance_valid(_sprite_rect):
		_sprite_rect.texture = null
	if _badge_lbl and is_instance_valid(_badge_lbl):
		_badge_lbl.text = ""
	queue_redraw()

func setup_enemy(p_name: String, p_elem: String):
	is_player_zone = false
	is_enemy = true
	enemy_name = p_name
	enemy_element = p_elem if p_elem != "" else "water"
	ally_name = ""
	disabled = true

	tooltip_text = "%s (%s Rival)\nEnemy Formation: (%d, %d)" % [
		enemy_name.capitalize(),
		enemy_element.capitalize(),
		tile_coord.x, tile_coord.y
	]
	_setup_sprite(enemy_element, 8) # Frame 8: Facing Left towards players
	_setup_badge(enemy_name.capitalize().substr(0, 3), Color(1.0, 0.35, 0.35))
	queue_redraw()

func setup_neutral_or_hazard(p_coord: Vector2i, p_hazard: String = ""):
	tile_coord = p_coord
	is_player_zone = false
	is_enemy = false
	is_midfield = (p_coord.x == 6)
	hazard_label = p_hazard
	disabled = true

	if hazard_label != "":
		tooltip_text = "%s (%d, %d)" % [hazard_label, p_coord.x, p_coord.y]
	else:
		tooltip_text = "Arena Square (%d, %d)" % [p_coord.x, p_coord.y]

	if _sprite_rect and is_instance_valid(_sprite_rect):
		_sprite_rect.texture = null
	if _badge_lbl and is_instance_valid(_badge_lbl):
		_badge_lbl.text = ""
	queue_redraw()

func _setup_sprite(elem: String, frame_idx: int):
	if _sprite_rect == null:
		_sprite_rect = TextureRect.new()
		_sprite_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_sprite_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		_sprite_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		_sprite_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_sprite_rect)

	var tex_path = "res://assets/%s_walk.png" % elem.to_lower()
	if ResourceLoader.exists(tex_path):
		var atlas = AtlasTexture.new()
		atlas.atlas = load(tex_path)
		var row = frame_idx / 4
		var col = frame_idx % 4
		atlas.region = Rect2(col * 128, row * 128, 128, 128)
		_sprite_rect.texture = atlas

func _setup_badge(text: String, col: Color):
	if _badge_lbl == null:
		_badge_lbl = Label.new()
		_badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_badge_lbl.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
			_badge_lbl.add_theme_font_override("font", load("res://assets/fonts/Cinzel-Bold.ttf"))
		_badge_lbl.add_theme_font_size_override("font_size", 7)
		_badge_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.95))
		_badge_lbl.add_theme_constant_override("shadow_offset_x", 1)
		_badge_lbl.add_theme_constant_override("shadow_offset_y", 1)
		add_child(_badge_lbl)

	_badge_lbl.text = text
	_badge_lbl.modulate = col

func _pressed():
	tile_clicked.emit(tile_coord)

func _draw():
	var rect = Rect2(Vector2.ZERO, size)

	# 1. Subtle arena tile grid outline
	draw_rect(rect, Color(0.20, 0.26, 0.38, 0.20), false, 0.5)

	# 2. Player Deployable Zone
	if is_player_zone:
		if ally_name != "":
			if is_selected:
				# Selected unit: Radiant Antique Gold frame and warm fill
				draw_rect(rect, Color(0.95, 0.78, 0.25, 0.22), true)
				draw_rect(rect, Color(1.0, 0.85, 0.35, 0.95), false, 1.5)
			else:
				# Deployed squadmate: Refined ethereal blue border with soft fill
				draw_rect(rect, Color(0.22, 0.50, 0.85, 0.18), true)
				draw_rect(rect, Color(0.40, 0.75, 1.00, 0.80), false, 1.2)
		else:
			# Open deploy tile: subtle elegant corner markers in antique gold tint
			_draw_corners(rect, Color(0.85, 0.75, 0.40, 0.40), 4.0, 1.0)

	# 3. Enemy Target Zone
	elif is_enemy:
		# Deep Ruby tactical border and fill
		draw_rect(rect, Color(0.85, 0.20, 0.20, 0.20), true)
		draw_rect(rect, Color(0.95, 0.30, 0.30, 0.85), false, 1.4)

	# 4. Midfield / Hazard
	elif is_midfield:
		if hazard_label != "":
			_draw_corners(rect, Color(1.0, 0.8, 0.2, 0.6), 4.0, 1.0)
		else:
			# Neutral midfield divider line on the right edge
			draw_line(Vector2(rect.size.x, 0), Vector2(rect.size.x, rect.size.y), Color(0.4, 0.7, 0.9, 0.3), 1.0)

	# 5. Mouse Hover highlight (for player deployable tiles)
	if is_player_zone and is_hovered():
		draw_rect(rect, Color(1.0, 0.88, 0.40, 0.25), true)
		draw_rect(rect, Color(1.0, 0.92, 0.50, 0.90), false, 1.5)

func _draw_corners(r: Rect2, color: Color, length: float, width: float):
	# Top-Left
	draw_line(r.position, r.position + Vector2(length, 0), color, width)
	draw_line(r.position, r.position + Vector2(0, length), color, width)
	# Top-Right
	var tr = r.position + Vector2(r.size.x, 0)
	draw_line(tr, tr + Vector2(-length, 0), color, width)
	draw_line(tr, tr + Vector2(0, length), color, width)
	# Bottom-Left
	var bl = r.position + Vector2(0, r.size.y)
	draw_line(bl, bl + Vector2(length, 0), color, width)
	draw_line(bl, bl + Vector2(0, -length), color, width)
	# Bottom-Right
	var br = r.position + r.size
	draw_line(br, br + Vector2(-length, 0), color, width)
	draw_line(br, br + Vector2(0, -length), color, width)

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not is_player_zone or ally_name == "":
		return null

	var preview_panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.08, 0.12, 0.20, 0.95)
	sb.border_color = Color(1.2, 1.0, 0.3, 1.0)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 6
	sb.content_margin_right = 6
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	preview_panel.add_theme_stylebox_override("panel", sb)

	var hb = HBoxContainer.new()
	hb.add_theme_constant_override("separation", 4)
	preview_panel.add_child(hb)

	if ally_element != "":
		var spr = TextureRect.new()
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/%s_walk.png" % ally_element.to_lower())
		atlas.region = Rect2(0, 128, 128, 128) # Frame 4: Right
		spr.texture = atlas
		spr.custom_minimum_size = Vector2(22, 22)
		spr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		spr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hb.add_child(spr)

	var preview_lbl = Label.new()
	preview_lbl.text = "%s" % ally_name.capitalize()
	if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		preview_lbl.add_theme_font_override("font", load("res://assets/fonts/Cinzel-Bold.ttf"))
	preview_lbl.add_theme_font_size_override("font_size", 9)
	preview_lbl.modulate = Color(1.2, 1.0, 0.4)
	hb.add_child(preview_lbl)

	set_drag_preview(preview_panel)
	return {
		"type": "squadmate",
		"name": ally_name,
		"from_tile": tile_coord
	}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not is_player_zone:
		return false
	return (data is Dictionary) and data.get("type") == "squadmate" and data.has("name")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if is_player_zone and (data is Dictionary) and data.get("type") == "squadmate":
		ally_dropped.emit(str(data.get("name", "")), tile_coord)
