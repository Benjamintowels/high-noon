class_name StageZoneCuller
extends RefCounted

const COLLISION_LAYER_ACTIVE := 1


static func set_zone_active(zone: Node3D, active: bool) -> void:
	if zone == null:
		return
	zone.visible = active
	zone.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
	_set_collision_active(zone, active)


static func _set_collision_active(node: Node, active: bool) -> void:
	if node is StaticBody3D:
		var body := node as StaticBody3D
		body.collision_layer = COLLISION_LAYER_ACTIVE if active else 0
		body.collision_mask = COLLISION_LAYER_ACTIVE if active else 0
	elif node is RigidBody3D:
		var rigid := node as RigidBody3D
		rigid.collision_layer = COLLISION_LAYER_ACTIVE if active else 0
		rigid.collision_mask = COLLISION_LAYER_ACTIVE if active else 0
	elif node is CollisionShape3D:
		(node as CollisionShape3D).disabled = not active
	elif node is Area3D:
		(node as Area3D).monitoring = active
		(node as Area3D).monitorable = active

	for child in node.get_children():
		_set_collision_active(child, active)
