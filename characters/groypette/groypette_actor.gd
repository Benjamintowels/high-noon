extends "res://characters/meshy_biped_actor.gd"
class_name GroypetteActor

## Meshy Groypette biped — shared physics and rig wiring for the NPC.


func _get_rig_root_name() -> String:
	return "GroypetteRig"


func _bind_animation_player() -> AnimationPlayer:
	return MeshyLocomotionUtils.find_body_animation_player(_body)


func _after_bind_rig() -> void:
	MeshyCharacterMaterials.apply_outdoor_skin(_body)
