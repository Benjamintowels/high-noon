class_name GroyperWeapons

enum Id {
	REVOLVER,
	MAC10,
	SHOTGUN,
	RPG,
	AWP,
	AK47,
	LASSO,
	BOW,
	SHOVEL,
	SWORD_SHIELD,
	HAMMER,
	UNARMED,
	AXE_1H,
	SWORD_1H,
	AXE_2H,
	SWORD_2H,
	HAMMER_2H,
	DYNAMITE,
	TORCH,
}

enum AmmoDisplayMode {
	CYLINDER,
	MAGAZINE,
	SLUG_TUBE,
	SINGLE_ROCKET,
	SNIPER_MAGAZINE,
	BANANA_CLIP,
	NONE,
	QUIVER,
}

enum OverworldReloadMode {
	PER_ROUND,
	MAGAZINE,
}

const GRIP_SCENES: Dictionary = {
	Id.REVOLVER: preload("res://characters/groyper/revolver_grip.tscn"),
	Id.MAC10: preload("res://characters/groyper/mac10_grip.tscn"),
	Id.SHOTGUN: preload("res://characters/groyper/shotgun_grip.tscn"),
	Id.RPG: preload("res://characters/groyper/rpg_grip.tscn"),
	Id.AWP: preload("res://characters/groyper/awp_grip.tscn"),
	Id.AK47: preload("res://characters/groyper/ak47_grip.tscn"),
	Id.LASSO: preload("res://characters/groyper/lasso_grip.tscn"),
	Id.BOW: preload("res://characters/groyper/bow_grip.tscn"),
	Id.SHOVEL: preload("res://characters/groyper/shovel_grip.tscn"),
	Id.HAMMER: preload("res://characters/smitty/equipment/hammer_grip.tscn"),
	Id.AXE_1H: preload("res://characters/baldwin/equipment/axe_1h_grip.tscn"),
}

# Unified weapon icon set (res://Assets/Weapons/WeaponIconsNew/). Each icon_*.png is a
# transparent 352x352 canvas with the sprite centered at native scale, so the relative
# sizing ratios between weapons stay consistent across the wheel, inventory and ammo HUD.
# Extra ready-to-use icons exist for weapons without an Id yet: spear,
# winchester_rifle, shuriken, kunai, claws, saber, round_shield, wooden_shield, scythe,
# short_bow.
const REVOLVER_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_revolver.png")
const MAC10_ICON := preload("res://Assets/UI/Icons/Mac10.png")
const SHOTGUN_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_shotgun.png")
const RPG_ICON := preload("res://Assets/UI/Icons/RPG.png")
const AWP_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_scoped_rifle.png")
const AK47_ICON := preload("res://Assets/UI/Icons/AK47.png")
const LASSO_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_lasso.png")
const BOW_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_recurve_bow.png")
const SHOVEL_ICON: Texture2D = preload("res://icon.svg")
const SWORD_SHIELD_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_kite_shield.png")
const HAMMER_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_warhammer.png")
const UNARMED_ICON: Texture2D = preload("res://icon.svg")
const AXE_1H_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_hatchet.png")
const SWORD_1H_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_short_sword.png")
const AXE_2H_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_battle_axe.png")
const SWORD_2H_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_great_sword.png")
const HAMMER_2H_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_warhammer.png")
const DYNAMITE_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_dynamite.png")
const TORCH_ICON := preload("res://Assets/Weapons/WeaponIconsNew/icon_spear.png")

## Base melee reach shared by the sword family. Individual melee weapons override
## this with a `melee_range` stat so hitboxes can differ per weapon.
const DEFAULT_MELEE_RANGE := 3.1

