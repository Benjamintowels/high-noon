class_name CoverPoseConfig
extends RefCounted

## Crouch cover — groyper_body.tscn AnimationPlayer → cover_pose/crouch_cover (time 0).
## Cover peek aim — groyper_body.tscn AnimationPlayer → cover_peek/cover_peek_aim (time 0).
## Or pose the skeleton and toggle capture on CoverPoseCapture.
##
## IMPORTANT: capture writes to cover_pose.tres / cover_peek_aim.tres only. Do not save bone
## overrides onto Skeleton3D in groyper_body.tscn — that distorts standing locomotion.

const LIBRARY_NAME := &"cover_pose"
const COVER_PEEK_LIBRARY_NAME := &"cover_peek"
const ROLL_BEHIND_COVER := &"roll_behind_cover"
const CROUCH_COVER := &"crouch_cover"
const COVER_PEEK_AIM := &"cover_peek_aim"

const OUT_PATH := "res://characters/groyper/cover_pose.tres"
const COVER_PEEK_OUT_PATH := "res://characters/groyper/cover_peek_aim.tres"

const ROLL_BEHIND_COVER_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Roll_Behind_Cover_frame_rate_60.fbx"
)

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const AUTHORING_BONES: Array[String] = [
	"Hips",
	"Spine",
	"Spine01",
	"Spine02",
	"neck",
	"Head",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
	"LeftUpLeg",
	"LeftLeg",
	"RightUpLeg",
	"RightLeg",
]

const AUTHORING_POSITION_BONES: Array[String] = [
	"Hips",
	"LeftUpLeg",
	"RightUpLeg",
]

## Gun-side chain for cover peek — shoulder stays on this pose while drawing / aiming.
const PEEK_AUTHORING_BONES: Array[String] = [
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

## Released to weapon-rig IK while aiming from cover (shoulder stays on cover_peek_aim).
const GUN_AIM_BONES: Array[String] = [
	"RightArm",
	"RightForeArm",
	"RightHand",
]


static func get_roll_behind_cover_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, ROLL_BEHIND_COVER])


static func get_crouch_cover_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, CROUCH_COVER])


static func get_cover_peek_aim_path() -> StringName:
	return StringName("%s/%s" % [COVER_PEEK_LIBRARY_NAME, COVER_PEEK_AIM])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_cover_pose_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in AUTHORING_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)
	for bone_name: String in AUTHORING_POSITION_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func configure_cover_peek_blend(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in PEEK_AUTHORING_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_gun_aim_blend_filtered(blend_node: AnimationNodeBlend2, filtered: bool) -> void:
	if blend_node == null:
		return
	for bone_name: String in GUN_AIM_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), filtered)
