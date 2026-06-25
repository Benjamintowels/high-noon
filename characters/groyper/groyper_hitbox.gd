extends StaticBody3D

@export var owner_path: NodePath

signal bullet_hit_received(hit_info: Dictionary)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	bullet_hit_received.emit(hit_info)

	var owner := _resolve_owner()
	if owner != null:
		owner.receive_bullet_hit(hit_info)


func _resolve_owner() -> Node:
	if not owner_path.is_empty():
		var explicit_owner := get_node_or_null(owner_path)
		if explicit_owner != null and explicit_owner.has_method("receive_bullet_hit"):
			return explicit_owner

	var node := get_parent()
	while node != null:
		if node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	return null
