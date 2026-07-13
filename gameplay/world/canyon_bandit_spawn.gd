extends Node
class_name CanyonBanditSpawn
## Spawns a canyon bandit at a Marker3D. Marker name picks the loadout:
## BanditUnarmed* → melee_only (1-2 shards), BanditUnarmedTorch* → unarmed, or
## torch in-hand when outdoor lights are on, BanditBowandArrow* → bow,
## BanditHatchet* → hatchet (armed drop 5-7 shards).

const BANDIT_SCENE := preload("res://characters/groyper/groyper_bandit_npc.tscn")
const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const GroyperBodyUtilsScript := preload("res://characters/groyper/groyper_body_utils.gd")

const UNARMED_SHARD_MIN := 1
const UNARMED_SHARD_MAX := 2
const ARMED_SHARD_MIN := 5
const ARMED_SHARD_MAX := 7
const SEAT_RAY_UP := 4.0
const SEAT_RAY_DOWN := 120.0

var marker: Marker3D
var _spawned: Node3D
var _melee_only := false
var _holds_torch := false
var _weapon_id: int = GroyperWeapons.Id.REVOLVER
var _shard_min := UNARMED_SHARD_MIN
var _shard_max := UNARMED_SHARD_MAX


func _ready() -> void:
	add_to_group("canyon_bandit_spawn")


func configure_from_marker(spawn_marker: Marker3D) -> void:
	marker = spawn_marker
	_resolve_loadout(String(spawn_marker.name))


## Always creates a fresh body at the marker (zone enter / fast travel).
func ensure_spawned(player: Node3D = null) -> void:
	spawn_enemy()
	_try_proximity_arm(player)


func spawn_enemy() -> void:
	var marker_name := String(marker.name) if marker != null else "?"
	if marker == null or not is_instance_valid(marker):
		return
	if not is_inside_tree():
		call_deferred("spawn_enemy")
		return

	despawn_enemy()
	var bandit: GroyperBanditNpc = BANDIT_SCENE.instantiate()
	if bandit == null:
		return

	bandit.melee_only = _melee_only
	if not _melee_only:
		bandit.equipped_weapon_id = _weapon_id as GroyperWeapons.Id
	bandit.set_meta(&"canyon_raider", true)
	bandit.set_meta(&"canyon_soul_shard_min", _shard_min)
	bandit.set_meta(&"canyon_soul_shard_max", _shard_max)
	bandit.add_to_group("bandit")
	# Keep simulating even if a parent momentarily flips modes.
	bandit.process_mode = Node.PROCESS_MODE_PAUSABLE

	var host := _get_spawn_host()
	if host == null:
		bandit.queue_free()
		return

	host.add_child(bandit)
	bandit.name = "Canyon_%s" % marker_name
	bandit.global_transform = marker.global_transform
	FloatingEnemyHealthBarScript.attach_to(bandit)
	_spawned = bandit
	if bandit.has_method("prepare_canyon_raider"):
		bandit.prepare_canyon_raider()

	_seat_on_marker_floor(bandit)
	# Reseat next frame in case Terrain3D data wasn't ready on the first pass.
	call_deferred("_seat_on_marker_floor_deferred", bandit)
	if _holds_torch and bandit.has_method("equip_handheld_torch"):
		bandit.equip_handheld_torch()


func _seat_on_marker_floor_deferred(bandit: Node3D) -> void:
	if bandit == null or not is_instance_valid(bandit):
		return
	_seat_on_marker_floor(bandit)


func _seat_on_marker_floor(bandit: Node3D) -> bool:
	if bandit == null or not is_instance_valid(bandit) or marker == null:
		return false
	bandit.global_transform = marker.global_transform
	if not (bandit is CharacterBody3D):
		return false
	var body := bandit as CharacterBody3D
	# Terrain3D Dynamic collision only exists near the camera (~64m). Canyon
	# markers are often outside that, so physics rays miss and gravity drops
	# them into the void. Seat via heightmap first.
	if _snap_to_terrain3d_height(body):
		return true
	return _snap_long_range(body)


func _snap_to_terrain3d_height(body: CharacterBody3D) -> bool:
	var terrain := _find_terrain3d(body)
	if terrain == null or terrain.data == null:
		return false
	var height: float = terrain.data.get_height(body.global_position)
	if is_nan(height):
		return false
	body.global_position.y = (
		height - GroyperBodyUtilsScript.get_collision_feet_offset(body)
	)
	if "velocity" in body:
		body.velocity.y = 0.0
	return true


