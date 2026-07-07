class_name MeshyCharacterMaterials
extends RefCounted

## Normalizes Meshy FBX skin materials so characters respond to outdoor day/night lighting
## like the sheriff (no emission, no PBR maps that read too bright at night).
## Materials are cached per albedo texture for reuse across every spawned character.

const SKIN_ROUGHNESS := 0.88
const SKIN_METALLIC := 0.0

static var _material_cache: Dictionary = {}


static func apply_outdoor_skin(
	root: Node3D,
	albedo_texture: Texture2D = null,
	skip_mounts: bool = true
) -> void:
	if root == null:
		return

	for mesh_inst in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_inst as MeshInstance3D
		if skip_mounts and _is_under_mount(mesh_inst):
			continue

		var texture := albedo_texture
		var albedo_color := Color.WHITE
		if texture == null:
			var source := _read_surface_material(mesh)
			if source == null:
				continue
			texture = _extract_albedo_texture(source)
			albedo_color = source.albedo_color
		if texture == null and albedo_color == Color.WHITE:
			continue

		mesh.material_override = _get_cached_material(texture, albedo_color)


static func _get_cached_material(texture: Texture2D, albedo_color: Color) -> StandardMaterial3D:
	var cache_key := _cache_key(texture, albedo_color)
	if _material_cache.has(cache_key):
		return _material_cache[cache_key]

	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.albedo_color = albedo_color
	material.roughness = SKIN_ROUGHNESS
	material.metallic = SKIN_METALLIC
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.emission_enabled = false
	_material_cache[cache_key] = material
	return material


static func _cache_key(texture: Texture2D, albedo_color: Color) -> String:
	var texture_key := texture.resource_path if texture != null and texture.resource_path != "" else (
		str(texture.get_instance_id()) if texture != null else "none"
	)
	return "%s|%s" % [texture_key, albedo_color]


static func _read_surface_material(mesh: MeshInstance3D) -> StandardMaterial3D:
	if mesh.material_override is StandardMaterial3D:
		return mesh.material_override as StandardMaterial3D

	if mesh.mesh == null:
		return null

	for surface_idx in mesh.mesh.get_surface_count():
		var override_mat := mesh.get_surface_override_material(surface_idx)
		if override_mat is StandardMaterial3D:
			return override_mat as StandardMaterial3D

		var surface_mat := mesh.mesh.surface_get_material(surface_idx)
		if surface_mat is StandardMaterial3D:
			return surface_mat as StandardMaterial3D

	return null


static func _extract_albedo_texture(material: StandardMaterial3D) -> Texture2D:
	return material.albedo_texture


static func _is_under_mount(node: Node) -> bool:
	var current: Node = node
	while current != null:
		if String(current.name).ends_with("Mount"):
			return true
		current = current.get_parent()
	return false
