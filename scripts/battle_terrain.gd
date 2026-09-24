extends Node2D
class_name BattleTerrain

const AbilityGeometryScript = preload("res://scripts/ability_geometry.gd")
const TILE_SIZE := 64
const COLORS := {
	"fire": Color(1.0, 0.30, 0.05, 0.55),
	"earth_wall": Color(0.55, 0.42, 0.25, 0.85),
	"ice": Color(0.46, 0.81, 1.0, 0.48),
	"smoke": Color(0.55, 0.56, 0.64, 0.55),
}

# Vector2i -> {kind, duration, hp}. Duration -1 means permanent.
var hazards: Dictionary = {}

func is_blocked(tile: Vector2i) -> bool:
	return hazards.has(tile) and str(hazards[tile]["kind"]) in ["fire", "earth_wall"]

func move_cost(tile: Vector2i) -> int:
	return 2 if hazards.has(tile) and hazards[tile]["kind"] == "ice" else 1

func accuracy_penalty(from_tile: Vector2i, to_tile: Vector2i) -> int:
	for tile in _line_tiles(from_tile, to_tile):
		if hazards.has(tile) and hazards[tile]["kind"] == "smoke": return 25
	return 0

func blocks_line(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	for tile in _line_tiles(from_tile, to_tile):
		if tile != to_tile and has_wall(tile): return true
	return false

func _line_tiles(from_tile: Vector2i, to_tile: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var x := from_tile.x
	var y := from_tile.y
	var dx: int = absi(to_tile.x - x)
	var dy: int = absi(to_tile.y - y)
	var sx := 1 if x < to_tile.x else -1
	var sy := 1 if y < to_tile.y else -1
	var error: int = dx - dy
	while true:
		result.append(Vector2i(x, y))
		if x == to_tile.x and y == to_tile.y: break
		var doubled: int = error * 2
		if doubled > -dy:
			error -= dy
			x += sx
		if doubled < dx:
			error += dx
			y += sy
	return result

func has_wall(tile: Vector2i) -> bool:
	return hazards.has(tile) and hazards[tile]["kind"] == "earth_wall"

func react_to_attack(element: String, tiles: Array[Vector2i], damage: int) -> void:
	for tile in tiles:
		if not hazards.has(tile): continue
		var kind: String = hazards[tile]["kind"]
		if kind == "fire" and element in ["water", "ice"]:
			hazards.erase(tile)
		elif kind == "ice" and element == "fire":
			hazards.erase(tile)
		elif kind == "smoke" and element == "air":
			hazards.erase(tile)
		elif kind == "earth_wall" and damage > 0:
			hazards[tile]["hp"] -= damage
			if hazards[tile]["hp"] <= 0: hazards.erase(tile)
	queue_redraw()

func place_from_skill(terrain_kind: String, origin: Vector2i, aimed_tile: Vector2i, reach: int, shape: String, duration: int = 2) -> void:
	if terrain_kind == "": return
	var direction: Vector2i = AbilityGeometryScript.direction_to(origin, aimed_tile)
	var tiles: Array[Vector2i] = []
	if terrain_kind == "earth_wall":
		tiles.append(aimed_tile)
	else:
		tiles = AbilityGeometryScript.tiles(origin, direction, reach, shape)
	var kind := terrain_kind
	for tile in tiles:
		# Fire and ice oppose one another. Water/ice attacks also quench in react_to_attack.
		if hazards.has(tile) and hazards[tile]["kind"] == "fire" and kind == "ice":
			hazards.erase(tile)
			continue
		if hazards.has(tile) and hazards[tile]["kind"] == "ice" and kind == "fire": hazards.erase(tile)
		if hazards.has(tile) and hazards[tile]["kind"] == kind:
			if kind == "earth_wall": hazards[tile]["hp"] = mini(100, int(hazards[tile]["hp"]) + 30)
			else: hazards[tile]["duration"] = mini(8, int(hazards[tile]["duration"]) + duration)
		else:
			hazards[tile] = {"kind": kind, "duration": -1 if kind == "earth_wall" else duration, "hp": 45 if kind == "earth_wall" else 0}
	queue_redraw()

func tick_round() -> void:
	var expired: Array[Vector2i] = []
	for tile in hazards.keys():
		var state: Dictionary = hazards[tile]
		if state["kind"] == "fire":
			for fighter in get_tree().get_nodes_in_group("combatants"):
				if is_instance_valid(fighter) and ("hp" not in fighter or fighter.hp > 0) and AbilityGeometryScript.tile_of(fighter.position) == tile:
					fighter.take_damage(6)
		if int(state["duration"]) > 0:
			state["duration"] -= 1
			if state["duration"] == 0: expired.append(tile)
	for tile in expired: hazards.erase(tile)
	queue_redraw()

func _draw() -> void:
	for tile in hazards:
		var kind: String = hazards[tile]["kind"]
		var rect := Rect2(tile.x * TILE_SIZE + 3, tile.y * TILE_SIZE + 3, TILE_SIZE - 6, TILE_SIZE - 6)
		draw_rect(rect, COLORS[kind], true)
		draw_rect(rect, COLORS[kind].lightened(0.35), false, 2.0)
		if kind == "earth_wall":
			draw_line(rect.position + Vector2(5, 8), rect.end - Vector2(5, 8), Color(0.95, 0.8, 0.5, 0.8), 2.0)
