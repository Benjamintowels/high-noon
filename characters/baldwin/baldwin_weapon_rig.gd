extends Node
class_name BaldwinWeaponRig

## Draw/holster sword + shield between back holsters and hand mounts.
## Uses the same procedural reach/raise arm poses as GroyperWeaponRig.

enum DrawState { HOLSTERED, DRAWING, EQUIPPED, HOLSTERING }

signal draw_state_changed(new_state: DrawState)

const RIGHT_ARM_BONES := ["RightArm", "RightForeArm", "RightHand"]
const LEFT_ARM_BONES := ["LeftArm", "LeftForeArm", "LeftHand"]

const SWORD_GRIP_NAME := &"SwordGrip"
const SHIELD_GRIP_NAME := &"ShieldGrip"

@export var draw_duration := 0.48
@export var holster_duration := 0.32
@export var draw_grab_threshold := 0.68
@export var holster_reach_offset := Vector3(0.0, 0.06, 0.02)
@export_range(0.0, 0.8, 0.01) var holster_reach_outward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_OUTWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_forward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_FORWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_down := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_DOWN
@export_range(0.0, 0.9, 0.01) var holster_reach_inward_start := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_INWARD_START
@export_range(0.0, 60.0, 1.0) var holster_reach_abduct_deg := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_ABDUCT_DEG
@export var holstered_arm_rotation_deg: Vector3 = GroyperBodyUtils.DEFAULT_HOLSTERED_ARM_ROTATION_DEG

var sword_hand_grip_local := Transform3D(
	Basis(Vector3(0.8480808, 0.0, 0.0), Vector3(0.0, 0.69858235, 0.0), Vector3(0.0, 0.0, 0.4493401)),
	Vector3(0.011335179, 0.038125873, 0.066636376)
)
var shield_hand_grip_local := Transform3D(
	Basis(
		Vector3(0.44269222, -0.15627772, 0.88295025),
		Vector3(-0.42422456, -0.90402275, 0.0526896),
		Vector3(0.7899729, -0.39789447, -0.4665007)
	),
	Vector3(0.051354766, 0.3249485, -0.0027492344)
)

## Which skeleton mounts this rig draws from. Overridden per weapon so each melee
## weapon can holster at its own body location (the back is reserved for
## two-handers). An empty shield mount name means the weapon carries no shield.
var sword_holster_mount_name := "BackSwordHolsterMount"
var shield_holster_mount_name := "BackShieldHolsterMount"
var sword_hand_mount_name := "HandSwordMount"
var shield_hand_mount_name := "HandShieldMount"

var _owner: Node3D
var _skeleton: Skeleton3D
var _sword_holster_socket: Node3D
var _shield_holster_socket: Node3D
var _sword_hand_socket: Node3D
var _shield_hand_socket: Node3D
var _sword_grip: Node3D
var _shield_grip: Node3D
var _sword_holster_local := Transform3D.IDENTITY
var _shield_holster_local := Transform3D.IDENTITY
var _sword_in_hand := false
var _shield_in_hand := false
var _draw_state := DrawState.HOLSTERED
var _draw_progress := 0.0
var _draw_active := false
var _bone_aim_axes: Dictionary = {}
var _right_raise_start: Dictionary = {}
var _left_raise_start: Dictionary = {}
var _sword_raise_start := Transform3D.IDENTITY
var _shield_raise_start := Transform3D.IDENTITY


var _release_arms_when_idle := true


func set_release_arms_when_idle(enabled: bool) -> void:
	_release_arms_when_idle = enabled


func setup(owner_node: Node3D, skeleton: Skeleton3D) -> void:
	_owner = owner_node
	_skeleton = skeleton
	_cache_bone_aim_axes()
	_resolve_mounts()
	reset_to_holster()


func get_draw_state() -> DrawState:
	return _draw_state


func is_holstered() -> bool:
	return _draw_state == DrawState.HOLSTERED


func is_equipped() -> bool:
	return _draw_state == DrawState.EQUIPPED


func is_transitioning() -> bool:
	return _draw_state == DrawState.DRAWING or _draw_state == DrawState.HOLSTERING


func begin_draw() -> void:
	if _draw_state != DrawState.HOLSTERED:
		return
	_draw_state = DrawState.DRAWING
	_draw_progress = 0.0
	_draw_active = true
	draw_state_changed.emit(_draw_state)


