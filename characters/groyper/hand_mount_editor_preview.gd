@tool
extends BoneAttachment3D

## When this mount is visible in the editor, pose the skeleton so the preview
## grip matches the in-game hold. Does nothing at runtime.

enum PreviewPose {
	TWO_HAND_AIM_NEUTRAL,
	HIP_FIRE_AIM_NEUTRAL,
	HIP_FIRE_AIM_ADS,
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
	for bone_name: String in poses.keys():
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id >= 0:
			skeleton.set_bone_pose_rotation(bone_id, poses[bone_name] as Quaternion)
	skeleton.force_update_all_bone_transforms()


func _load_preview_poses(anim_player: AnimationPlayer) -> Dictionary:
	match preview_pose:
		PreviewPose.HIP_FIRE_AIM_NEUTRAL:
			return _HIP_FIRE.load_pose_rotations(anim_player, _HIP_FIRE.POSE_NAME_NEUTRAL)
		PreviewPose.HIP_FIRE_AIM_ADS:
			return _HIP_FIRE.load_pose_rotations(anim_player, _HIP_FIRE.POSE_NAME_ADS)
		_:
			return _TWO_HAND.load_pose_rotations(anim_player, _TWO_HAND.POSE_NAME_NEUTRAL)
