extends SceneTree

func _init():
	print("\n========================================================")
	print("   SKILL TARGETING & VARIATIONS TEST SUITE")
	print("========================================================\n")

	var counts = {"passed": 0, "failed": 0}
	var check = func(condition: bool, test_name: String, details: String = ""):
		if condition:
			print("  [PASS] %s" % test_name)
			counts["passed"] += 1
		else:
			print("  [FAIL] %s %s" % [test_name, details])
			counts["failed"] += 1

	var root = get_root()
	await process_frame

	var overlay = preload("res://scripts/grid_overlay.gd").new()
	root.add_child(overlay)
	await process_frame

	# ── TEST 1: Standard Cardinal Attack Grid (No Diagonals) ──
	# Player at tile (5, 4), range 4 (fits completely within 18x10 bounds)
	overlay.show_attack_grid(Vector2(5 * 64 + 32, 4 * 64 + 32), 4, "cardinal")
	var tiles = overlay.valid_attack_tiles

	# Check: 4 boxes right, 4 left, 4 down, 4 up = 16 tiles total
	check.call(tiles.size() == 16, "T1.1 Range 4 cardinal targeting produces exactly 16 tiles (4 each dir)", "found=%d" % tiles.size())

	var has_diagonal = false
	for t in tiles:
		var dx = t.x - 5
		var dy = t.y - 4
		if dx != 0 and dy != 0:
			has_diagonal = true
			break
	check.call(not has_diagonal, "T1.2 ZERO diagonal tiles present in cardinal attack grid")

	# Check specific extremities
	check.call(tiles.has(Vector2i(9, 4)), "T1.3 Has tile 4 boxes right (9, 4)")
	check.call(tiles.has(Vector2i(1, 4)), "T1.4 Has tile 4 boxes left (1, 4)")
	check.call(tiles.has(Vector2i(5, 8)), "T1.5 Has tile 4 boxes down (5, 8)")
	check.call(tiles.has(Vector2i(5, 0)), "T1.6 Has tile 4 boxes up (5, 0)")

	# ── TEST 2: Linear Front Targeting (e.g. Explosion Pulse) ──
	# Player facing Right (Vector2i(1, 0)) at tile (3, 4), range 4
	overlay.show_attack_grid(Vector2(3 * 64 + 32, 4 * 64 + 32), 4, "linear_front", Vector2i(1, 0))
	var pulse_tiles = overlay.valid_attack_tiles
	check.call(pulse_tiles.size() == 4, "T2.1 Explosion Pulse produces exactly 4 tiles forward", "found=%d" % pulse_tiles.size())
	check.call(pulse_tiles.has(Vector2i(4, 4)) and pulse_tiles.has(Vector2i(5, 4)) and pulse_tiles.has(Vector2i(6, 4)) and pulse_tiles.has(Vector2i(7, 4)), "T2.2 Explosion Pulse tiles are strictly straight in front: (4,4), (5,4), (6,4), (7,4)")
	check.call(not pulse_tiles.has(Vector2i(2, 4)), "T2.3 Backward tiles not targeted by linear pulse")
	check.call(not pulse_tiles.has(Vector2i(3, 3)) and not pulse_tiles.has(Vector2i(3, 5)), "T2.4 Flank tiles not targeted by linear pulse")

	# Facing Left
	overlay.show_attack_grid(Vector2(6 * 64 + 32, 4 * 64 + 32), 4, "linear_front", Vector2i(-1, 0))
	var left_tiles = overlay.valid_attack_tiles
	check.call(left_tiles.size() == 4 and left_tiles.has(Vector2i(5, 4)) and left_tiles.has(Vector2i(2, 4)), "T2.5 Facing Left linear pulse projects straight to the left")

	# ── TEST 3: Radial Variation (e.g. Explosion Outburst) ──
	overlay.show_attack_grid(Vector2(5 * 64 + 32, 4 * 64 + 32), 2, "radial")
	var radial_tiles = overlay.valid_attack_tiles
	check.call(radial_tiles.size() > 4, "T3.1 Radial outburst covers 360 degree area around user", "found=%d" % radial_tiles.size())

	overlay.queue_free()
	await process_frame

	print("\n========================================================")
	print("  SKILL TARGETING RESULT: %d / %d PASSED (Failed: %d)" % [counts["passed"], counts["passed"] + counts["failed"], counts["failed"]])
	print("========================================================\n")

	if counts["failed"] == 0:
		print("[ALL SKILL TARGETING TESTS PASSED!]")
		quit(0)
	else:
		print("[SOME TESTS FAILED!]")
		quit(1)
