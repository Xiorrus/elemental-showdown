extends CharacterBody2D
const AbilityGeometryScript = preload("res://scripts/ability_geometry.gd")
const ForceMovementResolverScript = preload("res://scripts/force_movement_resolver.gd")
const AttackIntentScript = preload("res://scripts/attack_intent.gd")
const ReactionResolverScript = preload("res://scripts/reaction_resolver.gd")

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — Player
#  Implements: element combat, mana regen, artifact slot, injury tracking.
#  Persistent levels, XP, and skill purchases belong to CampaignManager.
# ──────────────────────────────────────────────

const TILE_SIZE = 64
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
var defense: int = 20
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

# ── Campaign progression snapshot for combat display ──
var level: int = 1
var xp: int = 0
var xp_to_next_level: int = 100

# ── Skills ────────────────────────────────────
# Keys into ElementData.ABILITIES. CampaignManager grants two starter abilities.
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

	# The exhibition fallback uses the same support/attack starters as a career.
	# World may replace this loadout with saved campaign skills after add_child().
	var cm = get_node_or_null("/root/CampaignManager")
	if equipped_abilities.is_empty() and cm and cm.DEFAULT_ELEMENT_SKILLS.has(element):
		for key in cm.DEFAULT_ELEMENT_SKILLS[element]:
			_unlock_ability(key)

	moves_remaining = get_total_speed()
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
		element = elem.to_lower().strip_edges()
	if element == "wind":
		element = "air"
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
		defense      = edata.get("base_defense", 20)
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
	if not unlocked_abilities.has(key):
		return
	if equipped_abilities.has(key):
		return
	# Replaces last slot or adds if space
	if equipped_abilities.size() < 4:
		equipped_abilities.append(key)
	else:
		equipped_abilities[3] = key
	if ui:
		ui.update_abilities(equipped_abilities, element_db)

# ──────────────────────────────────────────────
#  CAMPAIGN PROGRESSION DISPLAY
# ──────────────────────────────────────────────

func sync_campaign_progression(cm):
	if cm == null or not cm.has_active_campaign:
		return
	level = cm.player_level
	xp = cm.player_xp
	xp_to_next_level = cm.player_xp_to_next
	if ui:
		ui.update_xp(level, xp, xp_to_next_level)

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
		"range_band": "mid",
		"shape": "cardinal",
		"dmg_mult": 1.0,
		"mp_mult": 1.0,
		"effect": "",
		"terrain_kind": "",
		"terrain_duration": 0
	}
	var edata = element_db
	if not edata and is_inside_tree():
		edata = get_node_or_null("/root/ElementData")
	if not edata:
		var ed_res = load("res://scripts/element_data.gd")
		if ed_res: edata = ed_res.new()
	if not edata:
		return res

	var norm_key = key
	if not edata.ABILITIES.has(norm_key):
		var cand = norm_key.replace(" ", "_")
		if edata.ABILITIES.has(cand):
			norm_key = cand
		else:
			for k in edata.ABILITIES:
				if edata.ABILITIES[k].get("name", "").to_lower() == key.to_lower():
					norm_key = k
					break
	if not edata.ABILITIES.has(norm_key):
		return res

	var ab = edata.ABILITIES[norm_key]
	var forms = ab.get("forms", {})
	if forms.is_empty():
		res["effect"] = ab.get("effect", "")
		return res

	var current_f_key = active_skill_forms.get(norm_key, "")
	if current_f_key == "":
		var cm = get_node_or_null("/root/CampaignManager") if is_inside_tree() else null
		if cm and cm.skill_variations.has(norm_key):
			current_f_key = cm.skill_variations[norm_key]
		else:
			current_f_key = forms.keys()[0]
		active_skill_forms[norm_key] = current_f_key

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

	res["name"] = f_info.get("name", ab.get("name", norm_key))
	res["range_override"] = AbilityGeometryScript.effective_reach(str(res["name"]), int(f_info.get("range", ab.get("range", 2))))
	res["range_band"] = AbilityGeometryScript.preferred_band(str(res["name"]), int(res["range_override"]))
	res["dmg_mult"] = f_info.get("dmg_mult", 1.0)
	res["mp_mult"] = f_info.get("mp_mult", 1.0)
	res["effect"] = f_info.get("effect", ab.get("effect", ""))
	res["terrain_kind"] = f_info.get("terrain_kind", ab.get("terrain_kind", ""))
	res["terrain_duration"] = f_info.get("terrain_duration", ab.get("terrain_duration", 0))
	res["shape"] = f_info.get("shape", "cardinal")
	if f_info.get("is_radial", false):
		res["shape"] = "radial"
	elif f_info.get("desc", "").to_lower().contains("linear") or f_info.get("desc", "").to_lower().contains("forward"):
		res["shape"] = "linear_front"
	res["shape"] = AbilityGeometryScript.shape_for(str(res["name"]), str(res["shape"]))
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
		if battle_manager and battle_manager.current_state == battle_manager.State.PLAYER_ACT:
			_update_attack_range_display()
		elif battle_manager and battle_manager.current_state == battle_manager.State.PLAYER_MOVE:
			if grid_overlay and moves_remaining > 0:
				grid_overlay.show_move_grid(position, moves_remaining)

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
	for s in status_effects:
		if s.get("name") in ["evasion", "dodge_buff"]:
			eff_agi += float(agility) * 0.40
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

