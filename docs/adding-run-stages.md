# Adding a roguelike run stage

Roguelike runs never write `adventure_save.json`. Hub progress (bank, zone
completions, weapon chest, inventory) is written to `user://roguelike_save.json`
via `RoguelikeSave` whenever the hub loads (and after extract).

## Checklist

1. **Register the zone** in [`autoload/run_state.gd`](../autoload/run_state.gd):
   - Add an entry to `ZONES` (`path` + `title`).
   - Add `ZONE_UNLOCK_REQUIREMENTS` (empty string = always open; usually `"zone_1"` after Dry Gulch).

2. **Create a stage config**:
   - Copy / extend [`stages/runs/configs/dry_gulch_config.tres`](../stages/runs/configs/dry_gulch_config.tres).
   - Or build one in code via `RunStageConfig.make_dry_gulch()`-style factories in [`gameplay/runs/run_stage_config.gd`](../gameplay/runs/run_stage_config.gd).
   - Tune: `wave_groups` (themed encounter pools and/or legacy timed drip), or legacy `enemy_pool`, modifier pool, boss scene, difficulty ramp, loot mult, run aggro ranges, chest/prop counts and cost curves.
   - **Encounter areas (Dry Gulch):** set `use_encounter_areas = true`. Each themed `wave_groups` entry is keyed by `id` (`outskirts`, `bank`, …) with `drip_enabled = false`. Pack size scales with difficulty; elites/reinforce use the encounter thresholds. With `use_difficulty_tiers`, weapon/HP come from `RunEnemyTier` (scene is faction skin only).
   - **Tier profile:** `tier_profile = &"dry_gulch"` = bandits only — regulars stay **unarmed melee** (tier only scales toughness); elites carry shotgun then Winchester (~4m). In runs, only elites drop weapons. No gun-armor / bullet reflect (`disable_enemy_gun_armor = true`). Other zones use `&"default"` (full ladder incl. armored).
   - **Alive cap (Dry Gulch):** `max_alive_base = 15` + `max_alive_per_minute = 3` (hard ceiling `max_alive_enemies = 40`). Other stages use the same ladder formula.
   - **Kill goal:** `kill_goal = 50` shows `Enemies X/50` on the raid HUD and opens the extract portal at 50 kills (player may stay; waves continue). Victory extract marks the zone complete via `completed_runs`; defeating the boss sets `hub_quest_flags["zone_1_boss_defeated"]` (subquest) via `RunState.has_defeated_zone_boss`.
   - **Hybrid drip:** with encounter areas, also set `hybrid_drip_enabled = true` and add roaming groups with `drip_enabled = true`. Cadence starts at `hybrid_drip_interval_seconds` and tightens with run time; `hybrid_drip_max_per_tick` grows every 2 minutes.
   - **Hybrid drip budgets:** set `hybrid_drip_budgets` (e.g. Dry Gulch `[8, 12, 16, 20, 24, 28]` — one entry per encounter area). Remaining starts at 0. Walking into an encounter `Trigger` stacks that area’s budget (FIFO per area); drip enemies spawn on the **inside** of that area’s `GateWall` (toward the pocket), or at an optional child `DripSpawn` Marker3D. When remaining hits 0, drip stops so the player can explore. Empty array = uncapped drip. Order = child order under `RunEncounterAreas`.
   - **Legacy drip only:** leave `use_encounter_areas` false. All wavegroups drip by `unlock_time` / `base_spawn_interval`; elites on `elite_interval`.

3. **Create the zone scene** (copy `zone_1.tscn`):
   - Root: `run_zone.gd` + matching `zone_id`.
   - `PlayerSpawn`, `Sun`, `WorldEnvironment`, `FadeLayer/FadeOverlay`.
   - Optional `Terrain/Terrain3D` pointing at a zone data dir (e.g. `stages/runs/terrain/<name>/data`). Reuses stage1 desert material/assets; `run_zone.gd` imports a flat floor until you sculpt and save regions.
   - `Enemies` in group `cave_enemy_root` (spawn host for the director).
   - **Encounter areas (preferred):** `RunEncounterAreas` with `Marker3D` children using [`run_encounter_area.gd`](../gameplay/runs/run_encounter_area.gd). Set `area_id` to match a `wave_groups` id, add a child `Trigger` `Area3D` + `CollisionShape3D` (preferred; resize/move in-editor — falls back to `trigger_radius` if missing), child `Spawn*` Marker3Ds (**one immediate enemy per marker** — add `SpawnE` for a 5th; only names starting with `Spawn` count), optional `DripSpawn` Marker3D to hand-place budget drip spawns, a child `Chest` Marker3D for the kill-gated loot chest, and a child `GateWall` ([`encounter_gate_wall.tscn`](../gameplay/runs/encounter_gate_wall.tscn)) that blocks the path until the pocket is cleared (then sinks into the ground). Place `Trigger` volumes on the approach / far side of each GateWall so players cannot walk past without firing the pocket. Move the roots in-editor to place fights. Group: `run_encounter_area`.
   - Optional legacy: `cave_enemy_spawn` markers under `Enemies` (wave 0 only when not using encounter areas / wavegroups).
   - Child `RunDirector` (`run_director.gd`) with your stage config.
   - `BossTowerSpots` with **3** `Marker3D` children (director picks one).
   - `RunLootSpots/Props` — designer `Marker3D` candidates for destructibles. `RunLootDirector` picks `prop_count` and procedurally fills if short.
   - **Chests:** with `use_encounter_areas`, no start-of-run chest scatter. Each encounter spawns one free chest at its `Chest` marker when the pack triggers; it unlocks when that pack is cleared (random gun). Legacy stages without encounter areas still use `RunLootSpots/Chests` + `chest_count`.
   - `ReturnPortal` (`run_gate.gd`, `destination = HUB`, `gate_enabled = false`).
   - Optional `ReturnPortalVisual` gate mesh (hidden until boss dies).

