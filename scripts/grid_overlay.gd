extends Node2D

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Tactical Grid Overlay
#  Renders tactical movement & attack reach tiles (Fire Emblem / Wuxia RPG style).
#  Handles mouse hover & left-click selection for movement and attacks.
# ──────────────────────────────────────────────

const TILE_SIZE = 64

enum Mode { NONE, MOVE, ATTACK }

var current_mode: Mode = Mode.NONE
var tilemap = null
var player = null
var enemy = null

# Data caches
var valid_move_tiles: Dictionary = {}    # Vector2i -> int (distance)
var valid_attack_tiles: Array = []       # Array of Vector2i
var hovered_tile: Vector2i = Vector2i(-9999, -9999)
var _custom_font: Font = null

signal move_tile_clicked(target_tile: Vector2i, distance: int)
signal attack_tile_clicked(target_tile: Vector2i)
signal right_mouse_clicked()
signal ally_clicked(ally_unit: Node2D)

# Colors
const COL_MOVE_FILL   = Color(0.18, 0.45, 0.95, 0.35)
const COL_MOVE_BORDER = Color(0.40, 0.75, 1.00, 0.85)

const COL_ATK_FILL    = Color(0.95, 0.30, 0.10, 0.35)
const COL_ATK_BORDER  = Color(1.00, 0.55, 0.20, 0.85)

const COL_ENEMY_FILL  = Color(0.95, 0.15, 0.15, 0.55)
const COL_ENEMY_BORDER= Color(1.00, 0.25, 0.25, 1.00)

const COL_HOVER       = Color(1.00, 0.90, 0.30, 0.95)

func _ready():
	z_index = 5  # Above tiles, below characters / UI
	if ResourceLoader.exists("res://assets/fonts/Cinzel-Bold.ttf"):
		_custom_font = load("res://assets/fonts/Cinzel-Bold.ttf")

func _process(_delta):
	var mpos = get_global_mouse_position()
	var tile = Vector2i(int(floor(mpos.x / TILE_SIZE)), int(floor(mpos.y / TILE_SIZE)))
	if tile != hovered_tile:
		hovered_tile = tile
		queue_redraw()

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		emit_signal("right_mouse_clicked")
		get_viewport().set_input_as_handled()
		return

	if current_mode == Mode.NONE:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if current_mode == Mode.ATTACK:
			if valid_attack_tiles.has(hovered_tile):
				emit_signal("attack_tile_clicked", hovered_tile)
				get_viewport().set_input_as_handled()
				return
		elif current_mode == Mode.MOVE:
			if valid_move_tiles.has(hovered_tile):
				emit_signal("move_tile_clicked", hovered_tile, valid_move_tiles[hovered_tile])
				get_viewport().set_input_as_handled()
				return

		# Check if player clicked directly on an allied squadmate to switch control
		var clicked_ally = get_ally_at_tile(hovered_tile)
		if clicked_ally != null:
			emit_signal("ally_clicked", clicked_ally)
			get_viewport().set_input_as_handled()
			return

func get_ally_at_tile(tile: Vector2i) -> Node2D:
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(p) and ("hp" not in p or p.hp > 0):
				var pt = Vector2i(int(floor(p.position.x / TILE_SIZE)), int(floor(p.position.y / TILE_SIZE)))
				if pt == tile:
					return p
	return null

const ARENA_MIN = Vector2i(0, 0)
const ARENA_MAX = Vector2i(17, 9)  # 18 columns (0..17) and 10 rows (0..9)

func is_tile_in_arena(t: Vector2i) -> bool:
	return t.x >= ARENA_MIN.x and t.x <= ARENA_MAX.x and t.y >= ARENA_MIN.y and t.y <= ARENA_MAX.y

# ──────────────────────────────────────────────
#  SHOW MOVEMENT GRID
# ──────────────────────────────────────────────

func show_move_grid(p_pos: Vector2, moves_remaining: int):
	current_mode = Mode.MOVE
	valid_move_tiles.clear()
	valid_attack_tiles.clear()

	var start_tile = Vector2i(int(floor(p_pos.x / TILE_SIZE)), int(floor(p_pos.y / TILE_SIZE)))

	# Collect all occupied tiles of other combatants (allies & enemies)
	var occupied_tiles: Array = []
	if is_inside_tree():
		for c in get_tree().get_nodes_in_group("combatants"):
			if is_instance_valid(c) and ("hp" not in c or c.hp > 0):
				var ct = Vector2i(int(floor(c.position.x / TILE_SIZE)), int(floor(c.position.y / TILE_SIZE)))
				if ct != start_tile:
					occupied_tiles.append(ct)
	if occupied_tiles.is_empty() and enemy and is_instance_valid(enemy):
		occupied_tiles.append(Vector2i(int(floor(enemy.position.x / TILE_SIZE)), int(floor(enemy.position.y / TILE_SIZE))))

	# Flood-fill BFS to calculate real movement distances up to moves_remaining
	var queue = [{ "tile": start_tile, "dist": 0 }]
	var visited = { start_tile: 0 }

	while not queue.is_empty():
		var current = queue.pop_front()
		var cur_tile = current["tile"]
		var cur_dist = current["dist"]

		if cur_dist > 0:
			valid_move_tiles[cur_tile] = cur_dist

		if cur_dist < moves_remaining:
			for dir in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				var next_tile = cur_tile + dir
				# Cannot walk onto another combatant
				if next_tile in occupied_tiles:
					continue
				# Check if tile is inside the arena
				if not is_tile_in_arena(next_tile):
					continue

				if not visited.has(next_tile) or visited[next_tile] > cur_dist + 1:
					visited[next_tile] = cur_dist + 1
					queue.append({ "tile": next_tile, "dist": cur_dist + 1 })

	queue_redraw()

