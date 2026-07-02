class_name StairRampCollision
extends RefCounted

## Invisible ramp collider over stair meshes — the standard third-person approach.
## Visual steps stay decorative; one rotated box handles walking physics.
## When a flat landing sits above the top, trim the ramp (top_trim) so the deck
## collider owns the lip and the ramp end-cap does not block walk-down re-entry.

const COVER_COLLISION := preload("res://gameplay/world/cover_collision.gd")
const COLLISION_ROOT_NAME := "StairRampCollision"
const RAMP_SHAPE_NAME := "RampShape"
const RAMP_THICKNESS := 0.25

## StairsXL mesh bounds: 6.4 m wide on X, 2.8 m run on Z (+Z low -> -Z high), 2.2 m rise.
const STAIRS_XL_BOUNDS := {
	"width_min": -3.2,
	"width_max": 3.2,
	"climb_bottom_z": 1.4,
	"climb_top_z": -1.4,
	"floor_y": 0.0,
	"rise": 2.2,
	"climb_overlap": 0.1,
}

const DEFAULT_CLIMB_OVERLAP := 0.08


static func is_stair_node(node: Node) -> bool:
	if node == null:
		return false
	var name_lower := String(node.name).to_lower()
	return name_lower.contains("stair")


static func apply_to(root: Node3D, config: Dictionary = {}) -> bool:
	if root == null:
		return false
	if root.is_in_group(&"stair_ramp"):
		return true
	if root.get_node_or_null(COLLISION_ROOT_NAME) != null:
		return true
	if root.get_node_or_null(RAMP_SHAPE_NAME) != null:
		return true

	var meshes := COVER_COLLISION.collect_visible_meshes(root)
	if meshes.is_empty():
		push_warning("StairRampCollision: no visible meshes under %s." % root.name)
		return false

	var bounds := _resolve_bounds(root, meshes, config)
	var ramp := _build_ramp_box(bounds)
	if ramp == null:
		return false

	if root is StaticBody3D:
		_clear_collision_shapes(root)
		root.collision_layer = 1
		root.add_child(ramp)
	else:
		var collision_root := Node3D.new()
		collision_root.name = COLLISION_ROOT_NAME
		root.add_child(collision_root)

		var body := StaticBody3D.new()
		body.name = "RampBody"
		body.collision_layer = 1
		collision_root.add_child(body)
		body.add_child(ramp)

	root.add_to_group(&"stair_ramp")
	return true


static func _resolve_bounds(root: Node3D, meshes: Array[MeshInstance3D], config: Dictionary) -> Dictionary:
	if _is_stairs_xl(root, meshes):
		return _bounds_from_preset(STAIRS_XL_BOUNDS, config)

	return _bounds_from_mesh_aabb(_combined_mesh_aabb_local(root, meshes), config)


static func _is_stairs_xl(root: Node3D, meshes: Array[MeshInstance3D]) -> bool:
	if String(root.name).to_lower().contains("stairsxl"):
		return true

	for mesh_inst in meshes:
		if mesh_inst.mesh == null:
			continue
		var mesh_name := String(mesh_inst.mesh.resource_name).to_lower()
		if mesh_name.contains("stairsxl"):
			return true

	var aabb := _combined_mesh_aabb_local(root, meshes)
	return (
		is_equal_approx(aabb.size.x, 6.4)
		and is_equal_approx(aabb.size.y, 2.2)
		and is_equal_approx(aabb.size.z, 2.8)
	)


static func _bounds_from_preset(preset: Dictionary, config: Dictionary) -> Dictionary:
	var default_overlap := float(
		config.get("run_end_overlap", preset.get("climb_overlap", DEFAULT_CLIMB_OVERLAP))
	)
	return {
		"width_min": float(preset.width_min),
		"width_max": float(preset.width_max),
		"climb_bottom_z": float(preset.climb_bottom_z),
		"climb_top_z": float(preset.climb_top_z),
		"floor_y": float(preset.floor_y),
		"rise": float(preset.rise),
		"bottom_overlap": float(config.get("bottom_overlap", default_overlap)),
		"top_overlap": float(config.get("top_overlap", default_overlap)),
		"top_trim": float(config.get("top_trim", 0.0)),
	}


