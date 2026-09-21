extends CharacterBody2D

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Player
#  Implements: element system, XP/leveling, skill unlock offers,
#              mana regen, artifact slot, injury tracking
# ──────────────────────────────────────────────

const TILE_SIZE = 64
const XP_PER_LEVEL_BASE = 100       # XP needed for level 1→2
const XP_SCALE_FACTOR = 1.18        # Each level requires ~18% more XP
const MP_REGEN_PER_TURN = 8         # MP recovered at start of each player turn
const MAX_HP = 100                  # Overridden by element stats on _ready
const MAX_MP = 100

# ── Core stats ────────────────────────────────
var character_name: String = ""
var element: String = "fire"        # Set before _ready (or in World.tscn)
var hp: int = 100
var max_hp: int = 100
var mp: int = 100
var max_mp: int = 100
var stamina: int = 100
var max_stamina: int = 100
var agility: int = 28
var dexterity: int = 32
var base_speed: int = 3
var element_speed_bonus: int = 0
var ability_speed_bonus: int = 0
var item_speed_bonus: int = 0
var moves_remaining: int = 0
var stamina_cost_per_tile: int = 10
var is_braced_guard: bool = false
var tiles_moved_this_turn: int = 0
var has_moved: bool = false
var has_acted: bool = false:
	set(v):
		has_acted = v
		if sprite:
			sprite.modulate = Color(0.55, 0.55, 0.55, 1.0) if has_acted else Color.WHITE

# ── XP / Leveling ─────────────────────────────
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = XP_PER_LEVEL_BASE

# ── Skills ────────────────────────────────────
# Keys into ElementData.ABILITIES. Player starts with one starter ability.
var unlocked_abilities: Array = []
# The 4 abilities currently equipped (shown in UI, usable in combat)
var equipped_abilities: Array = []
var active_skill_forms: Dictionary = {}

# ── Artifact ──────────────────────────────────
var artifact: Dictionary = {}       # {} means no artifact equipped
var artifact_charges: int = 0

# ── Injury tracking ───────────────────────────
var injuries: Array = []            # Array of injury dicts

# ── Status effects ────────────────────────────
var status_effects: Array = []      # [{name, duration, value}]

var tex_walk: Texture2D = null
var tex_attack: Texture2D = null

@onready var sprite: Sprite2D = $Sprite2D
var is_animating: bool = false
var facing_frame: int = 4            # 0=Down, 4=Right, 8=Left, 12=Up
var facing_flip_h: bool = false

# ── References ────────────────────────────────
var battle_manager = null
var ui = null
var element_db = null              # Injected by World
var grid_overlay = null            # Injected by World
var selected_ability_index: int = 0

# ──────────────────────────────────────────────
func get_total_speed() -> int:
	return base_speed + element_speed_bonus + ability_speed_bonus + item_speed_bonus

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
	add_to_group("players")
	add_to_group("combatants")
	element_db = get_node_or_null("/root/ElementData")

	# Setup modular appearance - start facing right toward enemy
	set_appearance("player")
	if sprite:
		if tex_walk:
			sprite.texture = tex_walk
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.frame = 4
		sprite.flip_h = false
		sprite.offset = Vector2(0, -6)  # 64x64 tactical grid alignment
		sprite.modulate = Color.WHITE  # Reset red tint from scene template

	# Apply element base stats
	apply_element_stats(element)

	# Give starter ability (first basic skill of element).
	# Only auto-populate if no skills have been assigned yet — world.gd sets these
	# from CampaignManager after add_child(), so we must not overwrite them.
	if equipped_abilities.is_empty() and element_db and element_db.ELEMENTS.has(element):
		var pool = element_db.ELEMENTS[element]["skill_pool"]
		for key in pool:
			if element_db.ABILITIES[key]["tier"] == "basic":
				_unlock_ability(key)
				break

	moves_remaining = get_total_speed()
	var cm = get_node_or_null("/root/CampaignManager")
	var edata_init = element_db if element_db else get_node_or_null("/root/ElementData")
	for ab_k in equipped_abilities:
		if cm and cm.skill_variations.has(ab_k):
			active_skill_forms[ab_k] = cm.skill_variations[ab_k]
		elif edata_init:
			var f_keys = edata_init.get_skill_form_keys(ab_k)
			if not f_keys.is_empty():
				active_skill_forms[ab_k] = f_keys[0]
	print("[Player] Ready | Element: %s | HP: %d | MP: %d | Speed: %d" % [element, max_hp, max_mp, base_speed])

