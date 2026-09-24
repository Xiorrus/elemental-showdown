extends CharacterBody2D
const AbilityGeometryScript = preload("res://scripts/ability_geometry.gd")
const ForceMovementResolverScript = preload("res://scripts/force_movement_resolver.gd")
const AttackIntentScript = preload("res://scripts/attack_intent.gd")
const ReactionResolverScript = preload("res://scripts/reaction_resolver.gd")

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Enemy
#  Now element-driven: stats and ability pool come from ElementData.
#  AI: move toward player → pick best in-range ability → account for MP.
# ──────────────────────────────────────────────

const TILE_SIZE = 64
const MP_REGEN_PER_TURN = 6

var character_name: String = ""
var element: String = "water"       # Set by World before battle starts
var hp: int = 100
var max_hp: int = 100
var mp: int = 100
var max_mp: int = 100
var stamina: int = 100
var max_stamina: int = 100
var has_acted: bool = false:
	set(v):
		has_acted = v
		if sprite:
			sprite.modulate = Color(0.55, 0.55, 0.55, 1.0) if has_acted else Color.WHITE
var agility: int = 24
var dexterity: int = 26
var defense: int = 20
var base_speed: int = 2
var moves_remaining: int = 0
var stamina_cost_per_tile: int = 10
var is_braced_guard: bool = false

# Loaded from ElementData at _ready
var ability_pool: Array = []        # Array of ability dicts
var _planned_position_score: float = -99999.0
var status_effects: Array = []

var tex_walk: Texture2D = null
var tex_attack: Texture2D = null

@onready var sprite: Sprite2D = $Sprite2D
var is_animating: bool = false

var battle_manager = null
var player = null
var ui = null
var element_db = null

var facing_frame: int = 8            # 0=Down, 4=Right, 8=Left, 12=Up
var facing_flip_h: bool = false

func set_appearance(sheet_prefix: String):
	var walk_path = "res://assets/" + sheet_prefix + "_walk.png"
	var attack_path = "res://assets/" + sheet_prefix + "_attack.png"
	if ResourceLoader.exists(walk_path):
		tex_walk = load(walk_path)
	if ResourceLoader.exists(attack_path):
		tex_attack = load(attack_path)
	if sprite:
		if tex_walk:
			sprite.texture = tex_walk
		sprite.offset = Vector2(0, -6)

# ──────────────────────────────────────────────
func _ready():
	add_to_group("enemies")
	add_to_group("combatants")
	element_db = get_node_or_null("/root/ElementData")

	# Setup modular appearance - start facing left toward player
	set_appearance("enemy")
	if sprite:
		if tex_walk:
			sprite.texture = tex_walk
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.frame = 8
		sprite.flip_h = false
		sprite.offset = Vector2(0, -6)  # Standardized 64x64 tactical grid alignment
		sprite.modulate = Color.WHITE  # Clear yellow template tint

	apply_element_stats(element)
	print("[Enemy] Ready | Element: %s | HP: %d | MP: %d" % [element, max_hp, max_mp])

func apply_element_stats(elem: String = ""):
	if elem != "":
		element = elem.to_lower()
	if element_db == null:
		element_db = get_node_or_null("/root/ElementData")
	if element_db and element_db.ELEMENTS.has(element):
		var edata = element_db.ELEMENTS[element]
		base_speed  = edata.get("base_speed", 2)
		max_hp      = edata.get("base_hp", 100)
		max_mp      = edata.get("base_mp", 100)
		max_stamina = edata.get("base_stamina", 100)
		agility     = edata.get("base_agility", 24)
		dexterity   = edata.get("base_dexterity", 26)
		defense     = edata.get("base_defense", 20)
		hp          = max_hp
		mp          = max_mp
		stamina     = max_stamina
		moves_remaining = base_speed

		# Give AI access to each unlocked form. Forms are distinct tactical options:
		# a melee strike, a ranged line, or an area attack can share one skill.
		ability_pool.clear()
		var keys = edata.get("skill_pool", [])
		var loaded_skills := 0
		for key in keys:
			if element_db.ABILITIES.has(key):
				var ab = element_db.ABILITIES[key].duplicate()
				ab["key"] = key
				if ab["tier"] == "basic" or ab["tier"] == "advanced":
					var forms: Dictionary = ab.get("forms", {})
					if forms.is_empty():
						ability_pool.append(ab)
					else:
						for form in forms.values():
							var option: Dictionary = ab.duplicate(true)
							option["name"] = form.get("name", ab["name"])
							option["range"] = AbilityGeometryScript.effective_reach(str(option["name"]), int(form.get("range", ab["range"])))
							option["range_band"] = AbilityGeometryScript.preferred_band(str(option["name"]), int(option["range"]))
							option["damage"] = int(round(ab.get("damage", 0) * form.get("dmg_mult", 1.0)))
							option["mp_cost"] = int(round(ab.get("mp_cost", 0) * form.get("mp_mult", 1.0)))
							option["effect"] = form.get("effect", ab.get("effect", ""))
							option["shape"] = AbilityGeometryScript.shape_for(option["name"], form.get("shape", "cardinal"))
							option["terrain_kind"] = form.get("terrain_kind", "")
							option["terrain_duration"] = form.get("terrain_duration", 0)
							ability_pool.append(option)
					loaded_skills += 1
			if loaded_skills >= 4:
				break

