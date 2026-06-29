extends Node
class_name GroyperWeaponRig

const BULLET_SCENE := preload("res://gameplay/shooting/bullet.tscn")
const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")

const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const ARM_BONE := "RightArm"
const FOREARM_BONE := "RightForeArm"
const HAND_BONE := "RightHand"
const SHOULDER_BONE := "RightShoulder"
const AIM_IK_BONES := [ARM_BONE, FOREARM_BONE]
## Gun aim only twists the upper arm; forearm stays straight (identity) to avoid a bent elbow.
const GUN_AIM_IK_BONES := [ARM_BONE]
const AIM_BONES := [ARM_BONE, FOREARM_BONE, HAND_BONE]
const GUN_ARM_BONES := [SHOULDER_BONE, ARM_BONE, FOREARM_BONE, HAND_BONE]
const MOUNT_SPINE_BONES := ["Spine", "Spine01", "Spine02"]
const MOUNT_SPINE_TWIST_WEIGHTS := [0.2, 0.35, 0.45]
const ARM_AIM_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_arm_aim_modifier.gd")
const ShellCasingFX := preload("res://gameplay/fx/shell_casing_fx.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const LEFT_ARM_BONE := "LeftArm"
const LEFT_FOREARM_BONE := "LeftForeArm"
const LEFT_HAND_BONE := "LeftHand"
const LEFT_AIM_BONES := [LEFT_ARM_BONE, LEFT_FOREARM_BONE, LEFT_HAND_BONE]

const RELOAD_RAISE_DURATION := 0.28
const RELOAD_EJECT_DURATION := 0.55
const RELOAD_LOAD_SWING_DURATION := 0.11
const RELOAD_HOLSTER_DURATION := 0.22

enum DrawState { HOLSTERED, DRAWING, HOLSTERING, AIMING }

enum OverworldReloadPhase { NONE, RAISING, EJECTING, TAP_READY, LOADING, HOLSTERING }

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
var _hip_holster_socket: Node3D
var _back_holster_mount: BoneAttachment3D
var _back_holster_socket: Node3D
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
var _cover_crouch_hold := false
var _saddle_aim_mode := false
var _mount_aim_spine_yaw := 0.0
var _equipped_weapon_id: GroyperWeapons.Id = GroyperWeapons.get_enemy_weapon()

var _reload_phase := OverworldReloadPhase.NONE
var _reload_timer := 0.0
var _reload_load_alpha := 0.0
var _reload_raise_poses: Dictionary = {}
var _reload_aim_target := Vector3.ZERO
var _reload_cylinder_target := Vector3.ZERO
var _reload_started_from_aim := false
var _reload_aim_stance := false


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


func swap_equipped_weapon(weapon_id: GroyperWeapons.Id) -> void:
	if weapon_id == _equipped_weapon_id:
		return

	reset_to_holster()
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		_revolver_grip.queue_free()
		_revolver_grip = null
	_equipped_weapon_id = weapon_id

	var socket := _get_active_holster_socket()
	if socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			socket,
			_equipped_weapon_id
		)
		_holster_grip_local = _revolver_grip.transform
		_apply_holster_grip_transform()
		_resolve_hand_muzzle()
		_invalidate_muzzle_cache()

	draw_state_changed.emit(_draw_state)


func get_active_holster_socket() -> Node3D:
	return _get_active_holster_socket()


func _get_active_holster_socket() -> Node3D:
	if GroyperWeapons.uses_back_holster(_equipped_weapon_id):
		return _back_holster_socket
	return _hip_holster_socket


func reset_to_holster() -> void:
	_clear_reload_state()
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_draw_active = false
	_gun_in_hand = false
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	if _overworld_hold_mode or _saddle_aim_mode:
		if not _saddle_aim_mode:
			_release_arm_to_animation()
	else:
		_reset_aim_bone_poses()
	_ensure_revolver_grip()
	var holster_socket := _get_active_holster_socket()
	if _revolver_grip != null and holster_socket != null and _revolver_grip.get_parent() != holster_socket:
		var grip_global := _revolver_grip.global_transform
		_revolver_grip.reparent(holster_socket, true)
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


func begin_holster() -> void:
	if _draw_state == DrawState.HOLSTERED or _draw_state == DrawState.HOLSTERING:
		return
	if _draw_state == DrawState.DRAWING or _draw_state == DrawState.AIMING:
		_draw_state = DrawState.HOLSTERING
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


func get_equipped_weapon_id() -> GroyperWeapons.Id:
	return _equipped_weapon_id


