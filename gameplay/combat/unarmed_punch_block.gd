extends RefCounted
class_name UnarmedPunchBlock

const MeleeClashScript := preload("res://gameplay/combat/melee_clash.gd")

const FACING_DOT_MIN := 0.32


## Returns true when an unarmed defender is actively blocking a punch (not knives or gunfire).
static func can_block_punch(defender: Node, hit_info: Dictionary) -> bool:
	if defender == null or not is_instance_valid(defender):
		return false
	if not bool(hit_info.get("melee", false)):
		return false
	if bool(hit_info.get("knife_hit", false)) or bool(hit_info.get("sword_hit", false)):
		return false
	if not bool(hit_info.get("punch_hit", false)) and not hit_info.has("chip_damage"):
		return false
	if not defender.has_method("is_unarmed_blocking") or not defender.is_unarmed_blocking():
		return false
	if defender.has_method("is_facing_punch_block"):
		return defender.is_facing_punch_block(hit_info)
	return _default_facing_check(defender, hit_info)


static func resolve(attacker: Node, defender: Node, hit_info: Dictionary) -> bool:
	if defender == null:
		return false
	MeleeClashScript.resolve(defender, attacker, hit_info)
	return true


static func _default_facing_check(defender: Node, hit_info: Dictionary) -> bool:
	var attacker: Node = hit_info.get("shooter")
	if defender is Node3D and attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - (defender as Node3D).global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			var forward := Vector3.FORWARD
			if defender.has_method("get_punch_facing_direction"):
				forward = defender.get_punch_facing_direction()
			elif defender is Node3D:
				forward = -(defender as Node3D).global_transform.basis.z
				forward.y = 0.0
			if forward.length_squared() > 0.0001:
				return forward.normalized().dot(to_attacker.normalized()) >= FACING_DOT_MIN
	return true