func apply_career_scaling(division_tier: int, season_number: int) -> void:
	# Reapply only after apply_element_stats: that method resets elemental bases.
	# Division matters most; later seasons add gradual growth with a firm cap.
	var tier_bonus := maxi(0, division_tier - 1)
	var season_bonus := mini(8, maxi(0, season_number - 1))
	var hp_factor := 1.0 + tier_bonus * 0.10 + season_bonus * 0.025
	var damage_factor := 1.0 + tier_bonus * 0.08 + season_bonus * 0.02
	max_hp = int(round(max_hp * hp_factor))
	hp = max_hp
	max_mp = int(round(max_mp * (1.0 + tier_bonus * 0.06 + season_bonus * 0.015)))
	mp = max_mp
	defense += tier_bonus * 2 + int(season_bonus / 2)
	agility += tier_bonus * 2 + season_bonus
	dexterity += tier_bonus * 2 + season_bonus
	for ability in ability_pool:
		if ability.has("damage") and int(ability["damage"]) > 0:
			ability["damage"] = int(round(int(ability["damage"]) * damage_factor))

# ──────────────────────────────────────────────
#  DAMAGE / STATUS
# ──────────────────────────────────────────────


func get_facing_vector() -> Vector2:
	match facing_frame:
		0: return Vector2(0, 1)   # Down / Front
		4: return Vector2(1, 0)   # Right
		8: return Vector2(-1, 0)  # Left
		12: return Vector2(0, -1) # Up / Back
		_: return Vector2(-1, 0)

func calculate_directional_hit(attacker_pos: Vector2, attacker_dex: int = 20, skill_acc: int = 90) -> Dictionary:
	var facing_vec = get_facing_vector()
	var to_attacker = (attacker_pos - position).normalized()
	var dot = facing_vec.dot(to_attacker)

	var angle_name = "front"
	var angle_mult = 1.0
	if dot > 0.35:
		angle_name = "front"
		angle_mult = 1.0
	elif dot >= -0.35:
		angle_name = "flank"
		angle_mult = 0.5
	else:
		angle_name = "rear"
		angle_mult = 0.05

	var sta_ratio = float(stamina) / float(max_stamina) if max_stamina > 0 else 1.0
	var sta_factor = 1.0
	if sta_ratio > 0.60:
		sta_factor = 1.0
	elif sta_ratio >= 0.20:
		sta_factor = 0.8
	elif sta_ratio > 0.0:
		sta_factor = 0.2
	else:
		sta_factor = 0.0

	var eff_agi = float(agility) + (20.0 if is_braced_guard else 0.0)
	var hit_chance = float(skill_acc) + (float(attacker_dex) * 0.75) - (eff_agi * angle_mult * sta_factor)
	hit_chance = clamp(hit_chance, 10.0, 100.0)
	var roll = randf_range(0.0, 100.0)
	return {
		"is_hit": (roll <= hit_chance),
		"hit_chance": hit_chance,
		"angle": angle_name,
		"angle_mult": angle_mult
	}

func recover_stamina(amt: int):
	stamina = min(max_stamina, stamina + amt)
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

func spend_stamina(amt: int) -> bool:
	if stamina >= amt:
		stamina -= amt
		if ui:
			ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
		return true
	stamina = 0
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	return false

func rest_turn(full_standby: bool = false):
	if full_standby:
		recover_stamina(int(max_stamina * 0.25))
		mp = min(max_mp, mp + int(max_mp * 0.25))
		is_braced_guard = true
		if ui:
			ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	else:
		recover_stamina(int(max_stamina * 0.15))

func apply_distance_falloff(base_damage: float, distance: int, optimal_range: int = 2) -> float:
	if distance > optimal_range:
		var falloff = 0.10 * float(distance - optimal_range)
		return base_damage * clamp(1.0 - falloff, 0.20, 1.0)
	return base_damage

