# Project: Elemental Showdown Competition Rules & Tactical Combat

## Architecture
Elemental Showdown adopts a modular, decoupled Object-Oriented architecture using Godot 4.5.1 GDScript.
Core runtime rules, state machines, and resolution pipelines are implemented as lightweight `RefCounted` domain objects. Godot Scene Nodes (`World`, `Player`, `Enemy`, `UI`, `CampaignHub`) act as composition roots and presentation views, delegating business logic and calculations to the domain layer.

```
+--------------------------------------------------------------------------+
|                             Presentation & UI                            |
|  CampaignHub (Schedule Card, Deployment Workbench)  |  CareerCalendarPopup |
|  BattleHUD (Momentum, Telegraphs, Reactions)         |  BattleResultModal  |
+--------------------------------------------------------------------------+
                                     |
                                     v
+--------------------------------------------------------------------------+
|                       Career & Scheduling Domain                         |
|  SeasonCalendar (Dated Slots, Conflict Prevention)                        |
|  CampaignManager (Idempotent complete_game, Save/Load Migration, Awards) |
|  SeriesState (Wins, Clinch, Recorded Games, Scouting Memory)             |
|  CompetitionRuleBook -> MatchRules (Immutable Data-Driven Presets)        |
+--------------------------------------------------------------------------+
                                     |
                                     v
+--------------------------------------------------------------------------+
|                        Launch & World Composition                        |
|  MatchContext (Snapshot of Fixture, Series, Teams, Rules, Seed, Arena)   |
|  World (Spawns EXACTLY N Distinct Eligible Fighters, Wires Resolvers)    |
+--------------------------------------------------------------------------+
                                     |
                                     v
+--------------------------------------------------------------------------+
|                         Tactical Combat Domain                           |
|  BattleManager (Single Battle Coordinator, Turn Phasing, Overtime)       |
|  CombatActionResolver (Unified Player & Enemy Hit Pipeline)              |
|  ForceMovementResolver (Tile-by-Tile Push, Wall/Fighter Collision)       |
|  AttackIntent (Frozen Windup=1 Telegraph, Interrupt Resolution)          |
|  ReactionResolver (Guard, Counter, Intercept, Overwatch Priority)        |
|  BattleTerrain (Layered: Structure, Surface, Obscurant)                  |
|  CrowdMomentum (0-100 Per Side, 50 Roar, 100 Empower)                   |
|  CombatEvent (Structured Event Stream for HUD, Log, Tests)               |
|  GameResult (Immutable Single-Game Outcome Handed Off to Career)         |
+--------------------------------------------------------------------------+
```

---

