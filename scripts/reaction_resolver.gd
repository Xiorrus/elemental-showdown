class_name ReactionResolver
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# ReactionResolver
# Universal combat reactions: Guard, Counter, Intercept, Overwatch.
# Enforces once-per-round triggers, resource reservation, and recursion guards.
# ─────────────────────────────────────────────────────────────────────────────

const REACTION_NONE := "none"
const REACTION_GUARD := "guard"
const REACTION_COUNTER := "counter"
const REACTION_INTERCEPT := "intercept"
const REACTION_OVERWATCH := "overwatch"

const GUARD_DAMAGE_REDUCTION := 0.30
const COUNTER_RANGE_MAX := 1
const INTERCEPT_RANGE_MAX := 1
const OVERWATCH_DEFAULT_RANGE := 3

# Node2D -> Dictionary
# {
#   "type": String,
#   "target_ally": Node2D,
#   "reserved_mp": int,
#   "triggered": bool,
#   "reserved_ability": Dictionary
# }
var _unit_reactions: Dictionary = {}
var _is_resolving_reaction: bool = false

func declare_reaction(unit: Node2D, reaction_type: String, target_ally: Node2D = null, ability: Dictionary = {}) -> bool:
	if unit == null or not is_instance_valid(unit):
		return false
	if "hp" in unit and unit.hp <= 0:
		return false

	var mp_cost := 0
	if reaction_type == REACTION_OVERWATCH and not ability.is_empty():
		mp_cost = int(ability.get("mp_cost", 10))
		if "mp" in unit and unit.mp < mp_cost:
			return false

	_unit_reactions[unit] = {
		"type": reaction_type,
		"target_ally": target_ally,
		"reserved_mp": mp_cost,
		"triggered": false,
		"reserved_ability": ability.duplicate(true)
	}
	return true

func get_reaction(unit: Node2D) -> Dictionary:
	if unit != null and _unit_reactions.has(unit):
		return _unit_reactions[unit]
	return {"type": REACTION_NONE, "triggered": false}

func has_active_reaction(unit: Node2D, reaction_type: String) -> bool:
	if unit == null or not _unit_reactions.has(unit):
		return false
	var r: Dictionary = _unit_reactions[unit]
	return r["type"] == reaction_type and not r["triggered"]

## Resets trigger states for a new full round.
func reset_round() -> void:
	for unit in _unit_reactions.keys():
		if is_instance_valid(unit) and ("hp" not in unit or unit.hp > 0):
			_unit_reactions[unit]["triggered"] = false
		else:
			_unit_reactions.erase(unit)

## Check Guard on impact: reduces incoming damage by 30% and grants knockback resistance.
func evaluate_guard(target: Node2D, incoming_damage: int) -> Dictionary:
	if has_active_reaction(target, REACTION_GUARD):
		_unit_reactions[target]["triggered"] = true
		var reduced_dmg := int(round(incoming_damage * (1.0 - GUARD_DAMAGE_REDUCTION)))
		return {
			"guarded": true,
			"damage": reduced_dmg,
			"push_immune": true
		}
	return {
		"guarded": false,
		"damage": incoming_damage,
		"push_immune": false
	}

## Check Intercept: a nearby defender with Intercept active intercepts the attack aimed at target.
func evaluate_intercept(target: Node2D, tree: SceneTree) -> Node2D:
	if _is_resolving_reaction or tree == null or target == null:
		return null

	var target_tile = Vector2i(int(floor(target.position.x / 64)), int(floor(target.position.y / 64)))
	var group = "players" if target.is_in_group("players") else "enemies"

	for ally in tree.get_nodes_in_group(group):
		if ally != target and is_instance_valid(ally) and ("hp" not in ally or ally.hp > 0):
			if has_active_reaction(ally, REACTION_INTERCEPT):
				var ally_r = _unit_reactions[ally]
				# Must be guarding this target specifically or general adjacent intercept
				if ally_r["target_ally"] == target or ally_r["target_ally"] == null:
					var ally_tile = Vector2i(int(floor(ally.position.x / 64)), int(floor(ally.position.y / 64)))
					var dist = absi(ally_tile.x - target_tile.x) + absi(ally_tile.y - target_tile.y)
					if dist <= INTERCEPT_RANGE_MAX:
						_unit_reactions[ally]["triggered"] = true
						return ally
	return null

