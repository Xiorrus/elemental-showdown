extends SceneTree

const Geometry = preload("res://scripts/ability_geometry.gd")

var passed := 0
var failed := 0

class TestPlayer extends "res://scripts/player.gd":
	func _ready():
		add_to_group("players")
		add_to_group("combatants")
	func _play_attack_anim(_ability: Dictionary, _target: Vector2):
		pass

class TestEnemy extends "res://scripts/enemy.gd":
	func _ready():
		add_to_group("enemies")
		add_to_group("combatants")
	func _play_attack_anim(_ability: Dictionary, _target: Vector2):
		pass

func _init() -> void:
	_run.call_deferred()

func check(condition: bool, label: String) -> void:
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _at(x: int, y: int) -> Vector2:
	return Vector2(x * 64 + 32, y * 64 + 32)

func _run() -> void:
	var data = root.get_node_or_null("ElementData")
	if data == null:
		data = load("res://scripts/element_data.gd").new()
		root.add_child(data)
	var p := TestPlayer.new()
	var p_sprite := Sprite2D.new()
	p_sprite.name = "Sprite2D"
	p.add_child(p_sprite)
	root.add_child(p)
	p.element_db = data
	p.element = "fire"
	p.dexterity = 200
	p.hp = 500
	p.max_hp = 500
	p.position = _at(3, 4)
	p.equipped_abilities = ["Combustion"]
	p.active_skill_forms["Combustion"] = "pulse"
	var e := TestEnemy.new()
	var e_sprite := Sprite2D.new()
	e_sprite.name = "Sprite2D"
	e.add_child(e_sprite)
	root.add_child(e)
	e.element_db = data
	e.apply_element_stats("fire")
	e.player = p
	e.agility = 0
	e.defense = 0
	e.hp = 500
	e.max_hp = 500
	var punch: Dictionary = {}
	var pulse: Dictionary = {}
	for form in e.ability_pool:
		if form.get("name", "") == "Explosive Punch": punch = form
		if form.get("name", "") == "Explosion Pulse": pulse = form
	check(not punch.is_empty() and not pulse.is_empty(), "AI uses existing Combustion forms")
	check(Geometry.range_multiplier("close", 1) == 1.25 and Geometry.range_multiplier("mid", 2) == 1.25 and Geometry.range_multiplier("long", 4) == 1.25,
		"Close, mid, and long forms each gain 25% damage in their own band")
	check(Geometry.effective_reach("Ice Lance", 1) == 4 and Geometry.shape_for("Ice Lance", "cardinal") == "linear_front",
		"Existing Ice Lance reaches a long straight lane")
	check(not Geometry.is_multi_target("linear_front", "Needle Beam") and Geometry.is_multi_target("wide_slash", "Prism Sweep"),
		"Needle Beam stays single-target while Prism Sweep covers multiple targets")

	# The damage test casts the same existing form at two legal distances.
	var combustion: Dictionary = data.ABILITIES["Combustion"].duplicate(true)
	combustion["key"] = "Combustion"
	e.position = _at(7, 4)
	await p._execute_ability(combustion, e, 0)
	var long_damage: int = 500 - e.hp
	e.hp = 500
	e.position = _at(4, 4)
	await p._execute_ability(combustion, e, 0)
	var close_damage: int = 500 - e.hp
	check(long_damage > close_damage and long_damage >= 40 and close_damage <= 30,
		"Player Pulse deals more damage at its preferred long distance")

	# Ability selection uses the same range calculation as actual damage.
	p.position = _at(6, 4)
	p.facing_frame = 4
	p.agility = 60
	e.agility = 0
	e.position = _at(7, 4)
	e.ability_pool = [punch, pulse]
	var near_choice: Dictionary = e._best_attack_from(Geometry.tile_of(e.position))
	check(near_choice.get("ability", {}).get("name", "") == "Explosive Punch", "AI chooses close Punch at one tile")
	e.position = _at(10, 4)
	var far_choice: Dictionary = e._best_attack_from(Geometry.tile_of(e.position))
	check(far_choice.get("ability", {}).get("name", "") == "Explosion Pulse", "AI chooses long Pulse at four tiles")

	# An enemy with only the ranged form walks away from point-blank range.
	e.position = _at(7, 4)
	e.ability_pool = [pulse]
	e.base_speed = 3
	e.mp = 100
	p.agility = 0
	await e.take_turn()
	var new_distance: int = absi(Geometry.tile_of(e.position).x - 6) + absi(Geometry.tile_of(e.position).y - 4)
	check(new_distance >= 4, "AI repositions into Pulse's long-range bonus before casting (distance %d, tile %s)" % [new_distance, str(Geometry.tile_of(e.position))])

	# With a melee form, the same AI pursues the defender's side.
	e.position = _at(7, 4)
	e.ability_pool = [punch]
	e.base_speed = 2
	e.mp = 100
	p.hp = 500
	p.agility = 60
	await e.take_turn()
	var flank_tile: Vector2i = Geometry.tile_of(e.position)
	check(flank_tile.x == 6 and absi(flank_tile.y - 4) == 1,
		"AI moves from the defender's front to a side square before punching")
	e.position = _at(7, 4)
	e.base_speed = 4
	e.mp = 100
	p.hp = 500
	await e.take_turn()
	check(Geometry.tile_of(e.position) == Vector2i(5, 4),
		"With enough movement, AI circles behind the defender before punching")

	p.queue_free()
	e.queue_free()
	await process_frame
	print("RANGE TACTICS: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
