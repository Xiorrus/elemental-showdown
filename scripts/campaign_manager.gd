# campaign_manager.gd
# Central persistent autoload for Elemental Showdown campaign, tournament schedule,
# energy & fatigue mechanics, opponent scouting intel, and save/load operations.
extends Node

const SAVE_PATH = "user://campaign_save.json"
const MAX_ENERGY = 100
const FATIGUE_THRESHOLD = 30
const MAX_ROSTER_SIZE = 10
const RECRUITMENT_WINS_THRESHOLD = 3

# ──────────────────────────────────────────────
#  FIGHTER GENERATION — LEAGUE TIERS
# ──────────────────────────────────────────────
const LEAGUE_TIERS = {
	1: {"name": "Bronze",  "hp_min": 70,  "hp_max": 100, "mp_min": 80,  "mp_max": 110,
		"spd_min": 2, "spd_max": 3, "agi_min": 16, "agi_max": 28,
		"dex_min": 20, "dex_max": 30, "sta_min": 80,  "sta_max": 110,
		"lvl_min": 1,  "lvl_max": 5},
	2: {"name": "Silver",  "hp_min": 90,  "hp_max": 120, "mp_min": 100, "mp_max": 130,
		"spd_min": 3, "spd_max": 4, "agi_min": 24, "agi_max": 36,
		"dex_min": 26, "dex_max": 38, "sta_min": 100, "sta_max": 130,
		"lvl_min": 6,  "lvl_max": 12},
	3: {"name": "Gold",    "hp_min": 110, "hp_max": 145, "mp_min": 120, "mp_max": 150,
		"spd_min": 3, "spd_max": 5, "agi_min": 32, "agi_max": 48,
		"dex_min": 32, "dex_max": 46, "sta_min": 120, "sta_max": 150,
		"lvl_min": 13, "lvl_max": 22},
	4: {"name": "Diamond", "hp_min": 130, "hp_max": 170, "mp_min": 140, "mp_max": 180,
		"spd_min": 4, "spd_max": 5, "agi_min": 44, "agi_max": 60,
		"dex_min": 42, "dex_max": 55, "sta_min": 140, "sta_max": 170,
		"lvl_min": 23, "lvl_max": 35},
	5: {"name": "Apex",    "hp_min": 160, "hp_max": 200, "mp_min": 170, "mp_max": 210,
		"spd_min": 5, "spd_max": 6, "agi_min": 56, "agi_max": 72,
		"dex_min": 52, "dex_max": 68, "sta_min": 160, "sta_max": 200,
		"lvl_min": 36, "lvl_max": 50},
}

const ARCHETYPES = ["Striker", "Scout", "Defender", "Support"]
const GEN_ELEMENTS = ["fire", "water", "earth", "air"]

const FIGHTER_NAMES_FIRST = [
	"Remy", "Sable", "Dara", "Cael", "Nyx", "Oryn", "Voss", "Tala", "Zek", "Lyric",
	"Fen", "Roan", "Brix", "Dessa", "Korin", "Mael", "Sura", "Tev", "Wren", "Zain",
	"Ash", "Cass", "Dune", "Elio", "Faye", "Grim", "Hara", "Ivek", "Jax", "Kael",
	"Lira", "Mors", "Nael", "Osta", "Pyre", "Quin", "Rale", "Sorn", "Thex", "Urel"
]
const FIGHTER_NAMES_LAST = [
	"Flint", "Vane", "Stone", "Cross", "Holt", "Drake", "Crane", "Tide", "Gale",
	"Marsh", "Frost", "Blaze", "Peak", "Rush", "Vale", "Ward", "Shard", "Ridge",
	"Storm", "Brand", "Coil", "Dusk", "Edge", "Fall", "Gust", "Haze", "Iron",
	"Jade", "Knox", "Loch", "Mire", "Null", "Opal", "Pine", "Quill", "Rime"
]

# Default skills per element when ElementData is unavailable
const DEFAULT_ELEMENT_SKILLS = {
	"fire": ["Combustion"], "water": ["Aqua_Mend"],
	"earth": ["Stone_Plating"], "air": ["Gale_Step"]
}

# ──────────────────────────────────────────────
#  ACTIVE CAMPAIGN STATE
# ──────────────────────────────────────────────
var has_active_campaign: bool = false

# Player Profile
var player_name: String = "Ignis"
var player_element: String = "fire"
var unlocked_elements: Array = ["fire"]
var player_level: int = 1
var player_xp: int = 0
var player_xp_to_next: int = 100
var equipped_abilities: Array = ["Combustion"]
var unlocked_abilities: Array = ["Combustion"]
var player_speed: int = 3
var player_agility: int = 28
var player_dexterity: int = 32
var player_stamina: int = 100
var player_mana: int = 100
var player_potency: int = 30
var unspent_stat_points: int = 5
var unspent_skill_points: int = 2
var active_match_format: String = "3v3"
var designated_sub: String = "Gaius"
var starting_formation: Dictionary = {
	"Ignis": Vector2i(3, 4),
	"Kora": Vector2i(2, 3),
	"Gaius": Vector2i(2, 5)
}
var skill_variations: Dictionary = {}
var unlocked_skill_forms: Dictionary = {}

# ──────────────────────────────────────────────
#  FIGHTER CAREER STATE
# ──────────────────────────────────────────────
var league_tier: int = 1         # Current league tier 1–5
var street_wins: int = 0         # Street-brawler wins before joining a team
var has_team: bool = false        # Whether the player has joined an organised team
var known_fighters: Array = []   # All individual athletes the player has ever encountered
var career_team: String = "Phoenix Strikers"


# Visual Customization
var appearance: Dictionary = {
	"hair_style": "spiky",
	"hair_color": "crimson",
	"skin_tone": "peach",
	"outfit_style": "martial_gi",
	"team_palette": "fire",
	"sheet_prefix": "fire"
}

# Energy & Fatigue
var energy: int = 100
var is_fatigued: bool = false
var bench_risk: bool = false

# League & Tournament Progression
var current_league: String = "Bronze League (Street Tier)"
var league_round: int = 1
var total_wins: int = 0
var total_losses: int = 0
var win_streak: int = 0

# Economy & Currencies
var gold: int = 150
var shards: int = 0

# Timeline & Campaign Calendar
var campaign_day: int = 1

# Roster & Allies
var team_name: String = "Phoenix Strikers"
var allies: Array = [
	{
		"name": "Ignis",
		"element": "fire",
		"role": "Team Captain (Player)",
		"archetype": "Striker",
		"level": 1,
		"league_tier": 1,
		"base_stats": {
			"hp": 90, "mp": 100, "stamina": 100, "speed": 3, "agility": 28, "dexterity": 32
		},
		"hp": 90,
		"mp": 100,
		"stamina": 100,
		"speed": 3,
		"agility": 28,
		"dexterity": 32,
		"potential": 85,
		"status": "Active",
		"career_team": "Phoenix Strikers",
		"equipped_skills": ["Combustion"],
		"known_skills": ["Combustion", "Laser"]
	},
	{
		"name": "Kora",
		"element": "air",
		"role": "Scout / Tactician",
		"archetype": "Scout",
		"level": 1,
		"league_tier": 1,
		"base_stats": {
			"hp": 80, "mp": 110, "stamina": 105, "speed": 4, "agility": 38, "dexterity": 28
		},
		"hp": 80,
		"mp": 110,
		"stamina": 105,
		"speed": 4,
		"agility": 38,
		"dexterity": 28,
		"potential": 78,
		"status": "Reserve",
		"career_team": "Phoenix Strikers",
		"equipped_skills": ["Gale_Step", "Wind"],
		"known_skills": ["Gale_Step", "Wind", "Sound_Sonic"]
	},
	{
		"name": "Gaius",
		"element": "earth",
		"role": "Defender / Anchor",
		"archetype": "Defender",
		"level": 1,
		"league_tier": 1,
		"base_stats": {
			"hp": 130, "mp": 90, "stamina": 120, "speed": 2, "agility": 16, "dexterity": 24
		},
		"hp": 130,
		"mp": 90,
		"stamina": 120,
		"speed": 2,
		"agility": 16,
		"dexterity": 24,
		"potential": 72,
		"status": "Reserve",
		"career_team": "Phoenix Strikers",
		"equipped_skills": ["Stone_Plating", "Metal"],
		"known_skills": ["Stone_Plating", "Metal", "Crystal"]
	}
]

