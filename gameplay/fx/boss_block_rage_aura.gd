extends RefCounted
class_name BossBlockRageAura

## Red ↔ black body flash + dark crimson silhouette while block-rage is active.

const AURA_SHADER := preload("res://gameplay/fx/brawl_aura.gdshader")

const RAGE_RED := Color(1.55, 0.08, 0.06, 1.0)
const RAGE_BLACK := Color(0.06, 0.02, 0.02, 1.0)
const AURA_COLOR := Color(0.85, 0.05, 0.04, 0.42)
const FLASH_STEP := 0.11

const ACTIVE_META := &"boss_block_rage_aura_active"
const MATERIALS_META := &"boss_block_rage_aura_materials"
const ORIGINALS_META := &"boss_block_rage_aura_originals"
const TWEEN_META := &"boss_block_rage_aura_tween"
const OVERLAY_META := &"boss_block_rage_aura_overlays"


static func start(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	stop(actor)

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var flash_materials: Array[StandardMaterial3D] = []
	var originals: Dictionary = {}
	var covered: Array[NodePath] = []

	var aura_mat := ShaderMaterial.new()
	aura_mat.shader = AURA_SHADER
	aura_mat.set_shader_parameter("aura_color", AURA_COLOR)
	aura_mat.set_shader_parameter("grow_amount", 0.04)

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
			flash_mat.emission = RAGE_RED * 0.55
			mesh.set_surface_override_material(surface_idx, flash_mat)
			flash_materials.append(flash_mat)

		if mesh.material_overlay == null:
			mesh.material_overlay = aura_mat
			covered.append(actor.get_path_to(mesh))

	if flash_materials.is_empty():
		return

	actor.set_meta(ACTIVE_META, true)
	actor.set_meta(MATERIALS_META, flash_materials)
	actor.set_meta(ORIGINALS_META, originals)
	actor.set_meta(OVERLAY_META, covered)

	var tween := actor.create_tween().set_loops()
	tween.tween_callback(func() -> void:
		_set_material_colors(flash_materials, RAGE_RED)
	)
	tween.tween_interval(FLASH_STEP)
	tween.tween_callback(func() -> void:
		_set_material_colors(flash_materials, RAGE_BLACK)
	)
	tween.tween_interval(FLASH_STEP)
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

	var originals: Dictionary = (
		actor.get_meta(ORIGINALS_META) if actor.has_meta(ORIGINALS_META) else {}
	)
	var visual_root := _get_visual_root(actor)
	if visual_root != null:
		for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
			if _should_skip_mesh(mesh):
				continue
			var mesh_key := str(mesh.get_path())
			if originals.has(mesh_key):
				var cached_originals: Array = originals[mesh_key]
				var surface_count := mesh.mesh.get_surface_count()
				for surface_idx in range(surface_count):
					var original: Material = (
						cached_originals[surface_idx]
						if surface_idx < cached_originals.size()
						else null
					)
					mesh.set_surface_override_material(surface_idx, original)

	if actor.has_meta(OVERLAY_META):
		var covered: Array = actor.get_meta(OVERLAY_META)
		for mesh_path in covered:
			var mesh := actor.get_node_or_null(mesh_path) as MeshInstance3D
			if mesh != null:
				mesh.material_overlay = null
		actor.remove_meta(OVERLAY_META)

	actor.remove_meta(ACTIVE_META)
	actor.remove_meta(MATERIALS_META)
	actor.remove_meta(ORIGINALS_META)


static func _set_material_colors(materials: Array, color: Color) -> void:
	for mat in materials:
		if mat == null or not is_instance_valid(mat):
			continue
		mat.albedo_color = color
		mat.emission = color * 0.55


static func _get_visual_root(actor: Node) -> Node:
	if actor.has_node("Model"):
		return actor.get_node("Model")
	return actor


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh == null or mesh.mesh == null:
		return true
	if mesh.name.contains("Debug"):
		return true
	## Same trap as brawl aura: weapon FBX imports at ~100x scale turn the
	## inverted-hull outline into a screen-filling red shell.
	var node: Node = mesh
	while node != null:
		var node_name := String(node.name)
		if (
			node_name.contains("Mount")
			or node_name.contains("Holster")
			or node_name.contains("Grip")
			or node_name.contains("HatOffset")
		):
			return true
		var parent := node.get_parent()
		if parent == null or parent is CharacterBody3D:
			break
		node = parent
	if mesh.is_inside_tree():
		var world_scale := mesh.global_transform.basis.get_scale()
		var world_max := maxf(
			absf(world_scale.x),
			maxf(absf(world_scale.y), absf(world_scale.z))
		)
		if world_max > 8.0:
			return true
	return false
