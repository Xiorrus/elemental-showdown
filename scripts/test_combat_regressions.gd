extends SceneTree

# Deterministic combat contracts: real player/enemy/manager methods, small fixtures,
# and no campaign writes. Run with an isolated APPDATA as with the other suites.
var passed := 0
var failed := 0

class AbilityDatabase extends Node:
	var ABILITIES = {
		"Audit_Blast": {"name": "Audit Blast", "element": "fire", "damage": 20, "mp_cost": 10, "range": 2, "accuracy": 100, "effect": "burn", "forms": {
			"focused": {"name": "Focused", "range": 2, "dmg_mult": 1.0, "mp_mult": 1.5, "shape": "cardinal"}
		}},
		"Audit_Heal": {"name": "Audit Heal", "element": "water", "damage": -30, "mp_cost": 8, "range": 2, "effect": "heal"},
		"Audit_Guard": {"name": "Audit Guard", "element": "earth", "damage": 0, "mp_cost": 8, "range": 2, "effect": "defense_buff"},
		"Audit_Cleanse": {"name": "Audit Cleanse", "element": "water", "damage": 0, "mp_cost": 8, "range": 2, "effect": "cleanse"}
	}

class CombatPlayer extends "res://scripts/player.gd":
	var starts := 0
	var evade_all := false
	func _ready():
		add_to_group("players")
		add_to_group("combatants")
		set_process(false)
	func start_turn():
		starts += 1
		super.start_turn()
	func calculate_directional_hit(attacker_pos: Vector2, attacker_dex: int = 20, skill_acc: int = 90) -> Dictionary:
		if evade_all:
			return {"is_hit": false, "angle": "front", "hit_chance": 0}
		return super.calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
	func _play_attack_anim(_ability: Dictionary, _target: Vector2):
		is_animating = true
		await get_tree().create_timer(0.02).timeout
		is_animating = false

class CombatEnemy extends "res://scripts/enemy.gd":
	var starts: Array = []
	var evade_all := false
	func _ready():
		add_to_group("enemies")
		add_to_group("combatants")
	func take_turn():
		starts.append({"state": battle_manager.current_state, "round": battle_manager.turn_count})
		await super.take_turn()
	func calculate_directional_hit(attacker_pos: Vector2, attacker_dex: int = 20, skill_acc: int = 90) -> Dictionary:
		if evade_all:
			return {"is_hit": false, "angle": "front", "hit_chance": 0}
		return super.calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
	func _play_attack_anim(_ability: Dictionary, _target: Vector2):
		is_animating = true
		await get_tree().create_timer(0.02).timeout
		is_animating = false

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _arena(player_count: int = 2, enemy_count: int = 2) -> Dictionary:
	var world = Node2D.new()
	root.add_child(world)
	var bm = load("res://scripts/battle_manager.gd").new()
	world.add_child(bm)
	var db = AbilityDatabase.new()
	world.add_child(db)
	var overlay = load("res://scripts/grid_overlay.gd").new()
	world.add_child(overlay)
	var players: Array = []
	var enemies: Array = []
	for i in player_count:
		var p = CombatPlayer.new()
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		p.add_child(sprite)
		world.add_child(p)
		p.name = "Ally_%d" % i
		p.position = Vector2(224, 288 + i * 64)
		p.battle_manager = bm
		p.element_db = db
		p.grid_overlay = overlay
		p.max_hp = 1000
		p.hp = 1000
		p.dexterity = 200
		p.agility = 0
		p.equipped_abilities = ["Audit_Blast", "Audit_Heal", "Audit_Guard", "Audit_Cleanse"]
		p.moves_remaining = 3
		players.append(p)
	for i in enemy_count:
		var e = CombatEnemy.new()
		var sprite = Sprite2D.new()
		sprite.name = "Sprite2D"
		e.add_child(sprite)
		world.add_child(e)
		e.name = "Enemy_%d" % i
		e.position = Vector2(288 + i * 64, 288)
		e.battle_manager = bm
		e.player = players[0]
		e.max_hp = 1000
		e.hp = 1000
		e.base_speed = 0
		e.agility = 0
		e.dexterity = 200
		e.ability_pool = [{"name": "Test Strike", "damage": 10, "mp_cost": 0, "range": 5, "accuracy": 100, "effect": "", "element": "fire"}]
		enemies.append(e)
	bm.player_units = players
	bm.enemy_units = enemies
	bm.player = players[0]
	bm.enemy = enemies[0]
	bm.active_player_unit = players[0]
	bm.grid_overlay = overlay
	overlay.player = players[0]
	return {"world": world, "bm": bm, "players": players, "enemies": enemies, "grid": overlay, "db": db}

