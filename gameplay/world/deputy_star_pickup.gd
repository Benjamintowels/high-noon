extends Area3D
class_name DeputyStarPickup

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

var _picked_up := false
var _player_in_range: Node3D
var _display_root: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_star_visual()
	call_deferred("snap_to_floor")


func snap_to_floor() -> void:
	global_position = GroyperBodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


func get_interact_hint() -> String:
	if _picked_up:
		return ""
	return "Take Deputy Star"


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return

	PlayerInventory.set_has_deputy_badge(true)
	DeputyQuest.collect_badge()

	if player.has_method("refresh_deputy_badge_visual"):
		player.refresh_deputy_badge_visual()

	_picked_up = true
	_hide_display()
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)


func _spawn_star_visual() -> void:
	_display_root = Node3D.new()
	_display_root.name = "StarVisual"
	add_child(_display_root)

	for i in 5:
		var point := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, 0.04, 0.32)
		point.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.92, 0.78, 0.18, 1.0)
		material.metallic = 0.65
		material.roughness = 0.28
		point.material_override = material
		var angle := (float(i) / 5.0) * TAU - PI * 0.5
		point.rotation.y = angle
		point.position = Vector3(cos(angle), 0.08, sin(angle)) * 0.22
		_display_root.add_child(point)

	var center := MeshInstance3D.new()
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.1
	center_mesh.bottom_radius = 0.1
	center_mesh.height = 0.05
	center.mesh = center_mesh
	center.position.y = 0.08
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.72, 0.52, 0.12, 1.0)
	center_mat.metallic = 0.5
	center.material_override = center_mat
	_display_root.add_child(center)


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