# Tournament Schedule
var tournament_schedule: Array = [
	{
		"round": 1,
		"league": "Bronze League",
		"enemy_team": "Hydro Vipers",
		"enemy_captain": "Nami",
		"enemy_element": "water",
		"difficulty": "Normal",
		"completed": false,
		"result": ""
	},
	{
		"round": 2,
		"league": "Bronze League",
		"enemy_team": "Gale Force",
		"enemy_captain": "Zephyr",
		"enemy_element": "air",
		"difficulty": "Challenging",
		"completed": false,
		"result": ""
	},
	{
		"round": 3,
		"league": "Bronze Finals",
		"enemy_team": "Terra Titans",
		"enemy_captain": "Brock",
		"enemy_element": "earth",
		"difficulty": "Hard",
		"completed": false,
		"result": ""
	},
	{
		"round": 4,
		"league": "Apex Showdown",
		"enemy_team": "Shadow Faction",
		"enemy_captain": "Zero (The Rival)",
		"enemy_element": "zero",
		"difficulty": "Boss",
		"completed": false,
		"result": ""
	}
]

# Scouting Intel / Codex of Encountered Factions
var scouting_intel: Dictionary = {
	"water": {
		"team_name": "Hydro Vipers",
		"captain": "Nami",
		"element": "water",
		"strengths": ["High MP pool", "Freezing crowd control", "Sustained healing"],
		"weaknesses": ["Earth mass disruption", "Fire thermal combustion"],
		"known_skills": ["Ice", "Pressure_Wave", "Purification"],
		"matches_fought": 1,
		"wins_against": 1,
		"losses_against": 0
	},
	"earth": {
		"team_name": "Terra Titans",
		"captain": "Brock",
		"element": "earth",
		"strengths": ["Highest base HP (130)", "Armor fortification", "Gravity crowd control"],
		"weaknesses": ["Air vacuum strikes", "Water erosion"],
		"known_skills": ["Metal", "Sand", "Crystal"],
		"matches_fought": 0,
		"wins_against": 0,
		"losses_against": 0
	},
	"air": {
		"team_name": "Gale Force",
		"captain": "Zephyr",
		"element": "air",
		"strengths": ["Fastest movement (Speed 4)", "Sonic ranged kiting", "Displacement"],
		"weaknesses": ["Earth density anchors", "Fire explosive burst"],
		"known_skills": ["Wind", "Sound_Sonic", "Vacuum"],
		"matches_fought": 0,
		"wins_against": 0,
		"losses_against": 0
	},
	"zero": {
		"team_name": "Shadow Faction",
		"captain": "Zero (The Rival)",
		"element": "zero",
		"strengths": ["Dual elemental mastery", "Unmaking pinnacle burst", "High aggression"],
		"weaknesses": ["Resource exhaustion", "Close-range counters"],
		"known_skills": ["Destruction", "Nuclear_Ignition", "Pressure_Wave"],
		"matches_fought": 0,
		"wins_against": 0,
		"losses_against": 0
	}
}

# Match Execution Parameters (consumed by World.tscn)
var active_match_type: String = "tournament" # "tournament", "training", "street"
var active_enemy_element: String = "water"
var active_enemy_name: String = "Nami"
var active_enemy_team: String = "Hydro Vipers"

func _ready():
	print("[CampaignManager] Autoload initialized.")

func new_campaign(p_name_or_cfg = null, p_elem = null, t_name: String = "", start_solo: bool = false):
	init_new_campaign(p_name_or_cfg, p_elem, t_name, start_solo)

func init_new_campaign(p_name_or_cfg = null, p_elem = null, t_name: String = "", start_solo: bool = false):
	has_active_campaign = true

	var p_name = "Ignis"
	var p_elem_str = "fire"
	var t_name_str = ""
	var is_solo = false
	var app_cfg = null

	if p_name_or_cfg is Dictionary:
		var cfg = p_name_or_cfg
		p_name = cfg.get("player_name", cfg.get("name", "Ignis"))
		p_elem_str = cfg.get("player_element", cfg.get("element", "fire"))
		if cfg.has("appearance"):
			app_cfg = cfg["appearance"]
		if cfg.has("start_solo") or cfg.has("solo"):
			is_solo = cfg.get("start_solo", cfg.get("solo", false))
			t_name_str = cfg.get("team_name", "" if is_solo else "Phoenix Strikers")
		elif cfg.has("team_name"):
			t_name_str = cfg.get("team_name", "")
			is_solo = (t_name_str == "" or t_name_str == "Street Brawler" or t_name_str == "Free Agent" or t_name_str.to_lower() == "solo")
		else:
			# Default legacy dictionary without explicit team or solo
			t_name_str = "Phoenix Strikers"
			is_solo = false
	elif p_name_or_cfg is String:
		p_name = p_name_or_cfg
		p_elem_str = p_elem if p_elem != null else "fire"
		t_name_str = t_name
		is_solo = start_solo or (t_name == "" or t_name == "Street Brawler" or t_name == "Free Agent" or t_name.to_lower() == "solo")
	else:
		t_name_str = "Phoenix Strikers"
		is_solo = false

	player_name = p_name
	player_element = p_elem_str
	unlocked_elements = [player_element.to_lower()]

	if app_cfg:
		appearance = app_cfg.duplicate(true)
	else:
		appearance["sheet_prefix"] = player_element
		appearance["team_palette"] = player_element

	player_level = 1
	player_xp = 0
	player_xp_to_next = 100
	unspent_stat_points = 5
	unspent_skill_points = 2

	var edata_node = _get_element_data()
	var p_base = {}
	if edata_node and edata_node.ELEMENTS.has(player_element):
		p_base = edata_node.ELEMENTS[player_element]

	player_speed = p_base.get("base_speed", 3)
	player_agility = p_base.get("base_agility", 28)
	player_dexterity = p_base.get("base_dexterity", 32)
	player_stamina = p_base.get("base_stamina", 100)
	player_mana = p_base.get("base_mp", 100)
	player_potency = 30
	energy = 100
	is_fatigued = false
	bench_risk = false
	league_tier = 1
	current_league = "Bronze League (Street Tier)"
	league_round = 1
	total_wins = 0
	total_losses = 0
	win_streak = 0
	street_wins = 0
	gold = 150
	shards = 0
	campaign_day = 1

	var starter_skill = "Combustion"
	if player_element == "water": starter_skill = "Ice"
	elif player_element == "earth": starter_skill = "Metal"
	elif player_element == "air": starter_skill = "Wind"

	equipped_abilities = [starter_skill]
	unlocked_abilities = [starter_skill]
	var edata_starter = _get_element_data()
	var starter_f_keys = edata_starter.get_skill_form_keys(starter_skill) if edata_starter else []
	var starter_first_f = starter_f_keys[0] if not starter_f_keys.is_empty() else "form_1"
	unlocked_skill_forms = { starter_skill: [starter_first_f] }
	skill_variations = { starter_skill: starter_first_f }

	if is_solo:
		team_name = "Street Brawler"
		career_team = "Free Agent"
		has_team = false
		active_match_format = "1v1"
		allies.clear()
		starting_formation = {
			player_name: Vector2i(3, 4)
		}
		designated_sub = ""
		print("[CampaignManager] Created solo street campaign: %s (%s) [Free Agent]" % [player_name, player_element])
	else:
		team_name = t_name_str if t_name_str != "" else "Phoenix Strikers"
		career_team = team_name
		has_team = true
		active_match_format = "3v3"
		_init_default_squad(player_name, player_element, team_name)
		print("[CampaignManager] Created new campaign: %s (%s) of %s" % [player_name, player_element, team_name])

