extends RefCounted
class_name FactionRally

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIdsScript := preload("res://gameplay/faction/faction_ids.gd")
const FactionScanCacheScript := preload("res://gameplay/faction/faction_scan_cache.gd")


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
	for entry: Dictionary in FactionScanCacheScript.faction_members(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if entry.faction != victim_faction:
			continue
		if not npc.has_method("set_faction_aggro_level"):
			continue
		var target := _pick_target_for(npc, shooter, shooter_faction, tree)
		if target == null:
			continue
		npc.set_faction_aggro_level(aggro_level, target)


static func propagate_faction_aggro(
	source: Node,
	target: Node3D,
	tree: SceneTree,
	aggro_level: int = 3,
	range_limit: float = 60.0
) -> void:
	if tree == null or source == null or target == null or not is_instance_valid(target):
		return

	var source_faction := FactionAffinityScript.resolve_faction_id(source)
	if source_faction == FactionIdsScript.NEUTRAL:
		return

	var source_pos: Vector3 = source.global_position if source is Node3D else Vector3.ZERO
	var target_faction := FactionAffinityScript.resolve_faction_id(target)

	for entry: Dictionary in FactionScanCacheScript.faction_members(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc) or npc == source:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if entry.faction != source_faction:
			continue
		if not npc.has_method("set_faction_aggro_level"):
			continue
		if range_limit > 0.0:
			if source_pos.distance_to(npc.global_position) > range_limit:
				continue
		if not _is_valid_rally_target(npc, target, target_faction):
			continue
		if npc.has_method("get_faction_aggro_level") and npc.get_faction_aggro_level() >= aggro_level:
			continue
		npc.set_faction_aggro_level(aggro_level, target)


static func propagate_draw_to_allies(drawer: Node3D, tree: SceneTree, range_limit: float) -> void:
	if tree == null or drawer == null:
		return
	if not drawer.has_method("get_faction_id") or not drawer.has_method("get_faction_aggro_level"):
		return

	var drawer_faction: StringName = drawer.get_faction_id()
	var drawer_pos := drawer.global_position

	for entry: Dictionary in FactionScanCacheScript.faction_members(tree):
		var npc: Node3D = entry.node
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
		var draw_target: Node3D = null
		if drawer.has_method("get_faction_aggro_target"):
			draw_target = drawer.get_faction_aggro_target()
		if draw_target == null:
			draw_target = _pick_nearest_hostile_for(npc, tree)
		if draw_target != null:
			npc.set_faction_aggro_level(2, draw_target)


static func _pick_target_for(
	member: Node,
	shooter: Node3D,
	shooter_faction: StringName,
	tree: SceneTree
) -> Node3D:
	if shooter != null and is_instance_valid(shooter):
		if _is_valid_rally_target(member, shooter, shooter_faction):
			return shooter
	return _pick_nearest_hostile_for(member, tree)


static func _is_valid_rally_target(
	member: Node,
	shooter: Node,
	shooter_faction: StringName
) -> bool:
	var member_faction := FactionAffinityScript.resolve_faction_id(member)
	if FactionAffinityScript.is_enemy_faction(member_faction, shooter_faction):
		return true
	if shooter.is_in_group("overworld_player"):
		# Player's live faction is RUN during roguelike runs.
		return FactionAffinityScript.is_enemy_faction(
			member_faction,
			FactionAffinityScript.resolve_faction_id(shooter)
		)
	return false


static func _pick_nearest_hostile_for(member: Node, tree: SceneTree, max_range: float = 24.0) -> Node3D:
	if not member.has_method("get_faction_id"):
		return null

	if member.has_method("get") and member.get("faction_max_engage_range") != null:
		max_range = float(member.get("faction_max_engage_range"))

	var member_faction: StringName = member.get_faction_id()
	var member_pos: Vector3 = member.global_position
	var nearest: Node3D
	var nearest_dist_sq := INF
	var max_range_sq := max_range * max_range

	for entry: Dictionary in FactionScanCacheScript.combatants(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc) or npc == member:
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not FactionAffinityScript.is_enemy_faction(member_faction, entry.faction):
			continue
		var dist_sq := member_pos.distance_squared_to(npc.global_position)
		if dist_sq > max_range_sq or dist_sq >= nearest_dist_sq:
			continue
		nearest_dist_sq = dist_sq
		nearest = npc

	var player := _find_player(tree)
	if player != null and FactionAffinityScript.is_enemy_faction(
		member_faction,
		FactionAffinityScript.resolve_faction_id(player)
	):
		var dist_sq := member_pos.distance_squared_to(player.global_position)
		if dist_sq <= max_range_sq and dist_sq < nearest_dist_sq:
			nearest = player

	return nearest


static func notify_faction_member_eliminated(victim: Node, tree: SceneTree) -> void:
	if tree == null or victim == null:
		return

	var eliminated_faction := FactionAffinityScript.resolve_faction_id(victim)
	if eliminated_faction == FactionIdsScript.NEUTRAL:
		return
	if _count_living_faction_members(tree, eliminated_faction) > 0:
		return

	for npc in tree.get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if not npc.has_method("exit_town_faction_combat_peaceful"):
			continue
		npc.exit_town_faction_combat_peaceful()


static func _count_living_faction_members(tree: SceneTree, faction_id: StringName) -> int:
	var count := 0
	for entry: Dictionary in FactionScanCacheScript.town_combatants(tree):
		var npc: Node3D = entry.node
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if entry.faction != faction_id:
			continue
		count += 1
	return count


static func _find_player(tree: SceneTree) -> Node3D:
	return FactionScanCacheScript.find_player(tree)