func begin_holster() -> void:
	if _draw_state == DrawState.HOLSTERED or _draw_state == DrawState.HOLSTERING:
		return
	if _draw_state == DrawState.EQUIPPED:
		# Re-seed raise/grab cache so put-away can reverse the same draw curve
		# guns use (progress 1→0). EQUIPPED clears that cache on draw finish.
		_prepare_equipped_holster_putaway()
		_draw_progress = 1.0
	elif _draw_state == DrawState.DRAWING:
		# Mid-draw: reverse from the current progress. Re-seed if grab already
		# happened but raise cache was lost.
		if _sword_in_hand and _right_raise_start.is_empty():
			_prepare_equipped_holster_putaway()
	else:
		return
	_draw_state = DrawState.HOLSTERING
	_draw_active = true
	draw_state_changed.emit(_draw_state)


## From EQUIPPED: rebuild the grab-time raise cache so HOLSTERING can play the
## raise/reach pose backward (same reverse-draw pattern as GroyperWeaponRig).
func _prepare_equipped_holster_putaway() -> void:
	if _sword_in_hand and _sword_grip != null and is_instance_valid(_sword_grip):
		# Grip stays at the hand seat during raise reverse; arms reverse to the
		# holster-reach grab pose, then detach snaps the mesh home.
		_sword_raise_start = _sword_grip.transform
		var sword_target := _get_socket_holster_reach_target(
			_sword_holster_socket, _sword_holster_local, _sword_grip
		)
		_apply_reach_for_arm(RIGHT_ARM_BONES, sword_target, 1.0)
		_right_raise_start = _capture_bone_rotations(RIGHT_ARM_BONES)
	if _shield_in_hand and _shield_grip != null and is_instance_valid(_shield_grip):
		_shield_raise_start = _shield_grip.transform
		var shield_target := _get_socket_holster_reach_target(
			_shield_holster_socket, _shield_holster_local, _shield_grip
		)
		_apply_reach_for_arm(LEFT_ARM_BONES, shield_target, 1.0)
		_left_raise_start = _capture_bone_rotations(LEFT_ARM_BONES)


func _get_socket_holster_reach_target(
	holster_socket: Node3D,
	holster_local: Transform3D,
	grip: Node3D
) -> Vector3:
	if holster_socket != null:
		var holster_origin := (holster_socket.global_transform * holster_local).origin
		if grip != null and is_instance_valid(grip):
			return holster_origin + grip.global_transform.basis * holster_reach_offset
		return holster_origin
	return _get_holster_reach_target(grip)


func update(delta: float) -> void:
	if not _draw_active:
		return

	var previous_state := _draw_state
	match _draw_state:
		DrawState.DRAWING:
			_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
			if not _sword_in_hand and _draw_progress >= draw_grab_threshold:
				_attach_weapons_to_hands()
			if _draw_progress >= 1.0:
				_draw_state = DrawState.EQUIPPED
				_draw_progress = 1.0
				_draw_active = false
				_snap_grips_to_hands()
				_clear_raise_cache()
		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_duration, 0.0)
			if (_sword_in_hand or _shield_in_hand) and _draw_progress < draw_grab_threshold:
				_detach_weapons_to_holsters()
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_draw_active = false
				_clear_raise_cache()

	if previous_state != _draw_state:
		draw_state_changed.emit(_draw_state)


func apply_pose_overrides(_delta: float) -> void:
	if _skeleton == null:
		return
	match _draw_state:
		DrawState.DRAWING, DrawState.HOLSTERING:
			_apply_draw_pose(_draw_progress)
		DrawState.HOLSTERED, DrawState.EQUIPPED:
			if _release_arms_when_idle:
				_release_arms_to_animation()


func reset_to_holster() -> void:
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_draw_active = false
	_clear_raise_cache()
	_ensure_grips()
	_detach_weapons_to_holsters()
	_sword_in_hand = false
	_shield_in_hand = false
	draw_state_changed.emit(_draw_state)


