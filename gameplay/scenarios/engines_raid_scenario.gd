extends Node3D
class_name EnginesRaidScenario

const ENGINES_NPC_SCENE := preload("res://characters/fast/engines_npc.tscn")
const TOWNSFOLK_SCENE := preload("res://characters/groyper/groyper_townsfolk_npc.tscn")
const TOWN_CENTER_SCENE := preload("res://gameplay/world/town_center_object.tscn")
const STUPID_HORSE_SCENE := preload("res://characters/animals/stupid_horse.tscn")
const HorseModelConfig := preload("res://characters/animals/horse_model_config.gd")
const StupidHorseScript := preload("res://characters/animals/stupid_horse.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const TownShootout := preload("res://gameplay/world/town_shootout.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const INITIAL_RAIDER_COUNT := 10
const MAX_RAIDER_COUNT := 20
const TOWN_RAID_RAIDER_COUNT := 15
const TOWN_RAID_FOOT_COUNT := 6
const TOWN_RAID_ASSAULT_STAGGER := 0.04
const REINFORCEMENT_INTERVAL := 5.0
const TOWN_EDGE_FEET := 100.0
const FEET_TO_METERS := 0.3048
const SPAWN_RING_OFFSET := TOWN_EDGE_FEET * FEET_TO_METERS

const TOWNSFOLK_COUNT := 8
const ROW_SPACING := 2.4
const TOWNSFOLK_ROW_Z := 1.5
const PLAYER_SPAWN_Z := -4.5
## Mid-game raider spawns are spread across frames — each raider (plus horse)
## is several scene instantiations, and 15 at once is a visible hitch.
const RAID_SPAWNS_PER_FRAME := 2

## Approximate town footprint half-extents from Town origin (meters).
const TOWN_HALF_EXTENTS := Vector2(32.0, 48.0)

var _town: Node3D
var _town_raid_mode := false
var _ignore_player_targets := false
var _spawned_raider_count := 0
var _reinforcement_timer := 0.0
var _horse_seed := 900
var _defenders: Array[GroyperTownNpc] = []
var _raiders: Array[EnginesNpc] = []
var _pending_raider_spawns: Array[Dictionary] = []
var _pending_foot_raider_spawns: Array[EnginesNpc] = []
var _assault_queue: Array[Dictionary] = []
var _town_center: TownCenterObject
var _raid_kill_count := 0
var _raid_complete := false
var _town_raid_spawning := false


func setup(_stage: Node3D, town: Node3D) -> Marker3D:
	_town = town
	var player_spawn := _create_player_spawn()
	_spawn_townsfolk_defenders()
	_spawn_nearby_horses()
	_spawn_initial_raiders()
	return player_spawn


func setup_town_raid(town: Node3D) -> void:
	_town = town
	_town_raid_mode = true
	_ignore_player_targets = true
	_spawn_town_center()
	_spawn_town_raid_raiders()


func _spawn_town_raid_raiders() -> void:
	_spawned_raider_count = 0
	_raiders.clear()
	_pending_raider_spawns.clear()
	_pending_foot_raider_spawns.clear()
	_town_raid_spawning = true
	_spawn_town_raid_raiders_over_frames()


func _spawn_town_raid_raiders_over_frames() -> void:
	for i in TOWN_RAID_RAIDER_COUNT:
		var angle := (float(i) / float(TOWN_RAID_RAIDER_COUNT)) * TAU
		var on_foot := i >= TOWN_RAID_RAIDER_COUNT - TOWN_RAID_FOOT_COUNT
		_spawn_raider_on_ring(angle, false, on_foot)
		if (i + 1) % RAID_SPAWNS_PER_FRAME == 0:
			await get_tree().process_frame
	_town_raid_spawning = false


func _spawn_town_center() -> void:
	if _town == null:
		return
	_town_center = TOWN_CENTER_SCENE.instantiate() as TownCenterObject
	_town_center.name = "TownCenter"
	_town.add_child(_town_center)
	_town_center.global_position = _town.global_position
	if _town_center.get_world_3d() != null:
		_town_center.global_position = GroyperBodyUtils.snap_position_to_floor(
			_town_center.get_world_3d(),
			_town_center.global_position,
			0.0
		)


func _process(delta: float) -> void:
	if _town_raid_mode:
		_update_town_raid_progress()
		return
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


func _spawn_raider_on_ring(
	angle: float,
	begin_immediately: bool = false,
	on_foot: bool = false
) -> void:
	var max_count := TOWN_RAID_RAIDER_COUNT if _town_raid_mode else MAX_RAIDER_COUNT
	if _spawned_raider_count >= max_count:
		return

	var spawn_info := _ring_spawn_for_angle(angle)
	var npc: EnginesNpc = ENGINES_NPC_SCENE.instantiate()
	_town.add_child(npc)
	npc.global_position = spawn_info["spawn_pos"]
	if npc.has_method("snap_to_floor"):
		npc.snap_to_floor()
	if _ignore_player_targets:
		npc.set_raid_ignore_player(true)
	if _town_center != null:
		npc.set_raid_town_center(_town_center)

	_spawned_raider_count += 1
	_raiders.append(npc)

	if on_foot:
		if begin_immediately:
			npc.begin_foot_raid_assault(self)
		else:
			_pending_foot_raider_spawns.append(npc)
		return

	var horse := _spawn_horse(spawn_info["spawn_pos"], spawn_info["face_dir"])
	if begin_immediately:
		npc.mount_and_begin_raid_assault(horse, self)
	else:
		_pending_raider_spawns.append({"npc": npc, "horse": horse})


func begin_raid() -> void:
	while _town_raid_spawning:
		await get_tree().process_frame

	if _town_raid_mode:
		GameAudio.play_town_bell(self)
	else:
		GameAudio.play_raid_drama_start(self)
	_enable_raid_voices()
	_assault_queue.clear()

	for npc in _pending_foot_raider_spawns:
		if is_instance_valid(npc):
			_assault_queue.append({"npc": npc, "horse": null})
	_pending_foot_raider_spawns.clear()

	for entry in _pending_raider_spawns:
		var npc: EnginesNpc = entry.get("npc")
		var horse: StupidHorse = entry.get("horse")
		if is_instance_valid(npc) and is_instance_valid(horse):
			_assault_queue.append({"npc": npc, "horse": horse})
	_pending_raider_spawns.clear()

	if _town_raid_mode:
		_show_raid_hud_start()
		_launch_all_raid_assaults()
	else:
		_launch_next_raid_assault()


func _launch_all_raid_assaults() -> void:
	for entry in _assault_queue:
		var npc: EnginesNpc = entry.get("npc")
		var horse: StupidHorse = entry.get("horse")
		if not is_instance_valid(npc):
			continue
		if is_instance_valid(horse):
			npc.mount_and_begin_raid_assault(horse, self)
		else:
			npc.begin_foot_raid_assault(self)
	_assault_queue.clear()
	_begin_town_defense()


func _launch_next_raid_assault() -> void:
	if _assault_queue.is_empty():
		_begin_town_defense()
		return

	var entry: Dictionary = _assault_queue.pop_front()
	var npc: EnginesNpc = entry.get("npc")
	var horse: StupidHorse = entry.get("horse")
	if not is_instance_valid(npc):
		_launch_next_raid_assault()
		return

	if is_instance_valid(horse):
		npc.mount_and_begin_raid_assault(horse, self)
	else:
		npc.begin_foot_raid_assault(self)

	get_tree().create_timer(TOWN_RAID_ASSAULT_STAGGER).timeout.connect(_launch_next_raid_assault)


func _enable_raid_voices() -> void:
	for raider in _raiders:
		if not is_instance_valid(raider):
			continue
		var voice := raider.get_node_or_null("AggroVoice")
		if voice != null and voice.has_method("set_raid_mode"):
			voice.set_raid_mode(true)

	for npc in get_tree().get_nodes_in_group("town_fast"):
		if not is_instance_valid(npc):
			continue
		var voice := npc.get_node_or_null("AggroVoice")
		if voice != null and voice.has_method("set_raid_mode"):
			voice.set_raid_mode(true)


func get_town_charge_point() -> Vector3:
	if _town_center != null and is_instance_valid(_town_center):
		return _town_center.global_position
	if _town == null:
		return Vector3.ZERO
	return _town.global_position


func get_town_center() -> TownCenterObject:
	return _town_center


func _show_raid_hud_start() -> void:
	var player := _find_overworld_player()
	if player == null or not player.has_method("get_raid_hud"):
		return
	var hud: RaidHud = player.get_raid_hud()
	if hud != null:
		hud.show_raid_start(_raiders.size())


func _update_town_raid_progress() -> void:
	if _raid_complete:
		return

	var killed := 0
	for raider in _raiders:
		if not is_instance_valid(raider) or raider.is_defeated():
			killed += 1

	if killed == _raid_kill_count:
		return

	_raid_kill_count = killed
	var player := _find_overworld_player()
	if player != null and player.has_method("get_raid_hud"):
		var hud: RaidHud = player.get_raid_hud()
		if hud != null:
			hud.update_kill_count(killed, _raiders.size())

	if killed < _raiders.size():
		return

	_raid_complete = true
	DeputyQuest.mark_raid_finished()
	if player != null and player.has_method("get_raid_hud"):
		var hud: RaidHud = player.get_raid_hud()
		if hud != null:
			hud.show_raid_victory()
	_notify_civilian_celebrations()


func _find_overworld_player() -> Node3D:
	for node in get_tree().get_nodes_in_group("overworld_player"):
		if node is Node3D:
			return node as Node3D
	return null


func _notify_civilian_celebrations() -> void:
	for node in get_tree().get_nodes_in_group("civilian"):
		if not is_instance_valid(node):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		if node.has_method("celebrate_town_event"):
			node.celebrate_town_event()


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
	var ring_pos := flat * minf(tx, tz)
	if _town != null:
		return _town.global_position + ring_pos
	return ring_pos


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
	if not _ignore_player_targets:
		var player_target := _pick_nearest_hostile(from_pos, &"overworld_player")
		if player_target != null:
			return player_target
	elif player_harmed_townsfolk():
		var outlaw_target := _pick_nearest_hostile(from_pos, &"overworld_player")
		if outlaw_target != null:
			return outlaw_target

	var nearest: Node3D = null
	for group_name: StringName in [
		&"becker_boys",
		&"town_groyper",
		&"town_fast",
		&"town_sheriff",
	]:
		var candidate := _pick_nearest_hostile(from_pos, group_name)
		if candidate == null:
			continue
		if nearest == null or from_pos.distance_squared_to(candidate.global_position) < from_pos.distance_squared_to(nearest.global_position):
			nearest = candidate

	for defender in _defenders:
		if not is_instance_valid(defender) or defender.is_defeated():
			continue
		var dist_sq := from_pos.distance_squared_to(defender.global_position)
		if nearest == null or dist_sq < from_pos.distance_squared_to(nearest.global_position):
			nearest = defender

	return nearest


func player_harmed_townsfolk() -> bool:
	return TownShootout.player_harmed_becker_boys(get_tree())


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

	if _town_raid_mode:
		for npc in get_tree().get_nodes_in_group("becker_boys"):
			if not is_instance_valid(npc):
				continue
			if npc.has_method("is_defeated") and npc.is_defeated():
				continue
			if not npc.has_method("set_faction_aggro_level"):
				continue
			npc.set_faction_aggro_level(3, attacker)
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
