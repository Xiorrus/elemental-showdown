# Elemental Showdown

A tactical turn-based martial arts combat sports game built in **Godot 4.5**.

Compete in high-stakes elemental arena combat where martial artists command the forces of nature across four core elements, primordial forces of space and time, and advanced elemental fusions.

---

## Key Features

### 1. The Elemental Wheel & Disciplines
- **Core Disciplines**: Fire (Combustion/Momentum), Water (Fluidity/Healing), Earth (Anchor/Defense), Air (Speed/Evasion).
- **Primordial Forces**: Space (Displacement/Barriers) and Time (Acceleration/Stasis).
- **Binary Combinations**: Steam (Fire + Water), Magma (Fire + Earth), Plasma/Lightning (Fire + Air), Mud (Water + Earth), Mist (Water + Air), Dust/Sand (Earth + Air).
- **Triple Combinations**: Complex tri-element martial disciplines on the outer mandala ring.

Each new fighter starts with one support skill and one attack skill. Their first forms are unlocked and equipped immediately:

| Element | Support | Attack |
| --- | --- | --- |
| Fire | Thermal Radiation → Heat Veil (defense) | Combustion |
| Water | Aqua Mend (healing) | Ice |
| Earth | Stone Plating (armor) | Metal |
| Air | Gale Step (evasion) | Wind |

The starter pairs live in `CampaignManager.DEFAULT_ELEMENT_SKILLS`; form effects live in `ElementData.ABILITIES` and are applied during combat by `Player`. This is the path to follow when adding another starter technique.

### 2. 72-Skill Progression Tree with Multiple Forms
- Every skill has **exactly 3 forms** modifying range, damage, MP cost, and targeting area. Existing forms such as Furnace Zone, Frost Nova, Rock Pillar, and Fog Shroud can leave terrain effects.
- **Progressive Unlock**: Unlocking a skill grants Form 1. Additional forms cost Skill Points (SP); there are no mid-game skill offers.
- **Mid-Combat Form Switching**: Freely switch active skill forms during your tactical combat turn (`F` hotkey, HUD cycle button, or right-click).

### 3. Tactical Squad Combat (1v1, 3v3, 5v5)
- **Direct Manual Squad Control**: Directly command captain and squadmates on an isometric grid.
- **Substitution System**: Bench reserves ready to swap into battle when formatted for team matches.
- **Dynamic Targeting & Status System**: Cardinal attacks and Needle Beam hit one target; piercing lines, wide sweeps, and radial attacks can hit multiple targets. Burn and Corrode deal damage over time. Each attacking form has a close (1 tile), mid (2–3 tiles), or long (4+ tiles) sweet spot that grants 25% more damage. The skill tree and combat HUD show that band.
- **Tactical Movement**: The AI scores legal firing squares using the same range bonus, expected hit chance, and flank/rear angle as actual attacks. Movement animates through every tile at 0.32 seconds per tile; attack frames and impact remain visible for about 0.64 seconds.
- **Terrain**: Furnace Zone leaves fire for several rounds and repeated casts extend it; water/ice extinguishes it. Rock Pillar creates one obstacle until destroyed, Frost Nova leaves slowing ice, and Fog Shroud obscures shots.