func _resolve_mounts() -> void:
	var sword_holster := _skeleton.get_node_or_null(sword_holster_mount_name) as Node3D
	var shield_holster: Node3D = null
	if shield_holster_mount_name != "":
		shield_holster = _skeleton.get_node_or_null(shield_holster_mount_name) as Node3D
	var sword_hand := _skeleton.get_node_or_null(sword_hand_mount_name) as Node3D
	var shield_hand := _skeleton.get_node_or_null(shield_hand_mount_name) as Node3D
	_sword_holster_socket = sword_holster.get_node_or_null("HolsterOffset") as Node3D if sword_holster else null
	_shield_holster_socket = shield_holster.get_node_or_null("HolsterOffset") as Node3D if shield_holster else null
	_sword_hand_socket = _hand_grip_socket(sword_hand)
	_shield_hand_socket = _hand_grip_socket(shield_hand)


## Weapons seat in GripOffset/PoseOffset when the mount has an animatable pose
## node (two-handers); older mounts parent them directly under GripOffset.
static func _hand_grip_socket(mount: Node3D) -> Node3D:
	if mount == null:
		return null
	var pose_socket := mount.get_node_or_null("GripOffset/PoseOffset") as Node3D
	if pose_socket != null:
		return pose_socket
	return mount.get_node_or_null("GripOffset") as Node3D


func _ensure_grips() -> void:
	if (_sword_grip == null or not is_instance_valid(_sword_grip)) and _sword_holster_socket != null:
		_sword_grip = _sword_holster_socket.get_node_or_null(String(SWORD_GRIP_NAME)) as Node3D
	if _sword_grip == null and _sword_hand_socket != null:
		_sword_grip = _sword_hand_socket.get_node_or_null(String(SWORD_GRIP_NAME)) as Node3D
	if (_shield_grip == null or not is_instance_valid(_shield_grip)) and _shield_holster_socket != null:
		_shield_grip = _shield_holster_socket.get_node_or_null(String(SHIELD_GRIP_NAME)) as Node3D
	if _shield_grip == null and _shield_hand_socket != null:
		_shield_grip = _shield_hand_socket.get_node_or_null(String(SHIELD_GRIP_NAME)) as Node3D
	if _sword_grip != null and _sword_holster_socket != null:
		var holstered := _sword_holster_socket.get_node_or_null(String(SWORD_GRIP_NAME)) as Node3D
		if holstered != null:
			_sword_holster_local = holstered.transform
	if _shield_grip != null and _shield_holster_socket != null:
		var holstered := _shield_holster_socket.get_node_or_null(String(SHIELD_GRIP_NAME)) as Node3D
		if holstered != null:
			_shield_holster_local = holstered.transform


func _attach_weapons_to_hands() -> void:
	if _sword_grip != null and is_instance_valid(_sword_grip) and _sword_hand_socket != null and not _sword_in_hand:
		var grip_global := _sword_grip.global_transform
		_cache_raise_start(true)
		_sword_grip.reparent(_sword_hand_socket, true)
		_sword_grip.global_transform = grip_global
		_sword_raise_start = _sword_grip.transform
		_sword_in_hand = true
	if _shield_grip != null and is_instance_valid(_shield_grip) and _shield_hand_socket != null and not _shield_in_hand:
		var grip_global := _shield_grip.global_transform
		_cache_raise_start(false)
		_shield_grip.reparent(_shield_hand_socket, true)
		_shield_grip.global_transform = grip_global
		_shield_raise_start = _shield_grip.transform
		_shield_in_hand = true


func _detach_weapons_to_holsters() -> void:
	if _sword_grip != null and _sword_holster_socket != null and _grip_is_in_hand(_sword_grip, _sword_hand_socket):
		var grip_global := _sword_grip.global_transform
		_sword_grip.reparent(_sword_holster_socket, true)
		_sword_grip.global_transform = grip_global
		_sword_grip.transform = _sword_holster_local
		_sword_in_hand = false
	if _shield_grip != null and _shield_holster_socket != null and _grip_is_in_hand(_shield_grip, _shield_hand_socket):
		var grip_global := _shield_grip.global_transform
		_shield_grip.reparent(_shield_holster_socket, true)
		_shield_grip.global_transform = grip_global
		_shield_grip.transform = _shield_holster_local
		_shield_in_hand = false
	_clear_raise_cache()


func _grip_is_in_hand(grip: Node3D, hand_socket: Node3D) -> bool:
	return (
		grip != null
		and is_instance_valid(grip)
		and hand_socket != null
		and grip.get_parent() == hand_socket
	)


