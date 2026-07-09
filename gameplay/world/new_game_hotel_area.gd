extends Node3D

const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
	_enable_wall_collision()
	_restore_prop_physics()
	call_deferred("_setup_wall_lights")


func _enable_wall_collision() -> void:
	for child in get_children():
		if not child.name.begins_with("WallNorth"):
			continue
		var body := child.get_node_or_null("WallBody") as StaticBody3D
		if body == null:
			continue
		body.collision_layer = 1
		body.collision_mask = 1
		for shape_node in body.get_children():
			if shape_node is CollisionShape3D:
				(shape_node as CollisionShape3D).disabled = false


func _restore_prop_physics() -> void:
	for child in get_children():
		if child is StaticBody3D:
			var body := child as StaticBody3D
			if body.collision_layer == 0:
				body.collision_layer = 1
				body.collision_mask = 1


func _setup_wall_lights() -> void:
	for child in get_children():
		if not child.name.begins_with("WallLight"):
			continue
		if child is StaticBody3D:
			var body := child as StaticBody3D
			body.collision_layer = 1
			body.collision_mask = 3
		var fire := child.get_node_or_null("Fire")
		if fire != null and fire.has_method("set_respect_day_night"):
			fire.call("set_respect_day_night", true)