func apply_knockback(source_pos: Vector2, distance_tiles: int = 1) -> bool:
	var bm = battle_manager if battle_manager else (get_parent().get_node_or_null("BattleManager") if get_parent() else null)
	var terrain_node = bm.terrain if (bm != null and "terrain" in bm) else null
	var result = ForceMovementResolverScript.resolve_push(self, source_pos, distance_tiles, get_tree(), terrain_node)
	return ForceMovementResolverScript.apply_resolved_push(result, ui, bm)

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, attacker_dex: int = 20, skill_acc: int = 90, is_unavoidable: bool = false, attacker_node: Node2D = null, skill_elem: String = ""):
	if hp <= 0 or is_queued_for_deletion() or amount <= 0:
		return 0
	var final_amount = amount
	var hit_angle = "front"

	if not is_unavoidable and attacker_pos != Vector2.ZERO:
		var res = calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
		if not res["is_hit"]:
			print("[Enemy] EVADED attack from %s! (Hit chance was %d%%)" % [res["angle"], int(res["hit_chance"])])
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "EVADED [%s]" % res["angle"].to_upper(), "status")
			return 0
		hit_angle = res["angle"]

	# Directional Critical & Braced Block / Riposte
	if hit_angle == "rear":
		final_amount = int(round(final_amount * 1.35))
		if ui and ui.has_method("spawn_damage_popup"):
			ui.spawn_damage_popup(position, "CRITICAL BACKSTAB! (+35%)", "status")
	elif hit_angle == "front" and is_braced_guard:
		final_amount = int(round(final_amount * 0.65))
		if ui and ui.has_method("spawn_damage_popup"):
			ui.spawn_damage_popup(position, "BRACED BLOCK (-35%)", "status")
		if attacker_node != null and is_instance_valid(attacker_node) and attacker_node.has_method("take_damage"):
			var dist_to_atk = (abs(attacker_node.position.x - position.x) + abs(attacker_node.position.y - position.y)) / TILE_SIZE
			if dist_to_atk <= 1.5:
				print("[Enemy] Riposte counter against %s!" % attacker_node.name)
				if ui and ui.has_method("spawn_damage_popup"):
					ui.spawn_damage_popup(attacker_node.position, "RIPOSTE COUNTER!", "status")
				if ui and ui.has_method("log_action"):
					ui.log_action("⚔️ [Enemy] Braced Guard ripostes %s for 15 dmg!" % attacker_node.name)
				attacker_node.take_damage(15, Vector2.ZERO, 30, 100, true)

	# Elemental Affinity & Weakness Exploitation
	if skill_elem != "" and element_db and element_db.has_method("get_elemental_multiplier"):
		var mult = element_db.get_elemental_multiplier(skill_elem, element)
		if mult > 1.0:
			final_amount = int(round(final_amount * mult))
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "WEAKNESS HIT! (+25%)", "status")
		elif mult < 1.0:
			final_amount = int(round(final_amount * mult))
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "RESISTED (-15%)", "status")

	# ReactionResolver: Guard check
	var bm = battle_manager if battle_manager else (get_parent().get_node_or_null("BattleManager") if get_parent() else null)
	if bm and "reaction_resolver" in bm and bm.reaction_resolver != null:
		var g_res = bm.reaction_resolver.evaluate_guard(self, final_amount)
		if g_res.get("guarded", false):
			final_amount = g_res["damage"]
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "GUARD (-30%)", "status")

	hp -= final_amount
	hp = max(hp, 0)
	print("[Enemy] Took %d damage → HP: %d/%d" % [final_amount, hp, max_hp])
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.08)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, final_amount, "damage", skill_elem)
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

	# ReactionResolver: Counter check
	if hp > 0 and bm and "reaction_resolver" in bm and bm.reaction_resolver != null and attacker_node != null and attacker_node != self:
		bm.reaction_resolver.trigger_counter(self, attacker_node, ui)

	if hp <= 0:
		print("[Enemy] Defeated!")
		if ui and ui.has_method("trigger_screen_shake"):
			ui.trigger_screen_shake(12.0, 0.35)
		if ui and ui.has_method("trigger_hit_stop"):
			ui.trigger_hit_stop(60.0)
		if battle_manager and battle_manager.has_method("record_knockout"):
			battle_manager.record_knockout(self)
		# Check if all enemies defeated
		var remaining = []
		if is_inside_tree():
			for node in get_tree().get_nodes_in_group("enemies"):
				if is_instance_valid(node) and node != self and not node.is_queued_for_deletion() and ("hp" not in node or node.hp > 0):
					remaining.append(node)

		if remaining.is_empty():
			if battle_manager:
				battle_manager.enemy = null
				battle_manager.call_deferred("player_wins")
		else:
			if battle_manager and battle_manager.enemy == self:
				battle_manager.enemy = remaining[0]

		queue_free()
	return final_amount