func can_fire() -> bool:
	return _draw_state == DrawState.AIMING and _reload_phase == OverworldReloadPhase.NONE


func can_use_reticle() -> bool:
	if _reload_phase != OverworldReloadPhase.NONE and _reload_aim_stance:
		return true
	return _draw_state == DrawState.AIMING and _reload_phase == OverworldReloadPhase.NONE


func is_overworld_reloading() -> bool:
	return _reload_phase != OverworldReloadPhase.NONE


func can_begin_overworld_reload() -> bool:
	if GroyperWeapons.is_lasso(_equipped_weapon_id):
		return false
	return (
		_overworld_hold_mode
		and not _saddle_aim_mode
		and (
			_draw_state == DrawState.HOLSTERED
			or _draw_state == DrawState.AIMING
		)
		and _reload_phase == OverworldReloadPhase.NONE
	)


func did_overworld_reload_start_from_aim() -> bool:
	return _reload_started_from_aim


func set_overworld_reload_aim_stance(active: bool) -> void:
	_reload_aim_stance = active
	if active and _gun_in_hand:
		_draw_state = DrawState.AIMING
		_draw_progress = 1.0


func begin_overworld_reload_eject() -> void:
	if not can_begin_overworld_reload():
		return

	_reload_started_from_aim = _draw_state == DrawState.AIMING
	_reload_aim_stance = _reload_started_from_aim

	if not _gun_in_hand:
		_attach_gun_to_hand()
	elif _reload_started_from_aim:
		_snap_gun_grip_to_hand()

	_capture_reload_rest_poses()
	_reload_phase = OverworldReloadPhase.RAISING
	_reload_timer = 0.0
	_reload_load_alpha = 0.0


func try_overworld_reload_tap() -> bool:
	if _reload_phase != OverworldReloadPhase.TAP_READY:
		return false
	if _reload_load_alpha > 0.001:
		return false

	_reload_phase = OverworldReloadPhase.LOADING
	_reload_timer = 0.0
	_reload_load_alpha = 0.0
	return true


func finish_overworld_reload_holster() -> void:
	finish_overworld_reload(false)


func finish_overworld_reload(return_to_aim: bool) -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return

	if return_to_aim and _gun_in_hand:
		_clear_reload_state()
		_draw_state = DrawState.AIMING
		_draw_progress = 1.0
		_snap_gun_grip_to_hand()
		_seed_arm_aim_smoothing()
		draw_state_changed.emit(_draw_state)
		return

	_reload_phase = OverworldReloadPhase.HOLSTERING
	_reload_timer = 0.0
	_reload_aim_stance = false


func cancel_overworld_reload_for_aim() -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return
	_clear_reload_state()
	if not _gun_in_hand:
		return
	_draw_state = DrawState.AIMING
	_draw_progress = 1.0
	_snap_gun_grip_to_hand()
	_clear_raise_cache()
	_seed_arm_aim_smoothing()
	draw_state_changed.emit(_draw_state)


func get_overworld_reload_phase() -> OverworldReloadPhase:
	return _reload_phase


func notify_overworld_reload_eject_complete() -> void:
	_reload_phase = OverworldReloadPhase.TAP_READY
	_reload_timer = 0.0


func notify_overworld_reload_round_complete() -> void:
	_reload_phase = OverworldReloadPhase.TAP_READY
	_reload_timer = 0.0
	_reload_load_alpha = 0.0


func update_overworld_reload(delta: float) -> void:
	if _reload_phase == OverworldReloadPhase.NONE:
		return

	match _reload_phase:
		OverworldReloadPhase.RAISING:
			_reload_timer += delta
			if _reload_timer >= RELOAD_RAISE_DURATION:
				_begin_reload_eject()

		OverworldReloadPhase.EJECTING:
			_reload_timer += delta
			if _reload_timer >= RELOAD_EJECT_DURATION:
				_reload_phase = OverworldReloadPhase.TAP_READY
				_reload_timer = 0.0

		OverworldReloadPhase.LOADING:
			_reload_timer += delta
			_reload_load_alpha = clampf(_reload_timer / RELOAD_LOAD_SWING_DURATION, 0.0, 1.0)
			if _reload_timer >= RELOAD_LOAD_SWING_DURATION:
				_reload_phase = OverworldReloadPhase.TAP_READY
				_reload_timer = 0.0
				_reload_load_alpha = 0.0

		OverworldReloadPhase.HOLSTERING:
			_reload_timer += delta
			var alpha := 1.0 - clampf(_reload_timer / RELOAD_HOLSTER_DURATION, 0.0, 1.0)
			if _gun_in_hand and alpha < draw_grab_threshold:
				_detach_gun_to_holster()
			if _reload_timer >= RELOAD_HOLSTER_DURATION:
				_finish_overworld_reload()


