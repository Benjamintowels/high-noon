extends Node3D

## Testing helper: spawns one interactable pickup of every hat type in a grid
## around this node. Drop it in a scene, position it over open floor.

const GroyperHatWorldPickupScript := preload("res://characters/groyper/groyper_hat_world_pickup.gd")
const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")

## Optional marker the hat grid centers on; falls back to this node.
@export var placement_marker_path: NodePath
@export var columns := 4
@export var spacing := 0.8


func _ready() -> void:
	_spawn_hats()


func _spawn_hats() -> void:
	# Let the interior's static bodies enter the physics space so the
	# pickups' floor raycasts land.
	await get_tree().physics_frame
	await get_tree().physics_frame

	var anchor := _resolve_anchor()
	var ids := GroyperHatCatalog.get_all_hat_ids()
	for i in ids.size():
		var col := i % columns
		@warning_ignore("integer_division")
		var row := i / columns
		var local := Vector3(
			(float(col) - float(columns - 1) * 0.5) * spacing,
			0.1,
			float(row) * spacing
		)
		GroyperHatWorldPickupScript.spawn_at_point(
			ids[i],
			anchor * local,
			get_parent()
		)


func _resolve_anchor() -> Transform3D:
	if not placement_marker_path.is_empty():
		var marker := get_node_or_null(placement_marker_path) as Node3D
		if marker != null:
			return marker.global_transform
		push_warning("TestHatRack: placement marker %s not found." % placement_marker_path)
	return global_transform