const WEAPON_STATS: Dictionary = {
	Id.REVOLVER: {
		"max_ammo": 6,
		"duel_ammo": 1,
		"shot_cooldown": 0.38,
		"full_auto": false,
		"forearm_recoil_strength": 1.0,
		"forearm_recoil_wobble_deg": 0.0,
		"reticle_recoil_kick": 14.0,
		"reticle_recoil_randomness": 0.25,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"ads_fov": 55.0,
		"handling": 26.0,
		"bloom_base_deg": 0.55,
		"bloom_shot_deg": 1.1,
		"bloom_max_deg": 5.0,
		"bloom_move_deg": 2.4,
		"effective_range": 14.0,
		"icon": REVOLVER_ICON,
		"ammo_display": AmmoDisplayMode.CYLINDER,
	},
	Id.MAC10: {
		"max_ammo": 30,
		"duel_ammo": 30,
		"shot_cooldown": 60.0 / 1000.0,
		"full_auto": true,
		"forearm_recoil_strength": 0.92,
		"forearm_recoil_wobble_deg": 18.0,
		"reticle_recoil_kick": 14.0,
		"reticle_recoil_randomness": 1.0,
		"camera_recoil_kick": 5.0,
		"aim_spread_deg": 2.6,
		"aim_spread_build_per_shot": 0.2,
		"aim_spread_max_bonus_deg": 6.0,
		"ads_fov": 60.0,
		"handling": 18.0,
		"bloom_base_deg": 1.3,
		"bloom_shot_deg": 0.45,
		"bloom_max_deg": 7.0,
		"bloom_move_deg": 2.8,
		"effective_range": 16.0,
		"icon": MAC10_ICON,
		"ammo_display": AmmoDisplayMode.MAGAZINE,
	},
	Id.SHOTGUN: {
		"two_handed": true,
		"max_ammo": 4,
		"duel_ammo": 4,
		"shot_cooldown": 0.55,
		"full_auto": false,
		"forearm_recoil_strength": 1.4,
		"forearm_recoil_wobble_deg": 24.0,
		"reticle_recoil_kick": 42.0,
		"reticle_recoil_randomness": 0.9,
		"camera_recoil_kick": 28.0,
		"camera_recoil_randomness": 0.65,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"ads_fov": 58.0,
		"handling": 6.5,
		"bloom_base_deg": 7.0,
		"bloom_shot_deg": 5.5,
		"bloom_max_deg": 15.0,
		"bloom_move_deg": 4.5,
		"ads_bloom_scale": 0.8,
		"pellet_count": 8,
		"pellet_spread_max_deg": 7.0,
		"pellet_chip_damage": 0.25,
		"pellet_falloff_start": 3.5,
		"pellet_falloff_end": 11.0,
		"pellet_max_range": 18.0,
		"effective_range": 6.0,
		"muzzle_flash_style": &"shotgun_blast",
		"reticle_style": &"circle",
		"icon": SHOTGUN_ICON,
		"ammo_display": AmmoDisplayMode.SLUG_TUBE,
	},
	Id.RPG: {
		"two_handed": true,
		"max_ammo": 1,
		"duel_ammo": 1,
		"shot_cooldown": 1.1,
		"full_auto": false,
		"forearm_recoil_strength": 1.0,
		"forearm_recoil_wobble_deg": 8.0,
		"reticle_recoil_kick": 24.0,
		"reticle_recoil_randomness": 0.35,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"ads_fov": 50.0,
		"handling": 10.0,
		"bloom_base_deg": 1.0,
		"bloom_shot_deg": 3.0,
		"bloom_max_deg": 8.0,
		"bloom_move_deg": 2.2,
		"effective_range": 40.0,
		"fire_mode": &"rpg",
		"muzzle_flash_style": &"symmetrical",
		"icon": RPG_ICON,
		"ammo_display": AmmoDisplayMode.SINGLE_ROCKET,
	},
	Id.AWP: {
		"two_handed": true,
		"max_ammo": 5,
		"duel_ammo": 5,
		"shot_cooldown": 1.15,
		"full_auto": false,
		"forearm_recoil_strength": 1.15,
		"forearm_recoil_wobble_deg": 5.0,
		"reticle_recoil_kick": 24.0,
		"reticle_recoil_randomness": 0.18,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"handling": 9.0,
		"bloom_base_deg": 1.2,
		"bloom_shot_deg": 3.2,
		"bloom_max_deg": 9.0,
		"bloom_move_deg": 3.2,
		"ads_bloom_scale": 0.0,
		"bullet_speed": 320.0,
		"bullet_scale": 1.8,
		"scope_aim": true,
		"scope_fov": 22.0,
		"scope_transition_smooth": 11.0,
		"scope_mouse_sensitivity": 0.0022,
		"scope_yaw_max_deg": 36.0,
		"scope_pitch_max_deg": 24.0,
		"effective_range": 75.0,
		"icon": AWP_ICON,
		"ammo_display": AmmoDisplayMode.SNIPER_MAGAZINE,
	},
	Id.AK47: {
		"two_handed": true,
		"max_ammo": 20,
		"duel_ammo": 20,
		"shot_cooldown": 60.0 / 300.0,
		"full_auto": true,
		"arm_driven_recoil": true,
		"fire_from_muzzle": true,
		"arm_recoil_pitch_deg": 4.2,
		"arm_recoil_yaw_jitter_deg": 1.2,
		"arm_recoil_recovery": 5.0,
		"arm_recoil_smooth": 22.0,
		"arm_recoil_max_deg": 18.0,
		"forearm_recoil_strength": 1.0,
		"forearm_recoil_wobble_deg": 0.0,
		"reticle_recoil_kick": 0.0,
		"reticle_recoil_randomness": 0.0,
		"camera_recoil_kick": 6.0,
		"camera_recoil_randomness": 0.35,
		"aim_spread_deg": 1.4,
		"aim_spread_build_per_shot": 0.28,
		"aim_spread_max_bonus_deg": 4.5,
		"aim_fov_reduction": 10.0,
		"ads_fov": 50.0,
		"handling": 16.0,
		"bloom_base_deg": 0.9,
		"bloom_shot_deg": 0.6,
		"bloom_max_deg": 6.5,
		"bloom_move_deg": 2.6,
		"effective_range": 24.0,
		"muzzle_flash_style": &"symmetrical",
		"icon": AK47_ICON,
		"ammo_display": AmmoDisplayMode.BANANA_CLIP,
	},
	Id.LASSO: {
		"max_ammo": 1,
		"duel_ammo": 1,
		"shot_cooldown": 0.2,
		"full_auto": false,
		"uses_ammo": false,
		"forearm_recoil_strength": 0.0,
		"forearm_recoil_wobble_deg": 0.0,
		"reticle_recoil_kick": 0.0,
		"reticle_recoil_randomness": 0.0,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"effective_range": 15.0,
		"fire_mode": &"lasso",
		"icon": LASSO_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
	},
	Id.BOW: {
		"two_handed": true,
		"max_ammo": 10,
		"duel_ammo": 10,
		"shot_cooldown": 0.35,
		"full_auto": false,
		"forearm_recoil_strength": 0.0,
		"forearm_recoil_wobble_deg": 0.0,
		"reticle_recoil_kick": 0.0,
		"reticle_recoil_randomness": 0.0,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"ads_fov": 52.0,
		"handling": 14.0,
		"bloom_base_deg": 0.7,
		"bloom_shot_deg": 0.9,
		"bloom_max_deg": 5.0,
		"bloom_move_deg": 2.2,
		"ads_bloom_scale": 0.3,
		"effective_range": 55.0,
		"fire_mode": &"bow",
		"icon": BOW_ICON,
		"ammo_display": AmmoDisplayMode.QUIVER,
	},
	Id.SHOVEL: {
		"two_handed": true,
		"max_ammo": 1,
		"duel_ammo": 1,
		"shot_cooldown": 0.35,
		"full_auto": false,
		"uses_ammo": false,
		"forearm_recoil_strength": 0.0,
		"forearm_recoil_wobble_deg": 0.0,
		"reticle_recoil_kick": 0.0,
		"reticle_recoil_randomness": 0.0,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"effective_range": 2.0,
		"fire_mode": &"shovel",
		"icon": SHOVEL_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
	},
	Id.SWORD_SHIELD: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"sword_shield",
		"icon": SWORD_SHIELD_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"melee_range": 3.1,
		"melee_attack_speed": 1.0,
	},
	Id.AXE_1H: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"sword_shield",
		"icon": AXE_1H_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		# Shorter reach than the sword, but swings 1.2x faster (see melee_attack_speed).
		"melee_range": 2.6,
		"melee_attack_speed": 1.2,
		# Throwable while blocking (LMB). Weight scales throw speed against the
		# player's throw strength; later it will gate what can be thrown at all.
		"throw_weight": 2.0,
	},
	Id.SWORD_1H: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"sword_shield",
		"icon": SWORD_1H_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		# Longest reach of the one-handed melee weapons, standard swing speed.
		"melee_range": 3.3,
		"melee_attack_speed": 1.0,
	},
	# Two-handed melee weapons: longer reach, slower swings, and 2 damage. They
	# share a dedicated two-handed hand mount + animation set (fire_mode below).
	Id.AXE_2H: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"two_hand_melee",
		"icon": AXE_2H_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"melee_range": 3.4,
		"melee_attack_speed": 0.9,
		"melee_damage": 2,
	},
	Id.SWORD_2H: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"two_hand_melee",
		"icon": SWORD_2H_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"melee_range": 3.8,
		"melee_attack_speed": 0.95,
		"melee_damage": 2,
	},
	Id.HAMMER_2H: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"two_hand_melee",
		"icon": HAMMER_2H_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"melee_range": 3.3,
		"melee_attack_speed": 0.8,
		# Direct hammer contact is 1 damage; the strike also detonates a ground
		# slam AOE (TwoHandHammerSlam) for another 1 damage + large knockback.
		"melee_damage": 1,
	},
	Id.HAMMER: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 0.85,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"hammer",
		"icon": HAMMER_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"effective_range": 2.2,
	},
	Id.UNARMED: {
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"unarmed",
		"icon": UNARMED_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"effective_range": 1.95,
	},
	Id.DYNAMITE: {
		# Consumable sticks tracked via inventory stack count (pickup grants 5).
		"max_ammo": 5,
		"duel_ammo": 0,
		"shot_cooldown": 0.35,
		"full_auto": false,
		"uses_ammo": true,
		"fire_mode": &"dynamite",
		"icon": DYNAMITE_ICON,
		"ammo_display": AmmoDisplayMode.MAGAZINE,
		"throw_weight": 1.5,
		"blast_damage": 3,
		"blast_radius": 7.5,
		"fuse_duration": 3.0,
	},
	Id.TORCH: {
		# Handheld light — right-hand only, no holster. Slashing reuses the
		# sword-slash anim but never chains into a combo. RMB braces like
		# dynamite, then LMB pitches the torch (pickable after landing).
		"max_ammo": 0,
		"duel_ammo": 0,
		"shot_cooldown": 999.0,
		"full_auto": false,
		"uses_ammo": false,
		"fire_mode": &"torch",
		"icon": TORCH_ICON,
		"ammo_display": AmmoDisplayMode.NONE,
		"melee_range": 2.8,
		"melee_attack_speed": 1.05,
		"melee_damage": 1,
		"throw_weight": 1.25,
	},
}

