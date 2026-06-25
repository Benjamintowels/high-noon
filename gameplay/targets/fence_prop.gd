extends RigidBody3D

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

@export var knockback_force := 16.0
@export var knockback_torque := 9.0
@export var use_metal_fx := false


func apply_bullet_hit(hit_info: Dictionary) -> void:
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

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
