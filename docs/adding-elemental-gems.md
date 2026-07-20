# Adding an Elemental Gem

Checklist for a new embeddable gem (Lightning / Fire / Ice today). Inventory, stamina HUD, armory spawn, and trail dust are mostly catalog-driven; **combat behavior is per-gem**.

## Mental model

```
Catalog (elemental_gems.gd)
  → free gems in PlayerInventory.owned_elemental_gems
  → embed onto a weapon TYPE (weapon_embedded_gems keyed by weapon id)
  → ElementalGemStamina gates “effect active” per weapon type
  → Trail dust color from first active embedded gem
  → On hit: each gem combat module’s try_proc_on_hit (lightning then fire then ice…)
```

- Embeddings are **per weapon type** (same collapse as inventory), not per instance.
- Default slot count: `GroyperWeapons.get_gem_slots()` → **1**.
- Stamina is **gem-agnostic**: any embedded gem drains/refills the same bar.
- Pickup visual: `gameplay/world/elemental_gem_pickup.gd` (Gem_Model + catalog tint).

## Existing gems

| Id | Color | Combat module | Behavior sketch |
|----|-------|---------------|-----------------|
| `lightning` | yellow | `gameplay/combat/lightning_gem_combat.gd` | ×1.15 attack speed; 100% root bolt on hit + chain arcs; electrify flash + stun; strike VFX |
| `fire` | red-orange | `gameplay/combat/fire_gem_combat.gd` | 100% ignite → `on_fire_status.gd` (10s, 0.2 chip/s, 1.8m spread); panic-run for non-bosses |
| `ice` | cyan | `gameplay/combat/ice_gem_combat.gd` | chill stacks (0.65× → 0.40×); 3rd hit freezes non-bosses into pushable ice block; slide shatter 1 dmg |

## Gem stamina (shared)

`gameplay/combat/elemental_gem_stamina.gd`

| Constant | Default | Meaning |
|----------|---------|---------|
| `DRAIN_PER_ATTACK` | 0.08 | Per shot / swing / punch |
| `COOLDOWN_SEC` | 10 | Empty → wait before recharge |
| `RECHARGE_SEC` | 6 | 0 → full after cooldown |

Phases: `ACTIVE` → drain → `COOLING` (bar empty, effects off) → `RECHARGING` → `ACTIVE`.

Effects must gate on **both**:

```gdscript
PlayerInventory.weapon_has_gem(weapon_id, ElementalGems.YOUR_GEM)
and ElementalGemStamina.is_effect_active(weapon_id)
```

Player hooks (already wired — do not re-add):

- Tick + HUD: `groyper_overworld_player.gd` `_process` → `tick` / `_sync_gem_stamina_hud`
- Drain: `_try_shoot`, bow fire, melee attack start, punch
- HUD bar: `ui/scripts/ammo_hud.gd` → `sync_gem_stamina(visible, ratio, color)`

## Trail / swing dust (shared)

`gameplay/fx/elemental_attack_fx.gd`

- `get_active_trail_gem(weapon_id)` → first embedded **active** gem with stamina
- `weapon_has_elemental_trail` / `get_trail_color` → used by weapon rig, bullets, pellets, melee swing dust

New gem colors automatically tint trails once the gem is in the catalog and embedded. No trail edits required unless you need a special particle look.

## On-hit wiring (must add your proc)

Shared pattern at each site: resolve combatant (hitbox → `CharacterBody3D` / `apply_fire_damage` host), then call every gem module:

| File | Helper |
|------|--------|
| `gameplay/shooting/bullet.gd` | `_try_elemental_procs` |
| `gameplay/shooting/shotgun_pellet.gd` | same |
| `gameplay/shooting/arrow_projectile.gd` | same (`weapon_id=-1` → resolve from shooter) |
| `gameplay/combat/melee_punch.gd` | after strike (`UNARMED`) |
| `gameplay/combat/melee_sword_slash.gd` | after strike |

**When adding a gem:** preload its combat script and call `try_proc_on_hit` next to lightning/fire in those five places.

Hitbox gotcha: NPCs often take damage on `GroyperHitbox.apply_bullet_hit` — procs must resolve the actor, not stop at the hitbox.

## Armory / inventory (usually free)

