extends Node

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Battle Manager
#  Manages: turn state, win/lose, XP rewards, match post-processing & game loop,
#  anytime substitutions for living combatants, and Blitz Steal interceptions.
# ──────────────────────────────────────────────

enum State {PLAYER_MOVE, PLAYER_ACT, ENEMY_TURN, BATTLE_OVER}

var current_state: State = State.PLAYER_MOVE
var enemy = null
var player = null
var turn_count: int = 0

# Multi-Unit Direct Squad Control
var player_units: Array = []
var enemy_units: Array = []
var active_player_unit: Node2D = null
var grid_overlay: Node2D = null

# Substitutions
var match_format: String = "3v3"
var max_subs: int = 1
var subs_remaining: int = 1
var knocked_out_units: Array = []

# Tiger's Mouth Blitz Steal
var is_blitz_active: bool = false

signal battle_ended(result)  # "victory" or "defeat"

func _ready():
	print("[BattleManager] Ready.")
	set_match_format(match_format)

func set_match_format(fmt: String):
	match_format = fmt
	if match_format == "3v3":
		max_subs = 1
		subs_remaining = 1
	elif match_format == "5v5":
		max_subs = 2
		subs_remaining = 2
	else:
		match_format = "1v1"
		max_subs = 0
		subs_remaining = 0

	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("update_sub_count"):
		ui.update_sub_count(subs_remaining)

func can_substitute(target_node: Node2D) -> bool:
	if subs_remaining <= 0 or target_node == null:
		return false
	if target_node in knocked_out_units:
		return false
	if "hp" in target_node and target_node.hp <= 0:
		return false
	return true

func record_knockout(target_node: Node2D):
	if target_node and not knocked_out_units.has(target_node):
		knocked_out_units.append(target_node)
		print("[BattleManager] [KNOCKOUT] %s is down! Slot locked (1 man down)." % target_node.name)
		var ui = get_parent().get_node_or_null("UI") if get_parent() else null
		if ui and ui.has_method("log_action"):
			ui.log_action("[KNOCKOUT] %s is down! Slot locked (1 man down)!" % target_node.name)
		if ui and ui.has_method("update_squad_bar"):
			ui.update_squad_bar()
		check_battle_end_conditions()

