extends StaticBody3D

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")


func apply_bullet_hit(hit_info: Dictionary) -> void:
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	ImpactFXScript.spawn_wood_impact(self, hit_position, normal, direction)
