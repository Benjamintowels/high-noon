extends Node
class_name GrappleController

const GrappleHookProjectileScript := preload("res://gameplay/grapple/grapple_hook_projectile.gd")
const GrappleRopeVisualScript := preload("res://gameplay/grapple/grapple_rope_visual.gd")
const GrappleTargetUtils := preload("res://gameplay/grapple/grapple_target_utils.gd")

enum State { IDLE, CHARGING, THROWING, TIGHTENING, SWINGING, RETRACTING }

const MIN_CHARGE := 0.08
const MAX_CHARGE := 0.4
const THROW_DURATION := 0.28
const TIGHTEN_DURATION := 0.32
const RETRACT_DURATION := 0.24
const MIN_ROPE_LENGTH := 2.5
const SWING_PUMP_FORCE := 5.5
const SWING_AIR_DRAG := 0.45
const RELEASE_IMPULSE_MIN := 9.0
const RELEASE_IMPULSE_SCALE := 0.92
const RELEASE_UPWARD_BIAS := 0.22
const GRAVITY := 22.0
const ROPE_CONSTRAINT_STIFFNESS := 48.0

signal state_changed(new_state: State)
signal target_highlight_changed(has_target: bool)

var max_range := GrappleTargetUtils.MAX_TARGET_RANGE

var _owner: CharacterBody3D
var _get_anchor: Callable
var _get_aim_target: Callable
var _get_ray_exclude: Callable
var _state := State.IDLE
var _charge := 0.0
var _hook: GrappleHookProjectile
var _rope: GrappleRopeVisual
var _scene_root: Node
var _anchor_node: Node3D
var _anchor_point := Vector3.ZERO
var _rope_length := MIN_ROPE_LENGTH
var _tighten_timer := 0.0
var _tighten_start_length := MIN_ROPE_LENGTH
var _highlighted_target: Node3D
var _swing_rope_angle := 0.0


func setup(
	owner_node: CharacterBody3D,
	get_anchor: Callable,
	get_aim_target: Callable,
	get_ray_exclude: Callable
) -> void:
	_owner = owner_node
	_get_anchor = get_anchor
	_get_aim_target = get_aim_target
	_get_ray_exclude = get_ray_exclude


func get_state() -> State:
	return _state


func is_active() -> bool:
	return _state != State.IDLE


func is_swinging() -> bool:
	return _state == State.SWINGING


func is_on_rope() -> bool:
	return _state in [State.THROWING, State.TIGHTENING, State.SWINGING]


func is_charging() -> bool:
	return _state == State.CHARGING


func get_charge_alpha() -> float:
	return clampf(_charge / MAX_CHARGE, 0.0, 1.0)


func has_valid_target() -> bool:
	return _highlighted_target != null and is_instance_valid(_highlighted_target)


func get_highlighted_target() -> Node3D:
	return _highlighted_target


func reset() -> void:
	_clear_highlight()
	_anchor_node = null
	_charge = 0.0
	_swing_rope_angle = 0.0
	if _hook != null and is_instance_valid(_hook):
		_hook.snap_hidden()
		_hook.queue_free()
		_hook = null
	if _rope != null and is_instance_valid(_rope):
		_rope.visible = false
	_set_state(State.IDLE)


func update(delta: float, rmb_held: bool, aim_mode_active: bool) -> void:
	if aim_mode_active and _state == State.IDLE:
		_update_target_highlight()
	else:
		_clear_highlight()

	if _state == State.RETRACTING:
		_update_rope_visual()
		return

	if _state == State.SWINGING:
		if not rmb_held:
			_release_swing()
		else:
			_update_rope_visual()
		return

	if not aim_mode_active:
		if _state in [State.THROWING, State.TIGHTENING]:
			if not rmb_held:
				_begin_retract()
			_update_rope_visual()
			return
		if is_active():
			reset()
		return

	match _state:
		State.IDLE:
			if rmb_held:
				_charge = 0.0
				_set_state(State.CHARGING)
		State.CHARGING:
			if rmb_held:
				_charge = minf(_charge + delta, MAX_CHARGE)
				if _charge >= MIN_CHARGE:
					try_throw()
			else:
				_charge = 0.0
				_set_state(State.IDLE)
		State.THROWING:
			if not rmb_held:
				_begin_retract()
		State.TIGHTENING:
			if not rmb_held:
				_begin_retract()
			else:
				_process_tighten(delta)

	_update_rope_visual()


