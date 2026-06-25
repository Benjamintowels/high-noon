extends Node
class_name GroyperWeaponRig

const BULLET_SCENE := preload("res://gameplay/shooting/bullet.tscn")
const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"
const AIM_IK_BONES := [ARM_BONE, FOREARM_BONE]
const AIM_BONES := [ARM_BONE, FOREARM_BONE, HAND_BONE]
const ARM_AIM_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_arm_aim_modifier.gd")

enum DrawState { HOLSTERED, DRAWING, HOLSTERING, AIMING }

signal draw_state_changed(new_state: DrawState)

@export var draw_duration := 0.48
@export var holster_duration := 0.32
@export var draw_grab_threshold := 0.68
@export var holster_reach_offset := Vector3(0.0, 0.06, 0.02)
@export_range(0.0, 0.8, 0.01) var holster_reach_outward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_OUTWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_forward := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_FORWARD
@export_range(0.0, 0.5, 0.01) var holster_reach_down := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_DOWN
@export_range(0.0, 0.9, 0.01) var holster_reach_inward_start := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_INWARD_START
@export_range(0.0, 60.0, 1.0) var holster_reach_abduct_deg := GroyperBodyUtils.DEFAULT_HOLSTER_REACH_ABDUCT_DEG
@export var hand_grip_position := Vector3(-0.1, -0.05, -0.08)
@export var hand_grip_rotation_deg := Vector3(-161.0, 13.0, -160.0)
@export var aim_arm_target_distance := 55.0
@export var aim_pose_smooth := 16.0
@export var holstered_arm_rotation_deg: Vector3 = GroyperBodyUtils.DEFAULT_HOLSTERED_ARM_ROTATION_DEG

var _owner: Node3D
var _skeleton: Skeleton3D
var _hip_holster_mount: BoneAttachment3D
var _holster_socket: Node3D
var _hand_revolver_mount: BoneAttachment3D
var _revolver_grip: Node3D
var _hand_muzzle: Marker3D

var _draw_state := DrawState.HOLSTERED
var _draw_progress := 0.0
var _draw_active := false
var _gun_in_hand := false
var _holster_grip_local := Transform3D.IDENTITY
var _raise_start_poses: Dictionary = {}
var _raise_aim_target := Vector3.ZERO
var _raise_grip_local_start := Transform3D.IDENTITY
var _bone_aim_axes: Dictionary = {}
var _aim_target := Vector3.ZERO
var _smoothed_arm_aim_target := Vector3.ZERO
var _aim_bone_poses_smoothed: Dictionary = {}
var _muzzle_offset_cached := false
var _muzzle_offset_in_hand := Vector3.ZERO
var _forearm_recoil := 0.0
var _forearm_recoil_rotation_deg := Vector3(-22.0, 0.0, 0.0)
var _forearm_recoil_recovery := 16.0
var _prep_aim := false
var _overworld_hold_mode := false
var _equipped_weapon_id: GroyperWeapons.Id = GroyperWeapons.get_enemy_weapon()


func setup(
	owner_node: Node3D,
	skeleton: Skeleton3D,
	weapon_id: GroyperWeapons.Id = GroyperWeapons.get_enemy_weapon()
) -> void:
	_owner = owner_node
	_skeleton = skeleton
	_equipped_weapon_id = weapon_id
	_setup_weapon_mounts()
	_cache_bone_aim_axes()
	_setup_arm_aim_modifier()


func reset_to_holster() -> void:
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_draw_active = false
	_gun_in_hand = false
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	if _overworld_hold_mode:
		_release_arm_to_animation()
	else:
		_reset_aim_bone_poses()
	_ensure_revolver_grip()
	if _revolver_grip != null and _holster_socket != null and _revolver_grip.get_parent() != _holster_socket:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_holster_socket, true)
		_revolver_grip.global_transform = grip_global
	_apply_holster_grip_transform()
	_invalidate_muzzle_cache()


func on_revolver_dropped() -> void:
	_gun_in_hand = false
	_draw_active = false
	_revolver_grip = null


func begin_draw() -> void:
	if _draw_state != DrawState.HOLSTERED:
		return
	_draw_state = DrawState.DRAWING
	_draw_progress = 0.0
	_draw_active = true


func is_aiming() -> bool:
	return _draw_state == DrawState.AIMING