func declare_reaction(reaction_type: String, target_ally: Node2D = null) -> bool:
	var bm = battle_manager if battle_manager else (get_parent().get_node_or_null("BattleManager") if get_parent() else null)
	if bm and "reaction_resolver" in bm and bm.reaction_resolver != null:
		var ok = bm.reaction_resolver.declare_reaction(self, reaction_type, target_ally)
		if ok:
			has_acted = true
			var e_name = character_name if ("character_name" in self and character_name != "") else name
			if ui and ui.has_method("log_action"):
				ui.log_action("🛡️ [ORDER] %s assumes %s stance!" % [e_name, reaction_type.to_upper()])
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, reaction_type.to_upper(), "status")
		return ok
	return false

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	print("[Enemy] Healed %d → HP: %d/%d" % [amount, hp, max_hp])
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(0.4, 2.0, 0.4), 0.08)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, amount, "heal")
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

func apply_status(effect_name: String, duration: int, value: float = 0.0):
	status_effects.append({"name": effect_name, "duration": duration, "value": value})
	print("[Enemy] Status: %s (%d turns)" % [effect_name, duration])

func has_status(effect_name: String) -> bool:
	for s in status_effects:
		if s["name"] == effect_name:
			return true
	return false

func tick_status_effects():
	var remaining = []
	for s in status_effects:
		if hp <= 0:
			break
		if s.get("duration", 0) > 0:
			# Apply DoT effects while active
			if s["name"] == "burn":
				take_damage(8)
			elif s["name"] == "corrode":
				take_damage(5)
			s["duration"] -= 1
			if s["duration"] > 0:
				remaining.append(s)
	status_effects = remaining

func _regen_mp():
	mp = min(mp + MP_REGEN_PER_TURN, max_mp)

# ──────────────────────────────────────────────
#  TURN AI
# ──────────────────────────────────────────────

func take_turn():
	has_acted = false
	tick_status_effects()
	_regen_mp()
	if hp <= 0:
		return
	moves_remaining = base_speed

	var target_player = get_best_tactical_target()
	if target_player == null:
		_end_turn()
		return
	var current_score: float = float(_best_attack_from(AbilityGeometryScript.tile_of(position)).get("score", 0.0))
	var step: Vector2i = _best_tactical_step(target_player, [])
	if current_score > 0.0 and (step.x < 0 or _planned_position_score <= current_score * 1.05 + 1.0):
		await _act()
		return
	await _move_toward_player()

func get_player_targets() -> Array:
	var targets: Array = []
	if is_inside_tree():
		for node in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(node) and ("hp" not in node or node.hp > 0):
				targets.append(node)
	if targets.is_empty() and player and is_instance_valid(player) and ("hp" not in player or player.hp > 0):
		targets.append(player)
	return targets

func get_closest_player_target() -> Node2D:
	var targets = get_player_targets()
	var closest: Node2D = null
	var min_dist: float = 999999.0
	for t in targets:
		var d = position.distance_to(t.position)
		if d < min_dist:
			min_dist = d
			closest = t
	return closest

func get_best_tactical_target() -> Node2D:
	var targets = get_player_targets()
	if targets.is_empty():
		return null
	if targets.size() == 1:
		return targets[0]

	var best_target: Node2D = null
	var best_score: float = -999.0
	for t in targets:
		var d = (abs(position.x - t.position.x) + abs(position.y - t.position.y)) / TILE_SIZE
		var t_hp = float(t.hp) if "hp" in t else 100.0
		var t_max = float(t.max_hp) if "max_hp" in t else 100.0
		var hp_ratio = t_hp / max(1.0, t_max)

		var score = 100.0 - (d * 10.0)
		if hp_ratio <= 0.35:
			score += 50.0  # Focus-fire vulnerable target
		if "element" in t and element_db and element_db.has_method("is_elemental_weakness"):
			if element_db.is_elemental_weakness(element, t.element):
				score += 30.0  # Elemental weakness matchup advantage
		if "status_effects" in t and not t.status_effects.is_empty():
			score += 15.0

		if score > best_score:
			best_score = score
			best_target = t

	return best_target if best_target else targets[0]

func _targets_for_ability(ability: Dictionary, aimed_at: Node2D) -> Array:
	return _targets_for_ability_from(AbilityGeometryScript.tile_of(position), ability, aimed_at)

