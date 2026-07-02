class_name PunchPoseConfig
extends RefCounted

## Punch clip — edit `punch.tres` directly, or pose in groyper_body.tscn and capture.
## AnimationPlayer library: Punch/punch (time 0), same pattern as Saddle/saddle.
##
## IMPORTANT: capture writes to punch.tres only. Do not save bone overrides onto
## Skeleton3D in groyper_body.tscn — that distorts standing locomotion.

const LIBRARY_NAME := &"Punch"
const PUNCH := &"punch"

const PUNCH_CLIP_PATH := "res://characters/groyper/punch.tres"
const OUT_PATH := "res://characters/groyper/punch_pose.tres"

const PUNCH_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Boxing_Guard_Prep_Straight_Punch_frame_rate_60.fbx"
)

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const BLEND_NODE := &"PunchBlend"
const TIME_SEEK_NODE := &"PunchTimeSeek"

## Only the punching arm chain is blended — legs stay on locomotion.
const PUNCH_ARM_BONES: Array[String] = [
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

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


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, PUNCH])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_punch_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in PUNCH_ARM_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % TIME_SEEK_NODE, time)
