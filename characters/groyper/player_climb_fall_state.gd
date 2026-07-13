extends RefCounted
## Climb-fall (airborne fall entry -> loop -> land -> exit) state machine for
## the overworld player, extracted from groyper_overworld_player.gd.
## Methods take the player as `p` for node access (house pattern, see
## player_reticle_state.gd). The run-once AnimationTree library setup stays in
## groyper_overworld_anim_builder.gd, which also owns writing
## p._climb_fall_nodes_ready and the blend-node references kept on the player.
## Tweens are created via p.create_tween() so their lifetime stays bound to
## the player node.

const ClimbFallConfigScript := preload("res://characters/groyper/climb_fall_config.gd")

const CLIMB_FALL_BLEND_IN := 0.22
const CLIMB_FALL_EXIT_BLEND := 0.28
const CLIMB_FALL_POSE_CROSSFADE := 0.35
const CLIMB_FALL_LOOP_START_TIME := 2.0
const CLIMB_FALL_MIN_DOWNWARD_SPEED := -0.35

var phase := ClimbFallConfigScript.Phase.NONE
var blend := 0.0
var pose_blend := 0.0
var land_blend := 0.0
var timer := 0.0
var exit_timer := 0.0
var land_duration := 0.0
var armed := false
var was_on_floor := true
var _pose_tween: Tween
var _land_tween: Tween


func init_animation_tree_state(p) -> void:
	phase = ClimbFallConfigScript.Phase.NONE
	blend = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	timer = 0.0
	exit_timer = 0.0
	armed = false
	was_on_floor = true
	_cancel_pose_tween()
	_cancel_land_tween()
	if p._animation_tree == null or not p._climb_fall_nodes_ready:
		return
	ClimbFallConfigScript.set_master_blend(p._animation_tree, 0.0)
	ClimbFallConfigScript.set_pose_blend(p._animation_tree, 0.0)
	ClimbFallConfigScript.set_land_blend(p._animation_tree, 0.0)
	ClimbFallConfigScript.set_fall_entry_seek(p._animation_tree, -1.0)
	ClimbFallConfigScript.set_fall_loop_seek(p._animation_tree, -1.0)
	ClimbFallConfigScript.set_land_seek(p._animation_tree, -1.0)


func is_sequence_active() -> bool:
	return phase != ClimbFallConfigScript.Phase.NONE


func _is_blocked(p) -> bool:
	if p._vault_drop_exit:
		return false
	return (
		p._vault_active
		or p._ladder_state.active
		or p._is_lasso_swing_sequence_active()
		or p._hit_reaction_active
		or p._is_fully_mounted()
		or p._mount_transition_active
		or p._roll_active
		or p._flying_kick_active
		or p._cover_crouch_active
		or p._cover_exit_active
		or p._cover_walk_enter_active
		or p._is_bonfire_pose_active()
	)


func _is_airborne(p) -> bool:
	if p.is_on_floor():
		return false
	if is_sequence_active():
		return true
	return (
		p.velocity.y < CLIMB_FALL_MIN_DOWNWARD_SPEED
		or (was_on_floor and not p.is_on_floor())
	)


func _should_start(p) -> bool:
	return armed and _is_airborne(p)


func _get_anim_length(p, anim_path: StringName, fallback: float) -> float:
	if p._animation_player == null or not p._animation_player.has_animation(anim_path):
		return fallback
	return maxf(p._animation_player.get_animation(anim_path).length, 0.001)


func apply_tree_blends(p) -> void:
	if p._animation_tree == null or not p._climb_fall_nodes_ready:
		return
	ClimbFallConfigScript.set_master_blend(p._animation_tree, blend)
	ClimbFallConfigScript.set_pose_blend(p._animation_tree, pose_blend)
	ClimbFallConfigScript.set_land_blend(p._animation_tree, land_blend)


## External drive of the master blend (vault-drop exit crossfade).
func set_master_blend(p, value: float) -> void:
	blend = value
	apply_tree_blends(p)


func _cancel_pose_tween() -> void:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = null


func _cancel_land_tween() -> void:
	if _land_tween != null and _land_tween.is_valid():
		_land_tween.kill()
	_land_tween = null


func _set_pose_blend(value: float, p) -> void:
	pose_blend = value
	apply_tree_blends(p)


func _set_land_blend(value: float, p) -> void:
	land_blend = value
	apply_tree_blends(p)


func _tween_pose_blend(p, target: float, duration: float) -> void:
	_cancel_pose_tween()
	if duration <= 0.001:
		_set_pose_blend(target, p)
		return
	_pose_tween = p.create_tween()
	_pose_tween.set_ease(Tween.EASE_OUT)
	_pose_tween.set_trans(Tween.TRANS_SINE)
	_pose_tween.tween_method(
		_set_pose_blend.bind(p),
		pose_blend,
		target,
		duration
	)


func _tween_land_blend(p, target: float, duration: float) -> void:
	_cancel_land_tween()
	if duration <= 0.001:
		_set_land_blend(target, p)
		return
	_land_tween = p.create_tween()
	_land_tween.set_ease(Tween.EASE_OUT)
	_land_tween.set_trans(Tween.TRANS_SINE)
	_land_tween.tween_method(
		_set_land_blend.bind(p),
		land_blend,
		target,
		duration
	)


