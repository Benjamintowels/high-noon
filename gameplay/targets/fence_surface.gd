extends StaticBody3D

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

@export var surface_kind: ImpactFX.SurfaceKind = ImpactFX.SurfaceKind.WOOD


func apply_bullet_hit(hit_info: Dictionary) -> void:
	var hit_position: Vector3 = hit_info.get("position", global_position)
	var normal: Vector3 = hit_info.get("normal", Vector3.UP)
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	var collider: Object = hit_info.get("collider")
	var mark_root := ImpactFXScript.mark_root_for(collider if collider is Node else self)
	if mark_root == null:
		mark_root = self
	ImpactFXScript.spawn_surface_impact(mark_root, hit_position, normal, direction, surface_kind)
