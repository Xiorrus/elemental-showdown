extends Node2D
class_name BattleTerrain

const AbilityGeometryScript = preload("res://scripts/ability_geometry.gd")
const TILE_SIZE := 64
const COLORS := {
	"fire": Color(1.0, 0.30, 0.05, 0.55),
	"earth_wall": Color(0.55, 0.42, 0.25, 0.85),
	"ice": Color(0.46, 0.81, 1.0, 0.48),
	"smoke": Color(0.55, 0.56, 0.64, 0.55),
	"puddle": Color(0.20, 0.50, 0.90, 0.45)
}

# ── LAYERED TERRAIN DATA ─────────────────────────────────────────────────────
# Layer 1: Structures (e.g. earth_wall) — has HP, blocks movement, line of sight, push
var structures: Dictionary = {} # Vector2i -> { "kind": "earth_wall", "hp": int, "max_hp": int, "duration": -1 }

# Layer 2: Surfaces (fire, ice, puddle) — effects movement cost & damage
var surfaces: Dictionary = {}   # Vector2i -> { "kind": String, "duration": int, "hp": 0 }

# Layer 3: Obscurants (smoke) — reduces ranged accuracy through tile
var obscurants: Dictionary = {} # Vector2i -> { "kind": "smoke", "duration": int }

# Legacy master map for backwards compatibility: Vector2i -> {kind, duration, hp}
var hazards: Dictionary = {}

# Arena preset configuration
var arena_preset: String = "standard"
var ring_out_enabled: bool = false

const ARENA_PRESETS := {
	"standard": {
		"name": "Colosseum Standard",
		"desc": "Regulation championship arena with boundary shock walls.",
		"ring_out": false
	},
	"ring_out": {
		"name": "Sky Ring",
		"desc": "Open floating platform where pushing enemies beyond the perimeter results in Ring Out.",
		"ring_out": true
	},
	"hazard_pillars": {
		"name": "Stone Pillars",
		"desc": "Neutral destructible earth pillars strategically placed in midfield.",
		"ring_out": false
	}
}

func load_arena_preset(preset_key: String) -> void:
	arena_preset = preset_key
	var conf: Dictionary = ARENA_PRESETS.get(preset_key, ARENA_PRESETS["standard"])
	ring_out_enabled = conf.get("ring_out", false)
	if preset_key == "hazard_pillars":
		var pillars: Array[Vector2i] = [Vector2i(6, 4), Vector2i(6, 5), Vector2i(11, 4), Vector2i(11, 5)]
		for p in pillars:
			structures[p] = {"kind": "earth_wall", "hp": 45, "max_hp": 45, "duration": -1}
			hazards[p] = {"kind": "earth_wall", "hp": 45, "duration": -1}
	queue_redraw()

func is_blocked(tile: Vector2i) -> bool:
	if structures.has(tile):
		return true
	if surfaces.has(tile) and surfaces[tile]["kind"] == "fire":
		return true
	return hazards.has(tile) and str(hazards[tile]["kind"]) in ["fire", "earth_wall"]

func move_cost(tile: Vector2i) -> int:
	if surfaces.has(tile) and surfaces[tile]["kind"] == "ice":
		return 2
	return 2 if hazards.has(tile) and hazards[tile]["kind"] == "ice" else 1

func accuracy_penalty(from_tile: Vector2i, to_tile: Vector2i) -> int:
	for tile in _line_tiles(from_tile, to_tile):
		if obscurants.has(tile):
			return 25
		if hazards.has(tile) and hazards[tile]["kind"] == "smoke":
			return 25
	return 0

func blocks_line(from_tile: Vector2i, to_tile: Vector2i) -> bool:
	for tile in _line_tiles(from_tile, to_tile):
		if tile != to_tile and has_wall(tile):
			return true
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
	if structures.has(tile) and structures[tile]["kind"] == "earth_wall":
		return true
	return hazards.has(tile) and hazards[tile]["kind"] == "earth_wall"

