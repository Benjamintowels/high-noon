extends RefCounted
class_name TcRageFlash

const RAGE_RED := Color(1.45, 0.15, 0.15, 1.0)
const RAGE_WHITE := Color(1.6, 1.6, 1.6, 1.0)
const FLASH_HALF_PERIOD := 0.1

const ACTIVE_META := &"tc_rage_flash_active"
const MATERIALS_META := &"tc_rage_flash_materials"
const ORIGINALS_META := &"tc_rage_flash_originals"
const TWEEN_META := &"tc_rage_flash_tween"


static func start(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	stop(actor)

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var flash_materials: Array[StandardMaterial3D] = []
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
			var flash_mat := StandardMaterial3D.new()
			flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			flash_mat.albedo_color = RAGE_RED
			flash_mat.emission_enabled = true
			flash_mat.emission = RAGE_RED * 0.4
			mesh.set_surface_override_material(surface_idx, flash_mat)
			flash_materials.append(flash_mat)

	if flash_materials.is_empty():
		return

	actor.set_meta(ACTIVE_META, true)
	actor.set_meta(MATERIALS_META, flash_materials)
	actor.set_meta(ORIGINALS_META, originals)

	var tween := actor.create_tween().set_loops()
	tween.tween_callback(func() -> void:
		_set_material_colors(flash_materials, RAGE_RED)
	)
	tween.tween_interval(FLASH_HALF_PERIOD)
	tween.tween_callback(func() -> void:
		_set_material_colors(flash_materials, RAGE_WHITE)
	)
	tween.tween_interval(FLASH_HALF_PERIOD)
	actor.set_meta(TWEEN_META, tween)


static func stop(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if not actor.has_meta(ACTIVE_META):
		return

	if actor.has_meta(TWEEN_META):
		var tween: Tween = actor.get_meta(TWEEN_META)
		if tween != null and tween.is_valid():
			tween.kill()
		actor.remove_meta(TWEEN_META)

	var originals: Dictionary = actor.get_meta(ORIGINALS_META) if actor.has_meta(ORIGINALS_META) else {}
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
	actor.remove_meta(MATERIALS_META)
	actor.remove_meta(ORIGINALS_META)


static func _set_material_colors(materials: Array, color: Color) -> void:
	for mat in materials:
		if mat == null or not is_instance_valid(mat):
			continue
		mat.albedo_color = color
		mat.emission = color * 0.4


static func _get_visual_root(actor: Node) -> Node:
	if actor.has_node("Model"):
		return actor.get_node("Model")
	return actor


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh.name.contains("Debug"):
		return true
	return mesh.mesh == null
