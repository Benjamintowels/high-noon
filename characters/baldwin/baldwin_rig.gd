@tool
extends Node3D

const HAND_SWORD_MOUNT_SCENE := preload("res://characters/baldwin/equipment/hand_sword_mount.tscn")
const HAND_SHIELD_MOUNT_SCENE := preload("res://characters/baldwin/equipment/hand_shield_mount.tscn")
const BACK_SWORD_HOLSTER_SCENE := preload("res://characters/baldwin/equipment/back_sword_holster_mount.tscn")
const BACK_SHIELD_HOLSTER_SCENE := preload("res://characters/baldwin/equipment/back_shield_holster_mount.tscn")

const RIGHT_HAND_BONE := "RightHand"
const LEFT_HAND_BONE := "LeftHand"
const SPINE_BONE := "Spine02"


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
	_add_mount_if_missing(skeleton, "HandShieldMount", HAND_SHIELD_MOUNT_SCENE, LEFT_HAND_BONE)
	_add_mount_if_missing(skeleton, "BackSwordHolsterMount", BACK_SWORD_HOLSTER_SCENE, SPINE_BONE)
	_add_mount_if_missing(skeleton, "BackShieldHolsterMount", BACK_SHIELD_HOLSTER_SCENE, SPINE_BONE)


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
	if Engine.is_editor_hint():
		mount.owner = _get_edited_scene_root()


func _get_edited_scene_root() -> Node:
	var tree := get_tree()
	if tree == null:
		return null
	return tree.edited_scene_root
