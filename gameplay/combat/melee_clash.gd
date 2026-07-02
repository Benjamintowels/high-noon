extends RefCounted
class_name MeleeClash

const MeleeBlockFXScript := preload("res://gameplay/fx/melee_block_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")

const STUN_MIN := 0.38
const STUN_MAX := 0.62
const KNOCKBACK_SCALE := 0.62
const KNOCKBACK_UP_SCALE := 0.7


## Stun both parties and knock them apart when a melee swing is blocked. Returns stun duration.
static func resolve(defender: Node, attacker: Node, hit_info: Dictionary) -> float:
	var attack_dir := _flat_direction(hit_info)
	var contact_position := _contact_position(defender, attacker)
	var knockback_speed := float(hit_info.get("knockback_speed", 6.5)) * KNOCKBACK_SCALE
	var knockback_up := float(hit_info.get("knockback_up", 1.0)) * KNOCKBACK_UP_SCALE
	var stun_duration := clampf(knockback_speed / 11.0, STUN_MIN, STUN_MAX)

	var sep_dir := _separation_direction(defender, attacker, attack_dir)
	_apply_separation_knockback(defender, sep_dir, knockback_speed, knockback_up)
	_apply_separation_knockback(attacker, -sep_dir, knockback_speed, knockback_up * 0.85)

	if defender.has_method("apply_melee_stun"):
		defender.apply_melee_stun(stun_duration)
	if attacker != null and attacker.has_method("apply_melee_stun"):
		attacker.apply_melee_stun(stun_duration)

	MeleeBlockFXScript.play(defender, attacker, contact_position, sep_dir)
	CombatHitFlashScript.flash_block(defender)
	if attacker != null:
		CombatHitFlashScript.flash_block(attacker)
	CombatKnockbackScript.preserve_velocity(defender, CombatKnockbackScript.DEFAULT_HOLD)
	CombatKnockbackScript.preserve_velocity(attacker, CombatKnockbackScript.DEFAULT_HOLD)

	if defender.has_method("on_melee_clash_blocked"):
		defender.on_melee_clash_blocked(attacker, hit_info, stun_duration)
	if attacker != null and attacker.has_method("on_melee_clash_attacker"):
		attacker.on_melee_clash_attacker(defender, hit_info, stun_duration)

	return stun_duration


static func _apply_separation_knockback(
	body_node: Node,
	direction: Vector3,
	knockback_speed: float,
	knockback_up: float
) -> void:
	if not (body_node is CharacterBody3D):
		return
	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		return
	flat_dir = flat_dir.normalized()
	var body := body_node as CharacterBody3D
	body.velocity.x = flat_dir.x * knockback_speed
	body.velocity.z = flat_dir.z * knockback_speed
	body.velocity.y = maxf(body.velocity.y, knockback_up)


static func _separation_direction(
	defender: Node,
	attacker: Node,
	fallback: Vector3
) -> Vector3:
	if defender is Node3D and attacker is Node3D:
		var sep := (defender as Node3D).global_position - (attacker as Node3D).global_position
		sep.y = 0.0
		if sep.length_squared() > 0.0001:
			return sep.normalized()
	return fallback


static func _flat_direction(hit_info: Dictionary) -> Vector3:
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	direction.y = 0.0
	if direction.length_squared() < 0.0001:
		return Vector3.FORWARD
	return direction.normalized()


static func _contact_position(defender: Node, attacker: Node) -> Vector3:
	if defender is Node3D and attacker is Node3D:
		var midpoint := (
			(defender as Node3D).global_position + (attacker as Node3D).global_position
		) * 0.5
		return midpoint + Vector3(0.0, 1.05, 0.0)
	if defender is Node3D:
		return (defender as Node3D).global_position + Vector3(0.0, 1.05, 0.0)
	return Vector3.ZERO
