extends Node3D

const StageZoneCuller := preload("res://gameplay/world/stage_zone_culler.gd")

@export var interior_scene: PackedScene
@export var exterior_entrance: NodePath

var _interior: Node3D


func is_loaded() -> bool:
	return _interior != null and is_instance_valid(_interior)


func get_enter_destination() -> Marker3D:
	return get_node_or_null("EnterDestination") as Marker3D


func ensure_loaded() -> Node3D:
	if is_loaded():
		StageZoneCuller.set_zone_active(_interior, true)
		return _interior
	if interior_scene == null:
		push_warning("InteriorZoneSlot: missing interior_scene on %s." % name)
		return null

	_interior = interior_scene.instantiate() as Node3D
	if _interior == null:
		push_warning("InteriorZoneSlot: failed to instantiate interior for %s." % name)
		return null

	_interior.name = "Interior"
	add_child(_interior)
	_wire_exit_door()
	return _interior


func unload() -> void:
	if not is_loaded():
		return
	_interior.queue_free()
	_interior = null


func get_spawn_marker() -> Marker3D:
	var interior := ensure_loaded()
	if interior == null:
		return get_enter_destination()
	return interior.get_node_or_null("InteriorSpawn") as Marker3D


func _wire_exit_door() -> void:
	if _interior == null:
		return
	var exit_door := _interior.get_node_or_null("ExitDoor")
	if exit_door == null:
		return
	if exterior_entrance.is_empty():
		push_warning("InteriorZoneSlot: missing exterior_entrance on %s." % name)
		return
	var entrance_marker := get_node_or_null(exterior_entrance) as Marker3D
	if entrance_marker == null:
		push_warning(
			"InteriorZoneSlot: missing exterior entrance marker at %s on %s."
			% [exterior_entrance, name]
		)
		return
	exit_door.set("destination", exit_door.get_path_to(entrance_marker))
