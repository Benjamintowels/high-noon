extends RigidBody3D

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

var _broken := false


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _broken:
		return
	_broken = true

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)

	ImpactFXScript.spawn_glass_shatter(self, hit_position, normal, direction)
	queue_free()