## Check Counter: if defender survives close-range hit, strikes back once.
func trigger_counter(defender: Node2D, attacker: Node2D, ui: Node = null) -> bool:
	if _is_resolving_reaction or defender == null or attacker == null:
		return false
	if not has_active_reaction(defender, REACTION_COUNTER):
		return false
	if "hp" in defender and defender.hp <= 0:
		return false

	var def_tile = Vector2i(int(floor(defender.position.x / 64)), int(floor(defender.position.y / 64)))
	var atk_tile = Vector2i(int(floor(attacker.position.x / 64)), int(floor(attacker.position.y / 64)))
	var dist = absi(def_tile.x - atk_tile.x) + absi(def_tile.y - atk_tile.y)
	if dist > COUNTER_RANGE_MAX:
		return false

	_unit_reactions[defender]["triggered"] = true
	_is_resolving_reaction = true

	var counter_damage := 14
	var def_name = defender.character_name if ("character_name" in defender and defender.character_name != "") else defender.name
	var atk_name = attacker.character_name if ("character_name" in attacker and attacker.character_name != "") else attacker.name

	if ui and ui.has_method("log_action"):
		ui.log_action("⚔️ [COUNTER] %s ripostes against %s for %d damage!" % [def_name, atk_name, counter_damage])
	if ui and ui.has_method("spawn_damage_popup"):
		ui.spawn_damage_popup(attacker.position, "COUNTER! (-%d)" % counter_damage, "damage")

	if attacker.has_method("take_damage"):
		attacker.take_damage(counter_damage, defender.position, 30, 100, true)

	_is_resolving_reaction = false
	return true

## Check Overwatch: when a moving enemy enters the overwatch tile pattern.
func trigger_overwatch(moving_unit: Node2D, destination_tile: Vector2i, tree: SceneTree, ui: Node = null) -> bool:
	if _is_resolving_reaction or tree == null or moving_unit == null:
		return false

	var opposing_group = "enemies" if moving_unit.is_in_group("players") else "players"

	for watcher in tree.get_nodes_in_group(opposing_group):
		if is_instance_valid(watcher) and ("hp" not in watcher or watcher.hp > 0):
			if has_active_reaction(watcher, REACTION_OVERWATCH):
				var w_tile = Vector2i(int(floor(watcher.position.x / 64)), int(floor(watcher.position.y / 64)))
				var dist = absi(w_tile.x - destination_tile.x) + absi(w_tile.y - destination_tile.y)
				if dist <= OVERWATCH_DEFAULT_RANGE:
					var r_data = _unit_reactions[watcher]
					r_data["triggered"] = true
					_is_resolving_reaction = true

					# Spend reserved MP
					if r_data["reserved_mp"] > 0 and "mp" in watcher:
						watcher.mp = max(0, watcher.mp - r_data["reserved_mp"])

					var ow_damage := 16
					var watcher_name = watcher.character_name if ("character_name" in watcher and watcher.character_name != "") else watcher.name
					var target_name = moving_unit.character_name if ("character_name" in moving_unit and moving_unit.character_name != "") else moving_unit.name

					if ui and ui.has_method("log_action"):
						ui.log_action("🎯 [OVERWATCH] %s ambushes %s entering crosshairs for %d damage!" % [watcher_name, target_name, ow_damage])
					if ui and ui.has_method("spawn_damage_popup"):
						ui.spawn_damage_popup(moving_unit.position, "OVERWATCH! (-%d)" % ow_damage, "damage")

					if moving_unit.has_method("take_damage"):
						moving_unit.take_damage(ow_damage, watcher.position, 30, 100, true)

					_is_resolving_reaction = false
					return true
	return false
