extends RigidBody3D
class_name TargetScorable

signal scored(scorer_id: String)

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

enum PropStyle { KNOCK_OFF, SHATTER }

@export var prop_style: PropStyle = PropStyle.KNOCK_OFF
@export var knockback_force := 16.0
@export var knockback_torque := 9.0
@export var use_metal_fx := false

var _scored := false


func _ready() -> void:
	add_to_group("target_scorable")
	freeze = true


func is_scored() -> bool:
	return _scored


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _scored:
		return

	var scorer_id := _scorer_id_from_hit(hit_info)
	if scorer_id.is_empty():
		return

	_scored = true
	scored.emit(scorer_id)

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

	if prop_style == PropStyle.SHATTER:
		ImpactFXScript.spawn_glass_shatter(self, hit_position, normal, direction)
		queue_free()
		return

	if freeze:
		freeze = false

	var offset := hit_position - global_position
	apply_impulse(direction * knockback_force, offset)
	apply_torque_impulse(Vector3(
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0),
		randf_range(-1.0, 1.0)
	).normalized() * knockback_torque)

	if use_metal_fx:
		ImpactFXScript.spawn_metal_impact(self, hit_position, normal, direction)
	else:
		ImpactFXScript.spawn_generic_impact(self, hit_position, normal, direction)


func _scorer_id_from_hit(hit_info: Dictionary) -> String:
	var shooter: Node = hit_info.get("shooter")
	if shooter == null:
		return ""
	if shooter.is_in_group("target_player"):
		return "player"
	if shooter.is_in_group("target_rival"):
		return "enemy"
	return ""
