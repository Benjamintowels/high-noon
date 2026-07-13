extends "res://characters/npc_melee_combatant.gd"
class_name RedoActor

## Meshy Redo biped — shared physics and rig wiring for the NPC.


func _get_rig_root_name() -> String:
	return "RedoRig"
