extends RefCounted
class_name BaldwinBodyUtils

const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const SWORD_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_grip.tscn")
const SHIELD_GRIP_SCENE := preload("res://characters/baldwin/equipment/shield_grip.tscn")
const AXE_1H_GRIP_SCENE := preload("res://characters/baldwin/equipment/axe_1h_grip.tscn")
const SWORD_1H_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_1h_grip.tscn")
const AXE_2H_GRIP_SCENE := preload("res://characters/baldwin/equipment/axe_2h_grip.tscn")
const SWORD_2H_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_2h_grip.tscn")
const HAMMER_2H_GRIP_SCENE := preload("res://characters/baldwin/equipment/hammer_2h_grip.tscn")

const SWORD_GRIP_NAME := &"SwordGrip"
const SHIELD_GRIP_NAME := &"ShieldGrip"
## Marks which weapon a mounted sword-slot grip belongs to, so we can swap the
## mesh when the player switches between different melee weapons.
const MELEE_WEAPON_META := &"melee_weapon_id"

const SWORD_HOLSTER_LOCAL := Transform3D(
	Basis(Vector3(0.035, 0.0, -0.999), Vector3(0.0, 1.0, 0.0), Vector3(0.999, 0.0, 0.035)),
	Vector3(0.13, -0.22, 0.08)
)
const SHIELD_HOLSTER_LOCAL := Transform3D(
	Basis(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0)),
	Vector3(-0.12, -0.18, 0.06)
)

## Hand grip transform used by the sword & shield loadout (matches BaldwinWeaponRig).
const SWORD_HAND_GRIP_LOCAL := Transform3D(
	Basis(Vector3(0.8480808, 0.0, 0.0), Vector3(0.0, 0.69858235, 0.0), Vector3(0.0, 0.0, 0.4493401)),
	Vector3(0.011335179, 0.038125873, 0.066636376)
)


static func melee_grip_scene_for(weapon_id: int) -> PackedScene:
	match weapon_id:
		GroyperWeaponsScript.Id.AXE_1H:
			return AXE_1H_GRIP_SCENE
		GroyperWeaponsScript.Id.SWORD_1H:
			return SWORD_1H_GRIP_SCENE
		GroyperWeaponsScript.Id.AXE_2H:
			return AXE_2H_GRIP_SCENE
		GroyperWeaponsScript.Id.SWORD_2H:
			return SWORD_2H_GRIP_SCENE
		GroyperWeaponsScript.Id.HAMMER_2H:
			return HAMMER_2H_GRIP_SCENE
		_:
			return SWORD_GRIP_SCENE


## The stylized FBX weapons are modelled upright along +Y with their origin near
## the handle base. This rotates that +Y blade to point forward out of the fist
## (grip +Z, matching the sword & shield rig), applies a uniform display scale,
## and seats it at the same hand offset the sword uses.
static func _one_handed_hand_grip_local(scale: float, roll_deg: float) -> Transform3D:
	var basis := Basis.from_euler(Vector3(PI * 0.5, 0.0, deg_to_rad(roll_deg)))
	basis = basis.scaled(Vector3(scale, scale, scale))
	return Transform3D(basis, Vector3(0.011335179, 0.038125873, 0.066636376))


## Two-handed weapons are gripped so the blade/head points forward out of the
## fist. Shares the same seat as the sword; tune per weapon in the editor via the
## grip scene and hand mount transforms.
static func _two_handed_hand_grip_local(scale: float, roll_deg: float) -> Transform3D:
	var basis := Basis.from_euler(Vector3(PI * 0.5, 0.0, deg_to_rad(roll_deg)))
	basis = basis.scaled(Vector3(scale, scale, scale))
	return Transform3D(basis, Vector3(0.011335179, 0.038125873, 0.066636376))


## Per-weapon transform for the weapon while gripped in the hand. Returns the
## sword & shield default unless a weapon needs its own tuned pose.
static func melee_hand_grip_local(weapon_id: int) -> Transform3D:
	match weapon_id:
		GroyperWeaponsScript.Id.AXE_1H:
			return _one_handed_hand_grip_local(1.0, 0.0)
		GroyperWeaponsScript.Id.SWORD_1H:
			return _one_handed_hand_grip_local(0.75, 0.0)
		GroyperWeaponsScript.Id.AXE_2H:
			return _two_handed_hand_grip_local(0.6, 0.0)
		GroyperWeaponsScript.Id.SWORD_2H:
			return _two_handed_hand_grip_local(0.6, 0.0)
		GroyperWeaponsScript.Id.HAMMER_2H:
			return _two_handed_hand_grip_local(0.6, 0.0)
		_:
			return SWORD_HAND_GRIP_LOCAL


## Which hand mount carries the drawn weapon. One-handed melee weapons share the
## sword hand mount (also used by one-handed guns); two-handers use their own.
static func melee_hand_mount_name(weapon_id: int) -> String:
	if GroyperWeaponsScript.is_two_handed_melee(weapon_id):
		return "HandTwoHandedMount"
	return "HandSwordMount"


## Skeleton mount that stows each melee weapon. One-handed weapons each get their
## own editor-placeable hip holster so several can hang on the body at once; the
## back is left for the sword & shield (and future two-handers).
static func melee_holster_mount_name(weapon_id: int) -> String:
	match weapon_id:
		GroyperWeaponsScript.Id.AXE_1H:
			return "Axe1hHolsterMount"
		GroyperWeaponsScript.Id.SWORD_1H:
			return "Sword1hHolsterMount"
		GroyperWeaponsScript.Id.AXE_2H:
			return "Axe2hHolsterMount"
		GroyperWeaponsScript.Id.SWORD_2H:
			return "Sword2hHolsterMount"
		GroyperWeaponsScript.Id.HAMMER_2H:
			return "Hammer2hHolsterMount"
		_:
			return "BackSwordHolsterMount"


