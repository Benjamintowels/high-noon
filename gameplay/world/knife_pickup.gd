extends Area3D
class_name KnifePickup

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const KNIFE_GRIP_SCENE := preload("res://characters/groyper/knife_grip.tscn")

const FLOOR_PAD_HEIGHT := 0.03
const DISPLAY_LIFT := 0.04
const SNAP_RETRY_FRAMES := 3

var _picked_up := false
var _player_in_range: Node3D
var _display_root: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_display_mesh()
	call_deferred("snap_to_floor")
	call_deferred("_retry_snap_to_floor")


func snap_to_floor() -> void:
	var feet_offset := _measure_display_bottom_offset()
	global_position = GroyperBodyUtils.snap_position_to_floor(
		get_world_3d(),
		global_position,
		feet_offset
	)


func _retry_snap_to_floor() -> void:
	for _frame in SNAP_RETRY_FRAMES:
		await get_tree().process_frame
		if _picked_up:
			return
		snap_to_floor()


func get_interact_hint() -> String:
	if _picked_up or PlayerInventory.has_knife:
		return ""
	return "Take Knife"


func interact(player: Node3D) -> void:
	if _picked_up or player == null or PlayerInventory.has_knife:
		return

	PlayerInventory.set_has_knife(true)
	if player.has_method("refresh_knife_visual"):
		player.refresh_knife_visual()

	_picked_up = true
	_hide_display()
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)


func _spawn_display_mesh() -> void:
	_display_root = Node3D.new()
	_display_root.name = "DisplayMesh"
	add_child(_display_root)

	var pad := MeshInstance3D.new()
	pad.name = "GroundPad"
	var pad_mesh := CylinderMesh.new()
	pad_mesh.top_radius = 0.14
	pad_mesh.bottom_radius = 0.16
	pad_mesh.height = FLOOR_PAD_HEIGHT
	pad.mesh = pad_mesh
	var pad_material := StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.52, 0.34, 0.18, 1.0)
	pad_material.roughness = 0.9
	pad.material_override = pad_material
	pad.position = Vector3(0.0, FLOOR_PAD_HEIGHT * 0.5, 0.0)
	_display_root.add_child(pad)

	var grip: Node3D = KNIFE_GRIP_SCENE.instantiate()
	_display_root.add_child(grip)
	grip.rotation_degrees = Vector3(90.0, 0.0, 45.0)
	grip.position = Vector3(0.0, FLOOR_PAD_HEIGHT + DISPLAY_LIFT, 0.0)
	grip.scale = Vector3(1.6, 1.6, 1.6)


func _measure_display_bottom_offset() -> float:
	if _display_root == null:
		return 0.0

	var origin_y := global_position.y
	var lowest_y := origin_y
	for node in _display_root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null:
			continue
		var aabb := mesh_inst.get_aabb()
		for corner_idx in 8:
			var corner_y := (mesh_inst.global_transform * aabb.get_endpoint(corner_idx)).y
			lowest_y = minf(lowest_y, corner_y)
	return maxf(0.0, origin_y - lowest_y)


func _hide_display() -> void:
	if _display_root != null:
		_display_root.visible = false
	visible = false


func _on_body_entered(body: Node3D) -> void:
	if _picked_up or PlayerInventory.has_knife:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
