extends RefCounted
class_name ScoutingCatalog

# This is a directory of known teams, not fabricated league results. The active
# division receives its real record from CampaignManager's season standings.
const DIVISIONS := [
	{"id": "street", "label": "Street"},
	{"id": "city", "label": "City"},
	{"id": "regional", "label": "Regional"},
	{"id": "national", "label": "National"},
	{"id": "continental", "label": "Continental"},
	{"id": "world", "label": "Club World Cup"},
	{"id": "national_teams", "label": "National Teams"},
]

const CLUBS := {
	"street": ["Dockside Sparks", "Canal Kings", "Red Alley Crew", "Stoneblock Union", "Northwind Runners", "Ash Market", "Tide Street", "Glass District"],
	"city": ["Phoenix Strikers", "Hydro Vipers", "Gale Force", "Terra Titans", "Ember Hawks", "Crystal Wardens", "Storm Runners", "Tidebreakers"],
	"regional": ["Volcano Reapers", "Frost Fang Legion", "Iron Bastion", "Skyward Eleven", "Ashen Comets", "Riverguard", "Quartz Blades", "Tempest Atlas"],
	"national": ["Solar Flare Dynasty", "Cobalt Tides", "Monolith FC", "Cyclone Vanguard", "Obsidian Vale", "Whitewater Union", "Thunder Crown", "Verdant Citadel"],
	"continental": ["Aurora Meridian", "Crimson Horizon", "Aegis of Stone", "Monsoon Collective", "Ember Dominion", "Polar Current", "Silver Tempest", "Atlas Sentinels"],
	"world": ["Celestial Arbiters", "Oceanic Imperium", "Worldforge", "Eclipse Circuit", "Solar Axis", "Abyssal Current", "Titan Assembly", "Stratosphere"],
}

const COUNTRIES := ["United States", "Brazil", "Japan", "Nigeria", "France", "Germany", "South Korea", "Mexico"]
const ELEMENTS := ["fire", "water", "earth", "air"]
const CITY_ELEMENTS := {"Phoenix Strikers": "fire", "Hydro Vipers": "water", "Gale Force": "air", "Terra Titans": "earth", "Ember Hawks": "fire", "Crystal Wardens": "earth", "Storm Runners": "air", "Tidebreakers": "water"}
const STYLES := ["Explosive pressure", "Control and sustain", "Defensive counterplay", "Mobile flanking"]

static func teams_for(division: String, manager: Node = null) -> Array:
	var names: Array = COUNTRIES if division == "national_teams" else CLUBS.get(division, [])
	var result: Array = []
	for i in range(names.size()):
		var nation := division == "national_teams"
		var display_name: String = "%s National Team" % names[i] if nation else names[i]
		var element: String = CITY_ELEMENTS.get(names[i], ELEMENTS[i % ELEMENTS.size()]) if division == "city" else ELEMENTS[i % ELEMENTS.size()]
		result.append({
			"name": display_name, "captain": "Unscouted", "element": element,
			"element_label": "Mixed elements" if nation else element.capitalize(),
			"rank": i + 1, "tier": "International" if nation else ("Club World Cup" if division == "world" else division.capitalize()),
			"wins": 0, "draws": 0, "losses": 0, "points": 0,
			"scouting_only": true, "playstyle": "Selection pending" if nation else STYLES[i % STYLES.size()],
			"strengths": ["Mixed-element roster potential"] if nation else ["Signature %s tactics" % element.capitalize()],
			"weaknesses": ["Scout in a match to learn counters"], "roster": [],
		})
	if manager and division == "national_teams":
		for team in result:
			if team["name"] == "%s National Team" % manager.player_nationality:
				team["captain"] = "Selection pending"
	return result