func apply_element_stats(elem: String = ""):
	if elem != "":
		element = elem.to_lower()
	if element_db == null:
		element_db = get_node_or_null("/root/ElementData")
	if element_db and element_db.ELEMENTS.has(element):
		var edata = element_db.ELEMENTS[element]
		base_speed   = edata.get("base_speed", 3)
		max_hp       = edata.get("base_hp", 100)
		max_mp       = edata.get("base_mp", 100)
		max_stamina  = edata.get("base_stamina", 100)
		agility      = edata.get("base_agility", 28)
		dexterity    = edata.get("base_dexterity", 32)
		hp           = max_hp
		mp           = max_mp
		stamina      = max_stamina
		moves_remaining = get_total_speed()

# ──────────────────────────────────────────────
#  ABILITY MANAGEMENT
# ──────────────────────────────────────────────

func _unlock_ability(key: String):
	if not unlocked_abilities.has(key):
		unlocked_abilities.append(key)
	# Auto-equip if we have fewer than 4 equipped
	if equipped_abilities.size() < 4 and not equipped_abilities.has(key):
		equipped_abilities.append(key)

func equip_ability(key: String):
	# Replaces last slot or adds if space
	if equipped_abilities.size() < 4:
		equipped_abilities.append(key)
	else:
		equipped_abilities[3] = key
	if ui:
		ui.update_abilities(equipped_abilities, element_db)

# ──────────────────────────────────────────────
#  XP / LEVEL UP
# ──────────────────────────────────────────────

func gain_xp(amount: int):
	xp += amount
	print("[Player] Gained %d XP (total: %d / %d)" % [amount, xp, xp_to_next_level])
	while xp >= xp_to_next_level:
		xp -= xp_to_next_level
		_level_up()
	if ui:
		ui.update_xp(level, xp, xp_to_next_level)

func _level_up():
	level += 1
	xp_to_next_level = int(XP_PER_LEVEL_BASE * pow(XP_SCALE_FACTOR, level - 1))
	# Small stat bonus per level
	max_hp += 3
	hp = min(hp + 3, max_hp)
	max_mp += 2
	print("[Player] LEVEL UP → Level %d! Next level at %d XP" % [level, xp_to_next_level])
	_trigger_skill_offer()

func _trigger_skill_offer():
	if not element_db:
		return
	var offers = element_db.get_skill_offers(element, unlocked_abilities, level)
	if offers.is_empty():
		print("[Player] No new skills available to offer.")
		return
	print("[Player] Skill offers: ", offers)
	if ui:
		ui.show_skill_offer(offers, element_db)
	else:
		# Fallback: auto-pick first offer
		_unlock_ability(offers[0])
		print("[Player] Auto-unlocked: ", offers[0])

func accept_skill_offer(key: String):
	_unlock_ability(key)
	print("[Player] Unlocked skill: %s" % key)
	if ui:
		ui.update_abilities(equipped_abilities, element_db)

# ──────────────────────────────────────────────
#  DAMAGE / HEALING / STATUS
# ──────────────────────────────────────────────


func get_facing_vector() -> Vector2:
	match facing_frame:
		0: return Vector2(0, 1)   # Down / Front
		4: return Vector2(1, 0)   # Right
		8: return Vector2(-1, 0)  # Left
		12: return Vector2(0, -1) # Up / Back
		_: return Vector2(1, 0)

func get_facing_direction() -> Vector2i:
	match facing_frame:
		0: return Vector2i(0, 1)   # Down
		4: return Vector2i(1, 0)   # Right
		8: return Vector2i(-1, 0)  # Left
		12: return Vector2i(0, -1) # Up
		_: return Vector2i(1, 0)