func substitute_fighter(outgoing_node: Node2D, incoming_data: Dictionary = {}) -> bool:
	if not can_substitute(outgoing_node):
		print("[BattleManager] Cannot substitute: either no subs remaining or combatant is KO'd!")
		return false

	subs_remaining -= 1
	print("[BattleManager] Substitution executed! %s subbed out. Remaining subs: %d" % [outgoing_node.name, subs_remaining])

	# 1. Clear any active grid overlays immediately (fixes movement & attack tile ghosting)
	if "grid_overlay" in outgoing_node and outgoing_node.grid_overlay != null:
		outgoing_node.grid_overlay.clear_grid()

	# Synchronize incoming attributes
	if "max_hp" in outgoing_node and incoming_data.has("max_hp"):
		outgoing_node.max_hp = incoming_data["max_hp"]
	if "hp" in outgoing_node:
		var cur_max_hp = outgoing_node.max_hp if "max_hp" in outgoing_node else 100
		outgoing_node.hp = incoming_data.get("hp", cur_max_hp)

	if "max_mp" in outgoing_node and incoming_data.has("max_mp"):
		outgoing_node.max_mp = incoming_data["max_mp"]
	if "mp" in outgoing_node:
		var cur_max_mp = outgoing_node.max_mp if "max_mp" in outgoing_node else 100
		outgoing_node.mp = incoming_data.get("mp", cur_max_mp)

	if "max_stamina" in outgoing_node and incoming_data.has("max_stamina"):
		outgoing_node.max_stamina = incoming_data["max_stamina"]
	if "stamina" in outgoing_node:
		var cur_max_sta = outgoing_node.max_stamina if "max_stamina" in outgoing_node else 100
		outgoing_node.stamina = incoming_data.get("stamina", cur_max_sta)

	if "base_speed" in outgoing_node:
		if incoming_data.has("base_speed"):
			outgoing_node.base_speed = incoming_data["base_speed"]
		elif incoming_data.has("speed"):
			outgoing_node.base_speed = incoming_data["speed"]

	if "agility" in outgoing_node and incoming_data.has("agility"):
		outgoing_node.agility = incoming_data["agility"]

	if "dexterity" in outgoing_node and incoming_data.has("dexterity"):
		outgoing_node.dexterity = incoming_data["dexterity"]

	if "equipped_abilities" in outgoing_node:
		var new_abilities = incoming_data.get("equipped_abilities", incoming_data.get("equipped_skills", []))
		if not new_abilities.is_empty():
			outgoing_node.equipped_abilities = new_abilities.duplicate()
			if "selected_ability_index" in outgoing_node:
				outgoing_node.selected_ability_index = 0

	if incoming_data.has("position"):
		outgoing_node.position = incoming_data["position"]
	if "element" in outgoing_node and incoming_data.has("element"):
		outgoing_node.element = incoming_data["element"]
	if outgoing_node.has_method("set_appearance"):
		outgoing_node.set_appearance(incoming_data.get("element", "fire"))
	if incoming_data.has("name"):
		outgoing_node.name = incoming_data["name"]

	# 2. Reset moves for fresh sub and refresh overlay for new position
	if outgoing_node.has_method("get_total_speed"):
		outgoing_node.moves_remaining = outgoing_node.get_total_speed()
	if "has_acted" in outgoing_node:
		outgoing_node.has_acted = false
	if "has_moved" in outgoing_node:
		outgoing_node.has_moved = false

	select_active_player_unit(outgoing_node)

	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	var edata = get_node_or_null("/root/ElementData")
	if ui:
		if ui.has_method("update_player_stats") and "hp" in outgoing_node:
			var u_hp = outgoing_node.hp
			var u_max_hp = outgoing_node.max_hp if "max_hp" in outgoing_node else 100
			var u_mp = outgoing_node.mp if "mp" in outgoing_node else 100
			var u_max_mp = outgoing_node.max_mp if "max_mp" in outgoing_node else 100
			var u_sta = outgoing_node.stamina if "stamina" in outgoing_node else 100
			var u_max_sta = outgoing_node.max_stamina if "max_stamina" in outgoing_node else 100
			ui.update_player_stats(u_hp, u_max_hp, u_mp, u_max_mp, u_sta, u_max_sta)
		if ui.has_method("update_abilities") and "equipped_abilities" in outgoing_node:
			ui.update_abilities(outgoing_node.equipped_abilities, edata)
			var sel_idx = outgoing_node.selected_ability_index if "selected_ability_index" in outgoing_node else 0
			ui.highlight_ability_slot(sel_idx)
		if ui.has_method("set_player_name") and "element" in outgoing_node:
			var node_n = outgoing_node.character_name if ("character_name" in outgoing_node and outgoing_node.character_name != "") else outgoing_node.name
			ui.set_player_name(node_n, outgoing_node.element)
		if ui.has_method("log_action"):
			var sub_n = outgoing_node.character_name if ("character_name" in outgoing_node and outgoing_node.character_name != "") else outgoing_node.name
			ui.log_action("[TACTICAL SUB] %s deployed (%d subs left)!" % [sub_n, subs_remaining])
		if ui.has_method("update_sub_count"):
			ui.update_sub_count(subs_remaining)
		if ui.has_method("update_squad_bar"):
			ui.update_squad_bar()
	return true

