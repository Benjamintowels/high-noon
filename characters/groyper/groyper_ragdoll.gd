extends Node
class_name GroyperRagdoll

## Procedural duel defeat fall — torso tips backward while limb springs add ragdoll-like lag and flop.

const IMPULSE := preload("res://characters/groyper/groyper_ragdoll_impulse.gd")
const DROPPED_REVOLVER := preload("res://characters/groyper/groyper_dropped_revolver.gd")
const DUEL_HAT := preload("res://characters/groyper/groyper_duel_hat.gd")
const POSE_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_ragdoll_modifier.gd")

const FLOOR_MASK := 1
const FLOOR_RAY_HEIGHT := 200.0
const FLOOR_RAY_DEPTH := 300.0
const ACTOR_GROUND_OFFSET := 0.05
const MAX_PITCH_RAD := deg_to_rad(92.0)
const SETTLE_PITCH_RAD := deg_to_rad(86.0)
const MAX_ROLL_RAD := deg_to_rad(38.0)
const MAX_YAW_RAD := deg_to_rad(28.0)
const FALL_KNOCKBACK_LIMIT := 0.55
const SETTLED_KNOCKBACK_LIMIT := 5.0
const LASSO_HEAD_FLOOR_CLEARANCE := 0.2
const LASSO_DRAG_PITCH_MIN := deg_to_rad(78.0)
const LASSO_DRAG_PITCH_MAX := deg_to_rad(90.0)
const LASSO_HIP_DROP_SCALE := 0.58

const LIMB_DRAG_FLOOR_BONES := [
	"Head",
	"Hips",
	"Spine02",
	"LeftHand",
	"RightHand",
	"LeftLeg",
	"RightLeg",
]

const LIMB_SIM_BONES := [
	"Hips",
	"Spine",
	"Spine01",
	"Spine02",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"LeftUpLeg",
	"LeftLeg",
	"RightUpLeg",
	"RightLeg",
	"neck",
	"Head",
]

const LIMB_SIM := {
	"Hips": {
		"inertia_pitch": 0.35,
		"gravity_pull": 0.25,
		"spring": 9.0,
		"damp": 3.4,
		"rest_scale": 0.55,
	},
	"Spine": {
		"inertia_pitch": 0.75,
		"gravity_pull": 0.45,
		"spring": 8.0,
		"damp": 3.0,
		"rest_scale": 0.85,
		"follow_bone": "Hips",
		"follow_strength": 0.35,
	},
	"Spine01": {
		"inertia_pitch": 0.95,
		"gravity_pull": 0.55,
		"spring": 7.5,
		"damp": 2.8,
		"rest_scale": 1.0,
		"follow_bone": "Spine",
		"follow_strength": 0.42,
	},
	"Spine02": {
		"inertia_pitch": 1.1,
		"gravity_pull": 0.65,
		"spring": 7.0,
		"damp": 2.6,
		"rest_scale": 1.1,
		"follow_bone": "Spine01",
		"follow_strength": 0.48,
	},
	"RightShoulder": {
		"inertia_pitch": 0.55,
		"gravity_pull": 0.35,
		"spring": 7.0,
		"damp": 2.8,
		"rest_scale": 1.0,
	},
	"RightArm": {
		"inertia_pitch": 1.45,
		"gravity_pull": 1.35,
		"spring": 5.5,
		"damp": 2.2,
		"rest_scale": 1.2,
	},
	"RightForeArm": {
		"inertia_pitch": 0.35,
		"gravity_pull": 1.8,
		"spring": 4.5,
		"damp": 1.8,
		"rest_scale": 1.35,
		"follow_bone": "RightArm",
		"follow_strength": 0.42,
	},
	"RightHand": {
		"inertia_pitch": 0.15,
		"gravity_pull": 0.6,
		"spring": 6.0,
		"damp": 2.4,
		"rest_scale": 0.8,
		"follow_bone": "RightForeArm",
		"follow_strength": 0.28,
	},
	"LeftShoulder": {
		"inertia_pitch": 0.55,
		"gravity_pull": 0.35,
		"spring": 7.0,
		"damp": 2.8,
		"rest_scale": 1.0,
	},
	"LeftArm": {
		"inertia_pitch": 1.45,
		"gravity_pull": 1.35,
		"spring": 5.5,
		"damp": 2.2,
		"rest_scale": 1.2,
	},
	"LeftForeArm": {
		"inertia_pitch": 0.35,
		"gravity_pull": 1.8,
		"spring": 4.5,
		"damp": 1.8,
		"rest_scale": 1.35,
		"follow_bone": "LeftArm",
		"follow_strength": 0.42,
	},
	"LeftHand": {
		"inertia_pitch": 0.15,
		"gravity_pull": 0.6,
		"spring": 6.0,
		"damp": 2.4,
		"rest_scale": 0.8,
		"follow_bone": "LeftForeArm",
		"follow_strength": 0.28,
	},
	"LeftUpLeg": {
		"inertia_pitch": 0.45,
		"gravity_pull": 0.55,
		"spring": 8.0,
		"damp": 3.0,
		"rest_scale": 0.9,
	},
	"LeftLeg": {
		"inertia_pitch": 0.2,
		"gravity_pull": 0.75,
		"spring": 6.5,
		"damp": 2.6,
		"rest_scale": 1.0,
		"follow_bone": "LeftUpLeg",
		"follow_strength": 0.35,
	},
	"RightUpLeg": {
		"inertia_pitch": 0.45,
		"gravity_pull": 0.55,
		"spring": 8.0,
		"damp": 3.0,
		"rest_scale": 0.9,
	},
	"RightLeg": {
		"inertia_pitch": 0.2,
		"gravity_pull": 0.75,
		"spring": 6.5,
		"damp": 2.6,
		"rest_scale": 1.0,
		"follow_bone": "RightUpLeg",
		"follow_strength": 0.35,
	},
	"neck": {
		"inertia_pitch": 0.65,
		"gravity_pull": 0.45,
		"spring": 7.5,
		"damp": 2.8,
		"rest_scale": 0.9,
	},
	"Head": {
		"inertia_pitch": 0.85,
		"gravity_pull": 0.55,
		"spring": 6.0,
		"damp": 2.4,
		"rest_scale": 1.0,
		"follow_bone": "neck",
		"follow_strength": 0.35,
	},
}

