extends Node3D
class_name LadderPiece

const INTERACT_RADIUS := 1.75

@export var mount_face_distance := 0.42
@export var top_dismount_forward := 0.9
@export var top_finish_forward := 1.25
@export var top_dismount_up := 0.05

@onready var _interact_area: Area3D = $InteractArea
@onready var _top_interact_area: Area3D = $TopInteractArea
@onready var _bottom_mount: Marker3D = $BottomMount
@onready var _top_mount: Marker3D = $TopMount

var _player_in_bottom_area: Node3D
var _player_in_top_area: Node3D


func _ready() -> void:
	add_to_group("ladder_piece")
	_setup_interact_area()
	_setup_top_interact_area()
	_refresh_mount_markers()


func get_interact_hint() -> String:
	return "Climb"


func interact(player: Node3D) -> void:
	if player == null:
		return
	if player.has_method("can_mount_ladder") and not player.can_mount_ladder():
		return
	if player.has_method("mount_ladder"):
		player.mount_ladder(self)


func should_mount_from_top(player: Node3D) -> bool:
	return player != null and _player_in_top_area == player


func get_bottom_position() -> Vector3:
	return _bottom_mount.global_position


func get_top_position() -> Vector3:
	return _top_mount.global_position


func get_top_dismount_position() -> Vector3:
	return (
		get_top_position()
		+ get_ladder_forward() * top_dismount_forward
		+ Vector3.UP * top_dismount_up
	)


func get_top_finish_dismount_position() -> Vector3:
	return (
		get_top_position()
		+ get_ladder_forward() * top_finish_forward
		+ Vector3.UP * top_dismount_up
	)


func get_ladder_up() -> Vector3:
	var up := get_top_position() - get_bottom_position()
	if up.length_squared() <= 0.0001:
		up = global_transform.basis.y
	return up.normalized()


## Horizontal direction from the ladder toward the climb approach side.
func get_ladder_forward() -> Vector3:
	var forward := -global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		forward = global_transform.basis.x
		forward.y = 0.0
	if forward.length_squared() <= 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


func get_climb_facing_yaw() -> float:
	var face_dir := -get_ladder_forward()
	return atan2(face_dir.x, face_dir.z)


func get_climb_length() -> float:
	return maxf(get_bottom_position().distance_to(get_top_position()), 0.25)


func get_jump_off_direction(player: Node3D) -> Vector3:
	return get_ladder_forward().normalized()


func _setup_interact_area() -> void:
	if _interact_area == null:
		return
	_interact_area.monitoring = true
	_interact_area.monitorable = false
	_interact_area.collision_layer = 0
	_interact_area.collision_mask = 1
	if not _interact_area.body_entered.is_connected(_on_bottom_body_entered):
		_interact_area.body_entered.connect(_on_bottom_body_entered)
	if not _interact_area.body_exited.is_connected(_on_bottom_body_exited):
		_interact_area.body_exited.connect(_on_bottom_body_exited)

	var shape_node := _interact_area.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node != null and shape_node.shape is SphereShape3D:
		(shape_node.shape as SphereShape3D).radius = INTERACT_RADIUS


func _setup_top_interact_area() -> void:
	if _top_interact_area == null:
		return
	_top_interact_area.monitoring = true
	_top_interact_area.monitorable = false
	_top_interact_area.collision_layer = 0
	_top_interact_area.collision_mask = 1
	if not _top_interact_area.body_entered.is_connected(_on_top_body_entered):
		_top_interact_area.body_entered.connect(_on_top_body_entered)
	if not _top_interact_area.body_exited.is_connected(_on_top_body_exited):
		_top_interact_area.body_exited.connect(_on_top_body_exited)


func _refresh_mount_markers() -> void:
	if _bottom_mount == null or _top_mount == null:
		return
	var mesh_inst := _find_ladder_mesh()
	if mesh_inst == null:
		return

	var aabb := mesh_inst.get_aabb()
	var mesh_xform := mesh_inst.transform
	var center_xz := Vector3(aabb.get_center().x, 0.0, aabb.get_center().z)
	var bottom_local := mesh_xform * Vector3(center_xz.x, aabb.position.y, center_xz.z)
	var top_local := mesh_xform * Vector3(
		center_xz.x,
		aabb.position.y + aabb.size.y,
		center_xz.z
	)
	var face_offset := Vector3(0.0, 0.0, -mount_face_distance)
	_bottom_mount.position = bottom_local + face_offset
	_top_mount.position = top_local + face_offset

	var mid := (bottom_local + top_local) * 0.5
	if _interact_area != null:
		_interact_area.position = mid + face_offset
	if _top_interact_area != null:
		_top_interact_area.position = top_local + face_offset


func _find_ladder_mesh() -> MeshInstance3D:
	for child in get_children():
		if child is MeshInstance3D:
			return child
		if child is Node3D:
			var nested := child.get_node_or_null("Ladder") as MeshInstance3D
			if nested != null:
				return nested
	return null


func _register_interactable(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		body.register_interactable(self)


func _maybe_unregister_interactable(body: Node3D) -> void:
	if body == _player_in_bottom_area or body == _player_in_top_area:
		return
	if body is CharacterBody3D and body.has_method("unregister_interactable"):
		body.unregister_interactable(self)


func _on_bottom_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	_player_in_bottom_area = body
	_register_interactable(body)


func _on_bottom_body_exited(body: Node3D) -> void:
	if body == _player_in_bottom_area:
		_player_in_bottom_area = null
	_maybe_unregister_interactable(body)


func _on_top_body_entered(body: Node3D) -> void:
	if not body is CharacterBody3D:
		return
	_player_in_top_area = body
	_register_interactable(body)


func _on_top_body_exited(body: Node3D) -> void:
	if body == _player_in_top_area:
		_player_in_top_area = null
	_maybe_unregister_interactable(body)
