extends CollisionObject3D

## Marks this body as invisible to OverworldCameraArm occlusion rays.


func _ready() -> void:
	add_to_group("camera_ray_exclude")