@export var skeleton_path: NodePath
@export var model_path: NodePath = NodePath("../Model")
@export var debug_ragdoll := true

var _skeleton: Skeleton3D
var _model: Node3D
var _actor: Node3D
var _hidden_attachments: Array[Node3D] = []
var _active := false
var _lasso_drag_mode := false
var _lasso_settling := false
var _lasso_standup_recovery := false
var _lasso_pull_velocity := Vector3.ZERO
var _lasso_ring_position := Vector3.ZERO

var _fall_pitch := 0.0
var _fall_pitch_velocity := 0.0
var _fall_roll := 0.0
var _fall_roll_velocity := 0.0
var _fall_yaw := 0.0
var _fall_yaw_velocity := 0.0
var _fall_progress := 0.0
var _knockback_offset := Vector3.ZERO
var _knockback_velocity := Vector3.ZERO
var _airborne := false
var _air_velocity := Vector3.ZERO
var _floor_y := 0.0
var _base_actor_transform: Transform3D
var _base_model_rotation := Vector3.ZERO
var _upright_model_rotation := Vector3.ZERO
var _captured_bone_poses: Dictionary = {}
var _limb_angles: Dictionary = {}
var _limb_velocities: Dictionary = {}
var _dropped_revolver: RigidBody3D
var _revolver_restore: Dictionary = {}
var _pose_modifier: GroyperRagdollModifier
var _animation_player: AnimationPlayer
var _animation_tree: AnimationTree
var _end_frame_apply_bound := false
var _debug_tick := 0
var _disabled_actor_collisions: Array[CollisionShape3D] = []


func _ready() -> void:
	bind_skeleton()


func bind_skeleton() -> void:
	_resolve_nodes()
	_install_pose_modifier()


func _dbg(msg: String) -> void:
	if debug_ragdoll:
		var actor_name: String = str(_actor.name) if _actor != null else "?"
		print("[GroyperRagdoll:%s actor=%s] %s" % [name, actor_name, msg])


func _resolve_nodes() -> void:
	if _skeleton == null and not skeleton_path.is_empty():
		_skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if _actor == null:
		_actor = get_parent() as Node3D
	if _model == null and not model_path.is_empty():
		_model = get_node_or_null(model_path) as Node3D
		if _model == null and _actor != null:
			_model = _actor.get_node_or_null("Model") as Node3D


func is_active() -> bool:
	return _active


func is_lasso_drag_mode() -> bool:
	return _lasso_drag_mode


func activate_lasso_drag(pull_direction: Vector3, animation_player: AnimationPlayer = null) -> void:
	_resolve_nodes()
	if _active and _lasso_drag_mode:
		return
	var head_pos := _get_head_world_position()
	var hit_info := {
		"direction": pull_direction.normalized() if pull_direction.length_squared() > 0.0001 else Vector3.FORWARD,
		"position": head_pos,
		"lasso_drag": true,
		"impulse_scale": 0.48,
		"lasso_hat_drop": true,
	}
	activate(hit_info, animation_player)
	_lasso_drag_mode = true
	_lasso_settling = false
	_fall_pitch = 0.0
	_fall_pitch_velocity = 4.2
	_fall_roll = 0.0
	_fall_roll_velocity = 0.0
	_fall_yaw = 0.0
	_fall_yaw_velocity = 0.0
	_fall_progress = 0.0


func update_lasso_pull(pull_velocity: Vector3, _delta: float) -> void:
	if not _lasso_drag_mode or not _active:
		return
	_lasso_pull_velocity = Vector3(pull_velocity.x, 0.0, pull_velocity.z)


func sync_lasso_ring_position(ring_position: Vector3) -> void:
	_lasso_ring_position = ring_position


func is_lasso_settling() -> bool:
	return _lasso_settling


func get_lasso_settle_alpha() -> float:
	if not _lasso_settling:
		return 0.0
	if LASSO_DRAG_PITCH_MIN < 0.001:
		return 1.0
	var linear := 1.0 - clampf(_fall_pitch / LASSO_DRAG_PITCH_MIN, 0.0, 1.0)
	return smoothstep(0.0, 1.0, linear)


func deactivate_lasso_drag() -> void:
	if not _lasso_drag_mode and not _lasso_settling:
		return
	if _actor != null:
		_base_actor_transform = _actor.global_transform
	_lasso_standup_recovery = true
	_lasso_drag_mode = false
	_lasso_settling = true
	_lasso_pull_velocity = Vector3.ZERO
	_fall_pitch_velocity = -1.6
	_knockback_velocity = Vector3.ZERO
	_update_settle_modifier_influence()