func get_ability_variation_info(key: String) -> Dictionary:
	var res = {
		"name": key,
		"form_key": "",
		"range_override": -1,
		"shape": "cardinal",
		"dmg_mult": 1.0,
		"mp_mult": 1.0
	}
	var edata = element_db
	if not edata and is_inside_tree():
		edata = get_node_or_null("/root/ElementData")
	if not edata:
		var ed_res = load("res://scripts/element_data.gd")
		if ed_res: edata = ed_res.new()
	if not edata or not edata.ABILITIES.has(key):
		return res

	var ab = edata.ABILITIES[key]
	var forms = ab.get("forms", {})
	if forms.is_empty():
		return res

	var current_f_key = active_skill_forms.get(key, "")
	if current_f_key == "":
		var cm = get_node_or_null("/root/CampaignManager") if is_inside_tree() else null
		if cm and cm.skill_variations.has(key):
			current_f_key = cm.skill_variations[key]
		else:
			current_f_key = forms.keys()[0]
		active_skill_forms[key] = current_f_key

	var f_info = {}
	if forms.has(current_f_key):
		f_info = forms[current_f_key]
		res["form_key"] = current_f_key
	else:
		# check if current_f_key was a name
		for fk in forms:
			if forms[fk].get("name", "").to_lower() == current_f_key.to_lower():
				f_info = forms[fk]
				res["form_key"] = fk
				break
		if f_info.is_empty():
			var first_k = forms.keys()[0]
			f_info = forms[first_k]
			res["form_key"] = first_k

	res["name"] = f_info.get("name", key)
	res["range_override"] = f_info.get("range", ab.get("range", 2))
	res["dmg_mult"] = f_info.get("dmg_mult", 1.0)
	res["mp_mult"] = f_info.get("mp_mult", 1.0)
	res["shape"] = f_info.get("shape", "cardinal")
	if f_info.get("is_radial", false):
		res["shape"] = "radial"
	elif f_info.get("desc", "").to_lower().contains("linear") or f_info.get("desc", "").to_lower().contains("forward"):
		res["shape"] = "linear_front"
	return res

func cycle_skill_form(slot_index: int):
	if slot_index < 0 or slot_index >= equipped_abilities.size():
		return
	var key = equipped_abilities[slot_index]
	var edata = element_db
	if not edata and is_inside_tree():
		edata = get_node_or_null("/root/ElementData")
	if not edata:
		var ed_res = load("res://scripts/element_data.gd")
		if ed_res: edata = ed_res.new()
	if not edata or not edata.ABILITIES.has(key):
		return

	var forms = edata.get_skill_forms(key)
	if forms.size() <= 1:
		if ui: ui.log_action("Skill [%s] has only 1 form." % key)
		return

	var cm = get_node_or_null("/root/CampaignManager") if is_inside_tree() else null
	var unlocked_forms = cm.get_unlocked_forms_for_skill(key) if cm else forms.keys()
	if unlocked_forms.size() <= 1:
		if ui: ui.log_action("[%s] only has 1 form unlocked. Unlock more in Skill Tree (-1 SP)!" % key)
		return

	var cur_info = get_ability_variation_info(key)
	var cur_f_key = cur_info.get("form_key", unlocked_forms[0])
	var cur_idx = unlocked_forms.find(cur_f_key)
	if cur_idx == -1:
		cur_idx = 0
	var next_idx = (cur_idx + 1) % unlocked_forms.size()
	var next_f_key = unlocked_forms[next_idx]

	active_skill_forms[key] = next_f_key
	if cm:
		cm.skill_variations[key] = next_f_key

	var new_info = get_ability_variation_info(key)
	var eff_r = new_info["range_override"] if new_info["range_override"] > 0 else edata.ABILITIES[key]["range"]
	var eff_mp = int(round(edata.ABILITIES[key]["mp_cost"] * new_info["mp_mult"]))

	if selected_ability_index == slot_index:
		_update_attack_range_display()

	if ui:
		ui.update_abilities(equipped_abilities, edata, self)
		ui.log_action("Shifted [%s] Form -> [%s] (Rng: %d, MP: %d, Shape: %s)" % [
			key, new_info["name"], eff_r, eff_mp, new_info["shape"].capitalize()
		])


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
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

func spend_stamina(amt: int) -> bool:
	if stamina >= amt:
		stamina -= amt
		if ui:
			ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
		return true
	stamina = 0
	if ui:
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	return false

func rest_turn(full_standby: bool = false):
	if full_standby:
		recover_stamina(int(max_stamina * 0.25))
		mp = min(max_mp, mp + int(max_mp * 0.25))
		is_braced_guard = true
		if ui:
			ui.log_action("Standby: +25% STA/MP, Braced Guard (+20 AGI)")
			ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	else:
		recover_stamina(int(max_stamina * 0.15))
		if ui:
			ui.log_action("Paced Breath: +15% STA")