### 4. Campaign & Athlete Management
- **Career Path**: Choose a nationality and one element, win three Street Circuit duels, then accept a club offer. Clubs from the player's country have higher recruitment odds. Promotion opens another element choice; techniques and forms beyond the starter pair still cost SP in the skill tree.
- **Eight-Month Club Seasons**: Each season has 224 dated days across 32 weeks and 14 home-and-away fixtures. The hub shows a scrollable month grid with Jump to Match and a two-click Skip Match action. Scheduled matches cannot be entered early; rest (1, 3, or 7 days), focused stat training, and street brawls use open days. A skipped league match receives a simulated result without match rewards. Optional club friendlies appear in weeks 1 and 17.
- **Club League**: Domestic promotion runs City → Regional → National. Wins earn three points, draws one, and standings determine a top-four championship, top-two promotion, and bottom-two relegation. Rivals gain modest strength as divisions and seasons advance.
- **Trophy Gates**: A National Cup title offers a choice of Space or Time. A national-team World Cup followed by a Club World Cup grants one skill permit; a later World Cup can unlock the other primordial element or grant another permit. Primordial skills still cost SP. A Continental Cup title opens the fourth core-element slot. The cup brackets that award the Continental, World, and Club World titles remain to be implemented.
- **National Calendar Windows**: Friendlies, continental-cup windows, and the national-team **World Cup** appear on the calendar as future competition slots. National-team selection and playable national matches remain to be built. The separate club tournament is the **Club World Cup**; its bracket remains to be built.
- **Focused Training**: Select a stat and complete repeated sessions for a permanent +1. Each session costs one day and 15 energy. Training no longer grants direct XP. Level-up stat points remain freely assignable.
- **Scouting Intel Codex**: Browse eight scouting profiles at each of Street, City, Regional, National, Continental, and Club World Cup level, plus the eight selectable national teams. Only the active domestic division shows live results; other profiles are clearly unranked previews.
- **Condition & Energy Mechanics**: Energy management with fatigue penalties and coach bench warnings.
- **Procedural Fighter Roster**: Recruitable athletes develop alongside the player over successive seasons.

---

## Technical Architecture

- **Engine**: Godot Engine 4.5.1 (stable)
- **Language**: GDScript 2.0
- **Career services**:
  - `CampaignManager` (`scripts/campaign_manager.gd`, autoload): Persistent save/load, the day clock, SP progression, nationality-based recruitment, training, and match rewards.
  - `SeasonCalendar` (`scripts/season_calendar.gd`, helper class): Deterministic fixtures, dated calendar entries, results, standings, and postseason qualification.
  - `CareerCalendarPopup` (`scripts/career_calendar_popup.gd`): Seven-column month grid and explicit rest, advance, play, and skip actions.
- **Tactical services**:
  - `AbilityGeometry` (`scripts/ability_geometry.gd`): One set of tile patterns shared by the attack preview, player hits, and enemy decisions. To add a named pattern, update `shape_for` and `tiles` together.
  - `BattleTerrain` (`scripts/battle_terrain.gd`): Per-tile hazard type, remaining turns or wall health, movement cost, visibility, and elemental reactions. A form places terrain through its `terrain_kind` field in `ElementData`.
  - `ScoutingCatalog` (`scripts/scouting_catalog.gd`): Browsable team directory; live season standings come from `CampaignManager`.
- **Other autoloads**:
  - `SettingsManager` (`scripts/settings_manager.gd`): Audio and display configuration.
  - `ElementData` (`scripts/element_data.gd`): Central registry for all 72 elemental abilities and their unlockable forms.
- **Headless Test Suite**: Comprehensive automated test suites verifying multi-unit combat, skill trees, targeting shapes, save/load, and campaign loops.

The next career milestone is playable Continental and Club World Cup brackets, followed by national-team call-ups, friendlies, continental cups, and the World Cup. Transfer-window club requests and country-based club pools also remain to be built.

---

## Running the Project

1. Install **Godot 4.5.1** or later.
2. Clone this repository:
   ```bash
   git clone https://github.com/Xiorrus/elemental-showdown.git
   ```
3. Open Godot Engine and import the `project.godot` file.
4. Press **F5** to run the Main Menu.

### Running Automated Verification Tests

Run all headless suites from PowerShell. The runner gives every suite a temporary Godot profile under `.godot`, so verification cannot change your campaign or settings:

```powershell
.\scripts\run_tests.ps1 -GodotPath 'C:\path\to\Godot_v4.5.1-stable_win64.exe'
```

Pass `-Tests test_element_data.gd,test_combat_regressions.gd` to run only those suites. The script exits with a failure code if a suite fails or times out.

### Capturing Screenshots

Use the capture launcher for the canonical 1920×1080 screens. It also isolates the campaign save, which matters because some screenshot fixtures unlock skill forms:

```powershell
.\scripts\run_capture.ps1 -GodotPath 'C:\path\to\Godot_v4.5.1-stable_win64.exe' -Screen main_menu
```

Omit `-Screen` to capture every screen. PNGs are written to `screenshots/new_ui` in this checkout.
