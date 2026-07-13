extends "res://characters/npc_melee_combatant.gd"
class_name TcActor

## Meshy TC biped — shared physics and rig wiring for the boss.


func _get_rig_root_name() -> String:
	return "TcRig"