func apply_knockback(source_pos: Vector2, distance_tiles: int = 1) -> bool:
	var bm = battle_manager if battle_manager else (get_parent().get_node_or_null("BattleManager") if get_parent() else null)
	var terrain_node = bm.terrain if (bm != null and "terrain" in bm) else null
	var result = ForceMovementResolverScript.resolve_push(self, source_pos, distance_tiles, get_tree(), terrain_node)
	return ForceMovementResolverScript.apply_resolved_push(result, ui, bm)

func take_damage(amount: int, attacker_pos: Vector2 = Vector2.ZERO, attacker_dex: int = 20, skill_acc: int = 90, is_unavoidable: bool = false, attacker_node: Node2D = null, skill_elem: String = ""):
	if hp <= 0 or amount <= 0:
		return 0
	var final_amount = amount
	var hit_angle = "front"

	if not is_unavoidable and attacker_pos != Vector2.ZERO:
		var res = calculate_directional_hit(attacker_pos, attacker_dex, skill_acc)
		if not res["is_hit"]:
			print("[Player] EVADED attack from %s! (Hit chance was %d%%)" % [res["angle"], int(res["hit_chance"])])
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
				print("[Player] Riposte counter against %s!" % attacker_node.name)
				if ui and ui.has_method("spawn_damage_popup"):
					ui.spawn_damage_popup(attacker_node.position, "RIPOSTE COUNTER!", "status")
				if ui and ui.has_method("log_action"):
					ui.log_action("⚔️ [Player] Braced Guard ripostes %s for 15 dmg!" % attacker_node.name)
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

	# Defense stat damage reduction (e.g. 30 defense = -15% damage taken)
	var eff_def = float(defense)
	for s in status_effects:
		if s.get("name") in ["defense_buff", "stone_plating", "guard"]:
			eff_def += float(s.get("value", 10.0))
	var def_factor = clamp(1.0 - (eff_def * 0.005), 0.60, 1.0)
	final_amount = int(round(final_amount * def_factor))
	final_amount = max(1, final_amount)

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
	print("[Player] Took %d damage → HP: %d/%d" % [final_amount, hp, max_hp])
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 0.4, 0.4), 0.08)
		var rest_color = Color(0.55, 0.55, 0.55, 1.0) if has_acted else Color.WHITE
		tw.tween_property(sprite, "modulate", rest_color, 0.08)
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(position, final_amount, "damage", skill_elem)
	if ui:
		ui.update_player_stats(hp, max_hp, mp, max_mp, stamina, max_stamina)

	# ReactionResolver: Counter check (surviving melee hit triggers counter-attack)
	if hp > 0 and bm and "reaction_resolver" in bm and bm.reaction_resolver != null and attacker_node != null and attacker_node != self:
		bm.reaction_resolver.trigger_counter(self, attacker_node, ui)

	if hp <= 0:
		if ui and ui.has_method("trigger_screen_shake"):
			ui.trigger_screen_shake(12.0, 0.35)
		if ui and ui.has_method("trigger_hit_stop"):
			ui.trigger_hit_stop(60.0)
		if battle_manager and battle_manager.has_method("record_knockout"):
			battle_manager.record_knockout(self)
		_on_defeated()
	return final_amount

