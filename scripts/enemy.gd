extends CharacterBody2D

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Enemy
#  Now element-driven: stats and ability pool come from ElementData.
#  AI: move toward player → pick best in-range ability → account for MP.
# ──────────────────────────────────────────────

const TILE_SIZE = 64
const MP_REGEN_PER_TURN = 6

var element: String = "water"       # Set by World before battle starts
var hp: int = 100
var max_hp: int = 100
var mp: int = 100
var max_mp: int = 100
var stamina: int = 100
var max_stamina: int = 100
var agility: int = 24
var dexterity: int = 26
var base_speed: int = 2
var moves_remaining: int = 0
var stamina_cost_per_tile: int = 10
var is_braced_guard: bool = false

# Loaded from ElementData at _ready
var ability_pool: Array = []        # Array of ability dicts
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
		hp          = max_hp
		mp          = max_mp
		stamina     = max_stamina
		moves_remaining = base_speed

		# Load the first 4 basic abilities for this enemy
		ability_pool.clear()
		var keys = edata.get("skill_pool", [])
		for key in keys:
			if element_db.ABILITIES.has(key):
				var ab = element_db.ABILITIES[key].duplicate()
				ab["key"] = key
				if ab["tier"] == "basic" or ab["tier"] == "advanced":
					ability_pool.append(ab)
				if ability_pool.size() >= 4:
					break

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

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, attacker_dex: int = 20, skill_acc: int = 90, is_unavoidable: bool = false):
	if not is_unavoidable and attacker_pos != Vector2.ZERO:
		var res = calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
		if not res["is_hit"]:
			print("[Enemy] EVADED attack from %s! (Hit chance was %d%%)" % [res["angle"], int(res["hit_chance"])])
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "EVADED [%s]" % res["angle"].to_upper(), "status")
			return 0

	hp -= amount
	hp = max(hp, 0)
	print("[Enemy] Took %d damage → HP: %d/%d" % [amount, hp, max_hp])
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.08)
		tw.tween_property(sprite, "modulate", Color.WHITE, 0.08)
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, amount, "damage")
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	if hp <= 0:
		print("[Enemy] Defeated!")
		if battle_manager and battle_manager.has_method("record_knockout"):
			battle_manager.record_knockout(self)
		# Award XP to player
		var p = player if player else get_closest_player_target()
		if p and p.has_method("gain_xp"):
			p.gain_xp(40 + (base_speed * 5))

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
	return amount

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
	tick_status_effects()
	_regen_mp()
	if hp <= 0:
		return
	moves_remaining = base_speed

	var target_player = get_closest_player_target()
	if target_player != null:
		var diff = target_player.position - position
		var distance = (abs(diff.x) + abs(diff.y)) / TILE_SIZE
		var can_reach = false
		for ability in ability_pool:
			if distance <= ability.get("range", 0) and mp >= ability.get("mp_cost", 0):
				can_reach = true
				break
		if can_reach:
			print("[Enemy] Target within ability range (dist: %.0f) — skipping movement." % distance)
			_act()
			return

	print("[Enemy] Taking turn — moving toward player.")
	_move_toward_player()

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

func _find_lethal_action() -> Dictionary:
	var targets = get_player_targets()
	var candidates: Array = []

	for target in targets:
		var target_hp = target.hp if "hp" in target else 9999
		var diff = target.position - position
		var distance_to_target = (abs(diff.x) + abs(diff.y)) / TILE_SIZE

		for ability in ability_pool:
			var cost: int = ability.get("mp_cost", 0)
			var rng: int = ability.get("range", 0)
			var dmg: int = ability.get("damage", 0)

			# Must afford MP, be in range, deal strictly positive damage, and deal >= target HP
			if mp >= cost and distance_to_target <= rng and dmg > 0 and dmg >= target_hp:
				candidates.append({
					"ability": ability,
					"target": target
				})

	if candidates.is_empty():
		return {}

	# If multiple lethal abilities exist, select the one with the lowest MP cost (resource conservation; break ties with higher damage)
	candidates.sort_custom(func(a, b):
		var cost_a = a["ability"].get("mp_cost", 0)
		var cost_b = b["ability"].get("mp_cost", 0)
		if cost_a != cost_b:
			return cost_a < cost_b
		return a["ability"].get("damage", 0) > b["ability"].get("damage", 0)
	)

	return candidates[0]