func apply_distance_falloff(base_damage: float, distance: int, optimal_range: int = 2) -> float:
	if distance > optimal_range:
		var falloff = 0.10 * float(distance - optimal_range)
		return base_damage * clamp(1.0 - falloff, 0.20, 1.0)
	return base_damage

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, attacker_dex: int = 20, skill_acc: int = 90, is_unavoidable: bool = false):
	if not is_unavoidable and attacker_pos != Vector2.ZERO:
		var res = calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
		if not res["is_hit"]:
			print("[Player] EVADED attack from %s! (Hit chance was %d%%)" % [res["angle"], int(res["hit_chance"])])
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "EVADED [%s]" % res["angle"].to_upper(), "status")
			return 0

	var final_amount = amount
	hp -= final_amount
	hp = max(hp, 0)
	print("[Player] Took %d damage → HP: %d/%d" % [final_amount, hp, max_hp])
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.08)
		var rest_color = Color(0.55, 0.55, 0.55, 1.0) if has_acted else Color.WHITE
		tw.tween_property(sprite, "modulate", rest_color, 0.08)
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, final_amount, "damage")
	if ui:
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	if hp <= 0:
		if battle_manager and battle_manager.has_method("record_knockout"):
			battle_manager.record_knockout(self)
		_on_defeated()
	return final_amount

func heal(amount: int):
	hp = min(hp + amount, max_hp)
	print("[Player] Healed %d → HP: %d/%d" % [amount, hp, max_hp])
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, amount, "heal")
	if ui:
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

func spend_mp(amount: int) -> bool:
	if mp >= amount:
		mp -= amount
		if ui:
			ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
		return true
	return false

func regen_mp():
	mp = min(mp + MP_REGEN_PER_TURN, max_mp)
	print("[Player] MP regen → MP: %d/%d" % [mp, max_mp])
	if ui:
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

func apply_status(effect_name: String, duration: int, value: float = 0.0):
	status_effects.append({"name": effect_name, "duration": duration, "value": value})
	print("[Player] Status applied: %s (%d turns)" % [effect_name, duration])

func tick_status_effects():
	var remaining = []
	for s in status_effects:
		if s.get("duration", 0) > 0:
			# Apply DoT effects
			if s["name"] == "burn":
				take_damage(8)
			elif s["name"] == "corrode":
				take_damage(5)
			s["duration"] -= 1
			if s["duration"] > 0:
				remaining.append(s)
	status_effects = remaining

func has_status(effect_name: String) -> bool:
	for s in status_effects:
		if s["name"] == effect_name:
			return true
	return false

func _on_defeated():
	print("[%s] DEFEATED." % name)
	if battle_manager and not battle_manager.has_method("record_knockout"):
		battle_manager.player_loses()

# ──────────────────────────────────────────────
#  ARTIFACT
# ──────────────────────────────────────────────

func equip_artifact(artifact_dict: Dictionary):
	artifact = artifact_dict
	artifact_charges = artifact_dict.get("charges", 2)
	print("[Player] Artifact equipped: %s (%d charges)" % [artifact.get("name","?"), artifact_charges])

func use_artifact():
	if artifact.is_empty() or artifact_charges <= 0:
		print("[Player] No artifact or no charges.")
		return
	# Artifact costs ZERO MP per GDD — emergency tool
	artifact_charges -= 1
	var key = artifact.get("ability_key", "")
	print("[Player] Artifact fired: %s (charges left: %d)" % [artifact.get("name","?"), artifact_charges])
	if key != "" and element_db and element_db.ABILITIES.has(key):
		var ability = element_db.ABILITIES[key]
		_execute_ability(ability)
	if ui:
		ui.update_artifact(artifact, artifact_charges)

# ──────────────────────────────────────────────
#  MOVEMENT & GRID SELECTION
# ──────────────────────────────────────────────