func declare_reaction(reaction_type: String, target_ally: Node2D = null) -> bool:
	var bm = battle_manager if battle_manager else (get_parent().get_node_or_null("BattleManager") if get_parent() else null)
	if bm and "reaction_resolver" in bm and bm.reaction_resolver != null:
		var ok = bm.reaction_resolver.declare_reaction(self, reaction_type, target_ally)
		if ok:
			has_acted = true
			var my_name = character_name if character_name != "" else name
			if ui and ui.has_method("log_action"):
				ui.log_action("🛡️ [ORDER] %s assumes %s stance!" % [my_name, reaction_type.to_upper()])
			if ui and ui.has_method("spawn_damage_popup"):
				ui.spawn_damage_popup(position, reaction_type.to_upper(), "status")
			end_turn()
		return ok
	return false

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
		if hp <= 0:
			break
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
	if not _can_take_action(true):
		return
	if artifact.is_empty() or artifact_charges <= 0:
		print("[Player] No artifact or no charges.")
		return
	# Artifact costs ZERO MP per GDD — emergency tool
	var key = artifact.get("ability_key", "")
	if key != "" and element_db and element_db.ABILITIES.has(key):
		var ability = element_db.ABILITIES[key]
		if await _execute_ability(ability):
			artifact_charges -= 1
	if ui:
		ui.update_artifact(artifact, artifact_charges)

# ──────────────────────────────────────────────
#  MOVEMENT & GRID SELECTION
# ──────────────────────────────────────────────

func is_active_unit() -> bool:
	if battle_manager == null:
		return true
	if "active_player_unit" in battle_manager and battle_manager.active_player_unit != null:
		return battle_manager.active_player_unit == self
	return true

func _can_take_action(attack_only: bool = false) -> bool:
	if is_animating or hp <= 0 or has_acted or not is_active_unit():
		return false
	if battle_manager == null:
		return true
	if battle_manager.current_state not in [battle_manager.State.PLAYER_MOVE, battle_manager.State.PLAYER_ACT]:
		return false
	if attack_only and battle_manager.current_state != battle_manager.State.PLAYER_ACT:
		return false
	return true

func _unhandled_input(event):
	if not _can_take_action() or battle_manager == null:
		return

	# Right click advances to next phase anywhere on screen
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		on_right_mouse_clicked()
		get_viewport().set_input_as_handled()
		return

	if battle_manager.current_state == battle_manager.State.PLAYER_MOVE:
		if event.is_action_pressed("end_move"):
			end_move_phase()
		elif event.is_action_pressed("ability_1"):
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
	if not _can_take_action() or battle_manager == null:
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
			if is_instance_valid(n) and n != self and not n.is_queued_for_deletion() and ("hp" not in n or n.hp > 0):
				list.append(n)
	if list.is_empty() and get_parent():
		var enemy = get_parent().get_node_or_null("Enemy")
		if enemy and is_instance_valid(enemy) and not enemy.is_queued_for_deletion() and ("hp" not in enemy or enemy.hp > 0):
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
	if not _can_take_action():
		return
	var target_enemy: Node2D = get_hovered_enemy()
	if target_enemy == null:
		target_enemy = get_closest_enemy()
	if target_enemy != null:
		var diff = target_enemy.position - position
		var prev_facing = facing_frame
		_update_facing_direction(diff)
		if prev_facing != facing_frame and battle_manager and battle_manager.current_state == battle_manager.State.PLAYER_ACT:
			_update_attack_range_display()


