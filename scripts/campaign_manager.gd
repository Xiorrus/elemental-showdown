# campaign_manager.gd
# Central persistent autoload for Elemental Showdown campaign, tournament schedule,
# energy & fatigue mechanics, opponent scouting intel, and save/load operations.
extends Node

const SAVE_PATH = "user://campaign_save.json"
const SAVES_DIR = "user://saves"

var current_save_path: String = SAVE_PATH
var current_campaign_id: String = ""

const MAX_ENERGY = 100
const FATIGUE_THRESHOLD = 30
const MAX_ROSTER_SIZE = 10
const RECRUITMENT_WINS_THRESHOLD = 3
const SeasonCalendarScript = preload("res://scripts/season_calendar.gd")
const ScoutingCatalogScript = preload("res://scripts/scouting_catalog.gd")
const CLUB_TEAM_ELEMENTS = {
	"Phoenix Strikers": "fire", "Hydro Vipers": "water",
	"Gale Force": "air", "Terra Titans": "earth",
	"Ember Hawks": "fire", "Crystal Wardens": "earth",
	"Storm Runners": "air", "Tidebreakers": "water"
}
const NATIONALITIES = ["United States", "Brazil", "Japan", "Nigeria", "France", "Germany", "South Korea", "Mexico"]
const CLUB_TEAM_COUNTRIES = {
	"Phoenix Strikers": "United States", "Hydro Vipers": "Japan",
	"Gale Force": "Brazil", "Terra Titans": "Nigeria",
	"Ember Hawks": "Mexico", "Crystal Wardens": "Germany",
	"Storm Runners": "France", "Tidebreakers": "South Korea"
}
const TRAINING_STATS = ["speed", "agility", "dexterity", "stamina", "mana", "potency", "defense"]
const TRAINING_CAPS = {"speed": 6, "agility": 75, "dexterity": 75,
	"stamina": 180, "mana": 180, "potency": 80, "defense": 70}
const CLUB_DIVISION_NAMES = {1: "City", 2: "Regional", 3: "National"}
const HIGHEST_DOMESTIC_DIVISION = 3

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

# Every starter loadout has one defensive/support form and one attack form.
# The first form of each ability is unlocked when a campaign begins.
const DEFAULT_ELEMENT_SKILLS = {
	"fire": ["Thermal_Radiation", "Combustion"],
	"water": ["Aqua_Mend", "Ice"],
	"earth": ["Stone_Plating", "Metal"],
	"air": ["Gale_Step", "Wind"]
}

# ──────────────────────────────────────────────
#  ACTIVE CAMPAIGN STATE
# ──────────────────────────────────────────────
var has_active_campaign: bool = false
var _fallback_element_data: Node

# Player Profile
var player_name: String = "Ignis"
var player_nationality: String = "United States"
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
var player_defense: int = 20
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
var league_tier: int = 1         # Player club's domestic division (1 City, 2 Regional, 3 National)
var street_wins: int = 0         # Street-brawler wins before joining a team
var has_team: bool = false        # Whether the player has joined an organised team
var recruitment_offer_pending: bool = false
var recruitment_offer_club: String = ""
var pending_element_choice: bool = false
var national_cup_titles: int = 0
var continental_cup_titles: int = 0
var national_world_cup_titles: int = 0
var club_world_cup_titles: int = 0
var primordial_choice_pending: bool = false
var world_cup_reward_pending: bool = false
var primordial_choices: Array = []
var primordial_skill_permits: int = 0
var known_fighters: Array = []   # All individual athletes the player has ever encountered
var career_team: String = "Phoenix Strikers"


# Visual Customization
const DEFAULT_APPEARANCE = {
	"hair_style": "spiky",
	"hair_color": "crimson",
	"skin_tone": "peach",
	"outfit_style": "martial_gi",
	"team_palette": "fire",
	"sheet_prefix": "fire"
}
var appearance: Dictionary = DEFAULT_APPEARANCE.duplicate(true)

# Energy & Fatigue
var energy: int = 100
var is_fatigued: bool = false
var bench_risk: bool = false

# League & Tournament Progression
var current_league: String = "Street Circuit"
var league_round: int = 1
var total_wins: int = 0
var total_losses: int = 0
var win_streak: int = 0

# Economy & Currencies
var gold: int = 150
var shards: int = 0

