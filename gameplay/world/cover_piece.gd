extends Node3D
class_name CoverPiece

## Attach to any wood prop root (e.g. Box.tscn). Space near the prop enters crouch cover.
## Collision is built automatically from visible meshes on the parent node.

const COVER_COLLISION := preload("res://gameplay/world/cover_collision.gd")

@export var cover_radius := 3.5
@export var cover_hold_slack := 0.2
@export var edge_standoff := 0.65
@export var cover_half_extents := Vector3(0.55, 0.45, 0.55)

var _cover_center_local := Vector3.ZERO
var _collision_bodies: Array[StaticBody3D] = []
var _collision_layers: Array[int] = []


func _ready() -> void:
	add_to_group("cover_piece")
	call_deferred("_setup_cover")


func _setup_cover() -> void:
	var root := get_parent() as Node3D
	if root == null:
		push_error("CoverPiece: parent must be the cover prop root (e.g. Box).")
		return

	_refresh_cover_bounds()
	COVER_COLLISION.apply_to(root)
	_cache_collision_bodies()
	if _collision_bodies.is_empty():
		push_warning("CoverPiece: no collision bodies on %s." % root.name)
	else:
		_ensure_collision_enabled()


func get_cover_anchor() -> Vector3:
	return global_position


func is_player_in_range(player: Node3D) -> bool:
	if player == null:
		return false
	var offset := player.global_position - get_cover_anchor()
	offset.y = 0.0
	return offset.length_squared() <= cover_radius * cover_radius


func is_player_holding_cover(player: Node3D, hold_position: Vector3) -> bool:
	if player == null:
		return false
	var offset := player.global_position - hold_position
	offset.y = 0.0
	return offset.length_squared() <= cover_hold_slack * cover_hold_slack


func get_crouch_spot(player: Node3D, far_side: bool) -> Dictionary:
	var root := get_parent() as Node3D
	if root == null or player == null:
		return {
			"position": global_position,
			"facing_yaw": 0.0,
			"outward": Vector3.FORWARD,
		}

	var inv := root.global_transform.affine_inverse()
	var local_player := inv * player.global_position
	var axis := _get_local_approach_axis(local_player)
	if far_side:
		axis = -axis

	var local_face := _cover_center_local + Vector3(
		axis.x * cover_half_extents.x,
		0.0,
		axis.z * cover_half_extents.z
	)
	if absf(axis.x) > 0.5:
		local_face.z = clampf(
			local_player.z,
			_cover_center_local.z - cover_half_extents.z,
			_cover_center_local.z + cover_half_extents.z
		)
	else:
		local_face.x = clampf(
			local_player.x,
			_cover_center_local.x - cover_half_extents.x,
			_cover_center_local.x + cover_half_extents.x
		)

	var world_face := root.global_transform * local_face
	var world_outward := root.global_transform.basis * axis
	world_outward.y = 0.0
	if world_outward.length_squared() < 0.0001:
		world_outward = Vector3.FORWARD
	else:
		world_outward = world_outward.normalized()

	var spot := world_face + world_outward * edge_standoff
	spot.y = player.global_position.y

	return {
		"position": spot,
		"facing_yaw": atan2(-world_outward.x, -world_outward.z),
		"outward": world_outward,
	}


func set_collision_enabled(enabled: bool) -> void:
	for i in range(_collision_bodies.size()):
		var body := _collision_bodies[i]
		if not is_instance_valid(body):
			continue
		if enabled:
			var layer := 1
			if i < _collision_layers.size() and _collision_layers[i] != 0:
				layer = _collision_layers[i]
			body.collision_layer = layer
		else:
			body.collision_layer = 0


func _ensure_collision_enabled() -> void:
	set_collision_enabled(true)


func _refresh_cover_bounds() -> void:
	var root := get_parent() as Node3D
	if root == null:
		return

	var combined := AABB()
	var first := true
	for mesh_inst in COVER_COLLISION.collect_visible_meshes(root):
		var mesh_aabb := mesh_inst.mesh.get_aabb()
		var to_root := root.global_transform.affine_inverse() * mesh_inst.global_transform
		for corner in _aabb_corners(mesh_aabb):
			var local_point := to_root * corner
			if first:
				combined = AABB(local_point, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(local_point)

	if first:
		return

	_cover_center_local = combined.get_center()
	cover_half_extents = combined.size * 0.5
	cover_half_extents.y = maxf(cover_half_extents.y, 0.35)


func _cache_collision_bodies() -> void:
	_collision_bodies.clear()
	_collision_layers.clear()
	var root := get_parent()
	if root == null:
		return
	_collect_static_bodies(root, _collision_bodies)
	for body in _collision_bodies:
		_collision_layers.append(body.collision_layer)


func _collect_static_bodies(node: Node, out: Array[StaticBody3D]) -> void:
	if node is StaticBody3D:
		out.append(node as StaticBody3D)
	for child in node.get_children():
		_collect_static_bodies(child, out)


func _get_local_approach_axis(local_player: Vector3) -> Vector3:
	var from_center := local_player - _cover_center_local
	from_center.y = 0.0
	if from_center.length_squared() < 0.0001:
		return Vector3(0.0, 0.0, 1.0)

	var x_dist := absf(from_center.x) / maxf(cover_half_extents.x, 0.01)
	var z_dist := absf(from_center.z) / maxf(cover_half_extents.z, 0.01)
	if x_dist >= z_dist:
		return Vector3(signf(from_center.x), 0.0, 0.0)
	return Vector3(0.0, 0.0, signf(from_center.z))


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.end,
	]