const DEFAULT_WEAPON := Id.REVOLVER

const STARTING_WEAPON := Id.REVOLVER

const HOLSTER_GRIP_NAME := &"RevolverGrip"
## Former shared firearm grip-root rotation. Hand/holster overwrite the grip
## root at runtime (identity / holster seat); FPS viewmodel still needs this
## so zeroing grip.tscn roots does not spin the first-person gun.
const FPS_GRIP_ROOT := Transform3D(
	Basis(
		Vector3(-0.034951694, 0.06833395, -0.9970501),
		Vector3(-0.8903003, -0.455374, 2.937568e-11),
		Vector3(-0.45403063, 0.88767385, 0.076753825)
	),
	Vector3.ZERO
)
const HOLSTER_GRIP_LOCAL := Transform3D(
	Basis(
		Vector3(0.035, 0.0, -0.999),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.999, 0.0, 0.035)
	),
	Vector3(0.13, -0.22, 0.08)
)
const SHOTGUN_BACK_HOLSTER_GRIP_LOCAL := Transform3D(
	Basis(
		Vector3(0.999, 0.0, 0.035),
		Vector3(0.0, 1.0, 0.0),
		Vector3(-0.035, 0.0, 0.999)
	),
	Vector3(0.0, -0.05, 0.02)
)
const SHOVEL_BACK_HOLSTER_GRIP_LOCAL := Transform3D(
	Basis(
		Vector3(0.0, 0.0, 1.0),
		Vector3(0.0, 1.0, 0.0),
		Vector3(-1.0, 0.0, 0.0)
	),
	Vector3(0.0, 0.08, -0.04)
)


