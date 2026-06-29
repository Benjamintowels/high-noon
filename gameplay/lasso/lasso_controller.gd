extends Node
class_name LassoController

const LassoRingScene := preload("res://gameplay/lasso/lasso_ring.tscn")
const LassoRopeVisualScript := preload("res://gameplay/lasso/lasso_rope_visual.gd")
const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")

enum State { IDLE, CHARGING, THROWING, DEPLOYED, TIGHTENING, DRAGGING, RETRACTING }

const MIN_CHARGE := 0.1
const MAX_CHARGE := 0.55
const THROW_DURATION := 0.42
const RETRACT_DURATION := 0.58
const TIGHTEN_DURATION := 0.42
const DRAG_ROPE_LENGTH := 8.5
const GROUND_RAY_HEIGHT := 4.0

signal state_changed(new_state: State)

var max_range := 15.0

var _owner: Node3D
var _get_anchor: Callable
var _get_aim_target: Callable
var _state := State.IDLE
var _charge := 0.0
var _ring: LassoRing
var _rope: LassoRopeVisual
var _scene_root: Node
var _captured_target: Node3D


func setup(
	owner_node: Node3D,
	get_anchor: Callable,
	get_aim_target: Callable
) -> void:
	_owner = owner_node
	_get_anchor = get_anchor
	_get_aim_target = get_aim_target


func get_state() -> State:
	return _state


func is_active() -> bool:
	return _state != State.IDLE


func is_dragging() -> bool:
	return _state == State.DRAGGING


func is_holding_captive() -> bool:
	return _state in [State.TIGHTENING, State.DRAGGING]


func get_charge_alpha() -> float:
	return clampf(_charge / MAX_CHARGE, 0.0, 1.0)


func reset() -> void:
	_release_captured_target()
	_charge = 0.0
	_disconnect_ring_signals()
	if _ring != null and is_instance_valid(_ring):
		_ring.snap_closed()
		_ring.queue_free()
		_ring = null
	if _rope != null and is_instance_valid(_rope):
		_rope.queue_free()
		_rope = null
	_set_state(State.IDLE)


func update(delta: float, rmb_held: bool, can_use: bool) -> void:
	if _state == State.RETRACTING:
		if _ring != null and is_instance_valid(_ring):
			_ring.set_retract_target(_get_throw_anchor())
		_update_rope_visual()
		return

	if _state == State.TIGHTENING:
		_update_rope_visual()
		return

	if _state == State.DRAGGING:
		_update_dragging(delta)
		return

	if not can_use:
		if _state == State.THROWING:
			if not rmb_held:
				_begin_retract()
			_update_rope_visual()
			return
		if _state == State.DEPLOYED:
			if not rmb_held:
				_try_capture_or_retract()
			else:
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
			else:
				_begin_retract()
		State.DEPLOYED:
			_validate_loose_attachment()
			if not rmb_held:
				_try_capture_or_retract()
		State.THROWING:
			if not rmb_held:
				_begin_retract()

	_update_rope_visual()


func try_throw() -> bool:
	if _state != State.CHARGING:
		return false
	if _charge < MIN_CHARGE:
		return false
	if not Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		return false

	_throw_ring()
	return true


func try_release_capture() -> bool:
	if _state != State.DRAGGING:
		return false
	_release_captured_target()
	_begin_retract(true)
	return true


func on_aim_released() -> void:
	if _state in [State.TIGHTENING, State.DRAGGING]:
		return
	if _state in [State.CHARGING, State.THROWING]:
		_begin_retract()
	elif _state == State.DEPLOYED:
		_try_capture_or_retract()


func _throw_ring() -> void:
	var anchor := _get_throw_anchor()
	var target := _resolve_throw_target(anchor)
	_ensure_ring()
	_ensure_rope()
	_ring.launch(anchor, target, THROW_DURATION)
	_set_state(State.THROWING)
	_charge = 0.0


func _try_capture_or_retract() -> void:
	var pending := _get_pending_target()
	if pending != null:
		_begin_capture(pending)
	else:
		_begin_retract()


func _get_pending_target() -> Node3D:
	if _ring == null or not is_instance_valid(_ring):
		return null
	return _ring.get_pending_target()


func _validate_loose_attachment() -> void:
	if _ring == null or not _ring.is_loosely_attached():
		return
	var target := _get_pending_target()
	if target == null or not LassoTargetUtils.is_lassoable(target):
		_begin_retract()


func _begin_capture(target: Node3D) -> void:
	if target == null or not LassoTargetUtils.is_lassoable(target):
		_begin_retract()
		return

	_captured_target = target
	if not _ring.tighten_finished.is_connected(_on_tighten_finished):
		_ring.tighten_finished.connect(_on_tighten_finished)
	_ring.begin_tighten_on(target, TIGHTEN_DURATION)
	_set_state(State.TIGHTENING)


func _begin_retract(from_release: bool = false) -> void:
	if _state in [State.IDLE, State.RETRACTING]:
		return
	if _state in [State.TIGHTENING, State.DRAGGING] and not from_release:
		return
	if _ring == null or not is_instance_valid(_ring):
		reset()
		return

	if not from_release:
		_release_captured_target()
	if not _ring.retract_finished.is_connected(_on_retract_finished):
		_ring.retract_finished.connect(_on_retract_finished)
	var anchor := _get_throw_anchor()
	_ring.begin_retract(anchor, RETRACT_DURATION)
	_set_state(State.RETRACTING)


