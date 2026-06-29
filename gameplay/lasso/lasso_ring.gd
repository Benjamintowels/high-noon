extends Area3D
class_name LassoRing

const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")

signal landed(global_position: Vector3)
signal retract_finished
signal tighten_finished
signal lasso_target_entered(target: Node3D)

const RING_RADIUS := 0.52
const RING_THICKNESS := 0.08
const RETRACT_ARC_HEIGHT := 1.1
const PHYSICS_RING_MASS := 0.65
const ATTACH_SPRING := 52.0
const ATTACH_SPRING_Y := 88.0
const ROPE_TENSION_SPRING := 68.0
const LEADER_PULL_SCALE := 0.55
const RING_LINEAR_DAMP := 2.4
const RING_ANGULAR_DAMP := 5.0

var _flight_active := false
var _flight_timer := 0.0
var _flight_duration := 0.45
var _flight_start := Vector3.ZERO
var _flight_end := Vector3.ZERO
var _flight_peak := 1.2
var _retract_active := false
var _retract_timer := 0.0
var _retract_duration := 0.35
var _retract_start := Vector3.ZERO
var _retract_target := Vector3.ZERO
var _tighten_active := false
var _tighten_timer := 0.0
var _tighten_duration := 0.4
var _tighten_start := Vector3.ZERO
var _tighten_target := Vector3.ZERO
var _follow_target: Node3D
var _pending_target: Node3D
var _loose_attach := false
var _deployed := false
var _open := true
var _physics_drag_active := false
var _physics_rope_length := 8.5
var _get_leader_anchor: Callable
var _get_target_attach: Callable
var _physics_body: RigidBody3D

@onready var _visual: Node3D = $Visual


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = true
	monitoring = true
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	_set_open(true)


func is_deployed() -> bool:
	return _deployed


func is_open() -> bool:
	return _open


func get_pending_target() -> Node3D:
	if _follow_target != null and is_instance_valid(_follow_target) and _loose_attach:
		return _follow_target
	if _pending_target != null and is_instance_valid(_pending_target):
		return _pending_target
	return null


func is_loosely_attached() -> bool:
	return _loose_attach and _follow_target != null and is_instance_valid(_follow_target)


func set_pending_target(target: Node3D) -> void:
	if target != null and LassoTargetUtils.is_lassoable(target):
		_pending_target = target


func clear_pending_target() -> void:
	_pending_target = null


func find_target_at(position: Vector3) -> Node3D:
	return LassoTargetUtils.find_lasso_target_at(get_world_3d(), position)


func launch(from: Vector3, to: Vector3, duration: float) -> void:
	_flight_active = true
	_flight_timer = 0.0
	_flight_duration = maxf(duration, 0.05)
	_flight_start = from
	_flight_end = to
	_deployed = false
	_retract_active = false
	_tighten_active = false
	_follow_target = null
	_pending_target = null
	_loose_attach = false
	_set_open(true)

	var span := _flight_start.distance_to(_flight_end)
	_flight_peak = clampf(span * 0.22, 0.65, 3.2)
	global_position = from
	visible = true
	set_physics_process(true)


func begin_retract(target: Vector3, duration: float) -> void:
	_retract_active = true
	_retract_timer = 0.0
	_retract_duration = maxf(duration, 0.05)
	_retract_start = global_position
	_retract_target = target
	_flight_active = false
	_tighten_active = false
	_follow_target = null
	_deployed = false
	_loose_attach = false
	_set_open(false)
	set_physics_process(true)


func attach_loose_to(target: Node3D) -> void:
	if target == null or not is_instance_valid(target):
		return
	_follow_target = target
	_pending_target = target
	_loose_attach = true
	_flight_active = false
	_retract_active = false
	_tighten_active = false
	_deployed = true
	_set_open(true)
	_scale_ring(1.0)
	global_position = LassoTargetUtils.get_loose_attach_point(target)
	_align_ring_to_ground()
	visible = true
	set_physics_process(true)


func begin_tighten_on(target: Node3D, duration: float) -> void:
	if target == null or not is_instance_valid(target):
		return
	_tighten_active = true
	_tighten_timer = 0.0
	_tighten_duration = maxf(duration, 0.05)
	_tighten_start = global_position
	_tighten_target = LassoTargetUtils.get_attach_point(target)
	_follow_target = target
	_loose_attach = false
	_flight_active = false
	_retract_active = false
	_deployed = false
	_set_open(false)
	monitoring = false
	set_physics_process(true)


func is_physics_drag_active() -> bool:
	return _physics_drag_active and _physics_body != null and is_instance_valid(_physics_body)