static func get_grip_scene(weapon_id: Id) -> PackedScene:
	return GRIP_SCENES.get(weapon_id, GRIP_SCENES[Id.REVOLVER]) as PackedScene


static func get_starting_weapon() -> Id:
	return STARTING_WEAPON


static func get_enemy_weapon() -> Id:
	return DEFAULT_WEAPON


static func get_stats(weapon_id: Id) -> Dictionary:
	return WEAPON_STATS.get(weapon_id, WEAPON_STATS[Id.REVOLVER])


## All registered weapons for debug spawn UIs. Skips UNARMED; new Id+stats rows appear automatically.
static func get_debug_spawn_weapon_ids() -> Array[int]:
	var ids: Array[int] = []
	for weapon_id in WEAPON_STATS.keys():
		if int(weapon_id) == Id.UNARMED:
			continue
		ids.append(int(weapon_id))
	ids.sort()
	return ids


static func get_max_ammo(weapon_id: Id) -> int:
	return int(get_stats(weapon_id).get("max_ammo", 6))


static func get_duel_ammo(weapon_id: Id) -> int:
	return int(get_stats(weapon_id).get("duel_ammo", 1))


static func get_shot_cooldown(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("shot_cooldown", 0.38))


static func is_full_auto(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("full_auto", false))


