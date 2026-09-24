class_name AttackIntent
extends RefCounted

# ─────────────────────────────────────────────────────────────────────────────
# AttackIntent
# Immutable-style snapshot representing a telegraphed combat action with windup.
# Tracks origin, frozen target area, countdown, and cancellation state.
# ─────────────────────────────────────────────────────────────────────────────

var id: String = ""
var caster: Node2D = null
var caster_team: String = "player" # "player" or "enemy"
var ability_key: String = ""
var ability_name: String = ""
var ability_data: Dictionary = {}
var origin_tile: Vector2i = Vector2i.ZERO
var aimed_tile: Vector2i = Vector2i.ZERO
var target_tiles: Array[Vector2i] = []
var windup_rounds: int = 1
var rounds_remaining: int = 1
var is_cancelled: bool = false
var cancel_reason: String = "" # "displacement", "stun", "ko", "destroyed_terrain"
var is_resolved: bool = false

func _init(
	p_caster: Node2D = null,
	p_team: String = "player",
	p_key: String = "",
	p_name: String = "",
	p_ability: Dictionary = {},
	p_origin: Vector2i = Vector2i.ZERO,
	p_aimed: Vector2i = Vector2i.ZERO,
	p_tiles: Array[Vector2i] = [],
	p_windup: int = 1
) -> void:
	caster = p_caster
	caster_team = p_team
	ability_key = p_key
	ability_name = p_name
	ability_data = p_ability.duplicate(true)
	origin_tile = p_origin
	aimed_tile = p_aimed
	target_tiles = p_tiles.duplicate()
	windup_rounds = max(1, p_windup)
	rounds_remaining = windup_rounds
	id = "intent_%d_%s_%s" % [Time.get_ticks_msec(), ability_key, str(origin_tile)]

func tick_round() -> bool:
	if is_cancelled or is_resolved:
		return false
	rounds_remaining -= 1
	return rounds_remaining <= 0

func cancel(reason: String = "displacement") -> void:
	if is_cancelled or is_resolved:
		return
	is_cancelled = true
	cancel_reason = reason

func can_resolve() -> bool:
	if is_cancelled or is_resolved:
		return false
	if caster == null or not is_instance_valid(caster):
		return false
	if "hp" in caster and caster.hp <= 0:
		return false
	if caster.has_method("is_stunned") and caster.is_stunned():
		return false
	return true

func to_dict() -> Dictionary:
	return {
		"id": id,
		"caster_team": caster_team,
		"ability_key": ability_key,
		"ability_name": ability_name,
		"origin_tile": [origin_tile.x, origin_tile.y],
		"aimed_tile": [aimed_tile.x, aimed_tile.y],
		"target_tiles": target_tiles.map(func(t: Vector2i): return [t.x, t.y]),
		"windup_rounds": windup_rounds,
		"rounds_remaining": rounds_remaining,
		"is_cancelled": is_cancelled,
		"cancel_reason": cancel_reason,
		"is_resolved": is_resolved
	}
