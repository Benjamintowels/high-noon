class_name CoverCollision
extends RefCounted

const FENCE_SURFACE_SCRIPT := preload("res://gameplay/targets/fence_surface.gd")
const COLLISION_ROOT_NAME := "CoverCollision"


static func apply_to(cover_root: Node3D) -> bool:
	if cover_root == null:
		return false
	if cover_root.get_node_or_null(COLLISION_ROOT_NAME) != null:
		return true

	var meshes := collect_visible_meshes(cover_root)
	if meshes.is_empty():
		push_warning("CoverCollision: no visible meshes under %s." % cover_root.name)
		return false

	_generate_collision_for(cover_root, meshes)
	return true


static func collect_visible_meshes(root: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	for child in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := child as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		if _is_node_visible(mesh_inst):
			meshes.append(mesh_inst)
	return meshes


static func _generate_collision_for(root: Node3D, meshes: Array[MeshInstance3D]) -> void:
	var collision_root := Node3D.new()
	collision_root.name = COLLISION_ROOT_NAME
	root.add_child(collision_root)

	for mesh_inst in meshes:
		_add_trimesh_body(collision_root, mesh_inst)


static func _add_trimesh_body(collision_root: Node3D, mesh_inst: MeshInstance3D) -> void:
	var mesh := mesh_inst.mesh
	if mesh == null:
		return

	var shape := mesh.create_trimesh_shape()
	if shape == null:
		push_warning("CoverCollision: failed to build trimesh for %s." % mesh_inst.name)
		return

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.set_script(FENCE_SURFACE_SCRIPT)
	body.set("surface_kind", ImpactFX.SurfaceKind.WOOD)
	collision_root.add_child(body)
	body.global_transform = mesh_inst.global_transform

	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


static func _is_node_visible(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is CanvasItem and not (current as CanvasItem).visible:
			return false
		if current is Node3D and not (current as Node3D).visible:
			return false
		current = current.get_parent()
	return true