static func get_icon(weapon_id: Id) -> Texture2D:
	return get_stats(weapon_id).get("icon", REVOLVER_ICON) as Texture2D


static func get_ammo_display_mode(weapon_id: Id) -> AmmoDisplayMode:
	return int(get_stats(weapon_id).get("ammo_display", AmmoDisplayMode.CYLINDER)) as AmmoDisplayMode


static func get_pellet_count(weapon_id: Id) -> int:
	return int(get_stats(weapon_id).get("pellet_count", 1))


static func get_pellet_spread_max_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("pellet_spread_max_deg", 7.0))


static func get_pellet_chip_damage(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("pellet_chip_damage", 0.25))


static func get_pellet_max_range(weapon_id: Id) -> float:
	var stats := get_stats(weapon_id)
	return float(stats.get("pellet_max_range", stats.get("effective_range", 14.0) * 2.5))


## Chip damage for one pellet at the given travel distance. Full chip inside
## falloff_start, then drops off hard toward falloff_end.
static func pellet_chip_at_distance(weapon_id: Id, distance: float) -> float:
	var stats := get_stats(weapon_id)
	var base := float(stats.get("pellet_chip_damage", 0.25))
	var start := float(stats.get("pellet_falloff_start", 3.5))
	var end := float(stats.get("pellet_falloff_end", 11.0))
	if distance <= start:
		return base
	if distance >= end:
		return base * 0.04
	var t := (distance - start) / maxf(end - start, 0.001)
	# Quadratic falloff — pellets go soft past mid range.
	return base * lerpf(1.0, 0.04, t * t)


static func get_reticle_style(weapon_id: Id) -> StringName:
	return StringName(str(get_stats(weapon_id).get("reticle_style", "ticks")))


## Even ring of unit offsets in the plane perpendicular to `base_direction`.
static func get_shotgun_pellet_offsets(base_direction: Vector3, pellet_count: int) -> Array[Vector3]:
	var offsets: Array[Vector3] = []
	var forward := base_direction.normalized()
	var right := forward.cross(Vector3.UP)
	if right.length_squared() < 0.0001:
		right = forward.cross(Vector3.RIGHT)
	right = right.normalized()
	var up := right.cross(forward).normalized()
	var count := maxi(pellet_count, 1)
	for i in count:
		var angle := TAU * float(i) / float(count)
		var ring := randf_range(0.45, 1.0)
		offsets.append((right * cos(angle) + up * sin(angle)) * ring)
	return offsets


