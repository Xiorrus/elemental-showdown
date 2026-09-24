# Original User Request

## Initial Request — 2026-09-13T00:08:27Z

Implement comprehensive visual, combat, and customization enhancements for Elemental Showdown, including high-contrast Persona-style typography, a modular character appearance system with team-based outfits, floating combat feedback, and polished battle AI.

Working directory: C:\Users\alexj\Documents\elemental-showdown
Integrity mode: development

## Requirements

### R1. High-Contrast Typography & Combat HUD Integration
Apply the high-contrast serif font (Cinzel Bold / Persona-style aesthetic) consistently across all game UI (turn indicators, combat log, player/enemy stat panels, ability bar, and modal dialogues). Integrate dynamic character name presentation matching the selected element. Ensure HP and MP bars transition smoothly via tweens on damage/cost deduction, and add an animated gold XP progress bar to the player panel.

### R2. Floating Combat Feedback System
Implement a dynamic floating text system that displays damage numbers, healing amounts, and critical combat feedback above targeted characters in the arena. Popups must float upward and fade out smoothly without obstructing tactical grid interaction.

### R3. Modular Character Sprite & Customization System
Create an expanded character visual system supporting customized hair, skin tone, detailed apparel, and team-based color schemes for the player, NPCs, and enemy combatants. Walk and attack sprite animations must maintain pixel alignment with the 64×64 tactical grid.

### R4. Combat Mechanics & Scene Integrity
Refactor enemy targeting to dynamically query character groups instead of hardcoded node paths, ensure enemy AI evaluates lethal opportunities before default damage ordering, and clean up unreferenced legacy scene nodes to maintain clean project assets.

## Acceptance Criteria

### Visual & Typography
- [ ] Cinzel Bold font is rendered cleanly across all HUD panels, ability buttons, turn ribbon, and logs without layout clipping.
- [ ] Floating damage indicators spawn upon damage/healing events, float upward, and fade out within 0.8 seconds.
- [ ] HP, MP, and XP bars animate smoothly to target values rather than snapping instantly.

### Character & Faction Customization
- [ ] Character sprite sheets (walk and attack) reflect detailed clothing, hairstyle, skin tone, and team/element color accents.
- [ ] Characters are centered correctly in 64×64 grid tiles across all 4 movement and idle orientations.

### Battle System & Verification
- [ ] Player and enemy combatants query targets via groups, supporting single or multiple combatants cleanly.
- [ ] Enemy AI prioritizes abilities that finish off targets when lethal damage is available.
- [ ] Project builds and runs headless verification without missing resource errors, script parse failures, or broken preload references.

## Follow-up — 2026-09-19T17:59:01Z

Fix all audited bugs and overhaul the fighter generation and
sub-selection systems in Elemental Showdown (Godot 4.5.1, GDScript).
Every athlete in the world — ally and enemy alike — must be an
individually generated entity with their own name, stats, potential,
and career arc, not a copy of the player or captain node.

Working directory: C:\Users\alexj\Documents\elemental-showdown
Integrity mode: development

---

## Reference Material

