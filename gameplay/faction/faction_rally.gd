extends RefCounted
class_name FactionRally

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")


static func rally_faction_on_injury(
	victim: Node,
	shooter: Node3D,
	tree: SceneTree,
	aggro_level: int = 3
) -> void:
	if tree == null or victim == null:
		return

	var victim_faction := FactionAffinityScript.resolve_faction_id(victim)
	if victim_faction == FactionIdsScript.NEUTRAL:
		return

	var shooter_faction := FactionAffinityScript.resolve_faction_id(shooter)
	for npc in tree.get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		var npc_faction := FactionAffinityScript.resolve_faction_id(npc)
		if npc_faction != victim_faction:
			continue
		if not npc.has_method("set_faction_aggro_level"):
			continue
		var target := _pick_target_for(npc, shooter, shooter_faction, tree)
		if target == null:
			continue
		npc.set_faction_aggro_level(aggro_level, target)


static func propagate_draw_to_allies(drawer: Node3D, tree: SceneTree, range_limit: float) -> void:
	if tree == null or drawer == null:
		return
	if not drawer.has_method("get_faction_id") or not drawer.has_method("get_faction_aggro_level"):
		return

	var drawer_faction: StringName = drawer.get_faction_id()
	var drawer_pos := drawer.global_position

	for npc in tree.get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == drawer:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("get_faction_id") or not npc.has_method("set_faction_aggro_level"):
			continue
		if npc.get_faction_id() != drawer_faction:
			continue
		if npc.get_faction_aggro_level() >= 2:
			continue
		if drawer_pos.distance_to(npc.global_position) > range_limit:
			continue
		var target := _pick_nearest_hostile_for(npc, tree)
		if target != null:
			npc.set_faction_aggro_level(2, target)


static func _pick_target_for(
	member: Node,
	shooter: Node3D,
	shooter_faction: StringName,
	tree: SceneTree
) -> Node3D:
	if shooter != null and is_instance_valid(shooter):
		if FactionAffinityScript.is_hostile(
			FactionAffinityScript.resolve_faction_id(member),
			shooter_faction
		):
			return shooter
	return _pick_nearest_hostile_for(member, tree)


static func _pick_nearest_hostile_for(member: Node, tree: SceneTree) -> Node3D:
	if not member.has_method("get_faction_id"):
		return null

	var member_faction: StringName = member.get_faction_id()
	var member_pos: Vector3 = member.global_position
	var nearest: Node3D
	var nearest_dist_sq := INF

	for npc in tree.get_nodes_in_group("faction_npc"):
		if not is_instance_valid(npc) or npc == member:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		var other_faction := FactionAffinityScript.resolve_faction_id(npc)
		if not FactionAffinityScript.is_hostile(member_faction, other_faction):
			continue
		var dist_sq := member_pos.distance_squared_to(npc.global_position)
		if dist_sq < nearest_dist_sq:
			nearest_dist_sq = dist_sq
			nearest = npc as Node3D

	var player := _find_player(tree)
	if player != null and FactionAffinityScript.is_hostile(member_faction, FactionIdsScript.PLAYER):
		var dist_sq := member_pos.distance_squared_to(player.global_position)
		if dist_sq < nearest_dist_sq:
			nearest = player

	return nearest


static func _find_player(tree: SceneTree) -> Node3D:
	var players := tree.get_nodes_in_group("overworld_player")
	if players.is_empty():
		return null
	return players[0] as Node3D