func activate(hit_info: Dictionary, animation_player: AnimationPlayer = null) -> void:
	_resolve_nodes()
	if _active:
		_dbg("activate skipped: already active")
		return
	if _skeleton == null:
		_dbg("activate FAILED: skeleton null (path=%s resolved=%s)" % [
			skeleton_path,
			get_node_or_null(skeleton_path),
		])
		return
	if _actor == null:
		_dbg("activate FAILED: actor null")
		return

	_dbg("activate start bones=%d model=%s" % [
		_skeleton.get_bone_count(),
		str(_model.name) if _model != null else "null",
	])
	_active = true
	_debug_tick = 0
	var lasso_drag := bool(hit_info.get("lasso_drag", false))
	if lasso_drag:
		_launch_lasso_dropped_hat(hit_info)
	elif not lasso_drag:
		_launch_dropped_revolver(hit_info)
		_launch_dropped_hat(hit_info)
	_ensure_visual_pose_before_capture()
	_capture_pose()
	_suspend_actor_animations()
	_stop_animation_sources(animation_player)
	_configure_skeleton_modifiers(true)
	if lasso_drag:
		_reset_lasso_limb_simulation(hit_info.get("direction", Vector3.FORWARD))
	else:
		_reset_limb_simulation(hit_info)
	if not lasso_drag:
		_bake_captured_pose()
	_hide_skeleton_attachments()
	_base_actor_transform = _actor.global_transform
	_floor_y = _sample_floor_y(_actor.global_position)
	_upright_model_rotation = _model.rotation if _model != null else Vector3.ZERO
	_base_model_rotation = _upright_model_rotation

	var impulse := IMPULSE.compute_fall_impulse(_skeleton, hit_info)
	if lasso_drag:
		_fall_pitch = 0.0
		_fall_pitch_velocity = 0.0
		_fall_roll = 0.0
		_fall_roll_velocity = 0.0
		_fall_yaw = 0.0
		_fall_yaw_velocity = 0.0
		_knockback_offset = Vector3.ZERO
		_knockback_velocity = Vector3.ZERO
		_fall_progress = 0.0
	else:
		_fall_pitch = 0.0
		_fall_pitch_velocity = impulse.pitch_velocity
		_fall_roll = 0.0
		_fall_roll_velocity = impulse.roll_velocity
		_fall_yaw = 0.0
		_fall_yaw_velocity = impulse.yaw_velocity
		_knockback_offset = Vector3.ZERO
		_knockback_velocity = impulse.knockback_velocity
		_fall_progress = 0.0
	_airborne = hit_info.get("mounted_dismount", false)
	_air_velocity = hit_info.get("mounted_launch_velocity", Vector3.ZERO)
	if _airborne and _air_velocity.length_squared() < 0.0001:
		var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
		_air_velocity = shot_direction * 7.0 + Vector3.UP * 4.5

	_disable_actor_collision()
	set_physics_process(true)
	_bind_end_frame_apply()
	var spine02: Vector3 = _limb_angles.get("Spine02", Vector3.ZERO)
	var right_arm: Vector3 = _limb_angles.get("RightArm", Vector3.ZERO)
	_dbg("activate done pitch_vel=%.2f spine02=%s right_arm=%s" % [
		_fall_pitch_velocity,
		spine02,
		right_arm,
	])


func deactivate() -> void:
	if not _active:
		return

	_dbg("deactivate")
	_active = false
	_lasso_drag_mode = false
	_lasso_settling = false
	_lasso_pull_velocity = Vector3.ZERO
	var was_standup := _lasso_standup_recovery
	_lasso_standup_recovery = false
	set_physics_process(false)
	_restore_actor_collision()
	_unbind_end_frame_apply()
	_configure_skeleton_modifiers(false)
	_restore_dropped_revolver()
	_restore_dropped_hat()
	_restore_skeleton_attachments()

	if _actor != null:
		if was_standup:
			_floor_y = _sample_floor_y(_actor.global_position)
			var ground_y := _floor_y + ACTOR_GROUND_OFFSET - _get_actor_feet_offset()
			_actor.global_position.y = ground_y
			_base_actor_transform.origin = _actor.global_position
		else:
			_actor.global_transform = _base_actor_transform
	if _model != null:
		if was_standup:
			_upright_model_rotation.y = _get_settle_facing_yaw()
			_model.rotation = _upright_model_rotation
			_base_model_rotation = _upright_model_rotation
		else:
			_model.rotation = _base_model_rotation

	if _skeleton != null:
		if was_standup:
			call_deferred("_reset_skeleton_after_standup")
		else:
			_skeleton.reset_bone_poses()

	_fall_pitch = 0.0
	_fall_pitch_velocity = 0.0
	_fall_roll = 0.0
	_fall_roll_velocity = 0.0
	_fall_yaw = 0.0
	_fall_yaw_velocity = 0.0
	_knockback_offset = Vector3.ZERO
	_knockback_velocity = Vector3.ZERO
	_airborne = false
	_air_velocity = Vector3.ZERO
	_fall_progress = 0.0
	_captured_bone_poses.clear()
	_limb_angles.clear()
	_limb_velocities.clear()
	_revolver_restore.clear()


func _reset_skeleton_after_standup() -> void:
	if _skeleton != null:
		_skeleton.reset_bone_poses()


func _physics_process(delta: float) -> void:
	if not _active or _actor == null or _skeleton == null:
		return

	var sim_delta := GameTime.physics_delta(delta)

	if _lasso_drag_mode:
		_process_lasso_drag(sim_delta)
	elif _lasso_settling:
		_process_lasso_settle(sim_delta)
	else:
		_process_defeat_fall(sim_delta)

	_apply_body_transform(sim_delta)
	_simulate_limbs(sim_delta)
	apply_skeleton_poses()
	_clamp_lasso_drag_to_floor(sim_delta)
	_update_settle_modifier_influence()

	_debug_tick += 1
	if debug_ragdoll and _debug_tick <= 3:
		var arm_offset: Vector3 = _limb_angles.get("RightArm", Vector3.ZERO)
		var spine_offset: Vector3 = _limb_angles.get("Spine02", Vector3.ZERO)
		_dbg("physics tick=%d pitch=%.1f arm_offset=%s spine02=%s" % [
			_debug_tick,
			rad_to_deg(_fall_pitch),
			arm_offset,
			spine_offset,
		])


