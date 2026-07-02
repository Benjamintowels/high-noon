extends Node3D
class_name EnginesRaidScenario

const ENGINES_NPC_SCENE := preload("res://characters/fast/engines_npc.tscn")
const TOWNSFOLK_SCENE := preload("res://characters/groyper/groyper_townsfolk_npc.tscn")
const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const INITIAL_RAIDER_COUNT := 10
const MAX_RAIDER_COUNT := 20
const REINFORCEMENT_INTERVAL := 5.0
const TOWN_EDGE_FEET := 100.0
const FEET_TO_METERS := 0.3048
const SPAWN_RING_OFFSET := TOWN_EDGE_FEET * FEET_TO_METERS

const TOWNSFOLK_COUNT := 8
const ROW_SPACING := 2.4
const TOWNSFOLK_ROW_Z := 1.5
const PLAYER_SPAWN_Z := -4.5

## Approximate town footprint half-extents from Town origin (meters).
const TOWN_HALF_EXTENTS := Vector2(32.0, 48.0)

const DEBUG_ENGINES_RAID := true

var _town: Node3D
var _spawned_raider_count := 0
var _reinforcement_timer := 0.0
var _horse_seed := 900
var _defenders: Array[GroyperTownNpc] = []
var _raiders: Array[EnginesNpc] = []
var _pending_raider_spawns: Array[Dictionary] = []


func setup(_stage: Node3D, town: Node3D) -> Marker3D:
	_town = town
	var player_spawn := _create_player_spawn()
	_spawn_townsfolk_defenders()
	_spawn_nearby_horses()
	_spawn_initial_raiders()
	return player_spawn


func _process(delta: float) -> void:
	if _spawned_raider_count >= MAX_RAIDER_COUNT:
		return

	_reinforcement_timer += delta
	if _reinforcement_timer < REINFORCEMENT_INTERVAL:
		return

	_reinforcement_timer = 0.0
	_spawn_raider_on_ring(randf() * TAU, true)


func _create_player_spawn() -> Marker3D:
	var player_spawn := Marker3D.new()
	player_spawn.name = "PlayerSpawn"
	player_spawn.position = Vector3(0.0, 0.0, PLAYER_SPAWN_Z)
	player_spawn.rotation.y = PI
	add_child(player_spawn)
	return player_spawn


func _spawn_townsfolk_defenders() -> void:
	var spawns := _build_row_markers("DefenderSpawns", TOWNSFOLK_COUNT, TOWNSFOLK_ROW_Z)
	_defenders.clear()

	for child in spawns.get_children():
		if not child is Marker3D:
			continue

		var marker := child as Marker3D
		var npc: GroyperTownNpc = TOWNSFOLK_SCENE.instantiate()
		_town.add_child(npc)
		npc.global_position = marker.global_position
		_defenders.append(npc)


func _spawn_nearby_horses() -> void:
	var horses_root := Node3D.new()
	horses_root.name = "RaidHorses"
	_town.add_child(horses_root)

	var horse_spawns: Array[Vector3] = [
		Vector3(8.0, 0.0, 4.0),
		Vector3(-7.5, 0.0, 6.0),
		Vector3(5.5, 0.0, -6.0),
		Vector3(-6.0, 0.0, -4.5),
	]

	for i in horse_spawns.size():
		_spawn_free_horse(horses_root, horse_spawns[i], i, _horse_seed + i)


func _spawn_initial_raiders() -> void:
	for i in INITIAL_RAIDER_COUNT:
		var angle := (float(i) / float(INITIAL_RAIDER_COUNT)) * TAU
		_spawn_raider_on_ring(angle, false)


func _spawn_raider_on_ring(angle: float, begin_immediately: bool = false) -> void:
	if _spawned_raider_count >= MAX_RAIDER_COUNT:
		return

	var spawn_info := _ring_spawn_for_angle(angle)
	var npc: EnginesNpc = ENGINES_NPC_SCENE.instantiate()
	_town.add_child(npc)
	npc.global_position = spawn_info["spawn_pos"]
	if npc.has_method("snap_to_floor"):
		npc.snap_to_floor()

	var horse := _spawn_horse(spawn_info["spawn_pos"], spawn_info["face_dir"])

	_spawned_raider_count += 1
	_raiders.append(npc)
	if begin_immediately:
		npc.mount_and_begin_raid_assault(horse, self)
	else:
		_pending_raider_spawns.append({"npc": npc, "horse": horse})


func begin_raid() -> void:
	_raid_debug(
		"begin_raid pending=%d total_raiders=%d"
		% [_pending_raider_spawns.size(), _raiders.size()]
	)
	for entry in _pending_raider_spawns:
		var npc: EnginesNpc = entry.get("npc")
		var horse: StupidHorse = entry.get("horse")
		if not is_instance_valid(npc) or not is_instance_valid(horse):
			_raid_debug("skip invalid entry npc=%s horse=%s" % [npc, horse])
			continue
		var target := pick_attack_target(npc.global_position)
		_raid_debug(
			"mounting %s on %s at %s target=%s"
			% [
				npc.name,
				horse.name,
				npc.global_position,
				target.name if target != null else "null",
			]
		)
		npc.mount_and_begin_raid_assault(horse, self)
	_pending_raider_spawns.clear()
	_begin_town_defense()


