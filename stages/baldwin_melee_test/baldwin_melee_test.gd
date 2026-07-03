extends Node3D

const BALDWIN_PLAYER_SCENE := preload("res://characters/baldwin/baldwin_overworld_player.tscn")
const RUINS_LOOT_CHEST_SCENE := preload("res://gameplay/world/ruins_loot_chest.tscn")

var _player: Node3D


func _ready() -> void:
	PlayerInventory.reset_for_new_game()
	PlayerInventory.set_has_ruins_key(true)
	_player = _spawn_player()
	_spawn_loot_chest()


func _spawn_player() -> Node3D:
	var spawn := $OverworldSpawn as Marker3D
	var player: Node3D = BALDWIN_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = spawn.global_transform
	if player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	return player


func _spawn_loot_chest() -> void:
	if PlayerInventory.has_sword_shield:
		return
	var marker := $ChestSpawn as Marker3D
	if marker == null:
		marker = $PickupSpawn as Marker3D
	if marker == null:
		return
	var chest: Node3D = RUINS_LOOT_CHEST_SCENE.instantiate()
	add_child(chest)
	chest.global_transform = marker.global_transform