- Engine: Godot 4.5.1 stable (`D:\USB\Games\Godot_v4.5.1-stable_win64.exe\`)
- Headless test runner: `Godot_v4.5.1-stable_win64_console.exe --headless -s scripts/<test>.gd`
- Existing test suites: `test_multi_unit.gd`, `test_features.gd`, `test_strategy_and_stats.gd`, `test_hub_interactive.gd`, `test_skill_targeting.gd`
- Core scripts to modify: `campaign_manager.gd`, `world.gd`, `player.gd`, `enemy.gd`, `battle_manager.gd`, `ui.gd`, `element_data.gd`

---

## Requirements

### R1. Fix All Audited Bugs (Critical + Major)

Fix the following confirmed bugs, each with exact file and line references:

**Critical:**
1. **Double KO registration** — `player.gd` lines 354+407: `_on_defeated()` calls `record_knockout(self)` when `take_damage()` already did. Remove the redundant call in `_on_defeated()`.
2. **Stamina bar freeze** — `player.gd` lines 365 and 371: `heal()` and `spend_mp()` call `ui.update_player_stats(hp, max_hp, mp, max_mp)` without the stamina arguments. Pass `stamina, max_stamina` in both.
3. **Ally equipped skills overwritten** — `world.gd` line 191–209: ally units are created with `player.duplicate()` then `add_child()` is called, which triggers `_ready()` and overwrites `equipped_abilities` with the element's first basic skill. Reorder so that `equipped_abilities` is set AFTER `add_child()`.
4. **`skill_variations` not saved** — `campaign_manager.gd` save/load functions: add `"skill_variations": skill_variations` to the save dict and `skill_variations = data.get("skill_variations", {})` to load.
5. **Infinite animation wait loop** — `battle_manager.gd` line 399: the `while e.is_animating` loop has no timeout. Add a tick counter; after 100 iterations (5 seconds) force-clear `e.is_animating = false` and break.
6. **DoT fires past expiry** — `player.gd` and `enemy.gd` `tick_status_effects()`: duration is decremented first, then DoT is applied regardless. Apply DoT only when `duration > 0` (before decrement, or restructure the condition).

**Major:**
7. **`update_xp()` writes level to wrong label** — `ui.gd` line 1517: `xp_label.text = "Lv. %d" % level` overwrites the team name display. Remove this line; `level_label` already handles level.
8. **Ally stamina not initialized** — `world.gd` ally spawn loop: add `ally_unit.max_stamina = a_data.get("stamina", 100)` and `ally_unit.stamina = ally_unit.max_stamina`.
9. **Stat revert uses hardcoded Fire baselines** — `campaign_manager.gd` `revert_stat_point()`: the minimums (speed ≤ 3, agility ≤ 28, etc.) are hardcoded to Fire stats. Read the floor from `ElementData.ELEMENTS[player_element]` instead.
10. **Enemy AI ignores its own range** — `enemy.gd` `take_turn()`: enemy always moves toward the player even when already in ability range. Before moving, check if any usable ability can reach the closest player. If yes, skip movement and call `_act()` directly.
11. **Enemy stamina missing from updates** — `battle_manager.gd` `_run_enemies_sequence()` line 397: `update_enemy_stats` is called with only HP+MP. Pass stamina too.
12. **Pause modal shows saved HP, not live** — `ui.gd` `_refresh_pause_modal()`: ally HP/MP comes from `cm.allies[]` (campaign save). Cross-reference live scene nodes from `get_tree().get_nodes_in_group("players")` to show current battle HP/MP; fall back to campaign data for bench reserves who aren't on field.
13. **Acted units have no visual feedback** — When `has_acted == true`, apply `modulate = Color(0.55, 0.55, 0.55, 1.0)` to that player unit's sprite. Reset to `Color.WHITE` at the start of each new turn in `start_turn()`.

Do NOT add screen shake. Do NOT add camera trauma effects.

---

## Requirements

### R2. In-Match Sub Selection Modal

Replace the current automatic `designated_sub` substitution with an interactive selection modal.

When the SUB button is pressed during a match:
- A small panel opens over the HUD listing all currently benched allies who are not KO'd.
- Each entry shows: fighter name, element, current HP/MP (from campaign data), and equipped skills.
- The player clicks one to sub them in. Clicking outside or pressing ESC cancels.
- The selected fighter replaces the currently active unit (same logic as the existing `substitute_fighter()` call).
- If only one bench fighter is available, skip the modal and sub directly.
- If no bench fighters are available (all KO'd or all already on field), the button shows "NO BENCH" and is disabled.

The modal must use the existing `OrnatePanel` + Cinzel-Bold styling already established in `ui.gd`.

---

## Requirements

### R3. Fighter Generation System — Athletes as Individuals

Replace the current `player.duplicate()` / `enemy.tscn` copy approach with a proper fighter generation and career system. Every fighter in the world — ally or enemy — is an individual athlete with persistent identity.

#### 3a. Athlete Profiles (Campaign Data Layer)

Each athlete has a persistent profile stored in `CampaignManager`:
- `name` (string), `element` (string), `archetype` (one of: Striker, Scout, Defender, Support)
- `level` (int), `league_tier` (int: 1=Street/Bronze, 2=Silver, 3=Gold, 4=Diamond, 5=Apex)
- `base_stats`: HP, MP, stamina, speed, agility, dexterity — rolled at generation within per-tier ranges
- `potential` (hidden int 1–100): determines their ceiling for stat growth. High potential fighters grow more per level-up and reach higher stat ceilings. Low potential fighters plateau early.
- `known_skills` (array), `equipped_skills` (array, max 4)
- `status`: Active, Reserve, Injured, Retired, Free Agent
- `career_team` (current team name)

The player starts the campaign with no team — as a Street Brawler (tier 1) in 1v1 mode. After winning a defined number of street matches, they receive a team recruitment offer. The initial team roster is generated at that moment with 3–5 other fighters at tier 1 stats.

#### 3b. Generation Rules Per League Tier

When generating a new fighter for a given league tier, roll their stats within these ranges:

| Tier | HP | MP | Speed | Agility | Dex | Level Range |
|------|----|----|-------|---------|-----|-------------|
| 1 (Bronze/Street) | 70–100 | 80–110 | 2–3 | 16–28 | 20–30 | 1–5 |
| 2 (Silver) | 90–120 | 100–130 | 3–4 | 24–36 | 26–38 | 6–12 |
| 3 (Gold) | 110–145 | 120–150 | 3–5 | 32–48 | 32–46 | 13–22 |
| 4 (Diamond) | 130–170 | 140–180 | 4–5 | 44–60 | 42–55 | 23–35 |
| 5 (Apex) | 160–200 | 170–210 | 5–6 | 56–72 | 52–68 | 36–50 |

Skill loadout is drawn from the fighter's element pool filtered by their level tier gate (same tier rules as `element_data.gd:get_skill_offers()`).

#### 3c. Team Roster and Career Lifecycle

- A team can have up to 10 fighters total (including the player).
- The player starts as a free agent (solo) and joins a team after early wins.
- Each league season, a **transfer window** event fires: some fighters may retire (probability rises with low potential), some become free agents, some are recruited by other teams.
- When the player's team promotes to a new league tier:
  - Fighters whose `potential` is high enough for the new tier stay and develop.
  - Fighters who don't meet the tier floor leave the team (retire or drop to a lower-tier team).
  - New fighters at the new tier level join to fill the gap.
- If the player is scouted and transferred to a higher-tier team mid-season, the new team has mostly new faces generated at the higher tier. Small chance (10–15%) that a former ally or former opponent from a previous team has already been on this new team.
- Any AI fighter the player has fought before can reappear on any team — as ally or enemy — if their career arc brings them there. Their stats should have evolved since last encountered.

#### 3d. World Scene Integration

In `world.gd`, replace the `player.duplicate()` pattern:
- Ally units must be instantiated using `preload("res://scenes/Player.tscn").instantiate()` (a fresh scene instance, not a duplicate).
- Enemy units are already instanced from `enemy.tscn` — keep this, but wire `element_db` to them after `add_child()`.
- All stat assignments (HP, MP, speed, agility, dexterity, stamina, equipped_abilities) are read from the athlete's profile in `CampaignManager.allies[]` or the generated enemy roster.
- Assignments must happen AFTER `add_child()` so `_ready()` does not overwrite them. Equipped abilities must be assigned last.

#### 3e. Campaign Hub Integration

The existing Campaign Hub roster, stats, and battle tabs should reflect the new per-athlete profiles:
- Roster tab: show each ally's name, element, level, league_tier, potential tier label ("Journeyman" for potential 1–39, "Rising Star" for 40–74, "Prodigy" for 75–100), status, equipped skills.
- Battle tab: deployment workbench already shows ally positions — keep that layout, but use athlete profile data.

---

## Code Quality Rule — OOP

All new and modified GDScript code must follow Object-Oriented Programming principles:

- **Encapsulation**: Athlete profile data lives exclusively in `CampaignManager`. No other script accesses raw profile fields directly — all reads/writes go through `CampaignManager` methods (e.g., `get_ally(name)`, `update_athlete_stat(name, stat, value)`).
- **Single Responsibility**: Each script has one reason to change. `world.gd` handles scene wiring only. `campaign_manager.gd` manages all campaign state and athlete data. `ui.gd` handles display only and never modifies game state.
- **No Node Duplication**: Ally scene nodes are always fresh instantiations from `Player.tscn` — never `node.duplicate()`. Enemy scene nodes are always instantiations from `enemy.tscn`.
- **Dependency Injection**: References (`battle_manager`, `ui`, `element_db`, `grid_overlay`) are injected into nodes from `world.gd` after `add_child()`. Nodes do not reach out for these themselves via hardcoded paths.
- **Data / View Separation**: `CampaignManager` holds no Godot `Node` references. Scene nodes hold no campaign save data — they read initial state from `CampaignManager` at spawn time and manage their own in-match state independently.

---

## Acceptance Criteria

### Bug Fixes (R1)
- [ ] A player unit dying from burn DoT no longer triggers `player_loses()` prematurely in 3v3 when other allies are alive.
- [ ] After `heal()` is called, the player STA bar in the HUD reflects the correct stamina value immediately.
- [ ] After `spend_mp()` is called, the player STA bar does not freeze.
- [ ] Ally units (Kora, Gaius) entering a 3v3 match have their Campaign-assigned equipped skills active (not just the first element basic skill).
- [ ] Saving and reloading a campaign preserves `skill_variations` entries.
- [ ] A 3v3 match with 3 animated enemy units never hangs indefinitely during enemy turn.
- [ ] Burn applied for 2 turns deals damage on turns 1 and 2 only, not on turn 3.
- [ ] `update_xp()` no longer overwrites the team name with a level number.
- [ ] Ally Gaius has 120 stamina (from campaign data) when spawned, not the default 100.
- [ ] An Air-element player (base speed 4) cannot revert Speed below 4.
- [ ] Enemies with ranged abilities (range ≥ 3) do not advance further toward the player when already within their ability range.
- [ ] Pause modal HP/MP for on-field fighters matches actual battle values, not save-file values.
- [ ] Acted units (has_acted = true) display as visually greyed on the battlefield.

### Sub Selection Modal (R2)
- [ ] Pressing SUB during a 3v3 match opens a modal listing available bench fighters with name, element, HP, equipped skills.
- [ ] Clicking a fighter in the modal executes the substitution and closes the modal.
- [ ] If only one bench fighter is available, the modal is skipped and sub is executed directly.
- [ ] If no bench fighters are available, the SUB button shows "NO BENCH" and is disabled (no modal opens).
- [ ] The modal uses OrnatePanel + Cinzel-Bold styling consistent with the rest of the HUD.

### Fighter Generation System (R3)
- [ ] All existing headless test suites pass without modification: `test_multi_unit.gd`, `test_features.gd`, `test_strategy_and_stats.gd`, `test_hub_interactive.gd`, `test_skill_targeting.gd`.
- [ ] A new headless test `test_fighter_generation.gd` is written and passes, covering:
  - New campaign → player solo, no allies, tier 1.
  - Recruitment trigger → roster populated with 3–5 fighters, all stats inside tier-1 ranges.
  - Each fighter has a unique name and a potential score in 1–100.
  - Save/load cycle preserves all profiles including potential.
  - Calling the career lifecycle method with a tier promotion removes below-threshold fighters and adds higher-tier replacements.
  - Ally units spawned in `world.gd` have stats and equipped skills matching their stored profile, not `_ready()` defaults.
  - No script calls `node.duplicate()` to create ally units (verified inside the test by scanning the source file).
- [ ] Campaign Hub roster tab displays each ally's potential tier label ("Journeyman" / "Rising Star" / "Prodigy") and league tier.
- [ ] Enemy units have `element_db` injected after `add_child()`.

### Code Quality (OOP)
- [ ] No script outside `campaign_manager.gd` directly mutates athlete profile dictionaries.
- [ ] `world.gd` contains no campaign state logic — only scene node wiring.
- [ ] `ui.gd` contains no direct campaign state mutations.
- [ ] `CampaignManager` holds no Godot `Node` references.

## Follow-up — 2026-09-24T14:55:38Z

Implement the complete Competition Rules and Tactical Combat Plan for Elemental Showdown (Godot 4.5.1, GDScript) following docs/COMBAT_AND_SERIES_IMPLEMENTATION_PLAN.md.

Working directory: C:\Users\alexj\Documents\elemental-showdown
Integrity mode: development

---

## Reference Material & Strict Game Constraints

- Engine: Godot 4.5.1 stable (`D:\USB\Games\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe`)
- Headless test runner: `.\scripts\run_tests.ps1 -GodotPath 'D:\USB\Games\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe'`
- Working project root: `C:\Users\alexj\Documents\elemental-showdown`
- Implementation Plan: `docs/COMBAT_AND_SERIES_IMPLEMENTATION_PLAN.md`
- **Core Rules & Corrections**:
  1. The starting support skill and attack skill, including their first forms, remain free at character creation. All later skills and forms require SP in the skill tree.
  2. Implement in verified phases:
     - Phase 1: 3v3 Best-of-3 semifinal, calendar, save/load, and UI first.
     - Phase 2: Roster readiness gate and the 5v5 National final.
     - Phase 3: Tactical combat mechanics (knockback, telegraphs, primers, layered terrain, reactions, momentum) after foundations pass tests.
     - Assign one integrator to shared files so parallel work does not conflict.
  3. Define overtime or judging for tied knockout games, simulate non-player series via deterministic seeded best-of reducers, and prevent the post-result Restart Match button from awarding rewards or recording the same game twice.
  4. Add presets only for future national-team friendlies, the continental competition, and the national-team World Cup. Do not make unfinished brackets award trophies.
  5. Numbers such as 12 collision damage and 50/100 momentum thresholds are initial tuning values; verify and balance them through playtesting.
  6. Combat remains strictly turn-based. All skills come from the existing 72 skills and 3-form progression; do not invent new skill tree entries.
  7. A series is several separate tactical battles on scheduled days, not several rounds inside one battle.

---

## Requirements

### R1. Competition Rules & Season Series Scheduling
- Define data-driven competition presets via small `MatchRules` snapshots:
  - Street Duel: 1v1, Single Game.
  - Club Friendly: 3v3 by default (optional 1/5 if both teams eligible), Single Game (no standings impact).
  - City/Regional/National Club League: 3v3, Single Game (14 fixtures with current points/table).
  - City/Regional Championship Semis & Final: 3v3, Best-of-3 (first to 2 wins).
  - National Championship Semifinal: 3v3, Best-of-3.
  - National Cup Final: 5v5, Best-of-5 (first to 3 wins; awards National Title & Space/Time choice upon clinch).
  - Presets only for future national-team friendlies, the continental competition, and the national-team World Cup (no placeholder trophies).
- Dedicated postseason calendar dates within the 224-day season:
  - Semifinals: Days 199, 202, 205.
  - Finals: Days 210, 213, 216, 220, 223 (use first 3 for Bo3 finals).
  - Move pre-postseason national window to Week 25 to avoid collisions.
  - All series dates are reserved up front. Later games display "if needed" on the calendar; when a team clinches, remaining dates become "not needed" (preserving history).
- Non-player series simulation:
  - Simulate every non-player semifinal/final using the same best-of reducer with a deterministic seeded result per game.
- Tie-breaking:
  - Overtime (up to 2 rounds where a KO ends the match) and judge scoring (surviving fighters, aggregate remaining HP fraction, damage dealt) for tied knockout games.
- Roster readiness & deployment gate:
  - Roster readiness milestones warn the player before mandatory 5v5 fixtures; provide clearly labeled emergency club signing/loan if roster would otherwise deadlock.
  - Launch enforces EXACTLY N eligible, distinct fighters (no 3v5 matches, no fallback fighters in career matches).
  - Skipping a game forfeits/simulates ONLY that specific scheduled game, advances the calendar, and awards zero played-game rewards.
  - Jump to Match jumps to the next unresolved game, not the end of the series.

### R2. Small OOP Domain Classes & Idempotent Career Boundary
- Implement decoupled domain classes (using `RefCounted` for runtime rules, clean JSON at boundaries):
  - `scripts/match_rules.gd`: Validated immutable rules snapshot (team size, best-of, substitutions, arena preset, edge rules, overtime/round limits, date spacing).
  - `scripts/competition_rule_book.gd`: Factory producing named rule presets copied into scheduled fixtures.
  - `scripts/series_state.gd`: Encapsulates series ID, teams, dates, per-team wins, unique recorded game IDs, and clinch determination (`record_game()` rejects duplicate game IDs and games after clinch).
  - `scripts/match_context.gd`: Immutable launch snapshot (fixture ID, series ID, game ID, date, teams, rules, seed, arena ID) injected into `World` and HUD.
  - `scripts/combat_action_resolver.gd`: Single shared action pipeline for player and enemy hits.
  - `scripts/force_movement_resolver.gd`: Tile-by-tile displacement, occupancy, obstacle/wall collision damage and stagger.
  - `scripts/attack_intent.gd`: Frozen telegraph snapshot (caster, form ID, origin, target tiles, countdown, interrupt criteria).
  - `scripts/reaction_resolver.gd`: Universal once-per-round Guard/Counter/Intercept/Overwatch orders with documented trigger ordering.
  - `scripts/combat_event.gd`: Structured combat event stream for HUD, logs, animations, and tests.
  - `scripts/game_result.gd`: Immutable single-game outcome.
  - `scripts/enemy_tactics.gd`: Heuristic scoring of legal actions, telegraphs, and reactions using visible board state and prior series tendencies.
- Single responsibility boundaries:
  - `CampaignManager` is the single persistent career owner and solely awards XP, gold, and clinch trophies.
  - `BattleManager` is the single battle coordinator.
  - `SeasonCalendar` owns deterministic calendar generation and fixture dates.
  - `CampaignManager.complete_game(result)` must be atomic and idempotent: validates expected game ID, updates `SeriesState`, awards series trophy only on clinch, and rolls back in-memory changes if save fails.
  - Prevent post-result Restart Match from awarding duplicate rewards or recording the same game twice (change to no-reward exhibition or remove for official fixtures).
  - Backward compatibility: previous single-game saves seamlessly migrate without losing progress.

### R3. Physical Board Resolution: Knockback, Walls & Collisions
- Shared force movement resolves pushes tile-by-tile for forms that imply physical force.
- Movement stops at the first blocking obstacle (arena boundary, fighter, earth wall, structure).
- Collisions deal one impact damage packet (base 12 tuning) and apply stagger (max 1 stagger per target per action; no infinite chain-stuns).
- Fighter-to-fighter collisions damage both combatants. Wall impacts damage the pushed combatant and deduct HP from destructible earth walls.
- Grid overlay previews push trajectory arrows and likely collision destination without relying on red color alone.
- AI factors collision damage into positional scoring.

### R4. Telegraphed High-Impact Attacks & Elemental Primers
- Telegraphed Attacks:
  - Flag selected high-impact existing forms with `windup_rounds = 1`.
  - Caster spends their turn's attack to lock origin, target area, and telegraph icon/danger tiles.
  - Danger zone remains active through the opponent's entire response turn.
  - At the start of the caster's next phase, resolve the frozen zone instead of granting an extra attack.
  - Interruption: Knockout, stun, forced displacement, or destroyed required terrain cancels the intent.
- Elemental Primer & Detonator Combos:
  - Landed elemental attacks apply a target-owned primer token lasting one response window.
  - A compatible subsequent elemental hit from a teammate consumes the primer and detonates a team reaction:
    - Water + Lightning: Conductive shock (adjacent tile arc + short stun).
    - Water + Fire: Scalding vapor (bonus armor-piercing damage + blind).
    - Fire + Earth: Molten slag (burning ground hazard).
    - Air + Status: Dispersal (spreads existing burn/wet/chill to adjacent legal targets).
  - Reaction damage is non-priming (cannot infinitely recurse).

### R5. Layered Terrain, Structures & Transparent Arena Presets
- Refactor `BattleTerrain` into clear distinct layers:
  - Structure (destructible earth walls with HP).
  - Surface (fire, ice, water puddles with turn durations).
  - Obscurant (smoke with sight/accuracy penalties).
- Deterministic interaction order: direct hit -> extinguish/transform surfaces -> place new surfaces -> advance round durations.
- Named arena presets (e.g. Standard Stadium, Cage Arena with shock fences, Dojo with ring-out boundaries) disclosed in match rules and previewed in deployment.

### R6. Team Crowd Momentum & Universal Combat Reactions
- Convert existing resonance gauge into independent team Crowd Momentum gauges (0–100 per side):
  - Builds from counter-hits, elemental detonations, multi-tile knockbacks, and surviving telegraphed attacks. Decays slightly on passive turns.
  - At 50% Momentum (initial tuning): "Crowd Roar" grants a modest once-per-round +1 move speed.
  - At 100% Momentum (initial tuning): player can empower their next equipped form (+20% damage/healing or +1 terrain duration) with an ornate animation banner (not a new skill or free turn).
- Universal Tactical Reactions (chosen at end-of-turn in lieu of attacking):
  - Guard: Damage reduction and knockback immunity.
  - Counter: Automatic basic strike against close-range melee attackers.
  - Intercept: Defender dashes up to 2 tiles to absorb a hit directed at a designated ally.
  - Overwatch: Reserve equipped ranged attack to strike the first enemy moving into its pattern.
  - Documented trigger order: Overwatch on movement -> Intercept on targeting -> Guard on impact -> Counter on survival.

### R7. Information Architecture, Calendar & Battle HUD
- Hub Schedule Card: Displays competition name, opponent, format (3v3 / 5v5), series type (Single / Bo3 / Bo5), series score (e.g. "1 – 0"), game number, and next match date.
- Monthly Calendar Popup: Displays individual cells for every potential series date (G1, G2, G3 if needed). Shows played / win / loss / next / if-needed / not-needed states with accessible symbols and colors.
- Deployment Workbench: Read-only format badge, deployment count validation (Required N vs Deployed N), bench sub limits, and disabled Launch button with specific error message until exactly N legal units are placed.
- Battle HUD & Overlays:
  - Series header badge (e.g. "National Final · Game 2 of 5 · 1–0").
  - Independent team momentum bars.
  - Visual reaction choice badge & remaining trigger.
  - Target-owned primer tokens and terrain turn/HP tooltip on hover.
  - Patterned red enemy danger layer distinct from orange player attack targeting.
- Result Modal:
  - Distinguishes Game Result from Series Result.
  - Displays series score tally, clinch status, and single-game reward summary.

---

## Acceptance Criteria

### Phase 1: 3v3 Bo3 Semifinal, Calendar, Save/Load & UI
- [ ] `MatchRules`, `CompetitionRuleBook`, and `SeriesState` domain classes implemented with unit tests.
- [ ] Best-of-3 semifinal correctly scheduled on Days 199, 202, 205 within the 224-day calendar.
- [ ] 2–0 series clinches and cancels Game 3 ("not needed"); 1–1 series advances to Game 3.
- [ ] Monthly calendar popup displays G1, G2, G3 (if-needed / not-needed) with accessible symbols and Jump to Next Game.
- [ ] Hub schedule card displays competition type, Bo3 series status, and current series score.
- [ ] Skipping Game 1 simulates/forfeits Game 1 only and advances calendar without played-game rewards.
- [ ] Save/load preserves series state, recorded game IDs, and migrates legacy saves without data corruption.
- [ ] Tied knockout games resolve via overtime / judge decisions without crashing or deadlocking.
- [ ] Non-player semifinals/finals simulate using deterministic seeded best-of reducers.
- [ ] Post-result restart does not duplicate XP, money, or record duplicate games.

### Phase 2: Roster Readiness & 5v5 National Final
- [ ] 5v5 National final scheduled on Days 210, 213, 216, 220, 223. First team to 3 wins clinches National Cup & Space/Time choice.
- [ ] Roster readiness milestone warns player in advance of 5v5 requirement, with emergency loan/signing fallback.
- [ ] Deployment strictly enforces exactly 5 legal, distinct combatants (blocks launch with clear error if incomplete or mismatched).
- [ ] Presets added for future national friendlies, continental cup, and national World Cup without awarding premature placeholder trophies.

### Phase 3: Tactical Combat Mechanics & Physical Grid
- [ ] Shared force movement executes tile-by-tile pushes, stopping at walls, fighters, and obstacles.
- [ ] Wall and fighter collisions deal single impact damage packet and stagger without infinite loops.
- [ ] Telegraphed attacks display distinct danger tiles across the opponent's turn and can be cancelled by displacement, stun, or KO.
- [ ] Landed attacks apply primer tokens; compatible teammate attacks trigger single non-recursing detonations.
- [ ] Layered `BattleTerrain` resolves structures, surfaces, and obscurants with deterministic order.
- [ ] Team Crowd Momentum operates 0–100 per side, granting Crowd Roar at 50 and empowered action at 100.
- [ ] Guard, Counter, Intercept, and Overwatch execute in documented priority order at most once per round.

### Verification & Testing
- [ ] New automated headless test suites pass:
  - `test_match_rules.gd`
  - `test_series_state.gd`
  - `test_match_scheduling.gd`
  - `test_combat_intents.gd`
  - `test_force_movement.gd`
  - `test_reaction_rules.gd`
- [ ] Full existing test suite passes: `test_campaign_regressions.gd`, `test_campaign_loop.gd`, `test_fighter_generation.gd`, `test_multi_unit.gd`, `test_features.gd`, `test_strategy_and_stats.gd`, `test_multi_campaign_saves.gd`.
- [ ] `.\scripts\run_tests.ps1` executes with 0 failures.
- [ ] Visual capture verification at 1920x1080 confirms calendar popup, deployment, battle HUD, and result modal are clean, unclipped, and legible.
