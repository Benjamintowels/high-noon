extends Area3D
class_name MeleeWeaponPickup

## Ground pickup for the one-handed stylized melee weapons (axe / sword). Grants
## the weapon, then equips it so it can be tested immediately.

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const BaldwinBodyUtilsScript := preload("res://characters/baldwin/baldwin_body_utils.gd")

const FLOOR_PAD_HEIGHT := 0.03
const DISPLAY_LIFT := 0.05

@export var weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.AXE_1H
@export var display_scale := 0.7
# Stand the +Y-authored weapon upright on the pad with a slight showcase turn.
@export var display_rotation_degrees := Vector3(0.0, 30.0, 0.0)
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
	return "Take %s" % PlayerInventory.get_weapon_display_name(weapon_id)


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return

	if not PlayerInventory.owns_weapon_type(weapon_id):
		PlayerInventory.add_weapon(weapon_id)

	if player.has_method("equip_weapon"):
		player.equip_weapon(weapon_id)
	if player.has_method("notify_weapon_inventory_changed"):
		player.notify_weapon_inventory_changed()

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
	pad_material.albedo_color = Color(0.52, 0.34, 0.18, 1.0)
	pad_material.roughness = 0.9
	pad.material_override = pad_material
	pad.position = Vector3(0.0, FLOOR_PAD_HEIGHT * 0.5, 0.0)
	_display_root.add_child(pad)

	var grip: Node3D = BaldwinBodyUtilsScript.melee_grip_scene_for(weapon_id).instantiate()
	grip.rotation_degrees = display_rotation_degrees
	grip.position = Vector3(0.0, FLOOR_PAD_HEIGHT + DISPLAY_LIFT, 0.0)
	# Stats override (holster mount scale); otherwise the scene export.
	var s := display_scale
	if GroyperWeapons.get_stats(weapon_id).has("pickup_display_scale"):
		s = GroyperWeapons.get_pickup_display_scale(weapon_id)
	grip.scale = Vector3(s, s, s)
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
