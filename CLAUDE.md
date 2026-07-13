# High Noon — project guide

Godot 4.6 (Forward Plus, Jolt physics, D3D12) western action game. Main scene: `stages/stage1/stage1.tscn` — boots straight into the overworld (no menu bootstrap). ~480 GDScript files.

## Folder map

- `characters/` — one folder per character. Pattern per character: `*_actor.gd` (CharacterBody3D base: rig binding, knockback/stun timers), `*_npc.gd` / `*_player.gd` (behavior), `*_rig.gd`, `*_anim_config.gd` (animation clip paths/settings), `*_anim_utils.gd`. Also contains one-off pose-extraction/bake CLI scripts (`*_extract*.gd`, `*_baker.gd`) that are tooling, not runtime code.
- `autoload/` — ~26 singletons registered in project.godot (quests/progress, save, inventory, UI hosts). `ShopSession` is the one autoload living elsewhere (`gameplay/world/shop_session.gd`).
- `gameplay/` — shared systems: `combat/` (knockback, melee clash, projectiles), `shooting/`, `duel/`, `navigation/`, `world/` (doors, interior slots, culling), `fx/`, `faction/`, `scenarios/`. NOTE: `target/` (range scoring) and `targets/` (fence props) are different dirs.
- `stages/` — `stage1/` is the overworld (one big scene, `stage1.gd` spawns most dynamic content against hardcoded node paths), `caves/` dungeon, `baldwin_melee_test/` dev stage.
- `ui/` — scenes/scripts/theme. `Assets/` (capital A) — raw art/models. `demo/` — Terrain3D sample content, NOT game code; ignore hits from searches there.
- `tools/` — bake/validate/capture dev scripts (has `.gdignore` so Godot skips them).

## Naming gotchas

- `characters/sheriff/sheriff_npc.gd` is the SHERIFF (a stripped fork of `groyper_town_npc.gd`, `class_name TownNpc`). `characters/uncle_toad/uncle_toad_civilian_npc.gd` is UNCLE TOAD (`class_name CivilianNpc`). Class names are still generic even though filenames aren't.
- The "Engines" NPC lives in `characters/fast/` (`engines_npc.gd` extends FastTownNpc).
- Player scripts are still FORKS, not a hierarchy: `groyper_overworld_player.gd` (~8.8k lines, overworld), `groyper_player.gd` (duel mode), `groyper_duelist.gd` (duel enemy). Reticle/scope/recoil is now SHARED via `characters/groyper/player_reticle_state.gd` — fix aim feel there, not in the players. Other shared-looking code may still need fixes in more than one file.
- The overworld player delegates to sibling modules (house pattern: `RefCounted`, no class_name, methods take the player as untyped `p`): `groyper_overworld_anim_builder.gd` (run-once AnimationTree/library construction), `player_lasso_swing_state.gd` / `player_ladder_state.gd` / `player_climb_fall_state.gd` (traversal FSMs). Blend-node refs written by the builder stay on the player.
- Melee NPCs (pavel, redo, undead, tc, chief_getcha) share `characters/npc_melee_combatant.gd` (damage plumbing, `_find_player`, facing/movement helpers, hitbox debug; per-character tuning via `_get_max_health()`-style getters). Their per-class melee FSM (`_process_attacking` etc.) is STILL duplicated — a fix in one FSM probably belongs in all; grep before declaring done. TC and Chief Getcha keep intentional overrides (rage/FX) — don't "deduplicate" those into the base.

## Character facing (Meshy rigs) — load-bearing

Imported Meshy FBX rigs bind facing **-Z**; the visual `Model` node needs a **PI yaw offset**.

