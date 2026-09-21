extends Node2D

# ──────────────────────────────────────────────
#  ELEMENTAL SHOWDOWN — World
#  Wires together: ElementData, CampaignManager, Player, Enemy, UI, BattleManager
# ──────────────────────────────────────────────

const PLAYER_SCENE = preload("res://scenes/Player.tscn")
var battle_manager: Node = null

func _ready():
	get_tree().paused = false

	# ── Camera: Zoomed-out retro perspective framing the grand stadium ──
	var camera = Camera2D.new()
	camera.name = "ArenaCamera"
	camera.position = Vector2(576, 320) # Center of 9x5 arena (1152x640)
	camera.zoom = Vector2(0.55, 0.55)   # Perfectly frames combat stage, sand ring, and spectator stands
	add_child(camera)

	# ── Seamless Arena Background & Grand Stadium ─────
	var tilemap = get_node_or_null("TileMapLayer")
	if tilemap:
		tilemap.visible = false

	var courtyard_tex = load("res://assets/cobblestone_courtyard.png")
	if courtyard_tex:
		var courtyard = Sprite2D.new()
		courtyard.name = "CourtyardBackground"
		courtyard.texture = courtyard_tex
		courtyard.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
		courtyard.region_enabled = true
		courtyard.region_rect = Rect2(-3000, -3000, 8000, 8000)
		courtyard.centered = false
		courtyard.position = Vector2(-3000, -3000)
		courtyard.z_index = -20
		add_child(courtyard)

	var stadium_tex = load("res://assets/stadium_arena.png")
	if stadium_tex:
		var stadium_sprite = Sprite2D.new()
		stadium_sprite.name = "StadiumArena"
		stadium_sprite.texture = stadium_tex
		stadium_sprite.centered = true
		stadium_sprite.position = Vector2(576, 320)
		stadium_sprite.z_index = -10
		add_child(stadium_sprite)
	else:
		var floor_tex = load("res://assets/arena_floor.png")
		if floor_tex:
			var floor_sprite = Sprite2D.new()
			floor_sprite.name = "ArenaPlatform"
			floor_sprite.texture = floor_tex
			floor_sprite.centered = false
			floor_sprite.position = Vector2(0, 0)
			floor_sprite.z_index = -10
			add_child(floor_sprite)

	# ── Instantiate BattleManager ──────────────
	battle_manager = preload("res://scripts/battle_manager.gd").new()
	battle_manager.name = "BattleManager"
	add_child(battle_manager)

	# ── Get scene nodes ────────────────────────
	var player = get_node("Player")
	var enemy  = get_node("Enemy")
	var ui     = get_node("UI")

	# ── Resolve Combatants & Match Format from CampaignManager or Fallbacks ──
	var cm = get_node_or_null("/root/CampaignManager")
	var edata = get_node_or_null("/root/ElementData")
	if edata == null:
		edata = load("res://scripts/element_data.gd").new()

	var m_format = "1v1"
	if cm and cm.has_active_campaign:
		if not cm.has_team:
			m_format = "1v1"
		elif "active_match_format" in cm and cm.active_match_format != "":
			m_format = cm.active_match_format
		elif cm.active_match_type == "street" or cm.active_enemy_name.begins_with("Zero"):
			m_format = "1v1"
		else:
			m_format = "3v3"
	battle_manager.set_match_format(m_format)

	var player_elem = "fire"
	var player_display_name = "Fire Fighter"
	var player_sheet = "fire"
	var enemy_elem = "water"
	var enemy_display_name = "Water Rival"
	var enemy_sheet = "water"

	if cm and cm.has_active_campaign:
		player_elem = cm.player_element
		player_display_name = cm.player_name
		player_sheet = cm.appearance.get("sheet_prefix", cm.player_element)
		enemy_elem = cm.active_enemy_element if cm.active_enemy_element != "" else "water"
		enemy_display_name = cm.active_enemy_name if cm.active_enemy_name != "" else "Water Rival"
		if cm.active_enemy_team != "":
			enemy_display_name += " (" + cm.active_enemy_team + ")"
		enemy_sheet = enemy_elem
	else:
		if edata and edata.ELEMENTS.has("fire"):
			player_display_name = edata.ELEMENTS["fire"]["display_name"] + " Fighter"
		if edata and edata.ELEMENTS.has("water"):
			enemy_display_name = edata.ELEMENTS["water"]["display_name"] + " Fighter"

	# ── Assign elements & modular appearance ────
	player.element = player_elem
	player.character_name = player_display_name
	player.set_appearance(player_sheet)

	enemy.element = enemy_elem
	enemy.set_appearance(enemy_sheet)

	# ── Tile-aligned starting positions (centered in 64px tiles) ────
	var start_tile = Vector2i(3, 4)
	if cm and cm.has_active_campaign and "starting_formation" in cm:
		if cm.starting_formation.has(cm.player_name) and cm.starting_formation[cm.player_name] is Vector2i:
			start_tile = cm.starting_formation[cm.player_name]
		elif cm.starting_formation.has("player") and cm.starting_formation["player"] is Vector2i:
			start_tile = cm.starting_formation["player"]
	player.position = Vector2(start_tile.x * 64 + 32, start_tile.y * 64 + 32)
	enemy.position  = Vector2(7 * 64 + 32, 4 * 64 + 32)

	# ── Wire references ────────────────────────
	player.battle_manager = battle_manager
	player.ui             = ui
	player.element_db     = edata

	enemy.battle_manager  = battle_manager
	enemy.player          = player
	enemy.ui              = ui
	enemy.element_db      = edata

	if player.has_method("apply_element_stats"):
		player.apply_element_stats(player_elem)
	if enemy.has_method("apply_element_stats"):
		enemy.apply_element_stats(enemy_elem)

	battle_manager.enemy  = enemy
	battle_manager.player = player

	# ── Instantiate GridOverlay ────────────────
	var grid_overlay = preload("res://scripts/grid_overlay.gd").new()
	grid_overlay.name = "GridOverlay"
	grid_overlay.tilemap = tilemap
	grid_overlay.player = player
	grid_overlay.enemy = enemy
	add_child(grid_overlay)

	player.grid_overlay = grid_overlay
	battle_manager.grid_overlay = grid_overlay

	grid_overlay.move_tile_clicked.connect(func(tile, dist):
		if battle_manager and battle_manager.active_player_unit and is_instance_valid(battle_manager.active_player_unit):
			battle_manager.active_player_unit.on_move_tile_clicked(tile, dist)
	)
	grid_overlay.attack_tile_clicked.connect(func(tile):
		if battle_manager and battle_manager.active_player_unit and is_instance_valid(battle_manager.active_player_unit):
			battle_manager.active_player_unit.on_attack_tile_clicked(tile)
	)
	grid_overlay.right_mouse_clicked.connect(func():
		if battle_manager and battle_manager.active_player_unit and is_instance_valid(battle_manager.active_player_unit):
			battle_manager.active_player_unit.on_right_mouse_clicked()
	)
	grid_overlay.ally_clicked.connect(func(ally):
		if battle_manager and is_instance_valid(ally):
			battle_manager.select_active_player_unit(ally)
	)

	# ── Direct Squad Control: Multi-Unit Spawning for 3v3 and 5v5 ──
	var player_units = [player]
	var enemy_units = [enemy]

	if m_format == "3v3" or m_format == "5v5":
		var target_count = 3 if m_format == "3v3" else 5
		var default_ally_positions = [Vector2i(2, 3), Vector2i(2, 5), Vector2i(1, 4), Vector2i(1, 2)]
		var ally_index = 0

		if cm and cm.has_active_campaign and not cm.allies.is_empty():
			for a_data in cm.allies:
				if player_units.size() >= target_count:
					break
				if a_data["name"] == cm.player_name:
					continue

				var a_pos_tile = default_ally_positions[ally_index] if ally_index < default_ally_positions.size() else Vector2i(1, 4)
				var is_benched = false
				if "starting_formation" in cm and cm.starting_formation.has(a_data["name"]):
					var cand_pos = cm.starting_formation[a_data["name"]]
					if cand_pos is Vector2i:
						if cand_pos == Vector2i(-1, -1):
							is_benched = true
						else:
							a_pos_tile = cand_pos
				elif cm.designated_sub != "" and a_data["name"] == cm.designated_sub:
					is_benched = true

				if is_benched:
					continue

				var ally_unit = PLAYER_SCENE.instantiate()
				ally_unit.name = a_data["name"]
				add_child(ally_unit)

				# Wire references strictly AFTER add_child()
				ally_unit.battle_manager = battle_manager
				ally_unit.ui = ui
				ally_unit.element_db = edata
				ally_unit.grid_overlay = grid_overlay

				# Assign stats AFTER add_child() — _ready() has now run and set element defaults
				var b_stats = a_data.get("base_stats", {})
				var a_hp = a_data.get("hp", b_stats.get("hp", 100))
				var a_mp = a_data.get("mp", b_stats.get("mp", 100))
				var a_sta = a_data.get("stamina", b_stats.get("stamina", 100))
				var a_spd = a_data.get("speed", b_stats.get("speed", 3))
				var a_agi = a_data.get("agility", b_stats.get("agility", 25))
				var a_dex = a_data.get("dexterity", b_stats.get("dexterity", 25))
				var a_known = a_data.get("known_skills", a_data.get("skills", [])).duplicate()
				var a_equipped = a_data.get("equipped_skills", a_data.get("skills", ["Gale_Step"])).duplicate()

				ally_unit.element = a_data.get("element", "air")
				ally_unit.set_appearance(a_data.get("element", "air"))
				ally_unit.position = Vector2(a_pos_tile.x * 64 + 32, a_pos_tile.y * 64 + 32)
				ally_unit.max_hp = a_hp
				ally_unit.hp = ally_unit.max_hp
				ally_unit.max_mp = a_mp
				ally_unit.mp = ally_unit.max_mp
				ally_unit.max_stamina = a_sta
				ally_unit.stamina = ally_unit.max_stamina
				ally_unit.base_speed = a_spd
				ally_unit.agility = a_agi
				ally_unit.dexterity = a_dex
				ally_unit.moves_remaining = ally_unit.get_total_speed()
				ally_unit.unlocked_abilities = a_known
				# equipped_abilities MUST be assigned last — overrides _ready() default
				ally_unit.equipped_abilities = a_equipped
				player_units.append(ally_unit)
				ally_index += 1
		else:
			var fallback_allies = [
				{"name": "Kora", "element": "air", "skills": ["Gale_Step", "Wind"], "pos": Vector2i(2, 3), "stamina": 105, "hp": 80, "mp": 110, "speed": 4, "agility": 38, "dexterity": 28},
				{"name": "Gaius", "element": "earth", "skills": ["Stone_Plating", "Metal"], "pos": Vector2i(2, 5), "stamina": 120, "hp": 130, "mp": 90, "speed": 2, "agility": 16, "dexterity": 24},
				{"name": "Torque", "element": "fire", "skills": ["Lightning"], "pos": Vector2i(1, 4), "stamina": 100, "hp": 90, "mp": 100, "speed": 3, "agility": 28, "dexterity": 32},
				{"name": "Mira", "element": "water", "skills": ["Aqua_Mend"], "pos": Vector2i(1, 2), "stamina": 100, "hp": 100, "mp": 120, "speed": 3, "agility": 25, "dexterity": 25}
			]
			for f_data in fallback_allies:
				if player_units.size() >= target_count:
					break
				var ally_unit = PLAYER_SCENE.instantiate()
				ally_unit.name = f_data["name"]
				add_child(ally_unit)

				# Wire references strictly AFTER add_child()
				ally_unit.battle_manager = battle_manager
				ally_unit.ui = ui
				ally_unit.element_db = edata
				ally_unit.grid_overlay = grid_overlay

				# Assign stats AFTER add_child() — _ready() has now run
				var f_hp = f_data.get("hp", 100)
				var f_mp = f_data.get("mp", 100)
				var f_sta = f_data.get("stamina", 100)
				var f_spd = f_data.get("speed", 3)
				var f_agi = f_data.get("agility", 25)
				var f_dex = f_data.get("dexterity", 25)
				var f_skills = f_data.get("skills", []).duplicate()

				ally_unit.element = f_data["element"]
				ally_unit.set_appearance(f_data["element"])
				ally_unit.position = Vector2(f_data["pos"].x * 64 + 32, f_data["pos"].y * 64 + 32)
				ally_unit.max_hp = f_hp
				ally_unit.hp = ally_unit.max_hp
				ally_unit.max_mp = f_mp
				ally_unit.mp = ally_unit.max_mp
				ally_unit.max_stamina = f_sta
				ally_unit.stamina = ally_unit.max_stamina
				ally_unit.base_speed = f_spd
				ally_unit.agility = f_agi
				ally_unit.dexterity = f_dex
				ally_unit.moves_remaining = ally_unit.get_total_speed()
				ally_unit.unlocked_abilities = f_skills
				# equipped_abilities MUST be assigned last
				ally_unit.equipped_abilities = f_skills
				player_units.append(ally_unit)


		# Spawn enemy squadmates
		var enemy_scene = preload("res://scenes/enemy.tscn")
		var default_enemy_positions = [Vector2i(8, 3), Vector2i(8, 5), Vector2i(9, 4), Vector2i(9, 2)]
		var enemy_elements = ["air", "earth", "fire", "water"]
		for i in range(target_count - 1):
			var extra_enemy = enemy_scene.instantiate()
			extra_enemy.name = "Enemy_%d" % (i + 1)
			extra_enemy.element = enemy_elements[i % enemy_elements.size()]
			add_child(extra_enemy)
			var e_tile = default_enemy_positions[i]
			extra_enemy.position = Vector2(e_tile.x * 64 + 32, e_tile.y * 64 + 32)
			extra_enemy.battle_manager = battle_manager
			extra_enemy.ui = ui
			extra_enemy.player = player
			extra_enemy.element_db = edata
			extra_enemy.set_appearance(extra_enemy.element)
			enemy_units.append(extra_enemy)

	battle_manager.player_units = player_units
	battle_manager.enemy_units = enemy_units
	battle_manager.active_player_unit = player

	# ── Initial UI sync ───────────────────────
	await get_tree().process_frame

	# Sync progression, stats, and equipped abilities from CampaignManager
	if cm and cm.has_active_campaign:
		player.level = cm.player_level
		player.xp = cm.player_xp
		player.xp_to_next_level = cm.player_xp_to_next
		player.base_speed = cm.player_speed
		player.agility = cm.player_agility
		player.dexterity = cm.player_dexterity
		player.max_stamina = cm.player_stamina
		player.stamina = player.max_stamina
		player.max_mp = cm.player_mana
		player.mp = player.max_mp
		if edata and edata.ELEMENTS.has(player_elem):
			var b_hp = edata.ELEMENTS[player_elem].get("base_hp", 100)
			player.max_hp = b_hp + (player.level - 1) * 10
			player.hp = player.max_hp
		player.moves_remaining = player.get_total_speed()
		if not cm.equipped_abilities.is_empty():
			player.equipped_abilities = cm.equipped_abilities.duplicate()
		if not cm.unlocked_abilities.is_empty():
			player.unlocked_abilities = cm.unlocked_abilities.duplicate()

		# Apply fatigue penalties if energy is low
		if cm.is_fatigued:
			var mods = cm.get_fatigue_stat_modifiers()
			player.max_hp = int(player.max_hp * mods.hp_mult)
			player.hp = player.max_hp
			player.max_mp = int(player.max_mp * mods.mp_mult)
			player.mp = player.max_mp
			player.base_speed = max(1, player.base_speed - mods.speed_penalty)
			player.moves_remaining = player.get_total_speed()
			ui.log_action("FATIGUE WARNING: Combatant is exhausted! -20% HP/MP & -1 Speed!")

	ui.update_player_stats(player.hp, player.max_hp, player.mp, player.max_mp, player.stamina, player.max_stamina)
	ui.update_enemy_stats(enemy.hp, enemy.max_hp, enemy.mp, enemy.max_mp, enemy.stamina, enemy.max_stamina)
	ui.update_xp(player.level, player.xp, player.xp_to_next_level)
	ui.update_moves(player.moves_remaining)
	ui.update_abilities(player.equipped_abilities, edata)
	ui.highlight_ability_slot(0)
	if ui.has_method("update_sub_count"):
		ui.update_sub_count(battle_manager.subs_remaining)

	# Wire ornate combatant names into UI
	if ui.has_method("set_player_name"):
		ui.set_player_name(player_display_name, player_elem)
	if ui.has_method("set_enemy_name"):
		ui.set_enemy_name(enemy_display_name, enemy_elem)

	ui._player_ref = player

	# Start battle
	battle_manager.start_player_turn()
	print("[World] Battle started: %s (%s) vs %s (%s)" % [player_display_name, player_elem, enemy_display_name, enemy_elem])
