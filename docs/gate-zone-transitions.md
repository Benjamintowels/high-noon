# Gate / zone-transition glitches — field guide

Lessons from wiring the Hotel ↔ Canyon ↔ Church ↔ Town gates
(`gameplay/world/canyon_gate_transition.gd` + `stages/stage1/stage1.gd`).
Read this before adding a gate or debugging "X stopped working after walking
through a gate."

## How the system works (30 seconds)

- `CanyonGateTransition` owns a list of `GateBinding`s. Each gate is an
  `Area3D` trigger with a zone/title/look-marker declared for BOTH sides
  (`add_gate(trigger, inner_zone, inner_title, inner_look_name, outer_zone,
  outer_title, outer_look_name)`).
- Crossing a trigger runs the letterbox cinematic, then `_apply_zone_state`
  asks `StageZoneCuller` to swap the heavy stage roots (`Town`, `Canyon`,
  `Church`...) so only the destination zone draws and simulates.
- Dynamic actors do NOT live under those culled roots — they live in sibling
  hosts at the stage root (`CanyonBandits`, `TownActors`) that the transition
  toggles with plain `visible` + `process_mode` only.
- Travel direction comes from player velocity vs. the inner→outer look-marker
  axis; zone-at-spawn comes from `_detect_zone` (nearest gate marker heuristic).

## Glitch catalog

### 1. NPCs/actors don't come back after a zone swap (but static stuff does)

**Symptom:** buildings load, birds fly, but CharacterBody3D NPCs are missing
or inert after re-entering a zone.

**Cause:** the actors were parented under a `StageZoneCuller`-managed root.
The culler force-toggles every `CollisionShape3D`/`Area3D` it finds, which
breaks CharacterBody3D actors across toggles (frozen bodies, dead triggers).
Birds survive because they're visual-only — that asymmetry is the tell.

**Fix:** runtime-spawned life goes in a dedicated host node at the STAGE ROOT
(`TownActors`, `CanyonBandits`), never under the culled zone root. The gate
transition toggles only `visible` and `process_mode` on that host. If you add
a new zone with dynamic actors, add a new host and mirror the handling in
`CanyonGateTransition._apply_zone_state`. Spawn helpers must know about the
host too (see `TownNpcSpawn._get_spawn_host`).

### 2. NPCs fall through the floor after arriving in a far zone

**Symptom:** actors in the destination zone are at y≈-28 (or plummeting) when
you arrive; a downward raycast at their spawn point hits nothing.

**Cause:** `Terrain3D` dynamic collision only generates ground within
`collision_radius` (was 64 m) of the CAMERA. Actors more than that from the
player have no floor. `AmbientAiFreezer` unfreezes NPCs at 100 m — so an NPC
can resume physics while standing on nothing.

**Fix:** `Terrain3D.collision_mode = 3` (FULL_GAME) in `stage1.tscn` builds
collision for the whole terrain at boot. If that's ever too expensive, the
alternative is keeping the freezer radius safely INSIDE the collision radius.

### 3. Sounds keep playing from unloaded/hidden things

**Symptom:** a loop (fire crackle etc.) plays at full volume everywhere,
never attenuating, after loading in.

**Causes, in order of likelihood:**
- An `AudioStreamPlayer3D` with `autoplay = true` riding ON THE PLAYER
  (e.g. the holstered hand torch's fire scene). Hiding a node does NOT stop
  its audio — the loop follows the listener at ~3 m forever. This masquerades
  as "the bonfire I loaded next to never fades."
- Fires/emitters in a culled zone: `PROCESS_MODE_DISABLED` pauses processing
  but already-playing `AudioStreamPlayer3D`s keep sounding.

**Fix:** the emitter script must gate playback on `is_visible_in_tree()` and
react to `visibility_changed` (see `torch_fire.gd::_sync_flame_audio`). When
debugging, dump ALL playing players of the suspect stream with their distance
to the camera — the one that stays at ~3 m across teleports is attached to
the player.

### 4. Wrong ambience/state at spawn or after transition (day/night)

**Symptom:** bird chorus at Dawn, lamps wrong, etc. Gate transitions advance
the day/night phase, so these show up right after walking a gate.

**Cause:** consumer used the wrong phase predicate. `is_night_time()` is
Night ONLY; Dawn/Dusk are dark but not "night".

**Fix:** use `DayNightCycle.is_dark_time()` (everything except full Day) for
"does the world look dark" decisions — ambient soundscape, bird roosting.
Keep paired systems (ambience + visible birds) on the SAME predicate or they
desync.

### 5. Gate trigger dead because it lives under a culled root

**Symptom:** a gate works leaving a zone but never fires coming back.

**Cause:** the trigger `Area3D` sits under a root that `StageZoneCuller`
disabled — a disabled Area3D detects nothing, so you can never re-enter.

**Fix:** a gate between zones A and B must remain live in BOTH zone states.
Either place it at the stage root, or ensure the culler keeps whichever root
it lives under active in both states (the Church↔Town gate lives under
`Church`, which stays resident for that reason). After adding a gate, test
BOTH directions.

### 6. Player enters the wrong way / transition direction flips

**Symptom:** walking out of a zone plays the "entering" cinematic.

**Cause:** direction is `player.velocity · (inner_look − outer_look)`. If the
look markers are missing, fallbacks are synthesized at fixed local offsets —
fine for detection but the axis may not match the doorway. If velocity is
near zero (spawned inside trigger), it falls back to "not currently in inner
zone".

**Fix:** author both look `Marker3D`s as children of the trigger, placed on
their respective sides of the gate. Don't rely on the fallbacks for a real
gate.

## Checklist for adding a new gate

1. Author the trigger `Area3D` + two look `Marker3D`s (one per side) in the
   scene; parent under a root that stays alive in both zone states.
2. Register with `add_gate(...)` in `stage1.gd`, both sides fully declared.
3. If the new zone has dynamic actors: stage-root host node, spawns routed
   into it, toggle wired in `_apply_zone_state`.
4. Confirm terrain collision exists where actors live (full collision mode,
   or actors inside the dynamic radius).
5. Verify headlessly: teleport across the gate both ways, assert NPC y-values
   stay grounded, actors visible/processing in destination zone, hidden in
   the other. Listen (or probe playing `AudioStreamPlayer3D`s) for loops that
   survive the swap.
