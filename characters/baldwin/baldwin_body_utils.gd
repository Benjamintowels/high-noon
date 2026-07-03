extends RefCounted
class_name BaldwinBodyUtils

const SWORD_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_grip.tscn")
const SHIELD_GRIP_SCENE := preload("res://characters/baldwin/equipment/shield_grip.tscn")

const SWORD_GRIP_NAME := &"SwordGrip"
const SHIELD_GRIP_NAME := &"ShieldGrip"

const SWORD_HOLSTER_LOCAL := Transform3D(
	Basis(Vector3(0.035, 0.0, -0.999), Vector3(0.0, 1.0, 0.0), Vector3(0.999, 0.0, 0.035)),
	Vector3(0.13, -0.22, 0.08)
)
const SHIELD_HOLSTER_LOCAL := Transform3D(
	Basis(Vector3(0.0, 0.0, -1.0), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0)),
	Vector3(-0.12, -0.18, 0.06)
)


static func sync_melee_equipment_owned(skeleton: Skeleton3D, owned: bool) -> void:
	if skeleton == null:
		return
	var sword_socket := _holster_socket(skeleton, "BackSwordHolsterMount")
	var shield_socket := _holster_socket(skeleton, "BackShieldHolsterMount")
	if owned:
		_ensure_grip(sword_socket, SWORD_GRIP_SCENE, SWORD_GRIP_NAME, SWORD_HOLSTER_LOCAL)
		_ensure_grip(shield_socket, SHIELD_GRIP_SCENE, SHIELD_GRIP_NAME, SHIELD_HOLSTER_LOCAL)
	else:
		_remove_grip(sword_socket, SWORD_GRIP_NAME)
		_remove_grip(shield_socket, SHIELD_GRIP_NAME)


static func _holster_socket(skeleton: Skeleton3D, mount_name: StringName) -> Node3D:
	var mount := skeleton.get_node_or_null(NodePath(String(mount_name))) as Node3D
	if mount == null:
		return null
	return mount.get_node_or_null("HolsterOffset") as Node3D


static func _ensure_grip(
	socket: Node3D,
	grip_scene: PackedScene,
	grip_name: StringName,
	local_transform: Transform3D
) -> void:
	if socket == null:
		return
	var existing := socket.get_node_or_null(String(grip_name)) as Node3D
	if existing != null:
		existing.visible = true
		return
	var grip: Node3D = grip_scene.instantiate()
	grip.name = grip_name
	socket.add_child(grip)
	grip.transform = local_transform


static func _remove_grip(socket: Node3D, grip_name: StringName) -> void:
	if socket == null:
		return
	var grip := socket.get_node_or_null(String(grip_name))
	if grip != null:
		grip.queue_free()
