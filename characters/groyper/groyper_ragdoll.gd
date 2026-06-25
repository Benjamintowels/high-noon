extends Node
class_name GroyperRagdoll

## Procedural duel defeat fall — torso tips backward while limb springs add ragdoll-like lag and flop.

const IMPULSE := preload("res://characters/groyper/groyper_ragdoll_impulse.gd")
const DROPPED_REVOLVER := preload("res://characters/groyper/groyper_dropped_revolver.gd")
const DUEL_HAT := preload("res://characters/groyper/groyper_duel_hat.gd")
const POSE_MODIFIER_SCRIPT := preload("res://characters/groyper/groyper_ragdoll_modifier.gd")

const FLOOR_MASK := 1
const MAX_PITCH_RAD := deg_to_rad(92.0)
const SETTLE_PITCH_RAD := deg_to_rad(86.0)
const MAX_ROLL_RAD := deg_to_rad(38.0)
const MAX_YAW_RAD := deg_to_rad(28.0)

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

var _fall_pitch := 0.0
var _fall_pitch_velocity := 0.0
var _fall_roll := 0.0
var _fall_roll_velocity := 0.0
var _fall_yaw := 0.0
var _fall_yaw_velocity := 0.0
var _fall_progress := 0.0
var _knockback_offset := Vector3.ZERO
var _knockback_velocity := Vector3.ZERO
var _floor_y := 0.0
var _base_actor_transform: Transform3D
var _base_model_rotation := Vector3.ZERO
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
		_model.name if _model != null else "null",
	])
	_active = true
	_debug_tick = 0
	_launch_dropped_revolver(hit_info)
	_launch_dropped_hat(hit_info)
	_ensure_visual_pose_before_capture()
	_capture_pose()
	_suspend_actor_animations()
	_stop_animation_sources(animation_player)
	_configure_skeleton_modifiers(true)
	_reset_limb_simulation(hit_info)
	_bake_captured_pose()
	_hide_skeleton_attachments()
	_base_actor_transform = _actor.global_transform
	_floor_y = _sample_floor_y(_actor.global_position)
	_base_model_rotation = _model.rotation if _model != null else Vector3.ZERO

	var impulse := IMPULSE.compute_fall_impulse(_skeleton, hit_info)
	_fall_pitch = 0.0
	_fall_pitch_velocity = impulse.pitch_velocity
	_fall_roll = 0.0
	_fall_roll_velocity = impulse.roll_velocity
	_fall_yaw = 0.0
	_fall_yaw_velocity = impulse.yaw_velocity
	_knockback_offset = Vector3.ZERO
	_knockback_velocity = impulse.knockback_velocity
	_fall_progress = 0.0

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
	set_physics_process(false)
	_unbind_end_frame_apply()
	_configure_skeleton_modifiers(false)
	_restore_dropped_revolver()
	_restore_dropped_hat()
	_restore_skeleton_attachments()

	if _actor != null:
		_actor.global_transform = _base_actor_transform
	if _model != null:
		_model.rotation = _base_model_rotation

	if _skeleton != null:
		_skeleton.reset_bone_poses()

	_fall_pitch = 0.0
	_fall_pitch_velocity = 0.0
	_fall_roll = 0.0
	_fall_roll_velocity = 0.0
	_fall_yaw = 0.0
	_fall_yaw_velocity = 0.0
	_knockback_offset = Vector3.ZERO
	_knockback_velocity = Vector3.ZERO
	_fall_progress = 0.0
	_captured_bone_poses.clear()
	_limb_angles.clear()
	_limb_velocities.clear()
	_revolver_restore.clear()


func _physics_process(delta: float) -> void:
	if not _active or _actor == null or _skeleton == null:
		return

	var sim_delta := GameTime.physics_delta(delta)

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

	_knockback_velocity = _knockback_velocity.lerp(Vector3.ZERO, 1.0 - exp(-3.0 * sim_delta))
	_knockback_offset += _knockback_velocity * sim_delta
	_knockback_offset = _knockback_offset.lerp(
		_knockback_offset.normalized() * minf(_knockback_offset.length(), 0.55),
		1.0 - exp(-4.0 * sim_delta)
	)

	_fall_progress = clampf(_fall_pitch / SETTLE_PITCH_RAD, 0.0, 1.0)
	_apply_body_transform(sim_delta)
	_simulate_limbs(sim_delta)
	apply_skeleton_poses()

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

	if _fall_progress > 0.98 and absf(_fall_pitch_velocity) < 0.05:
		_fall_pitch_velocity = 0.0
		_fall_pitch = lerpf(_fall_pitch, SETTLE_PITCH_RAD, 1.0 - exp(-6.0 * sim_delta))


func _apply_body_transform(sim_delta: float) -> void:
	if _model != null:
		_model.rotation.x = _base_model_rotation.x + _fall_pitch
		_model.rotation.y = _base_model_rotation.y + _fall_yaw
		_model.rotation.z = _base_model_rotation.z + _fall_roll
	else:
		_actor.rotation.x = _fall_pitch
		_actor.rotation.y = _fall_yaw
		_actor.rotation.z = _fall_roll

	var hip_drop := sin(_fall_pitch) * 0.42
	var target := _base_actor_transform.origin + _knockback_offset
	target.y = maxf(_floor_y, _base_actor_transform.origin.y - hip_drop)
	var blend := 1.0 - exp(-12.0 * sim_delta)
	_actor.global_position = _actor.global_position.lerp(target, blend)


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


func _simulate_limbs(delta: float) -> void:
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
		return from_position.y

	var ray_from := from_position + Vector3(0.0, 1.5, 0.0)
	var ray_to := from_position + Vector3(0.0, -4.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collision_mask = FLOOR_MASK
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return from_position.y
	return hit.position.y


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
	for attachment in _hidden_attachments:
		if is_instance_valid(attachment):
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
	var duel_hat := _resolve_duel_hat()
	if duel_hat == null or not duel_hat.can_drop():
		return

	var world_parent := _actor.get_tree().current_scene
	if world_parent == null:
		world_parent = _actor.get_tree().root

	duel_hat.drop_from_head(hit_info, world_parent, _actor)


func _restore_dropped_hat() -> void:
	var duel_hat := _resolve_duel_hat()
	if duel_hat == null:
		return
	duel_hat.restore_to_head_if_needed()


func _resolve_duel_hat() -> GroyperDuelHat:
	if _actor == null:
		return null
	if _actor.has_method("get_duel_hat"):
		return _actor.get_duel_hat() as GroyperDuelHat
	return null