func try_throw() -> bool:
	if _state != State.CHARGING:
		return false
	if _charge < MIN_CHARGE:
		return false
	_throw_hook()
	return true


func on_aim_released() -> void:
	if _state in [State.CHARGING, State.THROWING]:
		if _state == State.CHARGING:
			_charge = 0.0
			_set_state(State.IDLE)
		else:
			_begin_retract()


func apply_swing_physics(delta: float) -> void:
	if _owner == null or _state != State.SWINGING:
		return

	var anchor := _get_anchor_point()
	var attach := _get_player_attach_point()
	var offset := attach - anchor
	var dist := offset.length()
	if dist < 0.001:
		return

	var rope_dir := offset / dist
	var stretch := dist - _rope_length

	if stretch > 0.0:
		var attach_offset := attach - _owner.global_position
		_owner.global_position -= rope_dir * stretch
		offset = (_owner.global_position + attach_offset) - anchor
		dist = offset.length()
		if dist > 0.001:
			rope_dir = offset / dist

	_owner.velocity.y -= GRAVITY * delta

	var radial_vel := _owner.velocity.dot(rope_dir)
	if radial_vel > 0.0 and dist >= _rope_length * 0.992:
		_owner.velocity -= rope_dir * radial_vel

	if stretch > 0.0:
		_owner.velocity -= rope_dir * maxf(radial_vel, 0.0) * minf(1.0, ROPE_CONSTRAINT_STIFFNESS * delta)

	var input_dir := Vector3.ZERO
	if _owner.has_method("_get_camera_relative_input"):
		input_dir = _owner.call("_get_camera_relative_input") as Vector3
	if input_dir.length_squared() > 0.0001:
		var input_tangent := input_dir - rope_dir * input_dir.dot(rope_dir)
		if input_tangent.length_squared() > 0.0001:
			var pump := input_tangent.normalized() * SWING_PUMP_FORCE * delta
			var tangent_speed := (_owner.velocity - rope_dir * _owner.velocity.dot(rope_dir)).length()
			var pump_scale := clampf(1.0 - tangent_speed / 14.0, 0.25, 1.0)
			_owner.velocity += pump * pump_scale

	var radial_component := rope_dir * _owner.velocity.dot(rope_dir)
	var tangent_component := _owner.velocity - radial_component
	tangent_component *= exp(-SWING_AIR_DRAG * delta)
	_owner.velocity = radial_component + tangent_component

	_swing_rope_angle = atan2(offset.x, -offset.z)


func enforce_rope_constraint() -> void:
	if _owner == null or _state not in [State.SWINGING, State.TIGHTENING]:
		return

	var anchor := _get_anchor_point()
	var attach_offset := _get_player_attach_point() - _owner.global_position
	var attach := _owner.global_position + attach_offset
	var offset := attach - anchor
	var dist := offset.length()
	if dist <= _rope_length or dist < 0.001:
		return

	var rope_dir := offset / dist
	var stretch := dist - _rope_length
	_owner.global_position -= rope_dir * stretch

	var radial_vel := _owner.velocity.dot(rope_dir)
	if radial_vel > 0.0:
		_owner.velocity -= rope_dir * radial_vel


func get_rope_slack_amount() -> float:
	if _owner == null or _state != State.SWINGING:
		return 0.0
	var dist := _get_player_attach_point().distance_to(_get_anchor_point())
	return clampf((_rope_length - dist) / maxf(_rope_length, 0.001), 0.0, 1.0)


