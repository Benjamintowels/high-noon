extends Node3D

const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
	call_deferred("_setup_lantern_light")


func _setup_lantern_light() -> void:
	var fire := get_node_or_null("LanternLight")
	if fire != null and fire.has_method("set_respect_day_night"):
		fire.call("set_respect_day_night", true)
