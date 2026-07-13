extends "res://characters/npc_melee_combatant.gd"
class_name ChiefGetchaActor

## Meshy Chief Getcha biped — shared physics and rig wiring for the boss.


func _get_rig_root_name() -> String:
	return "ChiefGetchaRig"


func _bind_animation_player() -> AnimationPlayer:
	return MeshyLocomotionUtils.find_body_animation_player(_body)


func get_model_facing_yaw_for_direction(direction: Vector3) -> float:
	# Same root-rotation compensation as the base, via the Meshy helper.
	var world_yaw := MeshyLocomotionUtils.facing_yaw_for_direction(direction)
	return world_yaw - global_rotation.y