func _throw_hook() -> void:
	var throw_origin := _get_throw_anchor()
	var aim_target: Vector3 = _get_aim_target.call()
	var exclude: Array[RID] = []
	if _get_ray_exclude.is_valid():
		exclude = _get_ray_exclude.call()

	var to_aim := aim_target - throw_origin
	var direction := to_aim.normalized() if to_aim.length_squared() > 0.0001 else Vector3.FORWARD

	var anchor := GrappleTargetUtils.find_anchor_along_ray(
		_owner.get_world_3d(),
		throw_origin,
		direction,
		exclude,
		max_range
	)

	var end_point := aim_target
	if anchor != null:
		_anchor_node = anchor
		_anchor_point = GrappleTargetUtils.get_attach_point(anchor)
		end_point = _anchor_point
	else:
		_anchor_node = null
		end_point = throw_origin + direction * minf(to_aim.length(), max_range)

	_ensure_hook()
	_ensure_rope()
	_hook.launch(throw_origin, end_point, THROW_DURATION)
	if not _hook.arrived.is_connected(_on_hook_arrived):
		_hook.arrived.connect(_on_hook_arrived)
	_set_state(State.THROWING)
	_charge = 0.0


func _on_hook_arrived() -> void:
	if _state != State.THROWING:
		return

	if _anchor_node == null or not is_instance_valid(_anchor_node):
		_anchor_node = GrappleTargetUtils.find_nearest_anchor(_hook.get_hook_point())
		if _anchor_node != null:
			_anchor_point = GrappleTargetUtils.get_attach_point(_anchor_node)
			_hook.global_position = _anchor_point

	if _anchor_node == null:
		_begin_retract()
		return

	_tighten_start_length = maxf(
		_get_throw_anchor().distance_to(_get_anchor_point()),
		MIN_ROPE_LENGTH
	)
	_rope_length = _tighten_start_length * 1.12
	_tighten_timer = 0.0
	_set_state(State.TIGHTENING)


