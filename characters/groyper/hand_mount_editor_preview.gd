@tool
extends BoneAttachment3D

## When this mount is visible in the editor, pose the skeleton to
## TwoHandAim/neutral so the preview grip matches the in-game hip hold.
## Does nothing at runtime.

const _CONFIG := preload("res://characters/groyper/two_hand_aim_pose_config.gd")

var _preview_applied := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		set_process(false)


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		return
	if visible:
		if not _preview_applied:
			_apply_two_hand_neutral_preview()
			_preview_applied = true
	else:
		_preview_applied = false


func _apply_two_hand_neutral_preview() -> void:
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
	var poses: Dictionary = _CONFIG.load_pose_rotations(anim_player, _CONFIG.POSE_NAME_NEUTRAL)
	if poses.is_empty():
		return
	for bone_name: String in poses.keys():
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id >= 0:
			skeleton.set_bone_pose_rotation(bone_id, poses[bone_name] as Quaternion)
	skeleton.force_update_all_bone_transforms()
