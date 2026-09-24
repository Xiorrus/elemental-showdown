# E2E Test Infra: Elemental Showdown Competition & Combat

## Test Philosophy
- Opaque-box, requirement-driven testing executing Godot 4.5.1 stable headlessly.
- Multi-tier testing methodology: Category-Partition, Boundary Value Analysis, Pairwise Combinations, and End-to-End Career Workloads.
- No reliance on hidden internals; assertions verify contracts, public APIs, output states, and game boundaries.

## Test Runner Architecture
- **Engine**: Godot 4.5.1 stable (`D:\USB\Games\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe`)
- **Master Test Runner**: `.\scripts\run_tests.ps1 -GodotPath 'D:\USB\Games\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe'`
- **Headless Execution Command**:
  ```powershell
  & "D:\USB\Games\Godot_v4.5.1-stable_win64.exe\Godot_v4.5.1-stable_win64_console.exe" --headless -s scripts/<test_file>.gd
  ```
- **Exit Code Semantics**: Exit code 0 indicates all assertions passed cleanly. Non-zero indicates assertion failure or parse/runtime error.

## Test Directory & Suite Layout
```
scripts/
  test_match_rules.gd          (Tier 1/2: MatchRules & CompetitionRuleBook validation & presets)
  test_series_state.gd         (Tier 1/2/3: SeriesState recording, duplicate rejection, clinch logic)
  test_match_scheduling.gd     (Tier 1/2/3: Season calendar dates 199/202/205 & 210-223, W25 national window)
  test_force_movement.gd       (Tier 1/2/3: Step-by-step push, wall/unit collisions, 12 damage, 1-stagger)
  test_combat_intents.gd       (Tier 1/2/3: Telegraphed windup=1, danger tiles, interrupt conditions)
  test_reaction_rules.gd       (Tier 1/2/3: Guard/Counter/Intercept/Overwatch priority, resource costs)
  test_fighter_generation.gd   (Regression: athlete individuality and generation rules)
  test_campaign_loop.gd        (Tier 4: Career progression, promotions, training, hub flow)
  test_campaign_regressions.gd (Tier 4: Save/load integrity, migration, multi-unit combat)
  test_multi_campaign_saves.gd (Tier 4: Multi-profile save boundaries and schema stability)
```

## Coverage Tiers & Goals
- **Tier 1 - Feature Coverage**: Direct unit and contract tests verifying each preset, domain class, and resolver in isolation.
- **Tier 2 - Boundary & Corner Cases**: Edge cases including 0 remaining games, clinch at minimum games (2-0 Bo3, 3-0 Bo5), full 5-game series (3-2), tied knockout matches hitting 12-round limit and advancing to overtime/judge decision, collision at corner boundaries, multi-target pushes with intermediate obstacles, and duplicate game ID replay prevention.
- **Tier 3 - Cross-Feature Combinations**: Pairwise testing between force movement + elemental primers, telegraphed attacks + displacement interruption, and reaction orders (Overwatch -> Intercept -> Guard -> Counter) during complex team turns.
- **Tier 4 - Real-World Application Scenarios**: Complete full-season career loop simulations:
  - Scenario 1: City Championship 3v3 Bo3 series played to clinch (2-0), verifying Game 3 cancellation.
  - Scenario 2: City Championship 3v3 Bo3 series tied (1-1), playing Game 3 decider.
  - Scenario 3: National Championship Semifinal into 5v5 National Final (Bo5) with roster readiness milestone and emergency loan verification.
  - Scenario 4: Skipping a series game forfeits ONLY that single game, advances the calendar, and awards 0 played rewards.
  - Scenario 5: Legacy save migration (v1 to v2) seamlessly loads prior career and continues into series competition.