func _process_tighten(delta: float) -> void:
	_tighten_timer += delta
	var t := clampf(_tighten_timer / TIGHTEN_DURATION, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	_rope_length = lerpf(_tighten_start_length * 1.12, _tighten_start_length, eased)

	if _owner != null:
		enforce_rope_constraint()
		var anchor := _get_anchor_point()
		var attach := _get_player_attach_point()
		var to_anchor := anchor - attach
		if to_anchor.length_squared() > 0.01:
			_owner.velocity += to_anchor.normalized() * (18.0 * delta)

	if t >= 1.0:
		_rope_length = _tighten_start_length
		_begin_swing()


func _begin_swing() -> void:
	if _owner != null:
		enforce_rope_constraint()
		var rope_dir := (_get_player_attach_point() - _get_anchor_point()).normalized()
		var radial_vel := _owner.velocity.dot(rope_dir)
		if radial_vel > 0.0:
			_owner.velocity -= rope_dir * radial_vel
	_set_state(State.SWINGING)


func _release_swing() -> void:
	if _owner == null:
		reset()
		return

	var anchor := _get_anchor_point()
	var attach := _get_player_attach_point()
	var rope_dir := (attach - anchor).normalized()
	var tangent := _owner.velocity - rope_dir * _owner.velocity.dot(rope_dir)
	var launch_dir := tangent
	if launch_dir.length_squared() < 0.25:
		launch_dir = -rope_dir
	launch_dir = launch_dir.normalized()
	launch_dir.y += RELEASE_UPWARD_BIAS
	launch_dir = launch_dir.normalized()

	var speed := Vector3(_owner.velocity.x, _owner.velocity.y, _owner.velocity.z).length()
	var impulse_strength := maxf(RELEASE_IMPULSE_MIN, speed * RELEASE_IMPULSE_SCALE)
	_owner.velocity = launch_dir * impulse_strength
	_begin_retract()


func _begin_retract() -> void:
	if _hook == null or not is_instance_valid(_hook):
		reset()
		return
	if not _hook.retract_finished.is_connected(_on_retract_finished):
		_hook.retract_finished.connect(_on_retract_finished)
	_hook.begin_retract(_get_throw_anchor(), RETRACT_DURATION)
	_set_state(State.RETRACTING)


func _on_retract_finished() -> void:
	reset()


func _update_target_highlight() -> void:
	var target := _find_preview_target()
	if _highlighted_target == target:
		return
	_clear_highlight()
	_highlighted_target = target
	if target != null and target.has_method("set_targeted"):
		target.set_targeted(true)
	target_highlight_changed.emit(target != null)


func _clear_highlight() -> void:
	if _highlighted_target != null and is_instance_valid(_highlighted_target):
		if _highlighted_target.has_method("set_targeted"):
			_highlighted_target.set_targeted(false)
	_highlighted_target = null


func _find_preview_target() -> Node3D:
	if _owner == null or not _get_aim_target.is_valid():
		return null

	var throw_origin := _get_throw_anchor()
	var aim_target: Vector3 = _get_aim_target.call()
	var to_aim := aim_target - throw_origin
	if to_aim.length_squared() < 0.0001:
		return null

	var exclude: Array[RID] = []
	if _get_ray_exclude.is_valid():
		exclude = _get_ray_exclude.call()

	return GrappleTargetUtils.find_anchor_along_ray(
		_owner.get_world_3d(),
		throw_origin,
		to_aim.normalized(),
		exclude,
		max_range
	)


func _get_throw_anchor() -> Vector3:
	if _get_anchor.is_valid():
		return _get_anchor.call()
	if _owner != null:
		return _owner.global_position + Vector3(0.0, 1.35, 0.0)
	return Vector3.ZERO


func _get_player_attach_point() -> Vector3:
	return _get_throw_anchor()


func _get_anchor_point() -> Vector3:
	if _anchor_node != null and is_instance_valid(_anchor_node):
		return GrappleTargetUtils.get_attach_point(_anchor_node)
	return _anchor_point


func _ensure_scene_root() -> Node:
	if _scene_root != null and is_instance_valid(_scene_root):
		return _scene_root
	if _owner == null:
		return null
	_scene_root = _owner.get_tree().current_scene
	return _scene_root


func _ensure_hook() -> void:
	if _hook != null and is_instance_valid(_hook):
		return

	var parent := _ensure_scene_root()
	if parent == null:
		return

	_hook = GrappleHookProjectileScript.new()
	_hook.name = "GrappleHook"
	parent.add_child(_hook)

	var visual := MeshInstance3D.new()
	visual.name = "HookVisual"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.05
	mesh.bottom_radius = 0.08
	mesh.height = 0.16
	visual.mesh = mesh
	visual.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.55, 0.52, 0.48, 1.0)
	mat.metallic = 0.65
	mat.roughness = 0.35
	visual.material_override = mat
	_hook.add_child(visual)


func _ensure_rope() -> void:
	if _rope != null and is_instance_valid(_rope):
		return

	var parent := _ensure_scene_root()
	if parent == null:
		return

	_rope = GrappleRopeVisualScript.new()
	_rope.name = "GrappleRope"
	parent.add_child(_rope)


func _update_rope_visual() -> void:
	if _rope == null or not is_instance_valid(_rope):
		return
	if _state == State.IDLE:
		_rope.visible = false
		return

	var player_anchor := _get_throw_anchor()
	var hook_point := player_anchor
	if _hook != null and is_instance_valid(_hook) and _hook.visible:
		hook_point = _hook.get_hook_point()
	elif _state == State.SWINGING:
		hook_point = _get_anchor_point()

	_rope.visible = true
	var slack := get_rope_slack_amount()
	if _state in [State.THROWING, State.TIGHTENING]:
		slack = lerpf(0.45, 0.12, clampf(_tighten_timer / TIGHTEN_DURATION, 0.0, 1.0))
	elif _state == State.SWINGING:
		slack = maxf(slack, 0.08)
	_rope.update_rope(player_anchor, hook_point, slack, _swing_rope_angle)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(new_state)
	if new_state == State.IDLE and _rope != null and is_instance_valid(_rope):
		_rope.visible = false
