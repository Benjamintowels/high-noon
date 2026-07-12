extends RefCounted
class_name TwoHandImpactFX

## Impact feedback package for the slow, heavy two-handed melee strikes:
## the shared melee hit flash plus a ground dust burst and a stronger
## camera shake than one-handed hits.

const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

const ATTACKER_SHAKE := 0.75
const HIT_DUST_COUNT := 5


static func play_hit(attacker: Node3D, target: Node, direction: Vector3) -> void:
	if target == null or not (target is Node3D):
		return
	var hit_position := _get_target_anchor(target as Node3D)
	MeleeHitFXScript.play(attacker, target, hit_position, direction)

	var fx_parent := ImpactFXScript.parent_for(target)
	var ground_position := (target as Node3D).global_position + Vector3(0.0, 0.12, 0.0)
	SmokePuffFXScript.spawn_burst(fx_parent, ground_position, HIT_DUST_COUNT)

	if attacker != null and attacker.has_method("apply_camera_shake"):
		attacker.apply_camera_shake(ATTACKER_SHAKE)


static func _get_target_anchor(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.05, 0.0))
	return target.global_position + Vector3(0.0, 1.05, 0.0)
