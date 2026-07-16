extends RefCounted

## Shared run-spawn tuning: groups, health/loot mults, weapons, visual scale.

const RUN_MAX_HEALTH_META := &"run_max_health"
const RUN_LOOT_MULT_META := &"run_loot_mult"
const RUN_ELITE_META := &"run_elite"

const CombatHealthReadoutScript := preload("res://gameplay/ui/combat_health_readout.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")


static func apply(
	enemy: Node3D,
	health_mult: float = 1.0,
	loot_mult: float = 1.0,
	is_elite: bool = false,
	visual_scale: float = 1.0,
	weapon_id: int = -1,
	melee_only = null,
	base_max_override: int = -1
) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return

	if not enemy.is_in_group("cave_enemy"):
		enemy.add_to_group("cave_enemy")
	if not enemy.is_in_group("run_enemy"):
		enemy.add_to_group("run_enemy")
	if is_elite:
		enemy.add_to_group("run_elite")
		enemy.set_meta(RUN_ELITE_META, true)

	if melee_only != null and "melee_only" in enemy:
		enemy.set("melee_only", bool(melee_only))

	if weapon_id >= 0:
		_apply_weapon(enemy, weapon_id)

	var base_max := base_max_override if base_max_override > 0 else _read_base_max_health(enemy)
	var max_health := maxi(1, int(round(float(base_max) * maxf(health_mult, 0.1))))
	enemy.set_meta(RUN_MAX_HEALTH_META, max_health)
	enemy.set_meta(RUN_LOOT_MULT_META, maxf(loot_mult, 0.0))
	if "_health" in enemy:
		enemy.set("_health", max_health)

	if visual_scale > 0.0 and not is_equal_approx(visual_scale, 1.0):
		enemy.scale = Vector3.ONE * visual_scale


static func get_max_health(enemy: Node) -> int:
	if enemy != null and enemy.has_meta(RUN_MAX_HEALTH_META):
		return maxi(1, int(enemy.get_meta(RUN_MAX_HEALTH_META)))
	return -1


static func get_loot_mult(enemy: Node) -> float:
	if enemy != null and enemy.has_meta(RUN_LOOT_MULT_META):
		return maxf(float(enemy.get_meta(RUN_LOOT_MULT_META)), 0.0)
	return 1.0


static func _read_base_max_health(enemy: Node3D) -> int:
	if enemy.has_method("get_combat_max_health") and not enemy.has_meta(RUN_MAX_HEALTH_META):
		var value := int(enemy.call("get_combat_max_health"))
		if value > 0:
			return value
	var readout := CombatHealthReadoutScript.read(enemy)
	var current_max := int(readout.get("max", 0))
	if current_max > 0:
		return current_max
	return BulletHitDamageScript.DEFAULT_MAX_HEALTH


static func _apply_weapon(enemy: Node3D, weapon_id: int) -> void:
	if "equipped_weapon_id" in enemy:
		enemy.set("equipped_weapon_id", weapon_id)
	var rig: Node = enemy.get_node_or_null("WeaponRig")
	if rig != null and rig.has_method("swap_equipped_weapon"):
		rig.call("swap_equipped_weapon", weapon_id)
	elif (
		rig != null
		and rig.has_method("setup")
		and enemy.has_method("get")
	):
		# Fallback: some rigs only equip during setup.
		pass
	if weapon_id == GroyperWeaponsScript.Id.UNARMED and "melee_only" in enemy:
		enemy.set("melee_only", true)
		if rig != null and rig.has_method("clear_weapon_visual"):
			rig.call_deferred("clear_weapon_visual")