func _snap_grips_to_hands() -> void:
	if _sword_in_hand and _sword_grip != null and is_instance_valid(_sword_grip):
		_sword_grip.transform = sword_hand_grip_local
	if _shield_in_hand and _shield_grip != null and is_instance_valid(_shield_grip):
		_shield_grip.transform = shield_hand_grip_local


func _apply_draw_pose(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	if clamped < draw_grab_threshold:
		var reach_alpha := clamped / draw_grab_threshold
		reach_alpha = reach_alpha * reach_alpha * (3.0 - 2.0 * reach_alpha)
		_apply_reach_toward_holsters(reach_alpha)
	else:
		var raise_alpha := inverse_lerp(draw_grab_threshold, 1.0, clamped)
		raise_alpha = raise_alpha * raise_alpha * (3.0 - 2.0 * raise_alpha)
		_apply_raise_pose(raise_alpha)


func _apply_reach_toward_holsters(alpha: float) -> void:
	var sword_target := _get_holster_reach_target(_sword_grip)
	var shield_target := _get_holster_reach_target(_shield_grip)
	_apply_reach_for_arm(RIGHT_ARM_BONES, sword_target, alpha)
	_apply_reach_for_arm(LEFT_ARM_BONES, shield_target, alpha)


func _apply_raise_pose(alpha: float) -> void:
	var eased := alpha * alpha * (3.0 - 2.0 * alpha)
	_apply_raise_for_arm(RIGHT_ARM_BONES, _right_raise_start, eased)
	_apply_raise_for_arm(LEFT_ARM_BONES, _left_raise_start, eased)
	if _sword_in_hand and _sword_grip != null and is_instance_valid(_sword_grip):
		_sword_grip.transform = _lerp_transform(_sword_raise_start, sword_hand_grip_local, eased)
	if _shield_in_hand and _shield_grip != null and is_instance_valid(_shield_grip):
		_shield_grip.transform = _lerp_transform(_shield_raise_start, shield_hand_grip_local, eased)


func _apply_reach_for_arm(bone_names: Array, target: Vector3, alpha: float) -> void:
	var reach_weights := {
		bone_names[0]: clampf(alpha * 1.15, 0.0, 1.0),
		bone_names[1]: clampf((alpha - 0.12) * 1.2, 0.0, 1.0),
		bone_names[2]: clampf((alpha - 0.28) * 1.25, 0.0, 1.0),
	}
	var rest_fade := 1.0 - clampf(alpha / GroyperBodyUtils.HOLSTER_REST_FADE_REACH, 0.0, 1.0)
	var ik_targets := _compute_reach_chain_poses(bone_names, target, alpha)
	for bone_name: String in bone_names:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_alpha: float = reach_weights.get(bone_name, alpha)
		if bone_alpha <= 0.0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_reach_rest_pose(bone_name, rest_fade))
			continue
		var rest_pose := _get_reach_rest_pose(bone_name, rest_fade)
		var target_pose: Quaternion = ik_targets.get(bone_name, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_rotation(bone_id, rest_pose.slerp(target_pose, bone_alpha))


func _apply_raise_for_arm(bone_names: Array, start_poses: Dictionary, alpha: float) -> void:
	if start_poses.is_empty():
		return
	for bone_name: String in bone_names:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var from_q: Quaternion = start_poses.get(bone_name, Quaternion.IDENTITY)
		var to_q := Quaternion.IDENTITY
		_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, alpha))


func _compute_reach_chain_poses(bone_names: Array, holster_target: Vector3, reach_alpha: float) -> Dictionary:
	var poses := {}
	var arm_guide := GroyperBodyUtils.compute_holster_arm_guide_target(
		_skeleton,
		holster_target,
		reach_alpha,
		holster_reach_outward,
		holster_reach_forward,
		holster_reach_down,
		holster_reach_inward_start
	)
	var arm_id := _skeleton.find_bone(bone_names[0])
	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(bone_names[0], Vector3(-1.0, 0.0, 0.0))
		var arm_pose := _compute_bone_pose_toward(arm_id, arm_guide, arm_axis)
		arm_pose = (
			arm_pose
			* GroyperBodyUtils.reach_abduction_offset(reach_alpha, holster_reach_abduct_deg)
		).normalized()
		poses[bone_names[0]] = arm_pose
	var forearm_id := _skeleton.find_bone(bone_names[1])
	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(bone_names[1], Vector3(-1.0, 0.0, 0.0))
		var forearm_guide_blend := clampf(1.0 - reach_alpha * 1.35, 0.0, 0.5)
		var forearm_target := holster_target.lerp(arm_guide, forearm_guide_blend)
		poses[bone_names[1]] = _compute_bone_pose_toward(forearm_id, forearm_target, forearm_axis)
	poses[bone_names[2]] = Quaternion.IDENTITY
	return poses