func _targets_for_ability_from(origin: Vector2i, ability: Dictionary, aimed_at: Node2D) -> Array:
	if aimed_at == null or not is_instance_valid(aimed_at): return []
	var aim: Vector2i = AbilityGeometryScript.tile_of(aimed_at.position)
	var facing: Vector2i = AbilityGeometryScript.direction_to(origin, aim)
	var shape: String = ability.get("shape", "cardinal")
	var tiles: Array[Vector2i] = AbilityGeometryScript.tiles(origin, facing, int(ability.get("range", 1)), shape)
	if not tiles.has(aim): return []
	if battle_manager and battle_manager.terrain and battle_manager.terrain.blocks_line(origin, aim): return []
	if not AbilityGeometryScript.is_multi_target(shape, str(ability.get("name", ""))): return [aimed_at]
	var victims: Array = []
	for fighter in get_player_targets():
		if tiles.has(AbilityGeometryScript.tile_of(fighter.position)) and not (battle_manager and battle_manager.terrain and battle_manager.terrain.blocks_line(origin, AbilityGeometryScript.tile_of(fighter.position))):
			victims.append(fighter)
	return victims

func _expected_damage_from(tile: Vector2i, ability: Dictionary, victim: Node2D) -> float:
	var target_tile: Vector2i = AbilityGeometryScript.tile_of(victim.position)
	var distance: int = absi(tile.x - target_tile.x) + absi(tile.y - target_tile.y)
	var band: String = ability.get("range_band", AbilityGeometryScript.preferred_band(str(ability.get("name", "")), int(ability.get("range", 1))))
	var damage: float = float(ability.get("damage", 0)) * AbilityGeometryScript.range_multiplier(band, distance)
	if "element" in victim and element_db and element_db.has_method("get_elemental_multiplier"):
		damage *= float(element_db.get_elemental_multiplier(ability.get("element", element), victim.element))
	var facing := Vector2.LEFT
	if victim.has_method("get_facing_vector"): facing = victim.get_facing_vector()
	var attacker_pos := Vector2(tile.x * TILE_SIZE + TILE_SIZE / 2, tile.y * TILE_SIZE + TILE_SIZE / 2)
	var angle: float = facing.dot((attacker_pos - victim.position).normalized())
	var evasion_factor := 1.0 if angle > 0.35 else (0.5 if angle >= -0.35 else 0.05)
	if angle < -0.35: damage *= 1.35
	if angle > 0.35 and "is_braced_guard" in victim and victim.is_braced_guard: damage *= 0.65
	var agility_value: float = float(victim.agility) if "agility" in victim else 24.0
	var accuracy: float = float(ability.get("accuracy", 90))
	if battle_manager and battle_manager.terrain:
		accuracy -= battle_manager.terrain.accuracy_penalty(tile, target_tile)
	var hit_chance: float = clampf((accuracy + float(dexterity) * 0.75 - agility_value * evasion_factor) / 100.0, 0.10, 1.0)
	return damage * hit_chance

func _best_attack_from(tile: Vector2i) -> Dictionary:
	var best: Dictionary = {}
	for target in get_player_targets():
		for ability in ability_pool:
			if int(ability.get("damage", 0)) <= 0 or mp < int(ability.get("mp_cost", 0)): continue
			var victims: Array = _targets_for_ability_from(tile, ability, target)
			if not victims.has(target): continue
			var score := 0.0
			for victim in victims:
				score += _expected_damage_from(tile, ability, victim)
			if ability.get("effect", "") in ["stun", "freeze", "control", "blind", "knockback"]:
				score += 8.0
			if score > float(best.get("score", -1.0)):
				best = {"ability": ability, "target": target, "score": score}
	return best

func _find_lethal_action() -> Dictionary:
	var targets = get_player_targets()
	var candidates: Array = []

	for target in targets:
		var target_hp = target.hp if "hp" in target else 9999
		for ability in ability_pool:
			var cost: int = ability.get("mp_cost", 0)
			var eff_dmg: int = int(round(_expected_damage_from(AbilityGeometryScript.tile_of(position), ability, target)))

			# Must afford MP, be in range, deal strictly positive damage, and deal >= target HP
			if mp >= cost and _targets_for_ability(ability, target).has(target) and eff_dmg > 0 and eff_dmg >= target_hp:
				candidates.append({
					"ability": ability,
					"target": target,
					"effective_dmg": eff_dmg
				})

	if candidates.is_empty():
		return {}

	# If multiple lethal abilities exist, select lowest MP cost, break ties with higher damage
	candidates.sort_custom(func(a, b):
		var cost_a = a["ability"].get("mp_cost", 0)
		var cost_b = b["ability"].get("mp_cost", 0)
		if cost_a != cost_b:
			return cost_a < cost_b
		return a["effective_dmg"] > b["effective_dmg"]
	)

	return candidates[0]