## Feature Inventory
| # | Feature | Description | Milestone | Source |
|---|---------|-------------|-----------|--------|
| 1 | `MatchRules` Domain Class | Immutable rules snapshot (team size, best_of, substitutions, arena, overtime, date spacing) | M1 | R1, R2 |
| 2 | `CompetitionRuleBook` Preset Factory | Data-driven presets: Street Duel, Club Friendly, League, City/Regional/National Semis & Finals, and future international presets | M1 | R1, R2 |
| 3 | `SeriesState` Domain Class | Encapsulates series ID, teams, dates, per-team wins, recorded game IDs, clinch determination, and scouting memory | M1 | R1, R2 |
| 4 | `MatchContext` Domain Class | Immutable launch snapshot injected into World and HUD | M1 | R2 |
| 5 | `GameResult` Domain Class | Immutable single-game outcome (game ID, winner/draw, turns, judge score, played/skipped) | M1 | R2 |
| 6 | Postseason Calendar Slots (Days 199, 202, 205) | Exact calendar reservation for Semifinals in 224-day season | M1 | R1 |
| 7 | Calendar Day Event Lookup Refactor | Fix `season_calendar.gd` `get_day_entry()` to serve series events on non-day-7 dates | M1 | R1 |
| 8 | National Window Shift to Week 25 | Relocate Week 31 national window to Week 25 to prevent collisions with Finals | M1 | R1 |
| 9 | Non-Player Seeded Series Simulation | Deterministic seeded best-of reducer for simulated non-player series | M1 | R1 |
| 10 | Knockout Tie-Breaking (Overtime & Judges) | Up to 2 overtime sudden-death KO rounds and 3-step judge scoring | M1 | R1 |
| 11 | Single-Game Skip / Forfeit | Skipping a series game forfeits/simulates ONLY that specific scheduled game, advances calendar, 0 played rewards | M1 | R1 |
| 12 | Jump to Next Unresolved Game | Jump to Match navigates to the next unresolved game, not series end | M1 | R1 |
| 13 | Idempotent `CampaignManager.complete_game()` | Atomic validation of expected game ID, SeriesState update, clinch trophy award, and rollback on save failure | M1 | R2 |
| 14 | Save File Migration (v1 to v2) | Seamless backward compatibility for legacy single-game saves without data loss | M1 | R2 |
| 15 | Restart Match Duplicate Prevention | Post-result Restart Match disabled or converted to reward-free exhibition | M1 | R2 |
| 16 | Monthly Calendar Popup Series Display | Displays reserved cells G1, G2, G3 with if-needed and not-needed states, accessible symbols, and tooltips | M1 | R7 |
| 17 | Hub Schedule Card Series Integration | Displays competition name, format (3v3), series type (Bo3), series score, and game number | M1 | R7 |
| 18 | Deployment Workbench Count Check (Phase 1) | Launch button disabled unless exactly 3 eligible distinct fighters deployed for 3v3 | M1 | R7 |
| 19 | National Cup Final Bo5 Scheduling (Days 210, 213, 216, 220, 223) | Best-of-5 final; first to 3 wins clinches National Cup & Space/Time choice | M2 | R1 |
| 20 | Roster Readiness Milestone & Warning | Early warning before mandatory 5v5 fixtures (Week 17) in Campaign Hub | M2 | R1 |
| 21 | Emergency Club Loan/Signing Fallback | Guaranteed emergency recruitment option if roster would deadlock 5v5 | M2 | R1 |
| 22 | Strict 5v5 Deployment Gate | Exact 5 legal distinct fighters on both sides; blocks launch if incomplete, no fallback fake fighters | M2 | R1, R7 |
| 23 | Future International Cup Presets | Presets for national friendlies, continental cup, World Cup (no placeholder trophies awarded) | M2 | R1 |
| 24 | Force Movement Resolver | Tile-by-tile displacement, stopping at first blocking obstacle | M3 | R3 |
| 25 | Obstacle & Boundary Collision Damage | Base 12 damage packet to pushed combatant, damaging earth wall structures | M3 | R3 |
| 26 | Fighter-to-Fighter Collisions | Both collided combatants receive impact damage and max 1 stagger per action (no infinite stun) | M3 | R3 |
| 27 | Grid Overlay Collision & Push Previews | Trajectory arrows and impact destination previewed on grid overlay | M3 | R3, R7 |
| 28 | Telegraphed High-Impact Attacks | Selected existing forms given `windup_rounds = 1`, freezing origin & target area | M3 | R4 |
| 29 | Telegraph Danger Overlay & Window | Distinct patterned red danger zone active through opponent's entire response turn | M3 | R4, R7 |
| 30 | Telegraph Interruption Rules | Knockout, stun, forced displacement, or destroyed required terrain cancels intent | M3 | R4 |
| 31 | Elemental Primer Tokens | Landed elemental attack applies target-owned primer token lasting 1 response window | M3 | R4 |
| 32 | Elemental Detonations (4 Pairings) | Water+Lightning (shock/stun), Water+Fire (vapor/blind), Fire+Earth (molten ground), Air+Status (dispersal) | M3 | R4 |
| 33 | Non-Priming Reaction Damage | Detonation reaction damage cannot apply primers or infinitely recurse | M3 | R4 |
| 34 | Layered BattleTerrain | Discrete Structure (earth wall HP), Surface (fire/ice/water turn durations), Obscurant (smoke) layers | M3 | R5 |
| 35 | Deterministic Terrain Order | Direct hit -> extinguish/transform surfaces -> place new surfaces -> advance round durations | M3 | R5 |
| 36 | Transparent Arena Presets | Disclosed arena presets (Standard, Cage with shock fences, Dojo with ring-out) previewed in deployment | M3 | R5 |
| 37 | Independent Team Crowd Momentum | 0-100 gauge per team; gains from counters, detonations, knockbacks, surviving telegraphs; decays on passive turns | M3 | R6 |
| 38 | Crowd Roar (50% Momentum) | Once-per-round +1 move speed benefit | M3 | R6 |
| 39 | Empowered Action (100% Momentum) | Empowers next equipped form (+20% damage/heal or +1 terrain duration) with ornate animation banner | M3 | R6 |
| 40 | Universal Tactical Reactions | Guard (damage reduction + push immunity), Counter (melee basic strike), Intercept (dash 2 tiles to absorb hit), Overwatch (reserve ranged attack) | M3 | R6 |
| 41 | Reaction Trigger Priority Order | Overwatch (movement) -> Intercept (targeting) -> Guard (impact) -> Counter (survival) | M3 | R6 |
| 42 | AI Tactical Positioning & Reaction Scoring | `EnemyTactics` evaluates collisions, telegraphs, primers, and reactions using visible board state | M3 | R2, R3, R6 |
| 43 | Structured Combat Event Stream | `CombatEvent` objects emitted to HUD, battle log, and test harness | M3 | R2 |
| 44 | Battle HUD Momentum & Reaction Badges | Dual momentum bars, reaction choice badges, primer tokens, and intent countdowns | M3 | R7 |
| 45 | Result Modal Game vs Series Separation | Cleanly distinguishes single-game score, series score tally, clinch status, and single-game rewards | M1/M2 | R7 |
| 46 | Full Automated Headless Test Suite | All 6 new suites + 26 existing regression suites running 100% green | M4 | AC |
| 47 | Visual Capture Verification (1920x1080) | Headless capture verifying calendar popup, deployment, battle HUD, and result modal | M4 | AC |