# ──────────────────────────────────────────────
#  SHOW ATTACK GRID
# ──────────────────────────────────────────────

func show_attack_grid(p_pos: Vector2, ability_range: int, shape: String = "cardinal", facing_dir: Vector2i = Vector2i.ZERO):
	current_mode = Mode.ATTACK
	valid_move_tiles.clear()
	valid_attack_tiles.clear()

	var start_tile = Vector2i(int(floor(p_pos.x / TILE_SIZE)), int(floor(p_pos.y / TILE_SIZE)))

	if shape == "linear_front":
		var f_dir = facing_dir if facing_dir != Vector2i.ZERO else Vector2i(1, 0)
		for d in range(1, ability_range + 1):
			var t = start_tile + f_dir * d
			if is_tile_in_arena(t):
				valid_attack_tiles.append(t)
	elif shape == "radial":
		for dx in range(-ability_range, ability_range + 1):
			for dy in range(-ability_range, ability_range + 1):
				var dist = abs(dx) + abs(dy)
				if dist > 0 and dist <= ability_range:
					var t = start_tile + Vector2i(dx, dy)
					if is_tile_in_arena(t):
						valid_attack_tiles.append(t)
	else:
		# "cardinal" (Standard): Front, Back, Left, Right — NO DIAGONALS!
		var directions = [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for dir in directions:
			for d in range(1, ability_range + 1):
				var t = start_tile + dir * d
				if is_tile_in_arena(t):
					valid_attack_tiles.append(t)

	queue_redraw()

func clear_grid():
	current_mode = Mode.NONE
	valid_move_tiles.clear()
	valid_attack_tiles.clear()
	queue_redraw()

# ──────────────────────────────────────────────
#  DRAWING
# ──────────────────────────────────────────────

func _draw():
	var font = _custom_font if _custom_font else ThemeDB.fallback_font

	if current_mode == Mode.MOVE:
		for tile in valid_move_tiles.keys():
			var dist = valid_move_tiles[tile]
			var rect = Rect2(tile.x * TILE_SIZE + 2, tile.y * TILE_SIZE + 2, TILE_SIZE - 4, TILE_SIZE - 4)
			# Fill & Border
			draw_rect(rect, COL_MOVE_FILL, true)
			draw_rect(rect, COL_MOVE_BORDER, false, 1.5)
			_draw_tactical_corners(rect, COL_MOVE_BORDER, 6.0, 1.5)

			# Distance badge text
			if font:
				var text = str(dist)
				var text_pos = Vector2(tile.x * TILE_SIZE + (TILE_SIZE / 2.0) - 3, tile.y * TILE_SIZE + (TILE_SIZE / 2.0) + 5)
				draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, 14, Color(1, 1, 1, 0.9))

	elif current_mode == Mode.ATTACK:
		var enemy_tiles: Array = []
		if is_inside_tree():
			for e in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(e) and ("hp" not in e or e.hp > 0):
					enemy_tiles.append(Vector2i(int(floor(e.position.x / TILE_SIZE)), int(floor(e.position.y / TILE_SIZE))))
		if enemy_tiles.is_empty() and enemy and is_instance_valid(enemy):
			enemy_tiles.append(Vector2i(int(floor(enemy.position.x / TILE_SIZE)), int(floor(enemy.position.y / TILE_SIZE))))

		for tile in valid_attack_tiles:
			var rect = Rect2(tile.x * TILE_SIZE + 2, tile.y * TILE_SIZE + 2, TILE_SIZE - 4, TILE_SIZE - 4)
			var is_enemy = (tile in enemy_tiles)

			# Translucent attack reach tile fill & border
			draw_rect(rect, COL_ATK_FILL, true)
			draw_rect(rect, COL_ATK_BORDER, false, 1.5)

			if is_enemy:
				# Bright red tactical corner brackets on all enemies in range
				_draw_tactical_corners(rect, Color(1.0, 0.2, 0.2, 1.0), 12.0, 2.5)
			else:
				_draw_tactical_corners(rect, COL_ATK_BORDER, 6.0, 1.5)

	# Hover Cursor Bracket
	if current_mode != Mode.NONE:
		var is_valid = (current_mode == Mode.MOVE and valid_move_tiles.has(hovered_tile)) or \
					   (current_mode == Mode.ATTACK and valid_attack_tiles.has(hovered_tile))
		if is_valid:
			var h_rect = Rect2(hovered_tile.x * TILE_SIZE + 1, hovered_tile.y * TILE_SIZE + 1, TILE_SIZE - 2, TILE_SIZE - 2)
			_draw_tactical_corners(h_rect, COL_HOVER, 8.0, 2.0)

func _draw_tactical_corners(rect: Rect2, color: Color, length: float = 6.0, width: float = 1.5):
	# Top-Left
	draw_line(rect.position, rect.position + Vector2(length, 0), color, width)
	draw_line(rect.position, rect.position + Vector2(0, length), color, width)
	# Top-Right
	var top_right = rect.position + Vector2(rect.size.x, 0)
	draw_line(top_right, top_right + Vector2(-length, 0), color, width)
	draw_line(top_right, top_right + Vector2(0, length), color, width)
	# Bottom-Left
	var bl = rect.position + Vector2(0, rect.size.y)
	draw_line(bl, bl + Vector2(length, 0), color, width)
	draw_line(bl, bl + Vector2(0, -length), color, width)
	# Bottom-Right
	var br = rect.position + rect.size
	draw_line(br, br + Vector2(-length, 0), color, width)
	draw_line(br, br + Vector2(0, -length), color, width)
