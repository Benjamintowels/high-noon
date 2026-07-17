class_name TwoHandAimPoseConfig
extends RefCounted

## Authored two-hand hip / ADS rests — keyed in groyper_body AnimationPlayer
## TwoHandAim/neutral (hip) and TwoHandAim/ads (raised stock).
## Runtime slerps by ads_blend, then aim IK:
##   right arm → reticle, left arm → SupportHand marker on the grip.

const LIBRARY_NAME := &"TwoHandAim"
const POSE_NAME_NEUTRAL := &"neutral"
const POSE_NAME_ADS := &"ads"
## Backward-compatible alias used by duel draw / raise paths.
const POSE_NAME := POSE_NAME_NEUTRAL
const SKELETON_TRACK_PREFIX := "Armature/Skeleton3D:"

const LEFT_SHOULDER_BONE := "LeftShoulder"
const LEFT_ARM_BONE := "LeftArm"
const LEFT_FOREARM_BONE := "LeftForeArm"
const LEFT_HAND_BONE := "LeftHand"
const RIGHT_SHOULDER_BONE := "RightShoulder"
const RIGHT_ARM_BONE := "RightArm"
const RIGHT_FOREARM_BONE := "RightForeArm"
const RIGHT_HAND_BONE := "RightHand"

const SUPPORT_IK_BONES: Array[String] = [LEFT_ARM_BONE, LEFT_FOREARM_BONE]
const SUPPORT_AIM_BONES: Array[String] = [LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]

const GUN_ARM_BONES: Array[String] = [RIGHT_ARM_BONE, RIGHT_FOREARM_BONE, RIGHT_HAND_BONE]

## Torso / head keyed in TwoHandAim clips. When present at runtime these replace
## the procedural STANCE_* yaw twist so the editor pose matches in-game.
const UPPER_BODY_BONES: Array[String] = ["Spine", "Spine01", "Spine02", "Head"]

## Bones to key when authoring / capturing two-hand holds.
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

## While two-handing, lean must not drive the arm / torso chains (aim owns them).
const LEAN_EXCLUDED_WHEN_TWO_HANDED: Array[String] = [
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

const SUPPORT_HAND_MARKER := &"SupportHand"

## --- Rifle stance (procedural fallback when clips omit UPPER_BODY_BONES) ---
## Bladed third-person rifle hold: torso yaw twists toward the gun side while the
## head counter-twists to face the aim direction. Skipped when Spine/Spine01/
## Spine02 are keyed in TwoHandAim (authored pose wins).
const STANCE_SPINE_BONES: Array[String] = ["Spine", "Spine01", "Spine02"]
const STANCE_SPINE_WEIGHTS: Array[float] = [0.2, 0.35, 0.45]
const STANCE_HEAD_BONE := "Head"
## Total torso yaw at hip (degrees). Negative = right shoulder bladed back for the
## Meshy rig (Model carries a PI flip; sign verified in armory_test).
const STANCE_YAW_DEG := -25.0
## How much of the summed spine yaw the head undoes (1.0 = face straight at target).
const STANCE_HEAD_COUNTER := 1.0
## Fraction of hip twist kept at full ADS (shoulders square off when sighted).
const STANCE_ADS_RETAIN := 0.45

## --- Vertical aim (Spine02 pitch) ---
## Two-hand holds keep authored arm shape; left/right is body yaw. Elevation is
## applied as a local-X bend on Spine02 so the whole upper chain follows look up/down.
## Sign verified in-game: negated asin(aim.y) on local X (Body/Meshy flip).
const AIM_PITCH_BONE := "Spine02"
## Clamp asin(aim.y): negative = look down, positive = look up.
## Look-up max is above CAMERA_PITCH_MIN (−35°): elevation is measured from the
## chest bone to the far aim point, which steepens vs camera pitch near the top
## of the range — a tight 35° clamp left the last ~10% of look-up without lean.
const AIM_PITCH_MIN_RAD := deg_to_rad(-65.0)
const AIM_PITCH_MAX_RAD := deg_to_rad(50.0)
const AIM_PITCH_WEIGHT := 1.0


## True when a TwoHandAim clip keys at least one torso spine bone.
static func has_authored_torso(hip_poses: Dictionary, ads_poses: Dictionary) -> bool:
	for bone_name: String in STANCE_SPINE_BONES:
		if has_authored_pose(hip_poses, ads_poses, bone_name):
			return true
	return false


## Torso stance yaw in radians for the current hip→ADS blend.
static func stance_yaw(ads_blend: float) -> float:
	var t := clampf(ads_blend, 0.0, 1.0)
	var scale := lerpf(1.0, STANCE_ADS_RETAIN, t)
	return deg_to_rad(STANCE_YAW_DEG) * scale


## World-space aim elevation in radians (positive = look up).
static func aim_elevation_rad(world_origin: Vector3, world_target: Vector3) -> float:
	var to_target := world_target - world_origin
	if to_target.length_squared() < 0.0001:
		return 0.0
	var elevation := asin(clampf(to_target.normalized().y, -1.0, 1.0))
	return clampf(elevation, AIM_PITCH_MIN_RAD, AIM_PITCH_MAX_RAD)


## Local-space delta to multiply onto AIM_PITCH_BONE after the authored / stance rest.
## Negated vs asin(aim.y): Meshy spine + Body flip make +X bend toward look-down.
static func aim_pitch_delta(elevation_rad: float, weight: float = 1.0) -> Quaternion:
	var pitch := -elevation_rad * AIM_PITCH_WEIGHT * clampf(weight, 0.0, 1.0)
	if absf(pitch) <= 0.0001:
		return Quaternion.IDENTITY
	return Quaternion(Vector3.RIGHT, pitch)


## Pitch AIM_PITCH_BONE so the authored two-hand hold tracks look elevation.
static func apply_aim_pitch_to_skeleton(
	skeleton: Skeleton3D,
	world_target: Vector3,
	weight: float = 1.0
) -> void:
	if skeleton == null or weight <= 0.0001 or world_target == Vector3.ZERO:
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


static func get_animation_path(pose_name: StringName = POSE_NAME_NEUTRAL) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, pose_name])


static func get_skeleton_track_path(bone_name: String) -> NodePath:
	return NodePath("%s%s" % [SKELETON_TRACK_PREFIX, bone_name])


static func configure_lean_mix_filter(mix_node: AnimationNodeBlend2, two_handed_active: bool) -> void:
	mix_node.filter_enabled = true
	for bone_name: String in LeanPoseConfig.LEAN_MIX_FILTER_BONES:
		var enabled := true
		if two_handed_active and bone_name in LEAN_EXCLUDED_WHEN_TWO_HANDED:
			enabled = false
		mix_node.set_filter_path(LeanPoseConfig.get_skeleton_track_path(bone_name), enabled)


static func load_pose_rotations(
	animation_player: AnimationPlayer,
	pose_name: StringName = POSE_NAME_NEUTRAL
) -> Dictionary:
	var poses := {}
	if animation_player == null:
		return poses
	var animation_path := get_animation_path(pose_name)
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


## True when either hip or ADS clip keys this bone. Callers must not apply
## identity for missing keys — that forces bind/T-pose after AnimationTree.
static func has_authored_pose(
	hip_poses: Dictionary,
	ads_poses: Dictionary,
	bone_name: String
) -> bool:
	return hip_poses.has(bone_name) or ads_poses.has(bone_name)


## Blend authored hip → ADS rests by ads_blend (0 hip, 1 ADS).
## Missing hip keys fall back to ADS (and vice versa) so incomplete captures
## (e.g. neutral without RightShoulder/RightHand) still get a usable rest.
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
