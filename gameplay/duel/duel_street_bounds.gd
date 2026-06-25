class_name DuelStreetBounds
extends RefCounted

## Lateral walk limits from the Town/DuelStreet plane mesh (width = local X).


static func bounds_from_street_node(street: Node3D) -> Dictionary:
	if street == null:
		return {}

	var mesh_instance := street as MeshInstance3D
	if mesh_instance == null or mesh_instance.mesh == null:
		return {}

	var plane := mesh_instance.mesh as PlaneMesh
	if plane == null:
		return {}

	var scale := mesh_instance.global_transform.basis.get_scale()
	var half_width := plane.size.x * 0.5 * absf(scale.x)
	return {
		"center": mesh_instance.global_position,
		"half_width": half_width,
	}


static func find_street_in_scene(scene: Node) -> Node3D:
	if scene == null:
		return null
	return scene.get_node_or_null("Town/DuelStreet") as Node3D