func _release_captured_target() -> void:
	if _captured_target != null and is_instance_valid(_captured_target):
		LassoTargetUtils.end_capture(_captured_target)
	_captured_target = null
	if _ring != null and is_instance_valid(_ring):
		_ring.clear_pending_target()


func _update_dragging(_delta: float) -> void:
	if _captured_target == null or not is_instance_valid(_captured_target):
		_begin_retract()
		return

	if (
		_ring != null
		and is_instance_valid(_ring)
		and not _ring.is_physics_drag_active()
		and (
			_captured_target.is_in_group("cow")
			or _captured_target.is_in_group("stupid_horse")
		)
	):
		_ring.follow_target(_captured_target)
	_update_rope_visual()


func _resolve_throw_target(anchor: Vector3) -> Vector3:
	var aim_target: Vector3 = _get_aim_target.call()
	var to_target := aim_target - anchor
	to_target.y = 0.0

	if to_target.length_squared() < 0.01:
		to_target = _get_forward_flat() * max_range
	else:
		to_target = to_target.normalized() * minf(to_target.length(), max_range)

	var horizontal_target := anchor + to_target
	return _snap_to_ground(horizontal_target)


func _snap_to_ground(point: Vector3) -> Vector3:
	if _owner == null:
		return point

	var space_state := _owner.get_world_3d().direct_space_state
	if space_state == null:
		return point

	var ray_from := point + Vector3(0.0, GROUND_RAY_HEIGHT, 0.0)
	var ray_to := point + Vector3(0.0, -GROUND_RAY_HEIGHT * 2.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collide_with_areas = false
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return point

	return hit.position + Vector3(0.0, 0.05, 0.0)


func _get_forward_flat() -> Vector3:
	if _owner == null:
		return Vector3.FORWARD

	var forward := -_owner.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func _get_throw_anchor() -> Vector3:
	if _get_anchor.is_valid():
		return _get_anchor.call()
	if _owner != null:
		return _owner.global_position + Vector3(0.0, 1.2, 0.0)
	return Vector3.ZERO


func _ensure_scene_root() -> Node:
	if _scene_root != null and is_instance_valid(_scene_root):
		return _scene_root
	if _owner == null:
		return null
	_scene_root = _owner.get_tree().current_scene
	return _scene_root


func _ensure_ring() -> void:
	if _ring != null and is_instance_valid(_ring):
		return

	var parent := _ensure_scene_root()
	if parent == null:
		return

	_ring = LassoRingScene.instantiate() as LassoRing
	parent.add_child(_ring)
	_ring.landed.connect(_on_ring_landed)
	_ring.lasso_target_entered.connect(_on_lasso_target_entered)


func _ensure_rope() -> void:
	if _rope != null and is_instance_valid(_rope):
		return

	var parent := _ensure_scene_root()
	if parent == null:
		return

	_rope = LassoRopeVisualScript.new()
	_rope.name = "LassoRope"
	parent.add_child(_rope)


func _update_rope_visual() -> void:
	if _rope == null or not is_instance_valid(_rope):
		return
	if _state == State.IDLE:
		_rope.visible = false
		return

	if _ring == null or not is_instance_valid(_ring) or not _ring.visible:
		_rope.visible = false
		return

	_rope.visible = true
	var slack := false
	if _state == State.DRAGGING and _captured_target != null and is_instance_valid(_captured_target):
		var leader_anchor := _get_throw_anchor()
		var attach := LassoTargetUtils.get_attach_point(_captured_target)
		var dist := Vector2(leader_anchor.x - attach.x, leader_anchor.z - attach.z).length()
		var rope_len := DRAG_ROPE_LENGTH
		if _captured_target.has_method("get_lasso_rope_length"):
			rope_len = float(_captured_target.call("get_lasso_rope_length"))
		slack = dist < rope_len * 0.98
	_rope.update_rope(_get_throw_anchor(), _ring.get_ring_center(), slack)


func _on_ring_landed(_position: Vector3) -> void:
	if _state == State.THROWING and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		_set_state(State.DEPLOYED)
	elif _state == State.THROWING:
		_try_capture_or_retract()


func _on_lasso_target_entered(_target: Node3D) -> void:
	pass


func _on_tighten_finished() -> void:
	if _state != State.TIGHTENING:
		return
	if _captured_target == null or not is_instance_valid(_captured_target):
		_begin_retract()
		return
	var taut_length := LassoTargetUtils.compute_taut_rope_length(_owner, _captured_target)
	LassoTargetUtils.begin_capture(_captured_target, _owner, taut_length, _ring)
	_set_state(State.DRAGGING)


func _on_retract_finished() -> void:
	_set_state(State.IDLE)
	if _ring != null and is_instance_valid(_ring):
		_disconnect_ring_signals()
		_ring.queue_free()
		_ring = null


func _disconnect_ring_signals() -> void:
	if _ring == null or not is_instance_valid(_ring):
		return
	if _ring.retract_finished.is_connected(_on_retract_finished):
		_ring.retract_finished.disconnect(_on_retract_finished)
	if _ring.tighten_finished.is_connected(_on_tighten_finished):
		_ring.tighten_finished.disconnect(_on_tighten_finished)
	if _ring.landed.is_connected(_on_ring_landed):
		_ring.landed.disconnect(_on_ring_landed)
	if _ring.lasso_target_entered.is_connected(_on_lasso_target_entered):
		_ring.lasso_target_entered.disconnect(_on_lasso_target_entered)


func _set_state(new_state: State) -> void:
	if _state == new_state:
		return
	_state = new_state
	state_changed.emit(new_state)

	if new_state == State.IDLE:
		if _rope != null and is_instance_valid(_rope):
			_rope.visible = false