func _unhandled_input(event):
	if is_animating or battle_manager == null:
		return
	if "active_player_unit" in battle_manager and battle_manager.active_player_unit != null and battle_manager.active_player_unit != self:
		return

	# Right click advances to next phase anywhere on screen
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		on_right_mouse_clicked()
		get_viewport().set_input_as_handled()
		return

	if battle_manager.current_state == battle_manager.State.PLAYER_MOVE:
		if event.is_action_pressed("end_move"):
			end_move_phase()

	elif battle_manager.current_state == battle_manager.State.PLAYER_ACT:
		if event.is_action_pressed("ability_1"):
			if event.shift_pressed:
				cycle_skill_form(0)
			else:
				select_ability(0)
		elif event.is_action_pressed("ability_2"):
			if event.shift_pressed:
				cycle_skill_form(1)
			else:
				select_ability(1)
		elif event.is_action_pressed("ability_3"):
			if event.shift_pressed:
				cycle_skill_form(2)
			else:
				select_ability(2)
		elif event.is_action_pressed("ability_4"):
			if event.shift_pressed:
				cycle_skill_form(3)
			else:
				select_ability(3)
		elif event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_F or event.keycode == KEY_R):
			cycle_skill_form(selected_ability_index)
		elif event.is_action_pressed("artifact_use"):
			use_artifact()
		elif event.is_action_pressed("end_turn"):
			end_turn()

func on_right_mouse_clicked():
	if is_animating or battle_manager == null:
		return
	if battle_manager.current_state == battle_manager.State.PLAYER_MOVE:
		print("[Player] Right-clicked: ending movement phase.")
		end_move_phase()
	elif battle_manager.current_state == battle_manager.State.PLAYER_ACT:
		print("[Player] Right-clicked: ending turn.")
		mp = min(max_mp, mp + int(max_mp * 0.15))
		if tiles_moved_this_turn == 0:
			is_braced_guard = true
			recover_stamina(int(max_stamina * 0.10))
			mp = min(max_mp, mp + int(max_mp * 0.10))
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, "BRACED GUARD", "status")
			if ui:
				ui.log_action("Full Standby: Braced Guard (+20 AGI)")
		end_turn()

func _update_facing_direction(delta: Vector2):
	if sprite == null:
		return
	var new_frame = facing_frame
	var new_flip = false
	if abs(delta.x) >= abs(delta.y):
		if delta.x > 0:
			new_frame = 4   # Profile Right
			new_flip = false
		elif delta.x < 0:
			new_frame = 8   # Profile Left
			new_flip = false
	else:
		if delta.y > 0:
			new_frame = 0   # Front (Down)
			new_flip = false
		elif delta.y < 0:
			new_frame = 12  # Back view (Up - hair, headband knot, rear of tunic)
			new_flip = false

	if facing_frame != new_frame or facing_flip_h != new_flip or (tex_walk and sprite.texture != tex_walk):
		facing_frame = new_frame
		facing_flip_h = new_flip
		if tex_walk:
			sprite.texture = tex_walk
		sprite.hframes = 4
		sprite.vframes = 4
		sprite.frame = facing_frame
		sprite.flip_h = facing_flip_h
		sprite.offset = Vector2(0, -6)

func get_all_enemies() -> Array:
	var list = []
	if is_inside_tree():
		var group_nodes = get_tree().get_nodes_in_group("enemies")
		for n in group_nodes:
			if is_instance_valid(n) and n != self:
				list.append(n)
	if list.is_empty() and get_parent():
		var enemy = get_parent().get_node_or_null("Enemy")
		if enemy and is_instance_valid(enemy):
			list.append(enemy)
	return list

func get_closest_enemy() -> Node2D:
	var enemies = get_all_enemies()
	var closest: Node2D = null
	var min_dist: float = 999999.0
	for e in enemies:
		if is_instance_valid(e) and ("hp" not in e or e.hp > 0):
			var d = position.distance_to(e.position)
			if d < min_dist:
				min_dist = d
				closest = e
	return closest

func get_hovered_enemy(override_mouse_pos: Vector2 = Vector2.INF) -> Node2D:
	var mouse_pos = override_mouse_pos if override_mouse_pos != Vector2.INF else get_global_mouse_position()
	var mouse_tile = Vector2i(int(floor(mouse_pos.x / TILE_SIZE)), int(floor(mouse_pos.y / TILE_SIZE)))
	var enemies = get_all_enemies()
	for e in enemies:
		var enemy_tile = Vector2i(int(floor(e.position.x / TILE_SIZE)), int(floor(e.position.y / TILE_SIZE)))
		if mouse_tile == enemy_tile or mouse_pos.distance_to(e.position) <= (TILE_SIZE * 0.5):
			return e
	return null