- Town NPCs / AI (root does not rotate, only `Model` turns): use `GroyperBodyUtils.MODEL_YAW_OFFSET` and `GroyperBodyUtils.facing_yaw_for_direction(dir)` (Sheriff/Meshy NPCs: `MeshyLocomotionUtils` equivalents). Plain `atan2(dir.x, dir.z)` faces them BACKWARD.
- Overworld player is the EXCEPTION (camera pivot owns yaw): movement facing is raw `atan2(move_dir.x, move_dir.z)`; `facing_yaw_for_direction()` double-applies PI and flips him.
- `groyper_body.tscn` already 180°-flips the `Body` node — never add a `Skeleton3D` transform on top (double flip, and it leaks into ALL animation clips).
- Horses: `Facing.rotation.y` = plain `atan2`; no PI.
- NPC root nodes must keep IDENTITY rotation in scenes and at spawn — facing code assigns world-space yaw to `_model` without compensating for root rotation. Rotate the model/markers, never the CharacterBody3D root. Spawn markers set the root; the Model child still needs `MODEL_YAW_OFFSET` afterward. Overworld player spawns: apply marker rotation to root, then call `sync_overworld_spawn_orientation()`.

## Conventions

- Reference scripts via `const XScript := preload(...)` rather than relying on `class_name` globals (new class_names aren't resolvable headless until the editor rescans).
- Animate `PoseOffset` (identity) nodes, not `GripOffset`, for weapon poses — AnimationTree blends node tracks from identity.
- Interiors lazy-load via `gameplay/world/interior_zone_slot.gd` (`ensure_loaded()` instantiates the exported PackedScene as a child named "Interior"; `unload()` frees). Doors drive it (`gameplay/world/shop_door.gd`). If a door unloads the interior, that must be the door's LAST act — an awaited fade tween dies with the freed node (black screen).
- `.tscn` files carry non-standard `unique_id=` node attributes; the editor re-adds them, omitting them in hand-written scenes is fine.
- Save system: `autoload/adventure_save.gd` → single JSON `user://adventure_save.json`. Quest/progress autoloads extend `autoload/quest_state_base.gd`, join the `"quest_state"` group, and self-save/reset — a new quest only needs a new autoload overriding `get_save_key()` / `get_save_fields()` (+ `get_display_name()` for the journal). No AdventureSave or journal-UI edits. Gotcha: group membership lands at tree-enter, so UI created by an earlier autoload's `_ready` must `call_deferred` its group iteration.
- NPC actor bases: Meshy biped NPCs share `characters/meshy_biped_actor.gd` (rig binding, stun/knockback timers, locomotion audio); per-character `*_actor.gd` files are thin subclasses overriding `_get_rig_root_name()` and optional hooks. Groyper-family characters use `characters/groyper/groyper_actor.gd` instead.

## Running / verifying headlessly

- Engine exe at project root: `Godot_v4.6.1-stable_win64.exe`. It's a GUI-subsystem app — from PowerShell use `Start-Process -Wait -NoNewWindow -RedirectStandardOutput/-RedirectStandardError` to files, then read the files (direct invocation captures nothing).
- Verify with MainLoop scripts: `extends SceneTree`, run `--headless --path . --script res://_tmp_test_x.gd`. The script must live under `res://`. Signal pass/fail via `quit(exit_code)`. Delete `_tmp_*` files (and `.uid`) after.
- Headless `_process` is UNCAPPED while physics stays 60Hz — gate timing-sensitive stages on `Engine.get_physics_frames()`, never `_process` counts.
- Autoload singletons DO auto-install in `--script` runs (4.6.1 with `--path`); guard any manual install with `root.has_node(name)` or you get duplicates. The test script itself still can't use autoload global identifiers — use `root.get_node("Name")`. Don't `preload` product scripts that reference autoload globals in the test-script header — `load()` them inside `_initialize()`.
- After renaming/moving/deleting a script that has a `class_name`, run `--headless --import` once — the stale `.godot/global_script_class_cache.cfg` otherwise fails loads with "Class X hides a global script class".
- Booting the FULL main scene headless crashes in the dummy renderer (pre-existing). Full-boot verification needs a real windowed run (godot-mcp: `run_project` → `get_debug_output` → `stop_project`; pull output before the game closes).

## Docs

- `docs/adding-weapons.md` — weapon-adding checklist.
