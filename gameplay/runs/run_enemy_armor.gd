extends RefCounted

## Passive gun shield for tiered run enemies. Reflects ranged hits until block
## health is depleted, then stays broken for the rest of the fight.

const BossGunResilienceScript := preload("res://gameplay/combat/boss_gun_resilience.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const FloatingBlockPoiseBarScript := preload("res://gameplay/ui/floating_block_poise_bar.gd")

const BLOCK_HEALTH_META := &"run_block_health"
const BLOCK_CURRENT_META := &"run_block_current"
const ARMOR_BROKEN_META := &"run_armor_broken"
const AUTO_REFLECT_META := &"run_auto_reflect"

const BREAK_STUN := 0.95


static func apply(enemy: Node, block_health: float, auto_reflect: bool = true) -> void:
	if enemy == null or not is_instance_valid(enemy):
		return
	if block_health <= 0.0:
		_clear(enemy)
		return
	enemy.set_meta(BLOCK_HEALTH_META, block_health)
	enemy.set_meta(BLOCK_CURRENT_META, block_health)
	enemy.set_meta(ARMOR_BROKEN_META, false)
	enemy.set_meta(AUTO_REFLECT_META, auto_reflect)
	if enemy is Node3D:
		FloatingBlockPoiseBarScript.attach_to(enemy as Node3D)


static func has_armor(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return false
	return enemy.has_meta(BLOCK_HEALTH_META) and float(enemy.get_meta(BLOCK_HEALTH_META)) > 0.0


static func is_broken(enemy: Node) -> bool:
	if enemy == null or not is_instance_valid(enemy):
		return true
	return bool(enemy.get_meta(ARMOR_BROKEN_META, true))


static func get_max(enemy: Node) -> float:
	if not has_armor(enemy):
		return 0.0
	return maxf(float(enemy.get_meta(BLOCK_HEALTH_META)), 0.0)


static func get_current(enemy: Node) -> float:
	if not has_armor(enemy) or is_broken(enemy):
		return 0.0
	return maxf(float(enemy.get_meta(BLOCK_CURRENT_META, 0.0)), 0.0)


static func get_ratio(enemy: Node) -> float:
	var poise_max := get_max(enemy)
	if poise_max <= 0.0:
		return 0.0
	return clampf(get_current(enemy) / poise_max, 0.0, 1.0)


## Returns true when the hit was absorbed (caller should early-out).
static func try_handle_hit(enemy: Node, hit_info: Dictionary) -> bool:
	if not has_armor(enemy) or is_broken(enemy):
		return false
	if bool(hit_info.get("melee", false)):
		return false
	if bool(hit_info.get("reflected_hit", false)) or bool(hit_info.get("boss_reflected", false)):
		return false
	if not BossGunResilienceScript.is_ranged_gun_hit(hit_info):
		# Explosives still chip the shield hard but do not reflect.
		if not BossGunResilienceScript.is_explosive_hit(hit_info):
			return false

	var chip := maxf(float(hit_info.get("chip_damage", hit_info.get("damage", 1.0))), 0.5)
	var current := get_current(enemy) - chip
	enemy.set_meta(BLOCK_CURRENT_META, maxf(current, 0.0))
	var in_tree := enemy.is_inside_tree()
	if in_tree and enemy is Node3D:
		FloatingBlockPoiseBarScript.attach_to(enemy as Node3D)
	if in_tree:
		CombatHitFlashScript.flash_block(enemy)

	if current > 0.0001:
		if (
			in_tree
			and bool(enemy.get_meta(AUTO_REFLECT_META, true))
			and BossGunResilienceScript.is_ranged_gun_hit(hit_info)
		):
			BossGunResilienceScript.try_reflect_ranged(enemy, hit_info)
		return true

	_break_armor(enemy, hit_info)
	return true


static func _break_armor(enemy: Node, hit_info: Dictionary) -> void:
	enemy.set_meta(ARMOR_BROKEN_META, true)
	enemy.set_meta(BLOCK_CURRENT_META, 0.0)
	if enemy.is_inside_tree():
		CombatHitFlashScript.flash_block_break(enemy)
	var attacker: Node = hit_info.get("shooter")
	if enemy.has_method("on_block_poise_broken"):
		enemy.call("on_block_poise_broken", attacker, hit_info)
	elif enemy.has_method("apply_melee_stun"):
		enemy.call("apply_melee_stun", BREAK_STUN)
	if enemy.is_inside_tree() and enemy is Node3D:
		FloatingBlockPoiseBarScript.attach_to(enemy as Node3D)


static func _clear(enemy: Node) -> void:
	if enemy == null:
		return
	for key in [BLOCK_HEALTH_META, BLOCK_CURRENT_META, ARMOR_BROKEN_META, AUTO_REFLECT_META]:
		if enemy.has_meta(key):
			enemy.remove_meta(key)
