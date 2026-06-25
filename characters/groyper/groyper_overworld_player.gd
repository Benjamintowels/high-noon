extends CharacterBody3D

const GROYPER_RIG_SCENE := preload("res://characters/groyper/groyper_rig.tscn")
const WEAPON_RIG_SCRIPT := preload("res://characters/groyper/groyper_weapon_rig.gd")
const GroyperWeapons := preload("res://characters/groyper/groyper_weapons.gd")

const LOCOMOTION_BLEND := &"LocomotionBlend"

const WALK_SPEED := 3.6
const RUN_SPEED := 7.2
const AIM_WALK_SPEED := 2.2
const AIM_RUN_SPEED := 3.6
const GRAVITY := 22.0
const MOUSE_SENSITIVITY := 0.0025
const CAMERA_PITCH_MIN := deg_to_rad(-35.0)
const CAMERA_PITCH_MAX := deg_to_rad(55.0)
const FACING_SPEED := 12.0
const BLEND_SPEED := 8.0
const SHOT_RANGE := 140.0
const AIM_ARM_TARGET_DISTANCE := 55.0

const RETICLE_MAX_SCREEN_FRACTION := 0.32
const RETICLE_MOUSE_ACCEL := 2.4
const RETICLE_DRAG := 4.8
const RETICLE_MAX_SPEED_PX := 280.0
const RETICLE_SMOOTH := 6.5

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: Node3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _animation_tree: AnimationTree = $AnimationTree
@onready var _interact_hint: Label = $InteractHintLayer/HintLabel
@onready var _reticle_ui: CanvasLayer = $ReticleUI
@onready var _reticle: Control = $ReticleUI/Reticle
@onready var _ammo_hud: AmmoHud = $AmmoHud

var _camera_yaw := PI
var _camera_pitch := -0.15
var _locomotion_blend := 0.0
var _body: Node3D
var _skeleton: Skeleton3D
var _animation_player: AnimationPlayer
var _weapon_rig: GroyperWeaponRig
var _nearby_interactables := {}
var _dialog_active := false

var _equipped_weapon: GroyperWeapons.Id = GroyperWeapons.get_starting_weapon()
var _ammo := 6
var _shot_cooldown := 0.0
var _fire_held := false

var _reticle_offset := Vector2.ZERO
var _reticle_offset_target := Vector2.ZERO
var _reticle_velocity := Vector2.ZERO
var _reticle_limit_px := 180.0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_spawn_rig()
	_setup_weapon_rig()
	_setup_locomotion_library()
	_setup_animation_tree()
	_setup_combat_ui()
	_model.rotation.y = PI
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_reticle_limit()
	get_viewport().size_changed.connect(_update_reticle_limit)


func _setup_weapon_rig() -> void:
	if _skeleton == null:
		return

	_weapon_rig = WEAPON_RIG_SCRIPT.new()
	_weapon_rig.name = "WeaponRig"
	_weapon_rig.enable_overworld_hold_mode(true)
	add_child(_weapon_rig)
	_weapon_rig.setup(self, _skeleton, _equipped_weapon)
	_weapon_rig.draw_state_changed.connect(_on_weapon_draw_state_changed)


func _setup_combat_ui() -> void:
	_ammo = GroyperWeapons.get_max_ammo(_equipped_weapon)
	if _ammo_hud:
		_ammo_hud.configure_for_weapon(_equipped_weapon)
		_ammo_hud.sync_rounds(_ammo)
		_ammo_hud.visible = false
	if _reticle_ui:
		_reticle_ui.visible = false


func _process(delta: float) -> void:
	if _dialog_active or DialogManager.is_showing() or _weapon_rig == null:
		return

	_shot_cooldown = maxf(_shot_cooldown - delta, 0.0)

	var aim_target := _get_arm_aim_world_target()
	_weapon_rig.update(delta, aim_target)

	if _weapon_rig.can_use_reticle():
		_update_reticle(delta)
	elif _reticle:
		_reset_reticle_state()
		_reticle.set_screen_offset(Vector2.ZERO)

	_update_combat_ui()

	if _fire_held and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_fire_held = false
	if _fire_held and GroyperWeapons.is_full_auto(_equipped_weapon):
		_try_shoot()


func _input(event: InputEvent) -> void:
	if _dialog_active or DialogManager.is_showing():
		if (
			event is InputEventKey
			and event.pressed
			and event.keycode == KEY_E
		):
			_try_interact()
		return

	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		if _weapon_rig != null and _weapon_rig.can_use_reticle():
			_reticle_velocity += event.relative * RETICLE_MOUSE_ACCEL
		else:
			_camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
			_camera_pitch = clampf(
				_camera_pitch - event.relative.y * MOUSE_SENSITIVITY,
				CAMERA_PITCH_MIN,
				CAMERA_PITCH_MAX
			)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			if event.pressed:
				_try_shoot()
			_fire_held = event.pressed
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif (
		event is InputEventKey
		and event.pressed
		and event.keycode == KEY_E
	):
		_try_interact()


