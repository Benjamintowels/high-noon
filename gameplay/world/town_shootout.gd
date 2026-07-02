extends RefCounted
class_name TownShootout

const FactionAffinity := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")


static func rally_becker_boys(aggressor: Node3D, tree: SceneTree) -> void:
	if tree == null or aggressor == null or not is_instance_valid(aggressor):
		return

	var aggressor_faction := FactionAffinity.resolve_faction_id(aggressor)
	if not FactionAffinity.is_hostile(FactionIds.BECKER_BOYS, aggressor_faction):
		return

	if (
		aggressor.is_in_group("overworld_player")
		and aggressor.has_method("enter_overworld_combat")
	):
		aggressor.enter_overworld_combat()

	for npc in tree.get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if npc == aggressor:
			continue
		if npc.has_method("enter_combat"):
			npc.enter_combat(aggressor)


static func rally_groypers(shooter: Node3D, tree: SceneTree) -> void:
	rally_becker_boys(shooter, tree)