func begin(p) -> void:
	if not p._climb_fall_nodes_ready or p._animation_tree == null:
		return
	phase = ClimbFallConfigScript.Phase.FALL_ENTRY
	timer = 0.0
	exit_timer = 0.0
	blend = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	_cancel_pose_tween()
	_cancel_land_tween()
	apply_tree_blends(p)
	ClimbFallConfigScript.set_fall_entry_seek(p._animation_tree, 0.0)
	ClimbFallConfigScript.set_fall_loop_seek(p._animation_tree, -1.0)
	ClimbFallConfigScript.set_land_seek(p._animation_tree, -1.0)


func _begin_loop(p) -> void:
	if phase == ClimbFallConfigScript.Phase.FALL_LOOP:
		return
	phase = ClimbFallConfigScript.Phase.FALL_LOOP
	if p._animation_tree == null:
		return
	ClimbFallConfigScript.set_fall_loop_seek(p._animation_tree, 0.0)
	_tween_pose_blend(p, 1.0, CLIMB_FALL_POSE_CROSSFADE)


func _begin_land(p) -> void:
	if phase in [ClimbFallConfigScript.Phase.LAND, ClimbFallConfigScript.Phase.EXIT]:
		return
	phase = ClimbFallConfigScript.Phase.LAND
	timer = 0.0
	land_duration = _get_anim_length(
		p,
		ClimbFallConfigScript.get_fall_land_path(),
		0.9
	)
	if not p._climb_fall_nodes_ready or p._animation_tree == null:
		return
	_cancel_pose_tween()
	ClimbFallConfigScript.set_land_seek(p._animation_tree, 0.0)
	_tween_land_blend(p, 1.0, CLIMB_FALL_POSE_CROSSFADE)


func _begin_exit() -> void:
	phase = ClimbFallConfigScript.Phase.EXIT
	exit_timer = 0.0


func finish(p) -> void:
	_cancel_pose_tween()
	_cancel_land_tween()
	init_animation_tree_state(p)


func cancel(p) -> void:
	if not is_sequence_active():
		return
	finish(p)


func update(p, delta: float) -> void:
	if not p._climb_fall_nodes_ready:
		if p.is_on_floor():
			armed = true
		was_on_floor = p.is_on_floor()
		return

	if _is_blocked(p):
		if is_sequence_active():
			cancel(p)
		if p.is_on_floor():
			armed = true
		was_on_floor = p.is_on_floor()
		return

	var airborne := _is_airborne(p)
	var vault_drop_handoff: bool = p._vault_drop_exit and p._vault_exit_active

	match phase:
		ClimbFallConfigScript.Phase.NONE:
			if airborne and _should_start(p):
				begin(p)
		ClimbFallConfigScript.Phase.FALL_ENTRY:
			timer += delta
			if not vault_drop_handoff:
				var enter_t := clampf(
					timer / maxf(CLIMB_FALL_BLEND_IN, 0.001),
					0.0,
					1.0
				)
				var enter_eased := enter_t * enter_t * (3.0 - 2.0 * enter_t)
				blend = enter_eased
				apply_tree_blends(p)
			if not airborne:
				_begin_land(p)
			elif timer >= CLIMB_FALL_LOOP_START_TIME:
				_begin_loop(p)
		ClimbFallConfigScript.Phase.FALL_LOOP:
			blend = lerpf(blend, 1.0, delta * 8.0)
			apply_tree_blends(p)
			if not airborne:
				_begin_land(p)
		ClimbFallConfigScript.Phase.LAND:
			timer += delta
			blend = lerpf(blend, 1.0, delta * 10.0)
			apply_tree_blends(p)
			if timer >= land_duration:
				_begin_exit()
		ClimbFallConfigScript.Phase.EXIT:
			exit_timer += delta
			var progress := clampf(
				exit_timer / maxf(CLIMB_FALL_EXIT_BLEND, 0.001),
				0.0,
				1.0
			)
			var eased := progress * progress * (3.0 - 2.0 * progress)
			blend = 1.0 - eased
			land_blend = lerpf(land_blend, 0.0, eased)
			apply_tree_blends(p)
			if progress >= 1.0:
				finish(p)

	if p.is_on_floor():
		armed = true
	was_on_floor = p.is_on_floor()


func begin_vault_drop_fall_handoff(p) -> void:
	if not p._climb_fall_nodes_ready or p._animation_tree == null:
		return
	armed = true
	was_on_floor = true
	phase = ClimbFallConfigScript.Phase.FALL_ENTRY
	timer = 0.0
	exit_timer = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	_cancel_pose_tween()
	_cancel_land_tween()
	ClimbFallConfigScript.set_fall_entry_seek(p._animation_tree, 0.0)
	ClimbFallConfigScript.set_fall_loop_seek(p._animation_tree, -1.0)
	ClimbFallConfigScript.set_land_seek(p._animation_tree, -1.0)
	blend = 0.0
	apply_tree_blends(p)
	p._reset_locomotion_tree_blends()