func _find_terrain3d(from_node: Node) -> Terrain3D:
	var stage := _get_stage_root()
	if stage != null:
		var direct := stage.get_node_or_null("Terrain/Terrain3D")
		if direct is Terrain3D:
			return direct as Terrain3D
	var node: Node = from_node
	while node != null:
		var candidate := node.get_node_or_null("Terrain/Terrain3D")
		if candidate is Terrain3D:
			return candidate as Terrain3D
		node = node.get_parent()
	var tree := from_node.get_tree() if from_node != null else null
	if tree == null:
		return null
	return tree.root.find_child("Terrain3D", true, false) as Terrain3D


func _snap_long_range(body: CharacterBody3D) -> bool:
	var world := body.get_world_3d()
	if world == null:
		return false
	var space_state := world.direct_space_state
	if space_state == null:
		return false
	var from := body.global_position + Vector3(0.0, SEAT_RAY_UP, 0.0)
	var to := body.global_position - Vector3(0.0, SEAT_RAY_DOWN, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = 0x7FFFFFFF
	query.exclude = [body.get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return false
	body.global_position.y = (
		hit.position.y - GroyperBodyUtilsScript.get_collision_feet_offset(body)
	)
	return true


func get_spawned_body() -> Node3D:
	if _spawned != null and is_instance_valid(_spawned):
		return _spawned as Node3D
	return null


func has_living_bandit() -> bool:
	return (
		_spawned != null
		and is_instance_valid(_spawned)
		and not (_spawned.has_method("is_defeated") and _spawned.is_defeated())
	)


func despawn_enemy() -> void:
	if _spawned != null and is_instance_valid(_spawned):
		_spawned.queue_free()
	_spawned = null


func respawn_enemy() -> void:
	despawn_enemy()
	spawn_enemy()


func arm_hostility_if_alive(player: Node3D = null) -> void:
	ensure_spawned(player)


func _try_proximity_arm(player: Node3D) -> void:
	if player == null or not is_instance_valid(player):
		return
	if _spawned == null or not is_instance_valid(_spawned):
		return
	if not _spawned.has_method("arm_canyon_hostility"):
		return
	var aggro_range := 18.0
	if "aggro_range" in _spawned:
		aggro_range = float(_spawned.aggro_range)
	if (_spawned as Node3D).global_position.distance_to(player.global_position) <= aggro_range:
		_spawned.arm_canyon_hostility(player)


func _resolve_loadout(marker_name: String) -> void:
	var key := marker_name.to_lower()
	# Check torch variant before the generic unarmed prefix.
	if key.begins_with("banditunarmedtorch"):
		_melee_only = true
		_holds_torch = DayNightCycle.should_outdoor_lights_be_on(false)
		_shard_min = UNARMED_SHARD_MIN
		_shard_max = UNARMED_SHARD_MAX
		return
	if key.begins_with("banditunarmed"):
		_melee_only = true
		_holds_torch = false
		_shard_min = UNARMED_SHARD_MIN
		_shard_max = UNARMED_SHARD_MAX
		return

	_melee_only = false
	_holds_torch = false
	_shard_min = ARMED_SHARD_MIN
	_shard_max = ARMED_SHARD_MAX
	if key.begins_with("banditbowandarrow") or key.begins_with("banditbow"):
		_weapon_id = GroyperWeapons.Id.BOW
	elif key.begins_with("bandithatchet") or key.begins_with("banditaxe"):
		_weapon_id = GroyperWeapons.Id.AXE_1H
	else:
		_weapon_id = GroyperWeapons.Id.REVOLVER


func _get_spawn_host() -> Node:
	var stage := _get_stage_root()
	if stage != null:
		var bucket := stage.get_node_or_null("CanyonBandits") as Node3D
		if bucket == null:
			bucket = Node3D.new()
			bucket.name = "CanyonBandits"
			stage.add_child(bucket)
		# Never inherit DISABLED from a culled zone pass.
		bucket.visible = true
		bucket.process_mode = Node.PROCESS_MODE_PAUSABLE
		return bucket
	if marker != null and marker.get_parent() != null:
		return marker.get_parent()
	return get_parent()


func _get_stage_root() -> Node:
	var node: Node = self
	while node != null:
		if node.has_method("ensure_canyon_bandits_spawned"):
			return node
		node = node.get_parent()
	var tree := get_tree()
	if tree != null:
		return tree.current_scene
	return null
