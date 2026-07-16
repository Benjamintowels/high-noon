# Adding a roguelike run stage

Roguelike runs never write `adventure_save.json`. Session unlocks live in `RunState`.

## Checklist

1. **Register the zone** in [`autoload/run_state.gd`](../autoload/run_state.gd):
   - Add an entry to `ZONES` (`path` + `title`).
   - Add `ZONE_UNLOCK_REQUIREMENTS` (empty string = always open; usually `"zone_1"` after Dry Gulch).

2. **Create a stage config**:
   - Copy / extend [`stages/runs/configs/dry_gulch_config.tres`](../stages/runs/configs/dry_gulch_config.tres).
   - Or build one in code via `RunStageConfig.make_dry_gulch()`-style factories in [`gameplay/runs/run_stage_config.gd`](../gameplay/runs/run_stage_config.gd).
   - Tune: `wave_groups` (timed faction schedule + elites), or legacy `enemy_pool`, modifier pool, boss scene, difficulty ramp, spawn annulus, loot mult, run aggro ranges, chest/prop counts and cost curves.
   - Dry Gulch wavegroups: Bandits (Sheriff elite) → Engines (×2 shotgun Engine elite) → Redos (Pavel elite) → all factions. Elites every 30s with ×3 HP/loot vs that group's regulars; base spawn rate bumps each 30s; next group unlocks each 60s.

3. **Create the zone scene** (copy `zone_1.tscn`):
   - Root: `run_zone.gd` + matching `zone_id`.
   - `PlayerSpawn`, `Sun`, `WorldEnvironment`, `FadeLayer/FadeOverlay`.
   - Optional `Terrain/Terrain3D` pointing at a zone data dir (e.g. `stages/runs/terrain/<name>/data`). Reuses stage1 desert material/assets; `run_zone.gd` imports a flat floor until you sculpt and save regions.
   - `Enemies` in group `cave_enemy_root` with `cave_enemy_spawn` markers (wave 0).
   - Child `RunDirector` (`run_director.gd`) with your stage config.
   - `BossTowerSpots` with **3** `Marker3D` children (director picks one).
   - `RunLootSpots/Chests` + `RunLootSpots/Props` — designer `Marker3D` candidates for chests/destructibles. `RunLootDirector` picks `chest_count` / `prop_count` and procedurally fills if short.
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
  → loot scatter (chests + props) + wavegroups / wave 0
  → player faction = RUN (all combat factions hostile, incl. Sheriff)
  → difficulty rises → modifiers roll → near-player spawns
  → Boss Tower interact → summon boss
  → boss defeated → ReturnPortal opens
  → walk portal OR death → RunResultsScreen (half currency on death)
  → bank extract → hub fade-in
```

## Run hostility

While `RunState.run_active`, the overworld player reports `FactionIds.RUN`. Every combat faction is hostile to `RUN` (see `faction_affinity.gd`). `RunDirector` also arms spawns via `arm_canyon_hostility` / `set_faction_aggro_level(3)` / `force_alert_to_player` so town NPCs don't idle in Story Mode AI.

## Currency / extract

- Entering a run deposits current inventory gram/shards into `RunMetaProgress` bank, then zeros the run wallet.
- Victory extracts full remaining wallet; death extracts half (animated red slash on results UI).
- Quest items in `RunState.run_quest_items` extract on victory only (`RunMetaProgress.hub_quest_flags`).

## Related systems

- Hub bank / XP: `autoload/run_meta_progress.gd`
- Results UI: `ui/scripts/run_results_screen.gd`
- Loot director / chests / props: `gameplay/runs/run_loot_*.gd`
- Timed run buff pickup (stub): `gameplay/runs/run_powerup_pickup.gd`
