class_name TerrainCollision
extends RefCounted

const COLLISION_ROOT_NAME := "TerrainCollision"


static func apply_to(root: Node) -> void:
	if root == null or not root is Node3D:
		return
	if root.get_node_or_null(COLLISION_ROOT_NAME) != null:
		return

	var meshes := _collect_meshes(root as Node3D)
	if meshes.is_empty():
		return

	var collision_root := Node3D.new()
	collision_root.name = COLLISION_ROOT_NAME
	root.add_child(collision_root)

	for mesh_inst in meshes:
		_add_trimesh_body(collision_root, mesh_inst)


static func _collect_meshes(root: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes_recursive(root, meshes)
	return meshes


static func _collect_meshes_recursive(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node.name == COLLISION_ROOT_NAME:
		return
	if node is StaticBody3D or node is CharacterBody3D or node is Area3D:
		return
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh != null:
			meshes.append(mesh_inst)
	for child in node.get_children():
		_collect_meshes_recursive(child, meshes)


static func _add_trimesh_body(collision_root: Node3D, mesh_inst: MeshInstance3D) -> void:
	var mesh := mesh_inst.mesh
	if mesh == null:
		return

	var shape := mesh.create_trimesh_shape()
	if shape == null:
		return

	var body := StaticBody3D.new()
	body.name = "GroundBody"
	collision_root.add_child(body)
	body.global_transform = mesh_inst.global_transform

	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)