func select_active_player_unit(unit: Node2D):
	if unit == null or not is_instance_valid(unit) or ("hp" in unit and unit.hp <= 0):
		return
	if active_player_unit != null and is_instance_valid(active_player_unit) and active_player_unit != unit:
		if "grid_overlay" in active_player_unit and active_player_unit.grid_overlay != null:
			active_player_unit.grid_overlay.clear_grid()

	active_player_unit = unit
	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	var edata = get_node_or_null("/root/ElementData")

	if ui:
		ui._player_ref = unit
		if ui.has_method("update_player_stats"):
			var u_hp = unit.hp if "hp" in unit else 100
			var u_max_hp = unit.max_hp if "max_hp" in unit else 100
			var u_mp = unit.mp if "mp" in unit else 100
			var u_max_mp = unit.max_mp if "max_mp" in unit else 100
			var u_sta = unit.stamina if "stamina" in unit else 100
			var u_max_sta = unit.max_stamina if "max_stamina" in unit else 100
			ui.update_player_stats(u_hp, u_max_hp, u_mp, u_max_mp, u_sta, u_max_sta)
		if ui.has_method("update_moves"):
			ui.update_moves(unit.moves_remaining if "moves_remaining" in unit else 0)
		if ui.has_method("update_abilities") and "equipped_abilities" in unit:
			ui.update_abilities(unit.equipped_abilities, edata)
			ui.highlight_ability_slot(unit.selected_ability_index if "selected_ability_index" in unit else 0)
		if ui.has_method("set_player_name") and "element" in unit:
			var act_n = unit.character_name if ("character_name" in unit and unit.character_name != "") else unit.name
			ui.set_player_name(act_n, unit.element)
		if ui.has_method("update_squad_bar"):
			ui.update_squad_bar()

	var u_has_acted = unit.get("has_acted") if "has_acted" in unit else false
	var u_moves = unit.moves_remaining if "moves_remaining" in unit else 0

	if not u_has_acted:
		if u_moves > 0:
			current_state = State.PLAYER_MOVE
			if "grid_overlay" in unit and unit.grid_overlay != null:
				unit.grid_overlay.show_move_grid(unit.position, u_moves)
			_notify_ui_turn("Move [%s]: Select blue tile  |  Right-Click: Attack Phase" % unit.name, true)
		else:
			current_state = State.PLAYER_ACT
			if unit.has_method("_update_attack_range_display"):
				unit._update_attack_range_display()
			_notify_ui_turn("Attack [%s]: Select 1-4 skill, click target  |  Right-Click: Standby" % unit.name, true)
	else:
		_notify_ui_turn("[%s]: Action complete. Choose another squadmate." % unit.name, true)

func on_player_unit_acted(unit: Node2D):
	if "has_acted" in unit:
		unit.has_acted = true
	if check_battle_end_conditions():
		return

	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("update_squad_bar"):
		ui.update_squad_bar()

	# Find next ready player unit
	var next_unit = null
	for u in player_units:
		if is_instance_valid(u) and ("hp" not in u or u.hp > 0):
			var acted = u.get("has_acted") if "has_acted" in u else false
			if not acted:
				next_unit = u
				break

	if next_unit != null:
		select_active_player_unit(next_unit)
		if ui and ui.has_method("log_action"):
			ui.log_action("Ready: Commanded %s, now directing %s" % [unit.name, next_unit.name])
	else:
		if ui and ui.has_method("log_action"):
			ui.log_action("All squad units completed actions. Passing to enemy turn.")
		start_enemy_turn()

func end_squad_turn():
	if current_state == State.BATTLE_OVER or current_state == State.ENEMY_TURN:
		return
	print("[BattleManager] Squad turn manually concluded by player.")
	for u in player_units:
		if is_instance_valid(u) and ("hp" not in u or u.hp > 0):
			u.has_acted = true
	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("log_action"):
		ui.log_action("Squad turn ended. Remaining units take defensive standby.")
	start_enemy_turn()

