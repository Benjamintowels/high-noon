class_name BowAimPoseConfig
extends RefCounted

## Authored RecurveBow hip / ADS clips — keyed in groyper_body AnimationPlayer
## as BowAim/neutral and BowAim/ads.
##
## Clip layout (author once, runtime scrubs):
##   t = 0          → hold pose (arrow ready / undrawn)
##   t = 0 → length → drawback
## Charge scrubs forward by draw alpha. On release the scrub pauses at the peak
## then tweens reverse back to t = 0. Hip↔ADS still slerps by ads_blend.

const LIBRARY_NAME := &"BowAim"
const POSE_NAME_NEUTRAL := &"neutral"
const POSE_NAME_ADS := &"ads"
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const LEFT_SHOULDER_BONE := "LeftShoulder"
const LEFT_ARM_BONE := "LeftArm"
const LEFT_FOREARM_BONE := "LeftForeArm"
const LEFT_HAND_BONE := "LeftHand"
const RIGHT_SHOULDER_BONE := "RightShoulder"
const RIGHT_ARM_BONE := "RightArm"
const RIGHT_FOREARM_BONE := "RightForeArm"
const RIGHT_HAND_BONE := "RightHand"

const UPPER_BODY_BONES: Array[String] = ["Spine", "Spine01", "Spine02", "Head"]

## Left arm + torso stay on the hold pose so BowHandMount (LeftHand) never drifts.
const HOLD_LOCK_BONES: Array[String] = [
	LEFT_SHOULDER_BONE,
	LEFT_ARM_BONE,
	LEFT_FOREARM_BONE,
	LEFT_HAND_BONE,
	"Spine",
	"Spine01",
	"Spine02",
	"Head",
]

## Only the string hand scrubs with draw alpha (drawback / reverse).
const STRING_HAND_BONES: Array[String] = [
	RIGHT_SHOULDER_BONE,
	RIGHT_ARM_BONE,
	RIGHT_FOREARM_BONE,
	RIGHT_HAND_BONE,
]

const AUTHORING_BONES: Array[String] = [
	LEFT_SHOULDER_BONE,
	LEFT_ARM_BONE,
	LEFT_FOREARM_BONE,
	LEFT_HAND_BONE,
	RIGHT_SHOULDER_BONE,
	RIGHT_ARM_BONE,
	RIGHT_FOREARM_BONE,
	RIGHT_HAND_BONE,
	"Spine",
	"Spine01",
	"Spine02",
	"Head",
]

const LEAN_EXCLUDED_WHEN_BOW: Array[String] = [
	LEFT_SHOULDER_BONE,
	LEFT_ARM_BONE,
	LEFT_FOREARM_BONE,
	LEFT_HAND_BONE,
	RIGHT_SHOULDER_BONE,
	RIGHT_ARM_BONE,
	RIGHT_FOREARM_BONE,
	RIGHT_HAND_BONE,
	"Spine",
	"Spine01",
	"Spine02",
	"Head",
]

const AIM_PITCH_BONE := "Spine02"
const AIM_PITCH_MIN_RAD := deg_to_rad(-65.0)
const AIM_PITCH_MAX_RAD := deg_to_rad(50.0)
const AIM_PITCH_WEIGHT := 1.0

const STANCE_SPINE_BONES: Array[String] = ["Spine", "Spine01", "Spine02"]
const STANCE_SPINE_WEIGHTS: Array[float] = [0.2, 0.35, 0.45]
const STANCE_HEAD_BONE := "Head"
const STANCE_YAW_DEG := -25.0
const STANCE_HEAD_COUNTER := 1.0
const STANCE_ADS_RETAIN := 0.45

## Groyper Spine02 bind rest. Shared BowAim torso keys are absolute in this
## frame — applying them on Meshy bodies with a divergent Spine02 rest (Fast)
## folds the character backwards. Arms still transfer well enough.
const AUTHORING_SPINE02_REST := Quaternion(
	0.129253626, 0.007075693, -0.007422873, 0.991558552
)
const AUTHORING_REST_MATCH_MAX_ANGLE_RAD := deg_to_rad(35.0)

## Hold-lock without torso — used when skeleton rests don't match authoring.
const HOLD_LOCK_ARM_BONES: Array[String] = [
	LEFT_SHOULDER_BONE,
	LEFT_ARM_BONE,
	LEFT_FOREARM_BONE,
	LEFT_HAND_BONE,
]


static func get_animation_path(pose_name: StringName = POSE_NAME_NEUTRAL) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, pose_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


## True when this skeleton can take Groyper-authored BowAim torso / Spine02 pitch.
static func skeleton_matches_authoring_rests(skeleton: Skeleton3D) -> bool:
	if skeleton == null:
		return false
	var bone_id := skeleton.find_bone(AIM_PITCH_BONE)
	if bone_id < 0:
		return false
	var rest_q := skeleton.get_bone_rest(bone_id).basis.get_rotation_quaternion()
	return rest_q.angle_to(AUTHORING_SPINE02_REST) <= AUTHORING_REST_MATCH_MAX_ANGLE_RAD


