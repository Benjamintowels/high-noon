extends RefCounted

## Authored one-handed hip-fire rest for overworld run-and-gun.
## Keyed on groyper_body AnimationPlayer as HipFireAim/neutral.
## Runtime at ads=0: RightArm/ForeArm use this clip; RightArm gets a world aim
## correction so the barrel tracks the reticle. RightHand is solved so its world
## orientation matches ADS (straight-arm) — local hand keys alone look sideways
## once the forearm rolls.
## Walk/run: body_clearance_* helpers open the arm off the ribs and damp shoulder
## swing from locomotion (idle/ADS leave the authored rest alone).
## RMB ADS (_ads_blend→1) slerps to straight-arm IK (forearm/hand identity).
##
## Authoring (same workflow as lean / TwoHandAim):
## 1. Open characters/groyper/groyper_body.tscn
## 2. AnimationPlayer → HipFireAim/neutral at time 0
## 3. Pose RightArm / RightForeArm (hand can stay identity — runtime matches ADS)
## 4. Key bone rotations, save scene (keys live in hip_fire_aim.tres)

const LIBRARY_NAME := &"HipFireAim"
const POSE_NAME := &"neutral"
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"

const AUTHORING_BONES: Array[String] = [
	ARM_BONE,
	FOREARM_BONE,
	HAND_BONE,
]

## Fallback eulers (degrees) if the AnimationPlayer clip is missing.
## Forearm Z bend ≈ bent elbow while the arm IK keeps the barrel on reticle.
const FALLBACK_ARM_ROTATION_DEG := Vector3(8.0, 0.0, -12.0)
const FALLBACK_FOREARM_ROTATION_DEG := Vector3(0.0, 0.0, 55.0)
const FALLBACK_HAND_ROTATION_DEG := Vector3.ZERO

## Walk/run body clearance: local RightArm add (degrees) at full move, ads=0.
## Negative Z opens the Meshy right arm off the ribs (matches holster abduct feel).
const BODY_CLEARANCE_ARM_EULER_DEG := Vector3(4.0, 0.0, -16.0)
## How hard locomotion shoulder swing is pulled back toward identity (0–1).
const BODY_CLEARANCE_SHOULDER_DAMP := 0.65


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, POSE_NAME])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func fallback_pose_rotation(bone_name: String) -> Quaternion:
	match bone_name:
		ARM_BONE:
			return Quaternion(Basis.from_euler(FALLBACK_ARM_ROTATION_DEG * (PI / 180.0)))
		FOREARM_BONE:
			return Quaternion(Basis.from_euler(FALLBACK_FOREARM_ROTATION_DEG * (PI / 180.0)))
		HAND_BONE:
			return Quaternion(Basis.from_euler(FALLBACK_HAND_ROTATION_DEG * (PI / 180.0)))
		_:
			return Quaternion.IDENTITY


## Weight for walk/run clearance: full at move_blend=1 & ads=0, none when idle or ADS.
static func body_clearance_weight(move_blend: float, ads_blend: float) -> float:
	var move_w := clampf(move_blend, 0.0, 1.0)
	move_w = move_w * move_w * (3.0 - 2.0 * move_w)
	var hip_w := 1.0 - clampf(ads_blend, 0.0, 1.0)
	return move_w * hip_w


## Local RightArm offset that lifts/opens the hip-fire chain off the torso while moving.
## Applied to the authored hip arm *before* aim correction so the barrel stays on reticle.
static func body_clearance_arm_offset(move_blend: float, ads_blend: float) -> Quaternion:
	var amount := body_clearance_weight(move_blend, ads_blend)
	if amount <= 0.0001:
		return Quaternion.IDENTITY
	return Quaternion(
		Basis.from_euler(BODY_CLEARANCE_ARM_EULER_DEG * (PI / 180.0) * amount)
	)


static func load_pose_rotations(animation_player: AnimationPlayer) -> Dictionary:
	var poses := {}
	if animation_player == null:
		return poses
	var animation_path := get_animation_path()
	if not animation_player.has_animation(animation_path):
		return poses
	var animation := animation_player.get_animation(animation_path)
	if animation == null:
		return poses

	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		var node_path := String(animation.track_get_path(track_idx))
		var bone_name := node_path
		if ":" in node_path:
			bone_name = node_path.substr(node_path.rfind(":") + 1)
		if not AUTHORING_BONES.has(bone_name):
			continue
		if animation.track_get_key_count(track_idx) <= 0:
			continue
		var key_value: Variant = animation.track_get_key_value(track_idx, 0)
		if key_value is Quaternion:
			poses[bone_name] = key_value
	return poses
