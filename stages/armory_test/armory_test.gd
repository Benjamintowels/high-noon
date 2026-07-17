extends Node3D

## Flat armory sandbox for run-and-gun / weapon / combat iteration.
## Launch: F6 or run res://stages/armory_test/armory_test.tscn

const PLAYER_SCENE := preload("res://characters/groyper/groyper_overworld_player.tscn")
const CHEST_SCENE := preload("res://gameplay/debug/debug_weapon_chest.tscn")
const TERMINAL_SCENE := preload("res://gameplay/debug/debug_spawn_terminal.tscn")

var _player: Node3D


func _ready() -> void:
	PlayerInventory.reset_for_new_game()
	_player = _spawn_player()
	_spawn_chest()
	_spawn_terminal()


func _spawn_player() -> Node3D:
	var spawn := $OverworldSpawn as Marker3D
	var player: Node3D = PLAYER_SCENE.instantiate()
	add_child(player)
	# Overworld Groyper: body root carries PI yaw (hub/stage1 convention).
	# Identity spawn + camera PI explore offset moonwalks.
	player.global_position = spawn.global_position
	player.global_rotation = Vector3(0.0, PI, 0.0)
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	return player


func _spawn_chest() -> void:
	var marker := $ChestSpawn as Marker3D
	if marker == null:
		return
	var chest: Node3D = CHEST_SCENE.instantiate()
	add_child(chest)
	chest.global_transform = marker.global_transform


func _spawn_terminal() -> void:
	var marker := $TerminalSpawn as Marker3D
	if marker == null:
		return
	var terminal: Node = TERMINAL_SCENE.instantiate()
	add_child(terminal)
	if terminal is Node3D:
		(terminal as Node3D).global_transform = marker.global_transform
	if terminal.has_method("configure"):
		terminal.configure($TargetSpawn as Marker3D, $DecalWall as Node3D)