func _init_default_squad(p_name: String, p_elem: String, t_name: String):
	var starter_skill = "Combustion"
	if p_elem == "water": starter_skill = "Ice"
	elif p_elem == "earth": starter_skill = "Metal"
	elif p_elem == "air": starter_skill = "Wind"

	var p_known = [starter_skill]
	if p_elem == "fire" and not p_known.has("Laser"): p_known.append("Laser")

	var edata_node = _get_element_data()
	var p_base = {}
	if edata_node and edata_node.ELEMENTS.has(p_elem):
		p_base = edata_node.ELEMENTS[p_elem]

	var p_hp = p_base.get("base_hp", 90)
	var p_mp = p_base.get("base_mp", 100)
	var p_sta = p_base.get("base_stamina", 100)
	var p_spd = p_base.get("base_speed", 3)
	var p_agi = p_base.get("base_agility", 28)
	var p_dex = p_base.get("base_dexterity", 32)

	allies = [
		{
			"name": p_name,
			"element": p_elem,
			"role": "Team Captain (Player)",
			"archetype": "Striker",
			"level": 1,
			"league_tier": 1,
			"base_stats": {
				"hp": p_hp, "mp": p_mp, "stamina": p_sta, "speed": p_spd, "agility": p_agi, "dexterity": p_dex
			},
			"hp": p_hp,
			"mp": p_mp,
			"stamina": p_sta,
			"speed": p_spd,
			"agility": p_agi,
			"dexterity": p_dex,
			"potential": 85,
			"status": "Active",
			"career_team": t_name,
			"equipped_skills": [starter_skill],
			"known_skills": p_known
		},
		{
			"name": "Kora",
			"element": "air",
			"role": "Scout / Tactician",
			"archetype": "Scout",
			"level": 1,
			"league_tier": 1,
			"base_stats": {
				"hp": 80, "mp": 110, "stamina": 105, "speed": 4, "agility": 38, "dexterity": 28
			},
			"hp": 80,
			"mp": 110,
			"stamina": 105,
			"speed": 4,
			"agility": 38,
			"dexterity": 28,
			"potential": 78,
			"status": "Reserve",
			"career_team": t_name,
			"equipped_skills": ["Gale_Step", "Wind"],
			"known_skills": ["Gale_Step", "Wind", "Sound_Sonic"]
		},
		{
			"name": "Gaius",
			"element": "earth",
			"role": "Defender / Anchor",
			"archetype": "Defender",
			"level": 1,
			"league_tier": 1,
			"base_stats": {
				"hp": 130, "mp": 90, "stamina": 120, "speed": 2, "agility": 16, "dexterity": 24
			},
			"hp": 130,
			"mp": 90,
			"stamina": 120,
			"speed": 2,
			"agility": 16,
			"dexterity": 24,
			"potential": 72,
			"status": "Reserve",
			"career_team": t_name,
			"equipped_skills": ["Stone_Plating", "Metal"],
			"known_skills": ["Stone_Plating", "Metal", "Crystal"]
		}
	]

	designated_sub = "Gaius"
	starting_formation = {
		p_name: Vector2i(3, 4),
		"Kora": Vector2i(2, 3),
		"Gaius": Vector2i(2, 5)
	}

func consume_energy(amount: int) -> bool:
	energy = max(0, energy - amount)
	_evaluate_fatigue()
	print("[CampaignManager] Consumed %d energy. Remaining: %d" % [amount, energy])
	return true

func restore_energy(amount: int):
	energy = min(MAX_ENERGY, energy + amount)
	_evaluate_fatigue()
	print("[CampaignManager] Restored %d energy. Current: %d" % [amount, energy])

func _evaluate_fatigue():
	if energy < FATIGUE_THRESHOLD:
		is_fatigued = true
		bench_risk = (energy < 15)
	else:
		is_fatigued = false
		bench_risk = false

func get_fatigue_stat_modifiers() -> Dictionary:
	if is_fatigued:
		return {
			"hp_mult": 0.8,
			"mp_mult": 0.8,
			"speed_penalty": 1,
			"description": "FATIGUED: -20% HP/MP, -1 Speed (Low Energy)"
		}
	return {
		"hp_mult": 1.0,
		"mp_mult": 1.0,
		"speed_penalty": 0,
		"description": "RESTED: Full combat effectiveness"
	}

func dev_unlock_all():
	var edata = _get_element_data()
	if edata and edata.ABILITIES:
		unlocked_abilities.clear()
		unlocked_skill_forms.clear()
		for skill_key in edata.ABILITIES.keys():
			unlocked_abilities.append(skill_key)
			var f_keys = edata.get_skill_form_keys(skill_key)
			unlocked_skill_forms[skill_key] = f_keys.duplicate()
			if not f_keys.is_empty():
				skill_variations[skill_key] = f_keys[0]
	
	player_level = 30
	player_xp = 0
	energy = 100
	is_fatigued = false
	bench_risk = false

	var starter_pool = ["Combustion", "Laser", "Lightning", "Plasma"]
	if unlocked_abilities.size() >= 4:
		equipped_abilities = unlocked_abilities.slice(0, 4)
	else:
		equipped_abilities = starter_pool

	print("[CampaignManager] [DEV MODE] Unlocked %d skills, boosted to Lv %d!" % [unlocked_abilities.size(), player_level])

func get_next_scheduled_match() -> Dictionary:
	if not has_team:
		var rival_elements = ["water", "earth", "air", "fire"]
		var e_elem = rival_elements[(street_wins) % rival_elements.size()]
		var rival_names = ["Kage", "Slash", "Viper", "Brutus", "Gale", "Cinder"]
		var r_name = rival_names[(street_wins) % rival_names.size()]
		return {
			"round": street_wins + 1,
			"league": "Street Circuit",
			"enemy_team": "Underground Syndicate",
			"enemy_captain": r_name,
			"enemy_element": e_elem,
			"difficulty": "Street Duel",
			"completed": false,
			"result": ""
		}
	for m in tournament_schedule:
		if not m["completed"]:
			return m
	return {}

func get_combat_power() -> int:
	var cp = player_stamina + player_mana + (player_speed + player_agility + player_dexterity) * 5 + player_potency * 10
	if has_team:
		for a in allies:
			if a.get("status", "Active") == "Active" and a.get("name") != player_name:
				var a_stats = a.get("base_stats", {})
				var a_hp = a.get("hp", a_stats.get("hp", 100))
				var a_mp = a.get("mp", a_stats.get("mp", 100))
				var a_spd = a.get("speed", a_stats.get("speed", 3))
				var a_agi = a.get("agility", a_stats.get("agility", 25))
				var a_dex = a.get("dexterity", a_stats.get("dexterity", 25))
				var a_pot = a.get("potency", 28)
				cp += int((a_hp + a_mp + (a_spd + a_agi + a_dex) * 5 + a_pot * 10) * 0.75)
	return cp

func prepare_match(match_type: String, enemy_element: String, enemy_name: String, enemy_team: String):
	active_match_type = match_type
	active_enemy_element = enemy_element
	active_enemy_name = enemy_name
	active_enemy_team = enemy_team
	print("[CampaignManager] Prepared %s match vs %s (%s) from %s" % [match_type, enemy_name, enemy_element, enemy_team])

func record_match_result(victory: bool, xp_gained: int = 60):
	if victory:
		total_wins += 1
		win_streak += 1
		player_xp += xp_gained
		_check_level_up()
	else:
		total_losses += 1
		win_streak = 0
		player_xp += int(xp_gained * 0.4)
		_check_level_up()

	if active_match_type == "street":
		if victory:
			gold += 75
			record_street_win()
		else:
			gold += 20
		consume_energy(20)
	else:
		if victory:
			gold += 200
			shards += 5
		else:
			gold += 40
		if active_match_type == "tournament":
			for m in tournament_schedule:
				if not m["completed"]:
					m["completed"] = true
					m["result"] = "VICTORY" if victory else "DEFEAT"
					league_round += 1
					break
			consume_energy(20)

	campaign_day = min(7, campaign_day + 1)

	if scouting_intel.has(active_enemy_element):
		var info = scouting_intel[active_enemy_element]
		info["matches_fought"] += 1
		if victory:
			info["wins_against"] += 1
		else:
			info["losses_against"] += 1

	print("[CampaignManager] Match recorded: %s (Total: %d W / %d L, XP: %d/%d, Gold: %d G, Day: %d)" % [
		"Victory" if victory else "Defeat", total_wins, total_losses, player_xp, player_xp_to_next, gold, campaign_day
	])