func begin_physics_drag(
	leader_anchor_cb: Callable,
	target_attach_cb: Callable,
	rope_length: float,
	start_position: Vector3
) -> void:
	_get_leader_anchor = leader_anchor_cb
	_get_target_attach = target_attach_cb
	_physics_rope_length = rope_length
	_physics_drag_active = true
	_flight_active = false
	_retract_active = false
	_tighten_active = false
	_loose_attach = false
	_follow_target = null
	_set_open(false)
	_ensure_physics_body()
	_physics_body.global_position = start_position
	_physics_body.linear_velocity = Vector3.ZERO
	_physics_body.angular_velocity = Vector3.ZERO
	_physics_body.sleeping = false
	visible = true
	set_physics_process(true)


func end_physics_drag(target: Node3D) -> void:
	_physics_drag_active = false
	_get_leader_anchor = Callable()
	_get_target_attach = Callable()
	if _physics_body != null and is_instance_valid(_physics_body):
		global_position = _physics_body.global_position
		_physics_body.linear_velocity = Vector3.ZERO
		_physics_body.angular_velocity = Vector3.ZERO
		_restore_visual_to_area()
	_follow_target = target
	_loose_attach = false
	_tighten_active = false
	_retract_active = false
	_flight_active = false
	if target != null and is_instance_valid(target):
		global_position = LassoTargetUtils.get_attach_point(target)
		_scale_ring(0.55)
		visible = true
		set_physics_process(true)


func update_physics_drag(_delta: float) -> void:
	pass


func follow_target(target: Node3D) -> void:
	_physics_drag_active = false
	_follow_target = target
	_loose_attach = false
	_tighten_active = false
	_retract_active = false
	_flight_active = false
	if target != null and is_instance_valid(target):
		global_position = LassoTargetUtils.get_attach_point(target)
		_scale_ring(0.55)
		visible = true
		set_physics_process(true)


func set_retract_target(target: Vector3) -> void:
	if _retract_active:
		_retract_target = target


func snap_closed() -> void:
	var was_retracting := _retract_active
	_physics_drag_active = false
	_get_leader_anchor = Callable()
	_get_target_attach = Callable()
	if _physics_body != null and is_instance_valid(_physics_body):
		_restore_visual_to_area()
	_flight_active = false
	_retract_active = false
	_tighten_active = false
	_follow_target = null
	_pending_target = null
	_loose_attach = false
	_deployed = false
	visible = false
	set_physics_process(false)
	if was_retracting:
		retract_finished.emit()


func get_ring_center() -> Vector3:
	if is_physics_drag_active():
		return _physics_body.global_position
	if _follow_target != null and is_instance_valid(_follow_target):
		if _loose_attach:
			return LassoTargetUtils.get_loose_attach_point(_follow_target)
		return LassoTargetUtils.get_attach_point(_follow_target)
	return global_position


func get_physics_velocity() -> Vector3:
	if is_physics_drag_active() and _physics_body != null:
		return _physics_body.linear_velocity
	return Vector3.ZERO


func _physics_process(delta: float) -> void:
	if _physics_drag_active:
		_apply_physics_drag_forces()
		if _physics_body != null and is_instance_valid(_physics_body):
			global_position = _physics_body.global_position
		return

	if _flight_active:
		_process_flight(delta)
		return

	if _tighten_active:
		_process_tighten(delta)
		return

	if _retract_active:
		_process_retract(delta)
		return

	if _follow_target != null and is_instance_valid(_follow_target):
		if _loose_attach:
			global_position = LassoTargetUtils.get_loose_attach_point(_follow_target)
		else:
			global_position = LassoTargetUtils.get_attach_point(_follow_target)
		_align_ring_to_ground()


func _process_flight(delta: float) -> void:
	_flight_timer += delta
	var t := clampf(_flight_timer / _flight_duration, 0.0, 1.0)
	var pos := _flight_start.lerp(_flight_end, t)
	pos.y = lerpf(_flight_start.y, _flight_end.y, t) + sin(t * PI) * _flight_peak
	global_position = pos
	_align_ring_to_ground()

	if t >= 1.0:
		_flight_active = false
		_deployed = true
		global_position = _flight_end
		_align_ring_to_ground()
		var landed_target := find_target_at(global_position)
		if landed_target != null:
			attach_loose_to(landed_target)
		landed.emit(global_position)


