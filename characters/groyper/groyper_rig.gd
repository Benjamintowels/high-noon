@tool
extends Node3D

## Raise or lower the body mesh so the feet sit on the floor.
## Adjust foot_offset_y on this node — do not move the GroyperRig root transform.

@export_group("Foot Placement")
@export_range(-0.5, 0.5, 0.001, "or_greater", "or_less") var foot_offset_y := 0.06387776:
	set(value):
		foot_offset_y = value
		_apply_foot_offset()

@export var auto_align_feet_to_origin := false:
	set(value):
		auto_align_feet_to_origin = value
		_apply_foot_offset()

@export_range(-0.1, 0.1, 0.001, "or_greater", "or_less") var auto_align_fine_tune := 0.0:
	set(value):
		auto_align_fine_tune = value
		_apply_foot_offset()

@onready var _body: Node3D = $Body

var _body_base_y := 0.0


func _ready() -> void:
	if _body != null:
		_body_base_y = _body.position.y
	_apply_foot_offset()


func _apply_foot_offset() -> void:
	if _body == null:
		_body = get_node_or_null("Body") as Node3D
	if _body == null:
		return

	var offset := foot_offset_y
	if auto_align_feet_to_origin:
		offset = _measure_foot_raise() + auto_align_fine_tune

	_body.position.y = _body_base_y + offset


func _measure_foot_raise() -> float:
	var lowest_y := INF

	for mesh_instance in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh := mesh_instance as MeshInstance3D
		if mesh.mesh == null:
			continue

		var local_aabb := mesh.mesh.get_aabb()
		for corner_idx in 8:
			var corner := local_aabb.get_endpoint(corner_idx)
			var local_y := (global_transform.affine_inverse() * mesh.global_transform * corner).y
			lowest_y = minf(lowest_y, local_y)

	if lowest_y == INF:
		return 0.0

	return -lowest_y