func _move_toward_player(visited: Array = []):
	var target_player = get_best_tactical_target()
	if moves_remaining <= 0 or target_player == null:
		await _act()
		return
	var current_tile: Vector2i = AbilityGeometryScript.tile_of(position)
	var current_score: float = float(_best_attack_from(current_tile).get("score", 0.0))
	visited.append(current_tile)
	var best_tile: Vector2i = _best_tactical_step(target_player, visited)
	if best_tile.x < 0 or (current_score > 0.0 and _planned_position_score <= current_score * 1.05 + 1.0):
		await _act()
		return
	moves_remaining -= battle_manager.terrain.move_cost(best_tile) if battle_manager and battle_manager.terrain else 1
	var step := best_tile - current_tile
	await _play_walk_step(Vector2(step), Vector2(best_tile.x * TILE_SIZE + TILE_SIZE / 2, best_tile.y * TILE_SIZE + TILE_SIZE / 2))
	await _move_toward_player(visited)

func _best_tactical_step(target: Node2D, visited: Array) -> Vector2i:
	# Search the whole small arena for a reachable firing square, then take its
	# first step. This lets a squad route around occupied lanes and stone walls.
	var start: Vector2i = AbilityGeometryScript.tile_of(position)
	var occupied: Dictionary = {}
	for fighter in get_tree().get_nodes_in_group("combatants"):
		if fighter != self and is_instance_valid(fighter) and ("hp" not in fighter or fighter.hp > 0):
			occupied[AbilityGeometryScript.tile_of(fighter.position)] = true
	var frontier: Array[Vector2i] = [start]
	var cost: Dictionary = {start: 0}
	var first: Dictionary = {start: start}
	while not frontier.is_empty():
		var tile: Vector2i = frontier.pop_front()
		if int(cost[tile]) >= 12: continue
		for direction in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = tile + direction
			if next.x < 0 or next.x > 17 or next.y < 0 or next.y > 9 or occupied.has(next): continue
			if battle_manager and battle_manager.terrain and battle_manager.terrain.is_blocked(next): continue
			var step_cost: int = battle_manager.terrain.move_cost(next) if battle_manager and battle_manager.terrain else 1
			var new_cost: int = int(cost[tile]) + step_cost
			if new_cost > 12 or (cost.has(next) and int(cost[next]) <= new_cost): continue
			cost[next] = new_cost
			first[next] = next if tile == start else first[tile]
			frontier.append(next)
	var best_step := Vector2i(-1, -1)
	var best_score := -99999.0
	var has_current_attack: bool = not _best_attack_from(start).is_empty()
	for tile in cost:
		if tile == start: continue
		if has_current_attack and int(cost[tile]) > moves_remaining: continue
		var step: Vector2i = first[tile]
		if visited.has(step): continue
		var immediate_cost: int = battle_manager.terrain.move_cost(step) if battle_manager and battle_manager.terrain else 1
		if immediate_cost > moves_remaining: continue
		var score: float = _position_score(tile, target) - float(cost[tile]) * 0.5
		if score > best_score:
			best_score = score
			best_step = step
	_planned_position_score = best_score
	return best_step

func _position_score(tile: Vector2i, target: Node2D) -> float:
	var target_tile: Vector2i = AbilityGeometryScript.tile_of(target.position)
	var distance: int = abs(tile.x - target_tile.x) + abs(tile.y - target_tile.y)
	var attack: Dictionary = _best_attack_from(tile)
	if not attack.is_empty(): return float(attack["score"])
	return -float(distance) * 8.0

func _play_walk_step(direction: Vector2, target: Vector2):
	is_animating = true
	var base_frame = 0
	if direction == Vector2.DOWN:
		base_frame = 0      # Front (Down)
	elif direction == Vector2.RIGHT:
		base_frame = 4      # Right
	elif direction == Vector2.LEFT:
		base_frame = 8      # Left
	elif direction == Vector2.UP:
		base_frame = 12     # Up (Back view)

	facing_frame = base_frame
	facing_flip_h = false

	if sprite:
		if tex_walk:
			sprite.texture = tex_walk
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.flip_h = false
		sprite.offset = Vector2(0, -6)

	var tween = create_tween()
	tween.tween_property(self, "position", target, 0.32)

	for i in range(4):
		if sprite:
			sprite.frame = base_frame + i
		await get_tree().create_timer(0.08).timeout
	if tween.is_running(): await tween.finished

	if sprite:
		sprite.frame = base_frame
		sprite.offset = Vector2(0, -6)
	position = target
	spend_stamina(stamina_cost_per_tile)
	is_animating = false
	if battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null:
		var dest_tile = AbilityGeometryScript.tile_of(target)
		battle_manager.reaction_resolver.trigger_overwatch(self, dest_tile, get_tree(), ui)

