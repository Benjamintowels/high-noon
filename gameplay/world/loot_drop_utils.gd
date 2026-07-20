extends RefCounted
class_name LootDropUtils

const GramPickupScript := preload("res://gameplay/world/gram_pickup.gd")
const SoulShardPickupScript := preload("res://gameplay/world/soul_shard_pickup.gd")
const WeaponPickupScript := preload("res://gameplay/world/weapon_pickup.gd")
const RevolverAmmoPickupScript := preload("res://gameplay/world/revolver_ammo_pickup.gd")
const ElementalGemPickupScript := preload("res://gameplay/world/elemental_gem_pickup.gd")
const GemEnemyStatusScript := preload("res://gameplay/runs/gem_enemy_status.gd")

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
const WEAPON_LOOT_DROPPED_META := &"_weapon_loot_dropped"


static func try_spawn_for_kill(victim: Node, hit_info: Dictionary = {}) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	if not _is_player_kill(hit_info):
		return

	if RunState.run_active and not victim.get_meta(&"_run_kill_counted", false):
		victim.set_meta(&"_run_kill_counted", true)
		RunState.record_kill()

	try_spawn_weapon_loot_for_kill(victim, hit_info)
	_try_spawn_gem_enemy_drop(victim, hit_info)

	if victim.get_meta(LOOT_DROPPED_META, false):
		return
	if not _should_drop_loot(victim):
		return

	victim.set_meta(LOOT_DROPPED_META, true)

	var soul_shards := resolve_soul_shard_amount(victim)
	var gram := resolve_gram_amount(victim)
	var loot_mult := _run_loot_multiplier()
	if not is_equal_approx(loot_mult, 1.0):
		soul_shards = maxi(0, int(round(float(soul_shards) * loot_mult)))
		gram = maxi(0, int(round(float(gram) * loot_mult)))
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


static func _try_spawn_gem_enemy_drop(victim: Node, hit_info: Dictionary) -> void:
	if not GemEnemyStatusScript.is_gem_enemy(victim):
		return
	if GemEnemyStatusScript.is_fading(victim):
		return
	if bool(victim.get_meta(&"_gem_enemy_loot_dropped", false)):
		return
	var gem_id: StringName = victim.get_meta(GemEnemyStatusScript.GEM_ID_META, &"") as StringName
	if gem_id == &"":
		return
	victim.set_meta(&"_gem_enemy_loot_dropped", true)
	var parent := _resolve_drop_parent(victim)
	var drop_pos := _resolve_drop_position(victim, hit_info)
	ElementalGemPickupScript.spawn_eject_drop(parent, drop_pos, gem_id)


static func resolve_soul_shard_amount(victim: Node) -> int:
	if victim != null and victim.is_in_group("run_enemy"):
		var amount := _jitter_amount(SOUL_SHARDS_BY_TIER[LootTier.ENEMY])
		return _apply_run_enemy_loot_mult(victim, amount)
	if victim.has_method("get_kill_loot_soul_shards"):
		var custom := int(victim.get_kill_loot_soul_shards())
		if custom >= 0:
			return custom
	return _jitter_amount(SOUL_SHARDS_BY_TIER.get(resolve_tier(victim), 1))


static func resolve_gram_amount(victim: Node) -> int:
	if victim != null and victim.is_in_group("run_enemy"):
		var amount := _jitter_amount(GRAM_BY_TIER[LootTier.ENEMY])
		return _apply_run_enemy_loot_mult(victim, amount)
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
	# Run wave enemies use ENEMY tier; elites multiply via run_loot_mult meta.
	if victim.is_in_group("run_enemy"):
		return LootTier.ENEMY
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


static func _apply_run_enemy_loot_mult(victim: Node, amount: int) -> int:
	if amount <= 0:
		return 0
	var mult := 1.0
	if victim.has_meta(&"run_loot_mult"):
		mult = maxf(float(victim.get_meta(&"run_loot_mult")), 0.0)
	return maxi(0, int(round(float(amount) * mult)))


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


static func _run_loot_multiplier() -> float:
	if not RunState.run_active:
		return 1.0
	if not RunState.has_meta("active_run_director"):
		return 1.0
	var director = RunState.get_meta("active_run_director")
	if director == null or not is_instance_valid(director):
		return 1.0
	if director.has_method("get_loot_multiplier"):
		return maxf(float(director.get_loot_multiplier()), 0.05)
	return 1.0


static func try_spawn_weapon_loot_for_kill(victim: Node, hit_info: Dictionary = {}) -> void:
	if victim == null or not is_instance_valid(victim):
		return
	if victim.get_meta(WEAPON_LOOT_DROPPED_META, false):
		return
	if not _is_player_kill(hit_info):
		return
	if victim.is_in_group("overworld_player") or victim.is_in_group("player"):
		return
	if victim.is_in_group("target_scorable"):
		return
	if victim.has_method("drops_weapon_on_death") and not bool(victim.drops_weapon_on_death()):
		return

	var weapon_rig: Node = victim.get_node_or_null("WeaponRig")
	if weapon_rig == null:
		return
	if not weapon_rig.has_method("get_equipped_weapon_id"):
		return
	if not weapon_rig.has_method("is_holstered") or weapon_rig.is_holstered():
		return
	if weapon_rig.has_method("has_holster_grip") and not weapon_rig.has_holster_grip():
		return

	var weapon_id: GroyperWeapons.Id = weapon_rig.get_equipped_weapon_id()
	if victim.has_method("get_kill_loot_weapon_id"):
		var custom_weapon := int(victim.get_kill_loot_weapon_id())
		if custom_weapon < 0:
			return
		weapon_id = custom_weapon as GroyperWeapons.Id
	if not WeaponPickupScript._is_droppable_weapon_id(weapon_id):
		return

	victim.set_meta(WEAPON_LOOT_DROPPED_META, true)
	_clear_victim_weapon_visual(victim)

	var parent := _resolve_drop_parent(victim)
	var drop_pos := _resolve_drop_position(victim, hit_info)
	var side_offset := Vector3(
		cos(randf() * TAU) * 0.32,
		0.0,
		sin(randf() * TAU) * 0.32
	)

	WeaponPickupScript.spawn_death_drop(parent, drop_pos, weapon_id)

	var ammo_amount := _resolve_weapon_ammo_drop_amount(weapon_id)
	if ammo_amount > 0:
		RevolverAmmoPickupScript.spawn_eject_drop(parent, drop_pos + side_offset, ammo_amount)


static func _resolve_weapon_ammo_drop_amount(weapon_id: GroyperWeapons.Id) -> int:
	if not GroyperWeapons.uses_ammo(weapon_id):
		return 0

	var max_ammo := GroyperWeapons.get_max_ammo(weapon_id)
	match weapon_id:
		GroyperWeapons.Id.REVOLVER:
			return randi_range(maxi(1, max_ammo - 2), max_ammo)
		GroyperWeapons.Id.SHOTGUN:
			return randi_range(2, mini(max_ammo, 4))
		_:
			return 0


static func _clear_victim_weapon_visual(victim: Node) -> void:
	var weapon_rig: Node = victim.get_node_or_null("WeaponRig")
	if weapon_rig != null and weapon_rig.has_method("clear_weapon_visual"):
		weapon_rig.clear_weapon_visual()
