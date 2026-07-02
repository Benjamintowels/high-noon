extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const TERRAIN_COLLISION := preload("res://gameplay/world/terrain_collision.gd")
const FLOOR_TILE_COLLISION := preload("res://gameplay/world/floor_tile_collision.gd")
const BIRDS_AMBIENCE := preload("res://Assets/World/RuinsGR/Sounds/BirdsAmbience.mp3")
const TownNavSetup := preload("res://gameplay/navigation/town_nav_setup.gd")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _ruins_root: Node3D = $RuinsLayout
@onready var _ambience_player: AudioStreamPlayer = $AmbiencePlayer

var _player: Node3D


func _ready() -> void:
	add_to_group("caves_stage")
	_setup_ruins_collision()
	_setup_caves_navigation()
	_setup_ambience()
	_fade_overlay.modulate.a = 1.0

	if GameState.start_in_caves_test:
		_spawn_fresh_player()
		GameState.start_in_caves_test = false
	elif AdventureSave.has_save_data():
		_spawn_player_from_save()
	else:
		_spawn_fresh_player()

	call_deferred("_setup_cave_enemies")

	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func _spawn_player_from_save() -> void:
	_player = _spawn_overworld_player()
	AdventureSave.apply_to_player(_player)


func _spawn_fresh_player() -> void:
	_player = _spawn_overworld_player()


func _spawn_overworld_player() -> Node3D:
	var spawn: Marker3D = $OverworldSpawn
	var player: Node3D = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = spawn.global_transform
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	call_deferred("_finalize_player_spawn", player)
	call_deferred("_link_baldwin_companion", player)
	return player


func _link_baldwin_companion(player: Node3D) -> void:
	if player == null or not CompanionManager.is_recruited(CompanionManager.COMPANION_BALDWIN):
		return
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node is BaldwinNpc:
			(node as BaldwinNpc).call_deferred("_begin_companion_mode", player)


func _setup_caves_navigation() -> void:
	var nav_setup := TownNavSetup.new()
	nav_setup.name = "CavesNavigation"
	add_child(nav_setup)
	nav_setup.configure_and_bake(_ruins_root, Vector3.ZERO, Vector3(48.0, 10.0, 48.0))


func _finalize_player_spawn(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if player.has_method("snap_to_floor"):
		player.snap_to_floor()


func _setup_ambience() -> void:
	_ambience_player.stream = BIRDS_AMBIENCE
	_ambience_player.volume_db = -16.0
	_ambience_player.autoplay = true


func _setup_ruins_collision() -> void:
	var floor_root := _ruins_root.get_node_or_null("Floor") as Node3D
	if floor_root != null:
		FLOOR_TILE_COLLISION.apply_to(floor_root)

	for node_name in ["Structures", "Obstacles"]:
		var collision_root := _ruins_root.get_node_or_null(node_name) as Node3D
		if collision_root != null:
			TERRAIN_COLLISION.apply_to(collision_root)


func _setup_cave_enemies() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("spawn_enemy"):
			node.spawn_enemy()
