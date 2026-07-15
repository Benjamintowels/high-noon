extends RefCounted
class_name FactionShowdown

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionScanCacheScript := preload("res://gameplay/faction/faction_scan_cache.gd")


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

	for entry: Dictionary in FactionScanCacheScript.faction_members(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("is_faction_standoff_active") or not npc.is_faction_standoff_active():
			continue
		if not FactionAffinityScript.is_hostile(entry.faction, eliminated_faction):
			continue
		if npc.has_method("celebrate_faction_showdown_victory"):
			npc.celebrate_faction_showdown_victory()

	_notify_civilian_celebrations(tree)


static func _notify_civilian_celebrations(tree: SceneTree) -> void:
	for node in tree.get_nodes_in_group("civilian"):
		if not is_instance_valid(node):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		if node.has_method("celebrate_town_event"):
			node.celebrate_town_event()


static func _count_living_standoff_members(tree: SceneTree, faction_id: StringName) -> int:
	var count := 0
	for entry: Dictionary in FactionScanCacheScript.faction_members(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("is_faction_standoff_active") or not npc.is_faction_standoff_active():
			continue
		if entry.faction != faction_id:
			continue
		count += 1
	return count
