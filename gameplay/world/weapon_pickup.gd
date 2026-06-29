extends Area3D
class_name WeaponPickup

@export var weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.AWP

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


func get_interact_hint() -> String:
	if _picked_up:
		return ""
	return "Take %s" % PlayerInventory.get_weapon_display_name(weapon_id)


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return

	if not PlayerInventory.owns_weapon_type(weapon_id):
		PlayerInventory.add_weapon(weapon_id)

	if player.has_method("refresh_stowed_weapon_visuals"):
		player.refresh_stowed_weapon_visuals()

	_picked_up = true
	_hide_display()
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)


func _spawn_display_mesh() -> void:
	_display_root = Node3D.new()
	_display_root.name = "DisplayMesh"
	add_child(_display_root)

	var grip_scene := GroyperWeapons.get_grip_scene(weapon_id)
	var grip: Node3D = grip_scene.instantiate()
	_display_root.add_child(grip)
	grip.rotation_degrees = Vector3(0.0, 90.0, 0.0)
	grip.scale = _get_display_scale()


func _get_display_scale() -> Vector3:
	match weapon_id:
		GroyperWeapons.Id.SHOTGUN, GroyperWeapons.Id.AWP, GroyperWeapons.Id.AK47:
			return Vector3(1.1, 1.1, 1.1)
		GroyperWeapons.Id.LASSO:
			return Vector3(1.8, 1.8, 1.8)
		_:
			return Vector3(1.35, 1.35, 1.35)


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
