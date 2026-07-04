extends GroyperRagdoll
class_name SkelyRagdoll

## Mixamo bone aliases for the shared Groyper defeat ragdoll solver.

const SkeletonAnimUtilsScript := preload("res://characters/enemies/skeleton_anim_utils.gd")

const FOOT_GROYPER_BONE_NAMES := [
	"LeftFoot",
	"RightFoot",
	"LeftToeBase",
	"RightToeBase",
]

const FOOT_SKELY_BONE_NAMES := [
	"mixamorig_LeftFoot",
	"mixamorig_RightFoot",
	"mixamorig_LeftToeBase",
	"mixamorig_RightToeBase",
	"mixamorig:LeftFoot",
	"mixamorig:RightFoot",
	"mixamorig:LeftToeBase",
	"mixamorig:RightToeBase",
]


func _ready() -> void:
	debug_ragdoll = false
	super._ready()


func _mixamo_bone_name(groyper_name: String) -> String:
	return SkeletonAnimUtilsScript.GROYPER_TO_SKELY_BONE.get(groyper_name, groyper_name)


func _get_bone_id(groyper_name: String) -> int:
	return _resolve_skely_bone_id(groyper_name)


func _resolve_skely_bone_id(groyper_name: String) -> int:
	if _skeleton == null:
		return -1

	var mapped := _mixamo_bone_name(groyper_name)
	for bone_name in [
		mapped,
		groyper_name,
		"mixamorig:%s" % groyper_name,
		"mixamorig_%s" % groyper_name,
	]:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			return bone_id
	return -1


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
			return _actor.global_position + Vector3(0.0, 0.28, 0.0)
		return Vector3.ZERO

	var head_id := _get_bone_id("Head")
	if head_id < 0:
		return _actor.global_position + Vector3(0.0, 0.28, 0.0)
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)).origin


var _model_base_scale := Vector3.ONE


func activate(hit_info: Dictionary, animation_player: AnimationPlayer = null) -> void:
	_resolve_nodes()
	if _model != null:
		_model_base_scale = _model.scale
	_force_pose_world_update()
	_snap_visual_feet_to_floor()
	super.activate(hit_info, animation_player)
	if not _active or _actor == null:
		return
	_force_pose_world_update()
	_snap_visual_feet_to_floor()
	_base_actor_transform = _actor.global_transform
	_floor_y = _sample_floor_y(_actor.global_position)


func _get_actor_feet_offset() -> float:
	if _skeleton == null or _actor == null:
		return super._get_actor_feet_offset()

	var foot_y := _get_lowest_foot_world_y()
	if foot_y == INF:
		return super._get_actor_feet_offset()
	return maxf(_actor.global_position.y - foot_y, 0.0)


func _get_defeat_hip_drop() -> float:
	return sin(_fall_pitch) * _get_visual_body_height() * 0.58


func _get_visual_body_height() -> float:
	var foot_y := _get_lowest_foot_world_y()
	if foot_y == INF:
		return 0.28
	return maxf(_get_head_world_position().y - foot_y, 0.12)


func _force_pose_world_update() -> void:
	if _model != null:
		_model.force_update_transform()
	if _skeleton != null:
		_skeleton.force_update_transform()


func _snap_visual_feet_to_floor() -> void:
	if _actor == null or _skeleton == null:
		return

	_force_pose_world_update()
	var lowest_y := _get_ragdoll_lowest_world_y()
	if lowest_y == INF:
		return

	var floor_y := _sample_floor_y(_actor.global_position)
	var correction := (floor_y + ACTOR_GROUND_OFFSET) - lowest_y
	if absf(correction) <= 0.001:
		return
	_actor.global_position.y += correction


func _get_lowest_foot_world_y() -> float:
	if _skeleton == null:
		return INF

	var lowest := INF
	for bone_name in FOOT_GROYPER_BONE_NAMES:
		var bone_id := _resolve_skely_bone_id(bone_name)
		if bone_id < 0:
			continue
		var bone_y := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin.y
		lowest = minf(lowest, bone_y)
	for bone_name in FOOT_SKELY_BONE_NAMES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_y := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin.y
		lowest = minf(lowest, bone_y)
	return lowest


func _get_ragdoll_lowest_world_y() -> float:
	_force_pose_world_update()

	var lowest := _get_lowest_foot_world_y()
	var drag_lowest := _get_drag_lowest_world_y()
	if drag_lowest != INF:
		lowest = drag_lowest if lowest == INF else minf(lowest, drag_lowest)

	if lowest != INF:
		return lowest
	return _get_skeleton_lowest_world_y()


func _get_skeleton_lowest_world_y() -> float:
	if _skeleton == null:
		return INF

	var lowest := INF
	for bone_id in _skeleton.get_bone_count():
		var bone_y := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin.y
		lowest = minf(lowest, bone_y)
	return lowest


## Skely's scaled Model rotates in place; vertical body lerp from GroyperRagdoll can lift the corpse.
func _apply_body_transform(sim_delta: float) -> void:
	if _lasso_drag_mode or _lasso_settling or _airborne:
		super._apply_body_transform(sim_delta)
		return

	var saved_y := _actor.global_position.y
	super._apply_body_transform(sim_delta)
	_actor.global_position.y = saved_y


## GroyperRagdoll assigns Model.basis directly, which strips Skely's 0.15 visual scale.
func _apply_model_fall_rotation() -> void:
	var upright_euler := _upright_model_rotation
	if _lasso_settling and _model != null:
		upright_euler.y = _get_settle_facing_yaw()

	if _model != null:
		var upright := Basis.from_euler(upright_euler)
		var fall := Basis.from_euler(Vector3(_fall_pitch, _fall_yaw, _fall_roll))
		_model.basis = upright * fall
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


func _clamp_ragdoll_to_floor(_sim_delta: float) -> void:
	if not _active or _actor == null or _airborne:
		return

	_force_pose_world_update()
	_floor_y = _sample_floor_y(_actor.global_position)

	if _lasso_drag_mode or _lasso_settling:
		var raise := 0.0
		var head_pos := _get_head_world_position()
		var head_floor := _floor_y + LASSO_HEAD_FLOOR_CLEARANCE
		if head_pos.y < head_floor:
			raise = maxf(raise, head_floor - head_pos.y)

		var lasso_lowest_y := _get_ragdoll_lowest_world_y()
		if lasso_lowest_y != INF:
			var lasso_floor_fix := _floor_y + ACTOR_GROUND_OFFSET - lasso_lowest_y
			if lasso_floor_fix > 0.0:
				raise = maxf(raise, lasso_floor_fix)

		if raise <= 0.001:
			return
		_actor.global_position.y += raise
		_base_actor_transform.origin.y += raise
		return

	var lowest_y := _get_ragdoll_lowest_world_y()
	if lowest_y == INF:
		return

	var floor_fix := _floor_y + ACTOR_GROUND_OFFSET - lowest_y
	if absf(floor_fix) <= 0.001:
		return

	_actor.global_position.y += floor_fix
	_base_actor_transform.origin.y += floor_fix
