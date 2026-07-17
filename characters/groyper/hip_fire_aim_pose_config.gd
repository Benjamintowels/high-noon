extends RefCounted

## Authored one-handed hip-fire / ADS rests for overworld run-and-gun.
## Keyed on groyper_body AnimationPlayer as HipFireAim/neutral and HipFireAim/ads.
## Runtime slerps neutral→ads as the straight-ahead reference (plus baked
## RightArm euler offsets), then aim-corrects RightArm so the gun axis stays on
## the reticle while locomotion owns the legs. Hip walk uses the same arm lock
## recipe as ADS walk (no hip-only clearance abduct).
##
## Authoring:
## 1. Open characters/groyper/groyper_body.tscn
## 2. AnimationPlayer → HipFireAim/neutral or HipFireAim/ads at time 0
## 3. Pose Spine / Spine01 / Spine02 / RightShoulder / RightArm / RightForeArm / RightHand
## 4. Capture with HipFirePoseCapture, or edit the standalone .tres clips

const LIBRARY_NAME := &"HipFireAim"
const LIBRARY_PATH := "res://characters/groyper/hip_fire_aim.tres"
const POSE_PATH_NEUTRAL := "res://characters/groyper/hip_fire_aim_neutral.tres"
const POSE_PATH_ADS := "res://characters/groyper/hip_fire_aim_ads.tres"
const POSE_NAME_NEUTRAL := &"neutral"
const POSE_NAME_ADS := &"ads"
## Backward-compatible alias.
const POSE_NAME := POSE_NAME_NEUTRAL
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const SPINE_BONE := "Spine"
const SPINE01_BONE := "Spine01"
const SPINE02_BONE := "Spine02"
const SHOULDER_BONE := "RightShoulder"
const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"


static func get_pose_resource_path(pose_name: StringName) -> String:
	if pose_name == POSE_NAME_ADS:
		return POSE_PATH_ADS
	return POSE_PATH_NEUTRAL


## Full locked chain for HipFireAim — locomotion must not own these while drawn.
const AUTHORING_BONES: Array[String] = [
	SPINE_BONE,
	SPINE01_BONE,
	SPINE02_BONE,
	SHOULDER_BONE,
	ARM_BONE,
	FOREARM_BONE,
	HAND_BONE,
]

## Always needed at runtime; get euler fallbacks if the clip is missing.
const REQUIRED_BONES: Array[String] = [
	ARM_BONE,
	FOREARM_BONE,
	HAND_BONE,
]

## Gun-arm bones smoothed each frame while aiming (shoulder when keyed).
const GUN_ARM_SMOOTH_BONES: Array[String] = [
	SHOULDER_BONE,
	ARM_BONE,
	FOREARM_BONE,
	HAND_BONE,
]

## Fallback eulers (degrees) if the AnimationPlayer clip is missing.
## Forearm Z bend ≈ bent elbow hip hold.
const FALLBACK_ARM_ROTATION_DEG := Vector3(8.0, 0.0, -12.0)
const FALLBACK_FOREARM_ROTATION_DEG := Vector3(0.0, 0.0, 55.0)
const FALLBACK_HAND_ROTATION_DEG := Vector3.ZERO

## In-game O-key tuner offsets (hip + ADS). Zero by default — authored
## HipFireAim rests are applied verbatim so runtime matches the editor.
const HIP_ARM_OFFSET_EULER_DEG := Vector3.ZERO
const ADS_ARM_OFFSET_EULER_DEG := Vector3.ZERO

## How hard locomotion RightShoulder swing is pulled toward identity (0–1)
## while moving with a 1H gun (hip and ADS — same walk stabilizer).
const BODY_CLEARANCE_SHOULDER_DAMP := 1.0
## When HipFireAim/neutral omits spine keys, walking pulls ADS-only torso
## bones toward the ADS hold so the gun base stays stable (ADS walk style).
const WALK_TORSO_LOCK := 1.0

## Torso bones under the gun arm. Unkeyed ones get locomotion sway frozen
## while walking so the arm chain stays lined up with the reticle.
const TORSO_BONES: Array[String] = [
	SPINE_BONE,
	SPINE01_BONE,
	SPINE02_BONE,
]


static func get_animation_path(pose_name: StringName = POSE_NAME_NEUTRAL) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, pose_name])


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


## ADS fallback = identity (straight-arm procedural default before ads clip existed).
static func fallback_ads_pose_rotation(_bone_name: String) -> Quaternion:
	return Quaternion.IDENTITY


## Smooth 0–1 move weight for walk/run shoulder damp + torso lock.
static func move_stability_weight(move_blend: float) -> float:
	var move_w := clampf(move_blend, 0.0, 1.0)
	return move_w * move_w * (3.0 - 2.0 * move_w)


## Weight for locomotion shoulder damp while 1H aiming (hip and ADS).
static func body_clearance_weight(move_blend: float, _ads_blend: float = 0.0) -> float:
	return move_stability_weight(move_blend)


## How hard ADS-only torso bones lock toward the ADS hold while walking at hip.
static func walk_torso_lock_weight(move_blend: float, ads_blend: float) -> float:
	return maxf(
		clampf(ads_blend, 0.0, 1.0),
		move_stability_weight(move_blend) * WALK_TORSO_LOCK
	)