func _physics_process(delta: float) -> void:
	if _dialog_active or DialogManager.is_showing():
		velocity = Vector3.ZERO
		move_and_slide()
		_update_locomotion_blend(delta, 0.0, false)
		_update_interact_hint()
		return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var move_dir := _get_camera_relative_input()
	var in_combat_stance := _weapon_rig != null and not _weapon_rig.is_holstered()
	var sprinting := (
		Input.is_key_pressed(KEY_SHIFT)
		and move_dir.length_squared() > 0.0001
		and not in_combat_stance
	)
	var walk_speed := AIM_WALK_SPEED if in_combat_stance else WALK_SPEED
	var run_speed := AIM_RUN_SPEED if in_combat_stance else RUN_SPEED
	var target_speed := run_speed if sprinting else walk_speed
	var horizontal := move_dir * target_speed if move_dir.length_squared() > 0.0001 else Vector3.ZERO

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	_update_facing(delta, move_dir)
	_update_locomotion_blend(delta, horizontal.length(), sprinting)

	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch
	_update_interact_hint()


func _on_weapon_draw_state_changed(_new_state: GroyperWeaponRig.DrawState) -> void:
	_update_combat_ui()


func _update_combat_ui() -> void:
	if _weapon_rig == null:
		return

	var weapon_out := not _weapon_rig.is_holstered()
	if _ammo_hud:
		_ammo_hud.visible = weapon_out
	if _reticle_ui:
		_reticle_ui.visible = _weapon_rig.can_use_reticle()


func _try_shoot() -> void:
	if _weapon_rig == null or not _weapon_rig.can_fire():
		return
	if _shot_cooldown > 0.0 or _ammo <= 0:
		return

	_shot_cooldown = GroyperWeapons.get_shot_cooldown(_equipped_weapon)
	_weapon_rig.fire_at(_get_aim_world_target())
	_ammo -= 1
	if _ammo_hud:
		_ammo_hud.sync_rounds(_ammo, true)


func _get_reticle_screen_position() -> Vector2:
	return get_viewport().get_visible_rect().size * 0.5 + _reticle_offset


func _get_aim_ray_origin() -> Vector3:
	return _camera.project_ray_origin(_get_reticle_screen_position())


func _get_aim_direction() -> Vector3:
	return _camera.project_ray_normal(_get_reticle_screen_position()).normalized()


func _get_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()

	var space_state := get_world_3d().direct_space_state
	if space_state:
		var query := PhysicsRayQueryParameters3D.create(origin, origin + direction * SHOT_RANGE)
		query.collide_with_areas = false
		var hit := space_state.intersect_ray(query)
		if not hit.is_empty():
			return hit.position

	return origin + direction * SHOT_RANGE


func _get_arm_aim_world_target() -> Vector3:
	var origin := _get_aim_ray_origin()
	var direction := _get_aim_direction()
	return origin + direction * AIM_ARM_TARGET_DISTANCE


func _update_reticle_limit() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	_reticle_limit_px = minf(viewport_size.x, viewport_size.y) * RETICLE_MAX_SCREEN_FRACTION


func _reset_reticle_state() -> void:
	_reticle_offset = Vector2.ZERO
	_reticle_offset_target = Vector2.ZERO
	_reticle_velocity = Vector2.ZERO


func _clamp_reticle_offset(offset: Vector2) -> Vector2:
	if offset.length() <= _reticle_limit_px:
		return offset
	return offset.normalized() * _reticle_limit_px


func _apply_reticle_boundary_velocity() -> void:
	var clamped := _clamp_reticle_offset(_reticle_offset_target)
	if clamped.is_equal_approx(_reticle_offset_target):
		return
	var push := _reticle_offset_target - clamped
	if push.length_squared() < 0.001:
		return
	var boundary_normal := push.normalized()
	var outward := _reticle_velocity.dot(boundary_normal)
	if outward > 0.0:
		_reticle_velocity -= boundary_normal * outward
	_reticle_offset_target = clamped


func _update_reticle(delta: float) -> void:
	if _reticle:
		_reticle.visible = true

	_reticle_velocity *= exp(-RETICLE_DRAG * delta)
	var speed := _reticle_velocity.length()
	if speed > RETICLE_MAX_SPEED_PX:
		_reticle_velocity = _reticle_velocity * (RETICLE_MAX_SPEED_PX / speed)

	_reticle_offset_target += _reticle_velocity * delta
	_apply_reticle_boundary_velocity()

	var step := 1.0 - exp(-RETICLE_SMOOTH * delta)
	var target := _clamp_reticle_offset(_reticle_offset_target)
	_reticle_offset = _reticle_offset.lerp(target, step)

	if _reticle and _reticle.has_method("set_screen_offset"):
		_reticle.set_screen_offset(_reticle_offset)


