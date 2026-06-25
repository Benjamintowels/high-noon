extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_PLAYER_SCENE := preload("res://characters/groyper/groyper_player.tscn")
const GROYPER_OVERWORLD_PLAYER_SCENE := preload("res://characters/groyper/groyper_overworld_player.tscn")
const PRACTICE_FENCE_SCENE := preload("res://gameplay/targets/practice_fence.tscn")
const BUILDING_MATERIAL_APPLIER := preload("res://Assets/World/Buildings/building_material_applier.gd")
const DUEL_MANAGER_SCRIPT := preload("res://gameplay/duel/duel_manager.gd")
const TARGET_MANAGER_SCRIPT := preload("res://gameplay/target/target_manager.gd")
const TUMBLEWEED_SCENE := preload("res://gameplay/duel/tumbleweed.tscn")
const HORSE_CORRAL_SCENE := preload("res://gameplay/world/horse_corral.tscn")
const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _practice_targets: Node3D = $Town/PracticeTargets
@onready var _duel_lane: Node3D = $Town/DuelLane

var _player: Node3D
var _duel_manager: Node
var _target_manager: Node
var _opening_tumbleweed: Node3D


func _ready() -> void:
	BUILDING_MATERIAL_APPLIER.apply_to($Town)
	_fade_overlay.modulate.a = 1.0
	_ensure_practice_targets()
	_spawn_town_horses()

	if GameState.practice_tutorial_mode:
		_practice_targets.visible = true
		_spawn_player()
	elif GameState.selected_game_mode == GameState.GameMode.OVERWORLD:
		_practice_targets.visible = true
		_setup_overworld()
	elif GameState.selected_game_mode == GameState.GameMode.TARGET:
		_practice_targets.visible = false
		_setup_target()
	else:
		_practice_targets.visible = false
		_setup_duel()
		_spawn_opening_tumbleweed()

	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if _duel_manager != null:
		_duel_manager.call_deferred(
			"start_match",
			_player,
			$Town,
			_duel_lane.get_path_to($Town/DuelLane/PlayerSpawn),
			_opening_tumbleweed
		)
	elif _target_manager != null:
		_target_manager.call_deferred("start_match", _player, $Town)


func _spawn_opening_tumbleweed() -> void:
	_opening_tumbleweed = TUMBLEWEED_SCENE.instantiate()
	_duel_lane.add_child(_opening_tumbleweed)
	if _opening_tumbleweed.has_method("begin_roll"):
		var roll_duration := DuelTumbleweed.opening_roll_duration(
			FADE_IN_DURATION,
			DUEL_MANAGER_SCRIPT.INTRO_DELAY,
			DUEL_MANAGER_SCRIPT.COUNTDOWN_SECONDS
		)
		_opening_tumbleweed.begin_roll(_duel_lane, roll_duration)


func _setup_overworld() -> void:
	_player = _spawn_overworld_player()
	_spawn_town_npcs()


func _spawn_town_npcs() -> void:
	const SHERIFF_NPC_SCENE := preload("res://characters/sheriff/sheriff_town_npc.tscn")
	var spawn: Marker3D = get_node_or_null("Town/SheriffSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/SheriffSpawn marker.")
		return

	var sheriff: Node3D = SHERIFF_NPC_SCENE.instantiate()
	add_child(sheriff)
	sheriff.global_position = spawn.global_position
	sheriff.global_rotation = spawn.global_rotation


func _spawn_town_horses() -> void:
	var horses_root := get_node_or_null("Town/Horses") as Node3D
	if horses_root == null:
		horses_root = Node3D.new()
		horses_root.name = "Horses"
		$Town.add_child(horses_root)

	var corral: Node3D = HORSE_CORRAL_SCENE.instantiate()
	corral.name = "HorseCorral"
	horses_root.add_child(corral)
	corral.position = Vector3(-22.0, 0.0, 62.0)

	_spawn_free_horse(horses_root, Vector3(6.5, 0.0, 5.0), 1, StupidHorseScript.RoamMode.STREET, 501)
	_spawn_free_horse(horses_root, Vector3(-9.0, 0.0, 44.0), 3, StupidHorseScript.RoamMode.FREE, 733)
	_spawn_free_horse(horses_root, Vector3(15.5, 0.0, -16.0), 4, StupidHorseScript.RoamMode.FREE, 881)
	_spawn_free_horse(horses_root, Vector3(-5.5, 0.0, -32.0), 0, StupidHorseScript.RoamMode.FREE, 999)


func _spawn_free_horse(
	parent: Node3D,
	spawn_pos: Vector3,
	variant_index: int,
	roam_mode: StupidHorseScript.RoamMode,
	seed_value: int
) -> void:
	var horse: Node3D = STUPID_HORSE_SCENE.instantiate()
	horse.set("model_variant", HorseModelConfig.VARIANTS[variant_index % HorseModelConfig.VARIANTS.size()])
	horse.set("roam_mode", roam_mode)
	horse.set("personality_seed", seed_value)
	parent.add_child(horse)
	horse.position = spawn_pos
	if roam_mode == StupidHorseScript.RoamMode.STREET:
		horse.set("roam_center", spawn_pos)
		horse.set("roam_half_extents", Vector2(1.8, 6.0))


func _spawn_overworld_player() -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	var spawn: Marker3D = $Town/OverworldSpawn
	var player: Node3D = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = spawn.global_position
	player.global_rotation = spawn.global_rotation
	_player = player
	return player


func _setup_duel() -> void:
	_duel_manager = DUEL_MANAGER_SCRIPT.new()
	_duel_manager.name = "DuelManager"
	add_child(_duel_manager)
	_player = _spawn_player()
	_duel_manager.preload_opponent($Town, _player)


func _setup_target() -> void:
	_target_manager = TARGET_MANAGER_SCRIPT.new()
	_target_manager.name = "TargetManager"
	add_child(_target_manager)
	_player = _spawn_player()


func _ensure_practice_targets() -> void:
	var targets := get_node_or_null("Town/PracticeTargets")
	if targets == null:
		targets = Node3D.new()
		targets.name = "PracticeTargets"
		$Town.add_child(targets)

	if targets.get_node_or_null("PracticeFence") != null:
		return

	var fence: Node3D = PRACTICE_FENCE_SCENE.instantiate()
	fence.name = "PracticeFence"
	targets.add_child(fence)
	fence.position = Vector3(0.0, 0.0, -8.0)


func respawn_duel_player() -> Node3D:
	if _player != null:
		_player.queue_free()
		_player = null
	return _spawn_player()


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func _spawn_player() -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	var spawn: Marker3D = $Town/DuelLane/PlayerSpawn
	var player: Node3D = GROYPER_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = spawn.global_position
	player.rotation.y = PI
	if player.has_method("sync_stance_anchor"):
		player.sync_stance_anchor()

	if GameState.selected_game_mode == GameState.GameMode.DUEL and player.has_method("enable_duel_mode"):
		player.enable_duel_mode(true)
	elif GameState.selected_game_mode == GameState.GameMode.TARGET and player.has_method("enable_target_mode"):
		player.enable_target_mode(true)

	if has_node("CameraRig"):
		$CameraRig.queue_free()

	_player = player
	return player
