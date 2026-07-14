extends Area3D
class_name SoulShardPackPickup
## Interactable world pack that goes into inventory and can be used later
## for a large soul-shard grant.

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const SoulShardPickupScript := preload("res://gameplay/world/soul_shard_pickup.gd")

const DISPLAY_LIFT := 0.55

@export var pack_amount := 25
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
	_spawn_display()
	if snap_on_ready:
		call_deferred("snap_to_floor")


func snap_to_floor() -> void:
	global_position = GroyperBodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


func get_interact_hint() -> String:
	if _picked_up:
		return ""
	return "Take Soul Shard Pack (%d)" % pack_amount


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return
	PlayerInventory.add_soul_shard_pack(pack_amount)
	_picked_up = true
	if _display_root != null:
		_display_root.visible = false
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	queue_free()


func _spawn_display() -> void:
	_display_root = Node3D.new()
	_display_root.name = "Display"
	add_child(_display_root)
	_display_root.position = Vector3(0.0, DISPLAY_LIFT, 0.0)

	var shard := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.22, 0.34, 0.14)
	shard.mesh = mesh
	shard.rotation_degrees = Vector3(18.0, 40.0, 12.0)
	var mat := StandardMaterial3D.new()
	var color := SoulShardPickupScript.color_for_xp(pack_amount)
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color.lerp(Color.WHITE, 0.25)
	mat.emission_energy_multiplier = 1.6
	shard.material_override = mat
	_display_root.add_child(shard)

	var label := Label3D.new()
	label.text = "x%d" % pack_amount
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 42
	label.outline_size = 6
	label.position = Vector3(0.0, 0.28, 0.0)
	label.pixel_size = 0.01
	_display_root.add_child(label)


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