func _update_interact_hint() -> void:
	if _interact_hint == null:
		return
	var show_hint := (
		not _dialog_active
		and not DialogManager.is_showing()
		and not _nearby_interactables.is_empty()
		and (_weapon_rig == null or _weapon_rig.is_holstered())
	)
	_interact_hint.visible = show_hint


func _spawn_rig() -> void:
	var rig: Node3D = GROYPER_RIG_SCENE.instantiate()
	_model.add_child(rig)
	_body = rig.get_node("Body") as Node3D
	_skeleton = GroyperBodyUtils.find_skeleton(_body)
	_animation_player = GroyperBodyUtils.find_animation_player(_body)


func _setup_locomotion_library() -> void:
	if _animation_player == null:
		push_error("GroyperOverworldPlayer: missing AnimationPlayer on body.")
		return

	if _animation_tree.active:
		_animation_tree.active = false

	var library := AnimationLibrary.new()
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_IDLE, RigAnimConfig.IDLE_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_WALK, RigAnimConfig.WALK_SCENE)
	_add_locomotion_clip(library, RigAnimConfig.LOCOMOTION_RUN, RigAnimConfig.RUN_SCENE)

	if _animation_player.has_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY):
		_animation_player.remove_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY)
	_animation_player.add_animation_library(RigAnimConfig.LOCOMOTION_LIBRARY, library)


func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String
) -> void:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"GroyperOverworldPlayer: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return
	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)


func _setup_animation_tree() -> void:
	if _animation_player == null:
		return

	var idle_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_IDLE]
	)
	var walk_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_WALK]
	)
	var run_path := StringName(
		"%s/%s" % [RigAnimConfig.LOCOMOTION_LIBRARY, RigAnimConfig.LOCOMOTION_RUN]
	)

	if (
		not _animation_player.has_animation(idle_path)
		or not _animation_player.has_animation(walk_path)
		or not _animation_player.has_animation(run_path)
	):
		push_error("GroyperOverworldPlayer: locomotion clips missing on AnimationPlayer.")
		return

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path

	var run_node := AnimationNodeAnimation.new()
	run_node.animation = run_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 0.5)
	blend_space.add_blend_point(run_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0
	blend_space.snap = 0.0

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.connect_node(&"output", 0, LOCOMOTION_BLEND)

	_animation_tree.tree_root = blend_tree
	_animation_tree.anim_player = _animation_tree.get_path_to(_animation_player)
	_animation_tree.process_priority = -100
	_animation_tree.active = true


func _get_camera_relative_input() -> Vector3:
	var input := Vector2.ZERO
	if Input.is_key_pressed(KEY_W):
		input.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		input.y += 1.0
	if Input.is_key_pressed(KEY_A):
		input.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		input.x += 1.0
	if input.length_squared() < 0.0001:
		return Vector3.ZERO

	var cam_basis := _camera.global_transform.basis
	var forward := -cam_basis.z
	forward.y = 0.0
	forward = forward.normalized()
	var right := cam_basis.x
	right.y = 0.0
	right = right.normalized()
	return (forward * -input.y + right * input.x).normalized()


func _update_facing(delta: float, move_dir: Vector3) -> void:
	if move_dir.length_squared() < 0.0001:
		return
	var target_yaw := atan2(move_dir.x, move_dir.z)
	_model.rotation.y = lerp_angle(_model.rotation.y, target_yaw, FACING_SPEED * delta)


func _update_locomotion_blend(delta: float, speed: float, sprinting: bool) -> void:
	var target := 0.0
	if speed > 0.05:
		target = 1.0 if sprinting else 0.5
	_locomotion_blend = lerpf(_locomotion_blend, target, BLEND_SPEED * delta)
	_animation_tree.set("parameters/LocomotionBlend/blend_position", _locomotion_blend)


func register_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables[interactable.get_instance_id()] = interactable


func unregister_interactable(interactable: Node) -> void:
	if interactable == null:
		return
	_nearby_interactables.erase(interactable.get_instance_id())


func set_dialog_active(active: bool) -> void:
	_dialog_active = active
	if active:
		velocity = Vector3.ZERO
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		if _weapon_rig != null:
			_weapon_rig.reset_to_holster()
			_reset_reticle_state()
			_update_combat_ui()
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _try_interact() -> void:
	var target := _get_nearest_interactable()
	if target != null and target.has_method("interact"):
		target.interact(self)


func _get_nearest_interactable() -> Node:
	var nearest: Node = null
	var nearest_dist_sq := INF
	for interactable: Node in _nearby_interactables.values():
		if interactable == null or not is_instance_valid(interactable):
			continue
		var dist_sq := global_position.distance_squared_to(interactable.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = interactable
	return nearest