---

## Milestones

| # | Name | Scope | Dependencies | Status |
|---|------|-------|-------------|--------|
| M1 | Phase 1: Competition Rules, Series State, Bo3 Semifinals, Calendar & UI | Features 1–18, 45; `match_rules.gd`, `competition_rule_book.gd`, `series_state.gd`, `match_context.gd`, `game_result.gd`, `season_calendar.gd`, `campaign_manager.gd`, `career_calendar_popup.gd`, `campaign_hub.gd`, `ui.gd`; tests: `test_match_rules.gd`, `test_series_state.gd`, `test_match_scheduling.gd` | None | IN_PROGRESS |
| M2 | Phase 2: Roster Readiness, 5v5 National Final & Future Presets | Features 19–23; 5v5 Bo5 finals scheduling, roster readiness warning, emergency loans, strict 5-fighter deployment, international presets | M1 | PLANNED |
| M3 | Phase 3: Tactical Combat Mechanics & Physical Grid | Features 24–44; `force_movement_resolver.gd`, `attack_intent.gd`, `reaction_resolver.gd`, `combat_action_resolver.gd`, `combat_event.gd`, `battle_terrain.gd`, `enemy_tactics.gd`, HUD momentum & telegraph integration; tests: `test_force_movement.gd`, `test_combat_intents.gd`, `test_reaction_rules.gd` | M1 | PLANNED |
| M4 | Phase 4: Final E2E Suite, Regressions & Visual Capture | Features 46–47; Execute `.\scripts\run_tests.ps1` with 0 failures across all suites, 1920x1080 visual captures, forensic audit verification | M1, M2, M3 | PLANNED |