func get_draw_progress() -> float:
	return _draw_progress


func is_drawing() -> bool:
	return (
		_draw_state == DrawState.DRAWING
		or _draw_state == DrawState.AIMING
		or _draw_state == DrawState.HOLSTERING
	)


func is_holstered() -> bool:
	return _draw_state == DrawState.HOLSTERED


func get_draw_state() -> DrawState:
	return _draw_state


func can_fire() -> bool:
	return _draw_state == DrawState.AIMING


func can_use_reticle() -> bool:
	return _draw_state == DrawState.AIMING


func enable_overworld_hold_mode(enabled: bool) -> void:
	_overworld_hold_mode = enabled


func update(delta: float, aim_world_target: Vector3) -> void:
	if _skeleton == null:
		return

	_aim_target = aim_world_target
	_update_forearm_recoil(delta)
	if _overworld_hold_mode:
		var rmb_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
		_update_overworld_draw(rmb_held, delta)
	else:
		_update_draw(delta)


func set_prep_aim(active: bool) -> void:
	_prep_aim = active


func get_aim_target() -> Vector3:
	return _aim_target


func apply_pose_overrides(delta: float) -> void:
	if _skeleton == null or _is_defeat_ragdoll_active():
		return

	# Overworld: leave the right arm alone while holstered so locomotion can drive it.
	if _overworld_hold_mode and _draw_state == DrawState.HOLSTERED:
		return

	match _draw_state:
		DrawState.AIMING:
			_apply_arm_aim(_aim_target, delta)
		DrawState.DRAWING, DrawState.HOLSTERING:
			_apply_draw_pose(_draw_progress)
		DrawState.HOLSTERED:
			if _prep_aim:
				_apply_arm_aim(_aim_target, delta)
			else:
				_reset_aim_bone_poses()


func fire_at(target: Vector3) -> void:
	if _draw_state != DrawState.AIMING:
		return

	var origin := get_muzzle_global_position()
	var to_target := target - origin
	if to_target.length_squared() < 0.0001:
		return

	var direction := to_target.normalized()
	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return

	var bullet: Node3D = BULLET_SCENE.instantiate()
	scene_root.add_child(bullet)
	var exclude: Array = [_owner]
	var hitbox := _owner.get_node_or_null("Hitbox")
	if hitbox is CollisionObject3D:
		exclude.append(hitbox)
	bullet.setup(origin, direction, exclude, _owner)
	SHOT_BEAM.spawn(scene_root, origin, origin + direction * 1.2)
	MuzzleFlashFXScript.spawn(scene_root, origin)
	_forearm_recoil = 1.0


func capture_replay_state() -> Dictionary:
	return {
		"draw_state": _draw_state,
		"draw_progress": _draw_progress,
		"gun_in_hand": _gun_in_hand,
		"draw_active": _draw_active,
		"aim_target": _aim_target,
		"forearm_recoil": _forearm_recoil,
	}


func apply_replay_state(state: Dictionary) -> void:
	if state.is_empty():
		return

	_draw_state = state.get("draw_state", DrawState.HOLSTERED)
	_draw_progress = state.get("draw_progress", 0.0)
	_gun_in_hand = state.get("gun_in_hand", false)
	_draw_active = state.get("draw_active", false)
	_aim_target = state.get("aim_target", _aim_target)
	_forearm_recoil = state.get("forearm_recoil", 0.0)

	_sync_replay_weapon_mount()
	_ensure_replay_draw_cache()
	apply_pose_overrides(1.0)


func _sync_replay_weapon_mount() -> void:
	if _gun_in_hand and _revolver_grip != null and _hand_revolver_mount != null \
			and _revolver_grip.get_parent() != _hand_revolver_mount:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_hand_revolver_mount, true)
		_revolver_grip.global_transform = grip_global
		_invalidate_muzzle_cache()
	elif not _gun_in_hand and _revolver_grip != null and _holster_socket != null \
			and _revolver_grip.get_parent() != _holster_socket:
		var holster_global := _revolver_grip.global_transform
		_revolver_grip.reparent(_holster_socket, true)
		_revolver_grip.global_transform = holster_global
		_apply_holster_grip_transform()
		_invalidate_muzzle_cache()


