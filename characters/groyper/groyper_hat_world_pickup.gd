extends Node3D
class_name GroyperHatWorldPickup

## Visible lasso hat pickup — tweens from the head to the floor at the drag-start point.

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const WORLD_PICKUP_GROUP := &"world_hat_pickup"
const PICKUP_RADIUS := 1.45
const DROP_DURATION := 0.55

var _hat_id := &""
var _picked_up := false
var _pickup_enabled := false
var _interact_area: Area3D
var _player_in_range: Node3D
var _hat_visual: Node3D
var _drop_xz := Vector3.ZERO
var _start_origin := Vector3.ZERO
var _end_origin := Vector3.ZERO
var _start_basis := Basis.IDENTITY
var _exclude_rids: Array[RID] = []


static func spawn_from_visual(
	hat_visual: Node3D,
	hat_id: StringName,
	drop_anchor: Vector3,
	world_parent: Node,
	actor: Node3D = null
) -> GroyperHatWorldPickup:
	if hat_visual == null or world_parent == null:
		return null

	var start_transform := hat_visual.global_transform
	var mount := hat_visual.get_parent()
	if mount != null:
		mount.remove_child(hat_visual)

	var pickup := GroyperHatWorldPickup.new()
	pickup.name = "LassoHatPickup"
	world_parent.add_child(pickup)
	pickup._begin_drop(hat_visual, hat_id, start_transform, drop_anchor, actor)
	return pickup


func _begin_drop(
	hat_visual: Node3D,
	hat_id: StringName,
	start_transform: Transform3D,
	drop_anchor: Vector3,
	actor: Node3D
) -> void:
	_hat_id = hat_id
	_hat_visual = hat_visual
	_drop_xz = Vector3(drop_anchor.x, 0.0, drop_anchor.z)
	_start_origin = start_transform.origin
	_start_basis = start_transform.basis
	_exclude_rids = GroyperBodyUtils.collect_collision_rids(actor)

	add_child(_hat_visual)
	global_position = _start_origin
	_hat_visual.transform = Transform3D(_start_basis, Vector3.ZERO)
	_end_origin = _compute_resting_position()
	add_to_group(WORLD_PICKUP_GROUP)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_method(_apply_drop_progress, 0.0, 1.0, DROP_DURATION)
	tween.tween_callback(_finish_drop)


func _apply_drop_progress(progress: float) -> void:
	var pos := _start_origin.lerp(_end_origin, progress)
	pos.y += sin(progress * PI) * 0.18 * (1.0 - progress)
	global_position = pos
	if _hat_visual == null:
		return
	var start_q := _start_basis.get_rotation_quaternion()
	var blend_q := start_q.slerp(Quaternion.IDENTITY, progress)
	_hat_visual.transform = Transform3D(Basis(blend_q), Vector3.ZERO)


func _finish_drop() -> void:
	global_position = _compute_resting_position()
	if _hat_visual != null:
		_hat_visual.transform = Transform3D.IDENTITY
	_enable_pickup()


func _compute_resting_position() -> Vector3:
	var ground_y := _sample_ground_y(_drop_xz)
	var saved_position := global_position
	var saved_visual := Transform3D.IDENTITY
	if _hat_visual != null:
		saved_visual = _hat_visual.transform
		global_position = Vector3(_drop_xz.x, ground_y, _drop_xz.z)
		_hat_visual.transform = Transform3D.IDENTITY
	else:
		global_position = Vector3(_drop_xz.x, ground_y, _drop_xz.z)
	var bottom_offset := _measure_origin_to_bottom()
	global_position = saved_position
	if _hat_visual != null:
		_hat_visual.transform = saved_visual
	return Vector3(_drop_xz.x, ground_y + bottom_offset, _drop_xz.z)


func _sample_ground_y(xz_position: Vector3) -> float:
	var world := get_world_3d()
	if world == null:
		return xz_position.y
	return GroyperBodyUtils.sample_floor_y(world, xz_position, _exclude_rids)


func _measure_origin_to_bottom() -> float:
	if _hat_visual == null:
		return 0.0
	var origin_y := global_position.y
	var lowest_y := origin_y
	for node in _hat_visual.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		var aabb := mesh_inst.get_aabb()
		for corner_idx in 8:
			var corner_y := (mesh_inst.global_transform * aabb.get_endpoint(corner_idx)).y
			lowest_y = minf(lowest_y, corner_y)
	return maxf(0.0, origin_y - lowest_y)


func get_interact_hint() -> String:
	if not _pickup_enabled or _picked_up or _hat_id.is_empty():
		return ""
	if PlayerInventory.owns_hat(_hat_id):
		return "Pick up %s" % PlayerInventory.get_hat_display_name(_hat_id)
	return "Take %s" % PlayerInventory.get_hat_display_name(_hat_id)


func interact(player: Node3D) -> void:
	if not _pickup_enabled or _picked_up or player == null or _hat_id.is_empty():
		return
	PlayerInventory.add_hat(_hat_id)
	_picked_up = true
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	queue_free()


func _enable_pickup() -> void:
	if _pickup_enabled or _picked_up:
		return
	_pickup_enabled = true

	_interact_area = Area3D.new()
	_interact_area.name = "InteractArea"
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	_interact_area.monitorable = false
	_interact_area.monitoring = true
	add_child(_interact_area)

	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = PICKUP_RADIUS
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 0.12, 0.0)
	_interact_area.add_child(shape_node)

	_interact_area.body_entered.connect(_on_interact_body_entered)
	_interact_area.body_exited.connect(_on_interact_body_exited)


func _on_interact_body_entered(body: Node3D) -> void:
	if _picked_up or not _pickup_enabled:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_interact_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