func _move_toward_player():
	var target_player = get_closest_player_target()
	if moves_remaining <= 0 or target_player == null:
		_act()
		return

	var diff = target_player.position - position
	var direction = Vector2.ZERO

	if abs(diff.x) >= abs(diff.y):
		direction = Vector2.RIGHT if diff.x > 0 else Vector2.LEFT
	else:
		direction = Vector2.DOWN if diff.y > 0 else Vector2.UP

	var target = position + direction * TILE_SIZE
	var target_tile = Vector2i(int(floor(target.x / TILE_SIZE)), int(floor(target.y / TILE_SIZE)))

	# Stay strictly within 18x10 arena (cols 0..17, rows 0..9) and don't step onto target_player
	var can_move = target_tile.x >= 0 and target_tile.x <= 17 and \
				   target_tile.y >= 0 and target_tile.y <= 9 and \
				   (target - target_player.position).length() > 10

	if can_move:
		moves_remaining -= 1
		await _play_walk_step(direction, target)
		_move_toward_player()
	else:
		_act()

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
	tween.tween_property(self, "position", target, 0.16)

	for i in range(4):
		if sprite:
			sprite.frame = base_frame + i
		await get_tree().create_timer(0.04).timeout

	if sprite:
		sprite.frame = base_frame
		sprite.offset = Vector2(0, -6)
	position = target
	spend_stamina(stamina_cost_per_tile)
	is_animating = false

func _act():
	# 1. First check for lethal kill shot opportunity
	var lethal_action = _find_lethal_action()
	if not lethal_action.is_empty():
		var chosen = lethal_action["ability"]
		var target = lethal_action["target"]
		mp -= chosen["mp_cost"]
		mp = max(mp, 0)

		# Play attack animation facing target
		await _play_attack_anim(chosen, target.position)

		var damage = chosen["damage"]
		if damage > 0 and target.has_method("take_damage"):
			target.take_damage(damage, position, dexterity, chosen.get("accuracy", 90))

		# Apply status effect if any
		var lethal_effect = chosen.get("effect", "")
		if lethal_effect != "" and target.has_method("apply_status"):
			target.apply_status(lethal_effect, 2)

		print("[Enemy] Lethal Action Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [chosen["name"], damage, lethal_effect, mp, max_mp])
		if ui:
			ui.log_action("[Enemy] [Lethal] %s → %d dmg" % [chosen["name"], max(0, damage)])
			ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
		_end_turn()
		return

	# 2. Fall back to default combat ordering (highest damage among affordable in-range abilities)
	var target_player = get_closest_player_target()
	if target_player == null:
		_end_turn()
		return

	var diff = target_player.position - position
	var distance = (abs(diff.x) + abs(diff.y)) / TILE_SIZE

	var usable = []
	for ability in ability_pool:
		if distance <= ability["range"] and mp >= ability["mp_cost"]:
			usable.append(ability)

	if usable.is_empty():
		print("[Enemy] No ability in range — passing.")
		if ui:
			ui.log_action("[Enemy] Out of range — waits.")
		_end_turn()
		return

	# Sort by highest damage
	usable.sort_custom(func(a, b):
		return a["damage"] > b["damage"]
	)
	var chosen = usable[0]
	mp -= chosen["mp_cost"]
	mp = max(mp, 0)

	# Play attack animation facing target
	await _play_attack_anim(chosen, target_player.position)

	var damage = chosen["damage"]
	if damage > 0 and target_player.has_method("take_damage"):
		target_player.take_damage(damage, position, dexterity, chosen.get("accuracy", 90))

	# Apply status effect if any
	var effect = chosen.get("effect", "")
	if effect != "" and target_player.has_method("apply_status"):
		target_player.apply_status(effect, 2)

	print("[Enemy] Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [chosen["name"], damage, effect, mp, max_mp])
	if ui:
		ui.log_action("[Enemy] %s → %d dmg" % [chosen["name"], max(0, damage)])
	if ui:
		ui.update_enemy_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	_end_turn()

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
		await get_tree().create_timer(0.06).timeout

	if tex_walk:
		sprite.texture = tex_walk
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = facing_frame
	sprite.flip_h = false
	sprite.offset = Vector2(0, -6)
	is_animating = false

func _end_turn():
	if battle_manager:
		battle_manager.start_player_turn()