func check_blitz_steal(arg1, arg2, arg3 = null, arg4 = null) -> bool:
	var a_spd = 0
	var a_agi = 0
	var d_spd = 0
	var d_agi = 0
	var attacker_sta = 100
	var attacker_node = null

	if arg3 != null and arg4 != null:
		# Called with (speed_blitzer, agi_blitzer, speed_defender, agi_defender)
		a_spd = int(arg1)
		a_agi = int(arg2)
		d_spd = int(arg3)
		d_agi = int(arg4)
	else:
		# Called with (defender_node, attacker_node)
		var defender = arg1
		var attacker = arg2
		if attacker == null or defender == null:
			return false
		attacker_node = attacker
		a_spd = attacker.get_total_speed() if attacker.has_method("get_total_speed") else (attacker.base_speed if "base_speed" in attacker else 3)
		d_spd = defender.get_total_speed() if defender.has_method("get_total_speed") else (defender.base_speed if "base_speed" in defender else 3)
		a_agi = attacker.agility if "agility" in attacker else 25
		d_agi = defender.agility if "agility" in defender else 25
		attacker_sta = attacker.stamina if "stamina" in attacker else 100

	var diff = (a_spd + a_agi) - (d_spd + d_agi)
	if diff >= 15 and attacker_sta >= 20:
		if attacker_node and "stamina" in attacker_node:
			attacker_node.stamina -= 20
		is_blitz_active = true
		print("[BattleManager] [BLITZ STEAL] Turn stolen (-20 STA)!")
		var ui = get_parent().get_node_or_null("UI") if get_parent() else null
		if ui:
			if ui.has_method("log_action"):
				ui.log_action("[BLITZ STEAL] Timeline intercepted!")
		return true
	return false

func start_player_turn():
	if current_state == State.BATTLE_OVER:
		return
	turn_count += 1
	current_state = State.PLAYER_MOVE
	print("[BattleManager] --- Turn %d: Player Move Phase ---" % turn_count)

	if player_units.is_empty() and player != null:
		player_units.append(player)

	for u in player_units:
		if is_instance_valid(u) and ("hp" not in u or u.hp > 0):
			u.has_acted = false
			u.has_moved = false
			if u.has_method("start_turn"):
				u.start_turn()

	var first_ready = null
	if player != null and is_instance_valid(player) and ("hp" not in player or player.hp > 0):
		first_ready = player
	else:
		for u in player_units:
			if is_instance_valid(u) and ("hp" not in u or u.hp > 0):
				first_ready = u
				break

	if first_ready != null:
		select_active_player_unit(first_ready)
	else:
		player_loses()
		return

	_notify_ui_turn("Move Phase: Select blue tile  |  Right-Click: Attack Phase", true)
	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("update_squad_bar"):
		ui.update_squad_bar()

func start_player_act():
	if current_state == State.BATTLE_OVER:
		return
	current_state = State.PLAYER_ACT
	print("[BattleManager] --- Player Act Phase ---")
	var acting_unit = active_player_unit if (active_player_unit != null and is_instance_valid(active_player_unit)) else player
	if acting_unit and acting_unit.has_method("start_act"):
		acting_unit.start_act()
	var uname = acting_unit.name if acting_unit else "Player"
	_notify_ui_turn("Attack [%s]: Select 1-4 skill, click target  |  Right-Click: End Turn" % uname, true)

func check_battle_end_conditions() -> bool:
	if current_state == State.BATTLE_OVER:
		return true

	var live_enemies = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(node) and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
				live_enemies.append(node)
	if live_enemies.is_empty():
		for node in enemy_units:
			if is_instance_valid(node) and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
				live_enemies.append(node)
	if live_enemies.is_empty() and enemy != null and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and ("hp" not in enemy or enemy.hp > 0):
		live_enemies.append(enemy)

	if live_enemies.is_empty():
		player_wins()
		return true

	var live_players = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(node) and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
				live_players.append(node)
	if live_players.is_empty():
		for node in player_units:
			if is_instance_valid(node) and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
				live_players.append(node)
	if live_players.is_empty() and player != null and is_instance_valid(player) and not player.is_queued_for_deletion() and ("hp" not in player or player.hp > 0):
		live_players.append(player)

	if live_players.is_empty():
		player_loses()
		return true

	return false