func enable_overworld_hold_mode(enabled: bool) -> void:
	_overworld_hold_mode = enabled


func set_cover_crouch_hold(active: bool) -> void:
	_cover_crouch_hold = active
	if active:
		reset_to_holster()


func set_saddle_aim_mode(active: bool) -> void:
	_saddle_aim_mode = active
	if not active:
		_mount_aim_spine_yaw = 0.0


func is_saddle_aim_mode() -> bool:
	return _saddle_aim_mode


func set_mount_aim_spine_yaw(yaw: float) -> void:
	_mount_aim_spine_yaw = yaw


func release_arms_for_locomotion() -> void:
	if _overworld_hold_mode and not _saddle_aim_mode:
		_release_arm_to_animation()


func update(delta: float, aim_world_target: Vector3) -> void:
	if _skeleton == null:
		return

	_aim_target = aim_world_target
	_update_forearm_recoil(delta)
	update_overworld_reload(delta)
	if _overworld_hold_mode and _reload_phase == OverworldReloadPhase.NONE:
		if not _cover_crouch_hold:
			var rmb_held := Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT)
			_update_overworld_draw(rmb_held, delta)
	elif not _overworld_hold_mode:
		_update_draw(delta)


func set_prep_aim(active: bool) -> void:
	_prep_aim = active


func get_aim_target() -> Vector3:
	return _aim_target


