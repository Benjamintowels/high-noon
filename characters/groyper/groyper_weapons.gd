class_name GroyperWeapons

enum Id {
	REVOLVER,
	MAC10,
	SHOTGUN,
	RPG,
	AWP,
	AK47,
}

enum AmmoDisplayMode {
	CYLINDER,
	MAGAZINE,
	SLUG_TUBE,
	SINGLE_ROCKET,
	SNIPER_MAGAZINE,
	BANANA_CLIP,
}

const GRIP_SCENES: Dictionary = {
	Id.REVOLVER: preload("res://characters/groyper/revolver_grip.tscn"),
	Id.MAC10: preload("res://characters/groyper/mac10_grip.tscn"),
	Id.SHOTGUN: preload("res://characters/groyper/shotgun_grip.tscn"),
	Id.RPG: preload("res://characters/groyper/rpg_grip.tscn"),
	Id.AWP: preload("res://characters/groyper/awp_grip.tscn"),
	Id.AK47: preload("res://characters/groyper/ak47_grip.tscn"),
}

const REVOLVER_ICON := preload("res://Assets/UI/Icons/256x256/wester_icon_revolver_01.png")
const MAC10_ICON := preload("res://Assets/UI/Icons/Mac10.png")
const SHOTGUN_ICON := preload("res://Assets/UI/Icons/Shotgun.png")
const RPG_ICON := preload("res://Assets/UI/Icons/RPG.png")
const AWP_ICON := preload("res://Assets/UI/Icons/AWP.png")
const AK47_ICON := preload("res://Assets/UI/Icons/AK47.png")

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
		"aim_spread_deg": 2.6,
		"aim_spread_build_per_shot": 0.2,
		"aim_spread_max_bonus_deg": 6.0,
		"icon": MAC10_ICON,
		"ammo_display": AmmoDisplayMode.MAGAZINE,
	},
	Id.SHOTGUN: {
		"two_handed": true,
		"max_ammo": 4,
		"duel_ammo": 4,
		"shot_cooldown": 0.5,
		"full_auto": false,
		"forearm_recoil_strength": 1.0,
		"forearm_recoil_wobble_deg": 10.0,
		"reticle_recoil_kick": 18.0,
		"reticle_recoil_randomness": 0.65,
		"aim_spread_deg": 0.0,
		"aim_spread_build_per_shot": 0.0,
		"aim_spread_max_bonus_deg": 0.0,
		"pellet_count": 6,
		"pellet_spread_max_deg": 14.0,
		"pellet_spread_distance": 22.0,
		"muzzle_flash_style": &"epic_explosion",
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
		"bullet_speed": 320.0,
		"bullet_scale": 1.8,
		"scope_aim": true,
		"scope_fov": 22.0,
		"scope_transition_smooth": 11.0,
		"scope_mouse_sensitivity": 0.0022,
		"scope_yaw_max_deg": 36.0,
		"scope_pitch_max_deg": 24.0,
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
		"aim_spread_deg": 1.4,
		"aim_spread_build_per_shot": 0.28,
		"aim_spread_max_bonus_deg": 4.5,
		"aim_fov_reduction": 10.0,
		"muzzle_flash_style": &"symmetrical",
		"icon": AK47_ICON,
		"ammo_display": AmmoDisplayMode.BANANA_CLIP,
	},
}

const DEFAULT_WEAPON := Id.REVOLVER

## Set while testing one-handed weapons; revolver remains the intended default loadout.
const STARTING_WEAPON := Id.AK47

const HOLSTER_GRIP_NAME := &"RevolverGrip"
const HOLSTER_GRIP_LOCAL := Transform3D(
	Basis(
		Vector3(0.035, 0.0, -0.999),
		Vector3(0.0, 1.0, 0.0),
		Vector3(0.999, 0.0, 0.035)
	),
	Vector3(0.13, -0.22, 0.08)
)


static func get_grip_scene(weapon_id: Id) -> PackedScene:
	return GRIP_SCENES.get(weapon_id, GRIP_SCENES[Id.REVOLVER]) as PackedScene


static func get_starting_weapon() -> Id:
	return STARTING_WEAPON


static func get_enemy_weapon() -> Id:
	return DEFAULT_WEAPON


static func get_stats(weapon_id: Id) -> Dictionary:
	return WEAPON_STATS.get(weapon_id, WEAPON_STATS[Id.REVOLVER])


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


static func get_muzzle_flash_style(weapon_id: Id) -> StringName:
	return StringName(str(get_stats(weapon_id).get("muzzle_flash_style", "default")))


static func is_rpg(weapon_id: Id) -> bool:
	return String(get_stats(weapon_id).get("fire_mode", "")) == "rpg"


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


static func is_two_handed(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("two_handed", false))


static func uses_muzzle_aim(weapon_id: Id) -> bool:
	return bool(get_stats(weapon_id).get("fire_from_muzzle", false))


static func get_bullet_speed(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bullet_speed", -1.0))


static func get_bullet_scale(weapon_id: Id) -> float:
	return float(get_stats(weapon_id).get("bullet_scale", 1.0))


static func install_holster_grip(holster_socket: Node3D, weapon_id: Id) -> Node3D:
	var existing := holster_socket.get_node_or_null(NodePath(str(HOLSTER_GRIP_NAME))) as Node3D
	var holster_local := existing.transform if existing != null else HOLSTER_GRIP_LOCAL
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
	return grip
