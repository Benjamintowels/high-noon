extends BanditStandoffScenario
class_name MountedStandoffScenario

const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")

const TOWNSFOLK_FACE_DIR := Vector3(0.0, 0.0, 1.0)
const BANDIT_FACE_DIR := Vector3(0.0, 0.0, -1.0)

var _player_horse: StupidHorse
var _horse_seed := 400


func setup(_stage: Node3D, town: Node3D) -> Marker3D:
	var player_spawn := super.setup(_stage, town)
	_mount_standoff_faction(town, FactionIdsScript.BANDITS, BANDIT_FACE_DIR)
	_mount_standoff_faction(town, FactionIdsScript.BECKER_BOYS, TOWNSFOLK_FACE_DIR)
	_player_horse = _spawn_standoff_horse(
		town,
		player_spawn.global_position,
		TOWNSFOLK_FACE_DIR,
		_horse_seed
	)
	_horse_seed += 1
	return player_spawn


func mount_player(player: CharacterBody3D) -> void:
	if _player_horse == null or player == null:
		return
	_player_horse.mount_rider(player)


func _mount_standoff_faction(town: Node3D, faction_id: StringName, face_dir: Vector3) -> void:
	for child in town.get_children():
		if not child is GroyperTownNpc:
			continue
		var npc := child as GroyperTownNpc
		if not npc.is_faction_standoff_active() or npc.get_faction_id() != faction_id:
			continue
		if npc.is_mounted_on_horse():
			continue
		var horse := _spawn_standoff_horse(town, npc.global_position, face_dir, _horse_seed)
		_horse_seed += 1
		horse.mount_rider(npc)


func _spawn_standoff_horse(
	town: Node3D,
	spawn_pos: Vector3,
	face_dir: Vector3,
	seed_value: int
) -> StupidHorse:
	var horse: StupidHorse = STUPID_HORSE_SCENE.instantiate()
	horse.model_variant = HorseModelConfig.VARIANTS[seed_value % HorseModelConfig.VARIANTS.size()]
	horse.roam_mode = StupidHorseScript.RoamMode.FREE
	horse.personality_seed = seed_value
	town.add_child(horse)
	horse.global_position = spawn_pos

	var flat_dir := Vector3(face_dir.x, 0.0, face_dir.z)
	if flat_dir.length_squared() > 0.0001:
		var facing := horse.get_facing_node()
		if facing != null:
			facing.rotation.y = atan2(flat_dir.x, flat_dir.z)

	return horse
