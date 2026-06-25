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
| `fire_mode` | `&"rpg"` triggers rocket launcher path |
| `muzzle_flash_style` | `default`, `symmetrical`, or `epic_explosion` |
| `ammo_display` | HUD widget (see below) |

For local testing, set `STARTING_WEAPON`. Enemies always use `DEFAULT_WEAPON` (revolver).

## 2. Create a grip scene

Copy an existing grip, e.g. `characters/groyper/mac10_grip.tscn`:

- Root node **must** be named `RevolverGrip` (holster rig expects this name)
- Instance your gun FBX under the root
- Add a `Muzzle` **Marker3D** on the barrel (`unique_name_in_owner = true`)
- Tune the FBX transform so it sits correctly in the hand

Holster install is automatic via `GroyperWeapons.install_holster_grip()` / `install_fps_grip()`.

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

1. Set `STARTING_WEAPON` to your new `Id`
2. Run a duel scene
3. Check draw/holster, muzzle flash, ammo HUD, duel hit, and replay if applicable

## File map

```
characters/groyper/groyper_weapons.gd   # registry + stats
characters/groyper/*_grip.tscn          # one scene per gun
characters/groyper/groyper_player.gd    # firing + duel hooks
gameplay/shooting/bullet.gd             # default projectile
gameplay/shooting/rpg_rocket.gd         # explosive projectile example
ui/scripts/ammo_hud.gd                  # HUD switching
```
