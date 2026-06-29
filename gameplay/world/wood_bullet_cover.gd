class_name WoodBulletCover
extends RefCounted

const FENCE_SURFACE_SCRIPT := preload("res://gameplay/targets/fence_surface.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const COVER_ROOT_NAME := "BulletCover"


static func apply_to(root: Node) -> void:
	if root == null:
		return
	_process_node(root)


static func _process_node(node: Node) -> void:
	if node.name == COVER_ROOT_NAME:
		return

	if node is StaticBody3D:
		_ensure_surface_script(node as StaticBody3D, ImpactFX.SurfaceKind.WOOD)
		return

	if _should_generate_cover(node):
		_generate_cover_for(node as Node3D)
		return

	for child in node.get_children():
		_process_node(child)


static func _should_generate_cover(node: Node) -> bool:
	if not node is Node3D:
		return false
	if node.get_node_or_null(COVER_ROOT_NAME) != null:
		return false
	if node.name.begins_with("Build_"):
		return true
	if node.name.begins_with("Signs"):
		return true
	if node.name.begins_with("Cart_"):
		return true
	return _is_natural_cover_name(node.name)


static func _is_natural_cover_name(node_name: String) -> bool:
	if node_name == "tree" or node_name.begins_with("tree_") or node_name.begins_with("pine_tree"):
		return true
	return false


static func _surface_kind_for(root: Node3D) -> ImpactFX.SurfaceKind:
	if root.name.begins_with("Build_"):
		return ImpactFX.SurfaceKind.PLASTER
	if root.name.begins_with("Signs"):
		return ImpactFX.SurfaceKind.WOOD
	return ImpactFX.SurfaceKind.WOOD


static func _generate_cover_for(root: Node3D) -> void:
	var cover_root := Node3D.new()
	cover_root.name = COVER_ROOT_NAME
	root.add_child(cover_root)

	var surface_kind := _surface_kind_for(root)
	for mesh_inst in _collect_meshes(root, cover_root):
		_add_trimesh_body(cover_root, mesh_inst, surface_kind)


static func _collect_meshes(node: Node, skip: Node) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []
	_collect_meshes_recursive(node, skip, meshes)
	return meshes


static func _collect_meshes_recursive(
	node: Node,
	skip: Node,
	meshes: Array[MeshInstance3D]
) -> void:
	if node == skip:
		return
	if node.name == COVER_ROOT_NAME:
		return
	if node is MeshInstance3D:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh != null and _is_node_visible(mesh_inst):
			meshes.append(mesh_inst)
	for child in node.get_children():
		_collect_meshes_recursive(child, skip, meshes)


static func _is_node_visible(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if current is CanvasItem and not (current as CanvasItem).visible:
			return false
		if current is Node3D and not (current as Node3D).visible:
			return false
		current = current.get_parent()
	return true


static func _add_trimesh_body(
	cover_root: Node3D,
	mesh_inst: MeshInstance3D,
	surface_kind: ImpactFX.SurfaceKind
) -> void:
	var mesh := mesh_inst.mesh
	if mesh == null:
		return

	var shape := mesh.create_trimesh_shape()
	if shape == null:
		return

	var body := StaticBody3D.new()
	body.collision_layer = 1
	body.set_script(FENCE_SURFACE_SCRIPT)
	body.set("surface_kind", surface_kind)
	cover_root.add_child(body)
	body.global_transform = mesh_inst.global_transform

	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


static func _ensure_surface_script(body: StaticBody3D, surface_kind: ImpactFX.SurfaceKind) -> void:
	if body.has_method("apply_bullet_hit"):
		return
	if body.name == "GroundBody":
		return
	body.set_script(FENCE_SURFACE_SCRIPT)
	body.set("surface_kind", surface_kind)
