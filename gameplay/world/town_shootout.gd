extends RefCounted
class_name TownShootout

const FactionAffinity := preload("res://gameplay/faction/faction_affinity.gd")
const FactionIds := preload("res://gameplay/faction/faction_ids.gd")

const WITNESS_RANGE := 60.0
const WITNESS_LOOK_HEIGHT := 1.05


static func rally_becker_boys(aggressor: Node3D, tree: SceneTree) -> void:
	if tree == null or aggressor == null or not is_instance_valid(aggressor):
		return

	var aggressor_faction := FactionAffinity.resolve_faction_id(aggressor)
	if not FactionAffinity.is_hostile(FactionIds.BECKER_BOYS, aggressor_faction):
		return

	_enter_overworld_combat_if_player(aggressor)

	for npc in tree.get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if npc == aggressor:
			continue
		_rally_witness(npc, aggressor)


## Nearby Becker Boys who can see a townsperson being hurt join the fight.
static func rally_becker_boys_on_injury(
	victim: Node3D,
	aggressor: Node3D,
	tree: SceneTree,
	witness_range: float = WITNESS_RANGE
) -> void:
	if tree == null or victim == null or aggressor == null:
		return
	if not is_instance_valid(victim) or not is_instance_valid(aggressor):
		return
	if not _is_becker_boys_injury(aggressor, victim):
		return

	_enter_overworld_combat_if_player(aggressor)

	var victim_pos := victim.global_position
	var range_sq := witness_range * witness_range
	for npc in tree.get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc):
			continue
		if npc.has_method("is_defeated") and npc.is_defeated():
			continue
		if npc == aggressor or npc == victim:
			continue
		if not (npc is Node3D):
			continue
		var witness := npc as Node3D
		if witness.global_position.distance_squared_to(victim_pos) > range_sq:
			continue
		if not _witness_can_see_victim(witness, victim):
			continue
		_rally_witness(npc, aggressor)


static func rally_groypers(shooter: Node3D, tree: SceneTree) -> void:
	rally_becker_boys(shooter, tree)


static func player_harmed_becker_boys(tree: SceneTree) -> bool:
	if tree == null:
		return false

	for npc in tree.get_nodes_in_group("becker_boys"):
		if not is_instance_valid(npc):
			continue
		if not npc.has_method("get_faction_aggro_level"):
			continue
		if npc.get_faction_aggro_level() < 2:
			continue
		if not npc.has_method("get_faction_aggro_target"):
			continue
		var target: Node3D = npc.get_faction_aggro_target()
		if target != null and target.is_in_group("overworld_player"):
			return true

	return false


static func _is_becker_boys_injury(aggressor: Node3D, victim: Node3D) -> bool:
	if not victim.is_in_group("becker_boys"):
		return false
	if aggressor.is_in_group("overworld_player"):
		return true
	var aggressor_faction := FactionAffinity.resolve_faction_id(aggressor)
	return FactionAffinity.is_hostile(FactionIds.BECKER_BOYS, aggressor_faction)


static func _enter_overworld_combat_if_player(aggressor: Node3D) -> void:
	if (
		aggressor.is_in_group("overworld_player")
		and aggressor.has_method("enter_overworld_combat")
	):
		aggressor.enter_overworld_combat()


static func _rally_witness(npc: Node, aggressor: Node3D) -> void:
	if npc.has_method("set_faction_aggro_level"):
		var level := 3
		if npc.has_method("get_faction_aggro_level"):
			level = maxi(npc.get_faction_aggro_level(), 3)
		npc.set_faction_aggro_level(level, aggressor)
		return
	if npc.has_method("enter_combat"):
		npc.enter_combat(aggressor)


static func _witness_can_see_victim(witness: Node3D, victim: Node3D) -> bool:
	var origin := witness.global_position + Vector3(0.0, WITNESS_LOOK_HEIGHT, 0.0)
	var target := victim.global_position + Vector3(0.0, WITNESS_LOOK_HEIGHT, 0.0)
	var world := witness.get_world_3d()
	if world == null:
		return true
	var space_state := world.direct_space_state
	if space_state == null:
		return true

	var query := PhysicsRayQueryParameters3D.create(origin, target)
	var exclude: Array[RID] = [witness.get_rid()]
	if victim is CollisionObject3D:
		exclude.append((victim as CollisionObject3D).get_rid())
	query.exclude = exclude
	query.collide_with_areas = false
	query.collision_mask = 1
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return true
	if hit.collider == victim:
		return true
	return hit.position.distance_to(target) <= 0.55