func on_move_tile_clicked(target_tile: Vector2i, distance: int):
	if not _can_take_action() or battle_manager == null or battle_manager.current_state != battle_manager.State.PLAYER_MOVE:
		return
	if distance <= 0 or distance > moves_remaining:
		return
	if grid_overlay and grid_overlay.valid_move_tiles.get(target_tile, -1) != distance:
		return

	var path: Array[Vector2i] = grid_overlay.get_move_path(target_tile) if grid_overlay else [target_tile]
	if path.is_empty():
		return
	is_animating = true
	if grid_overlay: grid_overlay.clear_grid()
	moves_remaining -= distance
	moves_remaining = max(0, moves_remaining)
	spend_stamina(distance * stamina_cost_per_tile)
	tiles_moved_this_turn += distance
	for step_tile in path:
		var step_pos := Vector2(step_tile.x * TILE_SIZE + TILE_SIZE * 0.5, step_tile.y * TILE_SIZE + TILE_SIZE * 0.5)
		_update_facing_direction(step_pos - position)
		await _play_walk_cycle(facing_frame, step_pos)
		if battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null:
			battle_manager.reaction_resolver.trigger_overwatch(self, step_tile, get_tree(), ui)
			if hp <= 0:
				break
	is_animating = false

	print("[Player] Moved %d tiles via mouse → %d moves remaining" % [distance, moves_remaining])

	if ui:
		ui.update_moves(moves_remaining)

	if moves_remaining > 0:
		if grid_overlay:
			grid_overlay.show_move_grid(position, moves_remaining)
	else:
		end_move_phase()

func _play_walk_cycle(base_frame: int, target_pos: Vector2):
	var tween := create_tween()
	tween.tween_property(self, "position", target_pos, 0.32)
	if sprite == null:
		if tween.is_running(): await tween.finished
		return
	if tex_walk:
		sprite.texture = tex_walk
	sprite.hframes = 4
	sprite.vframes = 4
	sprite.flip_h = false
	sprite.offset = Vector2(0, -6)
	for i in range(4):
		if sprite:
			sprite.frame = base_frame + i
		await get_tree().create_timer(0.08).timeout
	if tween.is_running(): await tween.finished
	if sprite:
		sprite.frame = facing_frame
		sprite.offset = Vector2(0, -6)

func end_move_phase():
	if not _can_take_action() or (battle_manager and battle_manager.current_state != battle_manager.State.PLAYER_MOVE):
		return
	if tiles_moved_this_turn == 0:
		recover_stamina(int(max_stamina * 0.15))
		if ui:
			ui.log_action("Paced breath: +15% Stamina")
	moves_remaining = 0
	print("[Player] Movement phase ended.")
	if battle_manager:
		battle_manager.start_player_act()

func start_act():
	var closest = get_closest_enemy()
	if closest:
		_update_facing_direction(closest.position - position)
	select_ability(selected_ability_index)

func on_enemy_turn():
	if grid_overlay:
		grid_overlay.clear_grid()

func select_ability(idx: int):
	if idx >= 0 and idx < equipped_abilities.size():
		selected_ability_index = idx
		var key = equipped_abilities[idx]
		if element_db and element_db.ABILITIES.has(key):
			var ab = element_db.ABILITIES[key]
			print("[Player] Selected ability: %s (range: %d)" % [ab["name"], ab["range"]])
			if not is_active_unit():
				return
			if ui:
				ui.log_action("Skill: %s (Range %d)" % [ab["name"], ab["range"]])
				ui.highlight_ability_slot(idx)
			if battle_manager and battle_manager.current_state == battle_manager.State.PLAYER_ACT:
				_update_attack_range_display()
			elif battle_manager and battle_manager.current_state == battle_manager.State.PLAYER_MOVE:
				if grid_overlay and moves_remaining > 0:
					grid_overlay.show_move_grid(position, moves_remaining)

