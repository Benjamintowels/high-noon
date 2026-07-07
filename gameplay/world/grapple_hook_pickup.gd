extends Area3D
class_name GrappleHookPickup

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const FLOOR_PAD_HEIGHT := 0.03
const DISPLAY_LIFT := 0.06

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


func snap_to_floor() -> void:
	global_position = GroyperBodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


func get_interact_hint() -> String:
	if _picked_up or PlayerInventory.has_grapple_hook:
		return ""
	return "Take Grapple Hook"


func interact(player: Node3D) -> void:
	if _picked_up or player == null or PlayerInventory.has_grapple_hook:
		return

	PlayerInventory.set_has_grapple_hook(true)
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
	pad_mesh.top_radius = 0.24
	pad_mesh.bottom_radius = 0.26
	pad_mesh.height = FLOOR_PAD_HEIGHT
	pad.mesh = pad_mesh
	var pad_material := StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.42, 0.34, 0.22, 1.0)
	pad_material.roughness = 0.9
	pad.material_override = pad_material
	pad.position = Vector3(0.0, FLOOR_PAD_HEIGHT * 0.5, 0.0)
	_display_root.add_child(pad)

	var hook := MeshInstance3D.new()
	hook.name = "HookVisual"
	var hook_mesh := CylinderMesh.new()
	hook_mesh.top_radius = 0.04
	hook_mesh.bottom_radius = 0.07
	hook_mesh.height = 0.22
	hook.mesh = hook_mesh
	hook.rotation_degrees = Vector3(35.0, 45.0, 0.0)
	var hook_material := StandardMaterial3D.new()
	hook_material.albedo_color = Color(0.58, 0.54, 0.48, 1.0)
	hook_material.metallic = 0.7
	hook_material.roughness = 0.35
	hook.material_override = hook_material
	hook.position = Vector3(0.0, FLOOR_PAD_HEIGHT + DISPLAY_LIFT + 0.08, 0.0)
	_display_root.add_child(hook)

	var coil := MeshInstance3D.new()
	coil.name = "CoilVisual"
	var coil_mesh := TorusMesh.new()
	coil_mesh.inner_radius = 0.08
	coil_mesh.outer_radius = 0.12
	coil.mesh = coil_mesh
	coil.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	coil.material_override = hook_material
	coil.position = Vector3(0.12, FLOOR_PAD_HEIGHT + DISPLAY_LIFT, 0.0)
	_display_root.add_child(coil)


func _hide_display() -> void:
	if _display_root != null:
		_display_root.visible = false
	visible = false


func _on_body_entered(body: Node3D) -> void:
	if _picked_up or PlayerInventory.has_grapple_hook:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