static func _bounds_from_mesh_aabb(aabb: AABB, config: Dictionary) -> Dictionary:
	var default_overlap := float(config.get("run_end_overlap", DEFAULT_CLIMB_OVERLAP))
	return {
		"width_min": aabb.position.x,
		"width_max": aabb.end.x,
		"climb_bottom_z": aabb.end.z,
		"climb_top_z": aabb.position.z,
		"floor_y": aabb.position.y,
		"rise": maxf(aabb.size.y, 0.05),
		"bottom_overlap": float(config.get("bottom_overlap", default_overlap)),
		"top_overlap": float(config.get("top_overlap", default_overlap)),
		"top_trim": float(config.get("top_trim", 0.0)),
	}


static func _build_ramp_box(bounds: Dictionary) -> CollisionShape3D:
	var center_x: float = (bounds.width_min + bounds.width_max) * 0.5
	var bottom := Vector3(center_x, bounds.floor_y, bounds.climb_bottom_z)
	var top := Vector3(center_x, bounds.floor_y + bounds.rise, bounds.climb_top_z)

	var climb := top - bottom
	var slope_len := climb.length()
	if slope_len < 0.05:
		return null

	var climb_axis := climb / slope_len
	var top_trim: float = float(bounds.get("top_trim", 0.0))
	if top_trim > 0.0:
		top -= climb_axis * minf(top_trim, slope_len - 0.05)
		climb = top - bottom
		slope_len = climb.length()
		if slope_len < 0.05:
			return null
		climb_axis = climb / slope_len

	var bottom_overlap: float = float(bounds.get("bottom_overlap", bounds.get("climb_overlap", 0.0)))
	var top_overlap: float = float(bounds.get("top_overlap", bounds.get("climb_overlap", 0.0)))
	if bottom_overlap > 0.0:
		bottom -= climb_axis * bottom_overlap
	if top_overlap > 0.0:
		top += climb_axis * top_overlap
	climb = top - bottom
	slope_len = climb.length()
	if slope_len < 0.05:
		return null

	var mid := (bottom + top) * 0.5
	var z_axis := climb / slope_len
	var x_axis := Vector3.RIGHT
	var y_axis := x_axis.cross(z_axis).normalized()
	if y_axis.length_squared() < 0.0001:
		y_axis = Vector3.UP
	x_axis = y_axis.cross(z_axis).normalized()

	var width: float = maxf(bounds.width_max - bounds.width_min, 0.05)
	var shape := BoxShape3D.new()
	shape.size = Vector3(width, RAMP_THICKNESS, slope_len)

	var collision := CollisionShape3D.new()
	collision.name = RAMP_SHAPE_NAME
	collision.shape = shape
	collision.transform = Transform3D(Basis(x_axis, y_axis, z_axis), mid)
	return collision


static func _clear_collision_shapes(body: StaticBody3D) -> void:
	for child in body.get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			body.remove_child(child)
			child.free()


static func _combined_mesh_aabb_local(root: Node3D, meshes: Array[MeshInstance3D]) -> AABB:
	var combined := AABB()
	var first := true
	var to_root := root.global_transform.affine_inverse()

	for mesh_inst in meshes:
		if mesh_inst.mesh == null:
			continue
		var mesh_to_root := to_root * mesh_inst.global_transform
		for corner in _aabb_corners(mesh_inst.mesh.get_aabb()):
			var local_point := mesh_to_root * corner
			if first:
				combined = AABB(local_point, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(local_point)

	return combined


static func _aabb_corners(aabb: AABB) -> Array[Vector3]:
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
