# element_data.gd
# Central registry for all elements, abilities, form variations, and fusions from the Elemental Showdown GDD.
# Supports 4 core elements (Fire, Water, Earth, Air), starter roles (Heal, Defense, Evasion, Burst),
# and Double, Triple, and Quadruple (Space & Time) Fusions.
extends Node

# ──────────────────────────────────────────────
#  CENTRALIZED PROGRESSION BALANCE CONFIGURATION
# ──────────────────────────────────────────────

const SKILL_LEVEL_REQUIREMENTS = {
	"basic": 1,
	"advanced": 6,
	"mastery": 15,
	"pinnacle": 25
}

const SKILL_SP_COSTS = {
	"basic": 1,
	"advanced": 1,
	"mastery": 1,
	"pinnacle": 2
}

# ──────────────────────────────────────────────
#  ABILITY DEFINITIONS
#  Each ability dict:
#    name, element, damage, mp_cost, range, accuracy, effect, tier, falloff_per_tile, forms, desc
# ──────────────────────────────────────────────

const ABILITIES = {

	# ── FIRE ──────────────────────────────────────────────────────────────────
	"Combustion": {
		"name": "Combustion", "element": "fire",
		"damage": 35, "mp_cost": 10, "range": 2, "accuracy": 92,
		"effect": "burn", "tier": "basic", "falloff_per_tile": 0.10,
		"forms": {
			"punch": {"name": "Explosive Punch", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Melee 1-box kinetic blast"},
			"pulse": {"name": "Explosion Pulse", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Forward 4-box linear shockwave"},
			"outburst": {"name": "Explosion Outburst", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "360° radial shockwave"}
		},
		"desc": "Ignite and sustain chemical fires. Applies Burn (DoT) on hit."
	},
	"Lightning": {
		"name": "Lightning", "element": "fire",
		"damage": 45, "mp_cost": 20, "range": 3, "accuracy": 90,
		"effect": "stun", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"shock_palm": {"name": "Shock Palm", "range": 1, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Touch-range neural overload"},
			"chain_bolt": {"name": "Chain Bolt", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "cardinal", "desc": "Arcs to adjacent wet/metal targets"},
			"storm_ring": {"name": "Storm Ring", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial perimeter discharge"}
		},
		"desc": "Generate and redirect electrical discharges. Chance to Stun."
	},
	"Laser": {
		"name": "Laser", "element": "fire",
		"damage": 40, "mp_cost": 15, "range": 5, "accuracy": 98,
		"effect": "", "tier": "basic", "falloff_per_tile": 0.04,
		"forms": {
			"needle": {"name": "Needle Beam", "range": 5, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Pinpoint sniper beam"},
			"prism_sweep": {"name": "Prism Sweep", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.20, "shape": "cardinal", "desc": "Wide 3-tile horizontal sweep"},
			"flash_flare": {"name": "Flash Flare", "range": 2, "dmg_mult": 0.70, "mp_mult": 0.90, "shape": "radial", "is_radial": true, "effect": "blind", "desc": "Blinding flash"}
		},
		"desc": "Concentrate photonic energy into a focused beam. Long range."
	},
	"Plasma": {
		"name": "Plasma", "element": "fire",
		"damage": 60, "mp_cost": 28, "range": 2, "accuracy": 88,
		"effect": "melt", "tier": "advanced", "falloff_per_tile": 0.12,
		"forms": {
			"plasma_lance": {"name": "Plasma Lance", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.90, "shape": "linear_front", "desc": "Piercing ionized thermal spike that melts armor"},
			"plasma_arc": {"name": "Plasma Arc", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "cardinal", "desc": "Sweeping superheated plasma arc"},
			"plasma_core": {"name": "Plasma Core", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial core detonation vaporizing defenses"}
		},
		"desc": "Ionize matter into its fourth state. High damage, reduces armor."
	},
	"Thermal_Radiation": {
		"name": "Thermal Radiation", "element": "fire",
		"damage": 25, "mp_cost": 8, "range": 2, "accuracy": 95,
		"effect": "aoe_heat", "tier": "basic", "falloff_per_tile": 0.05,
		"forms": {
			"heat_wave": {"name": "Heat Wave", "range": 2, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Direct infrared flash wave"},
			"scorch_beam": {"name": "Scorch Beam", "range": 4, "dmg_mult": 1.10, "mp_mult": 1.05, "shape": "linear_front", "desc": "Focused beam of silent searing heat"},
			"furnace_zone": {"name": "Furnace Zone", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.20, "shape": "radial", "is_radial": true, "desc": "Radial infrared zone inflicting burn"}
		},
		"desc": "Emit infrared heat in a radius without open flame."
	},
	"Nuclear_Ignition": {
		"name": "Nuclear Ignition", "element": "fire",
		"damage": 80, "mp_cost": 40, "range": 2, "accuracy": 85,
		"effect": "irradiate", "tier": "mastery", "falloff_per_tile": 0.10,
		"forms": {
			"fission_strike": {"name": "Fission Strike", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Point-blank micro-fission blast dealing massive damage"},
			"atomic_lance": {"name": "Atomic Lance", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear ionizing particle beam leaving radioactive wake"},
			"fusion_nova": {"name": "Fusion Nova", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial thermonuclear burst irradiating all adjacent tiles"}
		},
		"desc": "Trigger fission/fusion reactions at a microscopic scale."
	},
	"Photonic_Burst": {
		"name": "Photonic Burst", "element": "fire",
		"damage": 50, "mp_cost": 22, "range": 3, "accuracy": 94,
		"effect": "blind", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"blinding_flare": {"name": "Blinding Flare", "range": 3, "dmg_mult": 0.90, "mp_mult": 0.85, "shape": "cardinal", "desc": "Concentrated photonic flash that blinds the target"},
			"light_spear": {"name": "Light Spear", "range": 4, "dmg_mult": 1.15, "mp_mult": 1.05, "shape": "linear_front", "desc": "Linear piercing photonic javelin"},
			"solar_dispersion": {"name": "Solar Dispersion", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Omnidirectional radiant shockwave"}
		},
		"desc": "Explosive release of pure light energy in all directions."
	},
	"Destruction": {
		"name": "Destruction", "element": "fire",
		"damage": 120, "mp_cost": 60, "range": 2, "accuracy": 90,
		"effect": "unmaking", "tier": "pinnacle", "falloff_per_tile": 0.15,
		"forms": {
			"annihilation_ray": {"name": "Annihilation Ray", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear entropy disintegration ray"},
			"cataclysm_sphere": {"name": "Cataclysm Sphere", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial cataclysmic vortex unmaking matter"},
			"void_lance": {"name": "Void Lance", "range": 1, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Melee singular strike tearing molecular cohesion"}
		},
		"desc": "Accelerate entropy in matter at a molecular level. The target ceases to hold structure."
	},

	# ── WATER ─────────────────────────────────────────────────────────────────
	"Aqua_Mend": {
		"name": "Aqua Mend", "element": "water",
		"damage": -32, "mp_cost": 12, "range": 2, "accuracy": 100,
		"effect": "heal", "tier": "basic", "falloff_per_tile": 0.05,
		"forms": {
			"hydration_touch": {"name": "Hydration Touch", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.85, "shape": "cardinal", "desc": "1-box direct cellular mend (+40 HP)"},
			"healing_vapor": {"name": "Healing Vapor", "range": 3, "dmg_mult": 0.90, "mp_mult": 1.00, "shape": "linear_front", "desc": "3-box line restorative spray"},
			"spring_pool": {"name": "Spring Pool", "range": 2, "dmg_mult": 0.75, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "is_hazard": true, "desc": "Leaves a healing water puddle"}
		},
		"desc": "Starter cellular hydration and biological repair. Heals an ally."
	},
	"Ice": {
		"name": "Ice", "element": "water",
		"damage": 30, "mp_cost": 10, "range": 2, "accuracy": 92,
		"effect": "slow", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"frost_shard": {"name": "Frost Shard", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear freezing spike"},
			"frost_nova": {"name": "Frost Nova", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial freezing shockwave"},
			"ice_lance": {"name": "Ice Lance", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Heavy melee ice piercer"}
		},
		"desc": "Freeze moisture instantly. Applies Slow on hit."
	},
	"Blood": {
		"name": "Blood", "element": "water",
		"damage": 55, "mp_cost": 25, "range": 2, "accuracy": 90,
		"effect": "control", "tier": "advanced", "falloff_per_tile": 0.10,
		"forms": {
			"siphon_strike": {"name": "Siphon Strike", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Direct touch coagulating enemy circulation and siphoning vigor"},
			"crimson_needle": {"name": "Crimson Needle", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Crystallized iron-blood projectile with armor pierce"},
			"vascular_rupture": {"name": "Vascular Rupture", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial hematic resonance disrupting enemy cardiovascular rhythm"}
		},
		"desc": "Control iron-rich fluids within living bodies. Precise and lethal."
	},
	"Rejuvenation": {
		"name": "Rejuvenation", "element": "water",
		"damage": -55, "mp_cost": 30, "range": 3, "accuracy": 100,
		"effect": "heal", "tier": "pinnacle", "falloff_per_tile": 0.02,
		"forms": {
			"life_stream": {"name": "Life Stream", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Continuous beam of restorative primordial water"},
			"cellular_surge": {"name": "Cellular Surge", "range": 1, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Direct restorative infusion cleansing trauma and scars"},
			"fountain_bloom": {"name": "Fountain Bloom", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial regenerative fountain reviving all nearby allies"}
		},
		"desc": "Accelerate cellular hydration and biological repair. Heals an ally. Can reverse Scarring."
	},
	"Acid_Rain": {
		"name": "Acid Rain", "element": "water",
		"damage": 35, "mp_cost": 15, "range": 4, "accuracy": 88,
		"effect": "corrode", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"corrosive_jet": {"name": "Corrosive Jet", "range": 3, "dmg_mult": 1.10, "mp_mult": 0.90, "shape": "linear_front", "desc": "Concentrated acidic stream melting single target armor"},
			"caustic_downpour": {"name": "Caustic Downpour", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "cardinal", "desc": "Overhead acid squall striking target area"},
			"acid_deluge": {"name": "Acid Deluge", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial caustic splash corroding all adjacent tiles"}
		},
		"desc": "Alter the pH of water to corrosive extremes mid-fall."
	},
	"Pressure_Wave": {
		"name": "Pressure Wave", "element": "water",
		"damage": 40, "mp_cost": 18, "range": 3, "accuracy": 92,
		"effect": "knockback", "tier": "basic", "falloff_per_tile": 0.09,
		"forms": {
			"water_cannon": {"name": "Water Cannon", "range": 3, "dmg_mult": 1.10, "mp_mult": 0.90, "shape": "linear_front", "desc": "High pressure linear jet blasting target backwards"},
			"hydro_impact": {"name": "Hydro Impact", "range": 2, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "cardinal", "desc": "Focused hydraulic compression hammer"},
			"tsunami_burst": {"name": "Tsunami Burst", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial hydro-kinetic surge knocking back all adjacent combatants"}
		},
		"desc": "Compress water into a hydro-kinetic shockwave. Pushes enemies back."
	},
	"Tide_Pull": {
		"name": "Tide Pull", "element": "water",
		"damage": 20, "mp_cost": 22, "range": 5, "accuracy": 90,
		"effect": "pull", "tier": "advanced", "falloff_per_tile": 0.05,
		"forms": {
			"undertow_lash": {"name": "Undertow Lash", "range": 5, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Long-range water tendon pulling target directly to you"},
			"rip_current": {"name": "Rip Current", "range": 4, "dmg_mult": 1.15, "mp_mult": 1.05, "shape": "cardinal", "desc": "Violent cross-current dragging target off balance"},
			"maelstrom_vortex": {"name": "Maelstrom Vortex", "range": 3, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial whirlpool pulling all surrounding units 1 tile inward"}
		},
		"desc": "Exert tidal-scale gravitational force on large water bodies. Pulls enemy toward you."
	},
	"Mist_Fog": {
		"name": "Mist / Fog", "element": "water",
		"damage": 0, "mp_cost": 12, "range": 3, "accuracy": 100,
		"effect": "conceal", "tier": "basic", "falloff_per_tile": 0.0,
		"forms": {
			"vapor_screen": {"name": "Vapor Screen", "range": 2, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Dense wall of moisture granting heavy evasion"},
			"choking_haze": {"name": "Choking Haze", "range": 3, "dmg_mult": 1.10, "mp_mult": 1.00, "shape": "linear_front", "desc": "Pressurized vapor spray obscuring enemy sightline"},
			"fog_shroud": {"name": "Fog Shroud", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial mist cloud concealing user and allies"}
		},
		"desc": "Disperse water into microscopic droplets — concealment or suffocation."
	},
	"Purification": {
		"name": "Purification", "element": "water",
		"damage": 0, "mp_cost": 15, "range": 2, "accuracy": 100,
		"effect": "cleanse", "tier": "advanced", "falloff_per_tile": 0.0,
		"forms": {
			"cleansing_touch": {"name": "Cleansing Touch", "range": 1, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Direct touch removing all negative status conditions"},
			"sanctified_pulse": {"name": "Sanctified Pulse", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear radiant stream purging poisons and burns"},
			"pure_sanctuary": {"name": "Pure Sanctuary", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial sacred aura granting debuff immunity for 1 turn"}
		},
		"desc": "Strip contaminants from water. Also poisons by stripping nutrients."
	},

	# ── EARTH ─────────────────────────────────────────────────────────────────
	"Stone_Plating": {
		"name": "Stone Plating", "element": "earth",
		"damage": 20, "mp_cost": 10, "range": 1, "accuracy": 95,
		"effect": "barrier", "tier": "basic", "falloff_per_tile": 0.0,
		"forms": {
			"stone_skin": {"name": "Stone Skin", "range": 1, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "cardinal", "effect": "armor_buff", "desc": "Self armor & poise boost (+40 shield)"},
			"rock_pillar": {"name": "Rock Pillar", "range": 2, "dmg_mult": 0.70, "mp_mult": 1.10, "shape": "linear_front", "is_cover": true, "desc": "Summons a stone barricade blocking LOS"},
			"tremor_anchor": {"name": "Tremor Anchor", "range": 1, "dmg_mult": 1.10, "mp_mult": 1.00, "shape": "cardinal", "effect": "anchor", "desc": "Plants feet: immune to blitz steal & knockback"}
		},
		"desc": "Starter mineral bulwark and barrier fortification."
	},
	"Metal": {
		"name": "Metal", "element": "earth",
		"damage": 38, "mp_cost": 12, "range": 2, "accuracy": 94,
		"effect": "", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"forged_fist": {"name": "Forged Fist", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.85, "shape": "cardinal", "desc": "Heavy hardened iron punch inflicting crushing impact"},
			"ferrous_spike": {"name": "Ferrous Spike", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Piercing forged metallic projectile that ignores 30% armor"},
			"shrapnel_burst": {"name": "Shrapnel Burst", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial cloud of jagged steel razor fragments"}
		},
		"desc": "Shape and magnetize ferrous and non-ferrous alloys."
	},
	"Sand": {
		"name": "Sand", "element": "earth",
		"damage": 20, "mp_cost": 8, "range": 3, "accuracy": 88,
		"effect": "blind", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"sand_blast": {"name": "Sand Blast", "range": 3, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "linear_front", "desc": "High velocity abrasive spray blinding target"},
			"dune_shroud": {"name": "Dune Shroud", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.90, "shape": "cardinal", "desc": "Whirling granular vortex granting +35% evasion"},
			"quicksand_trap": {"name": "Quicksand Trap", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial loose sand trap slowing all entering combatants"}
		},
		"desc": "Control granular matter — abrasive, fluid-like, near-invisible in mass."
	},
	"Crystal": {
		"name": "Crystal", "element": "earth",
		"damage": 30, "mp_cost": 14, "range": 2, "accuracy": 92,
		"effect": "barrier", "tier": "basic", "falloff_per_tile": 0.07,
		"forms": {
			"crystal_shard": {"name": "Crystal Shard", "range": 3, "dmg_mult": 1.05, "mp_mult": 0.90, "shape": "linear_front", "desc": "Razor-sharp quartz lance piercing through barriers"},
			"lattice_shield": {"name": "Lattice Shield", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Crystalline barrier reflecting 25% of ranged damage"},
			"prism_shatter": {"name": "Prism Shatter", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial detonation of crystalline geometry inflicting bleed"}
		},
		"desc": "Grow and shatter mineral lattices with precision."
	},
	"Magnetism": {
		"name": "Magnetism", "element": "earth",
		"damage": 25, "mp_cost": 16, "range": 4, "accuracy": 90,
		"effect": "pull", "tier": "advanced", "falloff_per_tile": 0.05,
		"forms": {
			"magnetic_pulse": {"name": "Magnetic Pulse", "range": 4, "dmg_mult": 1.00, "mp_mult": 0.90, "shape": "linear_front", "desc": "Electromagnetic pulse yanking target toward or away"},
			"ferro_crush": {"name": "Ferro Crush", "range": 2, "dmg_mult": 1.20, "mp_mult": 1.05, "shape": "cardinal", "desc": "Heavy magnetic clamp compressing metallic armor"},
			"polar_inversion": {"name": "Polar Inversion", "range": 3, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial polarity wave disrupting all metallic items and weapons"}
		},
		"desc": "Attract and repel metallic objects at range."
	},
	"Petrification": {
		"name": "Petrification", "element": "earth",
		"damage": 15, "mp_cost": 20, "range": 2, "accuracy": 86,
		"effect": "root", "tier": "advanced", "falloff_per_tile": 0.10,
		"forms": {
			"basalt_gaze": {"name": "Basalt Gaze", "range": 2, "dmg_mult": 1.00, "mp_mult": 0.90, "shape": "cardinal", "desc": "Direct mineralizing ray stiffening target joints"},
			"calcifying_lance": {"name": "Calcifying Lance", "range": 3, "dmg_mult": 1.10, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear calcium spike rooting target for 1 turn"},
			"stone_bloom": {"name": "Stone Bloom", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial petrification field encasing ground in solid stone"}
		},
		"desc": "Accelerate mineral crystallization within organic matter. Roots target."
	},
	"Tectonic": {
		"name": "Tectonic", "element": "earth",
		"damage": 50, "mp_cost": 30, "range": 3, "accuracy": 88,
		"effect": "terrain_break", "tier": "mastery", "falloff_per_tile": 0.08,
		"forms": {
			"fault_line": {"name": "Fault Line", "range": 3, "dmg_mult": 1.05, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear rift cracking the ground and destroying cover"},
			"seismic_slam": {"name": "Seismic Slam", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Brutal tectonic ground pound staggering the target"},
			"earthquake": {"name": "Earthquake", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial seismic shockwave destabilizing all surrounding tiles"}
		},
		"desc": "Trigger localized seismic shifts — split ground or raise terrain."
	},
	"Density_Shift": {
		"name": "Density Shift", "element": "earth",
		"damage": 0, "mp_cost": 18, "range": 2, "accuracy": 95,
		"effect": "compress", "tier": "advanced", "falloff_per_tile": 0.0,
		"forms": {
			"hyper_density": {"name": "Hyper Density", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Compress physical mass into ultra-dense posture: +50 poise"},
			"mass_press": {"name": "Mass Press", "range": 2, "dmg_mult": 1.15, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear gravitational compression crushing target footing"},
			"collapse_field": {"name": "Collapse Field", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial density alteration pulling adjacent enemies down"}
		},
		"desc": "Compress or expand matter without changing its mass."
	},
	"Gravity": {
		"name": "Gravity", "element": "earth",
		"damage": 45, "mp_cost": 45, "range": 3, "accuracy": 92,
		"effect": "lockdown", "tier": "pinnacle", "falloff_per_tile": 0.05,
		"forms": {
			"gravitic_pull": {"name": "Gravitic Pull", "range": 4, "dmg_mult": 0.90, "mp_mult": 0.90, "shape": "linear_front", "desc": "Pulls distant enemies 2 squares toward your position"},
			"event_horizon": {"name": "Event Horizon", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial singularity trapping all targets in complete lockdown"},
			"gravitic_crush": {"name": "Gravitic Crush", "range": 3, "dmg_mult": 1.25, "mp_mult": 1.10, "shape": "cardinal", "desc": "Focal gravity well slamming down on target for massive impact"}
		},
		"desc": "Manipulate gravitational pull in a localized field. Full lockdown — no mobility escape."
	},

	# ── AIR ───────────────────────────────────────────────────────────────────
	"Gale_Step": {
		"name": "Gale Step", "element": "air",
		"damage": 18, "mp_cost": 8, "range": 2, "accuracy": 95,
		"effect": "evasion", "tier": "basic", "falloff_per_tile": 0.0,
		"forms": {
			"wind_slip": {"name": "Wind Slip", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "effect": "dodge_buff", "desc": "+40% Agility dodge for next turn"},
			"gale_dash": {"name": "Gale Dash", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "effect": "disengage", "desc": "Disengage leap: ignores flanking penalties"},
			"vortex_screen": {"name": "Vortex Screen", "range": 2, "dmg_mult": 0.75, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial projectile deflection barrier"}
		},
		"desc": "Starter zephyr slipping and elusive wind momentum."
	},
	"Wind": {
		"name": "Wind", "element": "air",
		"damage": 20, "mp_cost": 8, "range": 3, "accuracy": 90,
		"effect": "push", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"gust_strike": {"name": "Gust Strike", "range": 2, "dmg_mult": 1.10, "mp_mult": 0.85, "shape": "cardinal", "desc": "Concentrated air punch knocking target back 1 tile"},
			"cyclone_line": {"name": "Cyclone Line", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear wind funnel clearing hazards and pushing foes"},
			"tempest_gale": {"name": "Tempest Gale", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial hurricane burst repelling all surrounding units"}
		},
		"desc": "Generate directed airflow up to hurricane-force velocities."
	},
	"Sound_Sonic": {
		"name": "Sound / Sonic", "element": "air",
		"damage": 35, "mp_cost": 14, "range": 3, "accuracy": 92,
		"effect": "disrupt", "tier": "basic", "falloff_per_tile": 0.07,
		"forms": {
			"sonic_palm": {"name": "Sonic Palm", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Point-blank acoustic pulse staggering target poise"},
			"resonance_beam": {"name": "Resonance Beam", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear sonic frequency beam bypassing physical shields"},
			"cacophony_burst": {"name": "Cacophony Burst", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial sonic shockwave disorienting all nearby combatants"}
		},
		"desc": "Shape compression waves into weaponized frequencies."
	},
	"Nitrogen": {
		"name": "Nitrogen", "element": "air",
		"damage": 30, "mp_cost": 12, "range": 2, "accuracy": 90,
		"effect": "cryo", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"frostbite_grasp": {"name": "Frostbite Grasp", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Sub-zero liquid nitrogen touch freezing target reflexes"},
			"cryo_jet": {"name": "Cryo Jet", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear nitrogen plume causing chilling frost"},
			"asphyxiation_zone": {"name": "Asphyxiation Zone", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial nitrogen displacement choking enemy stamina"}
		},
		"desc": "Isolate and wield nitrogen — asphyxiation, cryogenic cooling, inert barriers."
	},
	"Oxygen": {
		"name": "Oxygen", "element": "air",
		"damage": 20, "mp_cost": 10, "range": 3, "accuracy": 94,
		"effect": "ignite_boost", "tier": "basic", "falloff_per_tile": 0.05,
		"forms": {
			"combustion_feed": {"name": "Combustion Feed", "range": 3, "dmg_mult": 1.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Inject pure oxygen into flames, amplifying fire damage"},
			"pressure_vent": {"name": "Pressure Vent", "range": 4, "dmg_mult": 1.10, "mp_mult": 1.00, "shape": "linear_front", "desc": "High velocity oxygen jet disrupting projectile trajectory"},
			"oxygen_surge": {"name": "Oxygen Surge", "range": 2, "dmg_mult": 0.00, "mp_mult": 1.20, "shape": "radial", "is_radial": true, "desc": "Radial stamina replenishment surge for squad"}
		},
		"desc": "Concentrate or deplete oxygen in a zone — fire-feeding or suffocation."
	},
	"Vacuum": {
		"name": "Vacuum", "element": "air",
		"damage": 40, "mp_cost": 22, "range": 4, "accuracy": 88,
		"effect": "pull_all", "tier": "advanced", "falloff_per_tile": 0.08,
		"forms": {
			"implosion_palm": {"name": "Implosion Palm", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Micro-vacuum pocket collapsing on target torso"},
			"vortex_tunnel": {"name": "Vortex Tunnel", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Zero-pressure vacuum corridor yanking enemies forward"},
			"spatial_implosion": {"name": "Spatial Implosion", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial atmospheric vacuum sucking in all nearby units"}
		},
		"desc": "Create pockets of near-zero pressure — lethal spatial compression."
	},
	"Pressure_Control": {
		"name": "Pressure Control", "element": "air",
		"damage": 55, "mp_cost": 28, "range": 2, "accuracy": 86,
		"effect": "crush", "tier": "mastery", "falloff_per_tile": 0.10,
		"forms": {
			"baric_strike": {"name": "Baric Strike", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Sudden barometric spike slamming target to the floor"},
			"pressurized_lance": {"name": "Pressurized Lance", "range": 3, "dmg_mult": 1.05, "mp_mult": 1.00, "shape": "linear_front", "desc": "High atmosphere compression bolt piercing armor"},
			"hyperbaric_crush": {"name": "Hyperbaric Crush", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial high-pressure atmospheric dome crushing stamina"}
		},
		"desc": "Crush or expand matter via rapid atmospheric pressure changes."
	},
	"Scent_Pheromone": {
		"name": "Scent / Pheromone", "element": "air",
		"damage": 0, "mp_cost": 16, "range": 4, "accuracy": 85,
		"effect": "confuse", "tier": "advanced", "falloff_per_tile": 0.0,
		"forms": {
			"tracer_mist": {"name": "Tracer Mist", "range": 4, "dmg_mult": 0.00, "mp_mult": 0.80, "shape": "linear_front", "desc": "Mark target with biochemical scent, giving allies +30% accuracy"},
			"alluring_vapor": {"name": "Alluring Vapor", "range": 3, "dmg_mult": 0.00, "mp_mult": 1.00, "shape": "cardinal", "desc": "Pheromone trail luring enemy to step into flanking vulnerability"},
			"confusion_cloud": {"name": "Confusion Cloud", "range": 2, "dmg_mult": 0.70, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial sensory deluge confounding enemy target selection"}
		},
		"desc": "Carry chemical signals on air currents — influence instinct."
	},
	"Space": {
		"name": "Space", "element": "space",
		"damage": 70, "mp_cost": 55, "range": 6, "accuracy": 95,
		"effect": "zone_denial", "tier": "pinnacle", "falloff_per_tile": 0.02,
		"forms": {
			"void_cleave": {"name": "Void Cleave", "range": 2, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Fissure in localized space rending target matter"},
			"dimensional_ray": {"name": "Dimensional Ray", "range": 6, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Long-range beam traversing across folded space"},
			"macro_singularity": {"name": "Macro Singularity", "range": 4, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Massive spatial collapse zone denying movement across 5x5"}
		},
		"desc": "Extend control to the macro void. Largest area-denial skill in the game."
	},

	# ── SPACE & TIME (PRIMORDIAL DISCIPLINES) ─────────────────────────────────
	"Spatial_Shift": {
		"name": "Spatial Shift", "element": "space",
		"damage": 22, "mp_cost": 12, "range": 3, "accuracy": 96,
		"effect": "teleport", "tier": "basic", "falloff_per_tile": 0.0,
		"forms": {
			"phase_step": {"name": "Phase Step", "range": 2, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Instant short-range dimensional blink bypassing obstacles"},
			"slipstream_thrust": {"name": "Slipstream Thrust", "range": 3, "dmg_mult": 1.10, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear spatial leap striking through target tile"},
			"spatial_reposition": {"name": "Spatial Reposition", "range": 3, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Swap positions with an ally or displace adjacent enemy"}
		},
		"desc": "Fold local coordinates to displace through space, ignoring obstacles."
	},
	"Spatial_Compression": {
		"name": "Spatial Compression", "element": "space",
		"damage": 48, "mp_cost": 24, "range": 4, "accuracy": 92,
		"effect": "compress", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"warp_pinch": {"name": "Warp Pinch", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Pinch coordinates around target causing localized dimensional crush"},
			"fold_beam": {"name": "Fold Beam", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear compression seam pulling line targets inward"},
			"singularity_pull": {"name": "Singularity Pull", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial vortex collapsing surrounding space toward center"}
		},
		"desc": "Crush dimensional volume, pulling surrounding targets toward a singularity."
	},
	"Spatial_Barrier": {
		"name": "Spatial Barrier", "element": "space",
		"damage": 0, "mp_cost": 18, "range": 2, "accuracy": 100,
		"effect": "barrier", "tier": "advanced", "falloff_per_tile": 0.0,
		"forms": {
			"dimensional_aegis": {"name": "Dimensional Aegis", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Personal folded space shield redirecting next 60 incoming damage"},
			"phase_wall": {"name": "Phase Wall", "range": 3, "dmg_mult": 0.00, "mp_mult": 1.05, "shape": "linear_front", "desc": "Linear dimensional barrier blocking enemy projectiles and movement"},
			"null_sphere": {"name": "Null Sphere", "range": 2, "dmg_mult": 0.00, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial defensive zone absorbing all ranged attacks for 1 turn"}
		},
		"desc": "Curvature event horizon that refracts and absorbs all incoming attacks."
	},
	"Time_Dilation": {
		"name": "Time Dilation", "element": "time",
		"damage": 24, "mp_cost": 12, "range": 3, "accuracy": 95,
		"effect": "slow", "tier": "basic", "falloff_per_tile": 0.05,
		"forms": {
			"chronobreak_touch": {"name": "Chronobreak Touch", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Direct strike reducing target movement speed to 1"},
			"temporal_beam": {"name": "Temporal Beam", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear stream dilating time flow for all caught in ray"},
			"sloth_field": {"name": "Sloth Field", "range": 2, "dmg_mult": 0.75, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial field reducing enemy speed and agility by 50%"}
		},
		"desc": "Alter temporal flow around a target, dilating their movement speed."
	},
	"Chrono_Acceleration": {
		"name": "Chrono Acceleration", "element": "time",
		"damage": 0, "mp_cost": 16, "range": 2, "accuracy": 100,
		"effect": "haste", "tier": "advanced", "falloff_per_tile": 0.0,
		"forms": {
			"quick_step": {"name": "Quick Step", "range": 1, "dmg_mult": 0.00, "mp_mult": 0.85, "shape": "cardinal", "desc": "Accelerate personal timeline granting +2 movement squares"},
			"haste_conduit": {"name": "Haste Conduit", "range": 3, "dmg_mult": 0.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear chronal wind accelerating target ally's turn"},
			"time_surge": {"name": "Time Surge", "range": 2, "dmg_mult": 0.00, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial temporal surge granting entire squad turn priority"}
		},
		"desc": "Accelerate local timeline to grant bonus speed and turn priority."
	},
	"Temporal_Decay": {
		"name": "Temporal Decay", "element": "time",
		"damage": 42, "mp_cost": 22, "range": 4, "accuracy": 92,
		"effect": "decay", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"entropic_touch": {"name": "Entropic Touch", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.85, "shape": "cardinal", "desc": "Touch accelerating age in target cells for massive initial burst"},
			"withering_ray": {"name": "Withering Ray", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear entropic beam inflicting decaying damage over 3 turns"},
			"entropy_miasma": {"name": "Entropy Miasma", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial entropic field deteriorating armor of all nearby foes"}
		},
		"desc": "Accelerate entropy within the target's physical matrix, dealing cascading damage."
	},
	"Chrono_Stasis": {
		"name": "Chrono Stasis", "element": "time",
		"damage": 70, "mp_cost": 50, "range": 3, "accuracy": 95,
		"effect": "stasis", "tier": "pinnacle", "falloff_per_tile": 0.02,
		"forms": {
			"stasis_lock": {"name": "Stasis Lock", "range": 2, "dmg_mult": 1.10, "mp_mult": 0.90, "shape": "cardinal", "desc": "Completely freeze single enemy in temporal crystallisation for 1 round"},
			"stasis_javelin": {"name": "Stasis Javelin", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear projectile freezing the first unit struck in suspended time"},
			"chronal_freeze": {"name": "Chronal Freeze", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial stasis wave immobilizing all surrounding combatants"}
		},
		"desc": "Halt time entirely in a localized pocket, freezing the target for one round."
	},

	# ── COMBINATION DISCIPLINES ───────────────────────────────────────────────
	# Steam (Fire + Water)
	"Steam_Vent": {
		"name": "Steam Vent", "element": "steam",
		"damage": 28, "mp_cost": 10, "range": 2, "accuracy": 94,
		"effect": "burn", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"scald_jet": {"name": "Scald Jet", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Direct boiling water jet blistering target armor"},
			"steam_lance": {"name": "Steam Lance", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear high-pressure steam blast penetrating cover"},
			"vapor_blanket": {"name": "Vapor Blanket", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial boiling vapor fog obscuring vision and burning enemies"}
		},
		"desc": "Release a jet of boiling vapor that scorches skin and obscures vision."
	},
	"Superheated_Scald": {
		"name": "Superheated Scald", "element": "steam",
		"damage": 46, "mp_cost": 20, "range": 3, "accuracy": 90,
		"effect": "scald", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"pressure_pierce": {"name": "Pressure Pierce", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "High pressure thermal spike melting physical defenses"},
			"scald_torrent": {"name": "Scald Torrent", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear flood of superheated water and vapor"},
			"thermal_haze": {"name": "Thermal Haze", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial cloud of scalding vapor burning all adjacent squares"}
		},
		"desc": "Project pressurized steam that melts physical defenses and burns flesh."
	},
	"Superheated_Steam": {
		"name": "Superheated Steam", "element": "steam",
		"damage": 68, "mp_cost": 36, "range": 4, "accuracy": 92,
		"effect": "scald_fog", "tier": "mastery", "falloff_per_tile": 0.04,
		"forms": {
			"flash_boiler": {"name": "Flash Boiler", "range": 2, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Concentrated boiling explosion detonating on target"},
			"whiteout_lance": {"name": "Whiteout Lance", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear incandescent steam blast stripping enemy vision"},
			"steamboil_cyclone": {"name": "Steamboil Cyclone", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial thermal tempest blinding LOS and inflicting burn"}
		},
		"desc": "Thermal boiling vapor blankets the grid. Blinds line-of-sight and inflicts scalding."
	},

	# Magma (Fire + Earth)
	"Molten_Shard": {
		"name": "Molten Shard", "element": "magma",
		"damage": 32, "mp_cost": 12, "range": 2, "accuracy": 92,
		"effect": "burn", "tier": "basic", "falloff_per_tile": 0.08,
		"forms": {
			"obsidian_dart": {"name": "Obsidian Dart", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Jagged molten glass shard piercing target for bleed and burn"},
			"magma_slug": {"name": "Magma Slug", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear projectile of molten lava leaving flaming puddles"},
			"slag_spray": {"name": "Slag Spray", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial splash of liquid obsidian shrapnel"}
		},
		"desc": "Hurl jagged superheated obsidian coated in molten slag."
	},
	"Lava_Torrent": {
		"name": "Lava Torrent", "element": "magma",
		"damage": 52, "mp_cost": 22, "range": 3, "accuracy": 88,
		"effect": "melt", "tier": "advanced", "falloff_per_tile": 0.08,
		"forms": {
			"magma_whip": {"name": "Magma Whip", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Coiled stream of lava lashing out and melting armor"},
			"volcanic_flume": {"name": "Volcanic Flume", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear river of molten magma destroying obstacles"},
			"caldera_eruption": {"name": "Caldera Eruption", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial upward geyser of boiling magma"}
		},
		"desc": "Unleash a river of liquid magma that destroys barriers and melts physical armor."
	},
	"Magma_Surge": {
		"name": "Magma Surge", "element": "magma",
		"damage": 74, "mp_cost": 38, "range": 3, "accuracy": 90,
		"effect": "lava_tiles", "tier": "mastery", "falloff_per_tile": 0.05,
		"forms": {
			"crater_fist": {"name": "Crater Fist", "range": 1, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Massive molten boulder strike creating a volcanic crater"},
			"pyroclastic_spear": {"name": "Pyroclastic Spear", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear projectile of solidified igneous lava"},
			"tectonic_meltdown": {"name": "Tectonic Meltdown", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial ground liquefaction converting tiles into magma"}
		},
		"desc": "Liquefies stone into creeping molten tiles across the combat grid."
	},

	# Plasma (Fire + Air)
	"Arc_Flash": {
		"name": "Arc Flash", "element": "plasma",
		"damage": 28, "mp_cost": 12, "range": 3, "accuracy": 94,
		"effect": "stun", "tier": "basic", "falloff_per_tile": 0.07,
		"forms": {
			"spark_needle": {"name": "Spark Needle", "range": 3, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Pinpoint electrical ionization shocking nerves"},
			"ionized_beam": {"name": "Ionized Beam", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear lightning channel searing through straight paths"},
			"static_discharge": {"name": "Static Discharge", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial ionizing wave stunning nearby foes"}
		},
		"desc": "Blinding atmospheric ionization that disrupts neural pathways."
	},
	"Ion_Shock": {
		"name": "Ion Shock", "element": "plasma",
		"damage": 50, "mp_cost": 24, "range": 4, "accuracy": 90,
		"effect": "shock", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"overload_touch": {"name": "Overload Touch", "range": 1, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Touch-range thermal ion discharge with stun"},
			"chain_surge": {"name": "Chain Surge", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear charged bolt chaining between wet/metal targets"},
			"ion_tempest": {"name": "Ion Tempest", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial ionization storm scrambling enemy actions"}
		},
		"desc": "Supercharged ionized bolt that chains to adjacent metallic or wet targets."
	},
	"Plasma_Conflagration": {
		"name": "Plasma Conflagration", "element": "plasma",
		"damage": 75, "mp_cost": 40, "range": 3, "accuracy": 92,
		"effect": "plasma_blast", "tier": "mastery", "falloff_per_tile": 0.05,
		"forms": {
			"solar_flare": {"name": "Solar Flare", "range": 2, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Blinding flash of fourth-state matter vaporizing defenses"},
			"plasma_corridor": {"name": "Plasma Corridor", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear superheated plasma tunnel leaving scorched tiles"},
			"supernova_burst": {"name": "Supernova Burst", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial thermo-plasma explosion destroying barriers"}
		},
		"desc": "Oxygen-supercharged inferno with heavy explosive shockwaves."
	},

	# Quicksand (Water + Earth)
	"Mud_Mire": {
		"name": "Mud Mire", "element": "quicksand",
		"damage": 22, "mp_cost": 10, "range": 2, "accuracy": 95,
		"effect": "slow", "tier": "basic", "falloff_per_tile": 0.05,
		"forms": {
			"sludge_strike": {"name": "Sludge Strike", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Heavy clump of dense soil slowing target footing"},
			"mud_jet": {"name": "Mud Jet", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear pressurized mud stream pushing targets"},
			"mire_puddle": {"name": "Mire Puddle", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial muddy sludge zone halving enemy move speed"}
		},
		"desc": "Churn soil into a thick viscous mud that hampers enemy strides."
	},
	"Bog_Sink": {
		"name": "Bog Sink", "element": "quicksand",
		"damage": 40, "mp_cost": 20, "range": 3, "accuracy": 90,
		"effect": "root", "tier": "advanced", "falloff_per_tile": 0.07,
		"forms": {
			"sinkhole_clutch": {"name": "Sinkhole Clutch", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Trap enemy feet into rapidly liquefying soil, rooting them"},
			"bog_trench": {"name": "Bog Trench", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear swamp fissure sinking line of units"},
			"swamp_quagmire": {"name": "Swamp Quagmire", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial bog mire immobilizing all adjacent units"}
		},
		"desc": "Submerge the target's footing in liquefying mud, rooting them in place."
	},
	"Quicksand_Mire": {
		"name": "Quicksand Mire", "element": "quicksand",
		"damage": 62, "mp_cost": 35, "range": 4, "accuracy": 88,
		"effect": "mire", "tier": "mastery", "falloff_per_tile": 0.05,
		"forms": {
			"quicksand_funnel": {"name": "Quicksand Funnel", "range": 3, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Vortex of liquefying silt swallowing enemy stance"},
			"silt_torrent": {"name": "Silt Torrent", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear river of heavy silt dragging targets backward"},
			"abyssal_sinkhole": {"name": "Abyssal Sinkhole", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial quicksand collapse reducing speed to 1"}
		},
		"desc": "Saturates ground into thick mud, reducing enemy speed to 1 and tripling sprint costs."
	},

	# Blizzard (Water + Air)
	"Flurry_Frost": {
		"name": "Flurry Frost", "element": "blizzard",
		"damage": 26, "mp_cost": 10, "range": 3, "accuracy": 94,
		"effect": "slow", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"ice_needle": {"name": "Ice Needle", "range": 3, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Whirling frost dart chilling target reflexes"},
			"subzero_gust": {"name": "Subzero Gust", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear freezing wind coating ground in frost"},
			"frost_hail": {"name": "Frost Hail", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial burst of crystalline ice needles"}
		},
		"desc": "Summon a whirling burst of sub-zero ice needles."
	},
	"Chill_Squall": {
		"name": "Chill Squall", "element": "blizzard",
		"damage": 46, "mp_cost": 22, "range": 3, "accuracy": 90,
		"effect": "freeze", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"rime_spear": {"name": "Rime Spear", "range": 3, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Piercing gale projectile encasing wet foes in ice"},
			"freezing_line": {"name": "Freezing Line", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear subzero vortex causing deep freeze"},
			"cryo_cyclone": {"name": "Cryo Cyclone", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial blizzard whirlwind freezing surrounding air"}
		},
		"desc": "Freezing gale that encases damp combatants in crystalline frost."
	},
	"Glacial_Blizzard": {
		"name": "Glacial Blizzard", "element": "blizzard",
		"damage": 70, "mp_cost": 38, "range": 4, "accuracy": 90,
		"effect": "freeze_slick", "tier": "mastery", "falloff_per_tile": 0.04,
		"forms": {
			"glacier_impact": {"name": "Glacier Impact", "range": 2, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Crushing continental ice block slam"},
			"whiteout_stream": {"name": "Whiteout Stream", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear blizzard beam turning water into ice slicks"},
			"permafrost_howl": {"name": "Permafrost Howl", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial arctic tempest covering 5x5 zone in slick ice"}
		},
		"desc": "Freezes water puddles into ice slicks causing moving units to slide uncontrollably."
	},

	# Dust Devil (Earth + Air)
	"Grit_Swirl": {
		"name": "Grit Swirl", "element": "dust_devil",
		"damage": 24, "mp_cost": 10, "range": 3, "accuracy": 92,
		"effect": "blind", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"sand_pebble": {"name": "Sand Pebble", "range": 3, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "High velocity grit particle blinding target"},
			"grit_jet": {"name": "Grit Jet", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear stream of pressurized abrasive sand"},
			"dust_vortex": {"name": "Dust Vortex", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial dust squall reducing adjacent enemies' accuracy"}
		},
		"desc": "Abrasive mini-vortex that kicks grit into the opponent's eyes."
	},
	"Abrasive_Grit": {
		"name": "Abrasive Grit", "element": "dust_devil",
		"damage": 44, "mp_cost": 20, "range": 3, "accuracy": 90,
		"effect": "disrupt", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"sandblaster": {"name": "Sandblaster", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Weaponized atmospheric sandblast stripping armor"},
			"corrosive_sandline": {"name": "Corrosive Sandline", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear abrasive funnel lacerating target defense"},
			"grit_haboob": {"name": "Grit Haboob", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial mineral storm disrupting enemy concentration"}
		},
		"desc": "Weaponized atmospheric sandblasting that strips enemy accuracy."
	},
	"Dust_Devil_Sandstorm": {
		"name": "Dust Devil Sandstorm", "element": "dust_devil",
		"damage": 65, "mp_cost": 36, "range": 4, "accuracy": 88,
		"effect": "sandstorm", "tier": "mastery", "falloff_per_tile": 0.04,
		"forms": {
			"cyclone_twister": {"name": "Cyclone Twister", "range": 3, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Abrasive tornado lifting and disorienting target"},
			"sandstorm_corridor": {"name": "Sandstorm Corridor", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear cutting sandstorm tearing through line of sight"},
			"desert_typhoon": {"name": "Desert Typhoon", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial zone-wide sandstorm halving enemy Dexterity"}
		},
		"desc": "Whirls sharp abrasive mineral grit, halving enemy Dexterity across the zone."
	},

	# ── TRIPLE COMBINATION DISCIPLINES ────────────────────────────────────────
	# Hydrothermal Forge (Fire + Water + Earth)
	"Ore_Synthesis": {
		"name": "Ore Synthesis", "element": "fire_water_earth",
		"damage": 34, "mp_cost": 14, "range": 2, "accuracy": 92,
		"effect": "barrier", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"alloy_forge": {"name": "Alloy Forge", "range": 1, "dmg_mult": 1.20, "mp_mult": 0.85, "shape": "cardinal", "desc": "Strike with hyper-dense hydro-crystallized metal ore"},
			"mineral_spear": {"name": "Mineral Spear", "range": 3, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear pressurized volcanic mineral javelin"},
			"ore_bulwark": {"name": "Ore Bulwark", "range": 2, "dmg_mult": 0.00, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial metallic crystallization granting barriers to squad"}
		},
		"desc": "Synthesize hyper-dense metallic ores from hydrothermal volcanic mineral solutions."
	},
	"Acid_Dissolution": {
		"name": "Acid Dissolution", "element": "fire_water_earth",
		"damage": 54, "mp_cost": 24, "range": 3, "accuracy": 90,
		"effect": "corrode", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"vitriol_touch": {"name": "Vitriol Touch", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Boiling mineral acid touch melting poise and physical armor"},
			"acidic_geyser": {"name": "Acidic Geyser", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear boiling acidic geyser corroding everything in its path"},
			"chemical_deluge": {"name": "Chemical Deluge", "range": 2, "dmg_mult": 0.85, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial hydrothermal acid pool coating the surrounding area"}
		},
		"desc": "Superheated mineral acid stream that strips enemy poise and melts physical armor."
	},
	"Geothermal_Obsidian": {
		"name": "Geothermal Obsidian", "element": "fire_water_earth",
		"damage": 82, "mp_cost": 44, "range": 4, "accuracy": 90,
		"effect": "obsidian_bleed", "tier": "mastery", "falloff_per_tile": 0.05,
		"forms": {
			"obsidian_spike": {"name": "Obsidian Spike", "range": 2, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Massive black obsidian spire erupting beneath target"},
			"geothermal_trench": {"name": "Geothermal Trench", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear boiling fissure line lacerating enemies with razor obsidian"},
			"volcanic_field": {"name": "Volcanic Field", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial caldera explosion coating zone in bleeding obsidian shards"}
		},
		"desc": "Erupts boiling geysers and coats grid in razor obsidian shards that inflict heavy Bleed."
	},

	# Tempest Flame (Fire + Water + Air)
	"Hailfire": {
		"name": "Hailfire", "element": "fire_water_air",
		"damage": 32, "mp_cost": 14, "range": 3, "accuracy": 92,
		"effect": "slow", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"pyroclastic_ice": {"name": "Pyroclastic Ice", "range": 3, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Supercooled hail encased in chemical fire slowing and burning"},
			"hailfire_lance": {"name": "Hailfire Lance", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear stream of thermal hail penetrating defenses"},
			"storm_barrage": {"name": "Storm Barrage", "range": 3, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial tempest raining flaming ice across surrounding tiles"}
		},
		"desc": "Rain down supercooled hail coated in volatile chemical flames."
	},
	"Lightning_Storm": {
		"name": "Lightning Storm", "element": "fire_water_air",
		"damage": 52, "mp_cost": 24, "range": 4, "accuracy": 90,
		"effect": "shock", "tier": "advanced", "falloff_per_tile": 0.05,
		"forms": {
			"thunder_strike": {"name": "Thunder Strike", "range": 3, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Pointed atmospheric lightning bolt delivering high shock"},
			"chain_lightning_line": {"name": "Chain Lightning Line", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear convective lightning bolt piercing wet targets"},
			"tempest_discharge": {"name": "Tempest Discharge", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial convective squall shocking all targets in zone"}
		},
		"desc": "Charged convective squall discharging multi-target lightning strikes."
	},
	"Superheated_Cyclone": {
		"name": "Superheated Cyclone", "element": "fire_water_air",
		"damage": 80, "mp_cost": 42, "range": 4, "accuracy": 92,
		"effect": "vortex_drain", "tier": "mastery", "falloff_per_tile": 0.04,
		"forms": {
			"vortex_funnel": {"name": "Vortex Funnel", "range": 3, "dmg_mult": 1.25, "mp_mult": 0.90, "shape": "cardinal", "desc": "Boiling vacuum funnel pulling target in and burning stamina"},
			"thermal_hurricane": {"name": "Thermal Hurricane", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear superheated gale blowing enemies backward"},
			"boiling_typhoon": {"name": "Boiling Typhoon", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial vacuum hurricane boiling stamina gauges to zero"}
		},
		"desc": "Vacuum hurricane that pulls all enemies inward while boiling stamina gauges to zero."
	},

	# Pyroclastic Storm (Fire + Earth + Air)
	"Sulfur_Clouds": {
		"name": "Sulfur Clouds", "element": "fire_earth_air",
		"damage": 30, "mp_cost": 12, "range": 3, "accuracy": 94,
		"effect": "blind", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"toxic_suffocation": {"name": "Toxic Suffocation", "range": 2, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Noxious volcanic gas jet stripping target visibility"},
			"choking_corridor": {"name": "Choking Corridor", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear sulfur cloud corridor blinding all units"},
			"volcanic_fog": {"name": "Volcanic Fog", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial noxious vapor cloud burning eyes and lungs"}
		},
		"desc": "Deploy choking noxious volcanic gas that strips visibility and burns eyes."
	},
	"Ashfall_Blackout": {
		"name": "Ashfall Blackout", "element": "fire_earth_air",
		"damage": 50, "mp_cost": 22, "range": 3, "accuracy": 90,
		"effect": "disrupt", "tier": "advanced", "falloff_per_tile": 0.06,
		"forms": {
			"incandescent_cinder": {"name": "Incandescent Cinder", "range": 2, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Dense glowing ash ball staggering target stance"},
			"ash_stream": {"name": "Ash Stream", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear incandescent ash deluge cutting line-of-sight"},
			"blackout_plume": {"name": "Blackout Plume", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial dark volcanic ash snuffing sight across zone"}
		},
		"desc": "Dense incandescent ash deluge that obscures the arena and snuffs line-of-sight."
	},
	"Meteoric_Reentry": {
		"name": "Meteoric Re-Entry", "element": "fire_earth_air",
		"damage": 85, "mp_cost": 46, "range": 3, "accuracy": 88,
		"effect": "crater_impact", "tier": "mastery", "falloff_per_tile": 0.05,
		"forms": {
			"artillery_impact": {"name": "Artillery Impact", "range": 3, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Kinetic blazing meteorite slamming into single target"},
			"reentry_line": {"name": "Re-entry Line", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear flaming meteor strike pulverizing path"},
			"cataclysmic_crater": {"name": "Cataclysmic Crater", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial meteoric bombardment turning area into crater pits"}
		},
		"desc": "Propels blazing kinetic boulders like artillery shells. Obliterates cover into crater pits."
	},

	# Lifeweave (Water + Earth + Air)
	"Bog_Traps": {
		"name": "Bog Traps", "element": "water_earth_air",
		"damage": 26, "mp_cost": 12, "range": 3, "accuracy": 94,
		"effect": "root", "tier": "basic", "falloff_per_tile": 0.06,
		"forms": {
			"creeping_vine": {"name": "Creeping Vine", "range": 3, "dmg_mult": 1.15, "mp_mult": 0.85, "shape": "cardinal", "desc": "Organic wetland root grasping enemy ankles"},
			"marsh_snare_line": {"name": "Marsh Snare Line", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear bramble trench entrapping footwork"},
			"wetland_ambush": {"name": "Wetland Ambush", "range": 2, "dmg_mult": 0.80, "mp_mult": 1.25, "shape": "radial", "is_radial": true, "desc": "Radial tangle of organic wetland vines rooting all foes"}
		},
		"desc": "Seed organic wetland snares that entrap enemy footwork."
	},
	"Spore_Tempest": {
		"name": "Spore Tempest", "element": "water_earth_air",
		"damage": 48, "mp_cost": 22, "range": 4, "accuracy": 90,
		"effect": "confuse", "tier": "advanced", "falloff_per_tile": 0.05,
		"forms": {
			"toxic_spore_dart": {"name": "Toxic Spore Dart", "range": 3, "dmg_mult": 1.20, "mp_mult": 0.90, "shape": "cardinal", "desc": "Concentrated fungal spore dart confusing the target"},
			"spore_stream": {"name": "Spore Stream", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear airborne spore stream draining stamina"},
			"mycelial_bloom": {"name": "Mycelial Bloom", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.30, "shape": "radial", "is_radial": true, "desc": "Radial fungal squall disorienting all enemies"}
		},
		"desc": "Airborne fungal spore squall that disorients targets and drains stamina."
	},
	"Permafrost_Cryotectonic": {
		"name": "Permafrost Cryo-Tectonic", "element": "water_earth_air",
		"damage": 78, "mp_cost": 42, "range": 4, "accuracy": 92,
		"effect": "permafrost_tomb", "tier": "mastery", "falloff_per_tile": 0.04,
		"forms": {
			"continental_spike": {"name": "Continental Spike", "range": 2, "dmg_mult": 1.30, "mp_mult": 0.90, "shape": "cardinal", "desc": "Continental tectonic glacier impaling target"},
			"permafrost_ridge": {"name": "Permafrost Ridge", "range": 4, "dmg_mult": 1.00, "mp_mult": 1.00, "shape": "linear_front", "desc": "Linear impassable glacier wall locking down row"},
			"glacial_tomb": {"name": "Glacial Tomb", "range": 3, "dmg_mult": 0.85, "mp_mult": 1.35, "shape": "radial", "is_radial": true, "desc": "Radial cryogenic tectonic catastrophe freezing all wet targets solid"}
		},
		"desc": "Erects impassable continental glaciers. Traps wet targets solid in ice blocks."
	}
}

# ──────────────────────────────────────────────
#  ELEMENT DEFINITIONS
#  skill_pool: list of ability keys available for this element
# ──────────────────────────────────────────────

const ELEMENTS = {
	"fire": {
		"display_name": "Fire",
		"badge": "Energy",
		"color": Color(1.0, 0.3, 0.1, 1.0),
		"base_speed": 3,
		"base_agility": 28,
		"base_dexterity": 32,
		"base_hp": 90,
		"base_mp": 100,
		"base_stamina": 100,
		"weakness": ["water", "air"],
		"skill_pool": [
			"Combustion", "Lightning", "Laser", "Plasma",
			"Thermal_Radiation", "Nuclear_Ignition", "Photonic_Burst",
			"Destruction"   # pinnacle
		]
	},
	"water": {
		"display_name": "Water",
		"badge": "Flow",
		"color": Color(0.2, 0.5, 1.0, 1.0),
		"base_speed": 2,
		"base_agility": 24,
		"base_dexterity": 26,
		"base_hp": 110,
		"base_mp": 120,
		"base_stamina": 95,
		"weakness": ["earth", "fire"],
		"skill_pool": [
			"Aqua_Mend", "Ice", "Blood", "Acid_Rain", "Pressure_Wave",
			"Tide_Pull", "Mist_Fog", "Purification",
			"Rejuvenation"  # pinnacle
		]
	},
	"earth": {
		"display_name": "Earth",
		"badge": "Mass",
		"color": Color(0.6, 0.4, 0.15, 1.0),
		"base_speed": 2,
		"base_agility": 16,
		"base_dexterity": 24,
		"base_hp": 130,
		"base_mp": 90,
		"base_stamina": 120,
		"weakness": ["air", "water"],
		"skill_pool": [
			"Stone_Plating", "Metal", "Sand", "Crystal", "Magnetism",
			"Petrification", "Tectonic", "Density_Shift",
			"Gravity"       # pinnacle
		]
	},
	"air": {
		"display_name": "Air",
		"badge": "Wave",
		"color": Color(0.7, 0.9, 1.0, 1.0),
		"base_speed": 4,
		"base_agility": 38,
		"base_dexterity": 28,
		"base_hp": 80,
		"base_mp": 110,
		"base_stamina": 105,
		"weakness": ["earth", "fire"],
		"skill_pool": [
			"Gale_Step", "Wind", "Sound_Sonic", "Nitrogen", "Oxygen",
			"Vacuum", "Pressure_Control", "Scent_Pheromone",
			"Space"         # pinnacle
		]
	},
	"zero": {
		"display_name": "Zero",
		"badge": "Null Void",
		"color": Color(0.75, 0.25, 0.85, 1.0),
		"base_speed": 4,
		"base_agility": 35,
		"base_dexterity": 35,
		"base_hp": 120,
		"base_mp": 140,
		"base_stamina": 120,
		"weakness": [],
		"skill_pool": [
			"Destruction", "Gravity", "Space", "Rejuvenation"
		]
	}
}

# ──────────────────────────────────────────────
#  FUSION REGISTRY (Double, Triple, Quadruple)
# ──────────────────────────────────────────────

const FUSIONS = {
	# ── Double Fusions (2 Elements) ──
	"Steam_Vapor": {
		"name": "Superheated Steam",
		"elements": ["fire", "water"],
		"tier": "double",
		"effect": "scald_fog",
		"desc": "Thermal boiling vapor blankets the grid. Blinds line-of-sight and burns entering units."
	},
	"Magma_Surge": {
		"name": "Magma Surge",
		"elements": ["fire", "earth"],
		"tier": "double",
		"effect": "lava_tiles",
		"desc": "Liquefies stone into creeping molten tiles. Destroys barriers and melts physical armor."
	},
	"Plasma_Storm": {
		"name": "Plasma Conflagration",
		"elements": ["fire", "air"],
		"tier": "double",
		"effect": "plasma_blast",
		"desc": "Oxygen-supercharged inferno. High-velocity explosive shockwave with heavy knockback."
	},
	"Quicksand_Sludge": {
		"name": "Quicksand Mire",
		"elements": ["water", "earth"],
		"tier": "double",
		"effect": "mire",
		"desc": "Saturates ground into thick mud. Reduces enemy speed to 1 and triples stamina sprint cost."
	},
	"Blizzard_Freeze": {
		"name": "Glacial Blizzard",
		"elements": ["water", "air"],
		"tier": "double",
		"effect": "freeze_slick",
		"desc": "Freezes water puddles into ice slicks. Moving units slide uncontrollably and lose cast speed."
	},
	"Dust_Devil": {
		"name": "Dust Devil Sandstorm",
		"elements": ["earth", "air"],
		"tier": "double",
		"effect": "sandstorm",
		"desc": "Whirls sharp abrasive mineral grit. Reduces enemy Dexterity by 50% across half the board."
	},

	# ── Triple Fusions (3 Elements) ──
	"Geothermal_Obsidian": {
		"name": "Geothermal Obsidian",
		"elements": ["fire", "water", "earth"],
		"tier": "triple",
		"effect": "obsidian_bleed",
		"desc": "Erupts boiling geysers and coats grid in razor obsidian shards that inflict heavy Bleed."
	},
	"Superheated_Cyclone": {
		"name": "Superheated Cyclone",
		"elements": ["fire", "water", "air"],
		"tier": "triple",
		"effect": "vortex_drain",
		"desc": "Vacuum hurricane that pulls all enemies inward while boiling stamina gauges to zero."
	},
	"Meteoric_Reentry": {
		"name": "Meteoric Re-Entry",
		"elements": ["fire", "earth", "air"],
		"tier": "triple",
		"effect": "crater_impact",
		"desc": "Propels blazing kinetic boulders like artillery shells. Obliterates cover into crater pits."
	},
	"Permafrost_Cryotectonic": {
		"name": "Permafrost Cryo-Tectonic",
		"elements": ["water", "earth", "air"],
		"tier": "triple",
		"effect": "permafrost_tomb",
		"desc": "Erects impassable continental glaciers. Traps wet targets solid in ice blocks for 1 turn."
	},

	# ── Quadruple Fusion: Space & Time (Cosmic Singularity) ──
	"Chrono_Spatial_Singularity": {
		"name": "Chrono-Spatial Singularity",
		"elements": ["fire", "water", "earth", "air"],
		"tier": "quadruple",
		"effect": "spacetime",
		"desc": "All 4 primordial elements resonate to warp reality. Grants Temporal Rewind, Spatial Fold wormholes, and Dimensional Horizons."
	},
	"Zero_Null_Void": {
		"name": "Zero: Null Void",
		"elements": ["zero"],
		"tier": "counter_pinnacle",
		"effect": "entropy_nullification",
		"desc": "Anti-elemental void that unravels Space and Time fusions, forcing combatants into raw physical stamina brawls."
	}
}

# ──────────────────────────────────────────────
#  DISCIPLINE REGISTRY (Celestial Mandala Nodes)
# ──────────────────────────────────────────────

const DISCIPLINES = {
	# Primordial Core Center
	"space": {
		"key": "space",
		"display_name": "Space",
		"category": "primordial",
		"color": Color(0.48, 0.28, 0.88),
		"accent": Color(0.70, 0.45, 1.0),
		"required_elements": [],
		"badge": "Void",
		"desc": "Foundational manipulation of dimensional coordinates, metrics, and spatial horizons."
	},
	"time": {
		"key": "time",
		"display_name": "Time",
		"category": "primordial",
		"color": Color(0.88, 0.72, 0.22),
		"accent": Color(1.0, 0.85, 0.40),
		"required_elements": [],
		"badge": "Chrono",
		"desc": "Foundational manipulation of temporal flow, entropy, dilation, and timeline acceleration."
	},

	# Inner Ring: 4 Core Elements
	"fire": {
		"key": "fire",
		"display_name": "Fire",
		"category": "core",
		"color": Color(0.95, 0.32, 0.18),
		"accent": Color(1.0, 0.55, 0.25),
		"required_elements": [],
		"badge": "Energy",
		"desc": "Primordial thermodynamic combustion, photonic energy, and lightning plasma."
	},
	"earth": {
		"key": "earth",
		"display_name": "Earth",
		"category": "core",
		"color": Color(0.65, 0.45, 0.20),
		"accent": Color(0.85, 0.65, 0.30),
		"required_elements": [],
		"badge": "Mass",
		"desc": "Primordial mineral fortification, metallurgy, granular dynamics, and gravimetric density."
	},
	"water": {
		"key": "water",
		"display_name": "Water",
		"category": "core",
		"color": Color(0.20, 0.55, 0.95),
		"accent": Color(0.40, 0.75, 1.0),
		"required_elements": [],
		"badge": "Flow",
		"desc": "Primordial cellular hydration, cryogenic solidification, hydro-kinetics, and restorative flow."
	},
	"air": {
		"key": "air",
		"display_name": "Air",
		"category": "core",
		"color": Color(0.25, 0.80, 0.75),
		"accent": Color(0.50, 0.95, 0.90),
		"required_elements": [],
		"badge": "Wave",
		"desc": "Primordial atmospheric currents, kinetic acoustics, gas barometrics, and evasion."
	},

	# Middle Ring: 6 Double Combination Disciplines
	"fire_earth": {
		"key": "fire_earth",
		"display_name": "Fire + Earth",
		"category": "combination",
		"color": Color(0.96, 0.48, 0.15),
		"accent": Color(1.0, 0.65, 0.25),
		"required_elements": ["fire", "earth"],
		"badge": "Molten",
		"desc": "Liquefied superheated stone that burns terrain, melts armor, and devastates barriers."
	},
	"fire_water": {
		"key": "fire_water",
		"display_name": "Fire + Water",
		"category": "combination",
		"color": Color(0.72, 0.50, 0.85),
		"accent": Color(0.88, 0.65, 0.95),
		"required_elements": ["fire", "water"],
		"badge": "Vapor",
		"desc": "Thermal boiling vapor that blankets combat zones, obscures sightlines, and scalds flesh."
	},
	"fire_air": {
		"key": "fire_air",
		"display_name": "Fire + Air",
		"category": "combination",
		"color": Color(0.92, 0.40, 0.85),
		"accent": Color(1.0, 0.60, 0.95),
		"required_elements": ["fire", "air"],
		"badge": "Ion",
		"desc": "Oxygen-supercharged ionized inferno producing explosive shockwaves and neural overload."
	},
	"water_earth": {
		"key": "water_earth",
		"display_name": "Water + Earth",
		"category": "combination",
		"color": Color(0.58, 0.62, 0.32),
		"accent": Color(0.78, 0.82, 0.48),
		"required_elements": ["water", "earth"],
		"badge": "Mire",
		"desc": "Saturated muddy terrain that entraps enemy mobility, roots targets, and saps stamina."
	},
	"water_air": {
		"key": "water_air",
		"display_name": "Water + Air",
		"category": "combination",
		"color": Color(0.40, 0.78, 0.96),
		"accent": Color(0.65, 0.92, 1.0),
		"required_elements": ["water", "air"],
		"badge": "Glacial",
		"desc": "Sub-zero convective tempests that coat the battlefield in slick frost and immobilize."
	},
	"earth_air": {
		"key": "earth_air",
		"display_name": "Earth + Air",
		"category": "combination",
		"color": Color(0.80, 0.72, 0.45),
		"accent": Color(0.94, 0.85, 0.55),
		"required_elements": ["earth", "air"],
		"badge": "Sandstorm",
		"desc": "Violent abrasive sand vortex that strips enemy accuracy, dexterity, and visibility."
	},

	# Outermost Ring: 4 Triple Combination Disciplines
	"fire_water_earth": {
		"key": "fire_water_earth",
		"display_name": "Fire + Water + Earth",
		"category": "triple",
		"color": Color(0.85, 0.48, 0.28),
		"accent": Color(1.0, 0.68, 0.42),
		"required_elements": ["fire", "water", "earth"],
		"badge": "Forge",
		"desc": "Hydrothermal ore synthesis and molten obsidian shards that inflict heavy bleeding."
	},
	"fire_water_air": {
		"key": "fire_water_air",
		"display_name": "Fire + Water + Air",
		"category": "triple",
		"color": Color(0.55, 0.68, 0.95),
		"accent": Color(0.75, 0.85, 1.0),
		"required_elements": ["fire", "water", "air"],
		"badge": "Tempest",
		"desc": "Charged steam hurricanes and superheated cyclonic vortices that boil enemy stamina."
	},
	"fire_earth_air": {
		"key": "fire_earth_air",
		"display_name": "Fire + Earth + Air",
		"category": "triple",
		"color": Color(0.92, 0.58, 0.32),
		"accent": Color(1.0, 0.75, 0.48),
		"required_elements": ["fire", "earth", "air"],
		"badge": "Pyroclastic",
		"desc": "Incandescent ashfall blackouts and meteoric re-entry artillery bombardment."
	},
	"water_earth_air": {
		"key": "water_earth_air",
		"display_name": "Water + Earth + Air",
		"category": "triple",
		"color": Color(0.38, 0.78, 0.65),
		"accent": Color(0.60, 0.95, 0.82),
		"required_elements": ["water", "earth", "air"],
		"badge": "Lifeweave",
		"desc": "Organic spore tempests and continental permafrost glaciers that freeze targets solid."
	}
}

const DISCIPLINE_ALIASES = {
	"steam": "fire_water",
	"magma": "fire_earth",
	"plasma": "fire_air",
	"quicksand": "water_earth",
	"blizzard": "water_air",
	"dust_devil": "earth_air",
	"hydrothermal_forge": "fire_water_earth",
	"tempest_flame": "fire_water_air",
	"pyroclastic_storm": "fire_earth_air",
	"lifeweave": "water_earth_air",
}

# ──────────────────────────────────────────────
#  SKILL TREE DIRECTED GRAPHS
#  Node schema:
#    key, display_name, discipline, tier, prerequisites: [],
#    level_req, sp_cost, branch_index, branch_tier, branch_angle, desc, ability_key
# ──────────────────────────────────────────────

const SKILL_TREES = {
	"space": [
		{
			"key": "Spatial_Shift", "display_name": "Spatial Shift", "discipline": "space", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 180.0,
			"desc": "Starter dimensional stride. Displace coordinates instantly across the field.",
			"ability_key": "Spatial_Shift"
		},
		{
			"key": "Spatial_Compression", "display_name": "Spatial Compression", "discipline": "space", "tier": "advanced",
			"prerequisites": ["Spatial_Shift"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 150.0,
			"desc": "Crush dimensional volume, pulling surrounding targets toward a singularity.",
			"ability_key": "Spatial_Compression"
		},
		{
			"key": "Spatial_Barrier", "display_name": "Spatial Barrier", "discipline": "space", "tier": "advanced",
			"prerequisites": ["Spatial_Shift"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": 210.0,
			"desc": "Curvature event horizon that refracts and deflects incoming projectile attacks.",
			"ability_key": "Spatial_Barrier"
		},
		{
			"key": "Space", "display_name": "Macro Void (Space)", "discipline": "space", "tier": "pinnacle",
			"prerequisites": ["Spatial_Compression", "Spatial_Barrier"], "level_req": 25, "sp_cost": 2,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 180.0,
			"desc": "Mastery convergence. Extend control to the macro void for massive zone denial.",
			"ability_key": "Space"
		}
	],

	"time": [
		{
			"key": "Time_Dilation", "display_name": "Time Dilation", "discipline": "time", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 0.0,
			"desc": "Starter temporal flux. Dilate enemy movement speed and reaction flow.",
			"ability_key": "Time_Dilation"
		},
		{
			"key": "Chrono_Acceleration", "display_name": "Chrono Acceleration", "discipline": "time", "tier": "advanced",
			"prerequisites": ["Time_Dilation"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -30.0,
			"desc": "Accelerate local timeline to grant bonus turn speed and tactical priority.",
			"ability_key": "Chrono_Acceleration"
		},
		{
			"key": "Temporal_Decay", "display_name": "Temporal Decay", "discipline": "time", "tier": "advanced",
			"prerequisites": ["Time_Dilation"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": 30.0,
			"desc": "Accelerate physical entropy within the target, inflicting cascading damage.",
			"ability_key": "Temporal_Decay"
		},
		{
			"key": "Chrono_Stasis", "display_name": "Chrono Stasis", "discipline": "time", "tier": "pinnacle",
			"prerequisites": ["Chrono_Acceleration", "Temporal_Decay"], "level_req": 25, "sp_cost": 2,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 0.0,
			"desc": "Mastery convergence. Halt time entirely in a localized pocket, freezing target.",
			"ability_key": "Chrono_Stasis"
		}
	],

	"fire": [
		# Branch 0: Combustion & Heat Specialization
		{
			"key": "Combustion", "display_name": "Combustion", "discipline": "fire", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -140.0,
			"desc": "Starter thermodynamic blast. Ignites chemical fire and inflicts Burn (DoT).",
			"ability_key": "Combustion"
		},
		{
			"key": "Thermal_Radiation", "display_name": "Thermal Radiation", "discipline": "fire", "tier": "advanced",
			"prerequisites": ["Combustion"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -150.0,
			"desc": "Emit intense infrared heat across a wide perimeter without open flame.",
			"ability_key": "Thermal_Radiation"
		},
		{
			"key": "Nuclear_Ignition", "display_name": "Nuclear Ignition", "discipline": "fire", "tier": "mastery",
			"prerequisites": ["Thermal_Radiation"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -145.0,
			"desc": "Trigger microscopic fission and fusion reactions for devastating area damage.",
			"ability_key": "Nuclear_Ignition"
		},

		# Branch 1: Lightning & Discharge Specialization
		{
			"key": "Lightning", "display_name": "Lightning", "discipline": "fire", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 1, "branch_angle": -90.0,
			"desc": "Starter electrical surge. Fast, high-voltage arc with a chance to Stun.",
			"ability_key": "Lightning"
		},
		{
			"key": "Photonic_Burst", "display_name": "Photonic Burst", "discipline": "fire", "tier": "advanced",
			"prerequisites": ["Lightning"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": -90.0,
			"desc": "Explosive discharge of pure light energy in all directions, blinding targets.",
			"ability_key": "Photonic_Burst"
		},
		{
			"key": "Destruction", "display_name": "Destruction", "discipline": "fire", "tier": "pinnacle",
			"prerequisites": ["Photonic_Burst"], "level_req": 25, "sp_cost": 2,
			"branch_index": 1, "branch_tier": 3, "branch_angle": -90.0,
			"desc": "Pinnacle entropy acceleration. Target ceases to hold molecular cohesion.",
			"ability_key": "Destruction"
		},

		# Branch 2: Laser & Photonics Specialization
		{
			"key": "Laser", "display_name": "Laser", "discipline": "fire", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 1, "branch_angle": -40.0,
			"desc": "Starter photonic beam. Focused precision laser with pinpoint range.",
			"ability_key": "Laser"
		},
		{
			"key": "Plasma", "display_name": "Plasma", "discipline": "fire", "tier": "advanced",
			"prerequisites": ["Laser"], "level_req": 6, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 2, "branch_angle": -30.0,
			"desc": "Ionize matter into its fourth state, reducing armor and burning targets.",
			"ability_key": "Plasma"
		}
	],

	"water": [
		# Branch 0: Restoration & Purification
		{
			"key": "Aqua_Mend", "display_name": "Aqua Mend", "discipline": "water", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 140.0,
			"desc": "Starter cellular hydration and biological repair. Restores HP to an ally.",
			"ability_key": "Aqua_Mend"
		},
		{
			"key": "Purification", "display_name": "Purification", "discipline": "water", "tier": "advanced",
			"prerequisites": ["Aqua_Mend"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 150.0,
			"desc": "Strip harmful conditions and cleanse status debuffs from active teammates.",
			"ability_key": "Purification"
		},
		{
			"key": "Rejuvenation", "display_name": "Rejuvenation", "discipline": "water", "tier": "pinnacle",
			"prerequisites": ["Purification"], "level_req": 25, "sp_cost": 2,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 145.0,
			"desc": "Pinnacle restoration. Accelerate cellular repair and reverse deep trauma.",
			"ability_key": "Rejuvenation"
		},

		# Branch 1: Cryo Solidification & Blood Control
		{
			"key": "Ice", "display_name": "Ice", "discipline": "water", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 1, "branch_angle": 90.0,
			"desc": "Starter cryogenic crystallization. Freeze moisture and apply Slow on hit.",
			"ability_key": "Ice"
		},
		{
			"key": "Acid_Rain", "display_name": "Acid Rain", "discipline": "water", "tier": "advanced",
			"prerequisites": ["Ice"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": 90.0,
			"desc": "Alter water pH to corrosive extremes mid-flight, corroding enemy armor.",
			"ability_key": "Acid_Rain"
		},
		{
			"key": "Blood", "display_name": "Blood Manipulation", "discipline": "water", "tier": "mastery",
			"prerequisites": ["Acid_Rain"], "level_req": 15, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 3, "branch_angle": 90.0,
			"desc": "Mastery haemokinesis. Control iron-rich fluids within living bodies.",
			"ability_key": "Blood"
		},

		# Branch 2: Hydro-Kinetics & Tidal Vortex
		{
			"key": "Pressure_Wave", "display_name": "Pressure Wave", "discipline": "water", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 1, "branch_angle": 40.0,
			"desc": "Starter hydro-kinetic shockwave. Compress water to push enemies back.",
			"ability_key": "Pressure_Wave"
		},
		{
			"key": "Tide_Pull", "display_name": "Tide Pull", "discipline": "water", "tier": "advanced",
			"prerequisites": ["Pressure_Wave"], "level_req": 6, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 2, "branch_angle": 30.0,
			"desc": "Gravitational tidal draw that drags opponents closer across the platform.",
			"ability_key": "Tide_Pull"
		},
		{
			"key": "Mist_Fog", "display_name": "Mist / Fog", "discipline": "water", "tier": "mastery",
			"prerequisites": ["Tide_Pull"], "level_req": 15, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 3, "branch_angle": 35.0,
			"desc": "Disperse microscopic moisture droplets for heavy area concealment.",
			"ability_key": "Mist_Fog"
		}
	],

	"earth": [
		# Branch 0: Fortification & Crystal Lattice
		{
			"key": "Stone_Plating", "display_name": "Stone Plating", "discipline": "earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -45.0,
			"desc": "Starter mineral bulwark. Fortifies posture and forms shielding barriers.",
			"ability_key": "Stone_Plating"
		},
		{
			"key": "Crystal", "display_name": "Crystal", "discipline": "earth", "tier": "advanced",
			"prerequisites": ["Stone_Plating"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -40.0,
			"desc": "Grow sharp mineral lattices that absorb impacts and retaliate with shards.",
			"ability_key": "Crystal"
		},
		{
			"key": "Gravity", "display_name": "Gravity", "discipline": "earth", "tier": "pinnacle",
			"prerequisites": ["Crystal"], "level_req": 25, "sp_cost": 2,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -40.0,
			"desc": "Pinnacle gravitational field distortion. Complete mobility lockdown.",
			"ability_key": "Gravity"
		},

		# Branch 1: Ferrous Metallurgy & Magnetism
		{
			"key": "Metal", "display_name": "Metal", "discipline": "earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 1, "branch_angle": 0.0,
			"desc": "Starter ferrous manipulation. Strike with heavy forged metallic density.",
			"ability_key": "Metal"
		},
		{
			"key": "Magnetism", "display_name": "Magnetism", "discipline": "earth", "tier": "advanced",
			"prerequisites": ["Metal"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": 0.0,
			"desc": "Exert polar attraction and repulsion upon metallic equipment at range.",
			"ability_key": "Magnetism"
		},
		{
			"key": "Density_Shift", "display_name": "Density Shift", "discipline": "earth", "tier": "mastery",
			"prerequisites": ["Magnetism"], "level_req": 15, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 3, "branch_angle": 0.0,
			"desc": "Compress physical atomic lattices to achieve immovable defensive density.",
			"ability_key": "Density_Shift"
		},

		# Branch 2: Granular Erosion & Seismic Tectonics
		{
			"key": "Sand", "display_name": "Sand", "discipline": "earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 1, "branch_angle": 45.0,
			"desc": "Starter granular abrasive flow. Scratches vision and blinds opponents.",
			"ability_key": "Sand"
		},
		{
			"key": "Petrification", "display_name": "Petrification", "discipline": "earth", "tier": "advanced",
			"prerequisites": ["Sand"], "level_req": 6, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 2, "branch_angle": 40.0,
			"desc": "Accelerate mineral crystallization inside target fibers to root their stance.",
			"ability_key": "Petrification"
		},
		{
			"key": "Tectonic", "display_name": "Tectonic Shift", "discipline": "earth", "tier": "mastery",
			"prerequisites": ["Petrification"], "level_req": 15, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 3, "branch_angle": 45.0,
			"desc": "Fracture ground plates with localized seismic waves to crush defensive cover.",
			"ability_key": "Tectonic"
		}
	],

	"air": [
		# Branch 0: Zephyr Momentum & Vacuum
		{
			"key": "Gale_Step", "display_name": "Gale Step", "discipline": "air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -135.0,
			"desc": "Starter evasive slip. Grants bonus dodge poise and fluid footwork.",
			"ability_key": "Gale_Step"
		},
		{
			"key": "Wind", "display_name": "Wind Vector", "discipline": "air", "tier": "advanced",
			"prerequisites": ["Gale_Step"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -140.0,
			"desc": "Generate directed high-velocity airflow that pushes opponents back.",
			"ability_key": "Wind"
		},
		{
			"key": "Vacuum", "display_name": "Vacuum", "discipline": "air", "tier": "mastery",
			"prerequisites": ["Wind"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -135.0,
			"desc": "Collapse atmospheric pressure pockets, creating lethal implosive vortices.",
			"ability_key": "Vacuum"
		},

		# Branch 1: Acoustics & Barometrics
		{
			"key": "Sound_Sonic", "display_name": "Sound / Sonic", "discipline": "air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 1, "branch_angle": 180.0,
			"desc": "Starter compression acoustics. Weaponizes sonic shock frequencies.",
			"ability_key": "Sound_Sonic"
		},
		{
			"key": "Nitrogen", "display_name": "Nitrogen", "discipline": "air", "tier": "advanced",
			"prerequisites": ["Sound_Sonic"], "level_req": 6, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 2, "branch_angle": 180.0,
			"desc": "Isolate inert atmospheric nitrogen to cool targets and deplete breath.",
			"ability_key": "Nitrogen"
		},
		{
			"key": "Pressure_Control", "display_name": "Pressure Control", "discipline": "air", "tier": "mastery",
			"prerequisites": ["Nitrogen"], "level_req": 15, "sp_cost": 1,
			"branch_index": 1, "branch_tier": 3, "branch_angle": 180.0,
			"desc": "Rapid barometric fluctuation that crushes stamina and breaks armor poise.",
			"ability_key": "Pressure_Control"
		},

		# Branch 2: Atmosphere & Chemical Pheromones
		{
			"key": "Oxygen", "display_name": "Oxygen", "discipline": "air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 1, "branch_angle": 135.0,
			"desc": "Starter gas concentration. Boosts friendly combustion and sustains stamina.",
			"ability_key": "Oxygen"
		},
		{
			"key": "Scent_Pheromone", "display_name": "Scent / Pheromone", "discipline": "air", "tier": "advanced",
			"prerequisites": ["Oxygen"], "level_req": 6, "sp_cost": 1,
			"branch_index": 2, "branch_tier": 2, "branch_angle": 140.0,
			"desc": "Disperse chemical signals on the wind to disorient and confuse opponents.",
			"ability_key": "Scent_Pheromone"
		}
	],

	"fire_water": [
		{
			"key": "Steam_Vent", "display_name": "Steam Vent", "discipline": "fire_water", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -15.0,
			"desc": "Release a jet of boiling vapor that scorches skin and obscures vision.",
			"ability_key": "Steam_Vent"
		},
		{
			"key": "Superheated_Scald", "display_name": "Superheated Scald", "discipline": "fire_water", "tier": "advanced",
			"prerequisites": ["Steam_Vent"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -15.0,
			"desc": "Project pressurized steam that melts physical defenses and burns targets.",
			"ability_key": "Superheated_Scald"
		},
		{
			"key": "Superheated_Steam", "display_name": "Superheated Steam", "discipline": "fire_water", "tier": "mastery",
			"prerequisites": ["Superheated_Scald"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -15.0,
			"desc": "Thermal boiling vapor blankets the grid. Blinds line-of-sight and inflicts scalding.",
			"ability_key": "Superheated_Steam"
		}
	],

	"fire_earth": [
		{
			"key": "Molten_Shard", "display_name": "Molten Shard", "discipline": "fire_earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -45.0,
			"desc": "Hurl jagged superheated obsidian coated in molten slag.",
			"ability_key": "Molten_Shard"
		},
		{
			"key": "Lava_Torrent", "display_name": "Lava Torrent", "discipline": "fire_earth", "tier": "advanced",
			"prerequisites": ["Molten_Shard"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -45.0,
			"desc": "Unleash a river of liquid magma that destroys barriers and melts physical armor.",
			"ability_key": "Lava_Torrent"
		},
		{
			"key": "Magma_Surge", "display_name": "Magma Surge", "discipline": "fire_earth", "tier": "mastery",
			"prerequisites": ["Lava_Torrent"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -45.0,
			"desc": "Liquefies stone into creeping molten tiles across the combat grid.",
			"ability_key": "Magma_Surge"
		}
	],

	"fire_air": [
		{
			"key": "Arc_Flash", "display_name": "Arc Flash", "discipline": "fire_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -135.0,
			"desc": "Blinding atmospheric ionization that disrupts neural pathways.",
			"ability_key": "Arc_Flash"
		},
		{
			"key": "Ion_Shock", "display_name": "Ion Shock", "discipline": "fire_air", "tier": "advanced",
			"prerequisites": ["Arc_Flash"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -135.0,
			"desc": "Supercharged ionized bolt that chains to adjacent metallic or wet targets.",
			"ability_key": "Ion_Shock"
		},
		{
			"key": "Plasma_Conflagration", "display_name": "Plasma Conflagration", "discipline": "fire_air", "tier": "mastery",
			"prerequisites": ["Ion_Shock"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -135.0,
			"desc": "Oxygen-supercharged inferno with heavy explosive shockwaves.",
			"ability_key": "Plasma_Conflagration"
		}
	],

	"water_earth": [
		{
			"key": "Mud_Mire", "display_name": "Mud Mire", "discipline": "water_earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 45.0,
			"desc": "Churn soil into a thick viscous mud that hampers enemy strides.",
			"ability_key": "Mud_Mire"
		},
		{
			"key": "Bog_Sink", "display_name": "Bog Sink", "discipline": "water_earth", "tier": "advanced",
			"prerequisites": ["Mud_Mire"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 45.0,
			"desc": "Submerge the target's footing in liquefying mud, rooting them in place.",
			"ability_key": "Bog_Sink"
		},
		{
			"key": "Quicksand_Mire", "display_name": "Quicksand Mire", "discipline": "water_earth", "tier": "mastery",
			"prerequisites": ["Bog_Sink"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 45.0,
			"desc": "Saturates ground into thick mud, reducing enemy speed to 1 and tripling sprint costs.",
			"ability_key": "Quicksand_Mire"
		}
	],

	"water_air": [
		{
			"key": "Flurry_Frost", "display_name": "Flurry Frost", "discipline": "water_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 165.0,
			"desc": "Summon a whirling burst of sub-zero ice needles.",
			"ability_key": "Flurry_Frost"
		},
		{
			"key": "Chill_Squall", "display_name": "Chill Squall", "discipline": "water_air", "tier": "advanced",
			"prerequisites": ["Flurry_Frost"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 165.0,
			"desc": "Freezing gale that encases damp combatants in crystalline frost.",
			"ability_key": "Chill_Squall"
		},
		{
			"key": "Glacial_Blizzard", "display_name": "Glacial Blizzard", "discipline": "water_air", "tier": "mastery",
			"prerequisites": ["Chill_Squall"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 165.0,
			"desc": "Freezes water puddles into ice slicks causing moving units to slide uncontrollably.",
			"ability_key": "Glacial_Blizzard"
		}
	],

	"earth_air": [
		{
			"key": "Grit_Swirl", "display_name": "Grit Swirl", "discipline": "earth_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 135.0,
			"desc": "Abrasive mini-vortex that kicks grit into the opponent's eyes.",
			"ability_key": "Grit_Swirl"
		},
		{
			"key": "Abrasive_Grit", "display_name": "Abrasive Grit", "discipline": "earth_air", "tier": "advanced",
			"prerequisites": ["Grit_Swirl"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 135.0,
			"desc": "Weaponized atmospheric sandblasting that strips enemy accuracy.",
			"ability_key": "Abrasive_Grit"
		},
		{
			"key": "Dust_Devil_Sandstorm", "display_name": "Dust Devil Sandstorm", "discipline": "earth_air", "tier": "mastery",
			"prerequisites": ["Abrasive_Grit"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 135.0,
			"desc": "Whirls sharp abrasive mineral grit, halving enemy Dexterity across the zone.",
			"ability_key": "Dust_Devil_Sandstorm"
		}
	],

	# ── 4 TRIPLE COMBINATION PROGRESSION TREES ──
	"fire_water_earth": [
		{
			"key": "Ore_Synthesis", "display_name": "Ore Synthesis", "discipline": "fire_water_earth", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -30.0,
			"desc": "Synthesize hyper-dense metallic ores from hydrothermal volcanic mineral solutions.",
			"ability_key": "Ore_Synthesis"
		},
		{
			"key": "Acid_Dissolution", "display_name": "Acid Dissolution", "discipline": "fire_water_earth", "tier": "advanced",
			"prerequisites": ["Ore_Synthesis"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -30.0,
			"desc": "Superheated mineral acid stream that strips enemy poise and melts physical armor.",
			"ability_key": "Acid_Dissolution"
		},
		{
			"key": "Geothermal_Obsidian", "display_name": "Geothermal Obsidian", "discipline": "fire_water_earth", "tier": "mastery",
			"prerequisites": ["Acid_Dissolution"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -30.0,
			"desc": "Erupts boiling geysers and coats grid in razor obsidian shards that inflict heavy Bleed.",
			"ability_key": "Geothermal_Obsidian"
		}
	],

	"fire_water_air": [
		{
			"key": "Hailfire", "display_name": "Hailfire", "discipline": "fire_water_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": -150.0,
			"desc": "Rain down supercooled hail coated in volatile chemical flames.",
			"ability_key": "Hailfire"
		},
		{
			"key": "Lightning_Storm", "display_name": "Lightning Storm", "discipline": "fire_water_air", "tier": "advanced",
			"prerequisites": ["Hailfire"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": -150.0,
			"desc": "Charged convective squall discharging multi-target lightning strikes.",
			"ability_key": "Lightning_Storm"
		},
		{
			"key": "Superheated_Cyclone", "display_name": "Superheated Cyclone", "discipline": "fire_water_air", "tier": "mastery",
			"prerequisites": ["Lightning_Storm"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": -150.0,
			"desc": "Vacuum hurricane that pulls all enemies inward while boiling stamina gauges to zero.",
			"ability_key": "Superheated_Cyclone"
		}
	],

	"fire_earth_air": [
		{
			"key": "Sulfur_Clouds", "display_name": "Sulfur Clouds", "discipline": "fire_earth_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 30.0,
			"desc": "Deploy choking noxious volcanic gas that strips visibility and burns eyes.",
			"ability_key": "Sulfur_Clouds"
		},
		{
			"key": "Ashfall_Blackout", "display_name": "Ashfall Blackout", "discipline": "fire_earth_air", "tier": "advanced",
			"prerequisites": ["Sulfur_Clouds"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 30.0,
			"desc": "Dense incandescent ash deluge that obscures the arena and snuffs line-of-sight.",
			"ability_key": "Ashfall_Blackout"
		},
		{
			"key": "Meteoric_Reentry", "display_name": "Meteoric Re-Entry", "discipline": "fire_earth_air", "tier": "mastery",
			"prerequisites": ["Ashfall_Blackout"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 30.0,
			"desc": "Propels blazing kinetic boulders like artillery shells. Obliterates cover into crater pits.",
			"ability_key": "Meteoric_Reentry"
		}
	],

	"water_earth_air": [
		{
			"key": "Bog_Traps", "display_name": "Bog Traps", "discipline": "water_earth_air", "tier": "basic",
			"prerequisites": [], "level_req": 1, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 1, "branch_angle": 150.0,
			"desc": "Seed organic wetland snares that entrap enemy footwork.",
			"ability_key": "Bog_Traps"
		},
		{
			"key": "Spore_Tempest", "display_name": "Spore Tempest", "discipline": "water_earth_air", "tier": "advanced",
			"prerequisites": ["Bog_Traps"], "level_req": 6, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 2, "branch_angle": 150.0,
			"desc": "Airborne fungal spore squall that disorients targets and drains stamina.",
			"ability_key": "Spore_Tempest"
		},
		{
			"key": "Permafrost_Cryotectonic", "display_name": "Permafrost Cryo-Tectonic", "discipline": "water_earth_air", "tier": "mastery",
			"prerequisites": ["Spore_Tempest"], "level_req": 15, "sp_cost": 1,
			"branch_index": 0, "branch_tier": 3, "branch_angle": 150.0,
			"desc": "Erects impassable continental glaciers. Traps wet targets solid in ice blocks.",
			"ability_key": "Permafrost_Cryotectonic"
		}
	]
}

func get_discipline(discipline_key: String) -> Dictionary:
	var k = discipline_key.to_lower()
	if DISCIPLINE_ALIASES.has(k):
		k = DISCIPLINE_ALIASES[k]
	return DISCIPLINES.get(k, {})

func get_skill_tree_nodes(discipline_key: String) -> Array:
	var k = discipline_key.to_lower()
	if DISCIPLINE_ALIASES.has(k):
		k = DISCIPLINE_ALIASES[k]
	return SKILL_TREES.get(k, [])

func get_skill_node(skill_key: String) -> Dictionary:
	for disc_key in SKILL_TREES:
		for node in SKILL_TREES[disc_key]:
			if node.get("key") == skill_key:
				return node
	return {}

func get_skill_level_req(tier: String) -> int:
	return SKILL_LEVEL_REQUIREMENTS.get(tier.to_lower(), 1)

func get_skill_sp_cost(tier: String) -> int:
	return SKILL_SP_COSTS.get(tier.to_lower(), 1)

# ──────────────────────────────────────────────
#  SKILL OFFER SYSTEM
# ──────────────────────────────────────────────

func get_skills_for_level(element_key: String, player_level: int) -> Array:
	if not ELEMENTS.has(element_key):
		return []

	var pool = ELEMENTS[element_key]["skill_pool"].duplicate()

	# Gate pinnacle abilities — only offer if level 30+
	if player_level < 30:
		pool = pool.filter(func(key): return ABILITIES[key]["tier"] != "pinnacle")

	# Gate mastery abilities by level
	if player_level < 26:
		pool = pool.filter(func(key): return ABILITIES[key]["tier"] != "mastery")

	# Gate advanced abilities by level
	if player_level < 11:
		pool = pool.filter(func(key): return ABILITIES[key]["tier"] != "advanced")

	return pool

func get_skill_offers(element_key: String, unlocked: Array, player_level: int) -> Array:
	var pool = get_skills_for_level(element_key, player_level)
	if pool.is_empty():
		return []

	# Filter out already-unlocked skills
	pool = pool.filter(func(key): return not unlocked.has(key))

	if pool.is_empty():
		return []

	pool.shuffle()
	return pool.slice(0, min(3, pool.size()))

func get_skills_for_athlete(element_key: String, player_level: int, count: int = 4) -> Array:
	var pool = get_skills_for_level(element_key, player_level)
	if pool.is_empty():
		return []
	pool = pool.duplicate()
	pool.shuffle()
	return pool.slice(0, min(count, pool.size()))

func get_fusion_info(elem_a: String, elem_b: String) -> Dictionary:
	for key in FUSIONS:
		var item = FUSIONS[key]
		if item["tier"] == "double" and item["elements"].has(elem_a) and item["elements"].has(elem_b):
			return item
	return {}

func get_triple_fusion(elem_a: String, elem_b: String, elem_c: String) -> Dictionary:
	for key in FUSIONS:
		var item = FUSIONS[key]
		if item["tier"] == "triple" and item["elements"].has(elem_a) and item["elements"].has(elem_b) and item["elements"].has(elem_c):
			return item
	return {}

func get_quadruple_fusion() -> Dictionary:
	return FUSIONS.get("Chrono_Spatial_Singularity", {})

func get_skill_forms(skill_key: String) -> Dictionary:
	if ABILITIES.has(skill_key):
		return ABILITIES[skill_key].get("forms", {})
	return {}

func get_skill_form_keys(skill_key: String) -> Array:
	var forms = get_skill_forms(skill_key)
	return forms.keys()

func get_skill_form_info(skill_key: String, form_key: String) -> Dictionary:
	var forms = get_skill_forms(skill_key)
	return forms.get(form_key, {})