## Companion shield holster for the weapon, or "" when it carries no shield.
static func melee_shield_holster_mount_name(weapon_id: int) -> String:
	if GroyperWeaponsScript.melee_uses_shield(weapon_id):
		return "BackShieldHolsterMount"
	return ""


## Shows the hip holster (with its embedded weapon) for every owned one-handed
## melee weapon, and hides the holster for weapons the player doesn't own. The
## equipped weapon's grip is carried in-hand by the rig, leaving its holster
## empty but visible.
static func sync_melee_holsters(skeleton: Skeleton3D, owned_ids: Array) -> void:
	if skeleton == null:
		return
	_set_mount_visible(skeleton, "Axe1hHolsterMount", GroyperWeaponsScript.Id.AXE_1H in owned_ids)
	_set_mount_visible(skeleton, "Sword1hHolsterMount", GroyperWeaponsScript.Id.SWORD_1H in owned_ids)
	_set_mount_visible(skeleton, "Axe2hHolsterMount", GroyperWeaponsScript.Id.AXE_2H in owned_ids)
	_set_mount_visible(skeleton, "Sword2hHolsterMount", GroyperWeaponsScript.Id.SWORD_2H in owned_ids)
	_set_mount_visible(skeleton, "Hammer2hHolsterMount", GroyperWeaponsScript.Id.HAMMER_2H in owned_ids)


static func _set_mount_visible(skeleton: Skeleton3D, mount_name: String, visible: bool) -> void:
	var mount := skeleton.get_node_or_null(mount_name) as Node3D
	if mount != null:
		mount.visible = visible


static func sync_melee_equipment_owned(
	skeleton: Skeleton3D,
	owned: bool,
	weapon_id: int = GroyperWeaponsScript.Id.SWORD_SHIELD
) -> void:
	if skeleton == null:
		return
	var sword_socket := _holster_socket(skeleton, "BackSwordHolsterMount")
	var shield_socket := _holster_socket(skeleton, "BackShieldHolsterMount")
	if owned:
		_ensure_melee_grip(
			sword_socket,
			melee_grip_scene_for(weapon_id),
			SWORD_GRIP_NAME,
			SWORD_HOLSTER_LOCAL,
			weapon_id
		)
		if GroyperWeaponsScript.melee_uses_shield(weapon_id):
			_ensure_melee_grip(
				shield_socket,
				SHIELD_GRIP_SCENE,
				SHIELD_GRIP_NAME,
				SHIELD_HOLSTER_LOCAL,
				-1
			)
		else:
			_remove_grip(shield_socket, SHIELD_GRIP_NAME)
	else:
		_remove_grip(sword_socket, SWORD_GRIP_NAME)
		_remove_grip(shield_socket, SHIELD_GRIP_NAME)


## Removes any mounted melee grips from both the back holster sockets and the
## hand grip sockets. Used before swapping to a different melee weapon mesh.
static func clear_melee_grips(skeleton: Skeleton3D) -> void:
	if skeleton == null:
		return
	_remove_grip(_holster_socket(skeleton, "BackSwordHolsterMount"), SWORD_GRIP_NAME)
	_remove_grip(_holster_socket(skeleton, "BackShieldHolsterMount"), SHIELD_GRIP_NAME)
	_remove_grip(_hand_socket(skeleton, "HandSwordMount"), SWORD_GRIP_NAME)
	_remove_grip(_hand_socket(skeleton, "HandShieldMount"), SHIELD_GRIP_NAME)


static func _holster_socket(skeleton: Skeleton3D, mount_name: StringName) -> Node3D:
	var mount := skeleton.get_node_or_null(NodePath(String(mount_name))) as Node3D
	if mount == null:
		return null
	return mount.get_node_or_null("HolsterOffset") as Node3D


static func _hand_socket(skeleton: Skeleton3D, mount_name: StringName) -> Node3D:
	var mount := skeleton.get_node_or_null(NodePath(String(mount_name))) as Node3D
	if mount == null:
		return null
	return mount.get_node_or_null("GripOffset") as Node3D


static func _ensure_melee_grip(
	socket: Node3D,
	grip_scene: PackedScene,
	grip_name: StringName,
	local_transform: Transform3D,
	weapon_id: int
) -> void:
	if socket == null:
		return
	var existing := socket.get_node_or_null(String(grip_name)) as Node3D
	if existing != null:
		var matches := weapon_id < 0 or int(existing.get_meta(MELEE_WEAPON_META, -1)) == weapon_id
		if matches:
			existing.visible = true
			return
		existing.free()
	var grip: Node3D = grip_scene.instantiate()
	grip.name = grip_name
	if weapon_id >= 0:
		grip.set_meta(MELEE_WEAPON_META, weapon_id)
	socket.add_child(grip)
	grip.transform = local_transform


static func _remove_grip(socket: Node3D, grip_name: StringName) -> void:
	if socket == null:
		return
	var grip := socket.get_node_or_null(String(grip_name))
	if grip != null:
		# Free immediately (not queue_free): a melee rig may be rebuilt in the same
		# frame and would otherwise resolve this doomed node into its grip cache.
		grip.get_parent().remove_child(grip)
		grip.free()