func _ensure_replay_draw_cache() -> void:
	if _draw_state != DrawState.DRAWING or _draw_progress < draw_grab_threshold:
		return
	if not _raise_start_poses.is_empty():
		return
	if not _gun_in_hand:
		if _revolver_grip == null or _hand_revolver_mount == null:
			return
		var holster_target := _get_holster_reach_target()
		var grip_global := _revolver_grip.global_transform
		_cache_raise_start_poses(holster_target)
		_revolver_grip.reparent(_hand_revolver_mount, true)
		_revolver_grip.global_transform = grip_global
		_raise_grip_local_start = _revolver_grip.transform
		_gun_in_hand = true
		_invalidate_muzzle_cache()
		_resolve_hand_muzzle()
	else:
		_cache_raise_start_poses(_get_holster_reach_target())
		_raise_grip_local_start = _revolver_grip.transform if _revolver_grip else Transform3D.IDENTITY
	_raise_aim_target = _aim_target


func get_muzzle_global_position() -> Vector3:
	_resolve_hand_muzzle()
	if _hand_muzzle != null and is_instance_valid(_hand_muzzle):
		return _hand_muzzle.global_position

	if _skeleton == null:
		return _owner.global_position

	return _owner.global_position


func _setup_weapon_mounts() -> void:
	_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
	_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	_hand_revolver_mount = _skeleton.get_node_or_null("HandRevolverMount") as BoneAttachment3D

	if _holster_socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			_holster_socket,
			_equipped_weapon_id
		)

	if _revolver_grip == null or _hand_revolver_mount == null:
		push_error("GroyperWeaponRig: missing weapon mounts.")
		return

	_holster_grip_local = _revolver_grip.transform
	_apply_holster_grip_transform()
	_resolve_hand_muzzle()


func _ensure_revolver_grip() -> void:
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		return
	if _holster_socket == null and _skeleton != null:
		_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
		_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	if _holster_socket != null:
		_revolver_grip = _holster_socket.get_node_or_null("RevolverGrip") as Node3D


func _setup_arm_aim_modifier() -> void:
	if _skeleton == null:
		return
	var existing := _skeleton.get_node_or_null("ArmAimModifier")
	if existing != null:
		existing.queue_free()
	var modifier = ARM_AIM_MODIFIER_SCRIPT.new()
	modifier.name = "ArmAimModifier"
	modifier.apply_overrides = apply_pose_overrides
	_skeleton.add_child(modifier)


func _is_defeat_ragdoll_active() -> bool:
	if _owner == null:
		return false
	for child in _owner.get_children():
		if child is GroyperRagdoll and child.is_active():
			return true
	return false


func _resolve_hand_muzzle() -> void:
	if _revolver_grip:
		_hand_muzzle = _revolver_grip.find_child("Muzzle", true, false) as Marker3D


func _cache_muzzle_hand_offset() -> void:
	_resolve_hand_muzzle()
	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id < 0 or _hand_muzzle == null:
		return

	var hand_global := _skeleton.global_transform * _skeleton.get_bone_global_pose(hand_id)
	_muzzle_offset_in_hand = hand_global.basis.inverse() * (_hand_muzzle.global_position - hand_global.origin)
	_muzzle_offset_cached = true


func _invalidate_muzzle_cache() -> void:
	_muzzle_offset_cached = false


func _snap_gun_grip_to_hand() -> void:
	if _gun_in_hand and _revolver_grip != null:
		_revolver_grip.transform = _get_hand_grip_local()
		_invalidate_muzzle_cache()


func _update_draw(delta: float) -> void:
	if not _draw_active:
		return

	match _draw_state:
		DrawState.DRAWING:
			_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
			if not _gun_in_hand and _draw_progress >= draw_grab_threshold:
				_attach_gun_to_hand()
			if _draw_progress >= 1.0:
				_draw_state = DrawState.AIMING
				_snap_gun_grip_to_hand()
				_clear_raise_cache()
				_seed_arm_aim_smoothing()
		DrawState.AIMING:
			pass


