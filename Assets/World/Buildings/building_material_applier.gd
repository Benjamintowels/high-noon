class_name BuildingMaterialApplier
extends RefCounted

const WALLS_MATERIAL := preload("res://Assets/World/Buildings/materials/building_walls.tres")
const WINDOOR_MATERIAL := preload("res://Assets/World/Buildings/materials/building_windoor.tres")
const PLANKS_MATERIAL := preload("res://Assets/World/Buildings/materials/building_planks.tres")

const MATERIALS_BY_NAME := {
	"Walls": WALLS_MATERIAL,
	"Windoorv4": WINDOOR_MATERIAL,
	"PlankFLoor": PLANKS_MATERIAL,
}


static func apply_to(root: Node) -> void:
	_apply_recursive(root)


static func _apply_recursive(node: Node) -> void:
	if node is MeshInstance3D:
		_apply_to_mesh(node as MeshInstance3D)

	for child in node.get_children():
		_apply_recursive(child)


static func _apply_to_mesh(mesh_instance: MeshInstance3D) -> void:
	if mesh_instance.material_override:
		var override_material := _resolve_material(mesh_instance.material_override)
		if override_material:
			mesh_instance.material_override = override_material
		return

	var mesh := mesh_instance.mesh
	if mesh == null:
		return

	for surface_index in mesh.get_surface_count():
		var source_material := mesh_instance.get_surface_override_material(surface_index)
		if source_material == null and mesh is ArrayMesh:
			source_material = mesh.surface_get_material(surface_index)

		var replacement := _resolve_material(source_material)
		if replacement:
			mesh_instance.set_surface_override_material(surface_index, replacement)


static func _resolve_material(source_material: Material) -> StandardMaterial3D:
	if source_material == null:
		return null

	if not MATERIALS_BY_NAME.has(source_material.resource_name):
		return null

	var replacement: StandardMaterial3D = MATERIALS_BY_NAME[source_material.resource_name]
	if source_material is StandardMaterial3D:
		var current := source_material as StandardMaterial3D
		if current.albedo_texture == replacement.albedo_texture:
			return null

	return replacement
