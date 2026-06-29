extends RefCounted
class_name BirdFlockAlert

const GUN_SCARE_RADIUS := 55.0
const EXPLOSION_SCARE_RADIUS := 72.0


static func scare_from_gun(parent: Node, origin: Vector3) -> void:
	_scare_near(parent, origin, GUN_SCARE_RADIUS)


static func scare_from_explosion(parent: Node, origin: Vector3) -> void:
	_scare_near(parent, origin, EXPLOSION_SCARE_RADIUS)


static func _scare_near(parent: Node, origin: Vector3, radius: float) -> void:
	if parent == null:
		return

	var tree := parent.get_tree()
	if tree == null:
		return

	var radius_sq := radius * radius
	for node in tree.get_nodes_in_group("ground_bird"):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		var bird := node as Node3D
		if bird.global_position.distance_squared_to(origin) > radius_sq:
			continue
		if bird.has_method("scare_from"):
			bird.call("scare_from", origin)
