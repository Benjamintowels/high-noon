extends Node

## Spawns run chests and destructible loot props from designer markers, with
## procedural fill when a zone has fewer markers than the configured counts.
## Encounter-area stages skip start-of-run chests; use spawn_encounter_chest.

const RunLootChestScript := preload("res://gameplay/runs/run_loot_chest.gd")
const RunLootPropScript := preload("res://gameplay/runs/run_loot_prop.gd")
const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

## 36 barrel/crate instantiations in one frame hitch Dry Gulch boot.
const SPAWNS_PER_FRAME := 4

var _host: Node3D
var _config: Resource
var _run_director: Node


func populate(stage: Node3D, config: Resource, run_director: Node = null) -> void:
	_host = stage
	_config = config
	_run_director = run_director
	if _host == null or _config == null:
		return

	## Encounter-area stages spawn kill-gated chests per pocket instead.
	var spawn_start_chests := not bool(_config.get("use_encounter_areas"))
	var chest_count := int(_config.get("chest_count")) if spawn_start_chests else 0
	var prop_count := int(_config.get("prop_count"))
	var loot_mult := 1.0
	if _run_director != null and _run_director.has_method("get_loot_multiplier"):
		loot_mult = float(_run_director.get_loot_multiplier())

	var chest_spots: Array[Vector3] = []
	if spawn_start_chests:
		chest_spots = _collect_marker_positions("RunLootSpots/Chests")
		_shuffle(chest_spots)
		_fill_positions(chest_spots, chest_count, "chest")
	var prop_spots := _collect_marker_positions("RunLootSpots/Props")
	_shuffle(prop_spots)
	_fill_positions(prop_spots, prop_count, "prop")

	var loot_root := _host.get_node_or_null("RunLootSpawned") as Node3D
	if loot_root == null:
		loot_root = Node3D.new()
		loot_root.name = "RunLootSpawned"
		_host.add_child(loot_root)

	var spawned_this_frame := 0
	for i in mini(chest_count, chest_spots.size()):
		_spawn_chest(loot_root, chest_spots[i])
		spawned_this_frame += 1
		if spawned_this_frame >= SPAWNS_PER_FRAME:
			spawned_this_frame = 0
			await get_tree().process_frame
	for i in mini(prop_count, prop_spots.size()):
		_spawn_prop(loot_root, prop_spots[i], loot_mult)
		spawned_this_frame += 1
		if spawned_this_frame >= SPAWNS_PER_FRAME:
			spawned_this_frame = 0
			await get_tree().process_frame


func _collect_marker_positions(path: String) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var root := _host.get_node_or_null(path)
	if root == null:
		return result
	for child in root.get_children():
		if child is Marker3D:
			result.append((child as Marker3D).global_position)
	return result


func _fill_positions(spots: Array[Vector3], needed: int, kind: String) -> void:
	if spots.size() >= needed:
		return
	var generated := _generate_fallback_positions(needed - spots.size(), kind)
	for pos in generated:
		spots.append(pos)


func _generate_fallback_positions(count: int, kind: String) -> Array[Vector3]:
	# Scatter across the whole playable map (all four Terrain3D regions), not
	# just a tight ring around the player spawn. Marker positions anchor the
	# interesting spots; this fill covers the space between them.
	var positions: Array[Vector3] = []
	var center := Vector3(30.0, 5.0, -20.0)
	var radius := 165.0 if kind == "chest" else 180.0
	var golden := PI * (3.0 - sqrt(5.0))
	for i in count:
		var t := float(i + 1) / float(count + 1)
		var r := radius * sqrt(t) * randf_range(0.5, 1.0)
		var angle := float(i) * golden + randf_range(-0.25, 0.25)
		var pos := center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)
		pos.y = center.y
		positions.append(pos)
	return positions


func _spawn_chest(parent: Node3D, world_pos: Vector3) -> void:
	var chest: Area3D = RunLootChestScript.new() as Area3D
	chest.configure(
		_roll_chest_mode(),
		int(_config.get("gram_chest_base_cost")),
		float(_config.get("gram_chest_cost_mult")),
		int(_config.get("shard_chest_base_cost")),
		float(_config.get("shard_chest_cost_mult")),
		float(_config.get("horsey_drop_chance")),
		float(_config.get("rare_seed_drop_chance"))
	)
	parent.add_child(chest)
	chest.global_position = _snap_to_floor(world_pos)


## Free, kill-gated chest for an encounter pocket. Caller unlocks after clear.
func spawn_encounter_chest(parent: Node3D, world_pos: Vector3) -> Area3D:
	if parent == null or _host == null:
		return null
	var chest: Area3D = RunLootChestScript.new() as Area3D
	chest.configure(
		0, ## LockMode.FREE
		0,
		1.0,
		0,
		1.0,
		0.0, ## no Horsey — always a random gun
		0.0
	)
	parent.add_child(chest)
	chest.global_position = _snap_to_floor(world_pos)
	if chest.has_method("set_encounter_locked"):
		chest.call("set_encounter_locked", true)
	return chest


func _spawn_prop(parent: Node3D, world_pos: Vector3, loot_mult: float) -> void:
	var prop: RigidBody3D = RunLootPropScript.new() as RigidBody3D
	var as_barrel := randf() < float(_config.get("prop_barrel_weight"))
	prop.setup(as_barrel, loot_mult)
	parent.add_child(prop)
	prop.global_position = _snap_to_floor(world_pos) + Vector3(0.0, 0.05, 0.0)


func _roll_chest_mode() -> int:
	var free_w := float(_config.get("chest_free_weight"))
	var gram_w := float(_config.get("chest_gram_weight"))
	var shard_w := float(_config.get("chest_shard_weight"))
	var total := maxf(free_w + gram_w + shard_w, 0.001)
	var roll := randf() * total
	if roll < free_w:
		return 0
	if roll < free_w + gram_w:
		return 1
	return 2


func _snap_to_floor(pos: Vector3) -> Vector3:
	var world := _host.get_world_3d()
	if world == null:
		return pos
	# sample_floor_y falls back to a 200m sky cast — terrain height across the
	# four regions varies more than the short snap ray covers.
	return Vector3(pos.x, GroyperBodyUtils.sample_floor_y(world, pos), pos.z)


func _shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := randi() % (i + 1)
		var tmp = items[i]
		items[i] = items[j]
		items[j] = tmp
