extends RefCounted
class_name BlockPoise

## Shared guard meter for unarmed + melee blocks (player and NPCs).
## Current poise persists when a guard is released; it only refills after a break.

const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")
const FLOATING_BLOCK_POISE_BAR_PATH := "res://gameplay/ui/floating_block_poise_bar.gd"

const CURRENT_META := &"block_poise_current"
const DEFAULT_BASE_POISE := 3.0
const BREAK_STUN := 0.95

enum Result {
	ABSORBED,
	BROKEN,
}


static func get_base_poise(actor: Node) -> float:
	if actor == null:
		return DEFAULT_BASE_POISE
	if actor.has_method("get_poise"):
		return maxf(float(actor.call("get_poise")), 0.1)
	if "poise" in actor:
		return maxf(float(actor.get("poise")), 0.1)
	return DEFAULT_BASE_POISE


static func get_weapon_bonus(actor: Node) -> float:
	if actor == null:
		return 0.0
	if actor.has_method("get_block_poise_bonus"):
		return maxf(float(actor.call("get_block_poise_bonus")), 0.0)
	if "equipped_weapon" in actor:
		var weapon_id: Variant = actor.get("equipped_weapon")
		if typeof(weapon_id) == TYPE_INT:
			return GroyperWeaponsScript.get_block_poise(weapon_id)
	if "_equipped_weapon" in actor:
		var equipped: Variant = actor.get("_equipped_weapon")
		if typeof(equipped) == TYPE_INT:
			return GroyperWeaponsScript.get_block_poise(equipped)
	return 0.0


static func get_max(actor: Node) -> float:
	return get_base_poise(actor) + get_weapon_bonus(actor)


static func get_current(actor: Node) -> float:
	_ensure(actor)
	return float(actor.get_meta(CURRENT_META))


static func get_ratio(actor: Node) -> float:
	var poise_max := get_max(actor)
	if poise_max <= 0.0:
		return 0.0
	return clampf(get_current(actor) / poise_max, 0.0, 1.0)


static func is_damaged(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return false
	if not actor.has_meta(CURRENT_META):
		return false
	return get_current(actor) + 0.001 < get_max(actor)


## Chip the defender's guard. Caller must already know the hit is blockable.
## Returns ABSORBED or BROKEN. Does not play clash FX — caller handles absorb clash.
static func apply_hit(defender: Node, hit_info: Dictionary) -> Result:
	if defender == null or not is_instance_valid(defender):
		return Result.ABSORBED
	_ensure(defender)
	var amount := _hit_amount(hit_info)
	var current := float(defender.get_meta(CURRENT_META))
	current = maxf(current - amount, 0.0)
	defender.set_meta(CURRENT_META, current)
	_ensure_indicator(defender)
	if current <= 0.0001:
		return Result.BROKEN
	return Result.ABSORBED


## Cancel the guard, flash, stumble/break presentation, then refill for the next block.
static func break_block(defender: Node, attacker: Node, hit_info: Dictionary) -> void:
	if defender == null or not is_instance_valid(defender):
		return
	CombatHitFlashScript.flash_block_break(defender)
	if defender.has_method("on_block_poise_broken"):
		defender.on_block_poise_broken(attacker, hit_info)
	else:
		_default_break(defender, attacker, hit_info)
	# Refill only after a break — releasing block never restores poise.
	defender.set_meta(CURRENT_META, get_max(defender))
	_ensure_indicator(defender)


static func _ensure(actor: Node) -> void:
	if actor == null:
		return
	var poise_max := get_max(actor)
	if not actor.has_meta(CURRENT_META):
		actor.set_meta(CURRENT_META, poise_max)
		return
	var current := float(actor.get_meta(CURRENT_META))
	# Weapon swaps can lower max; never silently refill by raising current.
	if current > poise_max:
		actor.set_meta(CURRENT_META, poise_max)


static func _hit_amount(hit_info: Dictionary) -> float:
	if hit_info.has("chip_damage"):
		return maxf(float(hit_info.get("chip_damage")), 0.0)
	return maxf(float(hit_info.get("damage", 1.0)), 0.0)


static func _ensure_indicator(actor: Node) -> void:
	if not (actor is Node3D):
		return
	# Bosses show poise on BossHealthBar — skip the world-space duplicate.
	if actor.is_in_group("tc_boss") or actor.is_in_group("chief_getcha_boss"):
		return
	# load() avoids a circular preload with floating_block_poise_bar.gd.
	var bar_script: Variant = load(FLOATING_BLOCK_POISE_BAR_PATH)
	if bar_script != null:
		bar_script.attach_to(actor as Node3D)


static func _default_break(defender: Node, attacker: Node, hit_info: Dictionary) -> void:
	if defender.has_method("apply_melee_stun"):
		defender.apply_melee_stun(BREAK_STUN)
	var push_dir := Vector3.FORWARD
	if attacker is Node3D and defender is Node3D:
		push_dir = (defender as Node3D).global_position - (attacker as Node3D).global_position
		push_dir.y = 0.0
		if push_dir.length_squared() < 0.0001:
			push_dir = hit_info.get("direction", Vector3.FORWARD)
	if defender.has_method("_begin_shove_stumble"):
		defender.call("_begin_shove_stumble", push_dir.normalized())
	elif defender.has_method("_end_blocking"):
		defender.call("_end_blocking")
	elif defender.has_method("_end_melee_block"):
		defender.call("_end_melee_block")
	elif defender.has_method("_end_unarmed_block_hold"):
		defender.call("_end_unarmed_block_hold")
