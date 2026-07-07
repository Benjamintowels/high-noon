extends StaticBody3D
class_name GrappleAnchor

@export var highlight_color := Color(0.98, 0.82, 0.22, 1.0)
@export var idle_color := Color(0.42, 0.38, 0.34, 1.0)

@onready var _mesh: MeshInstance3D = $BlockMesh
@onready var _attach_point: Node3D = $AttachPoint
@onready var _lock_ring: MeshInstance3D = $LockRing

var _targeted := false
var _lasso_player: Node3D
var _lasso_rope_length := LassoTargetUtils.DEFAULT_ROPE_LENGTH


func _ready() -> void:
	add_to_group("grapple_anchor")
	_apply_color(idle_color)
	if _lock_ring != null:
		_lock_ring.visible = false


func get_grapple_attach_point() -> Vector3:
	if _attach_point != null:
		return _attach_point.global_position
	return global_position + Vector3(0.0, 0.5, 0.0)


func is_lassoable() -> bool:
	return true


func get_lasso_attach_point() -> Vector3:
	return get_grapple_attach_point()


func get_lasso_loose_attach_point() -> Vector3:
	return get_grapple_attach_point()


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func begin_lasso_capture(player: Node3D, rope_length: float, _ring: LassoRing = null) -> void:
	_lasso_player = player
	_lasso_rope_length = rope_length


func end_lasso_capture() -> void:
	_lasso_player = null


func set_targeted(targeted: bool) -> void:
	if _targeted == targeted:
		return
	_targeted = targeted
	_apply_color(highlight_color if targeted else idle_color, targeted)
	if _lock_ring != null:
		_lock_ring.visible = targeted
	if _mesh != null:
		_mesh.scale = Vector3.ONE * (1.08 if targeted else 1.0)


func _apply_color(color: Color, glow: bool = false) -> void:
	if _mesh == null:
		return
	var mat := _mesh.material_override as StandardMaterial3D
	if mat == null:
		mat = StandardMaterial3D.new()
		_mesh.material_override = mat
	mat.albedo_color = color
	mat.emission_enabled = glow
	mat.emission = color * (0.9 if glow else 0.0)
