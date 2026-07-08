extends RefCounted
class_name LootDropUtils

const GramPickupScript := preload("res://gameplay/world/gram_pickup.gd")
const SoulShardPickupScript := preload("res://gameplay/world/soul_shard_pickup.gd")

enum LootTier { TRIVIAL, CIVILIAN, ENEMY, ELITE, BOSS }

const SOUL_SHARDS_BY_TIER := {
	LootTier.TRIVIAL: 1,
	LootTier.CIVILIAN: 2,
	LootTier.ENEMY: 4,
	LootTier.ELITE: 10,
	LootTier.BOSS: 40,
}

const GRAM_BY_TIER := {
	LootTier.TRIVIAL: 1,
	LootTier.CIVILIAN: 2,
	LootTier.ENEMY: 3,
	LootTier.ELITE: 8,
	LootTier.BOSS: 25,
}

const LOOT_DROPPED_META := &"_loot_dropped"


static func try_spawn_for_kill(victim: Node, hit_info: Dictionary = {}) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	if victim.get_meta(LOOT_DROPPED_META, false):
		return
	if not _should_drop_loot(victim):
		return
	if not _is_player_kill(hit_info):
		return

	victim.set_meta(LOOT_DROPPED_META, true)

	var soul_shards := resolve_soul_shard_amount(victim)
	var gram := resolve_gram_amount(victim)
	if soul_shards <= 0 and gram <= 0:
		return

	var parent := _resolve_drop_parent(victim)
	var drop_pos := _resolve_drop_position(victim, hit_info)
	var side_offset := Vector3(
		cos(randf() * TAU) * 0.28,
		0.0,
		sin(randf() * TAU) * 0.28
	)

	if soul_shards > 0:
		SoulShardPickupScript.spawn_eject_drop(parent, drop_pos, soul_shards)
	if gram > 0:
		GramPickupScript.spawn_eject_drop(parent, drop_pos + side_offset, gram)


static func resolve_soul_shard_amount(victim: Node) -> int:
	if victim.has_method("get_kill_loot_soul_shards"):
		var custom := int(victim.get_kill_loot_soul_shards())
		if custom >= 0:
			return custom
	return _jitter_amount(SOUL_SHARDS_BY_TIER.get(resolve_tier(victim), 1))


static func resolve_gram_amount(victim: Node) -> int:
	if victim.has_method("get_kill_loot_gram"):
		var custom := int(victim.get_kill_loot_gram())
		if custom >= 0:
			return custom
	return _jitter_amount(GRAM_BY_TIER.get(resolve_tier(victim), 1))


static func resolve_tier(victim: Node) -> int:
	if victim.has_method("get_kill_loot_tier"):
		return int(victim.get_kill_loot_tier())
	if victim.is_in_group("tc_boss"):
		return LootTier.BOSS
	if victim.is_in_group("undead_npc") or victim.is_in_group("redo_npc") or victim.is_in_group("pavel_npc"):
		return LootTier.ELITE
	if (
		victim.is_in_group("cave_enemy")
		or victim.is_in_group("ruins_enemy")
		or victim.is_in_group("stupid_horse")
	):
		return LootTier.ENEMY
	if victim.is_in_group("ground_bird"):
		return LootTier.TRIVIAL
	if (
		victim.is_in_group("town_npc")
		or victim.is_in_group("civilian")
		or victim.is_in_group("groypette_npc")
	):
		return LootTier.CIVILIAN
	return LootTier.ENEMY


static func _should_drop_loot(victim: Node) -> bool:
	if victim.is_in_group("overworld_player") or victim.is_in_group("player"):
		return false
	if victim.is_in_group("target_scorable"):
		return false
	if victim.has_method("drops_kill_loot"):
		return bool(victim.drops_kill_loot())
	return true


static func _is_player_kill(hit_info: Dictionary) -> bool:
	var shooter: Node = hit_info.get("shooter")
	if shooter == null or not is_instance_valid(shooter):
		return false
	return shooter.is_in_group("overworld_player") or shooter.is_in_group("player")


static func _resolve_drop_parent(victim: Node) -> Node:
	var tree := victim.get_tree()
	if tree != null and tree.current_scene != null:
		return tree.current_scene
	return victim.get_parent()


static func _resolve_drop_position(victim: Node, hit_info: Dictionary) -> Vector3:
	if not hit_info.is_empty() and hit_info.has("position"):
		return hit_info.position
	if victim is Node3D:
		return (victim as Node3D).global_position + Vector3(0.0, 0.85, 0.0)
	return Vector3.ZERO


static func _jitter_amount(base_amount: int) -> int:
	if base_amount <= 0:
		return 0
	return maxi(1, int(round(float(base_amount) * randf_range(0.85, 1.15))))
