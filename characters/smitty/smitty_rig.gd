extends Node3D

const HAND_SWORD_MOUNT_SCENE := preload("res://characters/baldwin/equipment/hand_sword_mount.tscn")
const HAMMER_GRIP_SCENE := preload("res://characters/smitty/equipment/hammer_grip.tscn")

const RIGHT_HAND_BONE := &"RightHand"


func _ready() -> void:
	_ensure_equipment_mounts()


func _ensure_equipment_mounts() -> void:
	var body := get_node_or_null("Body") as Node3D
	if body == null:
		return
	var skeleton := GroyperBodyUtils.find_skeleton(body)
	if skeleton == null:
		return
	_add_mount_if_missing(skeleton, "HandSwordMount", HAND_SWORD_MOUNT_SCENE, RIGHT_HAND_BONE)
	_attach_hammer(skeleton)


func _add_mount_if_missing(
	skeleton: Skeleton3D,
	mount_name: StringName,
	mount_scene: PackedScene,
	bone_name: StringName
) -> void:
	if skeleton.get_node_or_null(NodePath(String(mount_name))) != null:
		return
	var mount: BoneAttachment3D = mount_scene.instantiate()
	mount.name = mount_name
	mount.bone_name = bone_name
	var bone_idx := skeleton.find_bone(bone_name)
	if bone_idx >= 0:
		mount.bone_idx = bone_idx
	skeleton.add_child(mount)


func _attach_hammer(skeleton: Skeleton3D) -> void:
	var hand_mount := skeleton.get_node_or_null("HandSwordMount") as Node3D
	if hand_mount == null:
		return
	var grip_socket := hand_mount.get_node_or_null("GripOffset") as Node3D
	if grip_socket == null:
		return
	if grip_socket.get_node_or_null("HammerGrip") != null:
		return
	var grip: Node3D = HAMMER_GRIP_SCENE.instantiate()
	grip.name = "HammerGrip"
	grip_socket.add_child(grip)
