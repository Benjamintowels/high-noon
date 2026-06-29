extends RefCounted
class_name FactionShowdown

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")


static func check_after_death(victim: Node, tree: SceneTree) -> void:
	if tree == null or victim == null:
		return
	if not victim.has_method("is_faction_standoff_active"):
		return
	if not victim.is_faction_standoff_active():
		return

	var eliminated_faction := FactionAffinityScript.resolve_faction_id(victim)
	if eliminated_faction == FactionIdsScript.NEUTRAL:
		return
	if _count_living_standoff_members(tree, eliminated_faction) > 0:
		return

	for npc in tree.get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("is_faction_standoff_active") or not npc.is_faction_standoff_active():
			continue
		var npc_faction := FactionAffinityScript.resolve_faction_id(npc)
		if not FactionAffinityScript.is_hostile(npc_faction, eliminated_faction):
			continue
		if npc.has_method("celebrate_faction_showdown_victory"):
			npc.celebrate_faction_showdown_victory()


static func _count_living_standoff_members(tree: SceneTree, faction_id: StringName) -> int:
	var count := 0
	for npc in tree.get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("is_faction_standoff_active") or not npc.is_faction_standoff_active():
			continue
		if FactionAffinityScript.resolve_faction_id(npc) != faction_id:
			continue
		count += 1
	return count
