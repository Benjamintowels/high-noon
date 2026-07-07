class_name BuildingMaterialApplier
extends RefCounted

const WALLS_MATERIAL := preload("res://Assets/World/Buildings/materials/building_walls.tres")
const WINDOOR_MATERIAL := preload("res://Assets/World/Buildings/materials/building_windoor.tres")
const PLANKS_MATERIAL := preload("res://Assets/World/Buildings/materials/building_planks.tres")

const MATERIALS_BY_NAME := {
	"Walls": WALLS_MATERIAL,
	"WesternTrimV2": WALLS_MATERIAL,
	"WesternTrimV2_1": WALLS_MATERIAL,
	"Windoorv4": WINDOOR_MATERIAL,
	"Windoorv4_1": WINDOOR_MATERIAL,
	"Windoorv4_2": WINDOOR_MATERIAL,
	"PlankFLoor": PLANKS_MATERIAL,
	"PlankFloor": PLANKS_MATERIAL,
	"Planks": PLANKS_MATERIAL,
}


static func apply_to(root: Node) -> void:
	_apply_recursive(root)


static func apply_with_fallbacks(root: Node) -> void:
	apply_to(root)
	_apply_building_fallbacks(root)


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


static func _apply_building_fallbacks(node: Node) -> void:
	if _is_building_prop_name(node.name):
		_apply_fallback_to_untextured_meshes(node, WALLS_MATERIAL)
	for child in node.get_children():
		_apply_building_fallbacks(child)


static func _is_building_prop_name(node_name: String) -> bool:
	return node_name.begins_with("Build_") or node_name.begins_with("Signs_")


static func _apply_fallback_to_untextured_meshes(root: Node, material: Material) -> void:
	if root is MeshInstance3D:
		apply_fallback_material(root as MeshInstance3D, material)
	for child in root.get_children():
		_apply_fallback_to_untextured_meshes(child, material)


static func apply_fallback_material(mesh_instance: MeshInstance3D, material: Material) -> void:
	if mesh_instance.mesh == null:
		return

	if mesh_instance.material_override != null:
		if _material_needs_fallback(mesh_instance.material_override):
			mesh_instance.material_override = material
		return

	for surface_index in mesh_instance.mesh.get_surface_count():
		var source_material := mesh_instance.get_surface_override_material(surface_index)
		if source_material == null and mesh_instance.mesh is ArrayMesh:
			source_material = (mesh_instance.mesh as ArrayMesh).surface_get_material(surface_index)
		if _material_needs_fallback(source_material):
			mesh_instance.set_surface_override_material(surface_index, material)


static func mesh_needs_material_fix(mesh_instance: MeshInstance3D) -> bool:
	if mesh_instance.mesh == null:
		return false
	if mesh_instance.material_override != null:
		return _material_needs_fallback(mesh_instance.material_override)
	for surface_index in mesh_instance.mesh.get_surface_count():
		var source_material := mesh_instance.get_surface_override_material(surface_index)
		if source_material == null and mesh_instance.mesh is ArrayMesh:
			source_material = (mesh_instance.mesh as ArrayMesh).surface_get_material(surface_index)
		if _material_needs_fallback(source_material):
			return true
	return false


static func _material_needs_fallback(material: Material) -> bool:
	if material == null:
		return true
	if material is StandardMaterial3D:
		var std := material as StandardMaterial3D
		return std.albedo_texture == null
	return false