- Armory loops `ElementalGems.get_active_gem_ids()` → **Spawn \<Name\>** buttons (`debug_spawn_terminal.gd`). Set `"active": true` and it appears.
- Inventory attach/swap/remove is gem-agnostic (`inventory_menu.gd` + `PlayerInventory.assign_gem_to_weapon`).
- Optional test helpers (fire crates, townsperson group) are armory-only; add only if the gem needs special targets.

---

## Checklist: new gem

### 1. Catalog

`gameplay/items/elemental_gems.gd`:

```gdscript
const ICE := &"ice"

# in GEMS:
ICE: {
	"name": "Ice Gem",
	"color": Color(0.45, 0.85, 1.0, 1.0),
	"active": true,
},
```

### 2. Combat module

New file e.g. `gameplay/combat/ice_gem_combat.gd` (`extends RefCounted`, preload style, no `class_name`):

```gdscript
static func try_proc_on_hit(shooter: Node, target: Node, weapon_id: int = -1) -> void:
	# 1) shooter is overworld_player / player
	# 2) resolve weapon_id from shooter._equipped_weapon if < 0
	# 3) weapon_has_gem(..., ICE) + ElementalGemStamina.is_effect_active
	# 4) eligibility (not self/player/allies; has receive_bullet_hit or your prop API)
	# 5) apply effect
```

Mirror gates from `fire_gem_combat.gd` / `lightning_gem_combat.gd`. Keep status/DoT/VFX in a sibling module if it gets large (see `on_fire_status.gd`).

Speed mult: only if intentional — Lightning owns `get_speed_mult`; don’t reuse it blindly.

### 3. Wire on-hit

In all five call sites above, add:

```gdscript
IceGemCombat.try_proc_on_hit(shooter, target, weapon_id)
```

### 4. FX / status (as needed)

- One-shot hit VFX: follow `gameplay/fx/lightning_strike_fx.gd` or `fire_wave_fx.gd` (AnimatedSprite3D + `FxFramesLoader.FILTER_3D` nearest + modulate tint).
- Register frame dirs in `gameplay/fx/fx_catalog.gd` + `warm_all()` if reused often.
- Persistent status: child node on host (like `OnFireStatus`); clear panic/meta in `_exit_tree`.
- NPC AI reactions: prefer a small helper + early-return in town/melee FSMs; skip bosses via `BossGunResilience.uses_boss_hud_poise` (`tc_boss` / `chief_getcha_boss`).

### 5. Props (only if the gem should burn/break/freeze objects)

- Prefer `apply_fire_damage`-style methods or `fire_burn` / your flag on `hit_info`.
- `run_loot_prop.gd` / wood `breakable_prop.gd` are the flammable precedents.
- Skip blood/knockback for pure status ticks (`skip_knockback`, skip `BloodSplatter` like lightning/fire).

### 6. Verify in armory

1. Spawn gem → inventory embed on equipped weapon  
2. Confirm gem stamina bar color + drain on fire  
3. Spawn Townsperson Group (and any prop helpers)  
4. Confirm trail color, on-hit effect, stamina empty → effects stop → 10s → recharge  

---

## File map

| Role | Path |
|------|------|
| Catalog | `gameplay/items/elemental_gems.gd` |
| Inventory / embed | `autoload/player_inventory.gd` |
| Stamina | `gameplay/combat/elemental_gem_stamina.gd` |
| Trail dust | `gameplay/fx/elemental_attack_fx.gd` |
| Lightning combat | `gameplay/combat/lightning_gem_combat.gd` |
| Fire combat | `gameplay/combat/fire_gem_combat.gd` |
| Fire status / panic | `gameplay/combat/on_fire_status.gd`, `on_fire_panic.gd` |
| Pickup | `gameplay/world/elemental_gem_pickup.gd` |
| Ammo HUD bar | `ui/scripts/ammo_hud.gd`, `ui/scenes/ammo_hud.tscn` |
| Armory spawns | `gameplay/debug/debug_spawn_terminal.gd` |
| Inventory UI | `ui/scripts/inventory_menu.gd` |

## Gotchas

- **Hitboxes:** always resolve to the combatant before `try_proc_on_hit`.
- **Stamina:** effects off during cooldown *and* recharge until full again.
- **One gem per weapon type slot** by default — design around that (or raise `get_gem_slots`).
- **Bosses:** fire panic explicitly excludes them; new AI reactions should do the same unless intended.
- Prefer `const X := preload(...)` over new `class_name` for combat helpers (headless / cache friendliness).