func react_to_attack(element: String, tiles: Array[Vector2i], damage: int) -> void:
	for tile in tiles:
		# Layer 1: Structures (earth wall takes damage from any landed attack or collision)
		if structures.has(tile):
			var kind: String = structures[tile]["kind"]
			if kind == "earth_wall" and damage > 0:
				structures[tile]["hp"] -= damage
				if hazards.has(tile):
					hazards[tile]["hp"] = structures[tile]["hp"]
				if structures[tile]["hp"] <= 0:
					structures.erase(tile)
					hazards.erase(tile)

		# Layer 2: Surfaces
		if surfaces.has(tile):
			var s_kind: String = surfaces[tile]["kind"]
			if s_kind == "fire" and element in ["water", "ice"]:
				surfaces.erase(tile)
				hazards.erase(tile)
			elif s_kind == "ice" and element == "fire":
				surfaces.erase(tile)
				hazards.erase(tile)

		# Layer 3: Obscurants
		if obscurants.has(tile):
			if element == "air":
				obscurants.erase(tile)
				hazards.erase(tile)

		# Legacy fallback check (only for tiles in hazards dict not tracked by new layers)
		if hazards.has(tile) and not structures.has(tile) and not surfaces.has(tile) and not obscurants.has(tile):
			var h_kind: String = hazards[tile]["kind"]
			if h_kind == "fire" and element in ["water", "ice"]:
				hazards.erase(tile)
			elif h_kind == "ice" and element == "fire":
				hazards.erase(tile)
			elif h_kind == "smoke" and element == "air":
				hazards.erase(tile)
			elif h_kind == "earth_wall" and damage > 0:
				hazards[tile]["hp"] -= damage
				if hazards[tile]["hp"] <= 0:
					hazards.erase(tile)

	queue_redraw()

func place_from_skill(terrain_kind: String, origin: Vector2i, aimed_tile: Vector2i, reach: int, shape: String, duration: int = 2) -> void:
	if terrain_kind == "":
		return
	var direction: Vector2i = AbilityGeometryScript.direction_to(origin, aimed_tile)
	var tiles: Array[Vector2i] = []
	if terrain_kind == "earth_wall":
		tiles.append(aimed_tile)
	else:
		tiles = AbilityGeometryScript.tiles(origin, direction, reach, shape)

	for tile in tiles:
		if terrain_kind == "earth_wall":
			# Structure Layer
			if structures.has(tile):
				structures[tile]["hp"] = mini(100, int(structures[tile]["hp"]) + 30)
				hazards[tile]["hp"] = structures[tile]["hp"]
			else:
				structures[tile] = {"kind": "earth_wall", "hp": 45, "max_hp": 45, "duration": -1}
				hazards[tile] = {"kind": "earth_wall", "hp": 45, "duration": -1}
		elif terrain_kind in ["fire", "ice", "puddle"]:
			# Surface Layer
			# Fire and ice extinguish each other
			if surfaces.has(tile) and surfaces[tile]["kind"] == "fire" and terrain_kind == "ice":
				surfaces.erase(tile)
				hazards.erase(tile)
				continue
			if surfaces.has(tile) and surfaces[tile]["kind"] == "ice" and terrain_kind == "fire":
				surfaces.erase(tile)
				hazards.erase(tile)
				continue
			if hazards.has(tile) and hazards[tile]["kind"] == "fire" and terrain_kind == "ice":
				hazards.erase(tile)
				continue
			if hazards.has(tile) and hazards[tile]["kind"] == "ice" and terrain_kind == "fire":
				hazards.erase(tile)
				continue

			if surfaces.has(tile) and surfaces[tile]["kind"] == terrain_kind:
				surfaces[tile]["duration"] = mini(8, int(surfaces[tile]["duration"]) + duration)
				if hazards.has(tile):
					hazards[tile]["duration"] = surfaces[tile]["duration"]
			elif hazards.has(tile) and hazards[tile]["kind"] == terrain_kind:
				hazards[tile]["duration"] = mini(8, int(hazards[tile]["duration"]) + duration)
				surfaces[tile] = {"kind": terrain_kind, "duration": hazards[tile]["duration"], "hp": 0}
			else:
				surfaces[tile] = {"kind": terrain_kind, "duration": duration, "hp": 0}
				hazards[tile] = {"kind": terrain_kind, "duration": duration, "hp": 0}
		elif terrain_kind == "smoke":
			# Obscurant Layer
			if obscurants.has(tile):
				obscurants[tile]["duration"] = mini(8, int(obscurants[tile]["duration"]) + duration)
				if hazards.has(tile):
					hazards[tile]["duration"] = obscurants[tile]["duration"]
			else:
				obscurants[tile] = {"kind": "smoke", "duration": duration}
				hazards[tile] = {"kind": "smoke", "duration": duration, "hp": 0}

	queue_redraw()