func _dispose(arena: Dictionary):
	arena.world.queue_free()
	await process_frame

func _finish_enemy_phase(bm):
	var deadline = Time.get_ticks_msec() + 3000
	while bm._enemy_sequence_running and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not bm._enemy_sequence_running, "Enemy phase completes without hanging")

func _run():
	root.get_node("CampaignManager").has_active_campaign = false
	await _test_turn_order()
	await _test_knockouts()
	await _test_actions_and_targets()
	await _test_support_clicks()
	await _test_evasion_and_occupancy()
	await _test_areas_and_terrain()
	print("COMBAT REGRESSIONS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)

func _test_turn_order():
	var a = _arena(2, 3)
	var bm = a.bm
	var p = a.players[0]
	p.mp = 10
	p.apply_status("burn", 3)
	bm.start_enemy_turn()
	check(bm.current_state == bm.State.ENEMY_TURN, "Player controls remain locked during enemy animation")
	bm.select_active_player_unit(a.players[1])
	check(bm.active_player_unit == p and bm.current_state == bm.State.ENEMY_TURN, "Squad selection cannot interrupt enemy phase")
	bm.start_enemy_turn() # Duplicate signals must not schedule a second enemy sequence.
	await _finish_enemy_phase(bm)
	for e in a.enemies:
		check(e.starts.size() == 1 and e.starts[0].state == bm.State.ENEMY_TURN and e.starts[0].round == 0, "Each enemy acts once before the next player round")
	check(bm.turn_count == 1 and p.starts == 1, "A whole enemy squad grants exactly one player turn")
	check(p.mp == 18 and p.status_effects[0].duration == 2, "MP regeneration and status duration tick once per squad round")
	await _dispose(a)

func _test_knockouts():
	var a = _arena()
	var doomed = a.enemies[0]
	doomed.hp = 1
	doomed.apply_status("burn", 2)
	doomed.apply_status("corrode", 2)
	a.bm.start_enemy_turn()
	await _finish_enemy_phase(a.bm)
	check(a.enemies[1].starts.size() == 1 and a.bm.turn_count == 1, "Enemy DoT knockout does not skip the remaining enemy or stall the phase")
	check(a.players[0].xp == 0, "Knockouts do not grant unsaved mid-battle XP")
	await process_frame
	check(not is_instance_valid(doomed), "Enemy killed by DoT is freed safely")
	await _dispose(a)
	a = _arena(1, 1)
	a.enemies[0].hp = 1
	a.enemies[0].apply_status("burn", 1)
	a.bm.start_enemy_turn()
	check(a.bm.current_state == a.bm.State.BATTLE_OVER and not a.bm._enemy_sequence_running, "Last enemy DoT knockout finishes the match without starting another round")
	await _dispose(a)
	a = _arena()
	var p = a.players[0]
	p.hp = 1
	p.apply_status("burn", 1)
	a.bm.start_player_turn()
	check(p.has_acted and p.moves_remaining == 0 and a.bm.active_player_unit == a.players[1], "Player DoT knockout hands control to a living squadmate")
	await _dispose(a)

func _test_actions_and_targets():
	var a = _arena()
	var p = a.players[0]
	var ally = a.players[1]
	var enemy = a.enemies[0]
	a.bm.current_state = a.bm.State.PLAYER_ACT
	p.has_acted = true
	await p.use_ability(0, enemy)
	check(p.mp == 100 and enemy.hp == 1000, "An already-used fighter cannot attack again")
	p.has_acted = false
	a.bm.active_player_unit = ally
	await p.use_ability(0, enemy)
	check(p.mp == 100, "An inactive squadmate cannot spend MP or attack")
	a.bm.active_player_unit = p
	a.bm.current_state = a.bm.State.ENEMY_TURN
	await p.use_ability(0, enemy)
	check(p.mp == 100, "Abilities cannot execute in enemy phase")
	p.facing_frame = 12
	p._process(0)
	check(p.facing_frame == 12, "Facing remains fixed during enemy attacks")
	a.bm.current_state = a.bm.State.PLAYER_ACT
	await p.use_ability(-1, enemy)
	await p.use_ability(0, ally)
	await p.use_ability(1, enemy)
	check(p.mp == 100 and ally.hp == 1000 and enemy.hp == 1000, "Negative slots, friendly fire, and healing enemies are rejected without cost")
	enemy.position = p.position + Vector2(64, 64)
	a.grid.valid_attack_tiles = [Vector2i(4, 5)]
	await p.use_ability(0, enemy)
	check(p.mp == 100 and not p.has_acted, "Cardinal attacks reject diagonals even with stale overlay tiles")
	enemy.position = p.position + Vector2(64, 0)
	a.grid.valid_attack_tiles = [Vector2i(17, 9)]
	await p.use_ability(0, enemy)
	check(p.mp == 85 and enemy.hp < 1000, "Correct form MP cost and current skill range apply despite stale overlay")
	check(a.bm.active_player_unit == ally and p.has_acted, "Successful action passes control to next ready squadmate")
	# Invalid artifact use must preserve both MP and charges.
	a.bm.active_player_unit = p
	a.bm.current_state = a.bm.State.PLAYER_ACT
	p.has_acted = false
	p.mp = 20
	p.artifact = {"ability_key": "Audit_Blast"}
	p.artifact_charges = 2
	for e in a.enemies:
		e.position = Vector2(1000, 600)
	await p.use_artifact()
	check(p.mp == 20 and p.artifact_charges == 2 and not p.has_acted, "Out-of-range artifacts cannot create MP refunds or waste charges")
	for e in a.enemies:
		e.hp = 0
	await p.use_ability(0)
	check(p.mp == 20 and not p.has_acted, "Missing live target does not spend MP")
	await _dispose(a)

func _test_support_clicks():
	var a = _arena()
	var p = a.players[0]
	var ally = a.players[1]
	ally.hp = 500
	a.bm.current_state = a.bm.State.PLAYER_ACT
	a.bm.team_resonance_buff = true
	p.select_ability(1)
	a.grid.attack_tile_clicked.connect(p.on_attack_tile_clicked)
	var selections: Array = []
	a.grid.ally_clicked.connect(func(unit): selections.append(unit))
	a.grid.hovered_tile = Vector2i(floor(ally.position / 64))
	var click = InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	a.grid._unhandled_input(click)
	while p.is_animating:
		await process_frame
	check(ally.hp == 530 and selections.is_empty(), "Clicking an ally with a support skill heals them instead of changing selection")
	check(a.bm.team_resonance_buff, "Healing does not consume the next offensive resonance boost")
	a.bm.current_state = a.bm.State.PLAYER_ACT
	a.bm.active_player_unit = p
	p.has_acted = false
	await p.use_ability(2, ally)
	check(ally.has_status("defense_buff") and not p.has_status("defense_buff"), "Support buffs apply to the selected ally")
	a.bm.current_state = a.bm.State.PLAYER_ACT
	a.bm.active_player_unit = p
	p.has_acted = false
	ally.apply_status("burn", 2)
	await p.use_ability(3, ally)
	check(not ally.has_status("burn") and ally.has_status("defense_buff"), "Cleanse removes harmful statuses and preserves buffs")
	a.bm.current_state = a.bm.State.PLAYER_ACT
	a.bm.active_player_unit = p
	p.has_acted = false
	p.select_ability(1)
	check(a.grid.valid_attack_tiles.has(Vector2i(floor(p.position / 64))), "Support targeting includes the caster's tile")
	await _dispose(a)

func _test_evasion_and_occupancy():
	var a = _arena()
	var p = a.players[0]
	var e = a.enemies[0]
	a.bm.current_state = a.bm.State.PLAYER_ACT
	e.evade_all = true
	await p.use_ability(0, e)
	check(e.hp == 1000 and e.status_effects.is_empty() and a.bm.recent_elemental_actions.is_empty(), "Evaded player attacks cannot apply burn or trigger elemental fusion")
	p.evade_all = true
	p.hp = 500
	e.ability_pool = [{"name": "Test Burn", "damage": 20, "mp_cost": 0, "range": 5, "accuracy": 100, "effect": "burn", "element": "fire"}]
	a.bm._enemy_sequence_running = true
	await e._act()
	check(p.hp == 500 and p.status_effects.is_empty() and a.bm.recent_elemental_actions.is_empty(), "Evaded enemy attacks cannot apply burn or trigger elemental fusion")
	a.bm._enemy_sequence_running = false
	p.has_acted = false
	a.bm.current_state = a.bm.State.PLAYER_MOVE
	a.bm.active_player_unit = p
	a.grid.show_move_grid(p.position, 3)
	var original = p.position
	p.on_move_tile_clicked(Vector2i(floor(e.position / 64)), 1)
	check(p.position == original, "Player movement cannot enter an occupied tile")
	# Enemy is at (4,4), target at (1,4), blocker at (3,4).
	p.position = Vector2(96, 288)
	a.players[1].position = Vector2(32, 608)
	a.enemies[1].position = Vector2(224, 288)
	e.moves_remaining = 1
	e.ability_pool = []
	original = e.position
	a.bm._enemy_sequence_running = true
	await e._move_toward_player()
	check(e.position != a.enemies[1].position and e.position != p.position and e.position != a.players[1].position,
		"Enemy movement cannot overlap another combatant while repositioning")
	a.bm._enemy_sequence_running = false
	e.evade_all = false
	e.is_braced_guard = true
	var before = e.hp
	var dealt = e.take_damage(20, Vector2.ZERO, 20, 100, true)
	check(dealt == before - e.hp and dealt == 13, "Enemy damage result reports actual post-block damage")
	await _dispose(a)

func _test_areas_and_terrain():
	var a = _arena()
	var terrain = load("res://scripts/battle_terrain.gd").new()
	a.world.add_child(terrain)
	a.bm.terrain = terrain
	a.grid.terrain = terrain
	var p = a.players[0]
	var real_skills = load("res://scripts/element_data.gd").new()
	a.world.add_child(real_skills)
	p.element_db = real_skills
	p.equipped_abilities = ["Thermal_Radiation"]
	p.active_skill_forms["Thermal_Radiation"] = "furnace_zone"
	a.bm.current_state = a.bm.State.PLAYER_ACT
	await p.use_ability(0, a.enemies[0])
	check(a.enemies[0].hp < 1000 and a.enemies[1].hp < 1000,
		"Furnace Zone damages multiple enemies inside its radial pattern")
	check(terrain.hazards.has(Vector2i(4, 4)) and terrain.hazards[Vector2i(4, 4)]["kind"] == "fire",
		"Furnace Zone leaves persistent fire on the impacted arena")
	await _dispose(a)
	a = _arena()
	terrain = load("res://scripts/battle_terrain.gd").new()
	a.world.add_child(terrain)
	a.bm.terrain = terrain
	a.grid.terrain = terrain
	p = a.players[0]
	real_skills = load("res://scripts/element_data.gd").new()
	a.world.add_child(real_skills)
	p.element_db = real_skills
	p.equipped_abilities = ["Stone_Plating"]
	p.active_skill_forms["Stone_Plating"] = "rock_pillar"
	a.bm.current_state = a.bm.State.PLAYER_ACT
	await p.use_ability(0, null, Vector2i(5, 4))
	check(terrain.is_blocked(Vector2i(5, 4)) and not terrain.is_blocked(Vector2i(5, 3)),
		"Rock Pillar creates one durable obstacle on the aimed empty square")
	await _dispose(a)
