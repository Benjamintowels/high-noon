extends RefCounted
class_name DuelHitTest

## Ray vs capsule aligned to an arbitrary axis. Returns distance along ray to first hit, or -1.


static func normalized_capsule_axis(axis: Variant) -> Vector3:
	if axis is Vector3 and axis.length_squared() > 0.0001:
		return axis.normalized()
	return Vector3.UP


static func point_in_capsule(
	world_point: Vector3,
	capsule_center: Vector3,
	capsule_half_height: float,
	capsule_radius: float,
	capsule_axis: Vector3 = Vector3.UP,
	margin: float = 0.0
) -> bool:
	var axis := normalized_capsule_axis(capsule_axis)
	var local := world_point - capsule_center
	var along := local.dot(axis)
	var clamped_along := clampf(along, -capsule_half_height, capsule_half_height)
	var radial := local - axis * clamped_along
	return radial.length() <= capsule_radius + margin


static func raycast_capsule(
	ray_origin: Vector3,
	ray_dir: Vector3,
	max_distance: float,
	capsule_center: Vector3,
	capsule_half_height: float,
	capsule_radius: float,
	capsule_axis: Vector3 = Vector3.UP
) -> float:
	if max_distance <= 0.0001 or ray_dir.length_squared() < 0.0001:
		return -1.0

	var dir := ray_dir.normalized()
	var axis := normalized_capsule_axis(capsule_axis)
	var seg_a := capsule_center - axis * capsule_half_height
	var seg_b := capsule_center + axis * capsule_half_height
	var ba := seg_b - seg_a
	var oa := ray_origin - seg_a

	var baba := ba.dot(ba)
	var bard := ba.dot(dir)
	var baoa := ba.dot(oa)
	var rdoa := dir.dot(oa)
	var oaoa := oa.dot(oa)
	var radius_sq := capsule_radius * capsule_radius

	var a := baba - bard * bard
	var b := baba * rdoa - baoa * bard
	var c := baba * oaoa - baoa * baoa - radius_sq * baba
	var h := b * b - a * c
	if h >= 0.0 and absf(a) > 0.0001:
		var t := (-b - sqrt(h)) / a
		var y := baoa + t * bard
		if y >= 0.0 and y <= baba and t >= 0.0 and t <= max_distance:
			return t

	var caps := [
		{"center": seg_a, "t": _ray_sphere(ray_origin, dir, max_distance, seg_a, capsule_radius)},
		{"center": seg_b, "t": _ray_sphere(ray_origin, dir, max_distance, seg_b, capsule_radius)},
	]
	var best := -1.0
	for cap in caps:
		var cap_t: float = cap.t
		if cap_t >= 0.0 and (best < 0.0 or cap_t < best):
			best = cap_t
	return best


static func raycast_sphere(
	ray_origin: Vector3,
	ray_dir: Vector3,
	max_distance: float,
	sphere_center: Vector3,
	sphere_radius: float
) -> float:
	if max_distance <= 0.0001 or ray_dir.length_squared() < 0.0001:
		return -1.0
	return _ray_sphere(ray_origin, ray_dir.normalized(), max_distance, sphere_center, sphere_radius)


static func closest_group_sphere_hit(
	ray_origin: Vector3,
	ray_dir: Vector3,
	max_distance: float,
	group_name: StringName,
	sphere_radius: float,
	tree: SceneTree
) -> Dictionary:
	if tree == null or max_distance <= 0.0001 or ray_dir.length_squared() < 0.0001:
		return {}

	var best_t := max_distance + 1.0
	var best_node: Node = null
	for node in tree.get_nodes_in_group(group_name):
		if node == null or not is_instance_valid(node):
			continue
		if not node.has_method("get_bullet_hit_center"):
			continue

		var center: Vector3 = node.call("get_bullet_hit_center")
		var radius: float = node.call("get_bullet_hit_radius") if node.has_method("get_bullet_hit_radius") else sphere_radius
		var hit_t := raycast_sphere(ray_origin, ray_dir, max_distance, center, radius)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_node = node

	if best_node == null:
		return {}

	var dir := ray_dir.normalized()
	return {
		"position": ray_origin + dir * best_t,
		"normal": -dir,
		"collider": best_node,
		"distance": best_t,
	}


static func _ray_sphere(origin: Vector3, dir: Vector3, max_distance: float, center: Vector3, radius: float) -> float:
	var oc := origin - center
	var b := oc.dot(dir)
	var c := oc.dot(oc) - radius * radius
	var h := b * b - c
	if h < 0.0:
		return -1.0
	var t := -b - sqrt(h)
	if t >= 0.0 and t <= max_distance:
		return t
	t = -b + sqrt(h)
	if t >= 0.0 and t <= max_distance:
		return t
	return -1.0