func tick_round() -> void:
	var expired_surfaces: Array[Vector2i] = []
	var expired_obscurants: Array[Vector2i] = []
	var expired_hazards: Array[Vector2i] = []

	# 1. Surface layer tick (Fire damage & durations)
	for tile in surfaces.keys():
		var s = surfaces[tile]
		if s["kind"] == "fire":
			for fighter in get_tree().get_nodes_in_group("combatants"):
				if is_instance_valid(fighter) and ("hp" not in fighter or fighter.hp > 0) and AbilityGeometryScript.tile_of(fighter.position) == tile:
					fighter.take_damage(6)
		if int(s.get("duration", 0)) > 0:
			s["duration"] -= 1
			if s["duration"] <= 0:
				expired_surfaces.append(tile)

	for tile in expired_surfaces:
		surfaces.erase(tile)
		hazards.erase(tile)

	# 2. Obscurant layer tick
	for tile in obscurants.keys():
		var o = obscurants[tile]
		if int(o.get("duration", 0)) > 0:
			o["duration"] -= 1
			if o["duration"] <= 0:
				expired_obscurants.append(tile)

	for tile in expired_obscurants:
		obscurants.erase(tile)
		hazards.erase(tile)

	# 3. Legacy hazards sync
	for tile in hazards.keys():
		var state: Dictionary = hazards[tile]
		if state["kind"] == "fire" and not surfaces.has(tile):
			for fighter in get_tree().get_nodes_in_group("combatants"):
				if is_instance_valid(fighter) and ("hp" not in fighter or fighter.hp > 0) and AbilityGeometryScript.tile_of(fighter.position) == tile:
					fighter.take_damage(6)
		if int(state.get("duration", 0)) > 0:
			state["duration"] -= 1
			if state["duration"] <= 0:
				expired_hazards.append(tile)

	for tile in expired_hazards:
		hazards.erase(tile)

	queue_redraw()

func _draw() -> void:
	for tile in hazards:
		var kind: String = str(hazards[tile].get("kind", ""))
		if not COLORS.has(kind):
			continue
		var rect := Rect2(tile.x * TILE_SIZE + 3, tile.y * TILE_SIZE + 3, TILE_SIZE - 6, TILE_SIZE - 6)
		draw_rect(rect, COLORS[kind], true)
		draw_rect(rect, COLORS[kind].lightened(0.35), false, 2.0)
		if kind == "earth_wall":
			draw_line(rect.position + Vector2(5, 8), rect.end - Vector2(5, 8), Color(0.95, 0.8, 0.5, 0.8), 2.0)
			# Wall durability line
			var hp: int = int(hazards[tile].get("hp", 45))
			var max_hp := 45.0
			var ratio: float = clamp(float(hp) / max_hp, 0.0, 1.0)
			draw_line(rect.position + Vector2(4, rect.size.y - 4), rect.position + Vector2(4 + (rect.size.x - 8) * ratio, rect.size.y - 4), Color(0.2, 0.9, 0.3, 0.9), 2.5)