func apply_pose_overrides(delta: float) -> void:
	if _skeleton == null or _is_defeat_ragdoll_active():
		return

	if _reload_phase != OverworldReloadPhase.NONE:
		_apply_overworld_reload_pose(delta)
		return

	# Overworld / saddle: leave the right arm alone while holstered so animation can drive it.
	if (_overworld_hold_mode or _saddle_aim_mode) and _draw_state == DrawState.HOLSTERED:
		return

	if _saddle_aim_mode and _draw_state != DrawState.HOLSTERED:
		_apply_mount_spine_twist()

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
	GameAudio.play_weapon_shot(_equipped_weapon_id, scene_root, origin)
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
	elif not _gun_in_hand and _revolver_grip != null:
		var holster_socket := _get_active_holster_socket()
		if holster_socket != null and _revolver_grip.get_parent() != holster_socket:
			var holster_global := _revolver_grip.global_transform
			_revolver_grip.reparent(holster_socket, true)
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
	_hip_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	_back_holster_mount = _skeleton.get_node_or_null("BackHolsterMount") as BoneAttachment3D
	_back_holster_socket = _back_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _back_holster_mount else null
	_hand_revolver_mount = _skeleton.get_node_or_null("HandRevolverMount") as BoneAttachment3D

	var socket := _get_active_holster_socket()
	if socket:
		_revolver_grip = GroyperWeapons.install_holster_grip(
			socket,
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
	if _hip_holster_socket == null and _skeleton != null:
		_hip_holster_mount = _skeleton.get_node_or_null("HipHolsterMount") as BoneAttachment3D
		_hip_holster_socket = _hip_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _hip_holster_mount else null
	if _back_holster_socket == null and _skeleton != null:
		_back_holster_mount = _skeleton.get_node_or_null("BackHolsterMount") as BoneAttachment3D
		_back_holster_socket = _back_holster_mount.get_node_or_null("HolsterOffset") as Node3D if _back_holster_mount else null
	var socket := _get_active_holster_socket()
	if socket != null:
		_revolver_grip = socket.get_node_or_null("RevolverGrip") as Node3D


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

	var previous_state := _draw_state

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
		DrawState.HOLSTERING:
			_draw_progress = maxf(_draw_progress - delta / holster_duration, 0.0)
			if _gun_in_hand and _draw_progress < draw_grab_threshold:
				_detach_gun_to_holster()
			if _draw_progress <= 0.0:
				_draw_state = DrawState.HOLSTERED
				_draw_progress = 0.0
				_draw_active = false
				_clear_raise_cache()
				_clear_arm_aim_smoothing()

	if previous_state != _draw_state and _draw_state == DrawState.AIMING:
		_play_aim_enter_sound()


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
		if (
			_saddle_aim_mode
			and previous_state == DrawState.HOLSTERED
			and _draw_state != DrawState.HOLSTERED
		):
			_release_arm_to_animation()
		elif _overworld_hold_mode and not _saddle_aim_mode and _draw_state == DrawState.HOLSTERED:
			_release_arm_to_animation()
		if _draw_state == DrawState.AIMING and previous_state != DrawState.AIMING:
			_play_aim_enter_sound()
		draw_state_changed.emit(_draw_state)


func _play_aim_enter_sound() -> void:
	if _owner == null or GroyperWeapons.is_lasso(_equipped_weapon_id):
		return
	GameAudio.play_revolver_aim(_owner, get_muzzle_global_position())


func _detach_gun_to_holster() -> void:
	if not _gun_in_hand or _revolver_grip == null:
		return
	var holster_socket := _get_active_holster_socket()
	if holster_socket == null:
		return

	var grip_global := _revolver_grip.global_transform
	_revolver_grip.reparent(holster_socket, true)
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
	if _saddle_owns_gun_arm():
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			return _skeleton.get_bone_pose_rotation(bone_id)
	var holstered := _get_holstered_bone_pose(bone_name)
	return holstered.slerp(Quaternion.IDENTITY, 1.0 - rest_fade)


func _set_aim_bones_to_identity() -> void:
	if _saddle_owns_gun_arm():
		return
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
		if bone_name == ARM_BONE:
			local_axis = _get_gun_arm_aim_axis()
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
		var arm_axis := _get_gun_arm_aim_axis()
		var arm_target := _compute_bone_pose_toward(arm_id, aim_point, arm_axis)
		var arm_pose: Quaternion = _aim_bone_poses_smoothed.get(ARM_BONE, Quaternion.IDENTITY)
		arm_pose = _slerp_quaternion(arm_pose, arm_target, smooth_step)
		_aim_bone_poses_smoothed[ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	if forearm_id >= 0:
		var forearm_rest := Quaternion.IDENTITY
		var forearm_pose: Quaternion = _aim_bone_poses_smoothed.get(FOREARM_BONE, forearm_rest)
		forearm_pose = _slerp_quaternion(forearm_pose, forearm_rest, smooth_step)
		_aim_bone_poses_smoothed[FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, _apply_forearm_recoil_offset(forearm_pose))

	var hand_id := _skeleton.find_bone(HAND_BONE)
	if hand_id >= 0:
		_skeleton.set_bone_pose_rotation(hand_id, Quaternion.IDENTITY)


func _apply_mount_spine_twist() -> void:
	if absf(_mount_aim_spine_yaw) <= 0.0001:
		return

	for i in MOUNT_SPINE_BONES.size():
		var bone_name: String = MOUNT_SPINE_BONES[i]
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var twist := Quaternion(
			Vector3.UP,
			_mount_aim_spine_yaw * MOUNT_SPINE_TWIST_WEIGHTS[i]
		)
		var current := _skeleton.get_bone_pose_rotation(bone_id)
		_skeleton.set_bone_pose_rotation(bone_id, current * twist)


func _compute_aim_bone_rotations(world_target: Vector3) -> Dictionary:
	var poses := _compute_chain_bone_poses_toward(world_target, GUN_AIM_IK_BONES)
	poses[FOREARM_BONE] = Quaternion.IDENTITY
	if not _saddle_owns_gun_arm():
		_set_aim_bones_to_identity()
	return poses


func _saddle_owns_gun_arm() -> bool:
	return _saddle_aim_mode and is_holstered()


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

	# Aim from bind rest, not the animated arm pose (idle clips can raise the gun arm).
	var rest_global_rot := rest_global_basis.get_rotation_quaternion()
	var new_global_rot := twist * rest_global_rot
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
	_release_bones_to_animation(AIM_BONES)


func _release_gun_arm_to_animation() -> void:
	_release_bones_to_animation(GUN_ARM_BONES)


func _release_bones_to_animation(bone_names: Array) -> void:
	if _skeleton == null:
		return
	for bone_name in bone_names:
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
	for bone_name in AIM_BONES + LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_bone_aim_axes[bone_name] = GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)
	if _skeleton.find_bone(ARM_BONE) >= 0:
		_bone_aim_axes[ARM_BONE] = _get_gun_arm_aim_axis()


func _get_gun_arm_aim_axis() -> Vector3:
	return GroyperBodyUtils.detect_gun_arm_aim_axis(
		_skeleton,
		ARM_BONE,
		FOREARM_BONE,
		HAND_BONE
	)


func _detect_bone_aim_axis(bone_id: int) -> Vector3:
	return GroyperBodyUtils.detect_bone_child_aim_axis(_skeleton, bone_id)


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


func _clear_reload_state() -> void:
	_reload_phase = OverworldReloadPhase.NONE
	_reload_timer = 0.0
	_reload_load_alpha = 0.0
	_reload_raise_poses.clear()
	_reload_started_from_aim = false
	_reload_aim_stance = false
	_release_bones_to_animation(LEFT_AIM_BONES)


func _finish_overworld_reload() -> void:
	_clear_reload_state()
	_draw_state = DrawState.HOLSTERED
	_draw_progress = 0.0
	_clear_raise_cache()
	_clear_arm_aim_smoothing()
	_release_arm_to_animation()
	draw_state_changed.emit(_draw_state)


func _begin_reload_eject() -> void:
	_reload_phase = OverworldReloadPhase.EJECTING
	_reload_timer = 0.0
	if _equipped_weapon_id == GroyperWeapons.Id.REVOLVER and _owner != null:
		var spin_pos := get_muzzle_global_position()
		GameAudio.play_revolver_eject_spin(_owner, spin_pos)
	_spawn_shell_casings()


func _capture_reload_rest_poses() -> void:
	_reload_aim_target = _get_reload_aim_target()
	_reload_cylinder_target = _get_reload_cylinder_target()
	_reload_raise_poses.clear()
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_reload_raise_poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)