func _update_attack_range_display():
	if not grid_overlay or not element_db or not is_active_unit():
		return
	# Only display attack grid if in PLAYER_ACT phase
	if battle_manager and battle_manager.current_state != battle_manager.State.PLAYER_ACT:
		return
	if selected_ability_index < equipped_abilities.size():
		var key = equipped_abilities[selected_ability_index]
		if element_db.ABILITIES.has(key):
			var ab = element_db.ABILITIES[key]
			var var_info = get_ability_variation_info(key)
			var eff_range = var_info["range_override"] if var_info["range_override"] > 0 else ab["range"]
			var shape = var_info["shape"]
			grid_overlay.show_attack_grid(position, eff_range, shape, get_facing_direction())
			if selected_ability_is_support():
				grid_overlay.valid_attack_tiles.append(Vector2i(floor(position / TILE_SIZE)))

func on_attack_tile_clicked(target_tile: Vector2i):
	if not _can_take_action(true) or battle_manager == null:
		return

	# Face towards clicked tile
	var tile_world_pos = Vector2(target_tile.x * TILE_SIZE + TILE_SIZE * 0.5, target_tile.y * TILE_SIZE + TILE_SIZE * 0.5)
	var diff = tile_world_pos - position
	if diff.length_squared() > 1.0:
		_update_facing_direction(diff)
		_update_attack_range_display()

	if selected_ability_index < 0 or selected_ability_index >= equipped_abilities.size() or not element_db:
		return
	var key = equipped_abilities[selected_ability_index]
	var ab = element_db.ABILITIES.get(key, {})
	var var_info = get_ability_variation_info(key)
	var effect = var_info.get("effect", ab.get("effect", ""))
	var base_dmg = int(round(ab.get("damage", 0) * var_info.get("dmg_mult", 1.0)))

	# Check if this ability is a self-buff, heal, or support skill
	var is_support = _is_support_ability(base_dmg, effect)

	# Use group lookup so multiple enemies are supported
	var all_enemies = get_all_enemies()
	var hit_enemy = null
	for e in all_enemies:
		var et = Vector2i(int(floor(e.position.x / TILE_SIZE)), int(floor(e.position.y / TILE_SIZE)))
		if et == target_tile:
			hit_enemy = e
			break

	# Look for an ally or self on target tile
	var hit_ally = null
	if is_inside_tree():
		for p in get_tree().get_nodes_in_group("players"):
			if is_instance_valid(p) and ("hp" not in p or p.hp > 0):
				var pt = Vector2i(int(floor(p.position.x / TILE_SIZE)), int(floor(p.position.y / TILE_SIZE)))
				if pt == target_tile:
					hit_ally = p
					break

	if hit_enemy:
		use_ability(selected_ability_index, hit_enemy)
	elif hit_ally:
		use_ability(selected_ability_index, hit_ally)
	elif is_support:
		# Clicking anywhere valid triggers support / self-buff
		use_ability(selected_ability_index, self)
	elif str(var_info.get("terrain_kind", "")) != "" or (battle_manager.terrain and battle_manager.terrain.has_wall(target_tile)):
		use_ability(selected_ability_index, null, target_tile)
	else:
		if ui:
			ui.log_action("Click on the enemy TARGET square to strike!")

# ──────────────────────────────────────────────
#  ABILITIES
# ──────────────────────────────────────────────

