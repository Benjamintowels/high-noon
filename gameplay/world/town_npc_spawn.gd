extends Marker3D
class_name TownNpcSpawn

@export var npc_scene: PackedScene

var _spawned: Node3D


func _ready() -> void:
	add_to_group("town_npc_spawn")


func spawn_npc() -> void:
	if not is_inside_tree():
		call_deferred("spawn_npc")
		return

	despawn_npc()
	if npc_scene == null:
		return

	var npc: Node3D = npc_scene.instantiate()
	var host := _get_spawn_host()
	if host == null:
		npc.queue_free()
		return

	host.add_child(npc)
	npc.global_transform = global_transform
	_spawned = npc


func despawn_npc() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		_spawned.queue_free()
	_spawned = null


func respawn_if_defeated() -> void:
	if _spawned == null or not is_instance_valid(_spawned):
		spawn_npc()
		return
	if _spawned.has_method("is_defeated") and _spawned.is_defeated():
		spawn_npc()


func get_spawned_npc() -> Node3D:
	return _spawned


func _get_spawn_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.name in ["TownActors", "Town"] or node.is_in_group("stage_root"):
			return node
		node = node.get_parent()

	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	return get_parent()
