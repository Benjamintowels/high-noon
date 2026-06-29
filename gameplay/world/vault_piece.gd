extends Node3D
class_name VaultPiece

## Attach to fence prop roots. Space near the fence vaults over to the far side.

const COVER_COLLISION := preload("res://gameplay/world/cover_collision.gd")

@export var vault_radius := 2.8
@export var touch_distance := 0.85
@export var approach_standoff := 0.45
@export var exit_standoff := 0.55
@export var vault_half_extents := Vector3(0.5, 0.5, 0.05)

var _vault_center_local := Vector3.ZERO
var _thickness_axis_local := Vector3(0.0, 0.0, 1.0)
var _length_axis_local := Vector3(1.0, 0.0, 0.0)


func _ready() -> void:
	add_to_group("vault_piece")
	call_deferred("_setup_vault")


func _setup_vault() -> void:
	var root := get_parent() as Node3D
	if root == null:
		push_error("VaultPiece: parent must be the fence prop root.")
		return

	_refresh_vault_bounds()


func get_vault_anchor() -> Vector3:
	return global_position


func is_player_in_range(player: Node3D) -> bool:
	if player == null:
		return false
	var offset := player.global_position - get_vault_anchor()
	offset.y = 0.0
	return offset.length_squared() <= vault_radius * vault_radius


func is_player_touching(player: Node3D) -> bool:
	if player == null:
		return false
	var root := get_parent() as Node3D
	if root == null:
		return false

	var inv := root.global_transform.affine_inverse()
	var local_player := inv * player.global_position
	var from_center := local_player - _vault_center_local
	from_center.y = 0.0

	var thickness := absf(from_center.dot(_thickness_axis_local))
	var half_thickness := maxf(vault_half_extents.dot(_thickness_axis_local.abs()), 0.01)
	return thickness <= half_thickness + touch_distance


func get_vault_spot(player: Node3D) -> Dictionary:
	var root := get_parent() as Node3D
	if root == null or player == null:
		return {
			"start": global_position,
			"end": global_position,
			"facing_yaw": 0.0,
			"cross_direction": Vector3.FORWARD,
		}

	var inv := root.global_transform.affine_inverse()
	var local_player := inv * player.global_position
	var from_center := local_player - _vault_center_local
	from_center.y = 0.0

	var side_sign := 1.0
	if from_center.dot(_thickness_axis_local) < 0.0:
		side_sign = -1.0

	var thickness_axis := _thickness_axis_local * side_sign
	var half_thickness := maxf(vault_half_extents.dot(_thickness_axis_local.abs()), 0.01)

	var along := from_center.dot(_length_axis_local)
	along = clampf(
		along,
		-vault_half_extents.dot(_length_axis_local.abs()),
		vault_half_extents.dot(_length_axis_local.abs())
	)

	var local_start := (
		_vault_center_local
		+ _length_axis_local * along
		+ thickness_axis * (half_thickness + approach_standoff)
	)
	var local_end := (
		_vault_center_local
		+ _length_axis_local * along
		- thickness_axis * (half_thickness + exit_standoff)
	)

	var world_start := root.global_transform * local_start
	var world_end := root.global_transform * local_end
	world_start.y = player.global_position.y
	world_end.y = player.global_position.y

	var world_outward := root.global_transform.basis * thickness_axis
	world_outward.y = 0.0
	if world_outward.length_squared() < 0.0001:
		world_outward = Vector3.FORWARD
	else:
		world_outward = world_outward.normalized()

	var world_cross := world_end - world_start
	world_cross.y = 0.0
	if world_cross.length_squared() < 0.0001:
		world_cross = -world_outward
	else:
		world_cross = world_cross.normalized()

	return {
		"start": world_start,
		"end": world_end,
		# Match CoverPiece: overworld model uses raw atan2, negated outward faces into the fence.
		"facing_yaw": atan2(-world_outward.x, -world_outward.z),
		"cross_direction": world_cross,
	}


func _refresh_vault_bounds() -> void:
	var root := get_parent() as Node3D
	if root == null:
		return

	var combined := AABB()
	var first := true
	for mesh_inst in COVER_COLLISION.collect_visible_meshes(root):
		var mesh_aabb := mesh_inst.mesh.get_aabb()
		var to_root := root.global_transform.affine_inverse() * mesh_inst.global_transform
		for corner in _aabb_corners(mesh_aabb):
			var local_point := to_root * corner
			if first:
				combined = AABB(local_point, Vector3.ZERO)
				first = false
			else:
				combined = combined.expand(local_point)

	if first:
		return

	_vault_center_local = combined.get_center()
	vault_half_extents = combined.size * 0.5
	vault_half_extents.y = maxf(vault_half_extents.y, 0.35)

	# Thinnest horizontal axis is the vault cross direction; longest is along the fence run.
	var flat_extents := Vector3(vault_half_extents.x, 0.0, vault_half_extents.z)
	if flat_extents.x <= flat_extents.z:
		_thickness_axis_local = Vector3(1.0, 0.0, 0.0)
		_length_axis_local = Vector3(0.0, 0.0, 1.0)
	else:
		_thickness_axis_local = Vector3(0.0, 0.0, 1.0)
		_length_axis_local = Vector3(1.0, 0.0, 0.0)


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	return [
		aabb.position,
		aabb.position + Vector3(aabb.size.x, 0.0, 0.0),
		aabb.position + Vector3(0.0, 0.0, aabb.size.z),
		aabb.position + Vector3(aabb.size.x, 0.0, aabb.size.z),
		aabb.position + Vector3(0.0, aabb.size.y, 0.0),
		aabb.position + Vector3(aabb.size.x, aabb.size.y, 0.0),
		aabb.position + Vector3(0.0, aabb.size.y, aabb.size.z),
		aabb.end,
	]
