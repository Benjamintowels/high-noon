extends RefCounted
## Lasso rope/swing/grapple (hold -> release -> air -> land -> exit) state
## machine for the overworld player, extracted from
## groyper_overworld_player.gd. Methods take the player as `p` for node access
## (house pattern, see player_reticle_state.gd).
## The run-once AnimationTree library setup stays in
## groyper_overworld_anim_builder.gd, which also owns writing
## p._lasso_swing_nodes_ready and the blend-node references kept on the
## player. The public lasso API (begin/end/release grapple swing, rope-state
## queries) and the LassoController node stay on the player. Tweens are
## created via p.create_tween() so their lifetime stays bound to the player
## node.

const LassoSwingConfigScript := preload("res://characters/groyper/lasso_swing_config.gd")
const LassoSwingPhysicsScript := preload("res://gameplay/lasso/lasso_swing_physics.gd")

const LASSO_SWING_ANIM_FADEIN := 0.34
const LASSO_SWING_RELEASE_SPEED := 1.6
const LASSO_SWING_LAND_SPEED := 2.0
const LASSO_SWING_POSE_CROSSFADE := 0.18
const LASSO_SWING_EXIT_BLEND := 0.24
const LASSO_SWING_CONTROL_UNLOCK_FRACTION := 0.62
const LASSO_SWING_FACING_SPEED := 16.0
const LASSO_SWING_RELEASE_AIR_MIN := 0.02
const LASSO_SWING_AIR_LAND_MIN := 0.08
const LASSO_SWING_RELEASE_TO_AIR := 0.14
const LASSO_SWING_BODY_TILT_SPEED := 16.0
const LASSO_SWING_BODY_PITCH_SIGN := -1.0
const LASSO_SWING_HAND_PIVOT_Y := 1.15

var phase := LassoSwingConfigScript.Phase.NONE
var blend := 0.0
var pose_blend := 0.0
var land_blend := 0.0
var ground_blend := 0.0
var timer := 0.0
var release_duration := 0.0
var land_duration := 0.0
var control_unlocked := false
var exit_active := false
var exit_timer := 0.0
var release_air_control := false
var body_pitch := 0.0
var saved_motion_mode: CharacterBody3D.MotionMode = CharacterBody3D.MOTION_MODE_GROUNDED
var _pose_tween: Tween
var _master_tween: Tween


func is_sequence_active(p) -> bool:
	if phase == LassoSwingConfigScript.Phase.NONE:
		return false
	# Active rope climb uses hang pose, not the release/land sequence.
	if phase == LassoSwingConfigScript.Phase.SWING and p.is_lasso_rope_climbing():
		return false
	return true


