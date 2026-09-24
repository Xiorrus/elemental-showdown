extends SceneTree

# Exercises each new campaign's actual equipped skills through World.tscn.
var passed := 0
var failed := 0

const STARTERS = {
	"fire": ["Thermal_Radiation", "Combustion", "heat_wave"],
	"water": ["Aqua_Mend", "Ice", "hydration_touch"],
	"earth": ["Stone_Plating", "Metal", "stone_skin"],
	"air": ["Gale_Step", "Wind", "wind_slip"]
}

func _init():
	_run.call_deferred()

func check(condition: bool, label: String):
	if condition:
		passed += 1
		print("[PASS] " + label)
	else:
		failed += 1
		printerr("[FAIL] " + label)

func _remove_status(unit, effect: String):
	var remaining: Array = []
	for status in unit.status_effects:
		if status.get("name", "") != effect:
			remaining.append(status)
	unit.status_effects = remaining

func _wait_for_player_round(bm):
	var deadline = Time.get_ticks_msec() + 3000
	while bm._enemy_sequence_running and Time.get_ticks_msec() < deadline:
		await process_frame
	check(not bm._enemy_sequence_running and bm.current_state == bm.State.PLAYER_MOVE,
		"Support action returns to the next player round")

func _run():
	var cm = root.get_node("CampaignManager")
	for element in STARTERS:
		var expected: Array = STARTERS[element]
		cm.init_new_campaign({"player_name": "Smoke", "player_element": element, "start_solo": true})
		var world = load("res://scenes/World.tscn").instantiate()
		root.add_child(world)
		await process_frame
		await process_frame
		await process_frame

		var player = world.get_node("Player")
		var enemy = world.get_node("Enemy")
		var bm = world.get_node("BattleManager")
		check(player.element == element and player.equipped_abilities == expected.slice(0, 2),
			"%s battle equips its support and attack starters" % element)
		check(player.get_ability_variation_info(expected[0]).form_key == expected[2],
			"%s support starter uses its intended first form" % element)

		# Keep the enemy alive and idle so this checks the player's full turn flow.
		enemy.ability_pool = []
		enemy.base_speed = 0
		enemy.max_hp = 1000
		enemy.hp = 1000
		enemy.agility = 80
		player.max_hp = 1000
		player.hp = 600 if element == "water" else 1000
		player.dexterity = 200
		var hp_before_support = player.hp
		player.end_move_phase()
		await player.use_ability(0, player)

		match element:
			"fire", "earth":
				check(player.has_status("defense_buff"), "%s support grants defense" % element)
				var with_buff: int = player.take_damage(40, Vector2.ZERO, 20, 100, true)
				_remove_status(player, "defense_buff")
				var without_buff: int = player.take_damage(40, Vector2.ZERO, 20, 100, true)
				check(with_buff < without_buff, "%s support reduces actual damage" % element)
			"water":
				check(player.hp > hp_before_support, "water support restores HP")
			"air":
				check(player.has_status("evasion"), "air support grants evasion")
				var attacker_pos: Vector2 = player.position + player.get_facing_vector() * 64
				var with_buff: float = player.calculate_directional_hit(attacker_pos, 0, 70).hit_chance
				_remove_status(player, "evasion")
				var without_buff: float = player.calculate_directional_hit(attacker_pos, 0, 70).hit_chance
				check(with_buff < without_buff, "air support lowers an attacker's hit chance")

		await _wait_for_player_round(bm)
		enemy.position = player.position + Vector2(64, 0)
		enemy.facing_frame = 4 # The player attacks from behind for a certain hit.
		enemy.hp = 1000
		var enemy_hp_before = enemy.hp
		player.end_move_phase()
		await player.use_ability(1, enemy)
		check(enemy.hp < enemy_hp_before, "%s attack starter damages an enemy" % element)

		world.queue_free()
		await process_frame

	cm.has_active_campaign = false
	print("STARTER COMBAT SMOKE: %d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