func _check_level_up():
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = int(player_xp_to_next * 1.3)
		unspent_stat_points += 3
		unspent_skill_points += 1
		print("[CampaignManager] LEVEL UP! Now Level %d! (+3 Stat Points, +1 Skill Point)" % player_level)

func has_saved_campaign() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func save_campaign() -> bool:
	var data = {
		"has_active_campaign": has_active_campaign,
		"player_name": player_name,
		"player_element": player_element,
		"player_level": player_level,
		"player_xp": player_xp,
		"player_xp_to_next": player_xp_to_next,
		"player_speed": player_speed,
		"player_agility": player_agility,
		"player_dexterity": player_dexterity,
		"player_stamina": player_stamina,
		"player_mana": player_mana,
		"player_potency": player_potency,
		"unspent_stat_points": unspent_stat_points,
		"unspent_skill_points": unspent_skill_points,
		"active_match_format": active_match_format,
		"starting_formation": starting_formation,
		"designated_sub": designated_sub,
		"equipped_abilities": equipped_abilities,
		"unlocked_abilities": unlocked_abilities,
		"appearance": appearance,
		"energy": energy,
		"is_fatigued": is_fatigued,
		"bench_risk": bench_risk,
		"current_league": current_league,
		"league_round": league_round,
		"total_wins": total_wins,
		"total_losses": total_losses,
		"team_name": team_name,
		"career_team": career_team,
		"allies": allies,
		"tournament_schedule": tournament_schedule,
		"scouting_intel": scouting_intel,
		"skill_variations": skill_variations,
		"unlocked_skill_forms": unlocked_skill_forms,
		"league_tier": league_tier,
		"street_wins": street_wins,
		"has_team": has_team,
		"known_fighters": known_fighters,
		"gold": gold,
		"shards": shards,
		"campaign_day": campaign_day,
		"win_streak": win_streak,
		"unlocked_elements": unlocked_elements,
	}

	var json_string = JSON.stringify(data, "\t")
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		printerr("[CampaignManager] Failed to save campaign to ", SAVE_PATH)
		return false
	file.store_string(json_string)
	file.close()
	print("[CampaignManager] Saved campaign successfully to ", SAVE_PATH)
	return true

func parse_vector2i(val) -> Vector2i:
	if val is Vector2i:
		return val
	if val is Vector2:
		return Vector2i(int(val.x), int(val.y))
	if val is Dictionary and val.has("x") and val.has("y"):
		return Vector2i(int(val["x"]), int(val["y"]))
	if val is Array and val.size() >= 2:
		return Vector2i(int(val[0]), int(val[1]))
	if val is String:
		var cleaned = val.replace("(", "").replace(")", "").strip_edges()
		var parts = cleaned.split(",")
		if parts.size() >= 2:
			return Vector2i(int(parts[0].strip_edges()), int(parts[1].strip_edges()))
	return Vector2i(-1, -1)

func load_campaign() -> bool:
	if not has_saved_campaign():
		printerr("[CampaignManager] No save file found at ", SAVE_PATH)
		return false

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(text)
	if err != OK:
		printerr("[CampaignManager] JSON parse error: ", json.get_error_message())
		return false

	var data = json.get_data()
	if typeof(data) != TYPE_DICTIONARY:
		return false

	has_active_campaign = data.get("has_active_campaign", true)
	player_name = data.get("player_name", "Ignis")
	player_element = data.get("player_element", "fire")
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
	player_xp_to_next = data.get("player_xp_to_next", 100)

	var edata_node = _get_element_data()
	var def_spd = 3
	var def_agi = 28
	var def_dex = 32
	var def_sta = 100
	var def_mana = 100
	if edata_node and edata_node.ELEMENTS.has(player_element):
		var p_b = edata_node.ELEMENTS[player_element]
		def_spd = p_b.get("base_speed", 3)
		def_agi = p_b.get("base_agility", 28)
		def_dex = p_b.get("base_dexterity", 32)
		def_sta = p_b.get("base_stamina", 100)
		def_mana = p_b.get("base_mp", 100)

	player_speed = data.get("player_speed", def_spd)
	player_agility = data.get("player_agility", def_agi)
	player_dexterity = data.get("player_dexterity", def_dex)
	player_stamina = data.get("player_stamina", def_sta)
	player_mana = data.get("player_mana", def_mana)
	player_potency = data.get("player_potency", 30)
	unspent_stat_points = data.get("unspent_stat_points", 0)
	unspent_skill_points = data.get("unspent_skill_points", 0)
	active_match_format = data.get("active_match_format", "3v3")

	var raw_formation = data.get("starting_formation", starting_formation)
	if raw_formation is Dictionary:
		starting_formation = {}
		for k in raw_formation.keys():
			if k == "type":
				starting_formation[k] = raw_formation[k]
			else:
				starting_formation[k] = parse_vector2i(raw_formation[k])

	designated_sub = data.get("designated_sub", "Gaius")
	equipped_abilities = data.get("equipped_abilities", ["Combustion"])
	unlocked_abilities = data.get("unlocked_abilities", ["Combustion"])
	appearance = data.get("appearance", appearance)
	energy = data.get("energy", 100)
	is_fatigued = data.get("is_fatigued", false)
	bench_risk = data.get("bench_risk", false)
	current_league = data.get("current_league", "Bronze League (Street Tier)")
	league_round = data.get("league_round", 1)
	total_wins = data.get("total_wins", 0)
	total_losses = data.get("total_losses", 0)
	team_name = data.get("team_name", "Phoenix Strikers")
	career_team = data.get("career_team", team_name)
	allies = data.get("allies", allies)
	for a in allies:
		if not a.has("base_stats") or not (a["base_stats"] is Dictionary):
			a["base_stats"] = {
				"hp": a.get("hp", 100),
				"mp": a.get("mp", 100),
				"stamina": a.get("stamina", 100),
				"speed": a.get("speed", 3),
				"agility": a.get("agility", 25),
				"dexterity": a.get("dexterity", 25)
			}
		else:
			for k in ["hp", "mp", "stamina", "speed", "agility", "dexterity"]:
				if not a.has(k) and a["base_stats"].has(k):
					a[k] = a["base_stats"][k]
				elif a.has(k) and not a["base_stats"].has(k):
					a["base_stats"][k] = a[k]
		if not a.has("potential"):
			a["potential"] = 50
		if not a.has("archetype"):
			a["archetype"] = "Striker"
		if not a.has("league_tier"):
			a["league_tier"] = league_tier
		if not a.has("career_team"):
			a["career_team"] = team_name
		if not a.has("status"):
			a["status"] = "Active"
		if not a.has("equipped_skills"):
			a["equipped_skills"] = []
		if not a.has("known_skills"):
			a["known_skills"] = a["equipped_skills"].duplicate()
	tournament_schedule = data.get("tournament_schedule", tournament_schedule)
	scouting_intel = data.get("scouting_intel", scouting_intel)
	skill_variations = data.get("skill_variations", {})
	unlocked_skill_forms = data.get("unlocked_skill_forms", {})
	var edata_load = _get_element_data()
	if edata_load:
		for ab_k in unlocked_abilities:
			if not unlocked_skill_forms.has(ab_k) or unlocked_skill_forms[ab_k].is_empty():
				var f_keys = edata_load.get_skill_form_keys(ab_k)
				if not f_keys.is_empty():
					unlocked_skill_forms[ab_k] = [f_keys[0]]
					if not skill_variations.has(ab_k) or skill_variations[ab_k] == "Base" or skill_variations[ab_k] == "":
						skill_variations[ab_k] = f_keys[0]
	league_tier = data.get("league_tier", 1)
	street_wins = data.get("street_wins", 0)
	has_team = data.get("has_team", false)
	known_fighters = data.get("known_fighters", [])
	gold = data.get("gold", 150)
	shards = data.get("shards", 0)
	campaign_day = data.get("campaign_day", 1)
	win_streak = data.get("win_streak", 0)
	unlocked_elements = data.get("unlocked_elements", [player_element.to_lower()])

	print("[CampaignManager] Loaded campaign successfully: %s (Lv %d %s)" % [player_name, player_level, player_element])
	return true