static func arm_offset_euler_deg(ads: bool) -> Vector3:
	return ADS_ARM_OFFSET_EULER_DEG if ads else HIP_ARM_OFFSET_EULER_DEG


static func arm_offset_quat(euler_deg: Vector3) -> Quaternion:
	if euler_deg.is_equal_approx(Vector3.ZERO):
		return Quaternion.IDENTITY
	return Quaternion(Basis.from_euler(euler_deg * (PI / 180.0)))


static func _bone_name_from_track_path(node_path: String) -> String:
	if ":" in node_path:
		return node_path.substr(node_path.rfind(":") + 1)
	return node_path


static func load_pose_rotations_from_library(
	library: AnimationLibrary,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	var poses := {}
	if library == null or not library.has_animation(pose_name):
		return poses
	var animation := library.get_animation(pose_name)
	if animation == null:
		return poses

	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		var bone_name := _bone_name_from_track_path(String(animation.track_get_path(track_idx)))
		if not AUTHORING_BONES.has(bone_name):
			continue
		if animation.track_get_key_count(track_idx) <= 0:
			continue
		var key_value: Variant = animation.track_get_key_value(track_idx, 0)
		if key_value is Quaternion:
			poses[bone_name] = key_value
	return poses


static func load_pose_positions_from_library(
	library: AnimationLibrary,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	var poses := {}
	if library == null or not library.has_animation(pose_name):
		return poses
	var animation := library.get_animation(pose_name)
	if animation == null:
		return poses

	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_POSITION_3D:
			continue
		var bone_name := _bone_name_from_track_path(String(animation.track_get_path(track_idx)))
		if not AUTHORING_BONES.has(bone_name):
			continue
		if animation.track_get_key_count(track_idx) <= 0:
			continue
		var key_value: Variant = animation.track_get_key_value(track_idx, 0)
		if key_value is Vector3:
			poses[bone_name] = key_value
	return poses


static func load_pose_rotations(
	animation_player: AnimationPlayer,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	if animation_player != null and animation_player.has_animation_library(LIBRARY_NAME):
		var from_ap := load_pose_rotations_from_library(
			animation_player.get_animation_library(LIBRARY_NAME),
			pose_name
		)
		if not from_ap.is_empty():
			return from_ap
	return load_pose_rotations_from_library(
		load(LIBRARY_PATH) as AnimationLibrary,
		pose_name
	)


static func load_pose_positions(
	animation_player: AnimationPlayer,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	if animation_player != null and animation_player.has_animation_library(LIBRARY_NAME):
		var from_ap := load_pose_positions_from_library(
			animation_player.get_animation_library(LIBRARY_NAME),
			pose_name
		)
		if not from_ap.is_empty():
			return from_ap
	return load_pose_positions_from_library(
		load(LIBRARY_PATH) as AnimationLibrary,
		pose_name
	)


static func blended_pose_position(
	hip_positions: Dictionary,
	ads_positions: Dictionary,
	bone_name: String,
	ads_blend: float,
	fallback: Vector3
) -> Vector3:
	var has_hip := hip_positions.has(bone_name)
	var has_ads := ads_positions.has(bone_name)
	if not has_hip and not has_ads:
		return fallback
	var hip_p: Vector3 = hip_positions.get(bone_name, ads_positions.get(bone_name, fallback)) as Vector3
	var ads_p: Vector3 = ads_positions.get(bone_name, hip_p) as Vector3
	var t := clampf(ads_blend, 0.0, 1.0)
	if t <= 0.0001:
		return hip_p
	if t >= 0.999:
		return ads_p
	return hip_p.lerp(ads_p, t)


static func has_authored_pose(
	hip_poses: Dictionary,
	ads_poses: Dictionary,
	bone_name: String
) -> bool:
	return hip_poses.has(bone_name) or ads_poses.has(bone_name)


## Blend authored hip → ADS rests by ads_blend (0 hip, 1 ADS).
## Callers must gate optional bones with has_authored_pose first.
## Missing hip keys fall back to ADS (and vice versa) for incomplete captures;
## required bones with neither key use euler fallbacks.
static func blended_pose_rotation(
	hip_poses: Dictionary,
	ads_poses: Dictionary,
	bone_name: String,
	ads_blend: float
) -> Quaternion:
	var has_hip := hip_poses.has(bone_name)
	var has_ads := ads_poses.has(bone_name)
	if not has_hip and not has_ads:
		if bone_name in REQUIRED_BONES:
			return fallback_pose_rotation(bone_name)
		return Quaternion.IDENTITY
	var hip_q: Quaternion = (
		hip_poses.get(bone_name, ads_poses.get(bone_name, Quaternion.IDENTITY)) as Quaternion
	)
	var ads_q: Quaternion = ads_poses.get(bone_name, hip_q) as Quaternion
	var t := clampf(ads_blend, 0.0, 1.0)
	if t <= 0.0001:
		return hip_q
	if t >= 0.999:
		return ads_q
	return hip_q.slerp(ads_q, t).normalized()