---

## Interface Contracts

### Career / Scheduling Boundary (`SeasonCalendar` <-> `CampaignManager`)
```gdscript
# SeasonCalendar
func get_fixture_by_id(season: Dictionary, fixture_id: String) -> Dictionary
func get_day_entry(season: Dictionary, day: int) -> Dictionary
# Returns: {"day": int, "week": int, "day_in_week": int, "events": Array[Dictionary], "fixtures": Array[Dictionary]}
# Preserves scheduled series games on exact dates: 199, 202, 205, 210, 213, 216, 220, 223.

# CampaignManager
func complete_game(result: GameResult) -> Dictionary
# Idempotent game resolution:
# 1. Validates result.game_id against active scheduled game.
# 2. Rejects duplicate game IDs and updates SeriesState.
# 3. Applies energy/fatigue and modest XP.
# 4. If series clinches: records championship champion, awards trophy and Space/Time gate if applicable.
# 5. Saves campaign atomically (temp file rename). If save fails, rolls back memory state.
```

### Match Launch Boundary (`CampaignManager` -> `World`)
```gdscript
# MatchContext
class_name MatchContext
extends RefCounted
var fixture_id: String
var series_id: String
var game_id: String
var season_day: int
var home_team: String
var away_team: String
var rules: MatchRules # Snapshot of rules
var seed_value: int
var arena_id: String

# World.setup_match(context: MatchContext)
# Spawns EXACTLY rules.team_size distinct, eligible fighters for home and away.
# Injects MatchContext into BattleManager and UI.
```

### Tactical Combat Boundary (`BattleManager` <-> Resolvers)
```gdscript
# ForceMovementResolver.resolve_push(board_state: Dictionary, pusher: Node, target: Node, direction: Vector2i, max_distance: int, rules: MatchRules) -> ForceMovementResult
# Returns: {
#   "success": bool,
#   "actual_path": Array[Vector2i],
#   "final_tile": Vector2i,
#   "collision_occurred": bool,
#   "collided_with": Variant, # Node (fighter/wall) or "boundary"
#   "impact_damage": int, # 12
#   "stagger_applied": bool
# }

# ReactionResolver.evaluate_reactions(phase: String, trigger_event: Dictionary) -> Array[ReactionAction]
# Strict Priority: Overwatch -> Intercept -> Guard -> Counter.
# At most 1 reaction per unit per round.
```

---

## Code Layout
- Existing source scripts: `scripts/`
  - `scripts/season_calendar.gd`
  - `scripts/campaign_manager.gd`
  - `scripts/campaign_hub.gd`
  - `scripts/career_calendar_popup.gd`
  - `scripts/world.gd`
  - `scripts/battle_manager.gd`
  - `scripts/player.gd`
  - `scripts/enemy.gd`
  - `scripts/ability_geometry.gd`
  - `scripts/battle_terrain.gd`
  - `scripts/grid_overlay.gd`
  - `scripts/element_data.gd`
  - `scripts/ui.gd`
- New OOP Domain classes: `scripts/`
  - `scripts/match_rules.gd`
  - `scripts/competition_rule_book.gd`
  - `scripts/series_state.gd`
  - `scripts/match_context.gd`
  - `scripts/game_result.gd`
  - `scripts/combat_action_resolver.gd`
  - `scripts/force_movement_resolver.gd`
  - `scripts/attack_intent.gd`
  - `scripts/reaction_resolver.gd`
  - `scripts/combat_event.gd`
  - `scripts/enemy_tactics.gd`
- Test suites: `scripts/test_*.gd`
  - `scripts/test_match_rules.gd`
  - `scripts/test_series_state.gd`
  - `scripts/test_match_scheduling.gd`
  - `scripts/test_force_movement.gd`
  - `scripts/test_combat_intents.gd`
  - `scripts/test_reaction_rules.gd`
