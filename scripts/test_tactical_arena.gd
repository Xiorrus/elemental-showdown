extends SceneTree

const Geometry = preload("res://scripts/ability_geometry.gd")
const Terrain = preload("res://scripts/battle_terrain.gd")
const Catalog = preload("res://scripts/scouting_catalog.gd")

var passed := 0
var failed := 0

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _run() -> void:
	var origin := Vector2i(3, 4)
	var cone: Array[Vector2i] = Geometry.tiles(origin, Vector2i.RIGHT, 3, "cone")
	check(cone.size() == 9 and cone.has(Vector2i(4, 4)) and cone.has(Vector2i(5, 3)) and cone.has(Vector2i(6, 2)),
		"Cone geometry widens from one to three to five tiles")
	var slash: Array[Vector2i] = Geometry.tiles(origin, Vector2i.RIGHT, 4, Geometry.shape_for("Prism Sweep", "cardinal"))
	check(slash.size() == 16 and slash.has(Vector2i(7, 6)) and not slash.has(Vector2i(8, 4)),
		"Slash is a four-wide, four-deep attack")
	var pierce: Array[Vector2i] = Geometry.tiles(origin, Vector2i.RIGHT, 5, Geometry.shape_for("Pressure Pierce", "radial"))
	check(pierce.size() == 5 and pierce.has(Vector2i(8, 4)) and not pierce.has(Vector2i(5, 5)),
		"Pierce hits a straight line rather than a radial area")
	var terrain = Terrain.new()
	root.add_child(terrain)
	terrain.place_from_skill("fire", origin, Vector2i(5, 4), 2, "radial", 3)
	check(terrain.is_blocked(Vector2i(4, 4)) and terrain.is_blocked(Vector2i(5, 4)) and terrain.is_blocked(Vector2i(3, 3)),
		"Furnace Zone leaves a radial fire field")
	terrain.place_from_skill("fire", origin, Vector2i(5, 4), 2, "radial", 3)
	check(terrain.hazards[Vector2i(5, 4)]["duration"] == 6, "Repeated fire extends its lifetime")
	terrain.react_to_attack("water", [Vector2i(5, 4)], 1)
	check(not terrain.hazards.has(Vector2i(5, 4)) and terrain.hazards.has(Vector2i(4, 4)),
		"Water puts out only the affected fire tiles")
	terrain.place_from_skill("earth_wall", origin, Vector2i(7, 4), 3, "linear_front", 2)
	var wall := Vector2i(7, 4)
	for i in range(9): terrain.tick_round()
	check(terrain.has_wall(wall) and not terrain.has_wall(Vector2i(7, 3)), "Rock Pillar persists as one tile without a turn limit")
	terrain.react_to_attack("fire", [wall], 20)
	check(terrain.has_wall(wall), "A wall survives damage below its durability")
	terrain.react_to_attack("fire", [wall], 25)
	check(not terrain.has_wall(wall), "Attacks destroy a wall after sufficient damage")
	terrain.place_from_skill("ice", origin, Vector2i(5, 4), 3, "linear_front", 3)
	check(terrain.move_cost(Vector2i(5, 4)) == 2, "Ice costs an extra movement point")
	terrain.place_from_skill("smoke", origin, Vector2i(5, 4), 2, "radial", 3)
	check(terrain.accuracy_penalty(origin, Vector2i(4, 4)) == 25,
		"Smoke reduces accuracy for shots through an occupied smoke tile")
	check(Catalog.DIVISIONS.size() == 7 and Catalog.teams_for("city").size() == 8
		and Catalog.teams_for("world").size() == 8 and Catalog.teams_for("national_teams").size() == 8,
		"Scouting includes six club levels and all selectable national teams")
	terrain.queue_free()
	await process_frame
	print("TACTICAL ARENA: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
