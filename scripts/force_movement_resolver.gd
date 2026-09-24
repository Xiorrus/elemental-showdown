class_name ForceMovementResolver
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# ForceMovementResolver
# Shared domain resolver for tile-by-tile forced movement, boundary checks,
# fighter-to-fighter collisions, earth wall collisions, and collision shock.
# ─────────────────────────────────────────────────────────────────────────────

const TILE_SIZE := 64
const ARENA_WIDTH_TILES := 18
const ARENA_HEIGHT_TILES := 10
const BASE_COLLISION_DAMAGE := 12

static func get_tile_of(pos: Vector2) -> Vector2i:
	return Vector2i(int(floor(pos.x / TILE_SIZE)), int(floor(pos.y / TILE_SIZE)))

static func get_world_pos_of(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2, tile.y * TILE_SIZE + TILE_SIZE / 2)

## Calculates tile-by-tile displacement without mutating state or triggering animations.
static func resolve_push(
	target_node: Node2D,
	source_pos: Vector2,
	distance_tiles: int = 1,
	tree: SceneTree = null,
	terrain: Node2D = null,
	collision_damage: int = BASE_COLLISION_DAMAGE,
	ring_out_enabled: bool = false
) -> Dictionary:
	var result := {
		"target_node": target_node,
		"start_tile": Vector2i.ZERO,
		"final_tile": Vector2i.ZERO,
		"final_position": Vector2.ZERO,
		"traversed_tiles": [] as Array[Vector2i],
		"direction": Vector2i.ZERO,
		"collided": false,
		"collision_type": "none", # "boundary", "fighter", "structure", "ring_out", "none"
		"collided_node": null,
		"collided_tile": Vector2i(-1, -1),
		"collision_damage": collision_damage,
		"moved_tiles": 0,
		"ring_out": false,
		"interrupted": false
	}

	if target_node == null or not is_instance_valid(target_node):
		return result

	var start_tile = get_tile_of(target_node.position)
	result["start_tile"] = start_tile
	result["final_tile"] = start_tile
	result["final_position"] = target_node.position

	if distance_tiles <= 0:
		return result

	var diff: Vector2 = target_node.position - source_pos
	var dir_x: int = 0
	var dir_y: int = 0
	if abs(diff.x) >= abs(diff.y):
		dir_x = 1 if diff.x >= 0 else -1
	else:
		dir_y = 1 if diff.y >= 0 else -1

	# If source and target are on exact same point, push right by default
	if dir_x == 0 and dir_y == 0:
		dir_x = 1

	var dir := Vector2i(dir_x, dir_y)
	result["direction"] = dir

	var cur_col: int = start_tile.x
	var cur_row: int = start_tile.y

	for step in range(distance_tiles):
		var next_col: int = cur_col + dir_x
		var next_row: int = cur_row + dir_y
		var next_tile := Vector2i(next_col, next_row)

		# 1. Boundary Check
		var hit_boundary = (next_col < 0 or next_col >= ARENA_WIDTH_TILES or next_row < 0 or next_row >= ARENA_HEIGHT_TILES)
		if hit_boundary:
			if ring_out_enabled:
				result["collided"] = true
				result["ring_out"] = true
				result["collision_type"] = "ring_out"
				result["collided_tile"] = next_tile
				result["interrupted"] = true
			else:
				result["collided"] = true
				result["collision_type"] = "boundary"
				result["collided_tile"] = next_tile
				result["interrupted"] = true
			break

		# 2. Structure / Earth Wall Check
		if terrain != null and is_instance_valid(terrain):
			if terrain.has_method("has_wall") and terrain.has_wall(next_tile):
				result["collided"] = true
				result["collision_type"] = "structure"
				result["collided_tile"] = next_tile
				result["interrupted"] = true
				break

		# 3. Fighter / Combatant Occupancy Check
		var hit_fighter: Node2D = null
		if tree != null:
			for group in ["players", "enemies", "combatants"]:
				for node in tree.get_nodes_in_group(group):
					if is_instance_valid(node) and node != target_node and ("hp" not in node or node.hp > 0):
						var node_tile = get_tile_of(node.position)
						if node_tile == next_tile:
							hit_fighter = node
							break
				if hit_fighter != null:
					break

		if hit_fighter != null:
			result["collided"] = true
			result["collision_type"] = "fighter"
			result["collided_node"] = hit_fighter
			result["collided_tile"] = next_tile
			result["interrupted"] = true
			break

		# Clear tile: step forward
		cur_col = next_col
		cur_row = next_row
		result["traversed_tiles"].append(next_tile)
		result["moved_tiles"] += 1

	result["final_tile"] = Vector2i(cur_col, cur_row)
	result["final_position"] = get_world_pos_of(result["final_tile"])
	if result["moved_tiles"] > 0:
		result["interrupted"] = true

	return result