func spend_stat_point(stat_name: String) -> bool:
	if unspent_stat_points <= 0:
		return false
	match stat_name.to_lower():
		"speed": player_speed += 1
		"agility": player_agility += 2
		"dexterity": player_dexterity += 2
		"stamina": player_stamina += 10
		"mana": player_mana += 10
		"potency": player_potency += 3
		_: return false
	unspent_stat_points -= 1
	print("[CampaignManager] Spent stat point on %s. Remaining: %d" % [stat_name, unspent_stat_points])
	return true

func revert_stat_point(stat_name: String) -> bool:
	var edata = null
	var edata_node = _get_element_data()
	if edata_node and edata_node.ELEMENTS.has(player_element):
		edata = edata_node.ELEMENTS[player_element]

	var floor_speed = edata.get("base_speed", 3) if edata else 3
	var floor_agility = edata.get("base_agility", 28) if edata else 28
	var floor_dexterity = edata.get("base_dexterity", 32) if edata else 32
	var floor_stamina = edata.get("base_stamina", 100) if edata else 100
	var floor_mana = edata.get("base_mp", 100) if edata else 100
	var floor_potency = 30

	match stat_name.to_lower():
		"speed":
			if player_speed <= floor_speed: return false
			player_speed -= 1
		"agility":
			if player_agility <= floor_agility: return false
			player_agility -= 2
		"dexterity":
			if player_dexterity <= floor_dexterity: return false
			player_dexterity -= 2
		"stamina":
			if player_stamina <= floor_stamina: return false
			player_stamina -= 10
		"mana":
			if player_mana <= floor_mana: return false
			player_mana -= 10
		"potency":
			if player_potency <= floor_potency: return false
			player_potency -= 3
		_: return false
	unspent_stat_points += 1
	print("[CampaignManager] Reverted stat point on %s. Remaining: %d" % [stat_name, unspent_stat_points])
	return true

func get_unlocked_elements() -> Array:
	var res = []
	if player_element != "":
		res.append(player_element.to_lower())
	for a in allies:
		var el = a.get("element", "").to_lower()
		if el != "" and not res.has(el):
			res.append(el)
	for el in unlocked_elements:
		var e = str(el).to_lower()
		if not res.has(e):
			res.append(e)
	return res

func can_access_discipline(discipline_key: String) -> Dictionary:
	var edata = get_node_or_null("/root/ElementData")
	if not edata:
		return {"can_access": false, "reason": "ElementData autoload missing."}

	var d_key = discipline_key.to_lower()
	var disc = edata.get_discipline(d_key)
	if disc.is_empty():
		return {"can_access": false, "reason": "Discipline '%s' not found." % discipline_key}

	var cat = disc.get("category", "")
	if cat == "primordial":
		return {"can_access": true, "reason": "Primordial discipline available."}

	var available_elements = get_unlocked_elements()

	if cat == "core":
		return {"can_access": true, "reason": "Core discipline available."}

	if cat == "combination" or cat == "triple":
		var reqs = disc.get("required_elements", [])
		var missing = []
		for r in reqs:
			if not available_elements.has(r.to_lower()):
				var r_disc = edata.get_discipline(r)
				var r_name = r_disc.get("display_name", r.capitalize())
				missing.append(r_name)
		if missing.is_empty():
			return {"can_access": true, "reason": "%s discipline unlocked: all base elements available." % cat.capitalize()}
		else:
			var req_names = []
			for r in reqs:
				var r_disc = edata.get_discipline(r)
				req_names.append(r_disc.get("display_name", r.capitalize()))
			return {
				"can_access": false,
				"reason": "Requires base elements: %s (Missing: %s)." % [", ".join(req_names), ", ".join(missing)]
			}

	return {"can_access": true, "reason": "Discipline available."}

func can_unlock_skill(skill_key: String) -> Dictionary:
	var edata = get_node_or_null("/root/ElementData")
	if not edata:
		return {"can_unlock": false, "reason": "ElementData autoload missing."}

	# 1. Does the skill exist?
	var node = edata.get_skill_node(skill_key)
	if node.is_empty():
		if not edata.ABILITIES.has(skill_key):
			return {"can_unlock": false, "reason": "Skill '%s' does not exist." % skill_key}
		var ab = edata.ABILITIES[skill_key]
		var tier = ab.get("tier", "basic")
		node = {
			"key": skill_key,
			"discipline": ab.get("element", player_element),
			"tier": tier,
			"prerequisites": [],
			"level_req": edata.get_skill_level_req(tier),
			"sp_cost": edata.get_skill_sp_cost(tier)
		}

	# 2. Is the skill already unlocked?
	if unlocked_abilities.has(skill_key):
		return {"can_unlock": false, "reason": "Skill '%s' is already unlocked." % skill_key}

	# 3. Is the required discipline accessible?
	var disc_key = node.get("discipline", "")
	if disc_key != "":
		var d_access = can_access_discipline(disc_key)
		if not d_access.get("can_access", false):
			return {"can_unlock": false, "reason": "Discipline locked: %s" % d_access.get("reason", "")}

	# 4. Is player level sufficient?
	var lvl_req = int(node.get("level_req", edata.get_skill_level_req(node.get("tier", "basic"))))
	if player_level < lvl_req:
		return {
			"can_unlock": false,
			"reason": "Requires Player Level %d (Current: Lv. %d)." % [lvl_req, player_level]
		}

	# 5. Is sufficient SP available?
	var sp_cost = int(node.get("sp_cost", edata.get_skill_sp_cost(node.get("tier", "basic"))))
	if unspent_skill_points < sp_cost:
		return {
			"can_unlock": false,
			"reason": "Requires %d SP (Available: %d SP)." % [sp_cost, unspent_skill_points]
		}

	# 6. Are ALL required skill prerequisites satisfied?
	var prereqs = node.get("prerequisites", [])
	var missing_prereqs = []
	for p in prereqs:
		if not unlocked_abilities.has(p):
			var p_node = edata.get_skill_node(p)
			var p_name = p_node.get("display_name", p.replace("_", " "))
			missing_prereqs.append(p_name)

	if not missing_prereqs.is_empty():
		return {
			"can_unlock": false,
			"reason": "Requires prerequisite(s): %s." % [", ".join(missing_prereqs)]
		}

	# 7. Requirements met!
	return {
		"can_unlock": true,
		"reason": "Requirements met. Ready to unlock."
	}

func unlock_skill_node(skill_key: String) -> bool:
	var check = can_unlock_skill(skill_key)
	if not check.get("can_unlock", false):
		print("[CampaignManager] Unlock rejected for '%s': %s" % [skill_key, check.get("reason", "")])
		return false

	var edata = get_node_or_null("/root/ElementData")
	var sp_cost = 1
	if edata:
		var node = edata.get_skill_node(skill_key)
		if not node.is_empty():
			sp_cost = int(node.get("sp_cost", edata.get_skill_sp_cost(node.get("tier", "basic"))))
		elif edata.ABILITIES.has(skill_key):
			var ab = edata.ABILITIES[skill_key]
			sp_cost = edata.get_skill_sp_cost(ab.get("tier", "basic"))

	unlocked_abilities.append(skill_key)
	unspent_skill_points -= sp_cost
	if edata:
		var f_keys = edata.get_skill_form_keys(skill_key)
		var first_f = f_keys[0] if not f_keys.is_empty() else "form_1"
		if not unlocked_skill_forms.has(skill_key):
			unlocked_skill_forms[skill_key] = [first_f]
		elif not unlocked_skill_forms[skill_key].has(first_f):
			unlocked_skill_forms[skill_key].append(first_f)
		if not skill_variations.has(skill_key) or skill_variations[skill_key] == "Base" or skill_variations[skill_key] == "":
			skill_variations[skill_key] = first_f
	print("[CampaignManager] Unlocked skill node: %s (-%d SP, %d remaining)" % [skill_key, sp_cost, unspent_skill_points])
	return true