func _process_defeat_fall(sim_delta: float) -> void:
	_fall_pitch_velocity += 7.5 * sim_delta
	_fall_pitch_velocity -= _fall_pitch * 4.5 * sim_delta
	_fall_pitch_velocity *= exp(-2.2 * sim_delta)
	_fall_pitch += _fall_pitch_velocity * sim_delta
	_fall_pitch = clampf(_fall_pitch, 0.0, MAX_PITCH_RAD)

	_fall_roll_velocity -= _fall_roll * 4.0 * sim_delta
	_fall_roll_velocity *= exp(-2.4 * sim_delta)
	_fall_roll += _fall_roll_velocity * sim_delta
	_fall_roll = clampf(_fall_roll, -MAX_ROLL_RAD, MAX_ROLL_RAD)

	_fall_yaw_velocity -= _fall_yaw * 3.5 * sim_delta
	_fall_yaw_velocity *= exp(-2.6 * sim_delta)
	_fall_yaw += _fall_yaw_velocity * sim_delta
	_fall_yaw = clampf(_fall_yaw, -MAX_YAW_RAD, MAX_YAW_RAD)

	_fall_progress = clampf(_fall_pitch / SETTLE_PITCH_RAD, 0.0, 1.0)

	var knockback_limit := (
		SETTLED_KNOCKBACK_LIMIT
		if _fall_progress > 0.72
		else FALL_KNOCKBACK_LIMIT
	)
	const knockback_drag := 3.0
	_knockback_velocity = _knockback_velocity.lerp(
		Vector3.ZERO,
		1.0 - exp(-knockback_drag * sim_delta)
	)
	_knockback_offset += _knockback_velocity * sim_delta
	if _knockback_offset.length() > knockback_limit:
		_knockback_offset = _knockback_offset.normalized() * knockback_limit

	if _fall_progress > 0.98 and absf(_fall_pitch_velocity) < 0.05:
		_fall_pitch_velocity = 0.0
		_fall_pitch = lerpf(_fall_pitch, SETTLE_PITCH_RAD, 1.0 - exp(-6.0 * sim_delta))


func _process_lasso_drag(sim_delta: float) -> void:
	var pull_speed := _lasso_pull_velocity.length()
	var pull_drive := clampf(pull_speed / 6.0, 0.2, 1.35)
	var drag_target := lerpf(LASSO_DRAG_PITCH_MIN, LASSO_DRAG_PITCH_MAX, pull_drive)

	_fall_pitch_velocity += (3.6 + pull_drive * 2.8) * sim_delta
	_fall_pitch_velocity += (drag_target - _fall_pitch) * 3.0 * sim_delta
	_fall_pitch_velocity -= _fall_pitch * 1.6 * sim_delta
	_fall_pitch_velocity *= exp(-1.1 * sim_delta)
	_fall_pitch += _fall_pitch_velocity * sim_delta
	_fall_pitch = clampf(_fall_pitch, 0.0, LASSO_DRAG_PITCH_MAX)

	_fall_roll_velocity += randf_range(-0.45, 0.45) * sim_delta
	_fall_roll_velocity -= _fall_roll * 2.8 * sim_delta
	_fall_roll_velocity *= exp(-2.0 * sim_delta)
	_fall_roll += _fall_roll_velocity * sim_delta
	_fall_roll = clampf(_fall_roll, -MAX_ROLL_RAD, MAX_ROLL_RAD)

	_fall_yaw_velocity -= _fall_yaw * 2.4 * sim_delta
	_fall_yaw_velocity *= exp(-2.2 * sim_delta)
	_fall_yaw += _fall_yaw_velocity * sim_delta

	_fall_progress = clampf(_fall_pitch / SETTLE_PITCH_RAD, 0.0, 0.95)

	var pull := _lasso_pull_velocity
	if pull.length_squared() > 0.0001 and _actor != null:
		var step := Vector3(pull.x, 0.0, pull.z) * sim_delta
		_actor.global_position += step
		_base_actor_transform.origin = _actor.global_position


func _process_lasso_settle(sim_delta: float) -> void:
	const settle_snap := 0.07
	const min_stand_alpha := 0.88

	var stand_spring := 5.2
	_fall_pitch_velocity += (0.0 - _fall_pitch) * stand_spring * sim_delta
	_fall_pitch_velocity *= exp(-3.0 * sim_delta)
	_fall_pitch += _fall_pitch_velocity * sim_delta
	_fall_pitch = maxf(_fall_pitch, 0.0)

	_fall_roll = lerpf(_fall_roll, 0.0, 1.0 - exp(-4.5 * sim_delta))
	_fall_yaw = lerpf(_fall_yaw, 0.0, 1.0 - exp(-4.5 * sim_delta))
	_knockback_velocity = _knockback_velocity.lerp(Vector3.ZERO, 1.0 - exp(-5.0 * sim_delta))
	_knockback_offset = _knockback_offset.lerp(Vector3.ZERO, 1.0 - exp(-6.0 * sim_delta))
	_fall_progress = clampf(_fall_pitch / SETTLE_PITCH_RAD, 0.0, 1.0)

	var limb_blend := 1.0 - exp(-7.0 * sim_delta)
	for bone_name in _limb_angles.keys():
		_limb_angles[bone_name] = (_limb_angles[bone_name] as Vector3).lerp(Vector3.ZERO, limb_blend)
		_limb_velocities[bone_name] = Vector3.ZERO

	var modifier_done := _pose_modifier == null or _pose_modifier.influence < 0.12
	if (
		_fall_pitch < settle_snap
		and get_lasso_settle_alpha() >= min_stand_alpha
		and modifier_done
		and _knockback_offset.length_squared() < 0.003
	):
		_fall_pitch = 0.0
		_fall_roll = 0.0
		_fall_yaw = 0.0
		if _actor != null:
			_base_actor_transform = _actor.global_transform
		_lasso_settling = false
		deactivate()


func _apply_body_transform(sim_delta: float) -> void:
	_apply_model_fall_rotation()

	_floor_y = _sample_floor_y(_actor.global_position)

	if _lasso_drag_mode or _lasso_settling:
		var hip_drop := _get_lasso_hip_drop()
		var knockback := _knockback_offset if _lasso_settling else Vector3.ZERO
		var target := _base_actor_transform.origin + knockback
		var min_origin_y := _floor_y + ACTOR_GROUND_OFFSET - _get_actor_feet_offset()
		target.y = maxf(min_origin_y, _base_actor_transform.origin.y - hip_drop)
		var blend := 1.0 - exp(-14.0 * sim_delta)
		_actor.global_position = _actor.global_position.lerp(target, blend)
		return

	if _airborne:
		const gravity := 22.0
		var ground_y := _floor_y + ACTOR_GROUND_OFFSET
		_air_velocity.y -= gravity * sim_delta
		var next_pos := _actor.global_position + _air_velocity * sim_delta
		if next_pos.y <= ground_y:
			next_pos.y = ground_y
			_airborne = false
			_air_velocity = Vector3.ZERO
			_base_actor_transform.origin = next_pos
		_actor.global_position = next_pos
		return

	var hip_drop := sin(_fall_pitch) * 0.42
	var target := _base_actor_transform.origin + _knockback_offset
	var min_origin_y := _floor_y - _get_actor_feet_offset()
	target.y = maxf(min_origin_y, _base_actor_transform.origin.y - hip_drop)
	var blend := 1.0 - exp(-12.0 * sim_delta)
	_actor.global_position = _actor.global_position.lerp(target, blend)

	if (
		_fall_progress > 0.85
		and _knockback_velocity.length_squared() < 0.001
		and _knockback_offset.length_squared() > 0.0004
	):
		_base_actor_transform.origin += _knockback_offset
		_knockback_offset = Vector3.ZERO
		_floor_y = _sample_floor_y(_actor.global_position)