static func get_muzzle_flash_style(weapon_id: Id) -> StringName:
	return StringName(str(get_stats(weapon_id).get("muzzle_flash_style", "default")))


static func is_rpg(weapon_id: Id) -> bool:
	return String(get_stats(weapon_id).get("fire_mode", "")) == "rpg"


static func is_dynamite(weapon_id: Id) -> bool:
	return weapon_id == Id.DYNAMITE or get_fire_mode(weapon_id) == &"dynamite"


static func is_torch(weapon_id: Id) -> bool:
	return weapon_id == Id.TORCH or get_fire_mode(weapon_id) == &"torch"


## True for weapons that swing with the sword-slash melee system (includes the
## torch, which has no holster and never combos).
static func uses_melee_slash(weapon_id: Id) -> bool:
	return is_melee(weapon_id) or is_torch(weapon_id)


static func is_lasso(weapon_id: Id) -> bool:
	return String(get_stats(weapon_id).get("fire_mode", "")) == "lasso"


static func is_bow(weapon_id: Id) -> bool:
	return String(get_stats(weapon_id).get("fire_mode", "")) == "bow"


static func is_shovel(weapon_id: Id) -> bool:
	return String(get_stats(weapon_id).get("fire_mode", "")) == "shovel"


static func is_sword_shield(weapon_id: Id) -> bool:
	return weapon_id == Id.SWORD_SHIELD


## True for every weapon that drives the shared sword-slash melee combat system
## (SWORD_SHIELD, the one-handed stylized weapons, and the two-handed weapons).
static func is_melee(weapon_id: Id) -> bool:
	return (
		weapon_id == Id.SWORD_SHIELD
		or weapon_id == Id.AXE_1H
		or weapon_id == Id.SWORD_1H
		or is_two_handed_melee(weapon_id)
	)


## Weapons with their own sprint+LMB attack. Anything else falls back to the
## unarmed flying kick while sprinting. Torch is intentionally excluded (slash
## only, no spin); guns/lasso/bow/dynamite/unarmed use the kick default.
static func has_sprint_attack(weapon_id: Id) -> bool:
	return is_melee(weapon_id)


## Two-handed stylized melee weapons. They reuse the melee state machine but with
## their own hand mount, holster mounts, animation set, and 2 damage.
static func is_two_handed_melee(weapon_id: Id) -> bool:
	return get_fire_mode(weapon_id) == &"two_hand_melee"


## Bladed melee weapons (swords and axes) leave slash-arc visuals; the two-handed
## hammer is blunt and relies on impact FX instead.
static func is_bladed_melee(weapon_id: Id) -> bool:
	return is_melee(weapon_id) and weapon_id != Id.HAMMER_2H


## Only the sword & shield loadout carries a shield mesh; the stylized one-handed
## weapons reuse the shield animations without an actual shield in hand.
static func melee_uses_shield(weapon_id: Id) -> bool:
	return weapon_id == Id.SWORD_SHIELD


## Direct melee strike damage. Two-handed blades hit for 2; the two-handed
## hammer hits for 1 plus its ground-slam AOE; everything else hits for 1.
static func get_melee_damage(weapon_id: Id) -> int:
	return int(get_stats(weapon_id).get("melee_damage", 1))


## Weapons with a throw_weight stat can be hurled while blocking. The weight is
## measured against the player's throw strength for projectile speed (and later,
## for whether the player is strong enough to throw the item at all).
static func is_throwable(weapon_id: Id) -> bool:
	return get_stats(weapon_id).has("throw_weight")


static func get_throw_weight(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("throw_weight", 1.0))


static func get_melee_range(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("melee_range", DEFAULT_MELEE_RANGE))


static func get_melee_attack_speed(weapon_id: Id) -> float:
	return maxf(float(get_stats(weapon_id).get("melee_attack_speed", 1.0)), 0.05)


