class_name PunchPoseConfig
extends RefCounted

## Punch clip — extracted from Right Upper Hook FBX, or edit `punch.tres` directly.
## AnimationPlayer library: Punch/punch (time 0), same pattern as Saddle/saddle.
##
## IMPORTANT: capture writes to punch.tres only. Do not save bone overrides onto
## Skeleton3D in groyper_body.tscn — that distorts standing locomotion.

const LIBRARY_NAME := &"Punch"
const PUNCH := &"punch"
const ELBOW_STRIKE := &"elbow_strike"

const PUNCH_CLIP_PATH := "res://characters/groyper/punch.tres"
const ELBOW_STRIKE_CLIP_PATH := "res://characters/groyper/elbow_strike.tres"
const OUT_PATH := "res://characters/groyper/punch_pose.tres"

const PUNCH_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Right_Upper_Hook_from_Guard_frame_rate_60.fbx"
)
const ELBOW_STRIKE_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Elbow_Strike_frame_rate_60.fbx"
)

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const BLEND_NODE := &"PunchBlend"
const TIME_SEEK_NODE := &"PunchTimeSeek"

## Upper body blended during punch — legs stay on locomotion.
const PUNCH_BLEND_BONES: Array[String] = [
	"Spine",
	"Spine01",
	"Spine02",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
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


static func get_elbow_strike_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, ELBOW_STRIKE])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_punch_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in PUNCH_BLEND_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % TIME_SEEK_NODE, time)