func _disable_actor_collision() -> void:
	if _actor == null:
		return

	_disabled_actor_collisions.clear()
	for child in _actor.get_children():
		var collision := child as CollisionShape3D
		if collision == null or collision.disabled:
			continue
		_disabled_actor_collisions.append(collision)
		collision.disabled = true


func _restore_actor_collision() -> void:
	for collision in _disabled_actor_collisions:
		if is_instance_valid(collision):
			collision.disabled = false
	_disabled_actor_collisions.clear()


func _reset_limb_simulation(hit_info: Dictionary) -> void:
	_limb_angles.clear()
	_limb_velocities.clear()

	var shot_direction: Vector3 = hit_info.get("direction", Vector3.FORWARD).normalized()
	var side_sign := 1.0 if shot_direction.dot(_skeleton.global_transform.basis.x) >= 0.0 else -1.0
	var gun_arm_kick := IMPULSE.compute_gun_arm_kick(_skeleton, hit_info)
	var spine_bend: Dictionary = IMPULSE.compute_spine_bend(_skeleton, hit_info)

	const GUN_ARM_CHAIN := {
		"RightShoulder": 0.55,
		"RightArm": 1.0,
		"RightForeArm": 1.2,
		"RightHand": 0.95,
	}

	for bone_name in LIMB_SIM_BONES:
		var hit_angle := Vector3.ZERO
		if spine_bend.has(bone_name):
			hit_angle = spine_bend[bone_name]

		_limb_angles[bone_name] = hit_angle
		var kick := Vector3.ZERO
		if bone_name.begins_with("RightArm") or bone_name == "RightShoulder":
			kick = Vector3(-0.18, 0.12 * side_sign, 0.22)
		elif bone_name.begins_with("LeftArm") or bone_name == "LeftShoulder":
			kick = Vector3(-0.18, -0.12 * side_sign, -0.22)
		elif bone_name.begins_with("RightForeArm") or bone_name == "RightHand":
			kick = Vector3(0.28, 0.08 * side_sign, 0.15)
		elif bone_name.begins_with("LeftForeArm") or bone_name == "LeftHand":
			kick = Vector3(0.28, -0.08 * side_sign, -0.15)

		if GUN_ARM_CHAIN.has(bone_name):
			var chain_scale: float = GUN_ARM_CHAIN[bone_name]
			var gun_impulse := gun_arm_kick * chain_scale
			_limb_angles[bone_name] += gun_impulse * 1.35
			kick += gun_impulse * 2.4

		_limb_velocities[bone_name] = kick


func _reset_lasso_limb_simulation(pull_direction: Vector3) -> void:
	_limb_angles.clear()
	_limb_velocities.clear()
	if _skeleton == null:
		return

	var pull := (
		pull_direction.normalized()
		if pull_direction.length_squared() > 0.0001
		else -_skeleton.global_transform.basis.z
	)
	var side_sign := 1.0 if pull.dot(_skeleton.global_transform.basis.x) >= 0.0 else -1.0
	var backward := -_skeleton.global_transform.basis.z.normalized()
	var tip_drive := clampf(pull.dot(backward), 0.0, 1.0)

	for bone_name in LIMB_SIM_BONES:
		_limb_angles[bone_name] = Vector3.ZERO
		var kick := Vector3.ZERO
		match bone_name:
			"Hips":
				kick = Vector3(-0.12 * tip_drive, 0.04 * side_sign, 0.03)
			"Spine", "Spine01", "Spine02":
				kick = Vector3(-0.22 * tip_drive, 0.05 * side_sign, 0.04)
			"RightShoulder", "LeftShoulder":
				kick = Vector3(-0.08, 0.14 * side_sign, 0.2 * side_sign)
			"RightArm", "LeftArm":
				kick = Vector3(0.14, 0.1 * side_sign, 0.24 * side_sign)
			"RightForeArm", "LeftForeArm":
				kick = Vector3(0.22, 0.04 * side_sign, 0.1 * side_sign)
			"RightHand", "LeftHand":
				kick = Vector3(0.08, 0.0, 0.06 * side_sign)
			"LeftUpLeg", "RightUpLeg":
				kick = Vector3(-0.16 * tip_drive, 0.05 * side_sign, 0.08)
			"LeftLeg", "RightLeg":
				kick = Vector3(0.18 * tip_drive, 0.0, 0.05 * side_sign)
			"neck", "Head":
				kick = Vector3(0.1 * tip_drive, 0.0, 0.0)

		_limb_velocities[bone_name] = kick * 0.55


func _apply_model_fall_rotation() -> void:
	var upright_euler := _upright_model_rotation
	if _lasso_settling and _model != null:
		upright_euler.y = _get_settle_facing_yaw()

	if _model != null:
		var upright := Basis.from_euler(upright_euler)
		var fall := Basis.from_euler(Vector3(_fall_pitch, _fall_yaw, _fall_roll))
		_model.basis = upright * fall
		return

	if _actor != null:
		_actor.rotation.x = _fall_pitch
		_actor.rotation.y = upright_euler.y + _fall_yaw
		_actor.rotation.z = _fall_roll