func _update_overworld_draw(rmb_held: bool, delta: float) -> void:
	var previous_state := _draw_state

	match _draw_state:
		DrawState.HOLSTERED:
			if rmb_held:
				_draw_state = DrawState.DRAWING
				_draw_progress = 0.0

		DrawState.DRAWING:
			if rmb_held:
				_draw_progress = minf(_draw_progress + delta / draw_duration, 1.0)
				if not _gun_in_hand and _draw_progress >= draw_grab_threshold:
					_attach_gun_to_hand()
				if _draw_progress >= 1.0:
					_draw_state = DrawState.AIMING
					_snap_gun_grip_to_hand()
					_clear_raise_cache()
					_seed_arm_aim_smoothing()
			else:
				_draw_state = DrawState.HOLSTERING

		DrawState.AIMING:
			if not rmb_held:
				_draw_state = DrawState.HOLSTERING

		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_duration, 0.0)
			if _gun_in_hand and _draw_progress < draw_grab_threshold:
				_detach_gun_to_holster()
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_clear_raise_cache()
				_clear_arm_aim_smoothing()

	if previous_state != _draw_state:
		if _overworld_hold_mode and _draw_state == DrawState.HOLSTERED:
			_release_arm_to_animation()
		draw_state_changed.emit(_draw_state)


func _detach_gun_to_holster() -> void:
	if not _gun_in_hand or _revolver_grip == null or _holster_socket == null:
		return

	var grip_global := _revolver_grip.global_transform
	_revolver_grip.reparent(_holster_socket, true)
	_revolver_grip.global_transform = grip_global
	_apply_holster_grip_transform()
	_gun_in_hand = false
	_clear_raise_cache()
	_invalidate_muzzle_cache()


func _attach_gun_to_hand() -> void:
	if _gun_in_hand or _revolver_grip == null or _hand_revolver_mount == null:
		return

	var holster_target := _get_holster_reach_target()
	var grip_global := _revolver_grip.global_transform
	_cache_raise_start_poses(holster_target)

	_revolver_grip.reparent(_hand_revolver_mount, true)
	_revolver_grip.global_transform = grip_global
	_raise_grip_local_start = _revolver_grip.transform
	_gun_in_hand = true
	_invalidate_muzzle_cache()
	_resolve_hand_muzzle()
	_raise_aim_target = _aim_target


func _apply_draw_pose(progress: float) -> void:
	var clamped := clampf(progress, 0.0, 1.0)
	if clamped < draw_grab_threshold:
		var reach_alpha := clamped / draw_grab_threshold
		reach_alpha = reach_alpha * reach_alpha * (3.0 - 2.0 * reach_alpha)
		_apply_reach_toward_holster(reach_alpha)
	else:
		var raise_alpha := inverse_lerp(draw_grab_threshold, 1.0, clamped)
		raise_alpha = raise_alpha * raise_alpha * (3.0 - 2.0 * raise_alpha)
		_apply_raise_pose(raise_alpha)


func _get_holster_reach_target() -> Vector3:
	if _revolver_grip == null:
		return _owner.global_position
	return _revolver_grip.global_position + _revolver_grip.global_transform.basis * holster_reach_offset


func _apply_reach_toward_holster(alpha: float) -> void:
	_apply_reach_toward_target(alpha, _get_holster_reach_target())


func _apply_reach_toward_target(alpha: float, target: Vector3) -> void:
	var reach_weights := {
		ARM_BONE: clampf(alpha * 1.15, 0.0, 1.0),
		FOREARM_BONE: clampf((alpha - 0.12) * 1.2, 0.0, 1.0),
		HAND_BONE: clampf((alpha - 0.28) * 1.25, 0.0, 1.0),
	}
	var rest_fade := 1.0 - clampf(
		alpha / GroyperBodyUtils.HOLSTER_REST_FADE_REACH,
		0.0,
		1.0
	)
	var ik_targets := _compute_reach_chain_poses(target, alpha)

	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var bone_alpha: float = reach_weights.get(bone_name, alpha)
		if bone_alpha <= 0.0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_reach_rest_pose(bone_name, rest_fade))
			continue

		var rest_pose := _get_reach_rest_pose(bone_name, rest_fade)
		var target_pose: Quaternion = ik_targets.get(bone_name, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			rest_pose.slerp(target_pose, bone_alpha)
		)


func _get_reach_rest_pose(bone_name: String, rest_fade: float) -> Quaternion:
	var holstered := _get_holstered_bone_pose(bone_name)
	return holstered.slerp(Quaternion.IDENTITY, 1.0 - rest_fade)


