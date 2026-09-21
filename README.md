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

### 2. 72-Skill Progression Tree with 3 Forms Each
- Every skill features **3 distinct forms** modifying range, damage multiplier, MP cost, and targeting area (Cardinal, Linear Front, Radial).
- **Progressive Unlock**: Unlocking any skill automatically grants Form 1 for free; Forms 2 and 3 can be unlocked by investing Skill Points (SP).
- **Mid-Combat Form Switching**: Freely switch active skill forms during your tactical combat turn (`F` hotkey, HUD cycle button, or right-click).

### 3. Tactical Squad Combat (1v1, 3v3, 5v5)
- **Direct Manual Squad Control**: Directly command captain and squadmates on an isometric grid.
- **Substitution System**: Bench reserves ready to swap into battle when formatted for team matches.
- **Dynamic Targeting & Status System**: Status effects including Burn, Stun, Corrode, Freeze, and Blind.

### 4. Campaign & Athlete Management
- **Tournament Schedule**: Ladder progression against rival teams and the enigmatic rival Zero.
- **Scouting Intel Codex**: Opponent profiles, elemental affinities, known techniques, and tactical weaknesses.
- **Condition & Energy Mechanics**: Energy management with fatigue penalties and coach bench warnings.
- **Procedural Fighter Roster**: Unique athletes across Bronze, Silver, Gold, Diamond, and Apex league tiers.

---

## Technical Architecture

- **Engine**: Godot Engine 4.5.1 (stable)
- **Language**: GDScript 2.0
- **Autoloads**:
  - `CampaignManager` (`scripts/campaign_manager.gd`): Persistent save/load, fighter progression, tournament standings.
  - `SettingsManager` (`scripts/settings_manager.gd`): Audio and display configuration.
  - `ElementData` (`scripts/element_data.gd`): Central registry for all 72 elemental abilities and 216 skill forms.
- **Headless Test Suite**: Comprehensive automated test suites verifying multi-unit combat, skill trees, targeting shapes, save/load, and campaign loops.

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

Execute tests headlessly via the Godot console:
```bash
godot_console.exe --headless -s scripts/test_skill_forms.gd
godot_console.exe --headless -s scripts/test_skill_progression.gd
godot_console.exe --headless -s scripts/test_strategy_and_stats.gd
godot_console.exe --headless -s scripts/test_multi_unit.gd
godot_console.exe --headless -s scripts/test_campaign_loop.gd
```