# Timeline & Campaign Calendar
var campaign_day: int = 1
var career_start_year: int = 2026
var training_progress: Dictionary = {}
var training_gains: Dictionary = {}
var season_state: Dictionary = {}
var season_number: int = 1
var season_week: int = 0
var season_start_day: int = 1
var season_phase: String = "street"
var championship_state: Dictionary = {}
var season_history: Array = []
var active_fixture_id: int = -1

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
const DEFAULT_TOURNAMENT_SCHEDULE = [
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
var tournament_schedule: Array = DEFAULT_TOURNAMENT_SCHEDULE.duplicate(true)

# Scouting Intel / Codex of Encountered Factions
const DEFAULT_SCOUTING_INTEL = {
	"water": {
		"team_name": "Hydro Vipers",
		"captain": "Nami",
		"element": "water",
		"strengths": ["High MP pool", "Freezing crowd control", "Sustained healing"],
		"weaknesses": ["Earth mass disruption", "Fire thermal combustion"],
		"known_skills": ["Ice", "Pressure_Wave", "Purification"],
		"matches_fought": 0,
		"wins_against": 0,
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
var scouting_intel: Dictionary = DEFAULT_SCOUTING_INTEL.duplicate(true)

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
	var nationality = "United States"

	if p_name_or_cfg is Dictionary:
		var cfg = p_name_or_cfg
		p_name = cfg.get("player_name", cfg.get("name", "Ignis"))
		p_elem_str = cfg.get("player_element", cfg.get("element", "fire"))
		nationality = str(cfg.get("player_nationality", cfg.get("nationality", nationality)))
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
	player_nationality = nationality if NATIONALITIES.has(nationality) else NATIONALITIES[0]
	var raw_elem = p_elem_str.to_lower().strip_edges()
	if raw_elem == "wind": raw_elem = "air"
	player_element = raw_elem
	unlocked_elements = [player_element]

	# Autoloads survive scene changes: each new career needs fresh nested data.
	appearance = DEFAULT_APPEARANCE.duplicate(true)
	if app_cfg:
		appearance.merge(app_cfg, true)
	appearance["sheet_prefix"] = app_cfg.get("sheet_prefix", player_element) if app_cfg else player_element
	appearance["team_palette"] = app_cfg.get("team_palette", player_element) if app_cfg else player_element
	tournament_schedule = DEFAULT_TOURNAMENT_SCHEDULE.duplicate(true)
	scouting_intel = DEFAULT_SCOUTING_INTEL.duplicate(true)
	known_fighters = []
	active_match_type = "street" if is_solo else "tournament"
	active_enemy_element = "water"
	active_enemy_name = "Kage" if is_solo else "Nami"
	active_enemy_team = "Underground Syndicate" if is_solo else "Hydro Vipers"

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
	player_defense = p_base.get("base_defense", 20)
	energy = 100
	is_fatigued = false
	bench_risk = false
	league_tier = 1
	current_league = "Street Circuit"
	league_round = 1
	total_wins = 0
	total_losses = 0
	win_streak = 0
	street_wins = 0
	recruitment_offer_pending = false
	recruitment_offer_club = ""
	pending_element_choice = false
	national_cup_titles = 0
	continental_cup_titles = 0
	national_world_cup_titles = 0
	club_world_cup_titles = 0
	primordial_choice_pending = false
	world_cup_reward_pending = false
	primordial_choices = []
	primordial_skill_permits = 0
	gold = 150
	shards = 0
	campaign_day = 1
	career_start_year = int(Time.get_date_dict_from_system().get("year", 2026))
	training_progress = {}
	training_gains = {}
	season_state = {}
	season_number = 1
	season_week = 0
	season_start_day = 1
	season_phase = "street" if is_solo else "legacy_tournament"
	championship_state = {}
	season_history = []
	active_fixture_id = -1

	var starter_skills: Array = DEFAULT_ELEMENT_SKILLS.get(player_element, DEFAULT_ELEMENT_SKILLS["fire"]).duplicate()
	equipped_abilities = starter_skills.duplicate()
	unlocked_abilities = starter_skills.duplicate()
	var edata_starter = _get_element_data()
	unlocked_skill_forms = {}
	skill_variations = {}
	for skill in starter_skills:
		var form_keys = edata_starter.get_skill_form_keys(skill) if edata_starter else []
		var first_form = form_keys[0] if not form_keys.is_empty() else "form_1"
		unlocked_skill_forms[skill] = [first_form]
		skill_variations[skill] = first_form

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
		_start_club_season()
		print("[CampaignManager] Created new campaign: %s (%s) of %s" % [player_name, player_element, team_name])

func _init_default_squad(p_name: String, p_elem: String, t_name: String):
	var p_known: Array = DEFAULT_ELEMENT_SKILLS.get(p_elem, DEFAULT_ELEMENT_SKILLS["fire"]).duplicate()

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
			"equipped_skills": p_known.duplicate(),
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

func _start_club_season() -> bool:
	var division_keys := ["city", "regional", "national"]
	var division_key: String = division_keys[clampi(league_tier, 1, 3) - 1]
	var clubs: Array = ScoutingCatalogScript.CLUBS[division_key].duplicate()
	if not clubs.has(team_name):
		clubs[0] = team_name
	var generated: Dictionary = SeasonCalendarScript.new().create_season(clubs, season_number)
	if generated.is_empty():
		return false
	season_state = generated
	season_week = 1
	season_start_day = campaign_day
	season_phase = "club_regular"
	championship_state = {}
	active_fixture_id = -1
	active_match_format = "3v3"
	current_league = "%s Club League" % CLUB_DIVISION_NAMES.get(league_tier, "National")
	return true

func _opponent_element(club_name: String) -> String:
	if CLUB_TEAM_ELEMENTS.has(club_name):
		return CLUB_TEAM_ELEMENTS[club_name]
	var index = season_state.get("teams", []).find(club_name)
	return GEN_ELEMENTS[posmod(index, GEN_ELEMENTS.size())]

func _season_match(opponent: String, week: int, round_number: int, match_type: String, fixture_id: int = -1) -> Dictionary:
	var calendar = SeasonCalendarScript.new()
	var match_day: int = calendar.get_fixture_day(week)
	return {
		"round": round_number,
		"week": week,
		"season_day": match_day,
		"days_until": maxi(0, season_start_day + match_day - 1 - campaign_day),
		"date_label": calendar.get_day_entry(season_state, team_name, match_day, career_start_year + season_number - 1).get("date_label", ""),
		"league": current_league,
		"enemy_team": opponent,
		"enemy_captain": "%s Captain" % opponent,
		"enemy_element": _opponent_element(opponent),
		"difficulty": "Championship" if match_type == "championship" else "Club League",
		"completed": false,
		"result": "",
		"match_type": match_type,
		"fixture_id": fixture_id
	}

func get_season_day() -> int:
	if season_state.is_empty():
		return 0
	return clampi(campaign_day - season_start_day + 1, 1, SeasonCalendarScript.DAYS_PER_SEASON)

func get_calendar_days() -> Array:
	if season_state.is_empty():
		return []
	return SeasonCalendarScript.new().get_calendar_days(season_state, team_name,
		career_start_year + season_number - 1)

func get_optional_friendly_on_day(season_day: int) -> Dictionary:
	if season_state.is_empty() or season_phase == "offseason" or not season_day in [7, 119]:
		return {}
	if season_state.get("friendly_results", {}).has(str(season_day)):
		return {}
	var opponents: Array = season_state.get("teams", []).duplicate()
	opponents.erase(team_name)
	if opponents.is_empty():
		return {}
	var opponent: String = opponents[(season_number + int(season_day / 7)) % opponents.size()]
	return {"match_type": "friendly", "season_day": season_day,
		"enemy_team": opponent, "enemy_captain": "%s Captain" % opponent,
		"enemy_element": _opponent_element(opponent), "difficulty": "Club Friendly"}

func get_days_until_next_match() -> int:
	var next_match = get_next_scheduled_match()
	if next_match.is_empty() or not next_match.has("season_day"):
		return -1
	return maxi(0, season_start_day + int(next_match["season_day"]) - 1 - campaign_day)

func can_play_next_match() -> bool:
	var next_match = get_next_scheduled_match()
	return not next_match.is_empty() and (not next_match.has("season_day") or get_days_until_next_match() == 0)

func _sync_season_clock() -> void:
	if not season_state.is_empty():
		season_week = clampi(int((maxi(1, get_season_day()) - 1) / 7) + 1, 1, 32)

func advance_days(days: int) -> Dictionary:
	if days < 1:
		return {"success": false, "reason": "Choose at least one day."}
	if not season_state.is_empty():
		if season_phase == "offseason":
			return {"success": false, "reason": "Start the next season to continue the calendar."}
		var deadline = get_next_scheduled_match()
		if not deadline.is_empty() and deadline.has("season_day"):
			var fixture_day = season_start_day + int(deadline["season_day"]) - 1
			if campaign_day + days > fixture_day:
				return {"success": false, "reason": "A match with %s is due first. Play or skip it before advancing." % deadline.get("enemy_team", "your rival")}
		if campaign_day + days > season_start_day + SeasonCalendarScript.DAYS_PER_SEASON - 1:
			return {"success": false, "reason": "The season has ended."}
	campaign_day += days
	_sync_season_clock()
	save_campaign()
	return {"success": true, "days": days, "season_day": get_season_day()}

func rest_for_days(days: int) -> Dictionary:
	if not [1, 3, 7].has(days):
		return {"success": false, "reason": "Choose 1, 3, or 7 rest days."}
	var advanced = advance_days(days)
	if not advanced.get("success", false):
		return advanced
	var restored = {1: 20, 3: 50, 7: 90}[days]
	restore_energy(restored)
	save_campaign()
	return {"success": true, "days": days, "energy_restored": restored, "energy": energy}

func train_stat(stat_name: String) -> Dictionary:
	var stat = stat_name.to_lower().strip_edges()
	if not TRAINING_STATS.has(stat):
		return {"success": false, "reason": "Choose a valid training focus."}
	if int(get("player_%s" % stat)) >= int(TRAINING_CAPS[stat]):
		return {"success": false, "reason": "%s has reached its training cap." % stat.capitalize()}
	if energy < 15:
		return {"success": false, "reason": "Training requires 15 energy. Rest first."}
	var advanced = advance_days(1)
	if not advanced.get("success", false):
		return advanced
	consume_energy(15)
	var gains = int(training_gains.get(stat, 0))
	var threshold = 4 + mini(8, gains * 2)
	var progress = int(training_progress.get(stat, 0)) + 1
	var improved = false
	if progress >= threshold:
		progress = 0
		training_gains[stat] = gains + 1
		set("player_%s" % stat, int(get("player_%s" % stat)) + 1)
		var captain = get_ally(player_name)
		if not captain.is_empty() and stat in ["speed", "agility", "dexterity", "stamina", "mana"]:
			var key = "mp" if stat == "mana" else stat
			captain[key] = get("player_%s" % stat)
			captain["base_stats"][key] = captain[key]
		improved = true
	training_progress[stat] = progress
	save_campaign()
	return {"success": true, "stat": stat, "progress": progress,
		"threshold": 4 + mini(8, int(training_gains.get(stat, 0)) * 2), "improved": improved}

func skip_next_match() -> Dictionary:
	if season_state.is_empty() or season_phase == "offseason":
		return {"success": false, "reason": "No club match to skip."}
	var match_info = get_next_scheduled_match()
	if match_info.is_empty() or not match_info.has("season_day"):
		return {"success": false, "reason": "No scheduled match to skip."}
	campaign_day = maxi(campaign_day, season_start_day + int(match_info["season_day"]) - 1)
	_sync_season_clock()
	var simulated_win = false
	if season_phase == "club_regular":
		var rng := RandomNumberGenerator.new()
		rng.seed = absi(hash("%s:%d:%d" % [player_name, season_number, int(match_info["fixture_id"])]))
		var opposing_level = 1 + (league_tier - 1) * 5 + (season_number - 1) * 2
		var chance = clampf(0.48 + (player_level - opposing_level) * 0.025 + (energy - 50) * 0.003, 0.15, 0.80)
		simulated_win = rng.randf() < chance
		active_fixture_id = int(match_info["fixture_id"])
		_record_club_round(simulated_win)
		active_fixture_id = -1
	else:
		_record_championship_result(false)
	save_campaign()
	return {"success": true, "won": simulated_win, "opponent": match_info.get("enemy_team", ""),
		"match_type": match_info.get("match_type", "league")}

func get_season_summary() -> Dictionary:
	var active = not season_state.is_empty()
	var standings: Array = SeasonCalendarScript.new().get_standings(season_state) if active else []
	var international_events: Array = []
	if active:
		for event in SeasonCalendarScript.new().get_week(season_state, season_week).get("events", []):
			if event.get("type", "") == "national_window":
				international_events.append(event)
	return {
		"active": active,
		"season_number": season_number,
		"week": season_week,
		"season_day": get_season_day(),
		"today": SeasonCalendarScript.new().get_day_entry(season_state, team_name,
			get_season_day(), career_start_year + season_number - 1).get("date_label", "") if active else "",
		"days_until_next_match": get_days_until_next_match() if active else -1,
		"month": clampi(int((maxi(1, season_week) - 1) / 4) + 1, 1, 8),
		"phase": season_phase,
		"standings": standings,
		"next_match": get_next_scheduled_match() if active else {},
		"champion": championship_state.get("champion", ""),
		"national_window": international_events
	}

func get_next_scheduled_match() -> Dictionary:
	if recruitment_offer_pending and not has_team:
		return {}
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
	if not season_state.is_empty():
		if season_phase == "club_regular":
			for fixture in season_state.get("fixtures", []):
				if not fixture.get("played", false) and team_name in [fixture.get("home", ""), fixture.get("away", "")]:
					var opponent: String = fixture["away"] if fixture["home"] == team_name else fixture["home"]
					return _season_match(opponent, fixture["week"], fixture["round"], "league", fixture["id"])
		elif season_phase in ["club_semifinal", "club_final"]:
			var opponent = str(championship_state.get("player_opponent", ""))
			if not opponent.is_empty():
				return _season_match(opponent, 30 if season_phase == "club_semifinal" else 32,
					15 if season_phase == "club_semifinal" else 16, "championship")
		return {}
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
	active_fixture_id = -1
	if match_type == "league" and season_phase == "club_regular":
		var scheduled = get_next_scheduled_match()
		if scheduled.get("enemy_team", "") == enemy_team:
			active_fixture_id = int(scheduled.get("fixture_id", -1))
	print("[CampaignManager] Prepared %s match vs %s (%s) from %s" % [match_type, enemy_name, enemy_element, enemy_team])

func record_match_result(victory: bool, xp_gained: int = 60) -> int:
	# Career XP has one owner. Combat reports its outcome here; the player node
	# mirrors these values for its HUD, but never awards XP independently.
	var credited_xp := maxi(0, xp_gained) if victory else int(maxi(0, xp_gained) * 0.4)
	if active_match_type == "friendly":
		credited_xp = int(credited_xp * 0.5)
	if victory:
		total_wins += 1
		win_streak += 1
	else:
		total_losses += 1
		win_streak = 0
	player_xp += credited_xp
	_check_level_up()

	if active_match_type == "street":
		if victory:
			gold += 75
			if not has_team:
				record_street_win()
		else:
			gold += 20
		consume_energy(20)
	elif active_match_type == "friendly":
		gold += 40 if victory else 10
		var friendly_day = get_season_day()
		if friendly_day in [7, 119]:
			if not season_state.has("friendly_results"):
				season_state["friendly_results"] = {}
			season_state["friendly_results"][str(friendly_day)] = {
				"opponent": active_enemy_team, "won": victory}
		consume_energy(20)
	else:
		if victory:
			gold += 200
			shards += 5
		else:
			gold += 40
		if active_match_type == "league" and season_phase == "club_regular":
			_record_club_round(victory)
		elif active_match_type == "championship" and season_phase in ["club_semifinal", "club_final"]:
			_record_championship_result(victory)
		elif active_match_type == "tournament":
			for m in tournament_schedule:
				if not m["completed"]:
					# Legacy fixtures remain available on older saves, but a loss is
					# replayable. Only a win earns the next round.
					if victory:
						m["completed"] = true
						m["result"] = "VICTORY"
						league_round += 1
					break
		consume_energy(20)

	if active_match_type in ["street", "friendly"]:
		campaign_day += 1
		_sync_season_clock()
	elif season_state.is_empty():
		campaign_day += 1

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
	active_fixture_id = -1
	return credited_xp


func _set_season_week(week: int) -> void:
	season_week = clampi(week, 1, SeasonCalendarScript.WEEKS_PER_SEASON)
	campaign_day = maxi(campaign_day, season_start_day + (season_week - 1) * 7)


func _record_club_round(victory: bool) -> void:
	var fixtures: Array = season_state.get("fixtures", [])
	var fixture_id := active_fixture_id
	if fixture_id < 0 or fixture_id >= fixtures.size():
		return
	var fixture: Dictionary = fixtures[fixture_id]
	if fixture.get("played", false) or not team_name in [fixture.get("home", ""), fixture.get("away", "")]:
		return
	var calendar = SeasonCalendarScript.new()
	var score_home := 2 if (victory == (fixture["home"] == team_name)) else 0
	var score_away := 0 if score_home == 2 else 2
	if not calendar.record_result(season_state, fixture_id, score_home, score_away):
		return
	var played_week: int = fixture["week"]
	# The other clubs finish their fixtures in this round. A stable formula
	# makes reloads and repeated test runs yield the same standings.
	for other_fixture in fixtures:
		if other_fixture["week"] != played_week or other_fixture.get("played", false):
			continue
		var result_roll: int = (int(other_fixture["id"]) * 17 + season_number * 13) % 5
		var scores: Array = [[2, 1], [1, 1], [0, 2], [3, 1], [1, 2]][result_roll]
		calendar.record_result(season_state, int(other_fixture["id"]), scores[0], scores[1])
	league_round = int(fixture["round"]) + 1
	var next_match := get_next_scheduled_match()
	if next_match.is_empty():
		_enter_postseason()
	else:
		# The week between fixtures is visible for rest, training and the
		# national-team calendar window, even though the next club fixture
		# is already available to launch from the hub.
		_set_season_week(played_week + 1)


func _enter_postseason() -> void:
	var postseason: Dictionary = SeasonCalendarScript.new().get_postseason(season_state)
	if not postseason.get("ready", false):
		return
	championship_state = postseason
	championship_state["player_opponent"] = ""
	championship_state["champion"] = ""
	for pairing in postseason["semifinals"]:
		if team_name in [pairing["home"], pairing["away"]]:
			championship_state["player_opponent"] = pairing["away"] if pairing["home"] == team_name else pairing["home"]
			break
	if championship_state["player_opponent"].is_empty():
		_finish_club_season()
	else:
		season_phase = "club_semifinal"
		_set_season_week(29)


func _record_championship_result(victory: bool) -> void:
	if season_phase == "club_semifinal":
		if not victory:
			_finish_club_season()
			return
		var other_finalist := ""
		for pairing in championship_state.get("semifinals", []):
			if not team_name in [pairing["home"], pairing["away"]]:
				other_finalist = pairing["home"] # Higher seed wins the simulated semifinal.
				break
		championship_state["player_opponent"] = other_finalist
		season_phase = "club_final"
		_set_season_week(31)
	elif season_phase == "club_final":
		championship_state["champion"] = team_name if victory else championship_state.get("player_opponent", "")
		_finish_club_season()


func _finish_club_season() -> void:
	_set_season_week(32)
	campaign_day = maxi(campaign_day, season_start_day + SeasonCalendarScript.DAYS_PER_SEASON - 1)
	season_phase = "offseason"
	if championship_state.get("champion", "").is_empty():
		var finalists: Array = []
		for pairing in championship_state.get("semifinals", []):
			var semifinal_winner: String = pairing["home"]
			if team_name in [pairing["home"], pairing["away"]] and championship_state.get("player_opponent", "") != "":
				semifinal_winner = championship_state["player_opponent"]
			finalists.append(semifinal_winner)
		if finalists.size() == 2:
			var seeds: Array = championship_state.get("championship_qualifiers", [])
			championship_state["champion"] = finalists[0] if seeds.find(finalists[0]) < seeds.find(finalists[1]) else finalists[1]
	championship_state["player_opponent"] = ""
	var previous_tier := league_tier
	var placement := "stayed"
	if team_name in championship_state.get("promotion_candidates", []) and league_tier < HIGHEST_DOMESTIC_DIVISION:
		promote_team_tier(league_tier + 1)
		placement = "promoted"
		pending_element_choice = get_unlocked_elements().size() < get_element_slot_count()
	elif team_name in championship_state.get("relegation_candidates", []) and league_tier > 1:
		league_tier -= 1
		current_league = "%s Club League" % CLUB_DIVISION_NAMES[league_tier]
		placement = "relegated"
	if previous_tier == HIGHEST_DOMESTIC_DIVISION and championship_state.get("champion", "") == team_name:
		record_national_cup_title()
	season_history.append({
		"season_number": season_number,
		"tier_before": previous_tier,
		"tier_after": league_tier,
		"placement": placement,
		"champion": championship_state.get("champion", ""),
		"standings": SeasonCalendarScript.new().get_standings(season_state)
	})


func advance_to_next_season() -> bool:
	if not has_team or season_phase != "offseason" or season_state.is_empty():
		return false
	season_number += 1
	campaign_day = maxi(campaign_day + 1, season_start_day + SeasonCalendarScript.DAYS_PER_SEASON)
	energy = MAX_ENERGY
	_evaluate_fatigue()
	if not _start_club_season():
		season_number -= 1
		return false
	return save_campaign()

func _check_level_up():
	while player_xp >= player_xp_to_next:
		player_xp -= player_xp_to_next
		player_level += 1
		player_xp_to_next = int(player_xp_to_next * 1.3)
		unspent_stat_points += 3
		unspent_skill_points += 1
		print("[CampaignManager] LEVEL UP! Now Level %d! (+3 Stat Points, +1 Skill Point)" % player_level)

func _ensure_saves_dir() -> void:
	if not DirAccess.dir_exists_absolute(SAVES_DIR):
		DirAccess.make_dir_recursive_absolute(SAVES_DIR)

func create_new_campaign_slot(char_name: String = "") -> String:
	_ensure_saves_dir()
	var base_name = char_name.strip_edges()
	if base_name.is_empty():
		base_name = "Brawler"

	var safe_name = ""
	for i in range(base_name.length()):
		var ch = base_name[i]
		if (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z') or (ch >= '0' and ch <= '9'):
			safe_name += ch.to_lower()
		elif ch == ' ' or ch == '_':
			safe_name += "_"
	if safe_name.is_empty():
		safe_name = "hero"

	var timestamp = int(Time.get_unix_time_from_system())
	var camp_id = "campaign_%d_%s" % [timestamp, safe_name]
	var slot_path = "%s/%s.json" % [SAVES_DIR, camp_id]
	var counter = 1
	while FileAccess.file_exists(slot_path):
		camp_id = "campaign_%d_%s_%d" % [timestamp, safe_name, counter]
		slot_path = "%s/%s.json" % [SAVES_DIR, camp_id]
		counter += 1

	current_save_path = slot_path
	current_campaign_id = camp_id
	return slot_path

func _read_campaign_header(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return {}
	var text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(text) != OK:
		return {}
	var data = json.get_data()
	if not (data is Dictionary) or not _is_save_data_valid(data):
		return {}

	var mod_time = FileAccess.get_modified_time(path)
	var mod_dict = Time.get_datetime_dict_from_unix_time(mod_time)
	var time_str = "%04d-%02d-%02d %02d:%02d" % [
		mod_dict.get("year", 2026),
		mod_dict.get("month", 1),
		mod_dict.get("day", 1),
		mod_dict.get("hour", 0),
		mod_dict.get("minute", 0)
	]

	var p_name = data.get("player_name", "Brawler")
	var p_elem = str(data.get("player_element", "fire")).to_lower()
	if p_elem == "wind": p_elem = "air"
	var p_level = int(data.get("player_level", 1))
	var c_team = data.get("team_name", "Solo")
	var c_tier = int(data.get("league_tier", 1))
	var c_day = int(data.get("campaign_day", 1))
	var c_season = int(data.get("season_number", 1))
	var c_week = int(data.get("season_week", 0))
	var c_wins = int(data.get("total_wins", 0))
	var c_losses = int(data.get("total_losses", 0))
	var c_gold = int(data.get("gold", 0))
	var c_shards = int(data.get("shards", 0))
	var c_id = data.get("campaign_id", path.get_file().get_basename())

	var p_arch = "Striker"
	var allies_arr = data.get("allies", [])
	for a in allies_arr:
		if a is Dictionary and a.get("name") == p_name:
			p_arch = a.get("archetype", "Striker")
			break

	return {
		"path": path,
		"campaign_id": c_id,
		"player_name": p_name,
		"player_element": p_elem,
		"player_level": p_level,
		"archetype": p_arch,
		"team_name": c_team,
		"league_tier": c_tier,
		"campaign_day": c_day,
		"season_number": c_season,
		"season_week": c_week,
		"total_wins": c_wins,
		"total_losses": c_losses,
		"gold": c_gold,
		"shards": c_shards,
		"allies_count": allies_arr.size(),
		"modified_time": mod_time,
		"modified_str": time_str,
		"is_legacy": (path == SAVE_PATH)
	}

func get_saved_campaigns() -> Array[Dictionary]:
	var list: Array[Dictionary] = []
	var seen_paths: Dictionary = {}

	# 1. Scan user://saves/ directory
	_ensure_saves_dir()
	var dir = DirAccess.open(SAVES_DIR)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".json") and not file_name.ends_with(".tmp"):
				var full_path = SAVES_DIR + "/" + file_name
				var header = _read_campaign_header(full_path)
				if not header.is_empty():
					list.append(header)
					seen_paths[full_path] = true
			file_name = dir.get_next()
		dir.list_dir_end()

	# 2. Check legacy SAVE_PATH
	if FileAccess.file_exists(SAVE_PATH) and not seen_paths.has(SAVE_PATH):
		var legacy_header = _read_campaign_header(SAVE_PATH)
		if not legacy_header.is_empty():
			list.append(legacy_header)
			seen_paths[SAVE_PATH] = true

	# Sort descending by modified_time (most recent first)
	list.sort_custom(func(a, b): return a.get("modified_time", 0) > b.get("modified_time", 0))
	return list

func get_latest_save_path() -> String:
	var saves = get_saved_campaigns()
	if not saves.is_empty():
		return saves[0]["path"]
	if FileAccess.file_exists(SAVE_PATH):
		return SAVE_PATH
	return ""

func has_saved_campaign(check_path: String = "") -> bool:
	if not check_path.is_empty():
		return FileAccess.file_exists(check_path)
	if not current_save_path.is_empty() and FileAccess.file_exists(current_save_path):
		return true
	if FileAccess.file_exists(SAVE_PATH):
		return true
	return not get_saved_campaigns().is_empty()

func delete_saved_campaign(file_path: String) -> bool:
	if file_path.is_empty() or not FileAccess.file_exists(file_path):
		return false
	var err = DirAccess.remove_absolute(file_path)
	if err != OK:
		printerr("[CampaignManager] Failed to remove save file at: ", file_path)
		return false
	if FileAccess.file_exists(file_path + ".tmp"):
		DirAccess.remove_absolute(file_path + ".tmp")

	if current_save_path == file_path:
		var remaining = get_saved_campaigns()
		if not remaining.is_empty():
			current_save_path = remaining[0]["path"]
			current_campaign_id = remaining[0]["campaign_id"]
		else:
			current_save_path = SAVE_PATH
			current_campaign_id = ""
			has_active_campaign = false
	print("[CampaignManager] Successfully deleted save slot: ", file_path)
	return true

func duplicate_saved_campaign(source_path: String, new_player_name: String = "") -> String:
	if not FileAccess.file_exists(source_path):
		return ""
	var file = FileAccess.open(source_path, FileAccess.READ)
	if not file:
		return ""
	var json_str = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_str) != OK or not (json.data is Dictionary):
		return ""
	var data: Dictionary = json.data.duplicate(true)
	var p_name = new_player_name.strip_edges() if not new_player_name.strip_edges().is_empty() else (str(data.get("player_name", "Copy")) + " Copy")
	data["player_name"] = p_name

	var new_slot = create_new_campaign_slot(p_name)
	data["campaign_id"] = current_campaign_id
	var out_file = FileAccess.open(new_slot, FileAccess.WRITE)
	if not out_file:
		return ""
	out_file.store_string(JSON.stringify(data, "\t"))
	out_file.close()
	return new_slot

func save_campaign(target_path: String = "") -> bool:
	var dest_path = target_path if not target_path.is_empty() else current_save_path
	if dest_path.is_empty():
		dest_path = SAVE_PATH

	var dir_path = dest_path.get_base_dir()
	if not dir_path.is_empty() and not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var save_camp_id = current_campaign_id
	if save_camp_id.is_empty():
		save_camp_id = dest_path.get_file().get_basename()

	var data = {
		"campaign_id": save_camp_id,
		"has_active_campaign": has_active_campaign,
		"player_name": player_name,
		"player_nationality": player_nationality,
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
		"player_defense": player_defense,
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
		"career_start_year": career_start_year,
		"training_progress": training_progress,
		"training_gains": training_gains,
		"win_streak": win_streak,
		"unlocked_elements": unlocked_elements,
		"recruitment_offer_pending": recruitment_offer_pending,
		"recruitment_offer_club": recruitment_offer_club,
		"pending_element_choice": pending_element_choice,
		"national_cup_titles": national_cup_titles,
		"continental_cup_titles": continental_cup_titles,
		"national_world_cup_titles": national_world_cup_titles,
		"club_world_cup_titles": club_world_cup_titles,
		"primordial_choice_pending": primordial_choice_pending,
		"world_cup_reward_pending": world_cup_reward_pending,
		"primordial_choices": primordial_choices,
		"primordial_skill_permits": primordial_skill_permits,
		"season_state": season_state,
		"season_number": season_number,
		"season_week": season_week,
		"season_start_day": season_start_day,
		"season_phase": season_phase,
		"championship_state": championship_state,
		"season_history": season_history,
	}

	var json_string = JSON.stringify(data, "\t")
	# Replace only after the complete JSON has been flushed, preserving the last
	# good save if writing the new one fails or the process stops mid-write.
	var temporary_path = dest_path + ".tmp"
	var file = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		printerr("[CampaignManager] Failed to save campaign to ", dest_path)
		return false
	file.store_string(json_string)
	file.flush()
	var write_error = file.get_error()
	file.close()
	if write_error != OK:
		printerr("[CampaignManager] Failed to finish writing campaign: ", write_error)
		return false
	var replace_error = DirAccess.rename_absolute(temporary_path, dest_path)
	if replace_error != OK:
		if FileAccess.file_exists(dest_path):
			DirAccess.remove_absolute(dest_path)
			replace_error = DirAccess.rename_absolute(temporary_path, dest_path)
		if replace_error != OK:
			printerr("[CampaignManager] Failed to replace campaign save: ", replace_error)
			return false
	current_save_path = dest_path
	current_campaign_id = save_camp_id
	print("[CampaignManager] Saved campaign successfully to ", dest_path)
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

func _save_fields_match(data: Dictionary, fields: Array, expected_type: int) -> bool:
	for key in fields:
		if not data.has(key):
			continue # Missing fields are supported by legacy-save defaults.
		var value = data[key]
		if expected_type == TYPE_FLOAT:
			if not (value is int or value is float) or not is_finite(float(value)):
				return false
		elif typeof(value) != expected_type:
			return false
	return true

func _is_saved_position_valid(value) -> bool:
	if value is Dictionary:
		return value.has("x") and value.has("y") and _save_fields_match(value, ["x", "y"], TYPE_FLOAT)
	if value is Array:
		return value.size() == 2 and _save_fields_match({"x": value[0], "y": value[1]}, ["x", "y"], TYPE_FLOAT)
	if value is String:
		var parts = value.replace("(", "").replace(")", "").split(",")
		return parts.size() == 2 and parts[0].strip_edges().is_valid_float() and parts[1].strip_edges().is_valid_float()
	return false

func _is_saved_season_valid(value) -> bool:
	if not value is Dictionary:
		return false
	if value.is_empty():
		return true # Older campaigns had no club season.
	if not _save_fields_match(value, ["season_number", "weeks_total"], TYPE_FLOAT):
		return false
	if int(value.get("weeks_total", 0)) != SeasonCalendarScript.WEEKS_PER_SEASON:
		return false
	var teams = value.get("teams", null)
	var fixtures = value.get("fixtures", null)
	var calendar = value.get("calendar", null)
	if not teams is Array or not fixtures is Array or not calendar is Array:
		return false
	if teams.size() != 8 or fixtures.size() != 56 or calendar.size() != 32:
		return false
	var seen: Array = []
	for club in teams:
		if not club is String or club.strip_edges().is_empty() or seen.has(club):
			return false
		seen.append(club)
	for week in calendar:
		if not week is Dictionary or not _save_fields_match(week, ["week", "month"], TYPE_FLOAT):
			return false
		if not week.get("events", null) is Array or not week.get("fixture_ids", null) is Array:
			return false
	for fixture in fixtures:
		if not fixture is Dictionary:
			return false
		if not _save_fields_match(fixture, ["id", "round", "week", "home_score", "away_score"], TYPE_FLOAT):
			return false
		if not _save_fields_match(fixture, ["home", "away"], TYPE_STRING):
			return false
		if not _save_fields_match(fixture, ["played"], TYPE_BOOL):
			return false
		if not seen.has(fixture.get("home", "")) or not seen.has(fixture.get("away", "")):
			return false
	return true

func _is_save_data_valid(data: Dictionary) -> bool:
	# Validate before assigning anything: a malformed roster must not leave a
	# half-loaded campaign that a later autosave would write over the good one.
	if not data.has("player_name") or not data.has("player_element"):
		return false
	var saved_element = str(data["player_element"]).to_lower().strip_edges()
	if saved_element == "wind":
		saved_element = "air"
	if not DEFAULT_ELEMENT_SKILLS.has(saved_element):
		return false
	var schema = {
		TYPE_STRING: ["player_name", "player_element", "player_nationality", "recruitment_offer_club", "active_match_format", "designated_sub", "current_league", "team_name", "career_team", "season_phase", "campaign_id"],
		TYPE_BOOL: ["has_active_campaign", "is_fatigued", "bench_risk", "has_team", "recruitment_offer_pending", "pending_element_choice", "primordial_choice_pending", "world_cup_reward_pending"],
		TYPE_FLOAT: ["player_level", "player_xp", "player_xp_to_next", "player_speed", "player_agility", "player_dexterity", "player_stamina", "player_mana", "player_potency", "player_defense", "unspent_stat_points", "unspent_skill_points", "energy", "league_round", "total_wins", "total_losses", "league_tier", "street_wins", "gold", "shards", "campaign_day", "career_start_year", "win_streak", "season_number", "season_week", "season_start_day", "national_cup_titles", "continental_cup_titles", "national_world_cup_titles", "club_world_cup_titles", "primordial_skill_permits"],
		TYPE_DICTIONARY: ["starting_formation", "appearance", "scouting_intel", "skill_variations", "unlocked_skill_forms", "season_state", "championship_state", "training_progress", "training_gains"],
		TYPE_ARRAY: ["equipped_abilities", "unlocked_abilities", "allies", "tournament_schedule", "known_fighters", "unlocked_elements", "season_history", "primordial_choices"]
	}
	for kind in schema:
		if not _save_fields_match(data, schema[kind], kind):
			return false
	if not _is_saved_season_valid(data.get("season_state", {})):
		return false
	if data.has("player_nationality") and not NATIONALITIES.has(data["player_nationality"]):
		return false
	if data.has("recruitment_offer_club") and data["recruitment_offer_club"] != "" and not SeasonCalendarScript.DEFAULT_TEAMS.has(data["recruitment_offer_club"]):
		return false
	for tracked in ["training_progress", "training_gains"]:
		for key in data.get(tracked, {}):
			if not TRAINING_STATS.has(key) or not data[tracked][key] is float and not data[tracked][key] is int:
				return false
	if data.get("season_phase", "street") not in ["street", "legacy_tournament", "club_regular", "club_semifinal", "club_final", "offseason"]:
		return false
	if not _save_fields_match(data.get("appearance", {}), DEFAULT_APPEARANCE.keys(), TYPE_STRING):
		return false
	var formation = data.get("starting_formation", {})
	for fighter_name in formation:
		if fighter_name == "type":
			if not formation[fighter_name] is String:
				return false
		elif not _is_saved_position_valid(formation[fighter_name]):
			return false
	for key in ["equipped_abilities", "unlocked_abilities", "unlocked_elements"]:
		for value in data.get(key, []):
			if not value is String:
				return false
	for key in ["allies", "known_fighters"]:
		for fighter in data.get(key, []):
			if not fighter is Dictionary or not fighter.has("name"):
				return false
			if not _save_fields_match(fighter, ["name", "element", "status", "career_team", "archetype", "role"], TYPE_STRING):
				return false
			if not _save_fields_match(fighter, ["hp", "mp", "stamina", "speed", "agility", "dexterity", "potential", "level", "league_tier"], TYPE_FLOAT):
				return false
			if not _save_fields_match(fighter, ["base_stats"], TYPE_DICTIONARY):
				return false
			if not _save_fields_match(fighter, ["equipped_skills", "known_skills"], TYPE_ARRAY):
				return false
			for skill_list in ["equipped_skills", "known_skills"]:
				for skill in fighter.get(skill_list, []):
					if not skill is String:
						return false
			if not _save_fields_match(fighter.get("base_stats", {}), ["hp", "mp", "stamina", "speed", "agility", "dexterity"], TYPE_FLOAT):
				return false
	for scheduled_match in data.get("tournament_schedule", []):
		if not scheduled_match is Dictionary or not scheduled_match.has("completed"):
			return false
		if not _save_fields_match(scheduled_match, ["completed"], TYPE_BOOL):
			return false
		if not _save_fields_match(scheduled_match, ["league", "enemy_team", "enemy_captain", "enemy_element", "difficulty", "result"], TYPE_STRING):
			return false
		if not _save_fields_match(scheduled_match, ["round"], TYPE_FLOAT):
			return false
	for intel in data.get("scouting_intel", {}).values():
		if not intel is Dictionary:
			return false
		for identity in ["team_name", "captain", "element"]:
			if not intel.has(identity) or not _save_fields_match(intel, [identity], TYPE_STRING):
				return false
		for list_key in ["weaknesses", "known_skills"]:
			if not intel.has(list_key) or not intel[list_key] is Array:
				return false
			for entry in intel[list_key]:
				if not entry is String:
					return false
		for counter in ["matches_fought", "wins_against", "losses_against"]:
			if not intel.has(counter) or not _save_fields_match(intel, [counter], TYPE_FLOAT):
				return false
	for forms in data.get("unlocked_skill_forms", {}).values():
		if not forms is Array:
			return false
		for form in forms:
			if not form is String:
				return false
	for variant in data.get("skill_variations", {}).values():
		if not variant is String:
			return false
	return true

func load_campaign(source_path: String = "") -> bool:
	var load_path = source_path
	if load_path.is_empty():
		if FileAccess.file_exists(current_save_path):
			load_path = current_save_path
		elif FileAccess.file_exists(SAVE_PATH):
			load_path = SAVE_PATH
		else:
			load_path = get_latest_save_path()

	if load_path.is_empty() or not FileAccess.file_exists(load_path):
		printerr("[CampaignManager] No save file found at ", load_path if not load_path.is_empty() else current_save_path)
		return false

	var file = FileAccess.open(load_path, FileAccess.READ)
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
	if not (data is Dictionary) or not _is_save_data_valid(data):
		printerr("[CampaignManager] Save contains invalid campaign data; current campaign preserved.")
		return false

	current_save_path = load_path
	current_campaign_id = data.get("campaign_id", load_path.get_file().get_basename())
	has_active_campaign = data.get("has_active_campaign", true)
	player_name = data.get("player_name", "Ignis")
	player_nationality = data.get("player_nationality", NATIONALITIES[0])
	var raw_elem = str(data.get("player_element", "fire")).to_lower().strip_edges()
	if raw_elem == "wind": raw_elem = "air"
	player_element = raw_elem
	player_level = data.get("player_level", 1)
	player_xp = data.get("player_xp", 0)
	player_xp_to_next = int(data.get("player_xp_to_next", 100))
	if player_xp_to_next <= 0:
		player_xp_to_next = 100
	league_tier = clampi(int(data.get("league_tier", 1)), 1, 5)
	national_cup_titles = maxi(0, int(data.get("national_cup_titles", 0)))
	continental_cup_titles = maxi(0, int(data.get("continental_cup_titles", 0)))
	national_world_cup_titles = maxi(0, int(data.get("national_world_cup_titles", 0)))
	club_world_cup_titles = maxi(0, int(data.get("club_world_cup_titles", 0)))
	primordial_choices = data.get("primordial_choices", []).duplicate()
	primordial_choice_pending = bool(data.get("primordial_choice_pending", false))
	world_cup_reward_pending = bool(data.get("world_cup_reward_pending", false))
	primordial_skill_permits = maxi(0, int(data.get("primordial_skill_permits", 0)))
	season_history = data.get("season_history", []).duplicate(true)

	var edata_node = _get_element_data()
	var def_spd = 3
	var def_agi = 28
	var def_dex = 32
	var def_sta = 100
	var def_mana = 100
	var def_def = 20
	if edata_node and edata_node.ELEMENTS.has(player_element):
		var p_b = edata_node.ELEMENTS[player_element]
		def_spd = p_b.get("base_speed", 3)
		def_agi = p_b.get("base_agility", 28)
		def_dex = p_b.get("base_dexterity", 32)
		def_sta = p_b.get("base_stamina", 100)
		def_mana = p_b.get("base_mp", 100)
		def_def = p_b.get("base_defense", 20)

	player_speed = max(def_spd, data.get("player_speed", def_spd))
	player_agility = max(def_agi, data.get("player_agility", def_agi))
	player_dexterity = max(def_dex, data.get("player_dexterity", def_dex))
	player_stamina = max(def_sta, data.get("player_stamina", def_sta))
	player_mana = max(def_mana, data.get("player_mana", def_mana))
	player_potency = data.get("player_potency", 30)
	player_defense = max(def_def, data.get("player_defense", def_def))
	unspent_stat_points = data.get("unspent_stat_points", 0)
	unspent_skill_points = data.get("unspent_skill_points", 0)
	active_match_format = data.get("active_match_format", "3v3")

	var raw_formation = data.get("starting_formation", {player_name: Vector2i(3, 4)})
	if raw_formation is Dictionary:
		starting_formation = {}
		for k in raw_formation.keys():
			if k == "type":
				starting_formation[k] = raw_formation[k]
			else:
				starting_formation[k] = parse_vector2i(raw_formation[k])

	designated_sub = data.get("designated_sub", "Gaius")
	var starter_skills: Array = DEFAULT_ELEMENT_SKILLS.get(player_element, DEFAULT_ELEMENT_SKILLS["fire"])
	equipped_abilities = data.get("equipped_abilities", starter_skills.duplicate())
	unlocked_abilities = data.get("unlocked_abilities", equipped_abilities.duplicate())
	# Careers created before the paired-starter update may have only one skill.
	# Grant both without replacing a player's later choices in full loadouts.
	for starter_skill in starter_skills:
		if not unlocked_abilities.has(starter_skill):
			unlocked_abilities.append(starter_skill)
		if not equipped_abilities.has(starter_skill) and equipped_abilities.size() < 4:
			equipped_abilities.append(starter_skill)
	appearance = DEFAULT_APPEARANCE.duplicate(true)
	appearance["sheet_prefix"] = player_element
	appearance["team_palette"] = player_element
	appearance.merge(data.get("appearance", {}), true)
	energy = clampi(int(data.get("energy", 100)), 0, MAX_ENERGY)
	_evaluate_fatigue()
	current_league = data.get("current_league", "Street Circuit")
	league_round = data.get("league_round", 1)
	total_wins = data.get("total_wins", 0)
	total_losses = data.get("total_losses", 0)
	team_name = data.get("team_name", "Phoenix Strikers")
	career_team = data.get("career_team", team_name)
	allies = data.get("allies", [])
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
		if a.get("name") == player_name:
			for starter_skill in starter_skills:
				if not a["known_skills"].has(starter_skill):
					a["known_skills"].append(starter_skill)
			a["equipped_skills"] = equipped_abilities.duplicate()
	tournament_schedule = data.get("tournament_schedule", DEFAULT_TOURNAMENT_SCHEDULE.duplicate(true))
	scouting_intel = data.get("scouting_intel", DEFAULT_SCOUTING_INTEL.duplicate(true))
	skill_variations = data.get("skill_variations", {})
	unlocked_skill_forms = data.get("unlocked_skill_forms", {})
	var edata_load = _get_element_data()
	if edata_load:
		for ab_k in unlocked_abilities:
			var u_forms = get_unlocked_forms_for_skill(ab_k)
			var cur_var = skill_variations.get(ab_k, "")
			# Strictly ensure active skill variation is an unlocked form! If locked or empty, reset to Form 1
			if not u_forms.is_empty() and (cur_var == "" or cur_var == "Base" or not u_forms.has(cur_var)):
				skill_variations[ab_k] = u_forms[0]
	street_wins = data.get("street_wins", 0)
	var legacy_team = not allies.is_empty() and not team_name in ["", "Street Brawler", "Free Agent"]
	has_team = data.get("has_team", legacy_team)
	recruitment_offer_pending = data.get("recruitment_offer_pending", not has_team and street_wins >= RECRUITMENT_WINS_THRESHOLD)
	recruitment_offer_club = data.get("recruitment_offer_club", "")
	if recruitment_offer_pending and recruitment_offer_club.is_empty():
		recruitment_offer_club = _choose_recruitment_club()
	known_fighters = data.get("known_fighters", [])
	gold = data.get("gold", 150)
	shards = data.get("shards", 0)
	campaign_day = data.get("campaign_day", 1)
	career_start_year = int(data.get("career_start_year", Time.get_date_dict_from_system().get("year", 2026)))
	training_progress = data.get("training_progress", {}).duplicate(true)
	training_gains = data.get("training_gains", {}).duplicate(true)
	win_streak = data.get("win_streak", 0)
	unlocked_elements = data.get("unlocked_elements", [player_element.to_lower()])
	# Earlier saves could expose teammate elements to the player's tree. Keep
	# only the choices allowed by the player's current league tier.
	unlocked_elements = get_unlocked_elements()
	pending_element_choice = data.get("pending_element_choice", false)
	if get_unlocked_elements().size() < get_element_slot_count():
		pending_element_choice = true
	season_state = data.get("season_state", {}).duplicate(true)
	season_number = maxi(1, int(data.get("season_number", 1)))
	season_week = clampi(int(data.get("season_week", 0)), 0, SeasonCalendarScript.WEEKS_PER_SEASON)
	season_start_day = maxi(1, int(data.get("season_start_day", campaign_day)))
	season_phase = data.get("season_phase", "street" if not has_team else "legacy_tournament")
	championship_state = data.get("championship_state", {}).duplicate(true)
	season_history = data.get("season_history", []).duplicate(true)
	active_fixture_id = -1
	if has_team and season_state.is_empty():
		# Old four-round tournament saves join the new season without losing
		# their athlete roster, economy, skill tree or career records.
		_start_club_season()
	elif not has_team:
		season_phase = "street"

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
		"defense": player_defense += 2
		_: return false
	unspent_stat_points -= 1
	save_campaign()
	print("[CampaignManager] Spent stat point on %s. Remaining: %d" % [stat_name, unspent_stat_points])
	return true

func revert_stat_point(stat_name: String) -> bool:
	var edata = null
	var edata_node = _get_element_data()
	var norm_elem = player_element.to_lower()
	if norm_elem == "wind": norm_elem = "air"
	if edata_node and edata_node.ELEMENTS.has(norm_elem):
		edata = edata_node.ELEMENTS[norm_elem]

	var floor_speed = edata.get("base_speed", 3) if edata else 3
	var floor_agility = edata.get("base_agility", 28) if edata else 28
	var floor_dexterity = edata.get("base_dexterity", 32) if edata else 32
	var floor_stamina = edata.get("base_stamina", 100) if edata else 100
	var floor_mana = edata.get("base_mp", 100) if edata else 100
	var floor_potency = 30
	var floor_defense = edata.get("base_defense", 20) if edata else 20

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
		"defense":
			if player_defense <= floor_defense: return false
			player_defense -= 2
		_: return false
	unspent_stat_points += 1
	save_campaign()
	print("[CampaignManager] Reverted stat point on %s. Remaining: %d" % [stat_name, unspent_stat_points])
	return true

func get_element_slot_count() -> int:
	# Continental is a cup qualification, not a permanent fourth domestic tier.
	return mini(4, mini(HIGHEST_DOMESTIC_DIVISION, maxi(1, league_tier)) + (1 if continental_cup_titles > 0 else 0))

func get_earned_element_slot_count() -> int:
	# Relegation changes the club's division, not disciplines already earned.
	var best_tier = league_tier
	for season in season_history:
		if season is Dictionary:
			best_tier = maxi(best_tier, maxi(int(season.get("tier_before", 1)), int(season.get("tier_after", 1))))
	return mini(4, mini(HIGHEST_DOMESTIC_DIVISION, maxi(1, best_tier)) + (1 if continental_cup_titles > 0 else 0))

func get_unlocked_elements() -> Array:
	# Squadmates bring their own elements to team battles, but they do not
	# grant the captain permanent access to those disciplines in the skill tree.
	var res: Array = []
	if GEN_ELEMENTS.has(player_element) and not res.has(player_element):
		res.append(player_element)
	var slots = get_earned_element_slot_count()
	for el in unlocked_elements:
		var e = str(el).to_lower()
		if GEN_ELEMENTS.has(e) and not res.has(e) and res.size() < slots:
			res.append(e)
	return res

func unlock_next_element(element_key: String) -> bool:
	# City fighters stay single-element. Regional and National promotion each
	# open one choice; a Continental Cup title opens the fourth slot.
	var next_element = element_key.to_lower().strip_edges()
	if not GEN_ELEMENTS.has(next_element) or get_unlocked_elements().has(next_element):
		return false
	if get_unlocked_elements().size() >= get_element_slot_count():
		return false
	unlocked_elements.append(next_element)
	pending_element_choice = get_unlocked_elements().size() < get_element_slot_count()
	save_campaign()
	return true

func choose_primordial_element(element_key: String) -> bool:
	var chosen = element_key.to_lower().strip_edges()
	if not primordial_choice_pending or not chosen in ["space", "time"] or primordial_choices.has(chosen):
		return false
	primordial_choices.append(chosen)
	primordial_choice_pending = false
	save_campaign()
	return true

func record_national_cup_title() -> void:
	national_cup_titles += 1
	if primordial_choices.is_empty():
		primordial_choice_pending = true
	save_campaign()

func record_continental_cup_title() -> void:
	continental_cup_titles += 1
	pending_element_choice = get_unlocked_elements().size() < get_element_slot_count()
	save_campaign()

func record_national_world_cup_title() -> void:
	national_world_cup_titles += 1
	if national_world_cup_titles >= 2:
		world_cup_reward_pending = true
	save_campaign()

func choose_world_cup_reward(choice: String) -> bool:
	if not world_cup_reward_pending:
		return false
	var selected = choice.to_lower().strip_edges()
	if selected in ["space", "time"]:
		if primordial_choices.has(selected) or primordial_choices.is_empty():
			return false
		primordial_choices.append(selected)
	elif selected == "skill":
		if primordial_choices.is_empty():
			return false
		primordial_skill_permits += 1
	else:
		return false
	world_cup_reward_pending = false
	save_campaign()
	return true

func record_club_world_cup_title() -> void:
	club_world_cup_titles += 1
	# Only a Club World Cup won after a national-team World Cup pays out.
	if national_world_cup_titles > 0 and not primordial_choices.is_empty():
		primordial_skill_permits += 1
	save_campaign()

func can_access_discipline(discipline_key: String) -> Dictionary:
	var edata = get_node_or_null("/root/ElementData")
	if not edata:
		return {"can_access": false, "reason": "ElementData autoload missing."}

	var d_key = discipline_key.to_lower()
	var disc = edata.get_discipline(d_key)
	if disc.is_empty():
		return {"can_access": false, "reason": "Discipline '%s' not found." % discipline_key}

	var cat = disc.get("category", "")
	var available_elements = get_unlocked_elements()
	if cat == "primordial":
		var licensed = primordial_choices.has(d_key) and national_cup_titles > 0
		return {"can_access": licensed,
			"reason": "Win the National Cup, then choose %s." % d_key.capitalize() if not licensed else "%s chosen after a National Cup title." % d_key.capitalize()}

	if cat == "core":
		var is_owned = available_elements.has(d_key)
		return {"can_access": is_owned, "reason": "Element belongs to player." if is_owned else "This element is not unlocked by the player."}

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
	if disc_key in ["space", "time"] and primordial_skill_permits <= 0:
		return {"can_unlock": false, "reason": "Win a national-team World Cup, then a Club World Cup to earn a primordial skill permit."}

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
		var unlocked_node = edata.get_skill_node(skill_key)
		var unlocked_discipline = unlocked_node.get("discipline", edata.ABILITIES.get(skill_key, {}).get("element", ""))
		if unlocked_discipline in ["space", "time"]:
			primordial_skill_permits = maxi(0, primordial_skill_permits - 1)
	_sync_captain_skills()
	if edata:
		var f_keys = edata.get_skill_form_keys(skill_key)
		var first_f = f_keys[0] if not f_keys.is_empty() else "form_1"
		if not unlocked_skill_forms.has(skill_key):
			unlocked_skill_forms[skill_key] = [first_f]
		elif not unlocked_skill_forms[skill_key].has(first_f):
			unlocked_skill_forms[skill_key].append(first_f)
		if not skill_variations.has(skill_key) or skill_variations[skill_key] == "Base" or skill_variations[skill_key] == "":
			skill_variations[skill_key] = first_f
	save_campaign()
	print("[CampaignManager] Unlocked skill node: %s (-%d SP, %d remaining)" % [skill_key, sp_cost, unspent_skill_points])
	return true

func get_unlocked_forms_for_skill(skill_key: String) -> Array:
	if not unlocked_abilities.has(skill_key):
		return []
	var edata = _get_element_data()
	if not edata:
		return []
	var keys = edata.get_skill_form_keys(skill_key)
	var valid_forms: Array = []
	for form in unlocked_skill_forms.get(skill_key, []):
		if keys.has(form) and not valid_forms.has(form):
			valid_forms.append(form)
	if valid_forms.is_empty() and not keys.is_empty():
		valid_forms.append(keys[0])
	unlocked_skill_forms[skill_key] = valid_forms
	return valid_forms.duplicate()

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

func set_active_skill_form(skill_key: String, form_key: String) -> bool:
	var u_forms = get_unlocked_forms_for_skill(skill_key)
	if not u_forms.has(form_key):
		print("[CampaignManager] Cannot set active form '%s' for '%s': Form is locked or invalid." % [form_key, skill_key])
		return false
	skill_variations[skill_key] = form_key
	save_campaign()
	print("[CampaignManager] Set active form for '%s' to '%s'." % [skill_key, form_key])
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
			if a["name"].to_lower() == player_name.to_lower():
				if skills.size() > 4:
					return false
				for skill in skills:
					if not skill is String or not unlocked_abilities.has(skill):
						return false
				equipped_abilities = skills.duplicate()
			a["equipped_skills"] = skills.duplicate()
			print("[CampaignManager] Assigned active skills for %s: %s" % [a["name"], str(skills)])
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
	_sync_captain_skills()
	return true

func _sync_captain_skills() -> void:
	var captain: Dictionary = get_ally(player_name)
	if captain.is_empty():
		return
	captain["known_skills"] = unlocked_abilities.duplicate()
	captain["equipped_skills"] = equipped_abilities.duplicate()

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
			if a["name"].to_lower() == player_name.to_lower():
				if skills.size() > 4:
					return false
				for skill in skills:
					if not skill is String or not unlocked_abilities.has(skill):
						return false
				equipped_abilities = skills.duplicate()
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
	# Save migration can use a manager that has not been added to the tree yet.
	# It can still share the autoload instead of leaking a new Node per lookup.
	var main_loop = Engine.get_main_loop()
	if main_loop is SceneTree:
		var ed = main_loop.root.get_node_or_null("ElementData")
		if ed != null:
			return ed
	if is_instance_valid(_fallback_element_data):
		return _fallback_element_data
	var ed_res = load("res://scripts/element_data.gd")
	if ed_res:
		_fallback_element_data = ed_res.new()
		add_child(_fallback_element_data) # The manager owns the fallback's lifetime.
		return _fallback_element_data
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
	recruitment_offer_pending = false
	active_match_format = "3v3"
	if get_ally(player_name).is_empty():
		var element_data = _get_element_data()
		var base_hp := 90
		if element_data and element_data.ELEMENTS.has(player_element):
			base_hp = int(element_data.ELEMENTS[player_element].get("base_hp", 90))
		allies.insert(0, {
			"name": player_name,
			"element": player_element,
			"role": "Team Captain (Player)",
			"archetype": "Striker",
			"level": player_level,
			"league_tier": league_tier,
			"base_stats": {"hp": base_hp, "mp": player_mana, "stamina": player_stamina,
				"speed": player_speed, "agility": player_agility, "dexterity": player_dexterity},
			"hp": base_hp,
			"mp": player_mana,
			"stamina": player_stamina,
			"speed": player_speed,
			"agility": player_agility,
			"dexterity": player_dexterity,
			"potential": 85,
			"status": "Active",
			"career_team": team_name,
			"known_skills": unlocked_abilities.duplicate(),
			"equipped_skills": equipped_abilities.duplicate()
		})

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


func accept_recruitment_offer() -> bool:
	if not recruitment_offer_pending or has_team or street_wins < RECRUITMENT_WINS_THRESHOLD:
		return false
	var offered_club = recruitment_offer_club if SeasonCalendarScript.DEFAULT_TEAMS.has(recruitment_offer_club) else "Phoenix Strikers"
	trigger_recruitment_offer(offered_club, 4)
	if not _start_club_season():
		return false
	return save_campaign()

func get_recruitment_weights() -> Dictionary:
	var weights := {}
	for club in SeasonCalendarScript.DEFAULT_TEAMS:
		weights[club] = 5 if CLUB_TEAM_COUNTRIES.get(club, "") == player_nationality else 1
	return weights

func _choose_recruitment_club() -> String:
	var weights = get_recruitment_weights()
	var total := 0
	for weight in weights.values():
		total += int(weight)
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(hash("%s:%s:%d" % [player_name, player_nationality, street_wins]))
	var roll := rng.randi_range(1, total)
	for club in SeasonCalendarScript.DEFAULT_TEAMS:
		roll -= int(weights[club])
		if roll <= 0:
			return club
	return SeasonCalendarScript.DEFAULT_TEAMS[0]


## Called when the player earns a street win.
func record_street_win() -> bool:
	street_wins += 1
	print("[CampaignManager] Street wins: %d / %d" % [street_wins, RECRUITMENT_WINS_THRESHOLD])
	if street_wins >= RECRUITMENT_WINS_THRESHOLD and not has_team and not recruitment_offer_pending:
		recruitment_offer_pending = true
		recruitment_offer_club = _choose_recruitment_club()
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
			# The captain is governed by campaign XP and the SP skill tree.
			# A league promotion must never roll a free level or skill offer.
			a["league_tier"] = new_tier
			a["level"] = player_level
			a["known_skills"] = unlocked_abilities.duplicate()
			a["equipped_skills"] = equipped_abilities.duplicate()
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
	current_league = CLUB_DIVISION_NAMES.get(new_tier, LEAGUE_TIERS[new_tier]["name"]) + " Club League"

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
