extends RefCounted
class_name TcBlockTint

const BLOCK_BLUE := Color(0.55, 0.85, 1.45, 1.0)

const ACTIVE_META := &"tc_block_tint_active"
const ORIGINALS_META := &"tc_block_tint_originals"


static func start(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if actor.has_meta(ACTIVE_META):
		return

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var originals: Dictionary = {}
	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		var mesh_key := str(mesh.get_path())
		var surface_count := mesh.mesh.get_surface_count()
		if surface_count <= 0:
			continue

		var cached_originals: Array = []
		for surface_idx in range(surface_count):
			cached_originals.append(mesh.get_surface_override_material(surface_idx))
		originals[mesh_key] = cached_originals

		for surface_idx in range(surface_count):
			var tint_mat := StandardMaterial3D.new()
			tint_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			tint_mat.albedo_color = BLOCK_BLUE
			tint_mat.emission_enabled = true
			tint_mat.emission = BLOCK_BLUE * 0.35
			mesh.set_surface_override_material(surface_idx, tint_mat)

	if originals.is_empty():
		return

	actor.set_meta(ACTIVE_META, true)
	actor.set_meta(ORIGINALS_META, originals)


static func stop(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not actor.has_meta(ACTIVE_META):
		return

	var originals: Dictionary = (
		actor.get_meta(ORIGINALS_META) if actor.has_meta(ORIGINALS_META) else {}
	)
	var visual_root := _get_visual_root(actor)
	if visual_root != null:
		for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
			if _should_skip_mesh(mesh):
				continue
			var mesh_key := str(mesh.get_path())
			if not originals.has(mesh_key):
				continue
			var cached_originals: Array = originals[mesh_key]
			var surface_count := mesh.mesh.get_surface_count()
			for surface_idx in range(surface_count):
				var original: Material = (
					cached_originals[surface_idx]
					if surface_idx < cached_originals.size()
					else null
				)
				mesh.set_surface_override_material(surface_idx, original)

	actor.remove_meta(ACTIVE_META)
	actor.remove_meta(ORIGINALS_META)


static func _get_visual_root(actor: Node) -> Node:
	if actor.has_node("Model"):
		return actor.get_node("Model")
	return actor


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh.name.contains("Debug"):
		return true
	return mesh.mesh == null