func get_unlocked_forms_for_skill(skill_key: String) -> Array:
	if unlocked_skill_forms.has(skill_key) and not unlocked_skill_forms[skill_key].is_empty():
		return unlocked_skill_forms[skill_key]
	if unlocked_abilities.has(skill_key):
		var edata = _get_element_data()
		if edata:
			var keys = edata.get_skill_form_keys(skill_key)
			if not keys.is_empty():
				unlocked_skill_forms[skill_key] = [keys[0]]
				return [keys[0]]
	return []

func can_unlock_skill_form(skill_key: String, form_key: String) -> Dictionary:
	var edata = _get_element_data()
	if not edata:
		return {"can_unlock": false, "reason": "ElementData missing."}
	if not unlocked_abilities.has(skill_key):
		return {"can_unlock": false, "reason": "Skill '%s' must be unlocked first." % skill_key}
	var forms = edata.get_skill_forms(skill_key)
	if not forms.has(form_key):
		return {"can_unlock": false, "reason": "Form '%s' does not exist for '%s'." % [form_key, skill_key]}
	var current_unlocked = get_unlocked_forms_for_skill(skill_key)
	if current_unlocked.has(form_key):
		return {"can_unlock": false, "reason": "Form '%s' is already unlocked." % forms[form_key].get("name", form_key)}
	if unspent_skill_points < 1:
		return {"can_unlock": false, "reason": "Requires 1 SP (Available: %d SP)." % unspent_skill_points}
	return {"can_unlock": true, "reason": "Ready to unlock form (-1 SP)."}

func unlock_skill_form(skill_key: String, form_key: String) -> bool:
	var check = can_unlock_skill_form(skill_key, form_key)
	if not check.get("can_unlock", false):
		print("[CampaignManager] Cannot unlock form %s for %s: %s" % [form_key, skill_key, check.get("reason", "")])
		return false
	unspent_skill_points -= 1
	if not unlocked_skill_forms.has(skill_key):
		unlocked_skill_forms[skill_key] = []
	unlocked_skill_forms[skill_key].append(form_key)
	skill_variations[skill_key] = form_key
	save_campaign()
	print("[CampaignManager] Unlocked form '%s' for '%s' (-1 SP, %d SP remaining)" % [form_key, skill_key, unspent_skill_points])
	return true


# ──────────────────────────────────────────────
#  SQUAD MANAGEMENT & TRAINING SUGGESTIONS
# ──────────────────────────────────────────────

func suggest_training_focus(teammate_name: String, focus: String) -> Dictionary:
	var roll = randf()
	# 80-85% rejection rate based on archetype pride
	if roll <= 0.20:
		return {
			"accepted": true,
			"quote": "%s: 'Understood, Captain. I will trust your guidance and drill %s this week.'" % [teammate_name, focus]
		}
	else:
		var excuses = {
			"Kora": "Kora: 'Captain, dancing in the wind is how I stay alive. I am focusing on Speed and Evasion.'",
			"Gaius": "Gaius: 'Unmovable stone does not flinch. My armor and stamina carry this squad; I will train mass.'"
		}
		var quote = excuses.get(teammate_name, "%s: 'Appreciate the input, but my fighting style is set.'" % teammate_name)
		return {
			"accepted": false,
			"quote": quote
		}

func set_teammate_active_skills(teammate_name: String, skills: Array) -> bool:
	for a in allies:
		if a["name"].to_lower() == teammate_name.to_lower():
			a["equipped_skills"] = skills.duplicate()
			print("[CampaignManager] Assigned active skills for %s: %s" % [a["name"], str(skills)])
			return true
	if allies.size() > 1:
		allies[1]["equipped_skills"] = skills.duplicate()
		print("[CampaignManager] Assigned active skills for %s: %s" % [allies[1]["name"], str(skills)])
		return true
	return false

func set_starting_formation(formation_dict: Dictionary):
	starting_formation = {}
	for k in formation_dict.keys():
		if k == "type":
			starting_formation[k] = formation_dict[k]
		else:
			starting_formation[k] = parse_vector2i(formation_dict[k])
	print("[CampaignManager] Updated starting formation: ", starting_formation)

func set_bench_sub(teammate_name: String):
	designated_sub = teammate_name
	for a in allies:
		if a["name"] == teammate_name:
			a["status"] = "Reserve"
		else:
			if a["status"] != "Injured":
				a["status"] = "Active"
	print("[CampaignManager] Designated bench sub: ", designated_sub)

func set_active_match_format(fmt: String):
	active_match_format = fmt
	print("[CampaignManager] Set active match format: ", active_match_format)

func set_match_format(fmt: String):
	set_active_match_format(fmt)


func equip_ability(ability_name: String, slot_index: int = -1) -> bool:
	if not unlocked_abilities.has(ability_name):
		return false
	if slot_index >= 0 and slot_index < 4:
		while equipped_abilities.size() <= slot_index:
			equipped_abilities.append("")
		equipped_abilities[slot_index] = ability_name
	else:
		if not equipped_abilities.has(ability_name):
			if equipped_abilities.size() < 4:
				equipped_abilities.append(ability_name)
			else:
				equipped_abilities[3] = ability_name
	return true

func get_ally(ally_name: String) -> Dictionary:
	for a in allies:
		if a.get("name", "").to_lower() == ally_name.to_lower():
			return a
	return {}

func get_allies() -> Array:
	return allies.duplicate(true)


# ══════════════════════════════════════════════
#  FIGHTER GENERATION & CAREER LIFECYCLE  (OOP: all athlete data owned here)
# ══════════════════════════════════════════════

## Returns a human-readable label for a fighter's hidden potential score.
func get_potential_label(potential: int) -> String:
	if potential >= 75:
		return "Prodigy"
	elif potential >= 40:
		return "Rising Star"
	return "Journeyman"

func get_potential_tier_label(potential: int) -> String:
	return get_potential_label(potential)


## OOP encapsulation: external code updates ally stats only through this method.
func update_athlete_stat(ally_name: String, stat: String, value) -> bool:
	for a in allies:
		if a.get("name", "").to_lower() == ally_name.to_lower():
			a[stat] = value
			if ["hp", "mp", "stamina", "speed", "agility", "dexterity"].has(stat):
				if not a.has("base_stats") or not (a["base_stats"] is Dictionary):
					a["base_stats"] = {}
				a["base_stats"][stat] = value
			elif stat == "base_stats" and value is Dictionary:
				for k in value.keys():
					a[k] = value[k]
			return true
	return false

## OOP encapsulation: set equipped skills for an athlete (max 4 skills).
func set_athlete_skills(ally_name: String, skills: Array) -> bool:
	for a in allies:
		if a.get("name", "").to_lower() == ally_name.to_lower():
			var eq = skills.slice(0, min(4, skills.size()))
			a["equipped_skills"] = eq.duplicate()
			if not a.has("known_skills") or not (a["known_skills"] is Array):
				a["known_skills"] = []
			for s in eq:
				if not a["known_skills"].has(s):
					a["known_skills"].append(s)
			print("[CampaignManager] Assigned active skills for %s: %s" % [a["name"], str(eq)])
			return true
	return false

## OOP encapsulation: set athlete status.
func set_athlete_status(ally_name: String, status: String) -> bool:
	for a in allies:
		if a.get("name", "").to_lower() == ally_name.to_lower():
			a["status"] = status
			return true
	return false

