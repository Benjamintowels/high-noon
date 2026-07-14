extends Node3D

const FADE_IN_DURATION := 1.25
const GROYPER_PLAYER_SCENE := preload("res://characters/groyper/groyper_player.tscn")
const GROYPER_OVERWORLD_PLAYER_SCENE := preload("res://characters/groyper/groyper_overworld_player.tscn")
const PRACTICE_FENCE_SCENE := preload("res://gameplay/targets/practice_fence.tscn")
const STAGE1_VISUAL_SETUP := preload("res://stages/stage1/stage1_visual_setup.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const TERRAIN_COLLISION := preload("res://gameplay/world/terrain_collision.gd")
const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
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
const ARROW_AMMO_PICKUP_SCRIPT := preload("res://gameplay/world/arrow_ammo_pickup.gd")
const MELEE_WEAPON_PICKUP_SCENE := preload("res://gameplay/world/melee_weapon_pickup.tscn")
const DYNAMITE_PICKUP_SCENE := preload("res://gameplay/world/dynamite_pickup.tscn")
const BreakablePropSetupScript := preload("res://gameplay/world/breakable_prop_setup.gd")
const HAT_WORLD_PICKUP_SCRIPT := preload("res://characters/groyper/groyper_hat_world_pickup.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const GROUND_BIRD_SCENE := preload("res://characters/animals/ground_bird.tscn")
const COW_SCENE := preload("res://characters/animals/cow.tscn")
const TALL_GRASS_SCENE := preload("res://characters/animals/tall_grass.tscn")
const BANDIT_STANDOFF_SCENARIO_SCENE := preload("res://gameplay/scenarios/bandit_standoff_scenario.tscn")
const BanditAmbushScript := preload("res://gameplay/world/bandit_ambush.gd")
const CometCinematicScript := preload("res://gameplay/world/comet_cinematic.gd")
const CanyonGateTransitionScript := preload("res://gameplay/world/canyon_gate_transition.gd")
const CanyonBanditSpawnScript := preload("res://gameplay/world/canyon_bandit_spawn.gd")
const ChurchSkeletonAmbushScript := preload("res://gameplay/world/church_skeleton_ambush.gd")
const ChurchRecurveRewardScript := preload("res://gameplay/world/church_recurve_reward.gd")
const CHIEF_GETCHA_NPC_SCENE := preload("res://characters/chief_getcha/chief_getcha_npc.tscn")
const HomePracticeFenceScript := preload("res://gameplay/world/home_practice_fence.gd")
const SoloPracticeManagerScript := preload("res://gameplay/target/solo_practice_manager.gd")
const MOUNTED_STANDOFF_SCENARIO_SCENE := preload("res://gameplay/scenarios/mounted_standoff_scenario.tscn")
const ENGINES_RAID_SCENARIO_SCENE := preload("res://gameplay/scenarios/engines_raid_scenario.tscn")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")
const TownNavSetup := preload("res://gameplay/navigation/town_nav_setup.gd")
const StageAmbientAudio := preload("res://gameplay/audio/stage_ambient_audio.gd")
const TownBirdDayNight := preload("res://gameplay/world/town_bird_day_night.gd")
const QUEST_COW_SCENE := preload("res://characters/animals/quest_cow.tscn")
const OIL_DRUM_SCENE := preload("res://gameplay/world/oil_drum/oil_drum.tscn")
const BALDWIN_NPC_SCENE := preload("res://characters/baldwin/baldwin_npc.tscn")
const TownNpcSpawn := preload("res://gameplay/world/town_npc_spawn.gd")
const DistanceZoneCuller := preload("res://gameplay/world/distance_zone_culler.gd")
const StageZoneCuller := preload("res://gameplay/world/stage_zone_culler.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const AmbientAiFreezerScript := preload("res://gameplay/world/ambient_ai_freezer.gd")

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
var _church_zone_culler: DistanceZoneCuller
var _church_collision_ready := false
var _canyon_gate_transition: CanyonGateTransition
var _canyon_bandit_spawns: Array = []


func _exit_tree() -> void:
	DayNightCycle.unbind_outdoor_scene($Sun)


func _ready() -> void:
	# Pay all FX sprite-frame PNG loads during stage load instead of on the
	# first shot/hit of a fight.
	FxCatalogScript.warm_all()
	DayNightCycle.bind_outdoor_scene($Sun)
	_setup_town_wall_lights()
	_setup_stage_ambient_audio()
	STAGE1_VISUAL_SETUP.apply_materials(self)
	WOOD_BULLET_COVER.apply_to($Town)
	WOOD_BULLET_COVER.apply_to(self)
	BreakablePropSetupScript.apply_to(self)
	var desert_plane := _scatter_prop("desert_plane")
	if desert_plane != null:
		TERRAIN_COLLISION.apply_to(desert_plane)
	_setup_environment_collision()
	_setup_distance_zone_culling()
	_setup_ambient_ai_freezer()
	_setup_town_navigation()
	_wire_shop_doors()
	_wire_blacksmith_doors()
	_wire_home_doors()
	_wire_new_game_hotel_doors()
	_fade_overlay.modulate.a = 1.0
	PlayerDeathLoot.restore_loot_bag_for_stage(self)
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

	if AdventureSave.consume_bonfire_respawn_fade_pending():
		DeathOverlayManager.fade_in_after_respawn()

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


func _setup_ambient_ai_freezer() -> void:
	var freezer := AmbientAiFreezerScript.new()
	freezer.name = "AmbientAiFreezer"
	add_child(freezer)


func _setup_town_bird_day_night() -> void:
	var roost := TownBirdDayNight.new()
	roost.name = "TownBirdDayNight"
	add_child(roost)


func _setup_town_wall_lights() -> void:
	# Wall torches and altar fires follow day/night (on at dawn/dusk/night).
	# Bonfires (rest points) and lantern posts manage themselves.
	for pattern in ["WallLight*", "Altar*"]:
		for light_root in find_children(pattern, "", true, false):
			# "Altar*" also matches the AltarFire inside bonfire scenes — those
			# flames signal the lit/unlit rest point, never the time of day.
			if _is_bonfire_fire(light_root):
				continue
			_set_fire_respect_day_night(light_root)


func _is_bonfire_fire(light_root: Node) -> bool:
	var node: Node = light_root
	while node != null:
		if node is Bonfire:
			return true
		node = node.get_parent()
	return false


func _set_fire_respect_day_night(light_root: Node) -> void:
	var fire := light_root.get_node_or_null("Fire")
	if fire != null and fire.has_method("set_respect_day_night"):
		fire.call("set_respect_day_night", true)


func _setup_church_collision() -> void:
	if _church_collision_ready:
		return
	var church := get_node_or_null("Church") as Node3D
	if church != null:
		WOOD_PROP_COLLISION.apply_to(church)
		_church_collision_ready = true


func _setup_distance_zone_culling() -> void:
	var church := get_node_or_null("Church") as Node3D
	if church == null:
		return

	_church_zone_culler = DistanceZoneCuller.new()
	_church_zone_culler.name = "ChurchZoneCuller"
	_church_zone_culler.target = church
	_church_zone_culler.activate_distance = 95.0
	_church_zone_culler.deactivate_distance = 115.0
	_church_zone_culler.start_active = false
	_church_zone_culler.zone_activated.connect(_on_church_zone_activated)
	add_child(_church_zone_culler)


func _on_church_zone_activated() -> void:
	_setup_church_collision()


func _bind_distance_cullers_to_player(player: Node3D) -> void:
	if _church_zone_culler != null and player != null:
		_church_zone_culler.bind_player(player)


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
	var nav_roots: Array[Node] = [$Town, $Terrain]
	var church := get_node_or_null("Church")
	if church != null:
		nav_roots.append(church)
	nav_setup.configure_and_bake_from_roots(nav_roots, $Town.global_position, Vector3(200.0, 14.0, 200.0))


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
	if BonfireTravelManager.has_pending_travel():
		GameState.overworld_scenario_id = GameState.SCENARIO_NORMAL_TOWN
		_setup_normal_town(false, BonfireTravelManager.consume_pending_travel())
		return

	if AdventureSave.consume_pending_bonfire_respawn():
		GameState.overworld_scenario_id = GameState.SCENARIO_NORMAL_TOWN
		_setup_normal_town(true)
		return

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


func _setup_normal_town(bonfire_respawn := false, bonfire_travel: Dictionary = {}) -> void:
	var fresh_game_start := false
	if not bonfire_travel.is_empty():
		_player = _spawn_overworld_player_for_bonfire_travel(bonfire_travel)
	elif bonfire_respawn:
		_player = _spawn_overworld_player_for_bonfire_respawn()
	elif AdventureSave.should_restore_on_stage_load():
		GameState.overworld_scenario_id = AdventureSave.get_overworld_scenario_id()
		_player = _spawn_overworld_player_at_save()
		AdventureSave.consume_pending_town_restore()
	else:
		fresh_game_start = true
		_player = _spawn_overworld_player_at_new_game_hotel()
	_spawn_town_npcs()
	_spawn_ruins_guide()
	_spawn_cart_encounters()
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_arrow_ammo_pickups_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_melee_weapon_pickups_near_spawn()
	_spawn_dynamite_pickup_near_spawn()
	_spawn_hat_pickups_near_spawn()
	_spawn_town_oil_drums()
	_set_farmer_cow_quest_active(false)
	_spawn_baldwin_companion()
	_spawn_horsey()
	_setup_home_practice_fence()
	if fresh_game_start:
		_setup_bandit_ambush()
	_setup_comet_cinematic()
	_setup_canyon_gate_transition(bonfire_travel)
	_setup_canyon_content()
	_setup_church_skeleton_ambush()
	_setup_church_chief_getcha()
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
	_spawn_town_npcs()
	_spawn_cart_encounters()
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_arrow_ammo_pickups_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_melee_weapon_pickups_near_spawn()
	_spawn_dynamite_pickup_near_spawn()
	_spawn_lost_quest_cows()
	_spawn_town_oil_drums()
	_set_farmer_cow_quest_active(true)
	CowWrangleQuest.reset_quest()
	_setup_church_skeleton_ambush()
	_setup_church_chief_getcha()


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
	# Also keeps StageZoneCuller from clobbering the drums' authored
	# collision_layer/mask (it restores RigidBody3Ds to layer 1).
	var drum_root := get_node_or_null("TownActors/OilDrums") as Node3D
	if drum_root == null:
		drum_root = Node3D.new()
		drum_root.name = "OilDrums"
		_ensure_town_actors_host().add_child(drum_root)

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
	_spawn_arrow_ammo_pickups_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_melee_weapon_pickups_near_spawn()
	_spawn_dynamite_pickup_near_spawn()


func _setup_engines_raid_scenario() -> void:
	var scenario: Node3D = ENGINES_RAID_SCENARIO_SCENE.instantiate()
	$Town.add_child(scenario)
	var player_spawn: Marker3D = scenario.call("setup", self, $Town)
	_player = _spawn_overworld_player_at(player_spawn)
	scenario.call_deferred("begin_raid")
	_spawn_lasso_pickup_near_spawn()
	_spawn_bow_pickup_near_spawn()
	_spawn_arrow_ammo_pickups_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_melee_weapon_pickups_near_spawn()
	_spawn_dynamite_pickup_near_spawn()


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
	_spawn_arrow_ammo_pickups_near_spawn()
	_spawn_knife_pickup_near_spawn()
	_spawn_melee_weapon_pickups_near_spawn()
	_spawn_dynamite_pickup_near_spawn()


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


## Runtime-spawned town life (NPCs, animals, props) lives OUTSIDE the culled
## Town root: StageZoneCuller force-toggles every CollisionShape3D/Area3D it
## finds and breaks CharacterBody3D actors across zone swaps (same reason
## CanyonBandits is a separate host). The gate transition toggles this host's
## visibility/process instead.
func _ensure_town_actors_host() -> Node3D:
	var host := get_node_or_null("TownActors") as Node3D
	if host == null:
		host = Node3D.new()
		host.name = "TownActors"
		add_child(host)
	return host


func _spawn_town_npc_from_marker(marker: Marker3D, scene: PackedScene, host: Node) -> Node3D:
	if marker == null or scene == null or host == null:
		return null
	var spawn := TownNpcSpawn.new()
	spawn.npc_scene = scene
	host.add_child(spawn)
	spawn.global_transform = marker.global_transform
	spawn.spawn_npc()
	return spawn.get_spawned_npc()


func _spawn_town_npcs() -> void:
	const SHERIFF_NPC_SCENE := preload("res://characters/sheriff/sheriff_town_npc.tscn")
	var spawn: Marker3D = get_node_or_null("Town/SheriffSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/SheriffSpawn marker.")
		return

	_sheriff_npc = _spawn_town_npc_from_marker(spawn, SHERIFF_NPC_SCENE, _ensure_town_actors_host())
	_spawn_groyper_townspeople()
	_spawn_engines_npc()
	_spawn_uncle_toad()
	_spawn_groypettes()
	_spawn_hotel_warning_npc()


func _spawn_overworld_player_for_bonfire_respawn() -> Node3D:
	var player := _spawn_overworld_player_at_transform(AdventureSave.get_bonfire_spawn_transform(self))
	AdventureSave.apply_to_player(player)
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	if player.has_method("apply_post_bonfire_respawn"):
		player.call_deferred("apply_post_bonfire_respawn")
	if AdventureSave.is_bonfire_checkpoint_interior():
		_begin_interior_arrival(player)
	return player


func _spawn_overworld_player_for_bonfire_travel(travel: Dictionary) -> Node3D:
	var player := _spawn_overworld_player_at_transform(
		BonfireTravelManager.get_travel_spawn_transform(self, travel)
	)
	AdventureSave.apply_to_player(player)
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	if str(travel.get("interior_slot", "")) != "":
		_begin_interior_arrival(player)
	return player


## Spawning straight into an interior (fast travel / respawn) — engage the
## interior camera and home music the way a door entry would.
func _begin_interior_arrival(player: Node3D) -> void:
	if player != null and player.has_method("prepare_interior_spawn_camera"):
		player.prepare_interior_spawn_camera()
	ShopSession.start_home_music()


func _spawn_engines_npc() -> void:
	const ENGINES_NPC_SCENE := preload("res://characters/fast/engines_npc.tscn")
	var spawn := get_node_or_null("Town/FastTownSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/FastTownSpawn.")
		return

	_spawn_town_npc_from_marker(spawn, ENGINES_NPC_SCENE, _ensure_town_actors_host())


func _spawn_uncle_toad() -> void:
	const UNCLE_TOAD_SCENE := preload("res://characters/uncle_toad/uncle_toad_npc.tscn")
	var spawn := get_node_or_null("Town/UncleToadSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/UncleToadSpawn.")
		return

	_spawn_town_npc_from_marker(spawn, UNCLE_TOAD_SCENE, _ensure_town_actors_host())


func _spawn_groypettes() -> void:
	const GROYPETTE_SCENE := preload("res://characters/groypette/groypette_npc.tscn")
	var spawns_root := get_node_or_null("Town/GroypetteSpawns") as Node3D
	if spawns_root == null:
		push_warning("Stage1: missing Town/GroypetteSpawns.")
		return

	for child in spawns_root.get_children():
		if not child is Marker3D:
			continue
		_spawn_town_npc_from_marker(child as Marker3D, GROYPETTE_SCENE, _ensure_town_actors_host())


func _spawn_groyper_townspeople() -> void:
	const GROYPER_NPC_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
	var spawns_root := get_node_or_null("Town/GroyperTownSpawns") as Node3D
	if spawns_root == null:
		push_warning("Stage1: missing Town/GroyperTownSpawns.")
		return

	var actors_host := _ensure_town_actors_host()

	for child in spawns_root.get_children():
		if not child is Marker3D:
			continue

		var marker := child as Marker3D
		_spawn_town_npc_from_marker(marker, GROYPER_NPC_SCENE, actors_host)


func _spawn_hotel_warning_npc() -> void:
	const HOTEL_WARNING_NPC_SCENE := preload("res://characters/groyper/hotel_warning_npc.tscn")
	var spawn := get_node_or_null("NewGameHotel/WarningNPC") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing NewGameHotel/WarningNPC marker.")
		return

	_spawn_town_npc_from_marker(spawn, HOTEL_WARNING_NPC_SCENE, self)


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


func _setup_comet_cinematic() -> void:
	if CometProgress.completed:
		return

	var trigger := get_node_or_null("NewGameHotel/CometView") as Area3D
	if trigger == null:
		push_warning("Stage1: missing NewGameHotel/CometView trigger.")
		return

	var cinematic: CometCinematic = CometCinematicScript.new()
	cinematic.name = "CometCinematic"
	add_child(cinematic)
	cinematic.setup(trigger, _player)


func _setup_canyon_gate_transition(bonfire_travel: Dictionary = {}) -> void:
	if get_node_or_null("CanyonGateTransition") != null:
		return
	if _player == null:
		push_warning("Stage1: canyon gate setup skipped — no player.")
		return

	var hotel_trigger := get_node_or_null("NewGameHotel/Gate/CanyonEntrance") as Area3D
	if hotel_trigger == null:
		push_warning("Stage1: missing NewGameHotel/Gate/CanyonEntrance trigger.")
		return

	_canyon_gate_transition = CanyonGateTransitionScript.new()
	_canyon_gate_transition.name = "CanyonGateTransition"
	add_child(_canyon_gate_transition)
	_canyon_gate_transition.setup(_player, self)
	if _church_zone_culler != null:
		_canyon_gate_transition.bind_church_culler(_church_zone_culler)

	_canyon_gate_transition.add_gate(
		hotel_trigger,
		CanyonGateTransition.Zone.CANYON,
		CanyonGateTransition.TITLE_CANYONS,
		"CanyonLookAt",
		CanyonGateTransition.Zone.OVERWORLD,
		CanyonGateTransition.TITLE_HOTEL,
		"HotelLookAt"
	)

	var church_trigger := get_node_or_null("Gate2/CanyonExit") as Area3D
	if church_trigger == null:
		# Fallback if the gate was left parented under Canyon.
		church_trigger = get_node_or_null("Canyon/Gate2/CanyonExit") as Area3D
	if church_trigger != null:
		_canyon_gate_transition.add_gate(
			church_trigger,
			CanyonGateTransition.Zone.CANYON,
			CanyonGateTransition.TITLE_CANYONS,
			"CanyonLookAt",
			CanyonGateTransition.Zone.CHURCH,
			CanyonGateTransition.TITLE_CHURCH,
			"ChurchLookAt"
		)
	else:
		push_warning("Stage1: missing Gate2/CanyonExit church-end trigger.")

	var town_church_trigger := get_node_or_null("Church/Gate/TownEntrance") as Area3D
	if town_church_trigger != null:
		_canyon_gate_transition.add_gate(
			town_church_trigger,
			CanyonGateTransition.Zone.CHURCH,
			CanyonGateTransition.TITLE_CHURCH,
			"ChurchLookAt",
			CanyonGateTransition.Zone.OVERWORLD,
			CanyonGateTransition.TITLE_TOWN,
			"TownLookAt"
		)
	else:
		push_warning("Stage1: missing Church/Gate/TownEntrance trigger.")

	# Spawn/load / fast-travel may place the player already in a zone — apply
	# cull state without replaying the cinematic (gates are not walked through).
	var travel_id := str(bonfire_travel.get("id", ""))
	if travel_id == "":
		travel_id = AdventureSave.get_bonfire_checkpoint_id()
	if travel_id != "":
		_canyon_gate_transition.call_deferred("sync_from_travel_id", travel_id)
	else:
		_canyon_gate_transition.call_deferred("sync_from_player_position")


func _setup_canyon_content() -> void:
	var canyon := get_node_or_null("Canyon") as Node3D
	if canyon == null:
		return

	_canyon_bandit_spawns.clear()
	for child in canyon.get_children():
		if not (child is Marker3D):
			continue
		var marker := child as Marker3D
		var marker_name := String(marker.name)
		if marker_name.begins_with("Bandit"):
			_wire_canyon_bandit_marker(marker)
		elif marker_name == "KnifePickup":
			_spawn_canyon_knife_pickup(marker)

	# If travel/sync already put us in the canyon this frame, spawn after the
	# deferred zone apply + one physics tick so prop collision is live.
	if _canyon_gate_transition != null and _canyon_gate_transition.is_in_canyon():
		call_deferred("ensure_canyon_bandits_spawned")


## Spawn every canyon bandit marker. Called when the canyon zone becomes active.
## Uses the wired list (not the scene-tree group) so deferred _ready races cannot
## skip markers.
func ensure_canyon_bandits_spawned(player: Node3D = null) -> void:
	var canyon := get_node_or_null("Canyon") as Node3D
	if canyon == null or not canyon.visible:
		return
	var bandits_host := get_node_or_null("CanyonBandits") as Node3D
	if bandits_host == null:
		bandits_host = Node3D.new()
		bandits_host.name = "CanyonBandits"
		add_child(bandits_host)
	bandits_host.visible = true
	bandits_host.process_mode = Node.PROCESS_MODE_PAUSABLE
	if player == null:
		player = _player
	for spawn in _canyon_bandit_spawns:
		if spawn == null or not is_instance_valid(spawn):
			continue
		if spawn.has_method("ensure_spawned"):
			spawn.ensure_spawned(player)


func _wire_canyon_bandit_marker(marker: Marker3D) -> void:
	var existing := marker.get_node_or_null("CanyonBanditSpawn")
	if existing != null:
		if not _canyon_bandit_spawns.has(existing):
			_canyon_bandit_spawns.append(existing)
		return
	var spawn = CanyonBanditSpawnScript.new()
	spawn.name = "CanyonBanditSpawn"
	marker.add_child(spawn)
	spawn.configure_from_marker(marker)
	_canyon_bandit_spawns.append(spawn)


func _spawn_canyon_knife_pickup(marker: Marker3D) -> void:
	if PlayerInventory.has_knife:
		return
	if marker.get_node_or_null("KnifePickupInstance") != null:
		return
	var pickup: Node3D = KNIFE_PICKUP_SCENE.instantiate()
	pickup.name = "KnifePickupInstance"
	marker.add_child(pickup)
	pickup.global_transform = marker.global_transform
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _setup_church_skeleton_ambush() -> void:
	if get_node_or_null("ChurchSkeletonAmbush") != null:
		return

	var trigger := get_node_or_null("Church/SkeletonTrigger") as Area3D
	if trigger == null:
		push_warning("Stage1: missing Church/SkeletonTrigger area.")
		return

	var ambush = ChurchSkeletonAmbushScript.new()
	ambush.name = "ChurchSkeletonAmbush"
	add_child(ambush)
	ambush.setup(trigger, _player)


func _setup_church_chief_getcha() -> void:
	if ChurchSanctifyQuest.is_sanctified():
		_spawn_church_recurve_bow_reward()
		return

	if get_node_or_null("Church/ChiefGetcha") != null:
		return

	var spawn := get_node_or_null("Church/ChiefGetchaSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Church/ChiefGetchaSpawn marker.")
		return

	var church := get_node_or_null("Church") as Node3D
	if church == null:
		return

	var chief: Node3D = CHIEF_GETCHA_NPC_SCENE.instantiate()
	chief.name = "ChiefGetcha"
	church.add_child(chief)
	chief.global_transform = spawn.global_transform


func _spawn_church_recurve_bow_reward() -> void:
	ChurchRecurveRewardScript.spawn_if_needed(get_node_or_null("Church") as Node3D)


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


## Debug pickups anchor on the player wherever they spawned (hotel room,
## bonfire, scenario marker); the town spawn marker is only a fallback.
## Offsets stay within ~3m so the lineup fits inside interior rooms.
func _debug_pickup_anchor() -> Transform3D:
	if _player != null and is_instance_valid(_player):
		return _player.global_transform
	var spawn := get_node_or_null("Town/OverworldSpawn") as Marker3D
	if spawn != null:
		return spawn.global_transform
	push_warning("Stage1: no player or Town/OverworldSpawn for debug pickups.")
	return Transform3D.IDENTITY


func _spawn_lasso_pickup_near_spawn() -> void:
	var anchor := _debug_pickup_anchor()
	var pickup = WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = GroyperWeapons.Id.LASSO
	$Town.add_child(pickup)
	pickup.global_position = anchor * Vector3(1.9, 0.0, 1.6)
	pickup.global_rotation.y = anchor.basis.get_euler().y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _spawn_bow_pickup_near_spawn() -> void:
	# Recurve Bow unlocks from the sanctified church reward after Chief Getcha.
	pass


## Debug arrows for the bow: ten walk-over auto-pickups scattered in a loose
## grid beside the bow pickup (bow sits at (1.9, 0, 2.6) off the anchor).
func _spawn_arrow_ammo_pickups_near_spawn() -> void:
	var anchor := _debug_pickup_anchor()
	for i in 10:
		var col := i % 5
		@warning_ignore("integer_division")
		var row := i / 5
		var pickup: Area3D = ARROW_AMMO_PICKUP_SCRIPT.new()
		pickup.ammo_amount = 1
		$Town.add_child(pickup)
		var jitter := 0.18 if (i % 2) == 0 else -0.14
		pickup.global_position = anchor * Vector3(
			2.8 + float(row) * 0.7 + jitter,
			0.0,
			1.2 + float(col) * 0.65
		)
		pickup.global_rotation.y = anchor.basis.get_euler().y


func _spawn_knife_pickup_near_spawn() -> void:
	if PlayerInventory.has_knife:
		return

	var anchor := _debug_pickup_anchor()
	var pickup = KNIFE_PICKUP_SCENE.instantiate()
	$Town.add_child(pickup)
	# Lasso sits at (1.9, 0, 1.6) — knife one step to its side.
	pickup.global_position = anchor * Vector3(0.9, 0.0, 1.6)
	pickup.global_rotation.y = anchor.basis.get_euler().y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _spawn_melee_weapon_pickups_near_spawn() -> void:
	var anchor := _debug_pickup_anchor()
	var rot_y := anchor.basis.get_euler().y

	# One-handers finish the lasso/knife row, two-handers line a second row.
	_spawn_one_melee_pickup(GroyperWeapons.Id.AXE_1H, anchor * Vector3(-0.1, 0.0, 1.6), rot_y)
	_spawn_one_melee_pickup(GroyperWeapons.Id.SWORD_1H, anchor * Vector3(-1.1, 0.0, 1.6), rot_y)
	_spawn_one_melee_pickup(GroyperWeapons.Id.AXE_2H, anchor * Vector3(-0.1, 0.0, 2.6), rot_y)
	_spawn_one_melee_pickup(GroyperWeapons.Id.SWORD_2H, anchor * Vector3(-1.1, 0.0, 2.6), rot_y)
	_spawn_one_melee_pickup(GroyperWeapons.Id.HAMMER_2H, anchor * Vector3(-2.1, 0.0, 2.6), rot_y)


func _spawn_dynamite_pickup_near_spawn() -> void:
	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.DYNAMITE):
		return
	var anchor := _debug_pickup_anchor()
	var pickup = DYNAMITE_PICKUP_SCENE.instantiate()
	$Town.add_child(pickup)
	pickup.global_position = anchor * Vector3(-3.1, 0.0, 1.6)
	pickup.global_rotation.y = anchor.basis.get_euler().y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


## Every hat type in a grid behind the weapon rows — swap-testing pickups.
func _spawn_hat_pickups_near_spawn() -> void:
	var anchor := _debug_pickup_anchor()
	var ids := GroyperHatCatalog.get_all_hat_ids()
	for i in ids.size():
		var col := i % 4
		@warning_ignore("integer_division")
		var row := i / 4
		var offset := Vector3(
			(float(col) - 1.5) * 0.8,
			0.0,
			3.6 + float(row) * 0.8
		)
		HAT_WORLD_PICKUP_SCRIPT.spawn_at_point(ids[i], anchor * offset, $Town)


func _spawn_one_melee_pickup(
	weapon_id: GroyperWeapons.Id,
	world_pos: Vector3,
	rot_y: float
) -> void:
	if PlayerInventory.owns_weapon_type(weapon_id):
		return
	var pickup = MELEE_WEAPON_PICKUP_SCENE.instantiate()
	pickup.weapon_id = weapon_id
	$Town.add_child(pickup)
	pickup.global_position = world_pos
	pickup.global_rotation.y = rot_y
	if pickup.has_method("snap_to_floor"):
		pickup.call_deferred("snap_to_floor")


func _spawn_town_horses() -> void:
	var horses_root := get_node_or_null("TownActors/Horses") as Node3D
	if horses_root == null:
		horses_root = Node3D.new()
		horses_root.name = "Horses"
		_ensure_town_actors_host().add_child(horses_root)

	_spawn_free_horse(horses_root, Vector3(6.5, 0.0, 5.0), 1, StupidHorseScript.RoamMode.STREET, 501)
	_spawn_free_horse(horses_root, Vector3(-9.0, 0.0, 44.0), 3, StupidHorseScript.RoamMode.FREE, 733)
	_spawn_free_horse(horses_root, Vector3(15.5, 0.0, -16.0), 4, StupidHorseScript.RoamMode.FREE, 881)
	_spawn_free_horse(horses_root, Vector3(-5.5, 0.0, -32.0), 0, StupidHorseScript.RoamMode.FREE, 999)


func _spawn_town_birds() -> void:
	var birds_root := get_node_or_null("TownActors/Birds") as Node3D
	if birds_root == null:
		birds_root = Node3D.new()
		birds_root.name = "Birds"
		_ensure_town_actors_host().add_child(birds_root)

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
	var birds_root := get_node_or_null("TownActors/Birds") as Node3D
	if birds_root == null:
		birds_root = Node3D.new()
		birds_root.name = "Birds"
		_ensure_town_actors_host().add_child(birds_root)

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
	var grass_root := get_node_or_null("TownActors/GrazingGrass") as Node3D
	if grass_root == null:
		grass_root = Node3D.new()
		grass_root.name = "GrazingGrass"
		_ensure_town_actors_host().add_child(grass_root)

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
	var cows_root := get_node_or_null("TownActors/Cows") as Node3D
	if cows_root == null:
		cows_root = Node3D.new()
		cows_root.name = "Cows"
		_ensure_town_actors_host().add_child(cows_root)

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

	var spawn := get_node_or_null("Town/TownSpawn") as Marker3D
	if spawn == null:
		push_warning("Stage1: missing Town/TownSpawn marker.")
		spawn = $Town/OverworldSpawn
	return _spawn_overworld_player_at_marker(spawn)


func _spawn_overworld_player_at_new_game_hotel() -> Node3D:
	if GameState.selected_character_id != "" and GameState.selected_character_id != "groyper":
		return null

	# TESTING: fresh games spawn at the Church Bonfire for Chief Getcha
	# combat checks. Restore Canyon/Bonfire + NIGHT when done testing.
	var bonfire := get_node_or_null("Church/Bonfire") as Node3D
	if bonfire == null:
		push_warning("Stage1: missing Church/Bonfire, falling back to TownSpawn.")
		return _spawn_overworld_player()

	PlayerInventory.reset_for_home_start()

	var spawn_basis := Basis.from_euler(Vector3(0.0, PI, 0.0))
	var player := _spawn_overworld_player_at_transform(
		Transform3D(spawn_basis, bonfire.global_position)
	)
	if player != null and player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player != null and player.has_method("snap_to_floor"):
		player.call_deferred("snap_to_floor")
	if player != null and player.has_method("prepare_for_home_start"):
		player.call_deferred("prepare_for_home_start")

	var church_spawn := get_node_or_null("Church/ChurchSpawn") as Marker3D
	if church_spawn != null:
		_activate_church_zone_if_near_spawn(church_spawn)

	var church_entry := {
		"id": "church",
		"name": "Church",
		"stage_path": "res://stages/stage1/stage1.tscn",
		"bonfire_path": "Church/Bonfire",
		"travelable": true,
	}
	AdventureSave.mark_bonfire_lit(BonfireTravelManager.HOTEL_TRAVEL_ENTRY)
	AdventureSave.mark_bonfire_lit(church_entry)
	AdventureSave.set_bonfire_checkpoint(bonfire, self)
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
	var player := _spawn_overworld_player_at_transform(
		_overworld_spawn_transform_from_marker(spawn)
	)
	_activate_church_zone_if_near_spawn(spawn)
	return player


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
	_bind_distance_cullers_to_player(player)
	return player


func _activate_church_zone_if_near_spawn(spawn: Marker3D) -> void:
	var church := get_node_or_null("Church") as Node3D
	if church == null or spawn == null:
		return
	var distance_sq := church.global_position.distance_squared_to(spawn.global_position)
	if distance_sq > 115.0 * 115.0:
		return
	StageZoneCuller.set_zone_active(church, true)
	_setup_church_collision()
	if _church_zone_culler != null and _player != null:
		_church_zone_culler.bind_player(_player)


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
	var interior_slot := get_node_or_null("ShopInteriors/WestShopInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Stage1: shop door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Stage1: shop interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
		exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _wire_blacksmith_doors() -> void:
	var entrance_marker := get_node_or_null(
		"Town/WestRow/Build_05/BlacksmithEntranceMarker"
	) as Marker3D
	var entrance := get_node_or_null(
		"Town/WestRow/Build_05/BlacksmithEntranceMarker/WestBlacksmithEntrance"
	)
	var interior_slot := get_node_or_null("ShopInteriors/BlacksmithInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Stage1: blacksmith door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Stage1: blacksmith interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	entrance.set("interior_music", ShopSession.SMITH_MUSIC)
	entrance.set("interior_music_volume_db", ShopSession.SMITH_MUSIC_VOLUME_DB)
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
		exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _wire_home_doors() -> void:
	var entrance_marker := get_node_or_null("Town/WestRow/Build_07/Home") as Marker3D
	var entrance := get_node_or_null("Town/WestRow/Build_07/Home/HomeEntrance")
	var interior_slot := get_node_or_null("ShopInteriors/HomeInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Stage1: home door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Stage1: home interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
		exit_door.set("destination", exit_door.get_path_to(entrance_marker))


func _wire_new_game_hotel_doors() -> void:
	var entrance_marker := get_node_or_null("NewGameHotel/NewGameHotelEntrance") as Marker3D
	var entrance := get_node_or_null(
		"NewGameHotel/NewGameHotelEntrance/NewGameHotelEntranceDoor"
	)
	var interior_slot := get_node_or_null("ShopInteriors/NewGameHotelInterior")
	if entrance == null or entrance_marker == null or interior_slot == null:
		push_warning("Stage1: NewGameHotel door wiring incomplete.")
		return

	interior_slot.set("exterior_entrance", interior_slot.get_path_to(entrance_marker))
	var interior_spawn := interior_slot.call("get_enter_destination") as Marker3D
	if interior_spawn == null:
		push_warning("Stage1: NewGameHotel interior enter destination missing.")
		return

	entrance.set("destination", entrance.get_path_to(interior_spawn))
	var exit_door := interior_slot.get_node_or_null("Interior/ExitDoor")
	if exit_door != null:
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

	var stable_root := get_node_or_null("TownActors/HomeStable") as Node3D
	if stable_root == null:
		stable_root = Node3D.new()
		stable_root.name = "HomeStable"
		_ensure_town_actors_host().add_child(stable_root)

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
