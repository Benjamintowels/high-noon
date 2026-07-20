extends RefCounted
## Subtle aura outline for NPCs (brawl red, or colored gem-enemy variants).
## Rendered as a material_overlay pass: the mesh drawn again, grown along its
## normals with front faces culled, leaving a soft silhouette.

const AURA_SHADER := preload("res://gameplay/fx/brawl_aura.gdshader")
const AURA_META := &"brawl_aura_meshes"
const DEFAULT_BRAWL_COLOR := Color(0.9, 0.12, 0.08, 0.32)


static func apply(npc: Node) -> void:
	apply_colored(npc, DEFAULT_BRAWL_COLOR)


static func apply_colored(npc: Node, color: Color) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	remove(npc)

	var material := ShaderMaterial.new()
	material.shader = AURA_SHADER
	material.set_shader_parameter("aura_color", color)

	var covered: Array[NodePath] = []
	for child in npc.find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
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
