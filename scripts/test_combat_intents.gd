extends SceneTree

# ─────────────────────────────────────────────────────────────────────────────
# Test Suite: AttackIntent & Telegraphed Combat
# Tests intent queuing, countdown ticking, interrupt on displacement/stun/KO,
# evasion via movement, and telegraphed zone detonation.
# ─────────────────────────────────────────────────────────────────────────────

const AttackIntentScript = preload("res://scripts/attack_intent.gd")
const ForceMovementResolverScript = preload("res://scripts/force_movement_resolver.gd")

var passed := 0
var failed := 0

class DummyCombatant extends CharacterBody2D:
	var hp: int = 100
	var max_hp: int = 100
	var mp: int = 50
	var character_name: String = "Dummy"
	var has_acted: bool = false
	var stunned: bool = false

	func is_stunned() -> bool:
		return stunned

	func take_damage(amount: int, _attacker_pos: Vector2 = Vector2.ZERO, _dex: int = 20, _acc: int = 90, _unavoidable: bool = false, _attacker: Node2D = null, _elem: String = ""):
		hp = max(0, hp - amount)
		return amount

	func spend_mp(amount: int) -> bool:
		if mp >= amount:
			mp -= amount
			return true
		return false

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
	print("   COMBAT ATTACK INTENTS & TELEGRAPH TEST SUITE")
	print("========================================================\n")

	# --- TEST 1: Creation and Snapshot Freezing ---
	print("--- TEST 1: Intent Creation & Area Freezing ---")
	var caster = DummyCombatant.new()
	caster.name = "EnemyMage"
	caster.position = _tile_pos(10, 4)
	root.add_child(caster)
	caster.add_to_group("enemies")

	var target_tiles: Array[Vector2i] = [Vector2i(5, 4), Vector2i(5, 5), Vector2i(6, 4), Vector2i(6, 5)]
	var ability = {"name": "Cataclysm", "damage": 40, "element": "earth", "mp_cost": 20, "windup_rounds": 1}

	var intent = AttackIntentScript.new(caster, "enemy", "Cataclysm", "Cataclysm Sphere", ability, Vector2i(10, 4), Vector2i(5, 4), target_tiles, 1)

	check(intent.caster == caster, "Caster correctly referenced")
	check(intent.caster_team == "enemy", "Caster team is enemy")
	check(intent.rounds_remaining == 1, "Initial countdown is 1 round")
	check(intent.target_tiles == target_tiles, "Target zone frozen correctly")
	check(intent.is_cancelled == false, "Intent starts uncancelled")
	check(intent.can_resolve() == true, "Intent is valid for resolution")

	# --- TEST 2: Countdown and Resolution ---
	print("\n--- TEST 2: Countdown & Execution ---")
	var victim = DummyCombatant.new()
	victim.name = "PlayerFighter"
	victim.position = _tile_pos(5, 4) # Inside target zone
	root.add_child(victim)
	victim.add_to_group("players")

	var bm = load("res://scripts/battle_manager.gd").new()
	root.add_child(bm)
	bm.enemy_units = [caster]
	bm.player_units = [victim]

	bm.queue_intent(intent)
	check(bm.active_intents.size() == 1, "Intent queued in BattleManager")

	# Resolve enemy intents at start of enemy turn
	bm.resolve_team_intents("enemy")
	check(victim.hp == 60, "Victim standing in target zone took 40 damage", "got hp=%d" % victim.hp)
	check(intent.is_resolved == true, "Intent marked resolved")
	check(bm.active_intents.is_empty(), "Resolved intent cleared from active queue")

	# --- TEST 3: Evasion via Simple Movement ---
	print("\n--- TEST 3: Evading Telegraph by Moving ---")
	var intent2 = AttackIntentScript.new(caster, "enemy", "Cataclysm", "Cataclysm Sphere", ability, Vector2i(10, 4), Vector2i(5, 4), target_tiles, 1)
	bm.queue_intent(intent2)

	# Victim moves out of target zone to (3, 4)
	victim.position = _tile_pos(3, 4)
	victim.hp = 60

	bm.resolve_team_intents("enemy")
	check(victim.hp == 60, "Victim took 0 damage because they moved away from marked zone")
	check(intent2.is_resolved == true, "Telegraph still detonated on original zone without tracking")

	# --- TEST 4: Interruption via Forced Displacement (Knockback) ---
	print("\n--- TEST 4: Interrupt via Forced Displacement ---")
	var intent3 = AttackIntentScript.new(caster, "enemy", "Cataclysm", "Cataclysm Sphere", ability, Vector2i(10, 4), Vector2i(5, 4), target_tiles, 1)
	bm.queue_intent(intent3)

	# Player pushes caster with 1 tile knockback
	var push_res = ForceMovementResolverScript.resolve_push(caster, _tile_pos(11, 4), 1, self, null)
	ForceMovementResolverScript.apply_resolved_push(push_res, null, bm)

	check(intent3.is_cancelled == true, "Forced displacement cancelled attack intent")
	check(intent3.cancel_reason == "displacement", "Cancel reason recorded as 'displacement'")
	check(intent3.can_resolve() == false, "Cancelled intent cannot resolve")

	# --- TEST 5: Interruption via KO or Stun ---
	print("\n--- TEST 5: Interrupt via Stun or KO ---")
	var intent4 = AttackIntentScript.new(caster, "enemy", "Cataclysm", "Cataclysm Sphere", ability, Vector2i(9, 4), Vector2i(5, 4), target_tiles, 1)
	bm.queue_intent(intent4)

	# Stun caster
	caster.stunned = true
	check(intent4.can_resolve() == false, "Stunned caster cannot resolve intent")

	bm.cancel_intents_for(caster, "stun")
	check(intent4.is_cancelled == true, "cancel_intents_for marks intent cancelled")
	check(intent4.cancel_reason == "stun", "Cancel reason recorded as 'stun'")

	# Cleanup
	caster.queue_free()
	victim.queue_free()
	bm.queue_free()
	await process_frame

	print("\n========================================================")
	print("  RESULT: %d PASS  /  %d FAIL  /  %d TOTAL" % [passed, failed, passed + failed])
	print("========================================================\n")

	quit(1 if failed > 0 else 0)
