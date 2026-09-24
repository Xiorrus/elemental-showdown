extends SceneTree

# ─────────────────────────────────────────────────────────────────────────────
# Test Suite: ForceMovementResolver
# Tests multi-tile pushes, boundary collision, fighter-to-fighter collision,
# earth wall collision, and ring-out mechanics.
# ─────────────────────────────────────────────────────────────────────────────

const ForceMovementResolverScript = preload("res://scripts/force_movement_resolver.gd")
const TerrainScript = preload("res://scripts/battle_terrain.gd")

var passed := 0
var failed := 0

class DummyFighter extends Node2D:
	var hp: int = 100
	var max_hp: int = 100
	var character_name: String = "Dummy"
	var took_damage_called: bool = false
	var last_damage_amount: int = 0

	func take_damage(amount: int, _attacker_pos: Vector2 = Vector2.ZERO, _dex: int = 20, _acc: int = 90, _unavoidable: bool = false, _attacker: Node2D = null, _elem: String = ""):
		took_damage_called = true
		last_damage_amount = amount
		hp = max(0, hp - amount)
		return amount

class DummyBattleManager extends Node:
	var terrain = null

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, label: String, detail: String = "") -> void:
	if condition:
		passed += 1
		print("  [PASS] " + label)
	else:
		failed += 1
		printerr("  [FAIL] " + label + (" (" + detail + ")" if detail != "" else ""))

func _tile_pos(col: int, row: int) -> Vector2:
	return Vector2(col * 64 + 32, row * 64 + 32)

