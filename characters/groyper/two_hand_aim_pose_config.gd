class_name TwoHandAimPoseConfig
extends RefCounted

## Authored arm neutral for two-hand IK — keyed in groyper_body AnimationPlayer TwoHandAim/neutral.
## Runtime reads this clip as bone rest poses, then the same aim IK as one-handed weapons runs on top.

const LIBRARY_NAME := &"TwoHandAim"
const POSE_NAME := &"neutral"
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const LEFT_ARM_BONE := "LeftArm"
const LEFT_FOREARM_BONE := "LeftForeArm"
const LEFT_HAND_BONE := "LeftHand"
const SUPPORT_IK_BONES: Array[String] = [LEFT_ARM_BONE, LEFT_FOREARM_BONE]
const SUPPORT_AIM_BONES: Array[String] = [LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]

const GUN_ARM_BONES: Array[String] = ["RightArm", "RightForeArm", "RightHand"]

## Bones to key when authoring / capturing the two-hand neutral hold.
const AUTHORING_BONES: Array[String] = [
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

## While two-handing, lean must not drive the arm chains (aim IK owns them).
const LEAN_EXCLUDED_WHEN_TWO_HANDED: Array[String] = [
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]

const SUPPORT_HAND_MARKER := &"SupportHand"


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, POSE_NAME])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_lean_mix_filter(mix_node: AnimationNodeBlend2, two_handed_active: bool) -> void:
	mix_node.filter_enabled = true
	for bone_name: String in LeanPoseConfig.LEAN_MIX_FILTER_BONES:
		var enabled := true
		if two_handed_active and bone_name in LEAN_EXCLUDED_WHEN_TWO_HANDED:
			enabled = false
		mix_node.set_filter_path(LeanPoseConfig.get_skeleton_track_path(bone_name), enabled)