static func is_hammer(weapon_id: Id) -> bool:
	return weapon_id == Id.HAMMER


static func is_unarmed(weapon_id: Id) -> bool:
	return weapon_id == Id.UNARMED


static func uses_ammo(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("uses_ammo", true))


static func get_fire_mode(weapon_id: Id) -> StringName:
	return StringName(str(get_stats(weapon_id).get("fire_mode", "bullet")))


static func has_scope_aim(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("scope_aim", false))


static func get_scope_fov(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("scope_fov", 30.0))


static func get_scope_transition_smooth(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("scope_transition_smooth", 10.0))


static func get_scope_mouse_sensitivity(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("scope_mouse_sensitivity", 0.0022))


static func get_scope_yaw_max_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("scope_yaw_max_deg", 36.0))


static func get_scope_pitch_max_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("scope_pitch_max_deg", 24.0))


static func get_aim_fov_reduction(weapon_id: Id, default_reduction: float = 4.0) -> float:
	return float(get_stats(weapon_id).get("aim_fov_reduction", default_reduction))


## Bullet/rocket firearms drive the run-and-gun overworld controller: always
## drawn while equipped, centered bloom crosshair, RMB = per-gun ADS zoom.
## Lasso/shovel keep their bespoke draw behaviors; the RecurveBow joins via
## uses_run_and_gun() while keeping fire_mode &"bow".
static func is_firearm(weapon_id: Id) -> bool:
	var mode := get_fire_mode(weapon_id)
	return mode == &"bullet" or mode == &"rpg"


## Shared hip-fire / ADS overworld controller (always drawn + bloom reticle + RMB zoom).
static func uses_run_and_gun(weapon_id: Id) -> bool:
	return is_firearm(weapon_id) or is_bow(weapon_id)


## Camera FOV while holding RMB (ADS). Scoped weapons (AWP) use scope_fov instead.
static func get_ads_fov(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("ads_fov", 55.0))


## Bloom recovery speed in degrees/second — the "gun handling" stat.
static func get_handling(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("handling", 16.0))


## Resting crosshair spread half-angle while standing still (degrees).
static func get_bloom_base_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bloom_base_deg", 0.8))


## Bloom added per shot — the gun's default recoil bloom stat (degrees).
static func get_bloom_shot_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bloom_shot_deg", 1.0))


static func get_bloom_max_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bloom_max_deg", 6.0))


