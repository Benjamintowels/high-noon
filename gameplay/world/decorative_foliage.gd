extends Node3D

## Visual-only foliage. Skipped by collision bakes and ignored by the overworld camera.


func _ready() -> void:
	add_to_group("decorative_foliage")
	_disable_physics_recursive(self)


static func is_under_decorative_foliage(node: Node) -> bool:
	var current := node
	while current != null:
		if current.is_in_group("decorative_foliage"):
			return true
		current = current.get_parent()
	return false


func _disable_physics_recursive(node: Node) -> void:
	if node is CollisionObject3D:
		var body := node as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
		body.add_to_group("camera_ray_exclude")
	elif node is CollisionShape3D:
		(node as CollisionShape3D).disabled = true
	for child in node.get_children():
		_disable_physics_recursive(child)
