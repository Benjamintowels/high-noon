class_name LassoHumanoidDrag

const LassoTautDragScript := preload("res://gameplay/lasso/lasso_taut_drag.gd")
const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")


static func apply(
	npc: Node,
	body: CharacterBody3D,
	player: Node3D,
	ring: LassoRing,
	rope_length: float,
	delta: float
) -> Dictionary:
	var ragdoll = _get_ragdoll(npc)
	var was_ragdoll_drag: bool = ragdoll != null and ragdoll.is_lasso_drag_mode()

	var info: Dictionary = LassoTautDragScript.apply(
		body,
		npc,
		player,
		rope_length,
		delta,
		was_ragdoll_drag
	)

	if bool(info.get("ragdoll_drag", false)):
		if not was_ragdoll_drag:
			_begin_ragdoll_drag(npc, player, ring, info)
		_update_ragdoll_drag(npc, ring, info, delta)
	elif was_ragdoll_drag:
		_begin_ragdoll_recovery(npc, ring)
		_apply_locomotion_phase(npc, body, player, ring, delta, info, ragdoll)
	elif ragdoll != null and ragdoll.is_lasso_settling():
		_apply_locomotion_phase(npc, body, player, ring, delta, info, ragdoll)
	else:
		_apply_locomotion_phase(npc, body, player, ring, delta, info, ragdoll)

	return info


static func cleanup(npc: Node, ring: LassoRing) -> void:
	var ragdoll = _get_ragdoll(npc)
	if ring != null and is_instance_valid(ring):
		ring.end_physics_drag(npc as Node3D)
	if ragdoll != null and ragdoll.is_active():
		ragdoll.deactivate()
	if npc.has_meta(&"lasso_pending_loco_resume"):
		npc.remove_meta(&"lasso_pending_loco_resume")
	_resume_locomotion(npc)
	_write_ragdoll_active(npc, false)


static func _apply_locomotion_phase(
	npc: Node,
	body: CharacterBody3D,
	player: Node3D,
	ring: LassoRing,
	delta: float,
	info: Dictionary,
	ragdoll = null
) -> void:
	var loco_info := info
	if ragdoll != null and ragdoll.is_lasso_settling():
		var settle_alpha: float = ragdoll.get_lasso_settle_alpha()
		loco_info = info.duplicate()
		var walk_alpha := settle_alpha * settle_alpha
		var speed := float(info.get("speed", 0.0)) * walk_alpha
		loco_info["speed"] = speed
		loco_info["sprinting"] = bool(info.get("sprinting", false)) and settle_alpha > 0.55

	if not bool(loco_info.get("slack", false)):
		LassoTargetUtils.face_travel_direction(
			body,
			LassoTautDragScript.get_leader_velocity(player),
			player.global_position,
			delta
		)
		_update_locomotion(npc, delta, loco_info)
	else:
		LassoTargetUtils.face_travel_direction(
			body,
			LassoTautDragScript.get_leader_velocity(player),
			player.global_position,
			delta
		)
		_idle_locomotion(npc, delta)
	_follow_ring_to_target(ring, npc)


static func _begin_ragdoll_drag(
	npc: Node,
	player: Node3D,
	ring: LassoRing,
	info: Dictionary
) -> void:
	var ragdoll = _get_ragdoll(npc)
	if ragdoll == null:
		return

	var pull_dir: Vector3 = info.get("pull_direction", Vector3.FORWARD)
	var anim_player := _get_animation_player(npc)
	_suspend_locomotion(npc)
	ragdoll.activate_lasso_drag(pull_dir, anim_player)
	_write_ragdoll_active(npc, true)

	if ring != null:
		ring.follow_target(npc as Node3D)


static func _update_ragdoll_drag(
	npc: Node,
	ring: LassoRing,
	info: Dictionary,
	delta: float
) -> void:
	var ragdoll = _get_ragdoll(npc)
	if ragdoll == null:
		return

	var pull_velocity: Vector3 = info.get("pull_velocity", Vector3.ZERO)
	var attach := LassoTargetUtils.get_attach_point(npc as Node3D)

	if ring != null:
		ring.follow_target(npc as Node3D)
	ragdoll.sync_lasso_ring_position(attach)
	ragdoll.update_lasso_pull(pull_velocity, delta)

	if npc is CharacterBody3D:
		body_zero_velocity(npc as CharacterBody3D)


static func _begin_ragdoll_recovery(npc: Node, ring: LassoRing) -> void:
	var ragdoll = _get_ragdoll(npc)
	_write_ragdoll_active(npc, false)
	npc.set_meta(&"lasso_soft_loco_resume", true)
	_resume_locomotion(npc)
	if ring != null:
		ring.follow_target(npc as Node3D)
	if ragdoll != null and ragdoll.is_lasso_drag_mode():
		ragdoll.deactivate_lasso_drag()
	npc.set_meta(&"lasso_pending_loco_resume", true)


static func finish_settling_if_needed(npc: Node) -> void:
	var ragdoll = _get_ragdoll(npc)
	if ragdoll != null and ragdoll.is_active():
		return
	if not npc.has_meta(&"lasso_pending_loco_resume"):
		return
	npc.remove_meta(&"lasso_pending_loco_resume")


static func _follow_ring_to_target(ring: LassoRing, npc: Node) -> void:
	if ring != null and is_instance_valid(ring) and not ring.is_physics_drag_active():
		ring.follow_target(npc as Node3D)


static func _update_locomotion(npc: Node, delta: float, info: Dictionary) -> void:
	if not npc.has_method("_update_locomotion_blend"):
		return
	var speed := float(info.get("speed", 0.0))
	if npc.is_in_group("town_groyper") or npc.is_in_group("town_fast"):
		npc.call(
			"_update_locomotion_blend",
			delta,
			speed,
			bool(info.get("sprinting", false))
		)
	else:
		npc.call("_update_locomotion_blend", delta, speed)


static func _idle_locomotion(npc: Node, delta: float) -> void:
	_update_locomotion(npc, delta, {"speed": 0.0, "sprinting": false})


static func body_zero_velocity(body: CharacterBody3D) -> void:
	if body == null:
		return
	body.velocity = Vector3.ZERO


static func _get_ragdoll(npc: Node):
	if npc == null:
		return null
	if npc.has_method("get_lasso_ragdoll"):
		return npc.call("get_lasso_ragdoll")
	return npc.get("_ragdoll")


static func _get_animation_player(npc: Node) -> AnimationPlayer:
	if npc.has_method("get_lasso_animation_player"):
		return npc.call("get_lasso_animation_player") as AnimationPlayer
	return npc.get("_animation_player") as AnimationPlayer


static func _suspend_locomotion(npc: Node) -> void:
	if npc.has_method("_suspend_locomotion_animations"):
		npc.call("_suspend_locomotion_animations")


static func _resume_locomotion(npc: Node) -> void:
	if npc.has_method("_resume_locomotion_animations"):
		npc.call("_resume_locomotion_animations")


static func _write_ragdoll_active(npc: Node, active: bool) -> void:
	npc.set_meta(&"lasso_ragdoll_active", active)