func _raid_debug(msg: String) -> void:
	if DEBUG_ENGINES_RAID:
		print("[EnginesRaid][Scenario] %s" % msg)


func get_town_charge_point() -> Vector3:
	if _town == null:
		return Vector3.ZERO
	return _town.global_position


func _ring_spawn_for_angle(angle: float) -> Dictionary:
	var dir := Vector3(sin(angle), 0.0, cos(angle))
	var spawn_pos: Vector3 = _point_on_town_ring(dir)
	var face_dir := -dir.normalized()
	return {
		"spawn_pos": spawn_pos,
		"face_dir": face_dir,
	}


func _point_on_town_ring(outward_dir: Vector3) -> Vector3:
	var flat := Vector3(outward_dir.x, 0.0, outward_dir.z)
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	flat = flat.normalized()

	var hx := TOWN_HALF_EXTENTS.x + SPAWN_RING_OFFSET
	var hz := TOWN_HALF_EXTENTS.y + SPAWN_RING_OFFSET
	var tx := hx / absf(flat.x) if absf(flat.x) > 0.001 else INF
	var tz := hz / absf(flat.z) if absf(flat.z) > 0.001 else INF
	return flat * minf(tx, tz)


func _spawn_horse(spawn_pos: Vector3, face_dir: Vector3) -> StupidHorse:
	var horse: StupidHorse = STUPID_HORSE_SCENE.instantiate()
	horse.model_variant = HorseModelConfig.VARIANTS[_horse_seed % HorseModelConfig.VARIANTS.size()]
	horse.roam_mode = StupidHorseScript.RoamMode.FREE
	horse.personality_seed = _horse_seed
	_horse_seed += 1
	_town.add_child(horse)
	horse.global_position = spawn_pos
	GroyperBodyUtils.snap_character_to_floor(horse)
	_orient_horse_toward(horse, face_dir)
	return horse


func _spawn_free_horse(
	parent: Node3D,
	spawn_pos: Vector3,
	variant_index: int,
	seed_value: int
) -> void:
	var horse: StupidHorse = STUPID_HORSE_SCENE.instantiate()
	horse.model_variant = HorseModelConfig.VARIANTS[variant_index % HorseModelConfig.VARIANTS.size()]
	horse.roam_mode = StupidHorseScript.RoamMode.FREE
	horse.personality_seed = seed_value
	parent.add_child(horse)
	horse.position = spawn_pos


func _orient_horse_toward(horse: StupidHorse, world_dir: Vector3) -> void:
	var flat_dir := Vector3(world_dir.x, 0.0, world_dir.z)
	if flat_dir.length_squared() < 0.0001:
		return
	var facing := horse.get_facing_node()
	if facing != null:
		facing.rotation.y = atan2(flat_dir.x, flat_dir.z)


func pick_attack_target(from_pos: Vector3) -> Node3D:
	var nearest := _pick_nearest_hostile(from_pos, &"overworld_player")
	if nearest != null:
		return nearest

	nearest = _pick_nearest_hostile(from_pos, &"town_groyper")
	if nearest != null:
		return nearest

	for defender in _defenders:
		if not is_instance_valid(defender) or defender.is_defeated():
			continue
		var dist_sq := from_pos.distance_squared_to(defender.global_position)
		if nearest == null or dist_sq < from_pos.distance_squared_to(nearest.global_position):
			nearest = defender

	return nearest


func _pick_nearest_hostile(from_pos: Vector3, group_name: StringName) -> Node3D:
	var nearest: Node3D
	var nearest_dist_sq := INF

	for node in get_tree().get_nodes_in_group(group_name):
		if not is_instance_valid(node) or not node is Node3D:
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		if not FactionAffinityScript.is_hostile(
			FactionIdsScript.ENGINES,
			FactionAffinityScript.resolve_faction_id(node)
		):
			continue

		var dist_sq := from_pos.distance_squared_to((node as Node3D).global_position)
		if dist_sq >= nearest_dist_sq:
			continue
		nearest_dist_sq = dist_sq
		nearest = node as Node3D

	return nearest


func _begin_town_defense() -> void:
	var threat := pick_nearest_raider(Vector3.ZERO)
	if threat == null:
		return
	rally_defenders_against(threat)


func pick_nearest_raider(from_pos: Vector3) -> Node3D:
	var nearest: Node3D
	var nearest_dist_sq := INF

	for raider in _raiders:
		if not is_instance_valid(raider) or raider.is_defeated():
			continue
		var dist_sq := from_pos.distance_squared_to(raider.global_position)
		if dist_sq >= nearest_dist_sq:
			continue
		nearest_dist_sq = dist_sq
		nearest = raider

	return nearest


func rally_defenders_against(attacker: Node3D) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return

	for defender in _defenders:
		if not is_instance_valid(defender) or defender.is_defeated():
			continue
		defender.set_faction_aggro_level(3, attacker)


func _build_row_markers(root_name: String, count: int, row_z: float) -> Node3D:
	var root := Node3D.new()
	root.name = root_name
	add_child(root)

	var total_width := float(count - 1) * ROW_SPACING
	var start_x := -total_width * 0.5

	for i in count:
		var marker := Marker3D.new()
		marker.name = "Spawn%02d" % (i + 1)
		marker.position = Vector3(start_x + float(i) * ROW_SPACING, 0.0, row_z)
		root.add_child(marker)

	return root