4. **Hub gate**:
   - Under `Hubworld/RunGates`, add visual + `Area3D` with `run_gate.gd`.
   - Set `zone_id`, `WalkTarget`, `ReturnSpawn`.
   - Locked gates auto-block until their requirement is won this session.

5. **Boss**:
   - Set `boss_scene` on the config (Dry Gulch uses Chief Getcha).
   - Bosses used in runs should support `start_as_run_boss(player)` / `run_boss_mode` so Story Mode quests are not written.

## Runtime flow

```
Hub gate (if unlocked) → deposit hub cash to bank → run wallet 0/0
  → zone loads → wait physics frames (Terrain3D collision) → RunDirector.begin_run
  → loot scatter (props; chests only on legacy non-encounter stages)
  → encounter packs on area entry (+ kill-gated chest) + optional hybrid drip
     (or legacy: wavegroups / wave 0 near-player drip only)
  → player faction = RUN (all combat factions hostile, incl. Sheriff)
  → kill HUD ticks toward kill_goal (if set) → portal opens at goal (optional extract)
  → difficulty / tiers rise → modifiers → denser packs / elites
  → Boss Tower interact → summon boss (subquest; optional)
  → boss defeated → portal opens if not already open; hub flag on victory extract
  → walk portal OR death → RunResultsScreen (half currency on death)
  → bank extract → hub fade-in
```

## Run hostility

While `RunState.run_active`, the overworld player reports `FactionIds.RUN`. Every combat faction is hostile to `RUN` (see `faction_affinity.gd`). `RunDirector` also arms spawns via `arm_canyon_hostility` / `set_faction_aggro_level(3)` / `force_alert_to_player` so town NPCs don't idle in Story Mode AI.

## Currency / extract

- Entering a run deposits current inventory gram/shards into `RunMetaProgress` bank, then zeros the run wallet.
- Victory extracts full remaining wallet; death extracts half (animated red slash on results UI).
- Quest items in `RunState.run_quest_items` extract on victory only (`RunMetaProgress.hub_quest_flags`).
- Zone clear vs boss subquest: victory extract (kill-goal or post-boss portal) appends `completed_runs` with `victory: true`. Boss kill sets `RunState.run_boss_defeated_this_run`; on victory extract that becomes `hub_quest_flags["<zone_id>_boss_defeated"]` for hub events (`RunState.has_defeated_zone_boss`).
- Weapons: death strips all carried weapons (starting revolver restored). Victory prompts to keep **one** weapon; the rest are lost. Store keepers in the hub weapon chest (`gameplay/world/hub_weapon_chest.gd`) so they persist on the roguelike save.

## Editor testing (F6)

- **Zone + current save:** open `stages/runs/zone_1.tscn` (or any `zone_*.tscn`) and **F6 / Play Scene**. Loads `user://roguelike_save.json` when present, deposits wallet to bank, then starts the run — same inventory/meta as Continue → hub → gate.
- **Hub + current save:** F6 `stages/hubworld/hubworld.tscn`, then walk the gate.
- No save file → fresh session (same as New Game). Extract/death still write the save.

## Related systems

- Hub bank / XP / weapon stash: `autoload/run_meta_progress.gd`
- Roguelike disk save: `autoload/roguelike_save.gd`
- Results UI: `ui/scripts/run_results_screen.gd`
- Victory weapon pick: `ui/scripts/run_weapon_extract_menu.gd`
- Loot director / chests / props: `gameplay/runs/run_loot_*.gd`
- Timed run buff pickup (stub): `gameplay/runs/run_powerup_pickup.gd`