func use_ability(slot_index: int, target: Node2D = null, aimed_tile: Vector2i = Vector2i(-1, -1)):
	if not _can_take_action(true):
		return

	if slot_index < 0 or slot_index >= equipped_abilities.size():
		print("[Player] No ability in slot %d." % slot_index)
		return

	if not element_db:
		return

	var key = equipped_abilities[slot_index]
	if not element_db.ABILITIES.has(key):
		print("[Player] Unknown ability: %s" % key)
		return

	var ability = element_db.ABILITIES[key]
	var cost = int(round(ability["mp_cost"] * get_ability_variation_info(key).get("mp_mult", 1.0)))
	await _execute_ability(ability, target, cost, aimed_tile)

func selected_ability_is_support() -> bool:
	if not element_db or selected_ability_index < 0 or selected_ability_index >= equipped_abilities.size():
		return false
	var key = equipped_abilities[selected_ability_index]
	var ability = element_db.ABILITIES.get(key, {})
	var variation = get_ability_variation_info(key)
	var damage = int(round(ability.get("damage", 0) * variation.get("dmg_mult", 1.0)))
	return _is_support_ability(damage, variation.get("effect", ability.get("effect", "")))

func _is_support_ability(damage: int, effect: String) -> bool:
	return effect in ["dodge_buff", "evasion", "defense_buff", "armor_buff", "guard", "heal", "cleanse", "anchor"] or damage <= 0

