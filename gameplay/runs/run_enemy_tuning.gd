extends RefCounted

## Shared run-spawn tuning: groups, health/loot mults, weapons, visual scale,
## speed, and optional gun-reflect armor.

const RUN_MAX_HEALTH_META := &"run_max_health"
const RUN_LOOT_MULT_META := &"run_loot_mult"
const RUN_ELITE_META := &"run_elite"
const RUN_SPEED_MULT_META := &"run_speed_mult"

const CombatHealthReadoutScript := preload("res://gameplay/ui/combat_health_readout.gd")
const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const RunEnemyArmorScript := preload("res://gameplay/runs/run_enemy_armor.gd")


static func apply(
	enemy: Node3D,
	health_mult: float = 1.0,
	loot_mult: float = 1.0,
	is_elite: bool = false,
	visual_scale: float = 1.0,
	weapon_id: int = -1,
	melee_only = null,
	base_max_override: int = -1,
	max_health: int = -1,
	speed_mult: float = 1.0,
	block_health: float = 0.0,
	auto_reflect: bool = false
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

	var resolved_max := max_health
	if resolved_max <= 0:
		var base_max := base_max_override if base_max_override > 0 else _read_base_max_health(enemy)
		resolved_max = maxi(1, int(round(float(base_max) * maxf(health_mult, 0.1))))
	else:
		resolved_max = maxi(1, resolved_max)
	enemy.set_meta(RUN_MAX_HEALTH_META, resolved_max)
	enemy.set_meta(RUN_LOOT_MULT_META, maxf(loot_mult, 0.0))
	if "_health" in enemy:
		enemy.set("_health", resolved_max)

	var resolved_speed := maxf(speed_mult, 0.05)
	if is_equal_approx(resolved_speed, 1.0):
		if enemy.has_meta(RUN_SPEED_MULT_META):
			enemy.remove_meta(RUN_SPEED_MULT_META)
	else:
		enemy.set_meta(RUN_SPEED_MULT_META, resolved_speed)

	if visual_scale > 0.0 and not is_equal_approx(visual_scale, 1.0):
		enemy.scale = Vector3.ONE * visual_scale

	RunEnemyArmorScript.apply(enemy, block_health, auto_reflect)


static func apply_from_opts(enemy: Node3D, opts: Dictionary) -> void:
	apply(
		enemy,
		float(opts.get("health_mult", 1.0)),
		float(opts.get("loot_mult", 1.0)),
		bool(opts.get("elite", false)),
		float(opts.get("visual_scale", 1.0)),
		int(opts.get("weapon_id", -1)),
		opts.get("melee_only", null),
		int(opts.get("base_max_override", -1)),
		int(opts.get("max_health", -1)),
		float(opts.get("speed_mult", 1.0)),
		float(opts.get("block_health", 0.0)),
		bool(opts.get("auto_reflect", false))
	)


static func get_max_health(enemy: Node) -> int:
	if enemy != null and enemy.has_meta(RUN_MAX_HEALTH_META):
		return maxi(1, int(enemy.get_meta(RUN_MAX_HEALTH_META)))
	return -1


static func get_loot_mult(enemy: Node) -> float:
	if enemy != null and enemy.has_meta(RUN_LOOT_MULT_META):
		return maxf(float(enemy.get_meta(RUN_LOOT_MULT_META)), 0.0)
	return 1.0


static func get_speed_mult(enemy: Node) -> float:
	if enemy != null and enemy.has_meta(RUN_SPEED_MULT_META):
		return maxf(float(enemy.get_meta(RUN_SPEED_MULT_META)), 0.05)
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
	var resolved_id := _resolve_weapon_for_enemy(enemy, weapon_id)
	if "equipped_weapon_id" in enemy:
		enemy.set("equipped_weapon_id", resolved_id)
	var rig: Node = enemy.get_node_or_null("WeaponRig")
	if rig != null and is_instance_valid(rig) and rig.has_method("swap_equipped_weapon"):
		rig.call("swap_equipped_weapon", resolved_id)
	if resolved_id == GroyperWeaponsScript.Id.UNARMED and "melee_only" in enemy:
		enemy.set("melee_only", true)
		if rig != null and is_instance_valid(rig) and rig.has_method("clear_weapon_visual"):
			rig.call_deferred("clear_weapon_visual")


static func _resolve_weapon_for_enemy(enemy: Node3D, weapon_id: int) -> int:
	## Sheriff / gun-town casts have no melee FSM — keep them on firearms.
	var path := String(enemy.scene_file_path).to_lower()
	var script_path := ""
	if enemy.get_script() != null:
		script_path = String(enemy.get_script().resource_path).to_lower()
	var is_sheriff := path.contains("sheriff") or script_path.contains("sheriff")
	if not is_sheriff:
		return weapon_id
	if (
		weapon_id == GroyperWeaponsScript.Id.SHOTGUN
		or weapon_id == GroyperWeaponsScript.Id.REVOLVER
	):
		return weapon_id
	return GroyperWeaponsScript.Id.REVOLVER
