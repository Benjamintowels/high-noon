extends Node3D

const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
	WOOD_BULLET_COVER.apply_to(self)
	call_deferred("_setup_interior_torch")


func _setup_interior_torch() -> void:
	var wall_torch := get_node_or_null("WallTorch")
	if wall_torch == null:
		return
	var fire := wall_torch.get_node_or_null("Fire")
	if fire != null and fire.has_method("set_respect_day_night"):
		fire.call("set_respect_day_night", false)
