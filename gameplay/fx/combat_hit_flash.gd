extends RefCounted
class_name CombatHitFlash

const BLOCK_COLOR := Color(1.55, 1.55, 1.55, 1.0)
const REFLECT_COLOR := Color(1.55, 1.22, 0.28, 1.0)
const DAMAGE_COLOR := Color(1.45, 0.28, 0.28, 1.0)
const FLASH_IN := 0.03
const FLASH_HOLD := 0.05
const FLASH_OUT := 0.1

const CACHE_META := &"combat_hit_flash_material_cache"


static func flash_block(actor: Node) -> void:
	_flash(actor, BLOCK_COLOR)


static func flash_reflect(actor: Node) -> void:
	_flash(actor, REFLECT_COLOR)


static func flash_damage(actor: Node) -> void:
	_flash(actor, DAMAGE_COLOR)


static func _flash(actor: Node, flash_color: Color) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var tree := actor.get_tree()
	if tree == null:
		return

	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		_flash_mesh(actor, mesh, flash_color, tree)


static func _get_visual_root(actor: Node) -> Node:
	if actor.has_node("Model"):
		return actor.get_node("Model")
	return actor


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh.name.contains("Debug"):
		return true
	return mesh.mesh == null


static func _flash_mesh(
	actor: Node,
	mesh: MeshInstance3D,
	flash_color: Color,
	tree: SceneTree
) -> void:
	var surface_count := mesh.mesh.get_surface_count()
	if surface_count <= 0:
		return

	var cache: Dictionary = _get_material_cache(actor)
	var mesh_key := str(mesh.get_path())
	if not cache.has(mesh_key):
		var cached_originals: Array = []
		for surface_idx in range(surface_count):
			cached_originals.append(mesh.get_surface_override_material(surface_idx))
		cache[mesh_key] = cached_originals

	var originals: Array = cache[mesh_key]
	var flash_materials: Array[StandardMaterial3D] = []
	for surface_idx in range(surface_count):
		var flash_mat := StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.albedo_color = flash_color
		flash_mat.emission_enabled = true
		flash_mat.emission = flash_color * 0.35
		mesh.set_surface_override_material(surface_idx, flash_mat)
		flash_materials.append(flash_mat)

	var tween := tree.create_tween()
	tween.tween_interval(FLASH_IN + FLASH_HOLD)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(mesh):
			return
		for surface_idx in range(surface_count):
			var original: Material = originals[surface_idx] if surface_idx < originals.size() else null
			mesh.set_surface_override_material(surface_idx, original)
	)


static func _get_material_cache(actor: Node) -> Dictionary:
	if not actor.has_meta(CACHE_META):
		actor.set_meta(CACHE_META, {})
	return actor.get_meta(CACHE_META)
