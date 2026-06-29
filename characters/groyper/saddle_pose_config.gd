class_name SaddlePoseConfig
extends RefCounted

## Riding pose — author in groyper_body.tscn AnimationPlayer → Saddle/saddle (time 0).
## Or pose the skeleton and toggle capture on SaddlePoseCapture.
##
## IMPORTANT: capture writes to saddle.tres only. Do not save saddle leg/arm bone
## overrides onto Skeleton3D in groyper_body.tscn — that flips or distorts standing
## locomotion. Never add a Skeleton3D node transform; facing is already corrected on Body.

const LIBRARY_NAME := &"Saddle"
const POSE_NAME := &"saddle"
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

## Bones to key for sitting on horseback with reins.
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

## Leg spread offsets authored in groyper_body.tscn for the riding seat.
const AUTHORING_POSITION_BONES: Array[String] = [
	"LeftUpLeg",
	"RightUpLeg",
]

## Right arm chain released from saddle animation while drawing / aiming on horseback.
## Shoulder stays on the saddle pose so the arm socket does not collapse into the torso.
const GUN_AIM_BONES: Array[String] = [
	"RightArm",
	"RightForeArm",
	"RightHand",
]

const GUN_ARM_BONES: Array[String] = [
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, POSE_NAME])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_saddle_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in AUTHORING_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)
	for bone_name: String in AUTHORING_POSITION_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), true)


static func set_gun_arm_blend_filtered(blend_node: AnimationNodeBlend2, filtered: bool) -> void:
	set_gun_aim_blend_filtered(blend_node, filtered)


static func set_gun_aim_blend_filtered(blend_node: AnimationNodeBlend2, filtered: bool) -> void:
	if blend_node == null:
		return
	for bone_name: String in GUN_AIM_BONES:
		blend_node.set_filter_path(get_skeleton_track_path(bone_name), filtered)