## OOP encapsulation: add an athlete profile to the active roster.
func add_athlete(profile: Dictionary) -> bool:
	if allies.size() >= MAX_ROSTER_SIZE:
		return false
	allies.append(profile)
	return true

## OOP encapsulation: remove an athlete from the active roster.
func remove_athlete(ally_name: String) -> bool:
	for i in range(allies.size()):
		if allies[i].get("name", "").to_lower() == ally_name.to_lower():
			allies.remove_at(i)
			return true
	return false

func _get_element_data():
	if is_inside_tree():
		var ed = get_node_or_null("/root/ElementData")
		if ed != null:
			return ed
	var ed_res = load("res://scripts/element_data.gd")
	if ed_res:
		return ed_res.new()
	return null

func _is_name_taken(candidate_name: String) -> bool:
	if candidate_name.to_lower() == player_name.to_lower():
		return true
	for a in allies:
		if a.get("name", "").to_lower() == candidate_name.to_lower():
			return true
	for k in known_fighters:
		if k.get("name", "").to_lower() == candidate_name.to_lower():
			return true
	return false


## Generates an individual athlete profile adhering strictly to League Tier bounds and schema.
func generate_athlete(tier: int = 1, archetype: String = "", element: String = "", athlete_name: String = "", exclude_names: Array = []) -> Dictionary:
	tier = clampi(tier, 1, 5)
	var td = LEAGUE_TIERS[tier]

	var elem = element if element != "" and GEN_ELEMENTS.has(element) \
		else GEN_ELEMENTS[randi() % GEN_ELEMENTS.size()]

	var arch = archetype if archetype != "" and ARCHETYPES.has(archetype) \
		else ARCHETYPES[randi() % ARCHETYPES.size()]

	var fname = ""
	if athlete_name != "":
		fname = athlete_name
	else:
		for _i in range(50):
			var f = FIGHTER_NAMES_FIRST[randi() % FIGHTER_NAMES_FIRST.size()]
			var l = FIGHTER_NAMES_LAST[randi() % FIGHTER_NAMES_LAST.size()]
			var candidate = f + " " + l
			if not exclude_names.has(candidate) and not _is_name_taken(candidate):
				fname = candidate
				break
		if fname == "":
			fname = "Athlete_%d" % (randi() % 9999)

	var lvl = randi_range(td["lvl_min"], td["lvl_max"])
	var potential = randi_range(1, 100)

	var rolled_hp = randi_range(td["hp_min"], td["hp_max"])
	var rolled_mp = randi_range(td["mp_min"], td["mp_max"])
	var rolled_spd = randi_range(td["spd_min"], td["spd_max"])
	var rolled_agi = randi_range(td["agi_min"], td["agi_max"])
	var rolled_dex = randi_range(td["dex_min"], td["dex_max"])
	var rolled_sta = randi_range(td["sta_min"], td["sta_max"])

	# Archetype stat biases strictly clamped inside tier bounds
	match arch:
		"Striker":
			rolled_dex = clampi(rolled_dex + randi_range(2, 4), td["dex_min"], td["dex_max"])
			rolled_spd = clampi(rolled_spd + (1 if randf() < 0.5 else 0), td["spd_min"], td["spd_max"])
		"Scout":
			rolled_agi = clampi(rolled_agi + randi_range(2, 5), td["agi_min"], td["agi_max"])
			rolled_spd = clampi(rolled_spd + 1, td["spd_min"], td["spd_max"])
		"Defender":
			rolled_hp = clampi(rolled_hp + randi_range(5, 10), td["hp_min"], td["hp_max"])
			rolled_sta = clampi(rolled_sta + randi_range(5, 10), td["sta_min"], td["sta_max"])
		"Support":
			rolled_mp = clampi(rolled_mp + randi_range(5, 10), td["mp_min"], td["mp_max"])
			rolled_agi = clampi(rolled_agi + randi_range(2, 4), td["agi_min"], td["agi_max"])

	var skills: Array = []
	var edata = _get_element_data()
	if edata and edata.ELEMENTS.has(elem):
		if edata.has_method("get_skills_for_athlete"):
			skills = edata.get_skills_for_athlete(elem, lvl, randi_range(2, 4))
		else:
			var pool = edata.get_skills_for_level(elem, lvl)
			if pool is Array:
				pool = pool.duplicate()
				pool.shuffle()
				skills = pool.slice(0, min(randi_range(2, 4), pool.size()))
	if skills.is_empty():
		skills = DEFAULT_ELEMENT_SKILLS.get(elem, ["Combustion"]).duplicate()

	var known = skills.duplicate()
	var equipped = skills.slice(0, min(4, skills.size()))

	var bstats = {
		"hp": rolled_hp,
		"mp": rolled_mp,
		"stamina": rolled_sta,
		"speed": rolled_spd,
		"agility": rolled_agi,
		"dexterity": rolled_dex
	}

	return {
		"name":           fname,
		"element":        elem,
		"archetype":      arch,
		"role":           arch + " / " + elem.capitalize(),
		"level":          lvl,
		"league_tier":    tier,
		"base_stats":     bstats,
		"hp":             rolled_hp,
		"mp":             rolled_mp,
		"stamina":        rolled_sta,
		"speed":          rolled_spd,
		"agility":        rolled_agi,
		"dexterity":      rolled_dex,
		"potential":      potential,
		"status":         "Active",
		"career_team":    team_name if team_name != "" else "Free Agent",
		"known_skills":   known,
		"equipped_skills": equipped,
	}


## Backward-compatible alias for generate_athlete.
func generate_fighter(tier: int, element: String = "", exclude_names: Array = []) -> Dictionary:
	return generate_athlete(tier, "", element, "", exclude_names)


## Generates a batch of athletes for a given league tier with unique names.
func generate_team_roster(tier: int, count: int = -1) -> Array:
	if count < 0:
		count = randi_range(3, 5)
	var result: Array = []
	var used_names: Array = []
	for a in allies:
		used_names.append(a.get("name", ""))
	for k in known_fighters:
		used_names.append(k.get("name", ""))
	for _i in range(count):
		var f = generate_athlete(tier, "", "", "", used_names)
		used_names.append(f["name"])
		result.append(f)
	return result


## Triggers a team recruitment offer, adding 3–5 Tier 1 athletes to the roster.
## Returns Array of recruited athlete dictionaries.
func trigger_recruitment_offer(arg1 = null, arg2: int = 4) -> Array:
	var count = 4
	var new_team = "Phoenix Strikers"
	if arg1 is String:
		new_team = arg1
		count = arg2
	elif arg1 is int:
		count = arg1
		if team_name != "" and team_name != "Street Brawler" and team_name != "Free Agent":
			new_team = team_name
	else:
		count = arg2
		if team_name != "" and team_name != "Street Brawler" and team_name != "Free Agent":
			new_team = team_name

	count = clampi(count, 3, 5)
	team_name = new_team
	career_team = new_team
	has_team = true
	active_match_format = "3v3"

	var existing_names: Array = []
	for a in allies:
		existing_names.append(a.get("name", ""))
	for k in known_fighters:
		existing_names.append(k.get("name", ""))

	var recruited: Array = []
	for i in range(count):
		if allies.size() >= MAX_ROSTER_SIZE:
			break
		var f = generate_athlete(1, "", "", "", existing_names)
		f["career_team"] = team_name
		existing_names.append(f["name"])
		allies.append(f)
		recruited.append(f)

	if allies.size() > 1:
		starting_formation[allies[0]["name"]] = Vector2i(3, 4)
		starting_formation[allies[1]["name"]] = Vector2i(2, 3)
		if allies.size() > 2:
			starting_formation[allies[2]["name"]] = Vector2i(2, 5)
		designated_sub = allies[allies.size() - 1]["name"]

	print("[CampaignManager] Team recruitment offer accepted for %s! Recruited %d athletes. Roster now has %d athletes." % [team_name, recruited.size(), allies.size()])
	return recruited


