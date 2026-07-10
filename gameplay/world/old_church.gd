extends Node3D

const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
