extends SceneTree

# ─────────────────────────────────────────────────────────────────────────────
# Test Suite: ReactionResolver, Primers, and Crowd Momentum
# Tests Guard, Counter, Intercept, Overwatch, recursion guards, target-owned
# elemental primers, and per-team crowd momentum thresholds.
# ─────────────────────────────────────────────────────────────────────────────

const ReactionResolverScript = preload("res://scripts/reaction_resolver.gd")

var passed := 0
var failed := 0

class DummyFighter extends CharacterBody2D:
	var hp: int = 100
	var max_hp: int = 100
	var mp: int = 50
	var character_name: String = "Dummy"
	var took_damage_called: bool = false
	var last_damage: int = 0
	var battle_manager: Node = null

	func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, _dex: int = 20, _acc: int = 90, _unavoidable: bool = false, attacker_node: Node2D = null, _elem: String = ""):
		var final_amount = amount
		# Guard check
		if battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null:
			var g_res = battle_manager.reaction_resolver.evaluate_guard(self, final_amount)
			if g_res.get("guarded", false):
				final_amount = g_res["damage"]

		hp = max(0, hp - final_amount)
		took_damage_called = true
		last_damage = final_amount

		# Counter check
		if hp > 0 and battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null and attacker_node != null and attacker_node != self:
			battle_manager.reaction_resolver.trigger_counter(self, attacker_node, null)

		return final_amount

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
	print("   REACTIONS, PRIMERS & MOMENTUM TEST SUITE")
	print("========================================================\n")

	var bm = load("res://scripts/battle_manager.gd").new()
	root.add_child(bm)

	var p1 = DummyFighter.new()
	p1.name = "PlayerDefender"
	p1.position = _tile_pos(4, 4)
	p1.battle_manager = bm
	root.add_child(p1)
	p1.add_to_group("players")
	p1.add_to_group("combatants")

	var p2 = DummyFighter.new()
	p2.name = "PlayerAlly"
	p2.position = _tile_pos(4, 5) # Adjacent to p1
	p2.battle_manager = bm
	root.add_child(p2)
	p2.add_to_group("players")
	p2.add_to_group("combatants")

	var e1 = DummyFighter.new()
	e1.name = "EnemyAttacker"
	e1.position = _tile_pos(5, 4) # 1 tile from p1
	e1.battle_manager = bm
	root.add_child(e1)
	e1.add_to_group("enemies")
	e1.add_to_group("combatants")

	bm.player_units = [p1, p2]
	bm.enemy_units = [e1]

	# --- TEST 1: Guard Reaction ---
	print("--- TEST 1: Guard Reaction (-30% damage) ---")
	bm.reaction_resolver.declare_reaction(p1, "guard")
	check(bm.reaction_resolver.has_active_reaction(p1, "guard"), "Guard stance is active on p1")

	p1.hp = 100
	p1.take_damage(20, e1.position, 20, 90, false, e1)
	check(p1.last_damage == 14, "Incoming 20 damage reduced to 14 by Guard (30% reduction)", "got %d" % p1.last_damage)
	check(not bm.reaction_resolver.has_active_reaction(p1, "guard"), "Guard consumed for round (single trigger)")

	# Second attack in same round does not get Guard reduction
	p1.take_damage(20, e1.position, 20, 90, false, e1)
	check(p1.last_damage == 20, "Subsequent hit in same round deals full damage (no double guard)")

	# --- TEST 2: Counter Reaction (Melee Retaliation) ---
	print("\n--- TEST 2: Counter Reaction ---")
	bm.reaction_resolver.reset_round()
	bm.reaction_resolver.declare_reaction(p1, "counter")
	check(bm.reaction_resolver.has_active_reaction(p1, "counter"), "Counter stance is active on p1")

	e1.hp = 100
	p1.hp = 100
	# e1 attacks p1 in melee range
	p1.take_damage(10, e1.position, 20, 90, false, e1)
	check(e1.hp == 86, "Enemy attacker took 14 counter damage upon hitting counter-stance defender", "got e1.hp=%d" % e1.hp)

	# --- TEST 3: Intercept Reaction ---
	print("\n--- TEST 3: Intercept Reaction ---")
	bm.reaction_resolver.reset_round()
	bm.reaction_resolver.declare_reaction(p1, "intercept", p2)
	check(bm.reaction_resolver.has_active_reaction(p1, "intercept"), "p1 declares Intercept protecting adjacent ally p2")

	var interceptor = bm.reaction_resolver.evaluate_intercept(p2, self)
	check(interceptor == p1, "Attack aimed at p2 redirected to protector p1")

	# --- TEST 4: Overwatch Reaction ---
	print("\n--- TEST 4: Overwatch Reaction ---")
	bm.reaction_resolver.reset_round()
	bm.reaction_resolver.declare_reaction(p1, "overwatch", null, {"mp_cost": 10})
	check(bm.reaction_resolver.has_active_reaction(p1, "overwatch"), "p1 sets Overwatch ambush trap")

	e1.position = _tile_pos(7, 4) # Out of range
	e1.hp = 86
	# e1 steps into tile (5, 4), which is 1 tile away from p1 (4, 4)
	var ow_triggered = bm.reaction_resolver.trigger_overwatch(e1, Vector2i(5, 4), self, null)
	check(ow_triggered == true, "Overwatch ambushed enemy entering threatened sector")
	check(e1.hp == 70, "Moving enemy took 16 overwatch damage", "got e1.hp=%d" % e1.hp)

	# --- TEST 5: Target-Owned Elemental Primers & Detonations ---
	print("\n--- TEST 5: Target-Owned Elemental Primers ---")
	check(bm.primers.is_empty(), "No initial primers")

	# p1 (player) lands a Fire attack on e1
	bm.register_elemental_action(p1, "fire", e1)
	check(bm.primers.has(e1), "Primer token attached directly to target e1")
	check(bm.primers[e1]["element"] == "fire", "Primer element is 'fire'")
	check(bm.primers[e1]["caster_team"] == "player", "Primer owned by player squad")

	# p2 (teammate) lands a Water attack on e1 -> Detonation!
	e1.hp = 70
	var fusion = bm.register_elemental_action(p2, "water", e1)
	check(not fusion.is_empty(), "Teammate landed compatible element triggering fusion detonation")
	check(not bm.primers.has(e1), "Primer consumed upon detonation")
	check(e1.hp == 58, "Target took 12 bonus fusion detonation damage", "got e1.hp=%d" % e1.hp)

	# --- TEST 6: Team Crowd Momentum ---
	print("\n--- TEST 6: Team Crowd Momentum & Roar/Empower ---")
	check(bm.player_momentum > 0, "Player squad accumulated crowd momentum from hits and detonation")
	check(bm.enemy_momentum == 0, "Enemy squad momentum remained independent at 0")

	# Test Crowd Roar at 50
	bm.player_momentum = 45
	bm.player_crowd_roar_active = false
	bm.add_momentum("player", 10, "test_boost")
	check(bm.player_momentum == 55, "Player momentum reached 55")
	check(bm.player_crowd_roar_active == true, "Crossing 50 triggered Crowd Roar (+1 movement benefit)")

	# Test Empowered Boost at 100
	bm.add_momentum("player", 50, "test_max")
	check(bm.player_momentum == 100, "Player momentum capped at 100")
	check(bm.player_empowered == true, "Reached 100: Player empowered stance active")

	var boost = bm.consume_empowered_boost("player")
	check(boost == 0.20, "Empowered form grants +20% damage/healing boost")
	check(bm.player_empowered == false, "Empowered boost consumed after execution")

	# Clean up
	p1.queue_free()
	p2.queue_free()
	e1.queue_free()
	bm.queue_free()
	await process_frame

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	quit(1 if failed > 0 else 0)
