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