func _apply_overworld_reload_pose(delta: float) -> void:
	if (
		_reload_aim_stance
		and _reload_phase in [
			OverworldReloadPhase.TAP_READY,
			OverworldReloadPhase.LOADING,
		]
	):
		_apply_arm_aim(_aim_target, delta)
		if _reload_phase == OverworldReloadPhase.LOADING:
			var swing := sin(_reload_load_alpha * PI)
			_apply_reload_left_arm_swing(swing)
		else:
			for bone_name: String in LEFT_AIM_BONES:
				var bone_id := _skeleton.find_bone(bone_name)
				if bone_id >= 0:
					_skeleton.reset_bone_pose(bone_id)
		return

	match _reload_phase:
		OverworldReloadPhase.RAISING:
			var alpha := clampf(_reload_timer / RELOAD_RAISE_DURATION, 0.0, 1.0)
			alpha = alpha * alpha * (3.0 - 2.0 * alpha)
			_apply_reload_gun_pose(alpha, 0.0)
		OverworldReloadPhase.EJECTING, OverworldReloadPhase.TAP_READY:
			_apply_reload_gun_pose(1.0, 0.0)
		OverworldReloadPhase.LOADING:
			var swing := sin(_reload_load_alpha * PI)
			_apply_reload_gun_pose(1.0, swing)
		OverworldReloadPhase.HOLSTERING:
			var alpha := 1.0 - clampf(_reload_timer / RELOAD_HOLSTER_DURATION, 0.0, 1.0)
			alpha = alpha * alpha * (3.0 - 2.0 * alpha)
			_apply_reload_gun_pose(alpha, 0.0)


func _apply_reload_gun_pose(gun_alpha: float, left_swing: float) -> void:
	if _reload_raise_poses.is_empty():
		_capture_reload_rest_poses()

	_reload_aim_target = _get_reload_aim_target()
	_reload_cylinder_target = _get_reload_cylinder_target()

	var target_poses := _compute_aim_bone_rotations(_reload_aim_target)
	var eased := gun_alpha * gun_alpha * (3.0 - 2.0 * gun_alpha)
	for bone_name: String in AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var from_q: Quaternion = _reload_raise_poses.get(bone_name, Quaternion.IDENTITY)
		var to_q: Quaternion = target_poses.get(bone_name, Quaternion.IDENTITY)
		if bone_name == HAND_BONE:
			to_q = Quaternion.IDENTITY
		_skeleton.set_bone_pose_rotation(bone_id, from_q.slerp(to_q, eased))

	if left_swing > 0.001:
		_apply_reload_left_arm_swing(left_swing)
	else:
		for bone_name: String in LEFT_AIM_BONES:
			var bone_id := _skeleton.find_bone(bone_name)
			if bone_id >= 0:
				_skeleton.reset_bone_pose(bone_id)