func _run() -> void:
	print("\n========================================================")
	print("   FORCE MOVEMENT & COLLISION RESOLVER TEST SUITE")
	print("========================================================\n")

	# --- TEST 1: Unobstructed 1-tile and 2-tile push ---
	print("--- TEST 1: Unobstructed Push ---")
	var f1 = DummyFighter.new()
	f1.name = "Fighter1"
	f1.position = _tile_pos(5, 5)
	root.add_child(f1)
	f1.add_to_group("combatants")

	var res1 = ForceMovementResolverScript.resolve_push(f1, _tile_pos(4, 5), 1, self, null)
	check(res1["collided"] == false, "1-tile push does not collide")
	check(res1["final_tile"] == Vector2i(6, 5), "Pushed from (5,5) to (6,5)", "got %s" % str(res1["final_tile"]))
	check(res1["moved_tiles"] == 1, "Moved tiles count is 1")

	var res2 = ForceMovementResolverScript.resolve_push(f1, _tile_pos(4, 5), 3, self, null)
	check(res2["collided"] == false, "3-tile push does not collide in open space")
	check(res2["final_tile"] == Vector2i(8, 5), "Pushed 3 tiles from (5,5) to (8,5)", "got %s" % str(res2["final_tile"]))
	check(res2["moved_tiles"] == 3, "Moved tiles count is 3")

	# --- TEST 2: Boundary Collision (Wall Impact) ---
	print("\n--- TEST 2: Boundary Collision ---")
	f1.position = _tile_pos(17, 5) # Right edge of 18-wide arena (0..17)
	var res_wall = ForceMovementResolverScript.resolve_push(f1, _tile_pos(16, 5), 2, self, null)
	check(res_wall["collided"] == true, "Pushing past right arena edge collides with boundary")
	check(res_wall["collision_type"] == "boundary", "Collision type is 'boundary'")
	check(res_wall["final_tile"] == Vector2i(17, 5), "Unit stops at edge tile (17,5)")
	check(res_wall["collision_damage"] == 12, "Base collision damage is 12")

	# Test applying wall collision
	f1.took_damage_called = false
	ForceMovementResolverScript.apply_resolved_push(res_wall, null, null)
	check(f1.took_damage_called == true, "take_damage called on boundary impact")
	check(f1.last_damage_amount == 12, "Took 12 collision shock damage")

	# --- TEST 3: Fighter-to-Fighter Collision ---
	print("\n--- TEST 3: Fighter-to-Fighter Collision ---")
	var f2 = DummyFighter.new()
	f2.name = "Fighter2"
	f2.position = _tile_pos(6, 5)
	root.add_child(f2)
	f2.add_to_group("combatants")

	f1.position = _tile_pos(5, 5)
	var res_f2f = ForceMovementResolverScript.resolve_push(f1, _tile_pos(4, 5), 2, self, null)
	check(res_f2f["collided"] == true, "Pushing towards occupied tile collides with other fighter")
	check(res_f2f["collision_type"] == "fighter", "Collision type is 'fighter'")
	check(res_f2f["collided_node"] == f2, "Collided node identifies Fighter2")
	check(res_f2f["final_tile"] == Vector2i(5, 5), "Pushed fighter stops before occupied tile")

	f1.took_damage_called = false
	f2.took_damage_called = false
	ForceMovementResolverScript.apply_resolved_push(res_f2f, null, null)
	check(f1.took_damage_called == true, "Pushed fighter takes collision damage")
	check(f1.last_damage_amount == 12, "Pushed fighter took 12 damage")
	check(f2.took_damage_called == true, "Bumped fighter ALSO takes collision damage (collateral shock)")
	check(f2.last_damage_amount == 12, "Bumped fighter took 12 damage")

	# --- TEST 4: Earth Wall Collision & Wall Degradation ---
	print("\n--- TEST 4: Earth Wall Collision ---")
	var terrain = TerrainScript.new()
	root.add_child(terrain)
	var wall_tile := Vector2i(7, 5)
	terrain.place_from_skill("earth_wall", Vector2i(5, 5), wall_tile, 2, "linear_front", 2)
	check(terrain.has_wall(wall_tile), "Earth wall placed at (7,5)")
	var initial_wall_hp = terrain.hazards[wall_tile]["hp"]

	# Move f2 out of the way
	f2.position = _tile_pos(1, 1)

	# Push f1 from (5,5) towards (7,5) with 2 tiles force
	f1.position = _tile_pos(5, 5)
	f1.took_damage_called = false
	var res_earth = ForceMovementResolverScript.resolve_push(f1, _tile_pos(4, 5), 3, self, terrain)
	check(res_earth["collided"] == true, "Push collides with earth wall")
	check(res_earth["collision_type"] == "structure", "Collision type is 'structure'")
	check(res_earth["final_tile"] == Vector2i(6, 5), "Pushed fighter advanced to (6,5) right before wall (7,5)")

	# Create a dummy battle manager with terrain reference to verify wall damage
	var dummy_bm = DummyBattleManager.new()
	dummy_bm.terrain = terrain
	root.add_child(dummy_bm)

	ForceMovementResolverScript.apply_resolved_push(res_earth, null, dummy_bm)
	check(f1.took_damage_called == true, "Pushed fighter took collision damage from earth wall")
	check(f1.last_damage_amount == 12, "Pushed fighter took 12 damage")
	check(terrain.hazards[wall_tile]["hp"] == initial_wall_hp - 12, "Earth wall durability decreased by 12 collision damage")

	# --- TEST 5: Ring-Out Rule ---
	print("\n--- TEST 5: Ring-Out Arena Preset ---")
	f1.position = _tile_pos(0, 5) # Left edge
	var res_ringout = ForceMovementResolverScript.resolve_push(f1, _tile_pos(1, 5), 1, self, null, 12, true)
	check(res_ringout["collided"] == true, "Ring out detected beyond edge")
	check(res_ringout["ring_out"] == true, "ring_out flag is true")
	check(res_ringout["collision_type"] == "ring_out", "collision_type is 'ring_out'")

	f1.hp = 100
	ForceMovementResolverScript.apply_resolved_push(res_ringout, null, null)
	check(f1.hp <= 0, "Ring out knocked out fighter immediately")

	# Clean up
	f1.queue_free()
	f2.queue_free()
	terrain.queue_free()
	dummy_bm.queue_free()
	await process_frame

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	quit(1 if failed > 0 else 0)
