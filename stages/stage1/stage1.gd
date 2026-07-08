extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_PLAYER_SCENE := preload("res://characters/groyper/groyper_player.tscn")
const GROYPER_OVERWORLD_PLAYER_SCENE := preload("res://characters/groyper/groyper_overworld_player.tscn")
const PRACTICE_FENCE_SCENE := preload("res://gameplay/targets/practice_fence.tscn")
const STAGE1_VISUAL_SETUP := preload("res://stages/stage1/stage1_visual_setup.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const TERRAIN_COLLISION := preload("res://gameplay/world/terrain_collision.gd")
const DUEL_MANAGER_SCRIPT := preload("res://gameplay/duel/duel_manager.gd")
const TARGET_MANAGER_SCRIPT := preload("res://gameplay/target/target_manager.gd")
const TUMBLEWEED_SCENE := preload("res://gameplay/duel/tumbleweed.tscn")
const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HORSEY_HORSE_SCENE := preload("res://characters/animals/horsey_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const BANDIT_NPC_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const WEAPON_PICKUP_SCENE := preload("res://gameplay/world/weapon_pickup.tscn")
const KNIFE_PICKUP_SCENE := preload("res://gameplay/world/knife_pickup.tscn")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const GROUND_BIRD_SCENE := preload("res://characters/animals/ground_bird.tscn")
const COW_SCENE := preload("res://characters/animals/cow.tscn")
const TALL_GRASS_SCENE := preload("res://characters/animals/tall_grass.tscn")
const BANDIT_STANDOFF_SCENARIO_SCENE := preload("res://gameplay/scenarios/bandit_standoff_scenario.tscn")
const BanditAmbushScript := preload("res://gameplay/world/bandit_ambush.gd")
const HomePracticeFenceScript := preload("res://gameplay/world/home_practice_fence.gd")
const SoloPracticeManagerScript := preload("res://gameplay/target/solo_practice_manager.gd")
const MOUNTED_STANDOFF_SCENARIO_SCENE := preload("res://gameplay/scenarios/mounted_standoff_scenario.tscn")
const ENGINES_RAID_SCENARIO_SCENE := preload("res://gameplay/scenarios/engines_raid_scenario.tscn")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const TownNavSetup := preload("res://gameplay/navigation/town_nav_setup.gd")
const TownConfig := preload("res://gameplay/world/town_config.gd")
const StageAmbientAudio := preload("res://gameplay/audio/stage_ambient_audio.gd")
const TownBirdDayNight := preload("res://gameplay/world/town_bird_day_night.gd")
const QUEST_COW_SCENE := preload("res://characters/animals/quest_cow.tscn")
const OIL_DRUM_SCENE := preload("res://gameplay/world/oil_drum/oil_drum.tscn")
const BALDWIN_NPC_SCENE := preload("res://characters/baldwin/baldwin_npc.tscn")

const LOST_COW_SPAWN_OFFSETS: Array[Vector3] = [
	Vector3(-1.2, 0.0, 0.8),
	Vector3(1.4, 0.0, -0.6),
]

const OIL_DRUM_SPAWNS: Array[Vector3] = [
	Vector3(-3.5, 0.0, -8.0),
	Vector3(4.0, 0.0, -4.0),
	Vector3(-2.0, 0.0, 6.0),
	Vector3(3.2, 0.0, 14.0),
]

const SCATTER_PROPS_PATH := "Environment/ScatterProps"
const SHERIFF_RAID_DELAY := 3.0


func _scatter_prop(prop_name: String) -> Node:
	return get_node_or_null("%s/%s" % [SCATTER_PROPS_PATH, prop_name])

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay
@onready var _practice_targets: Node3D = $Town/PracticeTargets
@onready var _duel_lane: Node3D = $Town/DuelLane

var _player: Node3D
var _duel_manager: Node
var _target_manager: Node
var _opening_tumbleweed: Node3D
var _town_raid_scenario: EnginesRaidScenario
var _town_raid_started := false
var _sheriff_npc: Node3D
var _sheriff_raid_armed := false
var _solo_practice_manager: SoloPracticeManager


func _exit_tree() -> void:
	DayNightCycle.unbind_outdoor_scene($Sun)


func _ready() -> void:
	DayNightCycle.bind_outdoor_scene($Sun)
	_setup_town_wall_lights()
	_setup_stage_ambient_audio()
	STAGE1_VISUAL_SETUP.apply_materials(self)
	WOOD_BULLET_COVER.apply_to($Town)
	WOOD_BULLET_COVER.apply_to(self)
	var desert_plane := _scatter_prop("desert_plane")
	if desert_plane != null:
		TERRAIN_COLLISION.apply_to(desert_plane)
	_setup_environment_collision()
	_setup_town_navigation()
	_wire_shop_doors()
	_wire_blacksmith_doors()
	_wire_home_doors()
	_fade_overlay.modulate.a = 1.0
	_ensure_practice_targets()
	if GameState.overworld_scenario_id not in [
		GameState.SCENARIO_MOUNTED_STANDOFF,
		GameState.SCENARIO_ENGINES_RAID,
	]:
		_spawn_town_horses()
	_spawn_town_birds()
	_spawn_home_birds()
	_setup_town_bird_day_night()
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


func _setup_stage_ambient_audio() -> void:
	var ambient := StageAmbientAudio.new()
	ambient.name = "StageAmbientAudio"
	add_child(ambient)


func _setup_town_bird_day_night() -> void:
	var roost := TownBirdDayNight.new()
	roost.name = "TownBirdDayNight"
	add_child(roost)


func _setup_town_wall_lights() -> void:
	for light_index in range(2, 10):
		var wall_light := get_node_or_null("WallLight%d" % light_index)
		if wall_light == null:
			continue
		_set_fire_respect_day_night(wall_light)
	var altar := get_node_or_null("Altar")
	if altar != null:
		_set_fire_respect_day_night(altar)


func _set_fire_respect_day_night(light_root: Node) -> void:
	var fire := light_root.get_node_or_null("Fire")
	if fire != null and fire.has_method("set_respect_day_night"):
		fire.call("set_respect_day_night", true)


func _setup_environment_collision() -> void:
	var roots: Array[String] = [
		"cliff_base",
		"cliff_base2",
		"cube_cliff",
		"cube_cliff2",
		"Ruined_Cliff",
		"cube_mountain",
		"cube_mountain2",
		"cube_mountain3",
		"cube_mountain4",
		"Large_sand_mountain2",
		"sand_mountain",
		"sand_mountain2",
		"sand_mountain3",
		"smallcubemountain",
		"Small_sand_mountain",
		"Small_sand_mountain2",
		"Small_sand_mountain3",
		"Small_sand_mountain4",
	]
	for node_path: String in roots:
		var root := _scatter_prop(node_path) as Node3D
		if root == null:
			root = get_node_or_null(node_path) as Node3D
		if root != null:
			TERRAIN_COLLISION.apply_to(root)


func _setup_town_navigation() -> void:
	var nav_setup := TownNavSetup.new()
	nav_setup.name = "TownNavigation"
	add_child(nav_setup)
	nav_setup.configure_and_bake(self, $Town.global_position, Vector3(200.0, 14.0, 200.0))


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
	match GameState.overworld_scenario_id:
		GameState.SCENARIO_BANDIT_STANDOFF:
			_setup_bandit_standoff_scenario()
		GameState.SCENARIO_MOUNTED_STANDOFF:
			_setup_mounted_standoff_scenario()
		GameState.SCENARIO_ENGINES_RAID:
			_setup_engines_raid_scenario()
		GameState.SCENARIO_FARMER_COW_QUEST:
			_setup_farmer_cow_quest()
		_:
			_setup_normal_town()


func _setup_normal_town() -> void:
	var fresh_home_start := false
	if AdventureSave.should_restore_on_stage_load():
		GameState.overworld_scenario_id = AdventureSave.get_overworld_scenario_id()
		_player = _spawn_overworld_player_at_save()
		AdventureSave.consume_pending_town_restore()
	else:
		fresh_home_start = true
		_player = _spawn_overworld_player_at_home()
	_spawn_town_name_sign()
	_spawn_town_npcs()
	_spawn_ruins_guide()
	_spawn_cart_encounters()
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_town_oil_drums()
	_set_farmer_cow_quest_active(false)
	_spawn_baldwin_companion()
	_spawn_horsey()
	_setup_home_practice_fence()
	if fresh_home_start:
		_setup_bandit_ambush()
	call_deferred("_setup_sheriff_raid_trigger")


func _spawn_baldwin_companion() -> void:
	if not CompanionManager.is_recruited(CompanionManager.COMPANION_BALDWIN):
		return
	if _player == null:
		return
	for node in get_tree().get_nodes_in_group("baldwin_npc"):
		if node is BaldwinNpc:
			(node as BaldwinNpc).call_deferred("_begin_companion_mode", _player)
			return

	var companion: BaldwinNpc = BALDWIN_NPC_SCENE.instantiate()
	add_child(companion)
	var offset := _player.global_transform.basis.x * 1.5
	companion.global_position = _player.global_position + Vector3(offset.x, 0.0, offset.z)
	companion.call_deferred("_begin_companion_mode", _player)
	companion.call_deferred("snap_to_floor")


func _setup_farmer_cow_quest() -> void:
	_player = _spawn_overworld_player()
	_spawn_town_name_sign()
	_spawn_town_npcs()
	_spawn_cart_encounters()
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_lost_quest_cows()
	_spawn_town_oil_drums()
	_set_farmer_cow_quest_active(true)
	CowWrangleQuest.reset_quest()


func _spawn_lost_quest_cows() -> void:
	var marker := _find_cows_lost_marker()
	if marker == null:
		push_warning("Stage1: missing CowsLost1 marker under Town for lost cows.")
		return

	var lost_root := get_node_or_null("Town/LostCows") as Node3D
	if lost_root == null:
		lost_root = Node3D.new()
		lost_root.name = "LostCows"
		$Town.add_child(lost_root)

	for child in lost_root.get_children():
		child.free()

	for i in LOST_COW_SPAWN_OFFSETS.size():
		var cow: Node3D = QUEST_COW_SCENE.instantiate()
		cow.name = "LostCow_%d" % (i + 1)
		lost_root.add_child(cow)
		cow.global_position = marker.global_position + marker.global_transform.basis * LOST_COW_SPAWN_OFFSETS[i]
		cow.global_rotation = marker.global_rotation


func _spawn_town_oil_drums() -> void:
	var drum_root := get_node_or_null("Town/OilDrums") as Node3D
	if drum_root == null:
		drum_root = Node3D.new()
		drum_root.name = "OilDrums"
		$Town.add_child(drum_root)

	for child in drum_root.get_children():
		child.free()

	for i in OIL_DRUM_SPAWNS.size():
		var drum: RigidBody3D = OIL_DRUM_SCENE.instantiate()
		drum.name = "OilDrum_%d" % (i + 1)
		drum_root.add_child(drum)
		drum.global_position = OIL_DRUM_SPAWNS[i]
		if drum.has_method("snap_to_floor"):
			drum.call("snap_to_floor")


func _find_cows_lost_marker() -> Marker3D:
	return get_node_or_null("Town/CowsLost1") as Marker3D


func _set_farmer_cow_quest_active(active: bool) -> void:
	var quest_root := get_node_or_null("Town/FarmerCowQuest") as Node3D
	if quest_root != null:
		quest_root.visible = active
		quest_root.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if active:
			var farmer := quest_root.get_node_or_null("FarmerNpc")
			if farmer != null and farmer.has_method("reset_for_quest"):
				farmer.call("reset_for_quest")

	var lost_root := get_node_or_null("Town/LostCows") as Node3D
	if lost_root != null:
		lost_root.visible = active
		lost_root.process_mode = Node.PROCESS_MODE_INHERIT if active else Node.PROCESS_MODE_DISABLED
		if active:
			for child in lost_root.get_children():
				if child.has_method("reset_quest_state"):
					child.call("reset_quest_state")

	var corral := get_node_or_null("Town/Corrals/CowCorral")
	if corral != null:
		corral.set("owner_faction_id", FactionIds.BECKER_BOYS if active else &"")


func _setup_bandit_standoff_scenario() -> void:
	var scenario: Node3D = BANDIT_STANDOFF_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	var player_spawn: Marker3D = scenario.call("setup", self, $Town)
	_player = _spawn_overworld_player_at(player_spawn)
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_knife_pickup_near_spawn()


func _setup_engines_raid_scenario() -> void:
	var scenario: Node3D = ENGINES_RAID_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	var player_spawn: Marker3D = scenario.call("setup", self, $Town)
	_player = _spawn_overworld_player_at(player_spawn)
	scenario.call_deferred("begin_raid")
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_knife_pickup_near_spawn()


func begin_town_engines_raid() -> void:
	if _town_raid_started:
		return
	_town_raid_started = true

	var scenario: EnginesRaidScenario = ENGINES_RAID_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	scenario.setup_town_raid($Town)
	scenario.call_deferred("begin_raid")
	_town_raid_scenario = scenario


func _setup_sheriff_raid_trigger() -> void:
	var sheriff := _sheriff_npc if is_instance_valid(_sheriff_npc) else _find_sheriff_npc()
	if sheriff == null or _player == null:
		push_warning(
			"Stage1: sheriff raid trigger skipped sheriff=%s player=%s"
			% [sheriff, _player]
		)
		return

	if sheriff.has_signal("dialog_finished") \
			and not sheriff.dialog_finished.is_connected(_on_sheriff_dialog_finished_for_raid):
		sheriff.dialog_finished.connect(_on_sheriff_dialog_finished_for_raid)


func _on_sheriff_dialog_finished_for_raid(_player_node: Node3D) -> void:
	arm_sheriff_raid_after_dialog()


func arm_sheriff_raid_after_dialog() -> void:
	if _sheriff_raid_armed or _town_raid_started:
		return
	if DeputyQuest.raid_finished:
		return

	_sheriff_raid_armed = true
	var timer := get_tree().create_timer(SHERIFF_RAID_DELAY)
	timer.timeout.connect(_on_sheriff_raid_delay_finished)


func _on_sheriff_raid_delay_finished() -> void:
	_sheriff_raid_armed = false
	if _town_raid_started or DeputyQuest.raid_finished:
		return
	begin_town_engines_raid()


func _find_sheriff_npc() -> Node3D:
	for node in get_tree().get_nodes_in_group("town_sheriff"):
		if node is Node3D:
			return node as Node3D
	return null


func _setup_mounted_standoff_scenario() -> void:
	var scenario: Node3D = MOUNTED_STANDOFF_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	var player_spawn: Marker3D = scenario.call("setup", self, $Town)
	_player = _spawn_overworld_player_at(player_spawn)
	scenario.call("mount_player", _player)
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_knife_pickup_near_spawn()


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
	_sheriff_npc = sheriff
	add_child(sheriff)
	sheriff.global_position = spawn.global_position
	sheriff.global_rotation = spawn.global_rotation

	_spawn_groyper_townspeople()
	_spawn_engines_npc()
	_spawn_uncle_toad()
	_spawn_groypettes()


func _spawn_engines_npc() -> void:
	const ENGINES_NPC_SCENE := preload("res://characters/fast/engines_npc.tscn")
	var spawn := get_node_or_null("Town/FastTownSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/FastTownSpawn.")
		return

	var npc: Node3D = ENGINES_NPC_SCENE.instantiate()
	$Town.add_child(npc)
	npc.global_position = spawn.global_position
	npc.global_rotation = spawn.global_rotation


func _spawn_uncle_toad() -> void:
	const UNCLE_TOAD_SCENE := preload("res://characters/uncle_toad/uncle_toad_npc.tscn")
	var spawn := get_node_or_null("Town/UncleToadSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/UncleToadSpawn.")
		return

	var npc: Node3D = UNCLE_TOAD_SCENE.instantiate()
	$Town.add_child(npc)
	npc.global_position = spawn.global_position
	npc.global_rotation = spawn.global_rotation


func _spawn_groypettes() -> void:
	const GROYPETTE_SCENE := preload("res://characters/groypette/groypette_npc.tscn")
	var spawns_root := get_node_or_null("Town/GroypetteSpawns") as Node3D
	if spawns_root == null:
		push_warning("Stage1: missing Town/GroypetteSpawns.")
		return

	for child in spawns_root.get_children():
		if not child is Marker3D:
			continue
		var npc: Node3D = GROYPETTE_SCENE.instantiate()
		$Town.add_child(npc)
		npc.global_position = child.global_position
		npc.global_rotation = child.global_rotation


func _spawn_town_name_sign() -> void:
	var anchor := get_node_or_null("Town/OverworldSpawn") as Marker3D
	if anchor == null:
		push_warning("Stage1: missing Town/OverworldSpawn for town name sign.")
		return

	var sign := Label3D.new()
	sign.name = "TownNameSign"
	sign.text = TownConfig.BECKER_RANCH
	sign.font_size = 72
	sign.modulate = Color(0.94, 0.86, 0.62, 1.0)
	sign.outline_size = 8
	sign.outline_modulate = Color(0.18, 0.1, 0.04, 1.0)
	sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign.no_depth_test = true
	sign.position = anchor.position + Vector3(0.0, 5.5, 10.0)
	sign.rotation_degrees = Vector3(0.0, 180.0, 0.0)
	$Town.add_child(sign)


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


func _setup_bandit_ambush() -> void:
	if BanditAmbushProgress.completed:
		return

	var marker := get_node_or_null("Town/WestRow/Build_07/BanditAmbush") as Marker3D
	if marker == null:
		push_warning("Stage1: missing Town/WestRow/Build_07/BanditAmbush marker.")
		return

	var ambush: BanditAmbush = BanditAmbushScript.new()
	ambush.name = "BanditAmbush"
	add_child(ambush)
	ambush.setup(marker, _player)


func _setup_home_practice_fence() -> void:
	var marker := get_node_or_null("Town/WestRow/Build_07/HomeTargetPractice") as Marker3D
	if marker == null:
		push_warning("Stage1: missing Town/WestRow/Build_07/HomeTargetPractice marker.")
		return

	var spawn_parent := marker.get_parent() as Node3D
	if spawn_parent == null:
		return
	if spawn_parent.get_node_or_null("HomePracticeFence") != null:
		return

	var spawn := Marker3D.new()
	spawn.name = "HomePracticeSpawn"
	spawn_parent.add_child(spawn)
	spawn.global_position = marker.global_position + marker.global_transform.basis * Vector3(0.0, 0.0, 3.0)
	spawn.global_rotation = marker.global_rotation

	var fence_root: Node3D = PRACTICE_FENCE_SCENE.instantiate()
	fence_root.name = "HomePracticeFence"
	fence_root.set_script(HomePracticeFenceScript)
	spawn_parent.add_child(fence_root)
	fence_root.global_position = marker.global_position
	fence_root.global_rotation = marker.global_rotation

	if _solo_practice_manager == null:
		_solo_practice_manager = SoloPracticeManagerScript.new()
		_solo_practice_manager.name = "SoloPracticeManager"
		add_child(_solo_practice_manager)
	_solo_practice_manager.configure_spawn(spawn)

	var fence := fence_root as HomePracticeFence
	if fence != null:
		fence.setup(_solo_practice_manager)


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
	var spawn := get_node_or_null("Town/OverworldSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/OverworldSpawn for lasso pickup.")
		return

	var spawn_pos := _player.global_position if _player != null else spawn.global_position
	var spawn_rot_y := _player.global_rotation.y if _player != null else spawn.global_rotation.y

	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = GroyperWeapons.Id.LASSO
	$Town.add_child(pickup)
	pickup.global_position = spawn_pos + spawn.global_transform.basis * Vector3(2.5, 0.0, 2.0)
	pickup.global_rotation.y = spawn_rot_y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _spawn_bow_pickup_near_spawn() -> void:
	var marker := get_node_or_null("Town/BowPickupSpawn") as Marker3D
	if marker == null:
		push_warning("Stage1: missing Town/BowPickupSpawn for bow pickup.")
		return

	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = GroyperWeapons.Id.BOW
	$Town.add_child(pickup)
	pickup.global_transform = marker.global_transform
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _spawn_knife_pickup_near_spawn() -> void:
	if PlayerInventory.has_knife:
		return

	var spawn := get_node_or_null("Town/OverworldSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/OverworldSpawn for knife pickup.")
		return

	var spawn_pos := _player.global_position if _player != null else spawn.global_position
	var spawn_rot_y := _player.global_rotation.y if _player != null else spawn.global_rotation.y

	var pickup = KNIFE_PICKUP_SCENE.instantiate()
	$Town.add_child(pickup)
	# Lasso sits at (2.5, 0, 2.0) — knife one step to its side.
	pickup.global_position = spawn_pos + spawn.global_transform.basis * Vector3(1.2, 0.0, 2.0)
	pickup.global_rotation.y = spawn_rot_y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


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


func _spawn_home_birds() -> void:
	var birds_root := get_node_or_null("Town/Birds") as Node3D
	if birds_root == null:
		birds_root = Node3D.new()
		birds_root.name = "Birds"
		$Town.add_child(birds_root)

	var spawn_parent := get_node_or_null("Town/WestRow/Build_07") as Node3D
	if spawn_parent == null:
		push_warning("Stage1: missing Town/WestRow/Build_07 for home birds.")
		return

	var spawns: Array[Dictionary] = [
		{"marker": "HomeBirdSpawn1", "radius": 2.2, "seed": 1001},
		{"marker": "HomeBirdSpawn2", "radius": 2.0, "seed": 1002},
		{"marker": "HomeBirdSpawn3", "radius": 2.5, "seed": 1003},
		{"marker": "HomeBirdSpawn4", "radius": 2.3, "seed": 1004},
	]

	for spawn_info in spawns:
		var marker := spawn_parent.get_node_or_null(spawn_info["marker"]) as Marker3D
		if marker == null:
			push_warning("Stage1: missing %s marker for home birds." % spawn_info["marker"])
			continue
		var spawn_pos := marker.global_position
		spawn_pos.y += 0.05
		_spawn_ground_bird(birds_root, {
			"pos": spawn_pos,
			"radius": spawn_info.get("radius", 2.5),
			"seed": spawn_info.get("seed", -1),
		})


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

	var spawn := get_node_or_null("ShopInteriors/HomeInterior/InteriorSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Home interior spawn, falling back to TownSpawn.")
		spawn = get_node_or_null("Town/TownSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/TownSpawn marker.")
		spawn = $Town/OverworldSpawn
	return _spawn_overworld_player_at_marker(spawn)


func _spawn_overworld_player_at_home() -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	var spawn := get_node_or_null("ShopInteriors/HomeInterior/InteriorSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Home interior spawn, falling back to TownSpawn.")
		return _spawn_overworld_player()

	PlayerInventory.reset_for_home_start()
	var player := _spawn_overworld_player_at_marker(spawn)
	if player != null and player.has_method("prepare_for_home_start"):
		player.call_deferred("prepare_for_home_start")
	ShopSession.start_home_music()
	return player


func _spawn_overworld_player_at_save() -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	var player := _spawn_overworld_player_at_transform(AdventureSave.get_return_spawn_transform())
	AdventureSave.apply_to_player(player)
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	return player


func _spawn_overworld_player_at_marker(spawn: Marker3D) -> Node3D:
	if spawn == null:
		return null
	return _spawn_overworld_player_at_transform(_overworld_spawn_transform_from_marker(spawn))


func _overworld_spawn_transform_from_marker(spawn: Marker3D) -> Transform3D:
	# Markers parented under scaled props inherit a skewed basis — never copy the
	# full global_transform. Position + fixed PI body yaw keeps the body/camera pair intact.
	var position := spawn.global_position
	var basis := Basis.from_euler(Vector3(0.0, PI, 0.0))
	return Transform3D(basis, position)


func _spawn_overworld_player_at_transform(spawn_transform: Transform3D) -> Node3D:
	var player: Node3D = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(player)
	player.global_transform = spawn_transform
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	_player = player
	return player


func _spawn_ruins_guide() -> void:
	const RUINS_GUIDE_SCENE := preload("res://characters/groyper/ruins_guide_npc.tscn")
	var spawn := get_node_or_null("Environment/ScatterProps/cliff_base/RuinsStart") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Environment/ScatterProps/cliff_base/RuinsStart marker.")
		return

	var guide: Node3D = RUINS_GUIDE_SCENE.instantiate()
	add_child(guide)
	guide.global_transform = spawn.global_transform


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


func _wire_blacksmith_doors() -> void:
	var entrance_marker := get_node_or_null(
		"Town/WestRow/Build_05/BlacksmithEntranceMarker"
	) as Marker3D
	var entrance := get_node_or_null(
		"Town/WestRow/Build_05/BlacksmithEntranceMarker/WestBlacksmithEntrance"
	)
	var interior_spawn := get_node_or_null(
		"ShopInteriors/BlacksmithInterior/InteriorSpawn"
	) as Marker3D
	var exit_door := get_node_or_null("ShopInteriors/BlacksmithInterior/ExitDoor")
	if entrance == null or entrance_marker == null or interior_spawn == null or exit_door == null:
		push_warning("Stage1: blacksmith door wiring incomplete.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	entrance.set("interior_music", ShopSession.SMITH_MUSIC)
	entrance.set("interior_music_volume_db", ShopSession.SMITH_MUSIC_VOLUME_DB)
	exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _wire_home_doors() -> void:
	var entrance_marker := get_node_or_null("Town/WestRow/Build_07/Home") as Marker3D
	var entrance := get_node_or_null("Town/WestRow/Build_07/Home/HomeEntrance")
	var interior_spawn := get_node_or_null("ShopInteriors/HomeInterior/InteriorSpawn") as Marker3D
	var exit_door := get_node_or_null("ShopInteriors/HomeInterior/ExitDoor")
	if entrance == null or entrance_marker == null or interior_spawn == null or exit_door == null:
		push_warning("Stage1: home door wiring incomplete.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _spawn_horsey() -> void:
	if GameState.overworld_scenario_id in [
		GameState.SCENARIO_MOUNTED_STANDOFF,
		GameState.SCENARIO_ENGINES_RAID,
	]:
		return

	for node in get_tree().get_nodes_in_group("horsey"):
		if is_instance_valid(node):
			return

	var corral_marker := get_node_or_null("Town/WestRow/Build_07/HomeCorral") as Marker3D
	if corral_marker == null:
		push_warning("Stage1: missing HomeCorral marker.")
		return

	var stable_root := get_node_or_null("Town/HomeStable") as Node3D
	if stable_root == null:
		stable_root = Node3D.new()
		stable_root.name = "HomeStable"
		$Town.add_child(stable_root)

	var horse: Node3D = HORSEY_HORSE_SCENE.instantiate()
	stable_root.add_child(horse)
	horse.global_position = corral_marker.global_position
	horse.global_rotation = corral_marker.global_rotation
	horse.set("roam_center", corral_marker.global_position)
	horse.set("roam_half_extents", Vector2(3.5, 3.5))


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