func _execute_ability(ability: Dictionary, target: Node2D = null, mp_cost: int = 0, aimed_tile: Vector2i = Vector2i(-1, -1)) -> bool:
	var key = ability.get("key", ability.get("name", "").replace(" ", "_"))
	var var_info = get_ability_variation_info(key)
	var eff_r = var_info["range_override"] if var_info["range_override"] > 0 else ability.get("range", 2)
	var effect = var_info.get("effect", ability.get("effect", ""))
	var base_damage = int(round(ability.get("damage", 0) * var_info.get("dmg_mult", 1.0)))
	var is_support = _is_support_ability(base_damage, effect)

	var target_node = target
	if (target_node == null or not is_instance_valid(target_node)) and aimed_tile.x < 0:
		if is_support:
			target_node = self
		else:
			target_node = get_closest_enemy()

	if target_node == null and aimed_tile.x < 0:
		print("[Player] No target.")
		return false
	if target_node != null and (target_node.is_queued_for_deletion() or ("hp" in target_node and target_node.hp <= 0)):
		return false
	var target_is_ally = target_node != null and (target_node == self or target_node.is_in_group("players"))
	if target_node != null and is_support != target_is_ally:
		if ui:
			ui.log_action("Choose an ally for support or an enemy for an attack.")
		return false

	var target_pos: Vector2 = target_node.position if target_node != null else Vector2(aimed_tile.x * TILE_SIZE + TILE_SIZE * 0.5, aimed_tile.y * TILE_SIZE + TILE_SIZE * 0.5)
	var diff = target_pos - position
	if diff.length_squared() > 1.0:
		_update_facing_direction(diff)

	var distance = (abs(diff.x) + abs(diff.y)) / TILE_SIZE
	# Validate this skill's geometry, independent of a previously displayed grid.
	var shape: String = AbilityGeometryScript.shape_for(str(var_info.get("name", ability.get("name", ""))), str(var_info.get("shape", "cardinal")))
	var origin_tile: Vector2i = AbilityGeometryScript.tile_of(position)
	var target_tile: Vector2i = AbilityGeometryScript.tile_of(target_pos)
	var affected_tiles: Array[Vector2i] = AbilityGeometryScript.tiles(origin_tile, get_facing_direction(), eff_r, shape)
	var in_range = affected_tiles.has(target_tile)
	if target_node == self:
		in_range = is_support

	if not in_range:
		print("[Player] %s out of range (dist: %.0f, range: %d)" % [ability["name"], distance, eff_r])
		if ui:
			ui.log_action("%s — out of range! (need target on valid attack square)" % [ability["name"]])
		return false
	if target_node != null and target_node != self and battle_manager and battle_manager.terrain and battle_manager.terrain.blocks_line(origin_tile, target_tile):
		if ui: ui.log_action("A stone wall blocks this attack. Break the wall first.")
		return false
	# ── Telegraphed Windup Check ─────────────────────────────────────────────
	var windup: int = int(var_info.get("windup_rounds", ability.get("windup_rounds", 0)))
	if windup > 0:
		if not spend_mp(mp_cost):
			if ui: ui.log_action("Not enough MP for %s!" % ability["name"])
			return false
		var intent = AttackIntentScript.new(self, "player", ability.get("name", "Skill"), var_info.get("name", ability.get("name")), ability, origin_tile, target_tile, affected_tiles, windup)
		if battle_manager and battle_manager.has_method("queue_intent"):
			battle_manager.queue_intent(intent)
		var c_name = character_name if character_name != "" else name
		if ui and ui.has_method("log_action"):
			ui.log_action("⏳ [WINDUP] %s charges %s! Target zone locked!" % [c_name, var_info.get("name", ability["name"])])
		if ui and ui.has_method("spawn_damage_popup"):
			ui.spawn_damage_popup(position, "WINDUP...", "status")
		has_acted = true
		end_turn()
		return true

	# Pay only after validation. Artifacts pass zero cost and cannot create MP refunds.
	if not spend_mp(mp_cost):
		if ui:
			ui.log_action("Not enough MP for %s!" % ability["name"])
		return false

	# Play attack animation facing target
	await _play_attack_anim(ability, target_pos)

	var damage = base_damage

	# Resonance / Empowered Boost (+20% damage if momentum was full)
	var resonance_active = false
	if damage > 0 and not is_support and battle_manager and battle_manager.has_method("consume_resonance_buff"):
		resonance_active = battle_manager.consume_resonance_buff()
	var empower_boost := 0.0
	if damage > 0 and not is_support and battle_manager and battle_manager.has_method("consume_empowered_boost"):
		empower_boost = battle_manager.consume_empowered_boost("player")
	if (resonance_active or empower_boost > 0.0) and damage > 0:
		damage = int(round(damage * 1.20))
		if ui and ui.has_method("log_action"):
			ui.log_action("⚡ [EMPOWERED MOMENT] +20% Damage!")

	var ab_elem = ability.get("element", element)
	var hit_landed = true
	if damage > 0 and not is_support:
		var targets: Array = [target_node] if target_node != null else []
		if AbilityGeometryScript.is_multi_target(shape, str(var_info.get("name", ""))):
			for other in get_all_enemies():
				if other != target_node and affected_tiles.has(AbilityGeometryScript.tile_of(other.position)):
					targets.append(other)

		# Check Intercept reaction for targets
		for ti in range(targets.size()):
			var tv = targets[ti]
			if battle_manager and "reaction_resolver" in battle_manager and battle_manager.reaction_resolver != null:
				var interceptor = battle_manager.reaction_resolver.evaluate_intercept(tv, get_tree())
				if interceptor != null:
					var int_name = interceptor.character_name if ("character_name" in interceptor and interceptor.character_name != "") else interceptor.name
					if ui and ui.has_method("log_action"):
						ui.log_action("🛡️ [INTERCEPT] %s steps in to protect their ally!" % int_name)
					targets[ti] = interceptor
		var total_damage := 0
		var any_hit := false
		for victim in targets:
			if not is_instance_valid(victim) or victim.is_queued_for_deletion() or ("hp" in victim and victim.hp <= 0):
				continue
			if battle_manager and battle_manager.terrain and battle_manager.terrain.blocks_line(origin_tile, AbilityGeometryScript.tile_of(victim.position)):
				continue
			var accuracy: int = int(ability.get("accuracy", 90))
			if battle_manager and battle_manager.terrain:
				accuracy -= battle_manager.terrain.accuracy_penalty(origin_tile, AbilityGeometryScript.tile_of(victim.position))
			var victim_tile: Vector2i = AbilityGeometryScript.tile_of(victim.position)
			var victim_distance: int = absi(victim_tile.x - origin_tile.x) + absi(victim_tile.y - origin_tile.y)
			var range_damage: int = int(round(damage * AbilityGeometryScript.range_multiplier(str(var_info.get("range_band", "mid")), victim_distance)))
			var dealt: int = victim.take_damage(range_damage, position, dexterity, accuracy, false, self, ab_elem)
			total_damage += dealt
			if dealt > 0:
				any_hit = true
				if effect != "" and effect != "heal" and victim.has_method("apply_status") and ("hp" not in victim or victim.hp > 0):
					victim.apply_status(effect, 2, 0.0)
				if effect == "knockback" and victim.has_method("apply_knockback") and ("hp" not in victim or victim.hp > 0):
					victim.apply_knockback(position, 1)
		damage = total_damage
		hit_landed = any_hit
	elif damage < 0 or effect == "heal":
		var heal_amt = abs(damage) if damage != 0 else 30
		if target_node.has_method("heal"):
			target_node.heal(heal_amt)
		else:
			heal(heal_amt)
	if battle_manager and battle_manager.terrain:
		battle_manager.terrain.react_to_attack(ab_elem, affected_tiles, maxi(0, base_damage))
		var terrain_kind: String = var_info.get("terrain_kind", "")
		if terrain_kind != "":
			battle_manager.terrain.place_from_skill(terrain_kind, origin_tile, target_tile, eff_r, shape, int(var_info.get("terrain_duration", 2)))
			hit_landed = true

	# Apply buffs to self or ally if defensive/support
	if effect in ["dodge_buff", "evasion"]:
		target_node.apply_status("evasion", 2, 0.40)
		if ui and ui.has_method("spawn_damage_popup"):
			ui.spawn_damage_popup(position, "+40% DODGE EVASION", "status")
	elif effect in ["defense_buff", "armor_buff", "guard"]:
		target_node.apply_status("defense_buff", 2, 10.0)
		if ui and ui.has_method("spawn_damage_popup"):
			ui.spawn_damage_popup(position, "+DEFENSE PLATING", "status")
	elif effect == "cleanse" and "status_effects" in target_node:
		target_node.status_effects = target_node.status_effects.filter(func(s): return s.get("name", "") in ["evasion", "defense_buff", "armor_buff", "guard", "barrier", "anchor"])
	elif is_support and effect != "" and effect != "heal" and hit_landed and target_node.has_method("apply_status") and ("hp" not in target_node or target_node.hp > 0):
		target_node.apply_status(effect, 2, 0.0)

	if is_support and hit_landed and effect == "knockback" and target_node != self and target_node.has_method("apply_knockback") and ("hp" not in target_node or target_node.hp > 0):
		target_node.apply_knockback(position, 1)

	# Register elemental action for Resonance & Fusion
	if hit_landed and battle_manager and battle_manager.has_method("register_elemental_action"):
		battle_manager.register_elemental_action(self, ab_elem, target_node if target_node != self else null)

	print("[Player] Used: %s | Dmg: %d | Effect: %s | MP: %d/%d" % [ability["name"], damage, effect, mp, max_mp])
	if ui:
		if is_support:
			ui.log_action("[You] %s activated!" % [ability["name"]])
		else:
			var band: String = var_info.get("range_band", "mid")
			var bonus: String = " +25%% %s range" % band if AbilityGeometryScript.range_multiplier(band, int(distance)) > 1.0 else ""
			ui.log_action("[You] %s → %d dmg%s" % [var_info.get("name", ability["name"]), max(0, damage), bonus])
	is_animating = true
	await get_tree().create_timer(0.20).timeout
	is_animating = false
	end_turn()
	return true

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
		await get_tree().create_timer(0.13).timeout
	await get_tree().create_timer(0.12).timeout

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
	if hp <= 0:
		moves_remaining = 0
		has_acted = true
		if grid_overlay:
			grid_overlay.clear_grid()
		return
	moves_remaining = get_total_speed()
	if not is_active_unit():
		return
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
