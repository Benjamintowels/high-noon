extends RefCounted
class_name GrappleTargetUtils

const GRAPPLE_GROUP := &"grapple_anchor"
const MAX_TARGET_RANGE := 28.0
const LAND_SNAP_RADIUS := 2.0
const RAY_PENETRATE_STEP := 0.08


static func is_grapple_anchor(node: Node) -> bool:
	if node == null:
		return false
	if node.is_in_group(GRAPPLE_GROUP):
		return true
	if node.get_parent() != null and node.get_parent().is_in_group(GRAPPLE_GROUP):
		return true
	return false


static func resolve_anchor_node(node: Node) -> Node3D:
	if node == null:
		return null
	if node is Node3D and node.is_in_group(GRAPPLE_GROUP):
		return node as Node3D
	var parent := node.get_parent()
	if parent is Node3D and parent.is_in_group(GRAPPLE_GROUP):
		return parent as Node3D
	return null


static func get_attach_point(anchor: Node3D) -> Vector3:
	if anchor == null:
		return Vector3.ZERO
	if anchor.has_method("get_grapple_attach_point"):
		return anchor.call("get_grapple_attach_point") as Vector3
	var marker := anchor.get_node_or_null("AttachPoint") as Node3D
	if marker != null:
		return marker.global_position
	return anchor.global_position + Vector3(0.0, 0.5, 0.0)


static func find_anchor_along_ray(
	world: World3D,
	origin: Vector3,
	direction: Vector3,
	exclude: Array[RID],
	max_range: float = MAX_TARGET_RANGE
) -> Node3D:
	if world == null:
		return null

	var space_state := world.direct_space_state
	if space_state == null:
		return null

	var dir_norm := direction.normalized()
	var ray_exclude := exclude.duplicate()
	var traveled := 0.0

	while traveled < max_range:
		var query := PhysicsRayQueryParameters3D.create(
			origin + dir_norm * traveled,
			origin + dir_norm * max_range
		)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		query.exclude = ray_exclude

		var hit := space_state.intersect_ray(query)
		if hit.is_empty():
			break

		var collider: Object = hit.get("collider")
		if collider is Node:
			var anchor := resolve_anchor_node(collider as Node)
			if anchor != null:
				return anchor

		var hit_rid: RID = hit.get("rid", RID())
		if hit_rid.is_valid():
			ray_exclude.append(hit_rid)

		var hit_dist: float = origin.distance_to(hit.position)
		var advance := maxf(hit_dist - traveled, RAY_PENETRATE_STEP)
		traveled += advance
		if advance <= 0.001:
			traveled += RAY_PENETRATE_STEP

	return null


static func find_nearest_anchor(world_point: Vector3, max_range: float = LAND_SNAP_RADIUS) -> Node3D:
	var tree := Engine.get_main_loop()
	if not tree is SceneTree:
		return null

	var best_anchor: Node3D
	var best_dist := max_range

	for node in (tree as SceneTree).get_nodes_in_group(GRAPPLE_GROUP):
		if not node is Node3D:
			continue
		var anchor := node as Node3D
		var attach := get_attach_point(anchor)
		var dist := world_point.distance_to(attach)
		if dist < best_dist:
			best_dist = dist
			best_anchor = anchor

	return best_anchor