## Extra spread at full sprint speed (degrees, scaled by velocity fraction).
static func get_bloom_move_deg(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bloom_move_deg", 2.5))


## Bloom multiplier while ADS (tighter spread when zoomed).
static func get_ads_bloom_scale(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("ads_bloom_scale", 0.35))


## Per-shot camera kick. Falls back to the reticle kick stat (same px-ish units,
## converted to degrees by the player).
static func get_camera_recoil_kick(weapon_id: Id) -> float:
	var stats := get_stats(weapon_id)
	return float(stats.get("camera_recoil_kick", stats.get("reticle_recoil_kick", 14.0)))


## Horizontal jitter fraction for camera kick. Fully-random reticle kicks (e.g.
## MAC10) are clamped so the camera doesn't wander sideways.
static func get_camera_recoil_randomness(weapon_id: Id) -> float:
	var stats := get_stats(weapon_id)
	var fallback := minf(float(stats.get("reticle_recoil_randomness", 0.18)), 0.6)
	return float(stats.get("camera_recoil_randomness", fallback))


static func is_two_handed(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("two_handed", false))


static func uses_muzzle_aim(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("fire_from_muzzle", false))


static func get_bullet_speed(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bullet_speed", -1.0))


static func get_bullet_scale(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bullet_scale", 1.0))


static func get_effective_range(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("effective_range", 14.0))


static func get_overworld_reload_mode(weapon_id: Id) -> OverworldReloadMode:
	match weapon_id:
		Id.REVOLVER, Id.SHOTGUN:
			return OverworldReloadMode.PER_ROUND
		_:
			return OverworldReloadMode.MAGAZINE


static func uses_per_round_overworld_reload(weapon_id: Id) -> bool:
	return get_overworld_reload_mode(weapon_id) == OverworldReloadMode.PER_ROUND


static func uses_back_holster(weapon_id: Id) -> bool:
	return (
		weapon_id == Id.MAC10
		or weapon_id == Id.SHOTGUN
		or weapon_id == Id.AWP
		or weapon_id == Id.BOW
		or weapon_id == Id.SHOVEL
	)


## Skeleton BoneAttachment3D name for this weapon's holster socket.
## Bespoke mounts (Mac10/AK/RPG/Shotgun/AWP) can be tuned via HolsterOffset in the editor.
static func holster_mount_name(weapon_id: Id) -> StringName:
	match weapon_id:
		Id.MAC10:
			return &"Mac10HolsterMount"
		Id.AK47:
			return &"Ak47HolsterMount"
		Id.RPG:
			return &"RpgHolsterMount"
		Id.SHOTGUN:
			return &"ShotgunHolsterMount"
		Id.AWP:
			return &"AwpHolsterMount"
		Id.REVOLVER:
			return &"HipHolsterMount"
		Id.BOW, Id.SHOVEL:
			return &"BackHolsterMount"
		_:
			return &"HipHolsterMount" if not uses_back_holster(weapon_id) else &"BackHolsterMount"


## Weapons with dedicated holster mounts (not the shared hip/back sockets).
static func has_bespoke_holster_mount(weapon_id: Id) -> bool:
	return weapon_id in [Id.MAC10, Id.AK47, Id.RPG, Id.SHOTGUN, Id.AWP]


## Skeleton BoneAttachment3D name for this weapon's hand socket.
## Bespoke mounts (Mac10/AK/RPG/Shotgun/AWP/Bow) can be tuned via GripOffset in the editor.
static func hand_mount_name(weapon_id: Id) -> StringName:
	match weapon_id:
		Id.MAC10:
			return &"Mac10HandMount"
		Id.AK47:
			return &"Ak47HandMount"
		Id.RPG:
			return &"RpgHandMount"
		Id.SHOTGUN:
			return &"ShotgunHandMount"
		Id.AWP:
			return &"AwpHandMount"
		Id.BOW:
			return &"BowHandMount"
		_:
			return &"HandRevolverMount"


## Weapons with dedicated hand mounts (not the shared HandRevolverMount).
static func has_bespoke_hand_mount(weapon_id: Id) -> bool:
	return weapon_id in [Id.MAC10, Id.AK47, Id.RPG, Id.SHOTGUN, Id.AWP, Id.BOW]


static func get_holster_grip_local(weapon_id: Id) -> Transform3D:
	if weapon_id == Id.SHOVEL:
		return SHOVEL_BACK_HOLSTER_GRIP_LOCAL
	if uses_back_holster(weapon_id):
		return SHOTGUN_BACK_HOLSTER_GRIP_LOCAL
	return HOLSTER_GRIP_LOCAL


static func install_holster_grip(holster_socket: Node3D, weapon_id: Id) -> Node3D:
	var existing := holster_socket.get_node_or_null(NodePath(str(HOLSTER_GRIP_NAME))) as Node3D
	var holster_local := existing.transform if existing != null else get_holster_grip_local(weapon_id)
	if existing != null:
		existing.queue_free()

	var grip := get_grip_scene(weapon_id).instantiate() as Node3D
	holster_socket.add_child(grip)
	grip.name = HOLSTER_GRIP_NAME
	grip.transform = holster_local
	return grip


static func install_fps_grip(viewmodel: Node3D, weapon_id: Id) -> Node3D:
	var existing := viewmodel.get_node_or_null(NodePath(str(HOLSTER_GRIP_NAME))) as Node3D
	if existing != null:
		existing.queue_free()

	var grip := get_grip_scene(weapon_id).instantiate() as Node3D
	viewmodel.add_child(grip)
	grip.name = HOLSTER_GRIP_NAME
	grip.transform = FPS_GRIP_ROOT
	return grip