func _process(_delta):
	if is_animating:
		return
	var target_enemy: Node2D = get_hovered_enemy()
	if target_enemy == null:
		target_enemy = get_closest_enemy()
	if target_enemy != null:
		var diff = target_enemy.position - position
		_update_facing_direction(diff)


func on_move_tile_clicked(target_tile: Vector2i, distance: int):
	if is_animating or battle_manager == null or battle_manager.current_state != battle_manager.State.PLAYER_MOVE:
		return

	var target_pos = Vector2(target_tile.x * TILE_SIZE + TILE_SIZE * 0.5, target_tile.y * TILE_SIZE + TILE_SIZE * 0.5)
	var delta = target_pos - position

	# Face movement direction (Left, Right, Front, or Back)
	_update_facing_direction(delta)

	# Snappy movement directly to the center of clicked square
	position = target_pos
	moves_remaining -= distance
	moves_remaining = max(0, moves_remaining)
	spend_stamina(distance * stamina_cost_per_tile)
	tiles_moved_this_turn += distance

	# Cycle walk frames (F18)
	_play_walk_cycle(facing_frame)

	print("[Player] Moved %d tiles via mouse → %d moves remaining" % [distance, moves_remaining])

	if ui:
		ui.update_moves(moves_remaining)

	if moves_remaining > 0:
		if grid_overlay:
			grid_overlay.show_move_grid(position, moves_remaining)
	else:
		end_move_phase()

func _play_walk_cycle(base_frame: int):
	if sprite == null:
		return
	is_animating = true
	if tex_walk:
		sprite.texture = tex_walk
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.flip_h = false
	sprite.offset = Vector2(0, -6)
	for i in range(4):
		if sprite:
			sprite.frame = base_frame + i
		await get_tree().create_timer(0.04).timeout
	if sprite:
		sprite.frame = base_frame
		sprite.offset = Vector2(0, -6)
	is_animating = false

func end_move_phase():
	if tiles_moved_this_turn == 0:
		recover_stamina(int(max_stamina * 0.15))
		if ui:
			ui.log_action("Paced breath: +15% Stamina")
	moves_remaining = 0
	print("[Player] Movement phase ended.")
	if battle_manager:
		battle_manager.start_player_act()

func start_act():
	select_ability(selected_ability_index)

func on_enemy_turn():
	if grid_overlay:
		grid_overlay.clear_grid()

func select_ability(idx: int):
	if idx < equipped_abilities.size():
		selected_ability_index = idx
		var key = equipped_abilities[idx]
		if element_db and element_db.ABILITIES.has(key):
			var ab = element_db.ABILITIES[key]
			print("[Player] Selected ability: %s (range: %d)" % [ab["name"], ab["range"]])
			if ui:
				ui.log_action("Skill: %s (Range %d)" % [ab["name"], ab["range"]])
				ui.highlight_ability_slot(idx)
			_update_attack_range_display()

func _update_attack_range_display():
	if not grid_overlay or not element_db:
		return
	if selected_ability_index < equipped_abilities.size():
		var key = equipped_abilities[selected_ability_index]
		if element_db.ABILITIES.has(key):
			var ab = element_db.ABILITIES[key]
			var var_info = get_ability_variation_info(key)
			var eff_range = var_info["range_override"] if var_info["range_override"] > 0 else ab["range"]
			var shape = var_info["shape"]
			grid_overlay.show_attack_grid(position, eff_range, shape, get_facing_direction())

func on_attack_tile_clicked(target_tile: Vector2i):
	if is_animating or battle_manager == null or battle_manager.current_state != battle_manager.State.PLAYER_ACT:
		return

	# Use group lookup so multiple enemies are supported
	var all_enemies = get_all_enemies()
	var hit_enemy = null
	for e in all_enemies:
		var et = Vector2i(int(floor(e.position.x / TILE_SIZE)), int(floor(e.position.y / TILE_SIZE)))
		if et == target_tile:
			hit_enemy = e
			break

	if hit_enemy:
		use_ability(selected_ability_index, hit_enemy)
	else:
		if ui:
			ui.log_action("Click on the enemy TARGET square to strike!")

# ──────────────────────────────────────────────
#  ABILITIES
# ──────────────────────────────────────────────

