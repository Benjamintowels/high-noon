extends Area3D

## Ground pickup that grants a stack of dynamite sticks (default 5) and equips it.

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const DynamiteGripScene := preload("res://characters/groyper/dynamite_grip.tscn")

const FLOOR_PAD_HEIGHT := 0.03
const DISPLAY_LIFT := 0.08
const DEFAULT_AMMO := 5

@export var ammo_amount: int = DEFAULT_AMMO
@export var display_scale := 0.85
@export var display_rotation_degrees := Vector3(15.0, 35.0, 12.0)
@export var snap_on_ready := true

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
	if snap_on_ready:
		call_deferred("snap_to_floor")


func snap_to_floor() -> void:
	global_position = GroyperBodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


func get_interact_hint() -> String:
	if _picked_up:
		return ""
	return "Take Dynamite (%d)" % ammo_amount


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return

	PlayerInventory.add_weapon_count(GroyperWeapons.Id.DYNAMITE, ammo_amount)

	if player.has_method("equip_weapon"):
		player.equip_weapon(GroyperWeapons.Id.DYNAMITE)
	if player.has_method("notify_weapon_inventory_changed"):
		player.notify_weapon_inventory_changed()
	if player.has_method("sync_dynamite_ammo_hud"):
		player.sync_dynamite_ammo_hud()

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
	pad_mesh.top_radius = 0.2
	pad_mesh.bottom_radius = 0.22
	pad_mesh.height = FLOOR_PAD_HEIGHT
	pad.mesh = pad_mesh
	var pad_material := StandardMaterial3D.new()
	pad_material.albedo_color = Color(0.35, 0.22, 0.12, 1.0)
	pad_material.roughness = 0.9
	pad.material_override = pad_material
	pad.position = Vector3(0.0, FLOOR_PAD_HEIGHT * 0.5, 0.0)
	_display_root.add_child(pad)

	var grip: Node3D = DynamiteGripScene.instantiate()
	grip.rotation_degrees = display_rotation_degrees
	grip.position = Vector3(0.0, FLOOR_PAD_HEIGHT + DISPLAY_LIFT, 0.0)
	grip.scale = Vector3(display_scale, display_scale, display_scale)
	_display_root.add_child(grip)


func _hide_display() -> void:
	if _display_root != null:
		_display_root.visible = false
	visible = false


func _on_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
