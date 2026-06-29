extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_PLAYER_SCENE := preload("res://characters/groyper/groyper_player.tscn")
const GROYPER_OVERWORLD_PLAYER_SCENE := preload("res://characters/groyper/groyper_overworld_player.tscn")
const PRACTICE_FENCE_SCENE := preload("res://gameplay/targets/practice_fence.tscn")
const BUILDING_MATERIAL_APPLIER := preload("res://Assets/World/Buildings/building_material_applier.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const TERRAIN_COLLISION := preload("res://gameplay/world/terrain_collision.gd")
const DUEL_MANAGER_SCRIPT := preload("res://gameplay/duel/duel_manager.gd")
const TARGET_MANAGER_SCRIPT := preload("res://gameplay/target/target_manager.gd")
const TUMBLEWEED_SCENE := preload("res://gameplay/duel/tumbleweed.tscn")
const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const BANDIT_NPC_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const WEAPON_PICKUP_SCENE := preload("res://gameplay/world/weapon_pickup.tscn")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const GROUND_BIRD_SCENE := preload("res://characters/animals/ground_bird.tscn")
const COW_SCENE := preload("res://characters/animals/cow.tscn")
const TALL_GRASS_SCENE := preload("res://characters/animals/tall_grass.tscn")
const BANDIT_STANDOFF_SCENARIO_SCENE := preload("res://gameplay/scenarios/bandit_standoff_scenario.tscn")

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _practice_targets: Node3D = $Town/PracticeTargets
@onready var _duel_lane: Node3D = $Town/DuelLane

var _player: Node3D
var _duel_manager: Node
var _target_manager: Node
var _opening_tumbleweed: Node3D


func _ready() -> void:
	GameAudio.play_stage_birds(self)
	BUILDING_MATERIAL_APPLIER.apply_to($Town)
	WOOD_BULLET_COVER.apply_to($Town)
	WOOD_BULLET_COVER.apply_to(self)
	TERRAIN_COLLISION.apply_to($desert_plane)
	_wire_shop_doors()
	_fade_overlay.modulate.a = 1.0
	_ensure_practice_targets()
	_spawn_town_horses()
	_spawn_town_birds()
	_spawn_town_grazing_grass()
	_spawn_town_cows()

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
	if GameState.overworld_scenario_id == "bandit_standoff":
		_setup_bandit_standoff_scenario()
	else:
		_player = _spawn_overworld_player()
		_spawn_town_npcs()
		_spawn_cart_encounters()
		_spawn_lasso_pickup_near_spawn()


func _setup_bandit_standoff_scenario() -> void:
	var scenario: Node3D = BANDIT_STANDOFF_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	var player_spawn: Marker3D = scenario.call("setup", self, $Town)
	_player = _spawn_overworld_player_at(player_spawn)
	_spawn_lasso_pickup_near_spawn()


func _spawn_overworld_player_at(spawn: Marker3D) -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	var player: Node3D = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_position = spawn.global_position
	player.global_rotation = spawn.global_rotation
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	_player = player
	return player


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

	_spawn_groyper_townspeople()


func _spawn_groyper_townspeople() -> void:
	const GROYPER_NPC_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
	var spawns_root := get_node_or_null("Town/GroyperTownSpawns") as Node3D
	if spawns_root == null:
		push_warning("Stage1: missing Town/GroyperTownSpawns.")
		return

	var town := $Town

	for child in spawns_root.get_children():
		if not child is Marker3D:
			continue

		var marker := child as Marker3D
		var npc: Node3D = GROYPER_NPC_SCENE.instantiate()
		town.add_child(npc)
		npc.global_position = marker.global_position
		npc.global_rotation = marker.global_rotation


func _spawn_cart_encounters() -> void:
	_spawn_bandits_near_marker("Cart_2/pillage")
	_spawn_weapon_pickup_at_marker("Cart_2/cactus6/rifle", GroyperWeapons.Id.AWP)


func _spawn_bandits_near_marker(marker_path: String) -> void:
	var marker := get_node_or_null(marker_path) as Marker3D
	if marker == null:
		push_warning("Stage1: missing bandit spawn marker at %s." % marker_path)
		return

	var spawn_parent := marker.get_parent()
	var offsets := [
		Vector3(-2.5, 0.0, 0.0),
		Vector3(2.5, 0.0, 0.0),
		Vector3(0.0, 0.0, -2.5),
	]

	for offset in offsets:
		var bandit: Node3D = BANDIT_NPC_SCENE.instantiate()
		spawn_parent.add_child(bandit)
		bandit.global_position = marker.global_position + marker.global_transform.basis * offset
		bandit.global_rotation = marker.global_rotation


func _spawn_weapon_pickup_at_marker(marker_path: String, weapon_id: GroyperWeapons.Id) -> void:
	var marker := get_node_or_null(marker_path) as Marker3D
	if marker == null:
		push_warning("Stage1: missing weapon pickup marker at %s." % marker_path)
		return

	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = weapon_id
	marker.get_parent().add_child(pickup)
	pickup.global_transform = marker.global_transform


func _spawn_lasso_pickup_near_spawn() -> void:
	var spawn_pos: Vector3
	var spawn_rot_y: float
	if _player != null:
		spawn_pos = _player.global_position
		spawn_rot_y = _player.global_rotation.y
	else:
		var spawn := get_node_or_null("Town/OverworldSpawn") as Marker3D
		if spawn == null:
			push_warning("Stage1: missing Town/OverworldSpawn for lasso pickup.")
			return
		spawn_pos = spawn.global_position
		spawn_rot_y = spawn.global_rotation.y

	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = GroyperWeapons.Id.LASSO
	$Town.add_child(pickup)
	pickup.global_position = spawn_pos + Vector3(2.5, 0.0, 2.0)
	pickup.global_rotation.y = spawn_rot_y


func _spawn_town_horses() -> void:
	var horses_root := get_node_or_null("Town/Horses") as Node3D
	if horses_root == null:
		horses_root = Node3D.new()
		horses_root.name = "Horses"
		$Town.add_child(horses_root)

	_spawn_free_horse(horses_root, Vector3(6.5, 0.0, 5.0), 1, StupidHorseScript.RoamMode.STREET, 501)
	_spawn_free_horse(horses_root, Vector3(-9.0, 0.0, 44.0), 3, StupidHorseScript.RoamMode.FREE, 733)
	_spawn_free_horse(horses_root, Vector3(15.5, 0.0, -16.0), 4, StupidHorseScript.RoamMode.FREE, 881)
	_spawn_free_horse(horses_root, Vector3(-5.5, 0.0, -32.0), 0, StupidHorseScript.RoamMode.FREE, 999)


func _spawn_town_birds() -> void:
	var birds_root := get_node_or_null("Town/Birds") as Node3D
	if birds_root == null:
		birds_root = Node3D.new()
		birds_root.name = "Birds"
		$Town.add_child(birds_root)

	var spawns: Array[Dictionary] = [
		{"pos": Vector3(-18.0, 0.05, 52.0), "radius": 2.8, "seed": 101},
		{"pos": Vector3(-14.5, 0.05, 48.5), "radius": 2.2, "seed": 202},
		{"pos": Vector3(4.0, 0.05, 8.0), "radius": 3.0, "seed": 303},
		{"pos": Vector3(-3.5, 0.05, 18.0), "radius": 2.5, "seed": 404},
		{"pos": Vector3(12.0, 0.05, -10.0), "radius": 3.2, "seed": 505},
		{"pos": Vector3(-8.0, 0.05, -24.0), "radius": 2.6, "seed": 606},
		{"pos": Vector3(20.0, 0.05, 36.0), "radius": 2.4, "seed": 707},
		{"pos": Vector3(-24.0, 0.05, 12.0), "radius": 2.0, "seed": 808},
		{"pos": Vector3(0.5, 0.05, 42.0), "radius": 2.8, "seed": 909},
		{"pos": Vector3(16.5, 0.05, 22.0), "radius": 2.3, "seed": 111},
	]

	for spawn_info in spawns:
		_spawn_ground_bird(birds_root, spawn_info)


func _spawn_town_grazing_grass() -> void:
	var grass_root := get_node_or_null("Town/GrazingGrass") as Node3D
	if grass_root == null:
		grass_root = Node3D.new()
		grass_root.name = "GrazingGrass"
		$Town.add_child(grass_root)

	var patches: Array[Vector3] = [
		Vector3(-13.0, 0.05, 48.0),
		Vector3(-8.5, 0.05, 52.0),
		Vector3(-11.0, 0.05, 44.0),
		Vector3(18.0, 0.05, 40.0),
		Vector3(21.5, 0.05, 44.0),
		Vector3(16.0, 0.05, 46.0),
		Vector3(-6.0, 0.05, -40.0),
		Vector3(-9.5, 0.05, -36.0),
		Vector3(-3.5, 0.05, -34.0),
	]

	for patch_pos in patches:
		var grass: Node3D = TALL_GRASS_SCENE.instantiate()
		grass_root.add_child(grass)
		grass.position = patch_pos
		grass.rotation.y = randf_range(0.0, TAU)


func _spawn_town_cows() -> void:
	var cows_root := get_node_or_null("Town/Cows") as Node3D
	if cows_root == null:
		cows_root = Node3D.new()
		cows_root.name = "Cows"
		$Town.add_child(cows_root)

	var spawns: Array[Dictionary] = [
		{"pos": Vector3(-10.0, 0.0, 50.0), "seed": 704, "radius": 5.5},
		{"pos": Vector3(19.0, 0.0, 42.0), "seed": 805, "radius": 4.5},
		{"pos": Vector3(-7.0, 0.0, -38.0), "seed": 906, "radius": 4.0},
	]

	for spawn_info in spawns:
		var spawn_pos: Vector3 = spawn_info["pos"]
		var cow: Node3D = COW_SCENE.instantiate()
		cow.set("personality_seed", spawn_info.get("seed", -1))
		cow.set("roam_center", spawn_pos)
		cow.set("roam_radius", spawn_info.get("radius", 6.0))
		cows_root.add_child(cow)
		cow.position = spawn_pos


func _spawn_ground_bird(parent: Node3D, spawn_info: Dictionary) -> void:
	var spawn_pos: Vector3 = spawn_info["pos"]
	var bird: Node3D = GROUND_BIRD_SCENE.instantiate()
	bird.set("roam_center", spawn_pos)
	bird.set("roam_radius", spawn_info.get("radius", 3.0))
	bird.set("personality_seed", spawn_info.get("seed", -1))
	bird.set("ground_height", spawn_pos.y)
	parent.add_child(bird)
	bird.position = spawn_pos


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
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
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


func _wire_shop_doors() -> void:
	var entrance_marker := get_node_or_null("Town/WestRow/Build_04/ShopEntranceMarker") as Marker3D
	var entrance := get_node_or_null("Town/WestRow/Build_04/ShopEntranceMarker/WestShopEntrance")
	var interior_spawn := get_node_or_null("ShopInteriors/WestShopInterior/InteriorSpawn") as Marker3D
	var exit_door := get_node_or_null("ShopInteriors/WestShopInterior/ExitDoor")
	if entrance == null or entrance_marker == null or interior_spawn == null or exit_door == null:
		push_warning("Stage1: shop door wiring incomplete.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	exit_door.set("destination", exit_door.get_path_to(entrance_marker))


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
