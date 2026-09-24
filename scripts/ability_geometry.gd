extends RefCounted
class_name AbilityGeometry

const TILE_SIZE := 64
const MIN_TILE := Vector2i(0, 0)
const MAX_TILE := Vector2i(17, 9)

static func shape_for(skill_name: String, declared_shape: String) -> String:
	var name := skill_name.to_lower()
	if "breath" in name: return "cone"
	if "slash" in name or "sweep" in name: return "wide_slash"
	if "pierce" in name or "lance" in name or "spear" in name or "beam" in name or " ray" in name: return "linear_front"
	return declared_shape

static func effective_reach(form_name: String, declared_reach: int) -> int:
	# A spear or beam must actually be able to reach its preferred long band.
	var name := form_name.to_lower()
	for word in ["pierce", "lance", "spear", "beam", " ray", "bolt", "needle"]:
		if word in name: return maxi(4, declared_reach)
	return declared_reach

static func preferred_band(form_name: String, reach: int) -> String:
	var name := form_name.to_lower()
	for word in ["punch", "fist", "palm", "touch", "strike", "skin", "anchor"]:
		if word in name: return "close"
	for word in ["pierce", "lance", "spear", "beam", " ray", "bolt", "needle", "shard"]:
		if word in name: return "long" if reach >= 4 else "mid"
	if reach <= 1: return "close"
	if reach >= 4: return "long"
	return "mid"

static func range_multiplier(band: String, distance: int) -> float:
	# Shared by damage and AI planning: +25% in the sweet spot, reduced power
	# when casting a ranged form in a cramped lane or a close form at distance.
	match band:
		"close": return 1.25 if distance == 1 else 0.85
		"mid": return 1.25 if distance >= 2 and distance <= 3 else 0.85
		"long": return 1.25 if distance >= 4 else 0.80
	return 1.0

static func ideal_range_label(band: String, reach: int = 0) -> String:
	match band:
		"close": return "1 tile"
		"mid": return "2 tiles" if reach == 2 else "2-3 tiles"
		"long": return "4 tiles" if reach == 4 else ("4-%d tiles" % reach if reach > 4 else "4+ tiles")
	return "any range"

static func direction_to(from_tile: Vector2i, to_tile: Vector2i) -> Vector2i:
	var delta := to_tile - from_tile
	if abs(delta.x) >= abs(delta.y): return Vector2i.RIGHT if delta.x >= 0 else Vector2i.LEFT
	return Vector2i.DOWN if delta.y >= 0 else Vector2i.UP

static func tiles(origin: Vector2i, facing: Vector2i, reach: int, shape: String) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	var forward := facing if facing != Vector2i.ZERO else Vector2i.RIGHT
	var side := Vector2i(-forward.y, forward.x)
	match shape:
		"radial":
			for dx in range(-reach, reach + 1):
				for dy in range(-reach, reach + 1):
					if abs(dx) + abs(dy) > 0 and abs(dx) + abs(dy) <= reach:
						_add(result, origin + Vector2i(dx, dy))
		"cone":
			for d in range(1, reach + 1):
				var half_width := mini(d - 1, 2) # 1, then 3, then 5 tiles.
				for lateral in range(-half_width, half_width + 1):
					_add(result, origin + forward * d + side * lateral)
		"wide_slash":
			for d in range(1, mini(reach, 4) + 1):
				for lateral in range(-1, 3):
					_add(result, origin + forward * d + side * lateral)
		"linear_front":
			for d in range(1, reach + 1): _add(result, origin + forward * d)
		_:
			for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
				for d in range(1, reach + 1): _add(result, origin + direction * d)
	return result

static func is_multi_target(shape: String, form_name: String = "") -> bool:
	var name := form_name.to_lower()
	if "needle" in name or "shot" in name: return false
	return shape in ["cone", "wide_slash", "linear_front", "radial"]

static func tile_of(world_position: Vector2) -> Vector2i:
	return Vector2i(int(floor(world_position.x / TILE_SIZE)), int(floor(world_position.y / TILE_SIZE)))

static func _add(result: Array[Vector2i], tile: Vector2i) -> void:
	if tile.x >= MIN_TILE.x and tile.x <= MAX_TILE.x and tile.y >= MIN_TILE.y and tile.y <= MAX_TILE.y and not result.has(tile):
		result.append(tile)
