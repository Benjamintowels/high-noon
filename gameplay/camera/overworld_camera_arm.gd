extends Node3D
class_name OverworldCameraArm

## Third-person camera arm with wall collision and vertical reframe when occluded.
## Keeps the classic local camera offset (x, y, z) and shortens it only for walls.
## When looking up, floor hits also shorten the arm (same reframe as walls).

@export var shape_radius: float = 0.28
@export var collision_margin: float = 0.2
@export var max_arm_lift: float = 1.35
@export var occlusion_ratio_threshold: float = 0.68
@export var max_occlusion_pitch: float = deg_to_rad(32.0)
@export var reframe_smooth: float = 11.0
@export var floor_normal_y_threshold: float = 0.72
@export var look_up_pitch_threshold: float = deg_to_rad(12.0)
@export_flags_3d_physics var collision_mask: int = 0xFFFFFFFF

var _camera: Camera3D
var _occlusion_blend: float = 0.0
var _distance_ratio: float = 1.0
var _owner_rid: RID


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D


func _physics_process(delta: float) -> void:
	update_occlusion_reframe(delta)


func bind_owner(body: CollisionObject3D) -> void:
	if body == null:
		return
	_owner_rid = body.get_rid()


func apply_desired_offset(offset: Vector3, extra: Vector3 = Vector3.ZERO) -> void:
	if _camera == null:
		return
	_camera.position = _clip_local_offset(offset + extra)


func _clip_local_offset(desired: Vector3) -> Vector3:
	var desired_length := desired.length()
	if desired_length <= 0.001:
		_distance_ratio = 1.0
		return desired

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		_distance_ratio = 1.0
		return desired

	var from := global_transform.origin
	var to := from + global_transform.basis * desired
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = collision_mask
	query.hit_from_inside = true
	if _owner_rid.is_valid():
		query.exclude = [_owner_rid]

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		_distance_ratio = 1.0
		return desired

	var hit_normal: Vector3 = hit.get("normal", Vector3.ZERO)
	var is_floor: bool = hit_normal.y > floor_normal_y_threshold
	var looking_up: bool = rotation.x > look_up_pitch_threshold
	if is_floor and not looking_up:
		_distance_ratio = 1.0
		return desired

	var safe_length := maxf(
		from.distance_to(hit.position) - collision_margin - shape_radius,
		0.08
	)
	_distance_ratio = clampf(safe_length / desired_length, 0.0, 1.0)
	return desired * _distance_ratio


func update_occlusion_reframe(delta: float) -> void:
	var target_blend := 0.0
	if _distance_ratio < occlusion_ratio_threshold:
		target_blend = 1.0 - (_distance_ratio / occlusion_ratio_threshold)

	var step := 1.0 - exp(-reframe_smooth * delta)
	_occlusion_blend = lerpf(_occlusion_blend, target_blend, step)
	position.y = max_arm_lift * _occlusion_blend


func get_occlusion_pitch() -> float:
	return -max_occlusion_pitch * _occlusion_blend


func get_occlusion_blend() -> float:
	return _occlusion_blend