static func hold_lock_bones_for_skeleton(skeleton: Skeleton3D) -> Array[String]:
	if skeleton_matches_authoring_rests(skeleton):
		return HOLD_LOCK_BONES
	return HOLD_LOCK_ARM_BONES


static func has_authored_torso(hip_poses: Dictionary, ads_poses: Dictionary) -> bool:
	for bone_name: String in STANCE_SPINE_BONES:
		if has_authored_pose(hip_poses, ads_poses, bone_name):
			return true
	return false


static func stance_yaw(ads_blend: float) -> float:
	var t := clampf(ads_blend, 0.0, 1.0)
	var scale := lerpf(1.0, STANCE_ADS_RETAIN, t)
	return deg_to_rad(STANCE_YAW_DEG) * scale


static func aim_elevation_rad(world_origin: Vector3, world_target: Vector3) -> float:
	var to_target := world_target - world_origin
	if to_target.length_squared() < 0.0001:
		return 0.0
	var elevation := asin(clampf(to_target.normalized().y, -1.0, 1.0))
	return clampf(elevation, AIM_PITCH_MIN_RAD, AIM_PITCH_MAX_RAD)


static func aim_pitch_delta(elevation_rad: float, weight: float = 1.0) -> Quaternion:
	var pitch := -elevation_rad * AIM_PITCH_WEIGHT * clampf(weight, 0.0, 1.0)
	if absf(pitch) <= 0.0001:
		return Quaternion.IDENTITY
	return Quaternion(Vector3.RIGHT, pitch)


static func apply_aim_pitch_to_skeleton(
	skeleton: Skeleton3D,
	world_target: Vector3,
	weight: float = 1.0
) -> void:
	if skeleton == null or weight <= 0.0001 or world_target == Vector3.ZERO:
		return
	# Local RIGHT pitch assumes Groyper Spine02 axes — skip on foreign rests.
	if not skeleton_matches_authoring_rests(skeleton):
		return
	var bone_id := skeleton.find_bone(AIM_PITCH_BONE)
	if bone_id < 0:
		return
	var bone_global := skeleton.global_transform * skeleton.get_bone_global_pose(bone_id)
	var elevation := aim_elevation_rad(bone_global.origin, world_target)
	var delta_q := aim_pitch_delta(elevation, weight)
	if delta_q.is_equal_approx(Quaternion.IDENTITY):
		return
	var current := skeleton.get_bone_pose_rotation(bone_id)
	skeleton.set_bone_pose_rotation(bone_id, (current * delta_q).normalized())


## Sample undrawn rest (time 0) — used by editor preview / capture checks.
static func load_pose_rotations(
	animation_player: AnimationPlayer,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	return sample_pose_rotations(animation_player, pose_name, 0.0)


## Sample the clip at draw_alpha (0..1): 0 = hold (first frame), 1 = full drawback.
static func sample_pose_rotations(
	animation_player: AnimationPlayer,
	pose_name: StringName,
	draw_alpha: float
) -> Dictionary:
	var poses := {}
	var animation := _resolve_animation(animation_player, pose_name)
	if animation == null:
		return poses

	var end_time := _drawback_end_time(animation)
	var time := clampf(draw_alpha, 0.0, 1.0) * end_time

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
		var key_value: Variant = animation.rotation_track_interpolate(track_idx, time)
		if key_value is Quaternion:
			poses[bone_name] = (key_value as Quaternion).normalized()
	return poses


static func _resolve_animation(
	animation_player: AnimationPlayer,
	pose_name: StringName
) -> Animation:
	if animation_player != null:
		var animation_path := get_animation_path(pose_name)
		if animation_player.has_animation(animation_path):
			var from_player := animation_player.get_animation(animation_path)
			if from_player != null:
				return from_player
	# Fallback: load the library resource directly (same file the editor saves).
	var library := load("res://characters/groyper/bow_aim.tres") as AnimationLibrary
	if library == null or not library.has_animation(pose_name):
		return null
	return library.get_animation(pose_name)


## Scrub end = latest rotation key time (NOT clip length). BowAim clips are often
## LOOP_LINEAR; sampling at length wraps back to the hold pose and kills drawback.
static func _drawback_end_time(animation: Animation) -> float:
	var end_time := 0.0
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		var key_count := animation.track_get_key_count(track_idx)
		if key_count <= 0:
			continue
		end_time = maxf(end_time, animation.track_get_key_time(track_idx, key_count - 1))
	if end_time <= 0.0001:
		end_time = maxf(animation.length, 0.0001)
	return end_time


static func is_string_hand_bone(bone_name: String) -> bool:
	return bone_name in STRING_HAND_BONES


static func has_authored_pose(
	hip_poses: Dictionary,
	ads_poses: Dictionary,
	bone_name: String
) -> bool:
	return hip_poses.has(bone_name) or ads_poses.has(bone_name)


static func blended_pose_rotation(
	hip_poses: Dictionary,
	ads_poses: Dictionary,
	bone_name: String,
	ads_blend: float
) -> Quaternion:
	if not has_authored_pose(hip_poses, ads_poses, bone_name):
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
