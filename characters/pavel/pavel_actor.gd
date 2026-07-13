extends "res://characters/npc_melee_combatant.gd"
class_name PavelActor

## Meshy Pavel biped — same facing stack as Redo/Baldwin.


func _get_rig_root_name() -> String:
	return "PavelRig"


func _after_bind_rig() -> void:
	# Pavel's imported rig carries a stray transform; zero it before use.
	var rig := _model.get_node_or_null("PavelRig") as Node3D
	if rig != null:
		rig.transform = Transform3D.IDENTITY
