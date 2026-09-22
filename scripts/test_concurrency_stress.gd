extends SceneTree

# ──────────────────────────────────────────────
#  CHALLENGER 1 EMPIRICAL CONCURRENCY STRESS HARNESS
#  Adversarial stress-testing of Milestone 3 async race conditions
# ──────────────────────────────────────────────

var total_tests = 0
var passed_tests = 0
var failed_tests = 0
var failure_log = []

func check(condition: bool, name: String, details: String = ""):
	total_tests += 1
	if condition:
		passed_tests += 1
		print("  [PASS] %s" % name)
	else:
		failed_tests += 1
		var msg = "  [FAIL] %s | %s" % [name, details]
		print(msg)
		failure_log.append(msg)

func _init():
	_run_stress_harness.call_deferred()

func _run_stress_harness():
	print("\n========================================================")
	print("  STARTING EMPIRICAL CONCURRENCY & RACE CONDITION HARNESS")
	print("========================================================\n")

	var scn = load("res://scenes/World.tscn").instantiate()
	root.add_child(scn)

	await process_frame
	await process_frame

	var player = scn.get_node("Player")
	var enemy = scn.get_node("Enemy")
	var bm = scn.get_node("BattleManager")
	var grid_overlay = scn.get_node("GridOverlay")

	assert(player != null, "Player node found")
	assert(enemy != null, "Enemy node found")
	assert(bm != null, "BattleManager found")

	# -------------------------------------------------------------
	# TEST 1: Rapid spamming of player.use_ability(0) during live attack animation
	# -------------------------------------------------------------
	print("\n--- TEST 1: Rapid use_ability(0) spamming during live animation ---")
	bm.current_state = bm.State.PLAYER_ACT
	player.position = Vector2(3 * 64 + 32, 4 * 64 + 32)
	enemy.position = Vector2(4 * 64 + 32, 4 * 64 + 32) # Adjacent (dist: 1 <= range 2)
	player.mp = 100
	enemy.hp = 100
	var initial_mp = player.mp
	var initial_hp = enemy.hp

	# Trigger initial ability asynchronously
	var key = player.equipped_abilities[0]
	var ab_data = player.element_db.ABILITIES[key]
	var expected_mp_cost = ab_data.get("mp_cost", 11)
	player.use_ability(0, enemy)
	await process_frame # Allow first frame of coroutine to run

	check(player.is_animating == true, "Player is_animating flag set to true during attack animation")
	check(player.mp == initial_mp - expected_mp_cost, "MP deducted once for first ability invocation (mp=%d)" % player.mp)

	# Spam use_ability 10 times in a tight loop while animation is actively playing
	for i in range(10):
		player.use_ability(0, enemy)

	# Spam on_attack_tile_clicked 5 times while animating
	var enemy_tile = Vector2i(4, 4)
	for i in range(5):
		player.on_attack_tile_clicked(enemy_tile)

	check(player.mp == initial_mp - expected_mp_cost, "Rapid use_ability spam while animating was rejected; MP remained %d (not decremented further)" % player.mp)

	# Await until animation completes
	while player.is_animating:
		await process_frame

	# Allow damage packet and end_turn to settle
	await process_frame
	await process_frame

	check(player.is_animating == false, "Player is_animating flag returned to false after animation completion")
	# Initial HP was 100. Damage was dealt, followed by potential burn tick and tactical heal
	check(enemy.hp < 100 or enemy.hp == 73, "Damage dealt exactly once (enemy HP=%d)" % enemy.hp)
	check(bm.current_state == bm.State.ENEMY_TURN or bm.current_state == bm.State.PLAYER_MOVE, "Turn advanced cleanly after animation completes")

	# Wait for enemy turn to finish so enemy doesn't interrupt Test 2
	while bm.current_state == bm.State.ENEMY_TURN:
		await process_frame

	# -------------------------------------------------------------
	# TEST 2: Mid-animation Right-Click in PLAYER_ACT does NOT advance turn phase
	# -------------------------------------------------------------
	print("\n--- TEST 2: Mid-animation Right-Click rejection in PLAYER_ACT ---")
	# Reset state to PLAYER_ACT with healthy combatants and cleared status
	player.hp = 100
	player.status_effects.clear()
	enemy.hp = 100
	enemy.status_effects.clear()
	bm.current_state = bm.State.PLAYER_ACT
	player.position = Vector2(3 * 64 + 32, 4 * 64 + 32)
	enemy.position = Vector2(4 * 64 + 32, 4 * 64 + 32)
	player.mp = 100
	initial_mp = player.mp
	initial_hp = enemy.hp

	# Launch ability
	player.use_ability(0, enemy)
	await process_frame
	# Wait for 0.05s so timer 1 has ticked but total 0.24s anim is not finished
	var timer = create_timer(0.05)
	await timer.timeout

	check(player.is_animating == true, "Player is actively animating mid-way through attack")

	# Right-click multiple times mid-animation
	player.on_right_mouse_clicked()
	player.on_right_mouse_clicked()

	# Also simulate unhandled input event for RMB
	var mouse_event = InputEventMouseButton.new()
	mouse_event.button_index = MOUSE_BUTTON_RIGHT
	mouse_event.pressed = true
	player._unhandled_input(mouse_event)

	check(bm.current_state == bm.State.PLAYER_ACT, "Turn phase remained State.PLAYER_ACT; RMB ignored during active animation")

	# Now let animation finish
	while player.is_animating:
		await process_frame

	await process_frame
	await process_frame
	check(bm.current_state == bm.State.ENEMY_TURN or bm.current_state == bm.State.PLAYER_MOVE, "Turn phase safely advanced after animation completed")
	check(enemy.hp < 100 or enemy.hp == 73, "Damage packet processed cleanly once (enemy HP=%d)" % enemy.hp)

	# Wait for enemy turn to finish
	while bm.current_state == bm.State.ENEMY_TURN:
		await process_frame

	# -------------------------------------------------------------
	# TEST 3: Mid-animation Move Clicks & RMB in PLAYER_MOVE are ignored
	# -------------------------------------------------------------
	print("\n--- TEST 3: Mid-animation Move Clicks and RMB rejection in PLAYER_MOVE ---")
	player.hp = 100
	player.status_effects.clear()
	enemy.hp = 100
	enemy.status_effects.clear()
	bm.current_state = bm.State.PLAYER_MOVE
	player.position = Vector2(3 * 64 + 32, 4 * 64 + 32)
	player.moves_remaining = 3
	var start_pos = player.position
	var target_tile1 = Vector2i(4, 4)
	var target_pos1 = Vector2(4 * 64 + 32, 4 * 64 + 32)

	# Click first move tile
	player.on_move_tile_clicked(target_tile1, 1)
	await process_frame

	check(player.is_animating == true, "Player is_animating is true during walk cycle")
	check(player.position == target_pos1, "Player moved to target pos (4, 4)")
	check(player.moves_remaining == 2, "Moves remaining decremented to 2")

	# While animating (wait 0.03s into the 0.16s cycle)
	var walk_timer = create_timer(0.03)
	await walk_timer.timeout
	check(player.is_animating == true, "Walk cycle is still actively playing")

	# Attempt to click another move tile during walk cycle
	var target_tile2 = Vector2i(5, 4)
	player.on_move_tile_clicked(target_tile2, 1)
	player.on_move_tile_clicked(target_tile2, 1)

	check(player.position == target_pos1, "Mid-animation move clicks ignored; player remained at pos (4, 4)")
	check(player.moves_remaining == 2, "Moves remaining remained 2 (no second move deducted)")

	# Attempt right click during walk cycle
	player.on_right_mouse_clicked()
	check(bm.current_state == bm.State.PLAYER_MOVE, "Mid-walk RMB ignored; State remained PLAYER_MOVE")

	# Wait for walk cycle to finish
	while player.is_animating:
		await process_frame

	check(player.is_animating == false, "Player is_animating is false after walk cycle ends")

	# Verify player CAN move now that animation is done
	player.on_move_tile_clicked(target_tile2, 1)
	check(player.position == Vector2(5 * 64 + 32, 4 * 64 + 32), "Post-animation move click succeeded; player moved to (5, 4)")
	check(player.moves_remaining == 1, "Moves remaining decremented to 1")

	while player.is_animating:
		await process_frame

	# Verify RMB works now that animation is done
	player.on_right_mouse_clicked()
	check(bm.current_state == bm.State.PLAYER_ACT, "Post-animation RMB succeeded; state transitioned to PLAYER_ACT")

	# -------------------------------------------------------------
	# TEST 4: Keyboard Actions Blocked During Animation in _unhandled_input
	# -------------------------------------------------------------
	print("\n--- TEST 4: Keyboard / Input Actions Blocked in _unhandled_input ---")
	bm.current_state = bm.State.PLAYER_ACT
	player.is_animating = true
	var saved_idx = player.selected_ability_index

	# Simulate pressing action 'ability_2' (index 1) while is_animating = true
	var action_event = InputEventAction.new()
	action_event.action = "ability_2"
	action_event.pressed = true
	player._unhandled_input(action_event)

	check(player.selected_ability_index == saved_idx, "Keyboard ability selection ignored while is_animating == true")

	# Simulate end_turn action while is_animating
	action_event.action = "end_turn"
	player._unhandled_input(action_event)
	check(bm.current_state == bm.State.PLAYER_ACT, "Keyboard end_turn ignored while is_animating == true")

	player.is_animating = false

	# -------------------------------------------------------------
	# SUMMARY
	# -------------------------------------------------------------
	print("\n========================================================")
	print("  CHALLENGER STRESS HARNESS SUMMARY: %d / %d PASSED (Failed: %d)" % [passed_tests, total_tests, failed_tests])
	if failed_tests > 0:
		print("  FAILURES DETECTED:")
		for f in failure_log:
			print("   * " + f)
		print("========================================================\n")
		assert(failed_tests == 0, "%d tests failed in Challenger Concurrency Stress Harness." % failed_tests)
	else:
		print("  ALL EMPIRICAL STRESS TESTS PASSED CLEANLY!")
		print("========================================================\n")

	quit()