func _process_tighten(delta: float) -> void:
	if _follow_target == null or not is_instance_valid(_follow_target):
		_tighten_active = false
		tighten_finished.emit()
		return

	_tighten_target = LassoTargetUtils.get_attach_point(_follow_target)
	_tighten_timer += delta
	var t := clampf(_tighten_timer / _tighten_duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	global_position = _tighten_start.lerp(_tighten_target, eased)
	_align_ring_to_ground()
	_scale_ring(lerpf(1.0, 0.55, eased))

	if t >= 1.0:
		_tighten_active = false
		global_position = _tighten_target
		_scale_ring(0.55)
		tighten_finished.emit()


func _process_retract(delta: float) -> void:
	_retract_timer += delta
	var t := clampf(_retract_timer / _retract_duration, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	var pos := _retract_start.lerp(_retract_target, eased)
	pos.y += sin(t * PI) * RETRACT_ARC_HEIGHT
	global_position = pos
	_align_ring_to_ground()
	_scale_ring(lerpf(1.0, 0.2, eased))
	if t >= 1.0:
		snap_closed()


func _align_ring_to_ground() -> void:
	rotation = Vector3.ZERO
	_visual.rotation.x = PI * 0.5


func _scale_ring(scale_factor: float) -> void:
	_visual.scale = Vector3.ONE * scale_factor


func _set_open(open: bool) -> void:
	_open = open
	monitoring = open and _deployed and not _loose_attach


func _on_body_entered(body: Node3D) -> void:
	_notify_lasso_target(body)


func _on_area_entered(area: Area3D) -> void:
	var owner_node := area.get_parent()
	if owner_node is Node3D:
		_notify_lasso_target(owner_node as Node3D)


func _notify_lasso_target(target: Node3D) -> void:
	if not _deployed or not _open:
		return
	if not LassoTargetUtils.is_lassoable(target):
		return
	set_pending_target(target)
	if _deployed and _open and not _loose_attach:
		attach_loose_to(target)
	lasso_target_entered.emit(target)


func _ensure_physics_body() -> void:
	if _physics_body != null and is_instance_valid(_physics_body):
		return

	_physics_body = RigidBody3D.new()
	_physics_body.name = "PhysicsRing"
	_physics_body.mass = PHYSICS_RING_MASS
	_physics_body.linear_damp = RING_LINEAR_DAMP
	_physics_body.angular_damp = RING_ANGULAR_DAMP
	_physics_body.gravity_scale = 0.0
	_physics_body.collision_layer = 0
	_physics_body.collision_mask = 1
	_physics_body.continuous_cd = true
	add_child(_physics_body)

	var shape := SphereShape3D.new()
	shape.radius = RING_RADIUS * 0.55
	var collision := CollisionShape3D.new()
	collision.shape = shape
	_physics_body.add_child(collision)

	if _visual.get_parent() != _physics_body:
		var visual_global := _visual.global_transform
		_visual.reparent(_physics_body, true)
		_visual.global_transform = visual_global
	_align_ring_to_ground()


func _restore_visual_to_area() -> void:
	if _visual == null or not is_instance_valid(_visual):
		return
	if _visual.get_parent() == self:
		return
	var visual_global := _visual.global_transform
	_visual.reparent(self, true)
	_visual.global_transform = visual_global
	_align_ring_to_ground()


func _apply_physics_drag_forces() -> void:
	if _physics_body == null or not is_instance_valid(_physics_body):
		return
	if not _get_leader_anchor.is_valid() or not _get_target_attach.is_valid():
		return

	var leader_anchor: Vector3 = _get_leader_anchor.call()
	var target_attach: Vector3 = _get_target_attach.call()
	var ring_pos := _physics_body.global_position

	var to_attach := target_attach - ring_pos
	_physics_body.apply_central_force(
		Vector3(to_attach.x, 0.0, to_attach.z) * ATTACH_SPRING
		+ Vector3(0.0, to_attach.y, 0.0) * ATTACH_SPRING_Y
	)

	var to_leader := leader_anchor - ring_pos
	to_leader.y = 0.0
	var leader_dist := to_leader.length()
	if leader_dist > _physics_rope_length:
		var tension_dir := to_leader / maxf(leader_dist, 0.001)
		var stretch := leader_dist - _physics_rope_length
		_physics_body.apply_central_force(tension_dir * stretch * ROPE_TENSION_SPRING)

	var leader_vel := Vector3.ZERO
	if _get_leader_anchor.get_object() != null:
		var leader_obj: Object = _get_leader_anchor.get_object()
		if leader_obj is Node3D and leader_obj.has_method("get_lasso_leader_velocity"):
			leader_vel = leader_obj.call("get_lasso_leader_velocity") as Vector3
	_physics_body.apply_central_force(Vector3(leader_vel.x, 0.0, leader_vel.z) * LEADER_PULL_SCALE)

	var floor_y := _sample_floor_y(ring_pos)
	var target_y := maxf(target_attach.y, floor_y + 0.12)
	if ring_pos.y < target_y:
		_physics_body.apply_central_force(Vector3.UP * (target_y - ring_pos.y) * 140.0)
	elif ring_pos.y > target_y + 0.35:
		_physics_body.apply_central_force(Vector3.DOWN * (ring_pos.y - target_y - 0.35) * 90.0)

	var vel := _physics_body.linear_velocity
	vel.y = lerpf(vel.y, 0.0, 0.35)
	_physics_body.linear_velocity = vel


func _sample_floor_y(point: Vector3) -> float:
	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		return point.y
	var ray_from := point + Vector3(0.0, 4.0, 0.0)
	var ray_to := point + Vector3(0.0, -8.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(ray_from, ray_to)
	query.collide_with_areas = false
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return point.y
	return hit.position.y + 0.05
