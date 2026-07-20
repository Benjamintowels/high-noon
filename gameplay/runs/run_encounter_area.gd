extends Marker3D

## Designer-placed encounter pocket for roguelike runs. RunDirector triggers a
## themed pack when the player enters trigger_radius. Move this marker (and its
## Spawn* children) in the editor to place fights on the map.

@export var area_id: StringName = &""
@export var trigger_radius: float = 22.0
@export var announce_override := ""


func _ready() -> void:
	add_to_group("run_encounter_area")


func get_spawn_markers() -> Array[Marker3D]:
	var markers: Array[Marker3D] = []
	for child in get_children():
		if child is Marker3D:
			markers.append(child as Marker3D)
	return markers


func distance_to_player_xz(player: Node3D) -> float:
	if player == null or not is_instance_valid(player):
		return INF
	var delta := player.global_position - global_position
	delta.y = 0.0
	return delta.length()


func is_player_in_range(player: Node3D) -> bool:
	return distance_to_player_xz(player) <= trigger_radius
