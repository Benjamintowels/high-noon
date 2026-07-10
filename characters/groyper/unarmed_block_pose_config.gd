class_name UnarmedBlockPoseConfig
extends RefCounted

const PunchPoseConfigScript := preload("res://characters/groyper/punch_pose_config.gd")

## Unarmed block hold — groyper_body.tscn AnimationPlayer → UnarmedBlock/block_hold (time 0).
## Pose in the viewport, then toggle Capture Unarmed Block Pose on UnarmedBlockPoseCapture.
##
## IMPORTANT: capture writes to unarmed_block.tres only. Do not save bone overrides onto
## Skeleton3D in groyper_body.tscn — that distorts standing locomotion.

const LIBRARY_NAME := &"UnarmedBlock"
const BLOCK_HOLD := &"block_hold"

const CLIP_PATH := "res://characters/groyper/unarmed_block.tres"
const OUT_PATH := "res://characters/groyper/unarmed_block_pose.tres"

const SOURCE_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Sword_Parry_Backward_1_frame_rate_60.fbx"
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

## Upper body blended during unarmed block — legs stay on locomotion.
const BLOCK_BLEND_BONES: Array[String] = [
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
]


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, BLOCK_HOLD])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_block_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in BLOCK_BLEND_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set(
			"parameters/%s/blend_amount" % PunchPoseConfigScript.BLEND_NODE,
			amount
		)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set(
			"parameters/%s/seek_request" % PunchPoseConfigScript.TIME_SEEK_NODE,
			time
		)
