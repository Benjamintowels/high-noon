extends RefCounted
class_name CombatKnockdown

const CombatKnockbackScript := preload("res://gameplay/combat/combat_knockback.gd")

const DRAG_DURATION := 0.55
const SETTLE_DURATION := 1.05
const FALLBACK_STUN := 2.6
const DRAG_PULL_SPEED := 7.5


static func apply_from_reflect(attacker: Node, _defender: Node, hit_info: Dictionary) -> void:
	if attacker == null or not is_instance_valid(attacker):
		return

	if attacker.has_method("apply_reflect_knockdown"):
		attacker.apply_reflect_knockdown(hit_info)
		return

	var fall_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	fall_dir.y = 0.0
	if fall_dir.length_squared() < 0.0001:
		fall_dir = Vector3.FORWARD
	else:
		fall_dir = fall_dir.normalized()

	if attacker.has_method("enter_overworld_combat"):
		attacker.enter_overworld_combat()
	if attacker.has_method("suspend_for_reflect_knockdown"):
		attacker.suspend_for_reflect_knockdown()

	var ragdoll = _get_ragdoll(attacker)
	if ragdoll != null and not ragdoll.is_active():
		_suspend_animations(attacker)
		var anim_player := _get_animation_player(attacker)
		ragdoll.activate_lasso_drag(fall_dir, anim_player)
		attacker.set_meta(&"reflect_knockdown_active", true)
		_drive_drag(attacker, ragdoll, fall_dir * DRAG_PULL_SPEED, 0.0)
		return

	_apply_fallback_stun(attacker, hit_info, fall_dir)


static func _drive_drag(
	target: Node,
	ragdoll,
	pull_velocity: Vector3,
	elapsed: float
) -> void:
	if not is_instance_valid(target) or not is_instance_valid(ragdoll):
		return

	var tick := 0.05
	if elapsed >= DRAG_DURATION:
		_begin_recovery(target, ragdoll)
		return

	ragdoll.update_lasso_pull(pull_velocity, tick)
	if target is CharacterBody3D:
		(target as CharacterBody3D).velocity = Vector3.ZERO

	var tree := target.get_tree()
	if tree == null:
		return
	tree.create_timer(tick).timeout.connect(
		func() -> void:
			_drive_drag(target, ragdoll, pull_velocity, elapsed + tick),
		CONNECT_ONE_SHOT
	)


static func _begin_recovery(target: Node, ragdoll) -> void:
	if is_instance_valid(ragdoll) and ragdoll.is_lasso_drag_mode():
		ragdoll.deactivate_lasso_drag()
	if is_instance_valid(target):
		target.set_meta(&"lasso_soft_loco_resume", true)
		_resume_animations(target)

	var tree := target.get_tree() if is_instance_valid(target) else null
	if tree == null:
		_finish_recovery(target)
		return
	tree.create_timer(SETTLE_DURATION).timeout.connect(
		func() -> void:
			_finish_recovery(target),
		CONNECT_ONE_SHOT
	)


static func _finish_recovery(target: Node) -> void:
	if not is_instance_valid(target):
		return
	if target.has_meta(&"reflect_knockdown_active"):
		target.remove_meta(&"reflect_knockdown_active")
	if target.has_meta(&"lasso_soft_loco_resume"):
		target.remove_meta(&"lasso_soft_loco_resume")
	if target.has_method("resume_from_reflect_knockdown"):
		target.resume_from_reflect_knockdown()
	elif target.has_method("apply_melee_stun"):
		target.apply_melee_stun(0.35)


static func _apply_fallback_stun(attacker: Node, _hit_info: Dictionary, fall_dir: Vector3) -> void:
	if attacker.has_method("apply_melee_stun"):
		attacker.apply_melee_stun(FALLBACK_STUN)
	if attacker is CharacterBody3D and attacker.has_method("hold_knockback_velocity"):
		attacker.hold_knockback_velocity(CombatKnockbackScript.DEFAULT_HOLD)
		var body := attacker as CharacterBody3D
		body.velocity.x = fall_dir.x * DRAG_PULL_SPEED
		body.velocity.z = fall_dir.z * DRAG_PULL_SPEED


static func _get_ragdoll(target: Node):
	if target == null:
		return null
	if target.has_method("get_lasso_ragdoll"):
		return target.call("get_lasso_ragdoll")
	if target.has_method("get"):
		return target.get("_ragdoll")
	return null


static func _get_animation_player(target: Node) -> AnimationPlayer:
	if target.has_method("get_lasso_animation_player"):
		return target.call("get_lasso_animation_player") as AnimationPlayer
	return target.get("_animation_player") as AnimationPlayer


static func _suspend_animations(target: Node) -> void:
	if target.has_method("_suspend_locomotion_animations"):
		target.call("_suspend_locomotion_animations")
		return
	if target.get("_animation_tree") != null:
		var tree: AnimationTree = target.get("_animation_tree")
		if tree != null:
			tree.active = false


static func _resume_animations(target: Node) -> void:
	if target.has_method("_resume_locomotion_animations"):
		target.call("_resume_locomotion_animations")
		return
	if target.get("_animation_tree") != null:
		var tree: AnimationTree = target.get("_animation_tree")
		if tree != null:
			tree.active = true