func start_enemy_turn():
	if current_state == State.BATTLE_OVER:
		return
	if check_battle_end_conditions():
		return

	current_state = State.ENEMY_TURN
	print("[BattleManager] --- Enemy Turn ---")

	if active_player_unit != null and is_instance_valid(active_player_unit) and "grid_overlay" in active_player_unit and active_player_unit.grid_overlay != null:
		active_player_unit.grid_overlay.clear_grid()

	for u in player_units:
		if is_instance_valid(u) and u.has_method("on_enemy_turn"):
			u.on_enemy_turn()
	if player != null and is_instance_valid(player) and player.has_method("on_enemy_turn"):
		player.on_enemy_turn()

	# Check for Blitz Steal from active player before enemy acts!
	var blitzer = active_player_unit if (active_player_unit != null and is_instance_valid(active_player_unit)) else player
	if not is_blitz_active and enemy != null and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and blitzer != null:
		if check_blitz_steal(enemy, blitzer):
			_notify_ui_turn("[Blitz Steal] Player attacks early!", true)
			start_player_turn()
			return

	is_blitz_active = false
	_notify_ui_turn("Enemy Turn — wait...", false)

	if enemy_units.is_empty() and enemy != null and is_instance_valid(enemy):
		enemy_units.append(enemy)

	var live_enemies: Array = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("enemies"):
			if is_instance_valid(node) and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
				if not live_enemies.has(node):
					live_enemies.append(node)
	if live_enemies.is_empty():
		for e in enemy_units:
			if is_instance_valid(e) and not e.is_queued_for_deletion() and ("hp" not in e or e.hp > 0):
				if not live_enemies.has(e):
					live_enemies.append(e)

	if live_enemies.is_empty():
		player_wins()
		return

	if live_enemies.size() == 1:
		live_enemies[0].take_turn()
	else:
		_run_enemies_sequence(live_enemies)

func _run_enemies_sequence(live_enemies: Array):
	for e in live_enemies:
		if current_state == State.BATTLE_OVER:
			return
		if is_instance_valid(e) and ("hp" not in e or e.hp > 0):
			var ui = get_parent().get_node_or_null("UI") if get_parent() else null
			if ui:
				if ui.has_method("set_enemy_name") and "element" in e:
					ui.set_enemy_name(e.name, e.element)
				if ui.has_method("update_enemy_stats"):
					var e_sta = e.stamina if "stamina" in e else 100
					var e_max_sta = e.max_stamina if "max_stamina" in e else 100
					ui.update_enemy_stats(e.hp, e.max_hp, e.mp, e.max_mp, e_sta, e_max_sta)
			e.take_turn()
			var anim_ticks = 0
			while is_instance_valid(e) and e.is_animating:
				await get_tree().create_timer(0.05).timeout
				anim_ticks += 1
				if anim_ticks >= 100:
					print("[BattleManager] Animation wait timeout for %s — force clearing is_animating" % e.name)
					e.is_animating = false
					break
			await get_tree().create_timer(0.2).timeout
			if check_battle_end_conditions():
				return

	if current_state != State.BATTLE_OVER:
		start_player_turn()

func player_wins():
	if current_state == State.BATTLE_OVER:
		return
	current_state = State.BATTLE_OVER
	print("[BattleManager] === VICTORY! (Turn %d) ===" % turn_count)
	if player and player.has_method("gain_xp"):
		player.gain_xp(60)

	var cm = get_node_or_null("/root/CampaignManager")
	if cm and cm.has_active_campaign:
		cm.record_match_result(true, 60)
		cm.save_campaign()

	_notify_ui_result(true, 60, turn_count)
	emit_signal("battle_ended", "victory")

func player_loses():
	if current_state == State.BATTLE_OVER:
		return
	current_state = State.BATTLE_OVER
	print("[BattleManager] === DEFEAT! (Turn %d) ===" % turn_count)

	var cm = get_node_or_null("/root/CampaignManager")
	if cm and cm.has_active_campaign:
		cm.record_match_result(false, 25)
		cm.save_campaign()

	_notify_ui_result(false, 25, turn_count)
	emit_signal("battle_ended", "defeat")

func _notify_ui_turn(label: String, is_player: bool):
	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("update_turn_indicator"):
		ui.update_turn_indicator(label, is_player)

func _notify_ui_result(victory: bool, xp_gained: int = 60, turns: int = 0):
	var ui = get_parent().get_node_or_null("UI") if get_parent() else null
	if ui and ui.has_method("show_battle_result"):
		ui.show_battle_result(victory, xp_gained, turns)