func _set_aim_bones_to_identity() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _compute_chain_bone_poses_toward(target: Vector3, bone_names: Array) -> Dictionary:
	_set_aim_bones_to_identity()
	var poses := {}

	for bone_name: String in bone_names:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var local_axis: Vector3 = _bone_aim_axes.get(bone_name, Vector3(-1.0, 0.0, 0.0))
		var pose := _compute_bone_pose_toward(bone_id, target, local_axis)
		poses[bone_name] = pose
		_skeleton.set_bone_pose_rotation(bone_id, pose)

	return poses


func _get_holster_arm_guide_target(holster_target: Vector3, reach_alpha: float) -> Vector3:
	return GroyperBodyUtils.compute_holster_arm_guide_target(
		_skeleton,
		holster_target,
		reach_alpha,
		holster_reach_outward,
		holster_reach_forward,
		holster_reach_down,
		holster_reach_inward_start
	)


func _compute_reach_chain_poses(holster_target: Vector3, reach_alpha: float) -> Dictionary:
	_set_aim_bones_to_identity()
	var poses := {}
	var arm_guide := _get_holster_arm_guide_target(holster_target, reach_alpha)

	var arm_id := _skeleton.find_bone(ARM_BONE)
	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(ARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var arm_pose := _compute_bone_pose_toward(arm_id, arm_guide, arm_axis)
		arm_pose = (
			arm_pose
			* GroyperBodyUtils.reach_abduction_offset(reach_alpha, holster_reach_abduct_deg)
		).normalized()
		poses[ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(FOREARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var forearm_guide_blend := clampf(1.0 - reach_alpha * 1.35, 0.0, 0.5)
		var forearm_target := holster_target.lerp(arm_guide, forearm_guide_blend)
		var forearm_pose := _compute_bone_pose_toward(forearm_id, forearm_target, forearm_axis)
		poses[FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	poses[HAND_BONE] = Quaternion.IDENTITY
	return poses


func _cache_raise_start_poses(holster_target: Vector3) -> void:
	_apply_reach_toward_target(1.0, holster_target)
	_raise_start_poses = _capture_aim_bone_rotations()


func _apply_raise_pose(alpha: float) -> void:
	if _raise_start_poses.is_empty():
		return

	var aim_poses := _compute_aim_bone_rotations(_raise_aim_target)
	var eased := alpha * alpha * (3.0 - 2.0 * alpha)

	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var from_q: Quaternion = _raise_start_poses.get(bone_name, Quaternion.IDENTITY)
		var to_q: Quaternion
		if bone_name == HAND_BONE:
			to_q = Quaternion.IDENTITY
		else:
			to_q = aim_poses.get(bone_name, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, eased))

	_apply_gun_grip_raise(eased)


func _apply_gun_grip_raise(alpha: float) -> void:
	if _revolver_grip == null or not _gun_in_hand:
		return

	var target := _get_hand_grip_local()
	if alpha >= 0.999:
		_revolver_grip.transform = target
	else:
		_revolver_grip.transform = _lerp_transform(_raise_grip_local_start, target, alpha)


func _apply_arm_aim(world_target: Vector3, delta: float) -> void:
	var arm_id := _skeleton.find_bone(ARM_BONE)
	var forearm_id := _skeleton.find_bone(FOREARM_BONE)
	if arm_id < 0:
		return

	var smooth_step := 1.0 - exp(-aim_pose_smooth * delta)
	if _smoothed_arm_aim_target == Vector3.ZERO:
		_smoothed_arm_aim_target = world_target
	_smoothed_arm_aim_target = _smoothed_arm_aim_target.lerp(world_target, smooth_step)

	_set_aim_bones_to_identity()
	var aim_point := _smoothed_arm_aim_target

	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(ARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var arm_target := _compute_bone_pose_toward(arm_id, aim_point, arm_axis)
		var arm_pose: Quaternion = _aim_bone_poses_smoothed.get(ARM_BONE, Quaternion.IDENTITY)
		arm_pose = _slerp_quaternion(arm_pose, arm_target, smooth_step)
		_aim_bone_poses_smoothed[ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(FOREARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var forearm_target := _compute_bone_pose_toward(forearm_id, aim_point, forearm_axis)
		var forearm_pose: Quaternion = _aim_bone_poses_smoothed.get(FOREARM_BONE, Quaternion.IDENTITY)
		forearm_pose = _slerp_quaternion(forearm_pose, forearm_target, smooth_step)
		_aim_bone_poses_smoothed[FOREARM_BONE] = _apply_forearm_recoil_offset(forearm_pose)
		_skeleton.set_bone_pose_rotation(forearm_id, _aim_bone_poses_smoothed[FOREARM_BONE])

	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id >= 0:
		_skeleton.set_bone_pose_rotation(hand_id, Quaternion.IDENTITY)


func _compute_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	var poses := _compute_chain_bone_poses_toward(world_target, AIM_IK_BONES)
	_set_aim_bones_to_identity()
	return poses


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
	var aim_vector := (parent_global.basis * bone_rest.basis * local_aim_axis).normalized()
	var twist := _safe_quat_between(aim_vector, to_target)

	var animated_global_rot := bone_global.basis.get_rotation_quaternion()
	var new_global_rot := twist * animated_global_rot
	var parent_rot := parent_global.basis.get_rotation_quaternion()
	var rest_rot := bone_rest.basis.get_rotation_quaternion()
	return rest_rot.inverse() * parent_rot.inverse() * new_global_rot


func _capture_aim_bone_rotations() -> Dictionary:
	var poses := {}
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	return poses


func _get_holstered_bone_pose(bone_name: String) -> Quaternion:
	return GroyperBodyUtils.holstered_bone_pose_rotation(bone_name, holstered_arm_rotation_deg)


func _reset_aim_bone_poses() -> void:
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, _get_holstered_bone_pose(bone_name))


func _release_arm_to_animation() -> void:
	if _skeleton == null:
		return
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.reset_bone_pose(bone_id)


func _clear_raise_cache() -> void:
	_raise_start_poses.clear()
	_raise_aim_target = Vector3.ZERO
	_raise_grip_local_start = Transform3D.IDENTITY


func _clear_arm_aim_smoothing() -> void:
	_smoothed_arm_aim_target = Vector3.ZERO
	_aim_bone_poses_smoothed.clear()


func _seed_arm_aim_smoothing() -> void:
	_aim_bone_poses_smoothed.clear()
	for bone_name: String in AIM_IK_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_aim_bone_poses_smoothed[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)
	_smoothed_arm_aim_target = _aim_target


func _apply_holster_grip_transform() -> void:
	if _revolver_grip:
		_revolver_grip.transform = _holster_grip_local


func _get_hand_grip_local() -> Transform3D:
	return Transform3D(Basis.from_euler(hand_grip_rotation_deg * (PI / 180.0)), hand_grip_position)


func _cache_bone_aim_axes() -> void:
	_bone_aim_axes.clear()
	for bone_name in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_bone_aim_axes[bone_name] = _detect_bone_aim_axis(bone_id)


func _detect_bone_aim_axis(bone_id: int) -> Vector3:
	var bone_rest := _skeleton.get_bone_rest(bone_id)
	for child_id in _skeleton.get_bone_count():
		if _skeleton.get_bone_parent(child_id) != bone_id:
			continue
		var child_rest := _skeleton.get_bone_rest(child_id)
		var local := bone_rest.affine_inverse() * child_rest.origin
		if local.length_squared() > 0.0001:
			return local.normalized()
	return Vector3(-1.0, 0.0, 0.0)


func _update_forearm_recoil(delta: float) -> void:
	if _forearm_recoil <= 0.0001:
		_forearm_recoil = 0.0
		return
	var recovery_step := 1.0 - exp(-_forearm_recoil_recovery * delta)
	_forearm_recoil = lerpf(_forearm_recoil, 0.0, recovery_step)


func _apply_forearm_recoil_offset(pose: Quaternion) -> Quaternion:
	if _forearm_recoil <= 0.0001:
		return pose
	var recoil := Basis.from_euler(_forearm_recoil_rotation_deg * (_forearm_recoil * PI / 180.0))
	return (pose * recoil.get_rotation_quaternion()).normalized()


func _lerp_transform(from: Transform3D, to: Transform3D, alpha: float) -> Transform3D:
	return Transform3D(
		from.basis.slerp(to.basis, alpha).orthonormalized(),
		from.origin.lerp(to.origin, alpha)
	)


func _slerp_quaternion(from_q: Quaternion, to_q: Quaternion, weight: float) -> Quaternion:
	return from_q.slerp(to_q, weight).normalized()


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
