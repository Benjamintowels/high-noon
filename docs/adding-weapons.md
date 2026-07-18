# Adding a New Gun

Short checklist for one-handed Groyper weapons. Most guns only need data + a grip scene; special behavior needs a small hook in `groyper_player.gd`.

## 1. Register the weapon

Edit `characters/groyper/groyper_weapons.gd`:

1. Add a value to `enum Id`
2. Add the grip scene to `GRIP_SCENES`
3. Add a row to `WEAPON_STATS` (ammo, cooldown, recoil, icon, `ammo_display`, etc.)
4. Preload an icon texture

Useful stat keys:

| Key | Purpose |
|-----|---------|
| `max_ammo` / `duel_ammo` | Magazine size (duel usually uses low ammo) |
| `shot_cooldown` | Seconds between shots |
| `full_auto` | Hold to fire (Mac10) |
| `forearm_recoil_*` / `reticle_recoil_*` / `aim_spread_*` | Feel tuning |
| `pellet_count` | `> 1` triggers shotgun-style spread |
| `pellet_spread_max_deg` / `pellet_chip_damage` | Cone half-angle + chip HP per pellet (0.25 → 4 pellets = 1 HP) |
| `pellet_falloff_start` / `pellet_falloff_end` | Distance where pellet chip stays full, then drops hard |
| `reticle_style` | `ticks` (default) or `circle` (shotgun bloom ring) |
| `fire_mode` | `&"rpg"` triggers rocket launcher path |
| `muzzle_flash_style` | `default`, `symmetrical`, `epic_explosion`, or `shotgun_blast` (triangle fan) |
| `ammo_display` | HUD widget (see below) |

For local testing, set `STARTING_WEAPON`. Enemies always use `DEFAULT_WEAPON` (revolver).

## 2. Create a grip scene

Copy an existing grip, e.g. `characters/groyper/mac10_grip.tscn`:

- Root node **must** be named `RevolverGrip` (holster rig expects this name)
- Instance your gun FBX under the root
- Add a `Muzzle` **Marker3D** on the barrel (`unique_name_in_owner = true`)
- Tune the FBX transform so it sits correctly in the hand
- **Two-handed firearms** (`two_handed: true` in stats): also add a `SupportHand`
  **Marker3D** on the foregrip — overworld/duel left-arm IK aims here. Shared arm
  rests live in `TwoHandAim/neutral` (hip) and `TwoHandAim/ads` (see
  `characters/groyper/TWO_HAND_AIM_AUTHORING.md` — body aim library contract:
  any Meshy gun-family body needs `HipFireAim` / `TwoHandAim` / `BowAim`;
  callers use `GroyperWeaponRig.sync_run_and_gun_aim_mode`)

Holster install is automatic via `GroyperWeapons.install_holster_grip()` / `install_fps_grip()`.

Long guns that shouldn't share the default hip/back sockets need a bespoke
`characters/groyper/<weapon>_holster_mount.tscn` (`BoneAttachment3D` → `HolsterOffset`
→ grip), an entry in `GroyperWeapons.holster_mount_name()`, and registration in
`GroyperBodyUtils.ensure_firearm_holster_mounts()` / `sync_firearm_holsters()`.
Tune placement on `HolsterOffset` in `groyper_body.tscn` (or the mount scene).

Long guns that need a custom in-hand seat also get a bespoke
`characters/groyper/<weapon>_hand_mount.tscn`
(`BoneAttachment3D` → `GripOffset` → `PoseOffset` → grip preview), an entry in
`GroyperWeapons.hand_mount_name()`, and registration in
`GroyperBodyUtils.ensure_firearm_hand_mounts()`. Firearm `*_grip.tscn` roots
stay **identity**; runtime attaches under `PoseOffset` at identity. Tune
**`GripOffset`** only (packed mount scene is source of truth — avoid conflicting
body overrides). Making the mount visible in `groyper_body` auto-previews
`TwoHandAim/neutral`. Revolver / one-handers use shared `HandRevolverMount`.

## 3. Pick how it fires

`_fire_shot()` in `groyper_player.gd` branches like this:

| Weapon type | How it's detected | What happens |
|-------------|-------------------|--------------|
| **Default hitscan / bullet** | No special flags | Duel: instant ray hit on reticle. Non-duel: spawns `bullet.tscn` from muzzle toward aim point |
| **Shotgun** | `pellet_count > 1` | Multiple pellets with spread (`shotgun_pellet.tscn` or duel ray batch) |
| **RPG** | `fire_mode == "rpg"` | Spawns `rpg_rocket.tscn`; ground splash + AOE via `blast_damage.gd` |

A normal pistol/rifle/SMG only needs stats — no new fire code.

For a **new fire mode** (grenade, laser, etc.):

1. Add a stat flag in `WEAPON_STATS` (e.g. `fire_mode: &"grenade"`)
2. Add a helper like `GroyperWeapons.is_grenade()`
3. Branch early in `_fire_shot()` and call your spawn function
4. Put projectile logic in `gameplay/shooting/`

## 4. Ammo HUD

Pick an existing `AmmoDisplayMode` in stats:

- `CYLINDER` — revolver drum
- `MAGAZINE` — vertical bullet stack
- `SLUG_TUBE` — shotgun tube
- `SINGLE_ROCKET` — one rocket icon

New HUD style: add enum value, display scene/script under `ui/`, wire `ammo_hud.gd` `configure_for_weapon()` + `sync_rounds()`.

## 5. Duel / replay notes

- Duel hits use the **camera reticle ray** (`get_aim_ray_origin()` + `get_aim_direction()`), not muzzle-to-ground
- Visual shot beam still starts at the **muzzle**
- RPG records launch + impact separately for replay (`duel_rpg_launched`, `duel_shot_fired`)
- Grip-specific visuals (e.g. rocket on launcher) live in `groyper_player.gd` sync helpers

## 6. Quick test

1. Register the weapon in `groyper_weapons.gd` (enum + stats + grip) — it appears in the debug chest automatically
2. F6 / run `res://stages/armory_test/armory_test.tscn`
3. `[E]` the debug chest → pick your weapon from the grid (drops a pickup; non-droppable IDs grant + equip)
4. Shoot the far wall for bullet holes; use the terminal to spawn Engines/bandits/melee foes (auto-aggro) for combat hits
5. Optional: set `STARTING_WEAPON` and run a duel scene for duel/replay checks

## File map

```
characters/groyper/groyper_weapons.gd   # registry + stats
characters/groyper/*_grip.tscn          # one scene per gun
characters/groyper/*_holster_mount.tscn # optional bespoke holster seats
characters/groyper/*_hand_mount.tscn    # optional bespoke in-hand seats
characters/groyper/groyper_player.gd    # firing + duel hooks
gameplay/shooting/bullet.gd             # default projectile
gameplay/shooting/rpg_rocket.gd         # explosive projectile example
ui/scripts/ammo_hud.gd                  # HUD switching
stages/armory_test/armory_test.tscn     # debug armory sandbox
gameplay/debug/debug_weapon_chest.tscn  # reusable all-weapons chest
```