func _get_settle_facing_yaw() -> float:
	if _actor is CharacterBody3D:
		var body := _actor as CharacterBody3D
		var vel := Vector3(body.velocity.x, 0.0, body.velocity.z)
		if vel.length_squared() > 0.04:
			return GroyperBodyUtils.facing_yaw_for_direction(vel)
	return _upright_model_rotation.y


func _get_lasso_hip_drop() -> float:
	var body_extent := 1.55
	if _actor != null:
		for child in _actor.get_children():
			var collision := child as CollisionShape3D
			if collision == null or collision.shape == null:
				continue
			if collision.shape is CapsuleShape3D:
				body_extent = (collision.shape as CapsuleShape3D).height
				break
	return sin(_fall_pitch) * maxf(0.42, body_extent * LASSO_HIP_DROP_SCALE)


func _simulate_limbs(delta: float) -> void:
	if _lasso_settling:
		return

	var flop_strength := clampf(_fall_progress * 1.1, 0.0, 1.0)
	var pitch_drive := _fall_pitch_velocity

	for bone_name in LIMB_SIM_BONES:
		var cfg: Dictionary = LIMB_SIM.get(bone_name, {})
		if cfg.is_empty():
			continue

		var angle: Vector3 = _limb_angles.get(bone_name, Vector3.ZERO)
		var velocity: Vector3 = _limb_velocities.get(bone_name, Vector3.ZERO)
		var rest := _get_limb_rest_angle(bone_name, flop_strength, cfg)

		velocity.x += pitch_drive * cfg.get("inertia_pitch", 0.5) * delta
		velocity.x += flop_strength * cfg.get("gravity_pull", 0.5) * delta
		velocity += (rest - angle) * cfg.get("spring", 6.0) * delta

		var follow_bone: String = cfg.get("follow_bone", "")
		if not follow_bone.is_empty() and _limb_angles.has(follow_bone):
			var parent_angle: Vector3 = _limb_angles[follow_bone]
			var follow_strength: float = cfg.get("follow_strength", 0.3)
			velocity += (parent_angle * follow_strength - angle) * (cfg.get("spring", 6.0) * 0.65) * delta

		var damp: float = cfg.get("damp", 2.5)
		velocity *= exp(-damp * delta)
		angle += velocity * delta

		_limb_angles[bone_name] = angle
		_limb_velocities[bone_name] = velocity


func apply_skeleton_poses() -> void:
	if not _active or _skeleton == null:
		return

	for bone_name: String in _captured_bone_poses:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue

		var pose: Quaternion = _captured_bone_poses[bone_name]
		if _limb_angles.has(bone_name):
			var offset: Vector3 = _limb_angles[bone_name]
			if offset.length_squared() > 0.000001:
				var offset_q := Basis.from_euler(offset).get_rotation_quaternion()
				pose = (offset_q * pose).normalized()
		_skeleton.set_bone_pose_rotation(bone_id, pose)


## Kept for GroyperRagdollModifier compatibility.
func apply_limb_poses() -> void:
	apply_skeleton_poses()


func _get_limb_rest_angle(bone_name: String, strength: float, cfg: Dictionary) -> Vector3:
	var scale: float = cfg.get("rest_scale", 1.0) * strength

	match bone_name:
		"Hips":
			return Vector3(0.06 * scale, 0.04 * scale, 0.05 * scale)
		"Spine":
			return Vector3(0.18 * scale, 0.06 * scale, 0.04 * scale)
		"Spine01":
			return Vector3(0.28 * scale, 0.08 * scale, 0.05 * scale)
		"Spine02":
			return Vector3(0.36 * scale, 0.1 * scale, 0.06 * scale)
		"RightShoulder":
			return Vector3(0.08 * scale, 0.12 * scale, 0.28 * scale)
		"RightArm":
			return Vector3(0.72 * scale, 0.18 * scale, 0.42 * scale)
		"RightForeArm":
			return Vector3(0.95 * scale, 0.05 * scale, 0.12 * scale)
		"RightHand":
			return Vector3(0.18 * scale, 0.0, 0.08 * scale)
		"LeftShoulder":
			return Vector3(0.08 * scale, -0.12 * scale, -0.28 * scale)
		"LeftArm":
			return Vector3(0.72 * scale, -0.18 * scale, -0.42 * scale)
		"LeftForeArm":
			return Vector3(0.95 * scale, -0.05 * scale, -0.12 * scale)
		"LeftHand":
			return Vector3(0.18 * scale, 0.0, -0.08 * scale)
		"LeftUpLeg":
			return Vector3(-0.18 * scale, 0.08 * scale, 0.16 * scale)
		"LeftLeg":
			return Vector3(0.42 * scale, 0.0, 0.08 * scale)
		"RightUpLeg":
			return Vector3(-0.18 * scale, -0.08 * scale, -0.16 * scale)
		"RightLeg":
			return Vector3(0.42 * scale, 0.0, -0.08 * scale)
		"neck":
			return Vector3(0.22 * scale, 0.0, 0.0)
		"Head":
			return Vector3(0.12 * scale, 0.0, 0.0)
		_:
			return Vector3.ZERO


func _ensure_visual_pose_before_capture() -> void:
	if _actor == null:
		return
	var weapon_rig := _actor.get_node_or_null("WeaponRig")
	if weapon_rig != null and weapon_rig.has_method("apply_pose_overrides"):
		weapon_rig.apply_pose_overrides(1.0)


func _capture_pose() -> void:
	_captured_bone_poses.clear()
	if _skeleton == null:
		return

	for bone_id in _skeleton.get_bone_count():
		var bone_name := _skeleton.get_bone_name(bone_id)
		_captured_bone_poses[bone_name] = _skeleton.get_bone_pose_rotation(bone_id)


func _bake_captured_pose() -> void:
	apply_skeleton_poses()