func _get_holster_reach_target(grip: Node3D) -> Vector3:
	if grip == null or not is_instance_valid(grip):
		return _owner.global_position
	return grip.global_position + grip.global_transform.basis * holster_reach_offset


func _get_reach_rest_pose(bone_name: String, rest_fade: float) -> Quaternion:
	var holstered := GroyperBodyUtils.holstered_bone_pose_rotation(
		bone_name,
		holstered_arm_rotation_deg
	)
	return holstered.slerp(Quaternion.IDENTITY, 1.0 - rest_fade)


func _cache_raise_start(right_arm: bool) -> void:
	if right_arm:
		_apply_reach_for_arm(
			RIGHT_ARM_BONES,
			_get_holster_reach_target(_sword_grip),
			1.0
		)
		_right_raise_start = _capture_bone_rotations(RIGHT_ARM_BONES)
	else:
		_apply_reach_for_arm(
			LEFT_ARM_BONES,
			_get_holster_reach_target(_shield_grip),
			1.0
		)
		_left_raise_start = _capture_bone_rotations(LEFT_ARM_BONES)


func _capture_bone_rotations(bone_names: Array) -> Dictionary:
	var poses := {}
	for bone_name: String in bone_names:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _release_arms_to_animation() -> void:
	for bone_name: String in RIGHT_ARM_BONES + LEFT_ARM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.reset_bone_pose(bone_id)


func _clear_raise_cache() -> void:
	_right_raise_start.clear()
	_left_raise_start.clear()


func _cache_bone_aim_axes() -> void:
	_bone_aim_axes.clear()
	if _skeleton == null:
		return
	for bone_name: String in RIGHT_ARM_BONES + LEFT_ARM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_bone_aim_axes[bone_name] = GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)


func _compute_bone_pose_toward(bone_id: int, world_target: Vector3, local_aim_axis: Vector3) -> Quaternion:
	var bone_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)
	var to_target := world_target - bone_global.origin
	if to_target.length_squared() < 0.04:
		to_target = -_owner.global_transform.basis.z
	else:
		to_target = to_target.normalized()

	var parent_id := _skeleton.get_bone_parent(bone_id)
	var parent_global := _skeleton.global_transform
	if parent_id >= 0:
		parent_global = _skeleton.global_transform * _skeleton.get_bone_global_pose(parent_id)

	var bone_rest := _skeleton.get_bone_rest(bone_id)
	var rest_global_basis := parent_global.basis * bone_rest.basis
	var aim_vector := (rest_global_basis * local_aim_axis).normalized()
	var twist := _safe_quat_between(aim_vector, to_target)
	var rest_global_rot := rest_global_basis.get_rotation_quaternion()
	var new_global_rot := twist * rest_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return rest_rot.inverse() * parent_rot.inverse() * new_global_rot


func _safe_quat_between(from_dir: Vector3, to_dir: Vector3) -> Quaternion:
	if from_dir.length_squared() < 0.0001 or to_dir.length_squared() < 0.0001:
		return Quaternion.IDENTITY
	var axis := from_dir.cross(to_dir)
	if axis.length_squared() < 0.0001:
		if from_dir.dot(to_dir) > 0.0:
			return Quaternion.IDENTITY
		axis = from_dir.cross(Vector3.UP)
		if axis.length_squared() < 0.0001:
			axis = from_dir.cross(Vector3.RIGHT)
	return Quaternion(axis.normalized(), from_dir.angle_to(to_dir))


func _lerp_transform(from: Transform3D, to: Transform3D, alpha: float) -> Transform3D:
	return Transform3D(
		from.basis.slerp(to.basis, alpha).orthonormalized(),
		from.origin.lerp(to.origin, alpha)
	)
