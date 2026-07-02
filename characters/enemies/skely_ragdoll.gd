extends GroyperRagdoll
class_name SkelyRagdoll

## Mixamo bone aliases for the shared Groyper defeat ragdoll solver.

const SkeletonAnimUtilsScript := preload("res://characters/enemies/skeleton_anim_utils.gd")


func _ready() -> void:
	debug_ragdoll = false
	super._ready()


func _mixamo_bone_name(groyper_name: String) -> String:
	return SkeletonAnimUtilsScript.GROYPER_TO_SKELY_BONE.get(groyper_name, groyper_name)


func _get_bone_id(groyper_name: String) -> int:
	if _skeleton == null:
		return -1
	return _skeleton.find_bone(_mixamo_bone_name(groyper_name))


func _groyper_name_for_skeleton_bone(skely_bone: String) -> String:
	for groyper_name in SkeletonAnimUtilsScript.GROYPER_TO_SKELY_BONE:
		if SkeletonAnimUtilsScript.GROYPER_TO_SKELY_BONE[groyper_name] == skely_bone:
			return groyper_name
	return ""


func apply_skeleton_poses() -> void:
	if not _active or _skeleton == null:
		return

	for bone_name: String in _captured_bone_poses:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var pose: Quaternion = _captured_bone_poses[bone_name]
		var groyper_name := _groyper_name_for_skeleton_bone(bone_name)
		if not groyper_name.is_empty() and _limb_angles.has(groyper_name):
			var offset: Vector3 = _limb_angles[groyper_name]
			if offset.length_squared() > 0.000001:
				var offset_q := Basis.from_euler(offset).get_rotation_quaternion()
				pose = (offset_q * pose).normalized()
		_skeleton.set_bone_pose_rotation(bone_id, pose)


func _get_head_world_position() -> Vector3:
	if _skeleton == null:
		if _actor != null:
			return _actor.global_position + Vector3(0.0, 1.2, 0.0)
		return Vector3.ZERO

	var head_id := _get_bone_id("Head")
	if head_id < 0:
		return _actor.global_position + Vector3(0.0, 1.2, 0.0)
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)).origin


var _model_base_scale := Vector3.ONE


func activate(hit_info: Dictionary, animation_player: AnimationPlayer = null) -> void:
	_resolve_nodes()
	if _model != null:
		_model_base_scale = _model.scale
	super.activate(hit_info, animation_player)


## GroyperRagdoll assigns Model.basis directly, which strips Skely's 0.15 visual scale.
func _apply_model_fall_rotation() -> void:
	var upright_euler := _upright_model_rotation
	if _lasso_settling and _model != null:
		upright_euler.y = _get_settle_facing_yaw()

	if _model != null:
		var combined := Basis.from_euler(upright_euler) * Basis.from_euler(
			Vector3(_fall_pitch, _fall_yaw, _fall_roll)
		)
		_model.rotation = combined.get_euler()
		_model.scale = _model_base_scale
		return

	if _actor != null:
		_actor.rotation.x = _fall_pitch
		_actor.rotation.y = upright_euler.y + _fall_yaw
		_actor.rotation.z = _fall_roll


func _get_drag_lowest_world_y() -> float:
	if _skeleton == null:
		return _actor.global_position.y if _actor != null else 0.0

	var lowest := INF
	for bone_name in LIMB_DRAG_FLOOR_BONES:
		var bone_id := _get_bone_id(bone_name)
		if bone_id < 0:
			continue
		var bone_y := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin.y
		lowest = minf(lowest, bone_y)

	if lowest == INF and _actor != null:
		return _actor.global_position.y
	return lowest
