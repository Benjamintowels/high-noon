class_name WoodPropCollision
extends RefCounted

const FENCE_SURFACE_SCRIPT := preload("res://gameplay/targets/fence_surface.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const COLLISION_ROOT_NAME := "PropCollision"

const SKIP_NODE_NAMES := {
	"Floor": true,
	"Ceiling": true,
	"WallNorth": true,
	"WallSouth": true,
	"WallWest": true,
	"WallEastNorth": true,
	"WallEastSouth": true,
	"InteriorLight": true,
	"InteriorSpawn": true,
	"ExitDoor": true,
	"ShopKeep": true,
	"Items": true,
	"Items2": true,
	"Items3": true,
	"Items4": true,
}


static func apply_to(root: Node) -> void:
	if root == null:
		return
	_process_node(root)


static func _process_node(node: Node) -> void:
	if node.name == COLLISION_ROOT_NAME:
		return

	if _should_skip(node):
		return

	if node is Node3D and node.get_node_or_null(COLLISION_ROOT_NAME) == null:
		var meshes := _collect_visible_meshes(node as Node3D)
		if not meshes.is_empty():
			_generate_collision_for(node as Node3D, meshes)
			return

	for child in node.get_children():
		_process_node(child)


static func _should_skip(node: Node) -> bool:
	if node is Marker3D or node is OmniLight3D or node is Camera3D:
		return true
	if node is CharacterBody3D or node is Area3D:
		return true
	if node is StaticBody3D:
		return true
	return SKIP_NODE_NAMES.has(node.name)


static func _collect_visible_meshes(root: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_collect_visible_meshes_recursive(root, meshes)
	return meshes


static func _collect_visible_meshes_recursive(node: Node, meshes: Array[MeshInstance3D]) -> void:
	if node.name == COLLISION_ROOT_NAME:
		return
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh != null and _is_node_visible(mesh_inst):
			meshes.append(mesh_inst)
	for child in node.get_children():
		_collect_visible_meshes_recursive(child, meshes)


static func _is_node_visible(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is CanvasItem and not (current as CanvasItem).visible:
			return false
		if current is Node3D and not (current as Node3D).visible:
			return false
		current = current.get_parent()
	return true


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