## Applies the resolved push physically to the arena nodes, triggering damage & tweens.
static func apply_resolved_push(push_result: Dictionary, ui: Node = null, battle_manager: Node = null) -> bool:
	var target = push_result.get("target_node", null)
	if target == null or not is_instance_valid(target):
		return false

	var collided = push_result.get("collided", false)
	var collision_type = push_result.get("collision_type", "none")
	var dmg = push_result.get("collision_damage", BASE_COLLISION_DAMAGE)
	var dir = push_result.get("direction", Vector2i.RIGHT)
	var moved_tiles = push_result.get("moved_tiles", 0)
	var final_pos = push_result.get("final_position", target.position)

	# 1. Move target node to final tile if moved
	if moved_tiles > 0:
		if target.has_method("create_tween") and target.is_inside_tree():
			var tw = target.create_tween()
			if tw:
				tw.tween_property(target, "position", final_pos, 0.15).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			else:
				target.position = final_pos
		else:
			target.position = final_pos

	# 2. If displacement occurred, cancel any active attack intents on the target
	if push_result.get("interrupted", false) and battle_manager != null and battle_manager.has_method("cancel_intents_for"):
		battle_manager.cancel_intents_for(target, "displacement")

	# 3. Handle collisions
	if collided:
		var target_name = target.character_name if ("character_name" in target and target.character_name != "") else target.name
		if push_result.get("ring_out", false):
			# Ring out: immediate knockout
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(target.position, "RING OUT!", "damage")
			if ui and ui.has_method("log_action"):
				ui.log_action("💥 [%s] Knocked out of the arena! RING OUT!" % target_name)
			if target.has_method("take_damage"):
				target.take_damage(9999, Vector2.ZERO, 30, 100, true)
		else:
			# Collision shock damage to pushed unit
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(target.position, "COLLISION SHOCK! (+%d)" % dmg, "damage")
			if ui and ui.has_method("log_action"):
				var obstacle_desc = "boundary wall"
				if collision_type == "fighter" and push_result.get("collided_node", null):
					var other = push_result["collided_node"]
					var other_name = other.character_name if ("character_name" in other and other.character_name != "") else other.name
					obstacle_desc = other_name
				elif collision_type == "structure":
					obstacle_desc = "earth wall"
				ui.log_action("💥 [%s] Collided with %s! Took %d collision damage!" % [target_name, obstacle_desc, dmg])

			if target.has_method("take_damage"):
				target.take_damage(dmg, Vector2.ZERO, 30, 100, true)

			# Fighter-to-fighter collision: bump victim ALSO takes 12 damage!
			if collision_type == "fighter":
				var bumped = push_result.get("collided_node", null)
				if bumped != null and is_instance_valid(bumped) and bumped.has_method("take_damage"):
					var bumped_name = bumped.character_name if ("character_name" in bumped and bumped.character_name != "") else bumped.name
					if ui and ui.has_method("spawn_damage_popup"):
						ui.spawn_damage_popup(bumped.position, "BUMP SHOCK! (+%d)" % dmg, "damage")
					if ui and ui.has_method("log_action"):
						ui.log_action("💥 [%s] Collateral impact! Took %d collision damage!" % [bumped_name, dmg])
					bumped.take_damage(dmg, Vector2.ZERO, 30, 100, true)
					# Intercept / cancel bumped fighter's windup intent too if staggered hard
					if battle_manager != null and battle_manager.has_method("cancel_intents_for"):
						battle_manager.cancel_intents_for(bumped, "displacement")

			# Structure collision: damage the earth wall
			elif collision_type == "structure":
				var wall_tile = push_result.get("collided_tile", Vector2i(-1, -1))
				var terrain = battle_manager.terrain if (battle_manager != null and "terrain" in battle_manager) else null
				if terrain != null and is_instance_valid(terrain) and terrain.has_method("react_to_attack"):
					var wall_tiles: Array[Vector2i] = [wall_tile]
					terrain.react_to_attack("physical", wall_tiles, dmg)

			# Sprite shake feedback on collision
			var sprite = target.get_node_or_null("Sprite2D")
			if sprite != null and target.has_method("create_tween") and target.is_inside_tree():
				var tw = target.create_tween()
				if tw:
					tw.tween_property(sprite, "position", Vector2(dir.x * 8, dir.y * 8), 0.05)
					tw.tween_property(sprite, "position", Vector2.ZERO, 0.05)

	# Return true if the unit actually shifted positions
	return moved_tiles > 0
