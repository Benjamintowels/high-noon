extends CharacterBody3D

const GROYPER_RIG_SCENE := preload("res://characters/groyper/groyper_rig.tscn")

const LOCOMOTION_BLEND := &"LocomotionBlend"

const WALK_SPEED := 3.6
const RUN_SPEED := 7.2
const GRAVITY := 22.0
const MOUSE_SENSITIVITY := 0.0025
const CAMERA_PITCH_MIN := deg_to_rad(-35.0)
const CAMERA_PITCH_MAX := deg_to_rad(55.0)
const FACING_SPEED := 12.0
const BLEND_SPEED := 8.0

@onready var _model: Node3D = $Model
@onready var _camera_pivot: Node3D = $CameraPivot
@onready var _camera_arm: Node3D = $CameraPivot/CameraArm
@onready var _camera: Camera3D = $CameraPivot/CameraArm/Camera3D
@onready var _animation_tree: AnimationTree = $AnimationTree

var _camera_yaw := PI
var _camera_pitch := -0.15
var _locomotion_blend := 0.0
var _body: Node3D
var _animation_player: AnimationPlayer


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	_spawn_rig()
	_setup_locomotion_library()
	_setup_animation_tree()
	_model.rotation.y = PI
	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		_camera_yaw -= event.relative.x * MOUSE_SENSITIVITY
		_camera_pitch = clampf(
			_camera_pitch - event.relative.y * MOUSE_SENSITIVITY,
			CAMERA_PITCH_MIN,
			CAMERA_PITCH_MAX
		)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	var move_dir := _get_camera_relative_input()
	var sprinting := Input.is_key_pressed(KEY_SHIFT) and move_dir.length_squared() > 0.0001
	var target_speed := RUN_SPEED if sprinting else WALK_SPEED
	var horizontal := move_dir * target_speed if move_dir.length_squared() > 0.0001 else Vector3.ZERO

	velocity.x = horizontal.x
	velocity.z = horizontal.z
	move_and_slide()

	_update_facing(delta, move_dir)
	_update_locomotion_blend(delta, horizontal.length(), sprinting)

	_camera_pivot.rotation.y = _camera_yaw
	_camera_arm.rotation.x = _camera_pitch


func _spawn_rig() -> void:
	var rig: Node3D = GROYPER_RIG_SCENE.instantiate()
	_model.add_child(rig)
	_body = rig.get_node("Body") as Node3D
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