func use_ability(slot_index: int, target: Node2D = null):
	if is_animating:
		print("[Player] Busy animating, cannot use ability.")
		return

	if slot_index >= equipped_abilities.size():
		print("[Player] No ability in slot %d." % slot_index)
		return

	if not element_db:
		return

	var key = equipped_abilities[slot_index]
	if not element_db.ABILITIES.has(key):
		print("[Player] Unknown ability: %s" % key)
		return

	var ability = element_db.ABILITIES[key]

	if not spend_mp(ability["mp_cost"]):
		print("[Player] Not enough MP for %s (need %d, have %d)" % [ability["name"], ability["mp_cost"], mp])
		if ui:
			ui.log_action("Not enough MP for %s!" % ability["name"])
		return

	await _execute_ability(ability, target)

func _execute_ability(ability: Dictionary, target: Node2D = null):
	var enemy = target
	if enemy == null or not is_instance_valid(enemy):
		enemy = get_closest_enemy()
	if enemy == null:
		print("[Player] No target.")
		return

	var diff = enemy.position - position
	var distance = (abs(diff.x) + abs(diff.y)) / TILE_SIZE
	var enemy_tile = Vector2i(int(floor(enemy.position.x / TILE_SIZE)), int(floor(enemy.position.y / TILE_SIZE)))

	var var_info = get_ability_variation_info(ability["name"])
	var eff_r = var_info["range_override"] if var_info["range_override"] > 0 else ability["range"]

	var in_range = false
	if grid_overlay and not grid_overlay.valid_attack_tiles.is_empty():
		in_range = grid_overlay.valid_attack_tiles.has(enemy_tile)
	else:
		in_range = (distance <= eff_r)

	if not in_range:
		print("[Player] %s out of range (dist: %.0f, range: %d)" % [ability["name"], distance, eff_r])
		# Refund MP — don't end the turn so the player can try something else
		mp = min(mp + ability["mp_cost"], max_mp)
		if ui:
			ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
			ui.log_action("%s — out of range! (need target on valid attack square)" % [ability["name"]])
		return

	# Play attack animation
	await _play_attack_anim(ability, enemy.position)

	var base_damage = int(round(ability["damage"] * var_info.get("dmg_mult", 1.0)))
	var effect  = ability.get("effect", "")
	var damage = base_damage

	# Distance Damage Falloff
	if damage > 0 and distance > 2:
		var falloff = ability.get("falloff_per_tile", 0.08) * (distance - 2)
		damage = int(round(damage * clamp(1.0 - falloff, 0.40, 1.0)))

	if damage > 0:
		enemy.take_damage(damage, position, dexterity, ability.get("accuracy", 90))
	elif damage < 0:
		# Negative damage = heal (e.g. Rejuvenation or Aqua Mend)
		heal(abs(damage))

	# Apply secondary effect
	if effect != "" and effect != "heal" and enemy.has_method("apply_status"):
		enemy.apply_status(effect, 2, 0.0)

	print("[Player] Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [ability["name"], damage, effect, mp, max_mp])
	if ui:
		ui.log_action("[You] %s → %d dmg" % [ability["name"], max(0, damage)])
	end_turn()

func _play_attack_anim(_ability: Dictionary, enemy_pos: Vector2):
	if sprite == null:
		return
	is_animating = true

	# Directional Attack Row Selection (F18)
	var delta = enemy_pos - position
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

	# Return to walk texture & preserve facing direction toward target
	if tex_walk:
		sprite.texture = tex_walk
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.frame = facing_frame
	sprite.flip_h = false
	sprite.offset = Vector2(0, -6)
	is_animating = false

# ──────────────────────────────────────────────
#  TURN MANAGEMENT
# ──────────────────────────────────────────────

func start_turn():
	is_braced_guard = false
	tiles_moved_this_turn = 0
	has_acted = false
	if sprite:
		sprite.modulate = Color.WHITE
	regen_mp()
	tick_status_effects()
	moves_remaining = get_total_speed()
	if ui:
		ui.update_moves(moves_remaining)
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)
	if grid_overlay:
		grid_overlay.show_move_grid(position, moves_remaining)

func end_turn():
	if grid_overlay:
		grid_overlay.clear_grid()
	has_acted = true
	print("[%s] Turn ended." % name)
	if battle_manager:
		if battle_manager.has_method("on_player_unit_acted"):
			battle_manager.on_player_unit_acted(self)
		else:
			battle_manager.start_enemy_turn()
