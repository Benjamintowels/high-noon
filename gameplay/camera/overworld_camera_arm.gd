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

const WORLD_COLLISION_LAYER := 1
const CAMERA_RAY_EXCLUDE_GROUP := &"camera_ray_exclude"
const PROP_COLLISION_ROOT_NAME := &"PropCollision"
const MAX_RAY_PASSES := 32

@export_flags_3d_physics var collision_mask: int = WORLD_COLLISION_LAYER

var _camera: Camera3D
var _occlusion_blend: float = 0.0
var _distance_ratio: float = 1.0
var _owner_rid: RID
var _extra_exclude: Array[RID] = []
## Colliders identified as camera-transparent (prop cover, NPC bodies) get
## remembered here so each one costs a script-tree walk only once, instead of
## restarting the multi-pass ignore loop every frame. Stale RIDs of freed
## bodies simply never match again; the cap guards unbounded growth.
var _learned_ignore_rids: Dictionary = {}
var _learned_ignore_list: Array[RID] = []

const MAX_LEARNED_IGNORES := 512


func _ready() -> void:
	_camera = get_node_or_null("Camera3D") as Camera3D


func _physics_process(delta: float) -> void:
	update_occlusion_reframe(delta)


func bind_owner(body: CollisionObject3D) -> void:
	if body == null:
		return
	_owner_rid = body.get_rid()
	call_deferred("_refresh_extra_excludes")


func _refresh_extra_excludes() -> void:
	_extra_exclude.clear()
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(CAMERA_RAY_EXCLUDE_GROUP):
		if node is CollisionObject3D:
			_extra_exclude.append((node as CollisionObject3D).get_rid())


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
	var exclude: Array[RID] = []
	if _owner_rid.is_valid():
		exclude.append(_owner_rid)
	if not _extra_exclude.is_empty():
		exclude.append_array(_extra_exclude)
	if not _learned_ignore_list.is_empty():
		exclude.append_array(_learned_ignore_list)

	for _pass in MAX_RAY_PASSES:
		var query := PhysicsRayQueryParameters3D.create(from, to)
		query.collision_mask = collision_mask
		query.hit_from_inside = true
		if not exclude.is_empty():
			query.exclude = exclude

		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			_distance_ratio = 1.0
			return desired

		var collider: Object = hit.get("collider")
		if _should_ignore_camera_hit(collider):
			if collider is CollisionObject3D:
				var rid := (collider as CollisionObject3D).get_rid()
				exclude.append(rid)
				_remember_ignored_rid(rid)
			continue

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

	_distance_ratio = 1.0
	return desired


func _remember_ignored_rid(rid: RID) -> void:
	if _learned_ignore_rids.has(rid):
		return
	if _learned_ignore_list.size() >= MAX_LEARNED_IGNORES:
		_learned_ignore_rids.clear()
		_learned_ignore_list.clear()
	_learned_ignore_rids[rid] = true
	_learned_ignore_list.append(rid)


func _should_ignore_camera_hit(collider: Object) -> bool:
	if collider == null:
		return true
	if collider is CharacterBody3D or collider is RigidBody3D:
		return true
	if collider is CollisionObject3D:
		var collision_object := collider as CollisionObject3D
		if collision_object.is_in_group(CAMERA_RAY_EXCLUDE_GROUP):
			return true
	if collider is Node:
		var node := collider as Node
		if _is_under_prop_collision(node):
			return true
		if _is_npc_collision_node(node):
			return true
	return false


func _is_under_prop_collision(node: Node) -> bool:
	var current := node
	while current != null:
		if current.name == PROP_COLLISION_ROOT_NAME:
			return true
		current = current.get_parent()
	return false


func _is_npc_collision_node(node: Node) -> bool:
	var current := node
	while current != null:
		var script := current.get_script() as Script
		if script != null:
			var script_path := script.resource_path
			if script_path.contains("_npc") or script_path.ends_with("duelist.gd"):
				return true
		current = current.get_parent()
	return false


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
