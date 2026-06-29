extends RefCounted
class_name TownShootout


static func rally_groypers(shooter: Node3D, tree: SceneTree) -> void:
	if tree == null:
		return

	if shooter != null and shooter.has_method("enter_overworld_combat"):
		shooter.enter_overworld_combat()

	for group_name: StringName in [&"town_groyper", &"town_fast"]:
		for npc in tree.get_nodes_in_group(group_name):
			if not is_instance_valid(npc):
				continue
			if npc.has_method("is_defeated") and npc.is_defeated():
				continue
			if npc.has_method("enter_combat"):
				npc.enter_combat(shooter)
