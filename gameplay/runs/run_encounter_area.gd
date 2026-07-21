extends Marker3D

## Designer-placed encounter pocket for roguelike runs. RunDirector triggers a
## themed pack when the player enters the Trigger Area3D (preferred) or
## trigger_radius — one enemy per spawn Marker3D child.
## Spawn markers: name them `{Enemy}{Weapon}{N}` (BanditRevolver1,
## RedoLightsaber, TownspersonUnarmed). Legacy `Spawn*` still works (Bandit +
## tier default). Entering also stacks that area's hybrid drip budget.

const RunEncounterSpawnSpecScript := preload("res://gameplay/runs/run_encounter_spawn_spec.gd")

const TRIGGER_NODE_NAME := &"Trigger"
const DRIP_SPAWN_NODE_NAME := &"DripSpawn"
## Offset from GateWall toward pocket center = "inside" corridor spawn.
const DRIP_INSIDE_OFFSET := 6.0

@export var area_id: StringName = &""
@export var trigger_radius: float = 22.0
@export var announce_override := ""


func _ready() -> void:
	add_to_group("run_encounter_area")
	_configure_trigger_area()


func get_spawn_markers() -> Array[Marker3D]:
	var markers: Array[Marker3D] = []
	for child in get_children():
		if child is Marker3D and RunEncounterSpawnSpecScript.is_spawn_marker_name(String(child.name)):
			markers.append(child as Marker3D)
	return markers


func get_chest_marker() -> Marker3D:
	var marker := get_node_or_null("Chest") as Marker3D
	return marker


func get_gate_walls() -> Array[Node3D]:
	var walls: Array[Node3D] = []
	for child in get_children():
		if child != null and child.has_method("sink_into_ground"):
			walls.append(child as Node3D)
	return walls


func get_primary_gate_wall() -> Node3D:
	var named := get_node_or_null("GateWall") as Node3D
	if named != null and named.has_method("sink_into_ground"):
		return named
	var walls := get_gate_walls()
	if walls.is_empty():
		return null
	return walls[0]


func get_drip_spawn_marker() -> Marker3D:
	return get_node_or_null(NodePath(DRIP_SPAWN_NODE_NAME)) as Marker3D


## World position for hybrid drip (inside GateWall / optional DripSpawn).
## Not floor-snapped — RunDirector snaps after jitter.
func get_drip_spawn_anchor() -> Vector3:
	var drip_marker := get_drip_spawn_marker()
	if drip_marker != null and is_instance_valid(drip_marker):
		return drip_marker.global_position
	var wall := get_primary_gate_wall()
	if wall == null or not is_instance_valid(wall):
		return global_position
	var wall_pos := wall.global_position
	var toward := global_position - wall_pos
	toward.y = 0.0
	if toward.length_squared() < 0.0001:
		return wall_pos
	toward = toward.normalized()
	return wall_pos + toward * DRIP_INSIDE_OFFSET


func sink_gate_walls() -> void:
	for wall in get_gate_walls():
		if wall != null and is_instance_valid(wall):
			wall.call("sink_into_ground")


func get_trigger_area() -> Area3D:
	return get_node_or_null(NodePath(TRIGGER_NODE_NAME)) as Area3D


func distance_to_player_xz(player: Node3D) -> float:
	if player == null or not is_instance_valid(player):
		return INF
	var delta := player.global_position - global_position
	delta.y = 0.0
	return delta.length()


func is_player_in_range(player: Node3D) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var trigger := get_trigger_area()
	if trigger != null and trigger.monitoring:
		return trigger.overlaps_body(player)
	return distance_to_player_xz(player) <= trigger_radius


func _configure_trigger_area() -> void:
	var trigger := get_trigger_area()
	if trigger == null:
		return
	trigger.monitoring = true
	trigger.monitorable = false
	trigger.collision_layer = 0
	trigger.collision_mask = 1
