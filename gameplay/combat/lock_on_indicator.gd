extends Node3D
class_name LockOnIndicator

const CombatLockOnScript := preload("res://gameplay/combat/combat_lock_on.gd")

const TRIANGLE_WIDTH := 0.34
const TRIANGLE_HEIGHT := 0.26

@export var height_above_anchor := 1.524

var _target: Node3D
var _custom_aim_point: Vector3
var _use_custom_aim := false
var _mesh: MeshInstance3D


func _ready() -> void:
	_mesh = MeshInstance3D.new()
	_mesh.name = "Triangle"
	_mesh.mesh = _build_triangle_mesh()
	_mesh.material_override = _build_material()
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_mesh)
	visible = false


func set_target(target: Node3D, aim_point_override: Vector3 = Vector3.INF) -> void:
	if target == null or not is_instance_valid(target):
		clear()
		return
	_target = target
	if aim_point_override != Vector3.INF:
		_use_custom_aim = true
		_custom_aim_point = aim_point_override
	else:
		_use_custom_aim = false
	visible = true


func clear() -> void:
	_target = null
	_use_custom_aim = false
	visible = false


func _process(_delta: float) -> void:
	if _target == null or not is_instance_valid(_target):
		clear()
		return

	global_position = _resolve_anchor(_target)

	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	var to_camera := camera.global_position - global_position
	to_camera.y = 0.0
	if to_camera.length_squared() < 0.0001:
		return
	look_at(global_position + to_camera.normalized(), Vector3.UP)


func _resolve_anchor(target: Node3D) -> Vector3:
	var anchor: Vector3
	if _use_custom_aim:
		anchor = _custom_aim_point
	else:
		anchor = CombatLockOnScript.get_aim_point(target)
		if target.has_method("get_bullet_capsule"):
			var capsule: Dictionary = target.get_bullet_capsule()
			var center: Vector3 = capsule.get("center", anchor)
			var half_height: float = capsule.get("half_height", 0.75)
			var radius: float = capsule.get("radius", 0.5)
			anchor = center
			anchor.y += half_height + radius * 0.2
	return anchor + Vector3(0.0, height_above_anchor, 0.0)


static func _build_triangle_mesh() -> ArrayMesh:
	var half_w := TRIANGLE_WIDTH * 0.5
	var tip := Vector3(0.0, -TRIANGLE_HEIGHT * 0.5, 0.0)
	var left := Vector3(-half_w, TRIANGLE_HEIGHT * 0.5, 0.0)
	var right := Vector3(half_w, TRIANGLE_HEIGHT * 0.5, 0.0)

	var normals := PackedVector3Array([Vector3.BACK, Vector3.BACK, Vector3.BACK])
	var vertices := PackedVector3Array([tip, left, right])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 1.0, 1.0, 0.95)
	material.emission_enabled = true
	material.emission = Color(1.0, 1.0, 1.0)
	material.emission_energy_multiplier = 0.35
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material
