@tool
extends BoneAttachment3D

## When this mount is visible in the editor, pose the skeleton so the preview
## grip matches the in-game hold. Does nothing at runtime.

enum PreviewPose {
	TWO_HAND_AIM_NEUTRAL,
	HIP_FIRE_AIM_NEUTRAL,
	HIP_FIRE_AIM_ADS,
	BOW_AIM_NEUTRAL,
	BOW_AIM_ADS,
	BOW_AIM_FULL_DRAW,
}

var _preview_pose: PreviewPose = PreviewPose.TWO_HAND_AIM_NEUTRAL
@export var preview_pose: PreviewPose = PreviewPose.TWO_HAND_AIM_NEUTRAL:
	get:
		return _preview_pose
	set(value):
		if _preview_pose == value:
			return
		_preview_pose = value
		_preview_applied = false
		if Engine.is_editor_hint() and visible and is_inside_tree():
			_apply_preview()
			_preview_applied = true

const _TWO_HAND := preload("res://characters/groyper/two_hand_aim_pose_config.gd")
const _HIP_FIRE := preload("res://characters/groyper/hip_fire_aim_pose_config.gd")
const _BOW := preload("res://characters/groyper/bow_aim_pose_config.gd")

var _preview_applied := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if visible:
		if not _preview_applied:
			_apply_preview()
			_preview_applied = true
	else:
		_preview_applied = false


func _apply_preview() -> void:
	var skeleton := get_parent() as Skeleton3D
	if skeleton == null:
		return
	var armature := skeleton.get_parent()
	if armature == null:
		return
	var body := armature.get_parent()
	if body == null:
		return
	var anim_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	var poses := _load_preview_poses(anim_player)
	if poses.is_empty():
		return
	# Rotations only — runtime ignores position keys, so the preview must too.
	for pose_bone: String in poses.keys():
		var bone_id := skeleton.find_bone(pose_bone)
		if bone_id >= 0:
			skeleton.set_bone_pose_rotation(bone_id, poses[pose_bone] as Quaternion)
	# LeftHand mounts: also stamp a mirrored HipFireAim onto the left gun arm
	# so GripOffset tuning matches dual-wield runtime (right clip only keys Right*).
	if (
		bone_name == "LeftHand"
		and (
			preview_pose == PreviewPose.HIP_FIRE_AIM_NEUTRAL
			or preview_pose == PreviewPose.HIP_FIRE_AIM_ADS
		)
	):
		_apply_mirrored_left_gun_arm(skeleton, poses)
	skeleton.force_update_all_bone_transforms()


func _apply_mirrored_left_gun_arm(skeleton: Skeleton3D, right_poses: Dictionary) -> void:
	# Match runtime dual mirror: arm chain only (no clavicle) + quat reflection.
	const RIGHT_TO_LEFT := {
		"RightArm": "LeftArm",
		"RightForeArm": "LeftForeArm",
		"RightHand": "LeftHand",
	}
	for right_name: String in RIGHT_TO_LEFT.keys():
		if not right_poses.has(right_name):
			continue
		var left_name: String = RIGHT_TO_LEFT[right_name]
		var bone_id := skeleton.find_bone(left_name)
		if bone_id < 0:
			continue
		var q: Quaternion = right_poses[right_name]
		var mirrored := Quaternion(q.x, -q.y, -q.z, q.w).normalized()
		skeleton.set_bone_pose_rotation(bone_id, mirrored)


func _load_preview_poses(anim_player: AnimationPlayer) -> Dictionary:
	match preview_pose:
		PreviewPose.HIP_FIRE_AIM_NEUTRAL:
			return _HIP_FIRE.load_pose_rotations(anim_player, _HIP_FIRE.POSE_NAME_NEUTRAL)
		PreviewPose.HIP_FIRE_AIM_ADS:
			return _HIP_FIRE.load_pose_rotations(anim_player, _HIP_FIRE.POSE_NAME_ADS)
		PreviewPose.BOW_AIM_NEUTRAL:
			return _BOW.sample_pose_rotations(anim_player, _BOW.POSE_NAME_NEUTRAL, 0.0)
		PreviewPose.BOW_AIM_ADS:
			return _BOW.sample_pose_rotations(anim_player, _BOW.POSE_NAME_ADS, 0.0)
		PreviewPose.BOW_AIM_FULL_DRAW:
			return _BOW.sample_pose_rotations(anim_player, _BOW.POSE_NAME_NEUTRAL, 1.0)
		_:
			return _TWO_HAND.load_pose_rotations(anim_player, _TWO_HAND.POSE_NAME_NEUTRAL)
