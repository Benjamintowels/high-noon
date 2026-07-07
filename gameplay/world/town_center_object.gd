extends StaticBody3D
class_name TownCenterObject

signal health_changed(current: int, maximum: int)
signal destroyed

const MAX_HEALTH := 100

var _health := MAX_HEALTH
var _mesh: MeshInstance3D


func _ready() -> void:
	add_to_group("town_center")
	_setup_visual()
	_setup_collision()


func get_health() -> int:
	return _health


func get_max_health() -> int:
	return MAX_HEALTH


func is_destroyed() -> bool:
	return _health <= 0


func take_damage(amount: int) -> void:
	if amount <= 0 or _health <= 0:
		return

	_health = maxi(_health - amount, 0)
	health_changed.emit(_health, MAX_HEALTH)
	_pulse_damage()

	if _health <= 0:
		destroyed.emit()
		_on_destroyed()


func _setup_visual() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "PlaceholderMesh"
	var pillar := CylinderMesh.new()
	pillar.top_radius = 1.2
	pillar.bottom_radius = 1.4
	pillar.height = 2.4
	_mesh.mesh = pillar
	_mesh.position.y = 1.2

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.62, 0.48, 0.32, 1.0)
	material.roughness = 0.85
	_mesh.material_override = material
	add_child(_mesh)

	var cap := MeshInstance3D.new()
	cap.name = "Cap"
	var cap_mesh := CylinderMesh.new()
	cap_mesh.top_radius = 0.2
	cap_mesh.bottom_radius = 0.35
	cap_mesh.height = 0.5
	cap.mesh = cap_mesh
	cap.position.y = 2.55
	var cap_mat := StandardMaterial3D.new()
	cap_mat.albedo_color = Color(0.78, 0.62, 0.22, 1.0)
	cap_mat.metallic = 0.35
	cap_mat.roughness = 0.4
	cap.material_override = cap_mat
	_mesh.add_child(cap)


func _setup_collision() -> void:
	var shape_node := CollisionShape3D.new()
	var shape := CylinderShape3D.new()
	shape.radius = 1.35
	shape.height = 2.5
	shape_node.shape = shape
	shape_node.position.y = 1.25
	add_child(shape_node)


func _pulse_damage() -> void:
	if _mesh == null:
		return
	var tween := _mesh.create_tween()
	tween.tween_property(_mesh, "scale", Vector3(1.08, 0.92, 1.08), 0.08)
	tween.tween_property(_mesh, "scale", Vector3.ONE, 0.18)


func _on_destroyed() -> void:
	if _mesh == null:
		return
	var material := _mesh.material_override as StandardMaterial3D
	if material != null:
		var tween := create_tween()
		tween.tween_property(material, "albedo_color:a", 0.35, 0.6)
