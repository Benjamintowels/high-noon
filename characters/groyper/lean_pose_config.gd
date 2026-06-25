class_name LeanPoseConfig
extends RefCounted

## Shared lean pose names, blend-space positions, and bones to key while authoring.
## Edit poses in groyper_body.tscn using the AnimationPlayer + Skeleton3D workflow.

const LIBRARY_NAME := &"Lean"

const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

## Bones to pose for dodge leans. Gun arm chain is excluded — aim IK owns that.
const LEAN_BONES: Array[String] = [
	"Hips",
	"Spine",
	"Spine01",
	"Spine02",
	"LeftShoulder",
	"LeftUpLeg",
	"RightUpLeg",
	"LeftLeg",
	"RightLeg",
]

## Never key these in Lean.res. IdleLeanMix keeps them on idle so draw/aim IK stays independent.
const AIM_EXCLUDED_BONES: Array[String] = [
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

## Cardinal lean poses authored in Lean.res. Diagonals are interpolated by BlendSpace2D.
## Vector2(x, y) matches gameplay lean input: x = left/right, y = forward/back.
const POSE_BLEND_POSITIONS: Dictionary = {
	"neutral": Vector2.ZERO,
	"forwards": Vector2(0.0, 1.0),
	"back": Vector2(0.0, -1.0),
	"left": Vector2(-1.0, 0.0),
	"right": Vector2(1.0, 0.0),
}

## Bones that may receive lean blend. All other bones stay on idle during lean mix.
const LEAN_MIX_FILTER_BONES: Array[String] = [
	"Hips",
	"Spine",
	"Spine01",
	"Spine02",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"LeftUpLeg",
	"LeftLeg",
	"LeftFoot",
	"LeftToeBase",
	"RightUpLeg",
	"RightLeg",
	"RightFoot",
	"RightToeBase",
	"neck",
	"Head",
	"head_end",
	"headfront",
]


static func get_pose_names() -> Array[String]:
	var names: Array[String] = []
	for pose_name in POSE_BLEND_POSITIONS.keys():
		names.append(pose_name)
	names.sort()
	return names


static func get_animation_path(pose_name: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, pose_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_idle_lean_mix_filter(mix_node: AnimationNodeBlend2) -> void:
	mix_node.filter_enabled = true
	for bone_name: String in LEAN_MIX_FILTER_BONES:
		mix_node.set_filter_path(get_skeleton_track_path(bone_name), true)