func init_animation_tree_state(p) -> void:
	phase = LassoSwingConfigScript.Phase.NONE
	blend = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	ground_blend = 0.0
	timer = 0.0
	control_unlocked = false
	exit_active = false
	exit_timer = 0.0
	release_air_control = false
	_cancel_pose_tween()
	_cancel_master_tween()
	if p._animation_tree == null or not p._lasso_swing_nodes_ready:
		return
	LassoSwingConfigScript.set_master_blend(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_pose_blend(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_land_blend(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_swing_seek(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_fall_seek(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_land_seek(p._animation_tree, -1.0)
	LassoSwingConfigScript.set_swing_playback_speed(p._animation_tree, 1.0)
	LassoSwingConfigScript.set_land_playback_speed(p._animation_tree, 1.0)


func begin_hold(p) -> void:
	phase = LassoSwingConfigScript.Phase.SWING
	timer = 0.0
	control_unlocked = false
	exit_active = false
	exit_timer = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	ground_blend = 0.0
	blend = 0.0
	_cancel_pose_tween()
	_cancel_master_tween()
	p._reset_locomotion_tree_blends()
	if not p._lasso_swing_nodes_ready or p._animation_tree == null:
		push_warning(
			"GroyperOverworldPlayer: lasso swing clips missing â€” run lasso_swing_extract_cli.gd"
		)
		return
	apply_tree_blends(p)
	LassoSwingConfigScript.set_swing_seek(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_fall_seek(p._animation_tree, -1.0)
	LassoSwingConfigScript.set_land_seek(p._animation_tree, -1.0)
	LassoSwingConfigScript.set_swing_playback_speed(p._animation_tree, 1.0)
	LassoSwingConfigScript.set_land_playback_speed(p._animation_tree, 1.0)
	_tween_master_blend(p, 1.0, LASSO_SWING_ANIM_FADEIN)


func begin_release(p) -> void:
	phase = LassoSwingConfigScript.Phase.RELEASE
	timer = 0.0
	control_unlocked = false
	exit_active = false
	release_air_control = true
	pose_blend = 0.0
	land_blend = 0.0
	release_duration = _get_anim_length(
		p,
		LassoSwingConfigScript.get_swing_path(),
		0.55
	) / LASSO_SWING_RELEASE_SPEED
	land_duration = _get_anim_length(
		p,
		LassoSwingConfigScript.get_land_path(),
		0.85
	) / LASSO_SWING_LAND_SPEED
	if not p._lasso_swing_nodes_ready or p._animation_tree == null:
		return

	_cancel_pose_tween()
	_cancel_master_tween()
	blend = 1.0
	apply_tree_blends(p)
	LassoSwingConfigScript.set_fall_seek(p._animation_tree, -1.0)
	LassoSwingConfigScript.set_land_seek(p._animation_tree, -1.0)
	LassoSwingConfigScript.set_swing_playback_speed(p._animation_tree, LASSO_SWING_RELEASE_SPEED)
	LassoSwingConfigScript.set_land_playback_speed(p._animation_tree, LASSO_SWING_LAND_SPEED)


func begin_air(p) -> void:
	if phase not in [
		LassoSwingConfigScript.Phase.RELEASE,
		LassoSwingConfigScript.Phase.SWING,
		LassoSwingConfigScript.Phase.NONE,
	]:
		return
	phase = LassoSwingConfigScript.Phase.AIR
	timer = 0.0
	blend = 0.2
	p.motion_mode = saved_motion_mode
	if p._lasso_swing_nodes_ready and p._animation_tree != null:
		_cancel_pose_tween()
		_cancel_master_tween()
		pose_blend = 0.0
		land_blend = 0.0
		apply_tree_blends(p)
		LassoSwingConfigScript.set_swing_playback_speed(p._animation_tree, 0.0)
		LassoSwingConfigScript.set_fall_seek(p._animation_tree, 0.0)
		LassoSwingConfigScript.set_land_seek(p._animation_tree, -1.0)
		_tween_pose_blend(p, 1.0, LASSO_SWING_POSE_CROSSFADE)
		_tween_master_blend(p, 0.25, LASSO_SWING_POSE_CROSSFADE)


func begin_land(p) -> void:
	if phase != LassoSwingConfigScript.Phase.AIR:
		return
	phase = LassoSwingConfigScript.Phase.LAND
	timer = 0.0
	control_unlocked = false
	p.motion_mode = saved_motion_mode
	p._lasso_release_float_timer = 0.0
	if not p._lasso_swing_nodes_ready or p._animation_tree == null:
		return
	_cancel_pose_tween()
	pose_blend = 1.0
	land_blend = 0.0
	apply_tree_blends(p)
	LassoSwingConfigScript.set_land_seek(p._animation_tree, 0.0)
	LassoSwingConfigScript.set_land_playback_speed(p._animation_tree, LASSO_SWING_LAND_SPEED)
	_tween_land_blend(p, 1.0, LASSO_SWING_POSE_CROSSFADE)


func begin_exit() -> void:
	if exit_active:
		return
	phase = LassoSwingConfigScript.Phase.EXIT
	exit_active = true
	exit_timer = 0.0
	control_unlocked = true


func finish(p) -> void:
	_cancel_pose_tween()
	_cancel_master_tween()
	p.motion_mode = saved_motion_mode
	phase = LassoSwingConfigScript.Phase.NONE
	blend = 0.0
	pose_blend = 0.0
	land_blend = 0.0
	ground_blend = 0.0
	control_unlocked = false
	exit_active = false
	exit_timer = 0.0
	release_air_control = false
	reset_body_pose(p)
	apply_tree_blends(p)
	if p._animation_tree != null and p._lasso_swing_nodes_ready:
		LassoSwingConfigScript.set_swing_playback_speed(p._animation_tree, 1.0)
		LassoSwingConfigScript.set_land_playback_speed(p._animation_tree, 1.0)


func _get_anim_length(p, anim_path: StringName, fallback: float) -> float:
	if p._animation_player == null or not p._animation_player.has_animation(anim_path):
		return fallback
	return maxf(p._animation_player.get_animation(anim_path).length, 0.001)


func apply_tree_blends(p) -> void:
	if p._animation_tree == null or not p._lasso_swing_nodes_ready:
		return
	LassoSwingConfigScript.set_master_blend(p._animation_tree, blend)
	LassoSwingConfigScript.set_pose_blend(p._animation_tree, pose_blend)
	LassoSwingConfigScript.set_land_blend(p._animation_tree, land_blend)


func _cancel_pose_tween() -> void:
	if _pose_tween != null and _pose_tween.is_valid():
		_pose_tween.kill()
	_pose_tween = null


func _cancel_master_tween() -> void:
	if _master_tween != null and _master_tween.is_valid():
		_master_tween.kill()
	_master_tween = null


func _tween_master_blend(p, target: float, duration: float) -> void:
	_cancel_master_tween()
	if duration <= 0.001:
		_set_master_blend(target, p)
		return
	_master_tween = p.create_tween()
	_master_tween.set_ease(Tween.EASE_OUT)
	_master_tween.set_trans(Tween.TRANS_SINE)
	_master_tween.tween_method(_set_master_blend.bind(p), blend, target, duration)


func _set_master_blend(value: float, p) -> void:
	blend = value
	apply_tree_blends(p)


func _tween_pose_blend(p, target: float, duration: float) -> void:
	_cancel_pose_tween()
	if duration <= 0.001:
		pose_blend = target
		apply_tree_blends(p)
		return
	_pose_tween = p.create_tween()
	_pose_tween.tween_method(_set_pose_blend.bind(p), pose_blend, target, duration)


func _tween_land_blend(p, target: float, duration: float) -> void:
	_cancel_pose_tween()
	if duration <= 0.001:
		land_blend = target
		apply_tree_blends(p)
		return
	_pose_tween = p.create_tween()
	_pose_tween.tween_method(_set_land_blend.bind(p), land_blend, target, duration)


func _set_pose_blend(value: float, p) -> void:
	pose_blend = value
	apply_tree_blends(p)


func _set_land_blend(value: float, p) -> void:
	land_blend = value
	apply_tree_blends(p)


func update_tighten(p, delta: float) -> void:
	if p._lasso_controller == null:
		return

	p.velocity.x = move_toward(p.velocity.x, 0.0, 18.0 * delta)
	p.velocity.z = move_toward(p.velocity.z, 0.0, 18.0 * delta)
	p.velocity.y = move_toward(p.velocity.y, 0.0, 18.0 * delta)
	p.move_and_slide()


func _update_swing_facing(p, delta: float) -> void:
	if p._model == null:
		return

	var tangent := Vector3.ZERO
	if phase in [LassoSwingConfigScript.Phase.RELEASE, LassoSwingConfigScript.Phase.AIR]:
		tangent = Vector3(p.velocity.x, 0.0, p.velocity.z)

	if tangent.length_squared() >= 0.08:
		var target_yaw := atan2(tangent.x, tangent.z)
		var turn := clampf(LASSO_SWING_FACING_SPEED * delta, 0.0, 1.0)
		p._model.rotation.y = lerp_angle(p._model.rotation.y, target_yaw, turn)


func update_rope_pose(p, delta: float) -> void:
	if p._model == null:
		return

	if p._lasso_controller == null or not p._lasso_controller.is_rope_vertical_climbing():
		reset_body_pose(p, delta)
		return

	var anchor: Node3D = p._lasso_controller.get_swing_anchor()
	if anchor == null or not is_instance_valid(anchor):
		reset_body_pose(p, delta)
		return

	var span := LassoSwingPhysicsScript.measure_rope_span(p, anchor)
	var rope_dir: Vector3 = span.rope_dir
	var target_pitch := (
		LassoSwingPhysicsScript.get_rope_body_pitch(rope_dir)
		* LASSO_SWING_BODY_PITCH_SIGN
	)
	var tilt_step := clampf(LASSO_SWING_BODY_TILT_SPEED * delta, 0.0, 1.0)
	body_pitch = lerp_angle(body_pitch, target_pitch, tilt_step)

	var model_pivot_y := LASSO_SWING_HAND_PIVOT_Y - GroyperBodyUtils.ACTOR_MODEL_Y
	var pivot := Vector3(0.0, model_pivot_y, 0.0)
	var pitch_basis := Basis.from_euler(Vector3(body_pitch, 0.0, 0.0))
	p._model.rotation.x = body_pitch
	p._model.position = Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y, 0.0) + pivot - pitch_basis * pivot


func reset_body_pose(p, delta: float = -1.0) -> void:
	if p._model == null:
		return
	if delta < 0.0:
		body_pitch = 0.0
		p._model.rotation.x = 0.0
		p._model.position = Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y, 0.0)
		return

	var tilt_step := clampf(LASSO_SWING_BODY_TILT_SPEED * delta, 0.0, 1.0)
	body_pitch = lerp_angle(body_pitch, 0.0, tilt_step)
	var model_pivot_y := LASSO_SWING_HAND_PIVOT_Y - GroyperBodyUtils.ACTOR_MODEL_Y
	var pivot := Vector3(0.0, model_pivot_y, 0.0)
	var pitch_basis := Basis.from_euler(Vector3(body_pitch, 0.0, 0.0))
	p._model.rotation.x = body_pitch
	p._model.position = Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y, 0.0) + pivot - pitch_basis * pivot
	if absf(body_pitch) < 0.01:
		body_pitch = 0.0
		p._model.rotation.x = 0.0
		p._model.position = Vector3(0.0, GroyperBodyUtils.ACTOR_MODEL_Y, 0.0)


func update_locomotion_overlay(p, delta: float) -> void:
	if (
		p._lasso_controller != null
		and p._lasso_controller.is_rope_vertical_climbing()
		and phase == LassoSwingConfigScript.Phase.SWING
	):
		p._locomotion_move_blend = lerpf(p._locomotion_move_blend, 0.0, p.BLEND_SPEED * delta * 2.5)
		p._locomotion_walk_blend = lerpf(p._locomotion_walk_blend, 0.0, p.BLEND_SPEED * delta * 2.5)
		p._apply_locomotion_tree_blends()
		return

	p._locomotion_move_blend = lerpf(p._locomotion_move_blend, 0.0, p.BLEND_SPEED * delta * 2.5)
	p._locomotion_walk_blend = lerpf(p._locomotion_walk_blend, 0.0, p.BLEND_SPEED * delta * 2.5)
	p._apply_locomotion_tree_blends()


func _apply_release_air_movement(p, delta: float) -> void:
	if phase != LassoSwingConfigScript.Phase.AIR:
		return

	var move_dir: Vector3 = p._get_camera_relative_input()
	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and move_dir.length_squared() > 0.0001
	var target_speed: float = p.RUN_SPEED if sprinting else p.WALK_SPEED
	var target_h := (
		move_dir * target_speed
		if move_dir.length_squared() > 0.0001
		else Vector3.ZERO
	)
	var current_h := Vector3(p.velocity.x, 0.0, p.velocity.z)
	var air_accel: float = p.MOVE_ACCEL * 0.55
	var new_h := current_h.move_toward(target_h, air_accel * delta)
	p.velocity.x = new_h.x
	p.velocity.z = new_h.z


func _get_rope_climb_input() -> float:
	var climb := 0.0
	if Input.is_key_pressed(KEY_W):
		climb += 1.0
	if Input.is_key_pressed(KEY_S):
		climb -= 1.0
	return climb


func update_rope_walk(p, delta: float) -> void:
	if p._lasso_controller == null:
		return

	var anchor: Node3D = p._lasso_controller.get_swing_anchor()
	if anchor == null or not is_instance_valid(anchor):
		return

	if LassoSwingPhysicsScript.is_at_rope_center(p, anchor):
		p._lasso_controller.enter_vertical_rope_climb()
		return

	var walk_input := _get_rope_climb_input()
	var walk_dir := LassoSwingPhysicsScript.get_rope_walk_direction(p, anchor, walk_input)
	var sprinting: bool = Input.is_key_pressed(KEY_SHIFT) and walk_dir.length_squared() > 0.0001
	var target_speed: float = p.RUN_SPEED if sprinting else p.WALK_SPEED
	var target_h := walk_dir * target_speed if walk_dir.length_squared() > 0.0001 else Vector3.ZERO
	var current_h := Vector3(p.velocity.x, 0.0, p.velocity.z)
	var move_rate: float = p.MOVE_ACCEL if target_h.length_squared() > 0.0001 else p.MOVE_STOP_DECEL
	var new_h := current_h.move_toward(target_h, move_rate * delta)
	p.velocity.x = new_h.x
	p.velocity.z = new_h.z

	if not p.is_on_floor():
		p.velocity.y -= p.GRAVITY * delta
	else:
		p.velocity.y = minf(p.velocity.y, 0.0)

	p.move_and_slide()
	LassoSwingPhysicsScript.enforce_ground_rope_tether(
		p,
		anchor,
		p._lasso_controller.get_rope_length()
	)
	p._update_facing(delta, walk_dir if walk_dir.length_squared() > 0.0001 else Vector3(p.velocity.x, 0.0, p.velocity.z))
	p._update_locomotion_blend(delta, new_h.length(), p.WALK_SPEED, p.RUN_SPEED, walk_dir)
	reset_body_pose(p, delta)


func update_rope_vertical_climb(p, delta: float) -> void:
	if p._lasso_controller == null:
		return

	p._lasso_controller.apply_vertical_climb(delta, _get_rope_climb_input())
	update_rope_pose(p, delta)
	update_locomotion_overlay(p, delta)
	update_hold_animation(p, delta)


func update_hold_animation(p, delta: float) -> void:
	if phase != LassoSwingConfigScript.Phase.SWING:
		return
	timer += delta
	if not p._lasso_swing_nodes_ready or p._animation_tree == null:
		return
	if _master_tween == null or not _master_tween.is_valid():
		var enter_t := clampf(
			timer / maxf(LASSO_SWING_ANIM_FADEIN, 0.001),
			0.0,
			1.0
		)
		var enter_eased := enter_t * enter_t * (3.0 - 2.0 * enter_t)
		blend = enter_eased
		apply_tree_blends(p)
	LassoSwingConfigScript.set_swing_seek(p._animation_tree, 0.0)


func update_sequence(p, delta: float) -> void:
	if not is_sequence_active(p):
		return

	if not p.is_on_floor():
		p.velocity.y -= p.GRAVITY * delta
	else:
		p.velocity.y = minf(p.velocity.y, 0.0)

	_apply_release_air_movement(p, delta)

	if not control_unlocked:
		p.move_and_slide()
	else:
		var ctx: Dictionary = p._get_vault_move_context()
		var move_dir: Vector3 = ctx.get("move_dir", Vector3.ZERO)
		var walk_speed: float = float(ctx.get("walk_speed", p.WALK_SPEED))
		var run_speed: float = float(ctx.get("run_speed", p.RUN_SPEED))
		var target_h: Vector3 = (
			move_dir * float(ctx.get("target_speed", 0.0))
			if move_dir.length_squared() > 0.0001
			else Vector3.ZERO
		)
		var current_h := Vector3(p.velocity.x, 0.0, p.velocity.z)
		var move_rate: float = p.MOVE_ACCEL if target_h.length_squared() > 0.0001 else p.MOVE_STOP_DECEL
		var new_h := current_h.move_toward(target_h, move_rate * delta)
		p._push_intent = target_h
		p.velocity.x = new_h.x
		p.velocity.z = new_h.z
		p.move_and_slide()
		p._update_facing(delta, move_dir)
		p._update_locomotion_blend(delta, new_h.length(), walk_speed, run_speed, move_dir)

	_update_swing_facing(p, delta)
	reset_body_pose(p, delta)
	update_locomotion_overlay(p, delta)
	timer += delta

	match phase:
		LassoSwingConfigScript.Phase.AIR:
			_update_air_phase(p, delta)
		LassoSwingConfigScript.Phase.LAND:
			_update_land_phase()
		LassoSwingConfigScript.Phase.EXIT:
			_update_exit_phase(p, delta)


func _is_release_airborne(p) -> bool:
	return not p.is_on_floor() and not LassoSwingPhysicsScript.is_body_near_floor(p)


func _update_release_phase(p) -> void:
	var release_window := maxf(release_duration, LASSO_SWING_RELEASE_TO_AIR)
	var release_t := clampf(
		timer / maxf(release_window, 0.001),
		0.0,
		1.0
	)
	var release_eased := release_t * release_t * (3.0 - 2.0 * release_t)
	blend = lerpf(1.0, 0.35, release_eased)
	apply_tree_blends(p)

	if timer >= release_window:
		begin_air(p)
		return

	if timer >= LASSO_SWING_RELEASE_AIR_MIN and _is_release_airborne(p):
		begin_air(p)


func _update_air_phase(p, delta: float) -> void:
	if timer >= LASSO_SWING_AIR_LAND_MIN and not _is_release_airborne(p):
		release_air_control = false
		begin_land(p)
		return

	blend = lerpf(blend, 0.0, delta * 6.0)
	apply_tree_blends(p)


func _update_land_phase() -> void:
	if (
		not control_unlocked
		and timer >= land_duration * LASSO_SWING_CONTROL_UNLOCK_FRACTION
	):
		control_unlocked = true

	if timer >= land_duration:
		begin_exit()


func _update_exit_phase(p, delta: float) -> void:
	exit_timer += delta
	var progress := clampf(
		exit_timer / maxf(LASSO_SWING_EXIT_BLEND, 0.001),
		0.0,
		1.0
	)
	var eased := progress * progress * (3.0 - 2.0 * progress)
	blend = 1.0 - eased
	apply_tree_blends(p)
	if progress >= 1.0:
		finish(p)