func _act():
	# 1. First check for lethal kill shot opportunity
	var lethal_action = _find_lethal_action()
	if not lethal_action.is_empty():
		var chosen = lethal_action["ability"]
		var target = lethal_action["target"]
		var ab_elem = chosen.get("element", element)
		mp -= chosen["mp_cost"]
		mp = max(mp, 0)

		# Play attack animation facing target
		await _play_attack_anim(chosen, target.position)
		var damage: int = _strike_targets(chosen, target)
		var lethal_effect: String = chosen.get("effect", "")

		print("[Enemy] Lethal Action Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [chosen["name"], damage, lethal_effect, mp, max_mp])
		if ui:
			ui.log_action("[Enemy] [Lethal] %s → %d dmg" % [chosen["name"], max(0, damage)])
			ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
		_end_turn()
		return

	# 2. Support / Defense: low HP recovery or barrier
	if hp <= int(max_hp * 0.40):
		for ability in ability_pool:
			if mp >= ability.get("mp_cost", 0):
				var eff = ability.get("effect", "")
				var dmg = ability.get("damage", 0)
				if dmg < 0: # Healing ability like Aqua_Mend
					mp -= ability["mp_cost"]
					heal(abs(dmg))
					if ui:
						ui.log_action("[Enemy] [Sustain] %s recovered %d HP!" % [ability["name"], abs(dmg)])
					_end_turn()
					return
				elif eff == "barrier" or ability.get("name") == "Stone Plating":
					mp -= ability["mp_cost"]
					apply_status("barrier", 3, 20.0)
					if ui:
						ui.log_action("[Enemy] [Defense] %s activated barrier!" % ability["name"])
					_end_turn()
					return

	# 3. Use the same range and angle estimate that guided movement.
	var attack: Dictionary = _best_attack_from(AbilityGeometryScript.tile_of(position))
	if attack.is_empty():
		if await _attack_blocking_terrain():
			return
		if ui: ui.log_action("[Enemy] Out of range — waits.")
		_end_turn()
		return
	var chosen: Dictionary = attack["ability"]
	var target_player: Node2D = attack["target"]
	var ab_elem = chosen.get("element", element)
	mp -= chosen["mp_cost"]
	mp = max(mp, 0)

	# Play attack animation facing target
	await _play_attack_anim(chosen, target_player.position)

	var damage: int = _strike_targets(chosen, target_player)
	var effect: String = chosen.get("effect", "")

	print("[Enemy] Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [chosen["name"], damage, effect, mp, max_mp])
	if ui:
		ui.log_action("[Enemy] %s → %d dmg" % [chosen["name"], max(0, damage)])
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	_end_turn()

func _attack_blocking_terrain() -> bool:
	if not battle_manager or not battle_manager.terrain: return false
	var terrain = battle_manager.terrain
	var origin: Vector2i = AbilityGeometryScript.tile_of(position)
	var best: Dictionary = {}
	var best_score := -99999.0
	for tile in terrain.hazards:
		if not terrain.is_blocked(tile): continue
		for ability in ability_pool:
			if int(ability.get("damage", 0)) <= 0 or mp < int(ability.get("mp_cost", 0)): continue
			var element_key: String = ability.get("element", element)
			if terrain.hazards[tile]["kind"] == "fire" and not element_key in ["water", "ice"]: continue
			var facing: Vector2i = AbilityGeometryScript.direction_to(origin, tile)
			var area: Array[Vector2i] = AbilityGeometryScript.tiles(origin, facing, int(ability.get("range", 1)), ability.get("shape", "cardinal"))
			if not area.has(tile) or terrain.blocks_line(origin, tile): continue
			var score: float = float(ability.get("damage", 0)) - float(abs(tile.x - origin.x) + abs(tile.y - origin.y)) * 5.0
			if score > best_score:
				best_score = score
				best = {"tile": tile, "ability": ability}
	if best.is_empty(): return false
	var chosen: Dictionary = best["ability"]
	var target_tile: Vector2i = best["tile"]
	mp = maxi(0, mp - int(chosen.get("mp_cost", 0)))
	await _play_attack_anim(chosen, Vector2(target_tile.x * TILE_SIZE + TILE_SIZE / 2, target_tile.y * TILE_SIZE + TILE_SIZE / 2))
	terrain.react_to_attack(chosen.get("element", element), [target_tile], int(chosen.get("damage", 0)))
	if ui: ui.log_action("[Enemy] %s clears an obstacle." % chosen.get("name", "Attack"))
	_end_turn()
	return true

func _strike_targets(ability: Dictionary, aimed_at: Node2D) -> int:
	var total := 0
	var ab_elem: String = ability.get("element", element)
	var origin_tile: Vector2i = AbilityGeometryScript.tile_of(position)
	var target_tile: Vector2i = AbilityGeometryScript.tile_of(aimed_at.position)
	var facing: Vector2i = AbilityGeometryScript.direction_to(origin_tile, target_tile)
	var area: Array[Vector2i] = AbilityGeometryScript.tiles(origin_tile, facing, int(ability.get("range", 1)), ability.get("shape", "cardinal"))

	# ── Telegraphed Windup Check ─────────────────────────────────────────────
	var windup: int = int(ability.get("windup_rounds", 0))
	if windup > 0:
		var intent = AttackIntentScript.new(self, "enemy", ability.get("name", "Skill"), ability.get("name", "Skill"), ability, origin_tile, target_tile, area, windup)
		if battle_manager and battle_manager.has_method("queue_intent"):
			battle_manager.queue_intent(intent)
		var e_name = character_name if ("character_name" in self and character_name != "") else name
		if ui and ui.has_method("log_action"):
			ui.log_action("⚠️ [ENEMY WINDUP] %s charges %s! Danger zone marked!" % [e_name, ability.get("name")])
		return 0

	var victims = _targets_for_ability(ability, aimed_at)
	# Check Intercept reaction
	for i in range(victims.size()):
		var v = victims[i]
		if battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null:
			var interceptor = battle_manager.reaction_resolver.evaluate_intercept(v, get_tree())
			if interceptor != null:
				var int_name = interceptor.character_name if ("character_name" in interceptor and interceptor.character_name != "") else interceptor.name
				if ui and ui.has_method("log_action"):
					ui.log_action("🛡️ [INTERCEPT] %s steps in to protect their ally!" % int_name)
				victims[i] = interceptor

	for victim in victims:
		if not is_instance_valid(victim) or victim.is_queued_for_deletion() or ("hp" in victim and victim.hp <= 0): continue
		var accuracy: int = int(ability.get("accuracy", 90))
		if battle_manager and battle_manager.terrain:
			accuracy -= battle_manager.terrain.accuracy_penalty(origin_tile, AbilityGeometryScript.tile_of(victim.position))
		var victim_tile: Vector2i = AbilityGeometryScript.tile_of(victim.position)
		var distance: int = absi(victim_tile.x - origin_tile.x) + absi(victim_tile.y - origin_tile.y)
		var band: String = ability.get("range_band", AbilityGeometryScript.preferred_band(str(ability.get("name", "")), int(ability.get("range", 1))))
		var range_damage: int = int(round(int(ability.get("damage", 0)) * AbilityGeometryScript.range_multiplier(band, distance)))

		# Empowered boost for enemy
		if battle_manager and battle_manager.has_method("consume_empowered_boost"):
			var e_boost = battle_manager.consume_empowered_boost("enemy")
			if e_boost > 0.0:
				range_damage = int(round(range_damage * (1.0 + e_boost)))

		var dealt: int = victim.take_damage(range_damage, position, dexterity, accuracy, false, self, ab_elem)
		total += dealt
		if dealt > 0:
			var effect: String = ability.get("effect", "")
			if effect != "" and ("hp" not in victim or victim.hp > 0) and victim.has_method("apply_status"):
				victim.apply_status(effect, 2)
			if effect == "knockback" and ("hp" not in victim or victim.hp > 0) and victim.has_method("apply_knockback"):
				victim.apply_knockback(position, 1)
			if battle_manager and battle_manager.has_method("register_elemental_action"):
				battle_manager.register_elemental_action(self, ab_elem, victim)
	if battle_manager and battle_manager.terrain:
		battle_manager.terrain.react_to_attack(ab_elem, area, int(ability.get("damage", 0)))
		var terrain_kind: String = ability.get("terrain_kind", "")
		if terrain_kind != "":
			battle_manager.terrain.place_from_skill(terrain_kind, origin_tile, target_tile, int(ability.get("range", 1)), ability.get("shape", "cardinal"), int(ability.get("terrain_duration", 2)))
	return total

func _play_attack_anim(_ability: Dictionary, target_pos: Vector2):
	if sprite == null:
		return
	is_animating = true

	# Directional Attack Row Selection (F18)
	var delta = target_pos - position
	var attack_row = 0
	if abs(delta.x) >= abs(delta.y):
		attack_row = 1 if delta.x > 0 else 2  # 1=Right, 2=Left
	else:
		attack_row = 0 if delta.y > 0 else 3  # 0=Down, 3=Up

	facing_frame = attack_row * 4
	facing_flip_h = false

	if tex_attack:
		sprite.texture = tex_attack
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.flip_h = false  # All 4 directions explicitly animated
	sprite.offset = Vector2(0, -6)

	var base_frame = attack_row * 4
	for i in range(4):
		sprite.frame = base_frame + i
		await get_tree().create_timer(0.13).timeout
	await get_tree().create_timer(0.12).timeout

	if tex_walk:
		sprite.texture = tex_walk
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = facing_frame
	sprite.flip_h = false
	sprite.offset = Vector2(0, -6)
	is_animating = false

func _end_turn():
	has_acted = true
	if battle_manager:
		battle_manager.start_player_turn()
