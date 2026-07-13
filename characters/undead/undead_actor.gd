extends "res://characters/npc_melee_combatant.gd"
class_name UndeadActor

## Meshy Ironbone Undead biped — shared physics and rig wiring for the NPC.


func _get_rig_root_name() -> String:
	return "UndeadRig"


func _after_bind_rig() -> void:
	# Some undead body meshes import hidden/shadowless; force them on.
	if _body == null:
		return
	for node in _body.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		mesh.visible = true
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