func _apply_reload_left_arm_swing(swing: float) -> void:
	var reach_weights := {
		LEFT_ARM_BONE: clampf(swing * 1.15, 0.0, 1.0),
		LEFT_FOREARM_BONE: clampf((swing - 0.08) * 1.2, 0.0, 1.0),
		LEFT_HAND_BONE: clampf((swing - 0.18) * 1.25, 0.0, 1.0),
	}
	var ik_targets := _compute_left_reach_poses(_reload_cylinder_target, swing)

	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var bone_alpha: float = reach_weights.get(bone_name, swing)
		if bone_alpha <= 0.0:
			_skeleton.reset_bone_pose(bone_id)
			continue

		var target_pose: Quaternion = ik_targets.get(bone_name, Quaternion.IDENTITY)
		_skeleton.set_bone_pose_rotation(
			bone_id,
			Quaternion.IDENTITY.slerp(target_pose, bone_alpha)
		)


func _compute_left_reach_poses(target: Vector3, _reach_alpha: float) -> Dictionary:
	_set_left_aim_bones_to_identity()
	var poses := {}
	var arm_id := _skeleton.find_bone(LEFT_ARM_BONE)
	if arm_id >= 0:
		var arm_axis: Vector3 = _bone_aim_axes.get(LEFT_ARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var arm_pose := _compute_bone_pose_toward(arm_id, target, arm_axis)
		poses[LEFT_ARM_BONE] = arm_pose
		_skeleton.set_bone_pose_rotation(arm_id, arm_pose)

	var forearm_id := _skeleton.find_bone(LEFT_FOREARM_BONE)
	if forearm_id >= 0:
		var forearm_axis: Vector3 = _bone_aim_axes.get(LEFT_FOREARM_BONE, Vector3(-1.0, 0.0, 0.0))
		var forearm_pose := _compute_bone_pose_toward(forearm_id, target, forearm_axis)
		poses[LEFT_FOREARM_BONE] = forearm_pose
		_skeleton.set_bone_pose_rotation(forearm_id, forearm_pose)

	poses[LEFT_HAND_BONE] = Quaternion.IDENTITY
	return poses


func _set_left_aim_bones_to_identity() -> void:
	for bone_name: String in LEFT_AIM_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id >= 0:
			_skeleton.set_bone_pose_rotation(bone_id, Quaternion.IDENTITY)


func _get_reload_shoulder_origin() -> Vector3:
	if _skeleton != null:
		var shoulder_id := _skeleton.find_bone(SHOULDER_BONE)
		if shoulder_id >= 0:
			return (
				_skeleton.global_transform * _skeleton.get_bone_global_pose(shoulder_id)
			).origin
	return _owner.global_position + Vector3(0.0, 1.15, 0.0) if _owner != null else Vector3.ZERO


func _get_reload_forward_direction() -> Vector3:
	# Overworld player rotates Model, not the CharacterBody3D root — never use _owner.basis.
	if _aim_target.length_squared() > 0.0001:
		var from_shoulder := _aim_target - _get_reload_shoulder_origin()
		if from_shoulder.length_squared() > 0.0001:
			return from_shoulder.normalized()

	if _skeleton != null:
		var skeleton_forward := -_skeleton.global_transform.basis.z
		skeleton_forward.y = 0.0
		if skeleton_forward.length_squared() > 0.0001:
			return skeleton_forward.normalized()

	return Vector3.FORWARD


func _get_reload_aim_target() -> Vector3:
	var origin := _get_reload_shoulder_origin()
	return origin + _get_reload_forward_direction() * 0.42 + Vector3(0.0, 0.06, 0.0)


func _get_reload_cylinder_target() -> Vector3:
	if _revolver_grip != null and is_instance_valid(_revolver_grip):
		var grip := _revolver_grip.global_transform
		return grip.origin + grip.basis * Vector3(0.0, 0.07, 0.03)
	return _get_reload_aim_target()


func _spawn_shell_casings() -> void:
	if _revolver_grip == null or _owner == null:
		return

	var scene_root := _owner.get_tree().current_scene
	if scene_root == null:
		return

	var eject_origin := _revolver_grip.global_transform
	eject_origin.origin += eject_origin.basis * Vector3(0.0, 0.08, 0.04)
	var eject_count := _get_reload_eject_particle_count()
	ShellCasingFX.spawn_burst(scene_root, eject_origin, eject_count)


func _get_reload_eject_particle_count() -> int:
	var max_ammo := GroyperWeapons.get_max_ammo(_equipped_weapon_id)
	if GroyperWeapons.uses_per_round_overworld_reload(_equipped_weapon_id):
		return max_ammo
	return clampi(maxi(max_ammo / 3, 4), 4, 10)