func _sample_floor_y(from_position: Vector3) -> float:
	var space_state := _actor.get_world_3d().direct_space_state
	if space_state == null:
		return from_position.y - _get_actor_feet_offset()

	var xz := Vector3(from_position.x, 0.0, from_position.z)
	var ray_from := xz + Vector3(0.0, FLOOR_RAY_HEIGHT, 0.0)
	var ray_to := xz - Vector3(0.0, FLOOR_RAY_DEPTH, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = FLOOR_MASK
	query.exclude = _collect_actor_collision_rids()
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		query.collision_mask = 0x7FFFFFFF
		hit = space_state.intersect_ray(query)
	if hit.is_empty():
		return from_position.y - _get_actor_feet_offset()
	return hit.position.y


func _collect_actor_collision_rids() -> Array[RID]:
	var rids: Array[RID] = []
	if _actor is CollisionObject3D:
		rids.append((_actor as CollisionObject3D).get_rid())
	if _actor != null:
		for node: CollisionObject3D in _actor.find_children(
			"*",
			"CollisionObject3D",
			true,
			false
		):
			rids.append(node.get_rid())
	return rids


func _get_actor_feet_offset() -> float:
	if _actor == null:
		return ACTOR_GROUND_OFFSET
	for child in _actor.get_children():
		var collision := child as CollisionShape3D
		if collision == null:
			continue
		var shape := collision.shape
		if shape is CapsuleShape3D:
			var capsule := shape as CapsuleShape3D
			return collision.position.y - capsule.height * 0.5
	return ACTOR_GROUND_OFFSET


func _get_head_world_position() -> Vector3:
	if _skeleton == null:
		if _actor != null:
			return _actor.global_position + Vector3(0.0, 1.55, 0.0)
		return Vector3.ZERO
	var head_id := _skeleton.find_bone("Head")
	if head_id < 0:
		return _actor.global_position + Vector3(0.0, 1.55, 0.0)
	return (_skeleton.global_transform * _skeleton.get_bone_global_pose(head_id)).origin


func _get_drag_lowest_world_y() -> float:
	if _skeleton == null:
		return _actor.global_position.y if _actor != null else 0.0
	var lowest := INF
	for bone_name in LIMB_DRAG_FLOOR_BONES:
		var bone_id := _skeleton.find_bone(bone_name)
		if bone_id < 0:
			continue
		var bone_y := (_skeleton.global_transform * _skeleton.get_bone_global_pose(bone_id)).origin.y
		lowest = minf(lowest, bone_y)
	if lowest == INF and _actor != null:
		return _actor.global_position.y
	return lowest


func _clamp_lasso_drag_to_floor(_sim_delta: float) -> void:
	if not (_lasso_drag_mode or _lasso_settling) or _actor == null:
		return

	_floor_y = _sample_floor_y(_actor.global_position)
	var raise := 0.0

	var head_pos := _get_head_world_position()
	var head_floor := _floor_y + LASSO_HEAD_FLOOR_CLEARANCE
	if head_pos.y < head_floor:
		raise = maxf(raise, head_floor - head_pos.y)

	var lowest_y := _get_drag_lowest_world_y()
	var floor_fix := _floor_y + ACTOR_GROUND_OFFSET - lowest_y
	if floor_fix > 0.0:
		raise = maxf(raise, floor_fix)

	if raise <= 0.001:
		return

	_actor.global_position.y += raise
	_base_actor_transform.origin.y += raise


func _update_settle_modifier_influence() -> void:
	if _pose_modifier == null:
		return
	if _lasso_settling:
		var alpha := get_lasso_settle_alpha()
		_pose_modifier.influence = 1.0 - smoothstep(0.15, 0.95, alpha)
	elif _lasso_drag_mode:
		_pose_modifier.influence = 1.0


func _stop_animation_sources(animation_player: AnimationPlayer) -> void:
	_animation_tree = _find_actor_animation_tree()
	if _animation_tree != null:
		if _animation_tree.get("parameters/LeanBlend/blend_position") != null:
			_animation_tree.set("parameters/LeanBlend/blend_position", Vector2.ZERO)
		if _animation_tree.get("parameters/IdleLeanMix/blend_amount") != null:
			_animation_tree.set("parameters/IdleLeanMix/blend_amount", 0.0)
		_animation_tree.active = false
		_animation_tree.process_mode = Node.PROCESS_MODE_DISABLED
		_dbg("stopped AnimationTree on %s" % _animation_tree.get_parent().name)

	var player := _resolve_animation_player(animation_player)
	if player != null:
		_animation_player = player
		if player.is_playing():
			player.pause()
		player.active = false
		player.speed_scale = 0.0
		player.process_mode = Node.PROCESS_MODE_DISABLED
		_dbg("paused AnimationPlayer playing=%s" % player.is_playing())


func _suspend_actor_animations() -> void:
	if _actor != null and _actor.has_method("suspend_animations_for_ragdoll"):
		_actor.suspend_animations_for_ragdoll()


func _resolve_animation_player(fallback: AnimationPlayer) -> AnimationPlayer:
	if fallback != null:
		return fallback
	if _skeleton == null:
		return null
	var body := _skeleton.get_parent().get_parent()
	if body == null:
		return null
	return body.get_node_or_null("AnimationPlayer") as AnimationPlayer


func _bind_end_frame_apply() -> void:
	if _end_frame_apply_bound:
		return
	var tree := get_tree()
	if tree == null:
		return
	tree.process_frame.connect(_on_end_frame_apply)
	_end_frame_apply_bound = true


func _unbind_end_frame_apply() -> void:
	if not _end_frame_apply_bound:
		return
	var tree := get_tree()
	if tree != null and tree.process_frame.is_connected(_on_end_frame_apply):
		tree.process_frame.disconnect(_on_end_frame_apply)
	_end_frame_apply_bound = false


func _on_end_frame_apply() -> void:
	if not _active:
		return
	apply_skeleton_poses()


func _find_actor_animation_tree() -> AnimationTree:
	if _actor == null:
		return null
	for node in _actor.find_children("*", "AnimationTree", true, false):
		return node as AnimationTree
	return null


func _hide_skeleton_attachments() -> void:
	_hidden_attachments.clear()
	if _skeleton == null:
		return

	for child in _skeleton.get_children():
		if child is BoneAttachment3D and child.visible:
			child.visible = false
			_hidden_attachments.append(child)


func _restore_skeleton_attachments() -> void:
	var duel_hat := _resolve_duel_hat()
	var hat_knocked_off := (
		duel_hat != null
		and duel_hat.has_method("should_restore_after_ragdoll")
		and not duel_hat.should_restore_after_ragdoll()
	)
	for attachment in _hidden_attachments:
		if not is_instance_valid(attachment):
			continue
		if hat_knocked_off and attachment.name == "CowboyHatMount":
			continue
		attachment.visible = true
	_hidden_attachments.clear()


func _find_revolver_grip() -> Node3D:
	if _skeleton == null:
		return null

	return _skeleton.find_child("RevolverGrip", true, false) as Node3D


func _configure_skeleton_modifiers(ragdoll_active: bool) -> void:
	if _skeleton == null:
		return

	_install_pose_modifier()
	for child in _skeleton.get_children():
		if not child is SkeletonModifier3D:
			continue
		var modifier := child as SkeletonModifier3D
		modifier.active = ragdoll_active if child == _pose_modifier else not ragdoll_active

	if ragdoll_active and _pose_modifier != null:
		_pose_modifier.active = true
		_skeleton.move_child(_pose_modifier, -1)
		_pose_modifier.process_priority = 256
		_pose_modifier.influence = 1.0
		_dbg("RagdollModifier enabled on skeleton")


func _install_pose_modifier() -> void:
	if _skeleton == null:
		return

	_pose_modifier = _skeleton.get_node_or_null("RagdollModifier") as GroyperRagdollModifier
	if _pose_modifier != null:
		_pose_modifier.ragdoll = self
		return

	_pose_modifier = POSE_MODIFIER_SCRIPT.new()
	_pose_modifier.name = "RagdollModifier"
	_pose_modifier.ragdoll = self
	_skeleton.add_child(_pose_modifier)
	_skeleton.move_child(_pose_modifier, -1)


func _launch_dropped_revolver(hit_info: Dictionary) -> void:
	_restore_dropped_revolver()

	var grip := _find_revolver_grip()
	if grip == null:
		return

	var mount := grip.get_parent()
	_revolver_restore = {
		"mount": mount,
		"local_transform": grip.transform,
	}

	var world_parent := _actor.get_tree().current_scene
	if world_parent == null:
		world_parent = _actor.get_tree().root

	_dropped_revolver = DROPPED_REVOLVER.launch_from_grip(grip, hit_info, world_parent, _actor)
	_notify_actor_revolver_dropped()


func _notify_actor_revolver_dropped() -> void:
	if _actor == null:
		return
	if _actor.has_method("on_revolver_dropped"):
		_actor.on_revolver_dropped()
	var weapon_rig := _actor.get_node_or_null("WeaponRig")
	if weapon_rig != null and weapon_rig.has_method("on_revolver_dropped"):
		weapon_rig.on_revolver_dropped()


func _restore_dropped_revolver() -> void:
	if not is_instance_valid(_dropped_revolver):
		_dropped_revolver = null
		_revolver_restore.clear()
		return

	var grip := _dropped_revolver.find_child("RevolverGrip", true, false) as Node3D
	if grip != null and not _revolver_restore.is_empty():
		var mount: Node = _revolver_restore.get("mount")
		if is_instance_valid(mount):
			var grip_global := grip.global_transform
			grip.reparent(mount, true)
			grip.global_transform = grip_global
			grip.transform = _revolver_restore.get("local_transform", grip.transform)

	_dropped_revolver.queue_free()
	_dropped_revolver = null
	_revolver_restore.clear()


func _launch_dropped_hat(hit_info: Dictionary) -> void:
	if _actor != null and _actor.has_method("get_hat_collectible_id"):
		if _launch_collectible_hat_drop(hit_info):
			return

	var duel_hat := _resolve_duel_hat()
	if duel_hat == null or not duel_hat.can_drop():
		return

	var world_parent := _get_world_parent()
	duel_hat.drop_from_head(hit_info, world_parent, _actor)


func _launch_lasso_dropped_hat(hit_info: Dictionary) -> void:
	_launch_collectible_hat_drop(hit_info)


func _launch_collectible_hat_drop(hit_info: Dictionary) -> bool:
	var duel_hat := _resolve_duel_hat()
	if duel_hat == null:
		return false

	if _skeleton != null:
		duel_hat.refresh_hat_nodes(_skeleton)
	elif _actor != null and _actor.has_method("get_lasso_hat_skeleton"):
		duel_hat.refresh_hat_nodes(_actor.call("get_lasso_hat_skeleton") as Skeleton3D)

	if not duel_hat.can_drop():
		return false

	var hat_id := &"red"
	if _actor != null and _actor.has_method("get_hat_collectible_id"):
		hat_id = _actor.call("get_hat_collectible_id")

	var world_parent := _get_world_parent()
	var drop_anchor := _actor.global_position
	drop_anchor.y = GroyperBodyUtils.snap_position_to_floor(
		_actor.get_world_3d(),
		drop_anchor,
		GroyperBodyUtils.ACTOR_MODEL_Y
	).y
	_actor.set_meta(&"lasso_hat_drop_anchor", drop_anchor)
	duel_hat.knock_off_for_lasso(hit_info, world_parent, _actor, hat_id, drop_anchor)
	return true


func _get_world_parent() -> Node:
	if _actor == null:
		return get_tree().root
	var world_parent := _actor.get_tree().current_scene
	if world_parent == null:
		world_parent = _actor.get_tree().root
	return world_parent


func _restore_dropped_hat() -> void:
	var duel_hat := _resolve_duel_hat()
	if duel_hat == null:
		return
	if duel_hat.has_method("should_restore_after_ragdoll") and not duel_hat.should_restore_after_ragdoll():
		return
	duel_hat.restore_to_head_if_needed()


func _resolve_duel_hat() -> GroyperDuelHat:
	if _actor == null:
		return null
	if _actor.has_method("get_duel_hat"):
		return _actor.get_duel_hat() as GroyperDuelHat
	return null
