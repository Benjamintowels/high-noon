extends Marker3D
class_name CaveEnemySpawn

const DEFAULT_ENEMY_SCENE := preload("res://characters/enemies/skeleton_enemy.tscn")

@export var enemy_scene: PackedScene = DEFAULT_ENEMY_SCENE

var _spawned: Node3D


func _ready() -> void:
	add_to_group("cave_enemy_spawn")


func spawn_enemy() -> void:
	if not is_inside_tree():
		call_deferred("spawn_enemy")
		return

	despawn_enemy()
	if enemy_scene == null:
		return

	var enemy: Node3D = enemy_scene.instantiate()
	var host := _get_spawn_host()
	if host == null:
		enemy.queue_free()
		return

	host.add_child(enemy)
	enemy.global_transform = global_transform
	_spawned = enemy


func despawn_enemy() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		_spawned.queue_free()
	_spawned = null


func respawn_enemy() -> void:
	spawn_enemy()


func _get_spawn_host() -> Node:
	var node: Node = get_parent()
	while node != null:
		if node.is_in_group("cave_enemy_root"):
			return node
		node = node.get_parent()

	var tree := get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	return get_parent()
