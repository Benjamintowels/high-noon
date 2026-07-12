class_name WeaponThrowConfig
extends RefCounted

## Baseball-pitch weapon throw: while blocking with a throwable one-hander,
## LMB blends the pitch overlay in at 2x speed and hurls the weapon forward.
## The clip is extracted from the FBX at runtime (same pattern as the melee
## library) into the "weapon_throw" AnimationPlayer library.

const LIBRARY_NAME := &"weapon_throw"
const CLIP_PITCH := &"pitch"

const PITCH_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_baseball_pitching_frame_rate_60.fbx"
)

const ANIM_NODE := &"WeaponThrowAnim"
const TIME_SEEK_NODE := &"WeaponThrowTimeSeek"
const TIME_SCALE_NODE := &"WeaponThrowTimeScale"
const BLEND_NODE := &"WeaponThrowBlend"

const PLAYBACK_SPEED := 2.0
## The Meshy pitch clip faces off-axis like the two-handed locomotion clips did
## (whole-body yaw baked into the Hips keys). Measured headless: +77 aligns the
## release arm with the sword slash's strike arm, but that anchor points at the
## camera, so the playtested correction is 77 - 180.
const PITCH_YAW_CORRECTION_DEG := -103.0
## Skeleton-space up axis (Hips is a root bone; its keys live in skeleton space
## where +Z is up — same convention as TwoHandedYawAdjust).
const SKELETON_UP := Vector3(0.0, 0.0, 1.0)
## Fraction of the pitch clip where the weapon leaves the hand.
const RELEASE_FRACTION := 0.45
const BLEND_IN_SPEED := 14.0
const EXIT_BLEND_DURATION := 0.25
## Base projectile speed, scaled by throw strength / weapon weight.
const BASE_THROW_SPEED := 14.0
const THROW_SPEED_SCALE_MIN := 0.5
const THROW_SPEED_SCALE_MAX := 2.0


## Rotates every Hips rotation key around skeleton up, turning the whole clip
## to face the given yaw offset (mirrors TwoHandedYawAdjust._rotate_hips).
static func apply_hips_yaw(animation: Animation, degrees: float) -> void:
	if animation == null or is_zero_approx(degrees):
		return
	var correction := Quaternion(SKELETON_UP, deg_to_rad(degrees))
	for track_idx in animation.get_track_count():
		if animation.track_get_type(track_idx) != Animation.TYPE_ROTATION_3D:
			continue
		if not String(animation.track_get_path(track_idx)).ends_with(":Hips"):
			continue
		for key_idx in animation.track_get_key_count(track_idx):
			var q: Quaternion = animation.track_get_key_value(track_idx, key_idx)
			animation.track_set_key_value(track_idx, key_idx, (correction * q).normalized())
		return


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, CLIP_PITCH])


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % TIME_SEEK_NODE, time)


static func set_tree_scale(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % TIME_SCALE_NODE, maxf(speed, 0.001))


## Projectile speed for a throw: stronger arms and lighter weapons throw faster.
## (Later: throws will be gated entirely when weight exceeds strength.)
static func get_throw_speed(throw_strength: float, weapon_weight: float) -> float:
	var scale := clampf(
		throw_strength / maxf(weapon_weight, 0.1),
		THROW_SPEED_SCALE_MIN,
		THROW_SPEED_SCALE_MAX
	)
	return BASE_THROW_SPEED * scale
