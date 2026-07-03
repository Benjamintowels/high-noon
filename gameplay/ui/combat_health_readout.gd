class_name CombatHealthReadout
extends RefCounted

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")


static func read(target: Node) -> Dictionary:
	return {
		"current": _read_current(target),
		"max": _read_max(target),
	}


static func _read_current(target: Node) -> int:
	if target == null:
		return 0
	if target.has_method("get_combat_health"):
		return int(target.call("get_combat_health"))
	var value: Variant = target.get("_health")
	if value != null:
		return int(value)
	return 0


static func _read_max(target: Node) -> int:
	if target == null:
		return 0
	if target.has_method("get_combat_max_health"):
		return int(target.call("get_combat_max_health"))
	var script := target.get_script() as Script
	if script != null:
		var constants: Dictionary = script.get_script_constant_map()
		if constants.has("MAX_HEALTH"):
			return int(constants["MAX_HEALTH"])
	return BulletHitDamageScript.DEFAULT_MAX_HEALTH
