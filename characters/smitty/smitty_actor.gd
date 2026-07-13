extends "res://characters/meshy_biped_actor.gd"
class_name SmittyActor

## Meshy Smitty biped — shared physics and rig wiring for the blacksmith.


func _get_rig_root_name() -> String:
	return "SmittyRig"


func _bind_animation_player() -> AnimationPlayer:
	return MeshyLocomotionUtils.find_body_animation_player(_body)


func _after_bind_rig() -> void:
	MeshyCharacterMaterials.apply_outdoor_skin(_body)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	# Smitty's root never rotates (interior anchor), so no root compensation.
	return MeshyLocomotionUtils.facing_yaw_for_direction(direction)