## Called when the player earns a street win.
func record_street_win() -> bool:
	street_wins += 1
	print("[CampaignManager] Street wins: %d / %d" % [street_wins, RECRUITMENT_WINS_THRESHOLD])
	if street_wins >= RECRUITMENT_WINS_THRESHOLD and not has_team:
		trigger_recruitment_offer("Phoenix Strikers", randi_range(3, 4))
		return true
	return false


func _develop_athlete_stats(athlete: Dictionary, _tier: int, td: Dictionary, edata) -> void:
	var pot = athlete.get("potential", 50)
	var growth_ratio = clampf(float(pot) / 100.0, 0.2, 1.0)
	
	athlete["level"] = clampi(athlete.get("level", 1) + randi_range(2, 5), td["lvl_min"], td["lvl_max"])

	var stats = ["hp", "mp", "stamina", "speed", "agility", "dexterity"]
	var stat_keys = {
		"hp": ["hp_min", "hp_max"],
		"mp": ["mp_min", "mp_max"],
		"stamina": ["sta_min", "sta_max"],
		"speed": ["spd_min", "spd_max"],
		"agility": ["agi_min", "agi_max"],
		"dexterity": ["dex_min", "dex_max"]
	}

	if not athlete.has("base_stats") or not (athlete["base_stats"] is Dictionary):
		athlete["base_stats"] = {}

	for s in stats:
		var cur_val = athlete.get(s, td[stat_keys[s][0]])
		var min_v = td[stat_keys[s][0]]
		var max_v = td[stat_keys[s][1]]
		var target_val = int(lerp(float(min_v), float(max_v), growth_ratio))
		var new_val = clampi(max(cur_val, target_val), min_v, max_v)
		athlete[s] = new_val
		athlete["base_stats"][s] = new_val

	if edata and edata.ELEMENTS.has(athlete.get("element", "")):
		var offers = edata.get_skill_offers(athlete["element"], athlete.get("known_skills", []), athlete["level"])
		if not athlete.has("known_skills") or not (athlete["known_skills"] is Array):
			athlete["known_skills"] = []
		for skill in offers:
			athlete["known_skills"].append(skill)
			if athlete.get("equipped_skills", []).size() < 4:
				athlete["equipped_skills"].append(skill)


## Promotes the team to a new league tier, pruning low-potential fighters and backfilling with new athletes.
func promote_team_tier(new_tier: int) -> Dictionary:
	new_tier = clampi(new_tier, 1, 5)
	var td = LEAGUE_TIERS[new_tier]
	
	var potential_threshold = 0
	match new_tier:
		2: potential_threshold = 40
		3: potential_threshold = 60
		4: potential_threshold = 75
		5: potential_threshold = 85
		_: potential_threshold = 0

	var stayed: Array = []
	var left: Array = []
	var joined: Array = []
	var survivors: Array = []
	var prev_size = allies.size()

	var edata = _get_element_data()

	for a in allies:
		if a.get("name", "") == player_name:
			a["league_tier"] = new_tier
			_develop_athlete_stats(a, new_tier, td, edata)
			survivors.append(a)
			stayed.append(a["name"])
			continue

		var pot = a.get("potential", 50)
		var cur_t = a.get("league_tier", 1)

		if pot >= potential_threshold or cur_t >= new_tier:
			a["league_tier"] = new_tier
			_develop_athlete_stats(a, new_tier, td, edata)
			survivors.append(a)
			stayed.append(a["name"])
		else:
			if pot < 20:
				a["status"] = "Retired"
			else:
				a["status"] = "Free Agent"
			a["career_team"] = "Free Agent"
			record_encountered_fighter(a)
			left.append(a["name"])

	# Backfill vacancies with new fighters at new_tier
	var target_size = max(3, prev_size)
	var gap = target_size - survivors.size()
	for _i in range(gap):
		if survivors.size() >= MAX_ROSTER_SIZE:
			break
		var existing_names = survivors.map(func(x): return x["name"])
		for k in known_fighters:
			existing_names.append(k.get("name", ""))
		var f = generate_athlete(new_tier, "", "", "", existing_names)
		f["career_team"] = team_name
		survivors.append(f)
		joined.append(f["name"])

	allies = survivors
	league_tier = new_tier
	current_league = LEAGUE_TIERS[new_tier]["name"] + " League"

	print("[CampaignManager] Promoted to Tier %d (%s). Stayed: %d, Left: %d, Joined: %d" % [
		new_tier, LEAGUE_TIERS[new_tier]["name"], stayed.size(), left.size(), joined.size()
	])

	return {
		"success": true,
		"stayed": stayed,
		"left": left,
		"joined": joined,
		"promoted_tier": new_tier
	}


## Backward-compatible alias for promote_team_tier.
func process_league_promotion(new_tier: int) -> Dictionary:
	return promote_team_tier(new_tier)


## Simulates a transfer window with potential-based retirements, free agency, and familiar faces returning.
func run_transfer_window() -> Dictionary:
	var retired: Array = []
	var free_agents: Array = []
	var rejoined: Array = []
	var recruited: Array = []
	var survivors: Array = []
	var prev_size = allies.size()
	var td = LEAGUE_TIERS[league_tier]
	var edata = _get_element_data()

	for a in allies:
		if a.get("name", "") == player_name:
			survivors.append(a)
			continue

		var pot = a.get("potential", 50)
		if randf() < 0.15 and pot < 40:
			if pot < 20 or randf() < 0.5:
				a["status"] = "Retired"
				retired.append(a["name"])
			else:
				a["status"] = "Free Agent"
				free_agents.append(a["name"])
			a["career_team"] = "Free Agent"
			record_encountered_fighter(a)
		else:
			survivors.append(a)

	var gap = max(0, prev_size - survivors.size())
	var available_returners = known_fighters.filter(func(f):
		return f.get("status", "") != "Retired" and f.get("name", "") != player_name
	)
	available_returners.shuffle()

	for f in available_returners:
		if gap <= 0 or survivors.size() >= MAX_ROSTER_SIZE:
			break
		if randf() < 0.20:
			var returnee = f.duplicate(true)
			returnee["status"] = "Active"
			returnee["career_team"] = team_name
			returnee["league_tier"] = league_tier
			_develop_athlete_stats(returnee, league_tier, td, edata)
			survivors.append(returnee)
			rejoined.append(returnee["name"])
			gap -= 1

	for _i in range(gap):
		if survivors.size() >= MAX_ROSTER_SIZE:
			break
		var used = survivors.map(func(x): return x["name"])
		for k in known_fighters:
			used.append(k.get("name", ""))
		var fresh = generate_athlete(league_tier, "", "", "", used)
		fresh["career_team"] = team_name
		survivors.append(fresh)
		recruited.append(fresh["name"])

	allies = survivors
	print("[CampaignManager] Transfer window complete. Retired: %d, Free Agents: %d, Rejoined: %d, Recruited: %d" % [
		retired.size(), free_agents.size(), rejoined.size(), recruited.size()
	])

	return {
		"success": true,
		"retired": retired,
		"free_agents": free_agents,
		"rejoined": rejoined,
		"recruited": recruited
	}


## Backward-compatible alias for run_transfer_window.
func simulate_transfer_window() -> Dictionary:
	return run_transfer_window()


## Records an athlete encountered across career matches into known_fighters history.
func record_encountered_fighter(fighter: Dictionary) -> void:
	if fighter.is_empty():
		return
	var fname = fighter.get("name", "")
	if fname == "" or fname == player_name:
		return
	for i in range(known_fighters.size()):
		if known_fighters[i].get("name", "") == fname:
			known_fighters[i] = fighter.duplicate(true)
			return
	known_fighters.append(fighter.duplicate(true))


## Evolves an athlete's stats and skills based on potential and target league tier.
func evolve_athlete(fighter: Dictionary, target_tier: int = -1) -> Dictionary:
	var evolved = fighter.duplicate(true)
	var t = target_tier if target_tier > 0 else evolved.get("league_tier", 1)
	t = clampi(t, 1, 5)
	evolved["league_tier"] = t
	var td = LEAGUE_TIERS[t]
	var edata = _get_element_data()
	_develop_athlete_stats(evolved, t, td, edata)
	return evolved


