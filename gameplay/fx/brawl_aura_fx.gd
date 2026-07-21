extends RefCounted
## Subtle aura outline for NPCs (brawl red, or colored gem-enemy variants).
## Rendered as a material_overlay pass: the mesh drawn again, grown along its
## normals with front faces culled, leaving a soft silhouette.

const AURA_SHADER := preload("res://gameplay/fx/brawl_aura.gdshader")
const AURA_META := &"brawl_aura_meshes"
const DEFAULT_BRAWL_COLOR := Color(0.9, 0.12, 0.08, 0.32)
## Weapon FBX nodes often keep ~100x local scale. Never outline those — even
## with shader compensation it's wasted draw calls, and pre-fix materials
## could still explode the silhouette.
const MAX_MESH_SCALE_AXIS := 8.0


static func apply(npc: Node) -> void:
	apply_colored(npc, DEFAULT_BRAWL_COLOR)


static func apply_colored(npc: Node, color: Color) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	remove(npc)

	var material := ShaderMaterial.new()
	material.shader = AURA_SHADER
	material.set_shader_parameter("aura_color", color)
	material.set_shader_parameter("grow_amount", 0.025)

	var visual_root := _get_visual_root(npc)
	var covered: Array[NodePath] = []
	for child in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if _should_skip_mesh(mesh):
			continue
		if mesh.material_overlay != null:
			continue
		mesh.material_overlay = material
		covered.append(npc.get_path_to(mesh))
	npc.set_meta(AURA_META, covered)


static func remove(npc: Node) -> void:
	if npc == null or not is_instance_valid(npc) or not npc.has_meta(AURA_META):
		return
	var covered: Array = npc.get_meta(AURA_META)
	for mesh_path in covered:
		var mesh := npc.get_node_or_null(mesh_path) as MeshInstance3D
		if mesh != null:
			mesh.material_overlay = null
	npc.remove_meta(AURA_META)


static func _get_visual_root(npc: Node) -> Node:
	if npc.has_node("Model"):
		return npc.get_node("Model")
	return npc


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh == null or mesh.mesh == null:
		return true
	if mesh.name.contains("Debug"):
		return true
	if _is_equipment_mesh(mesh):
		return true
	var local_scale := mesh.scale
	var local_max := maxf(
		absf(local_scale.x),
		maxf(absf(local_scale.y), absf(local_scale.z))
	)
	if local_max > MAX_MESH_SCALE_AXIS:
		return true
	if mesh.is_inside_tree():
		var world_scale := mesh.global_transform.basis.get_scale()
		var world_max := maxf(
			absf(world_scale.x),
			maxf(absf(world_scale.y), absf(world_scale.z))
		)
		if world_max > MAX_MESH_SCALE_AXIS:
			return true
	return false


static func _is_equipment_mesh(mesh: MeshInstance3D) -> bool:
	## Holster / hand / hat mounts hold scaled weapon FBXs. Outline the body
	## skin only so the red aura reads as a character silhouette.
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
	return false
