extends RefCounted
## Ladder climbing (mount -> climb -> exit) state machine for the overworld
## player, extracted from groyper_overworld_player.gd. Methods take the player
## as `p` for node access (house pattern, see player_reticle_state.gd).
## The run-once AnimationTree library setup stays in
## groyper_overworld_anim_builder.gd, which also owns writing
## p._ladder_climb_nodes_ready and the blend-node references kept on the
## player. The LadderAudio child node also stays on the player
## (p._update_ladder_audio / p._stop_ladder_audio). Tweens are created via
## p.create_tween() so their lifetime stays bound to the player node.

const LadderClimbConfigScript := preload("res://characters/groyper/ladder_climb_config.gd")

const LADDER_MOUNT_BLEND_DURATION := 0.28
const LADDER_CLIMB_PLAYBACK_SPEED := 1.35
const LADDER_CLIMB_ASCENT_SPEED := 1.85
const LADDER_SPRINT_CLIMB_MULTIPLIER := 1.5
const LADDER_SLIDE_DOWN_SPEED := 9.9
const LADDER_CLIMB_INPUT_DEADZONE := 0.15
const LADDER_TOP_THRESHOLD := 0.985
const LADDER_BOTTOM_THRESHOLD := 0.015
const LADDER_FINISH_BLEND_IN := 0.2
const LADDER_TOP_POP_UP := 6.25
const LADDER_JUMP_OFF_SPEED := 4.5
const LADDER_JUMP_OFF_UP := 2.8

var active := false
var phase := LadderClimbConfigScript.Phase.NONE
var piece  # LadderPiece; untyped so the module never depends on the global class cache.
var from_bottom := true
var progress := 0.0
var blend := 0.0
var finish_blend := 0.0
var mount_timer := 0.0
var finish_timer := 0.0
var finish_duration := 0.0
var exit_timer := 0.0
var climb_length := 1.0
var mount_from := Vector3.ZERO
var mount_to := Vector3.ZERO
var saved_motion_mode: CharacterBody3D.MotionMode = CharacterBody3D.MOTION_MODE_GROUNDED
var _blend_tween: Tween
var _finish_blend_tween: Tween
var _position_tween: Tween


func mount(p, ladder) -> void:
	if not p.can_mount_ladder() or ladder == null or not p._ladder_climb_nodes_ready:
		return
	piece = ladder
	from_bottom = not ladder.should_mount_from_top(p)
	progress = 0.0 if from_bottom else 1.0
	climb_length = ladder.get_climb_length()
	_begin_mount(p)


func _begin_mount(p) -> void:
	active = true
	phase = LadderClimbConfigScript.Phase.MOUNT
	mount_timer = 0.0
	blend = 0.0
	finish_blend = 0.0
	p.velocity = Vector3.ZERO
	saved_motion_mode = p.motion_mode
	p.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	_cancel_blend_tween()
	_cancel_finish_blend_tween()
	_cancel_position_tween()
	apply_tree_blends(p)

	var target_yaw: float = piece.get_climb_facing_yaw()
	p.rotation.y = target_yaw
	p._model.rotation.y = GroyperBodyUtils.MODEL_YAW_OFFSET

	mount_from = p.global_position
	mount_to = (
		piece.get_bottom_position()
		if from_bottom
		else piece.get_top_position()
	)

	if p._animation_tree != null and p._ladder_climb_nodes_ready:
		if from_bottom:
			_set_finish_blend(0.0, p)
			LadderClimbConfigScript.set_climb_seek(p._animation_tree, 0.0)
			LadderClimbConfigScript.set_finish_seek(p._animation_tree, -1.0)
			LadderClimbConfigScript.set_climb_playback_scale(p._animation_tree, 0.0)
			LadderClimbConfigScript.set_finish_playback_scale(p._animation_tree, 0.0)
		else:
			var finish_len := _get_anim_length(
				p,
				LadderClimbConfigScript.get_climb_finish_path(),
				4.0
			)
			_set_finish_blend(1.0, p)
			LadderClimbConfigScript.set_climb_seek(p._animation_tree, -1.0)
			LadderClimbConfigScript.set_climb_playback_scale(p._animation_tree, 0.0)
			LadderClimbConfigScript.set_finish_seek(p._animation_tree, finish_len)
			var reverse_speed := -finish_len / maxf(LADDER_MOUNT_BLEND_DURATION, 0.001)
			LadderClimbConfigScript.set_finish_playback_scale(p._animation_tree, reverse_speed)

	_tween_blend(p, 1.0, LADDER_MOUNT_BLEND_DURATION)


func update(p, delta: float) -> void:
	if not active or piece == null or not is_instance_valid(piece):
		finish(p)
		return

	p.velocity = Vector3.ZERO

	match phase:
		LadderClimbConfigScript.Phase.MOUNT:
			_update_mount(p, delta)
		LadderClimbConfigScript.Phase.CLIMB:
			_update_climbing(p, delta)
		LadderClimbConfigScript.Phase.EXIT:
			_update_exit(p, delta)

	if not active:
		p.move_and_slide()
		p._sync_camera_pivot_yaw()
		p._set_camera_arm_pitch()
		p._update_interact_hint()
		return

	p.move_and_slide()
	p._sync_camera_pivot_yaw()
	p._set_camera_arm_pitch()
	p._update_interact_hint()


func _update_mount(p, delta: float) -> void:
	mount_timer += delta
	var t := clampf(
		mount_timer / maxf(LADDER_MOUNT_BLEND_DURATION, 0.001),
		0.0,
		1.0
	)
	var eased := t * t * (3.0 - 2.0 * t)
	p.global_position = mount_from.lerp(mount_to, eased)
	if t >= 1.0:
		phase = LadderClimbConfigScript.Phase.CLIMB
		progress = 0.0 if from_bottom else 1.0
		_sync_body_position(p)
		if p._animation_tree != null and p._ladder_climb_nodes_ready:
			if from_bottom:
				_set_finish_blend(0.0, p)
				LadderClimbConfigScript.set_climb_seek(p._animation_tree, 0.0)
				LadderClimbConfigScript.set_finish_playback_scale(p._animation_tree, 0.0)
			else:
				LadderClimbConfigScript.set_finish_playback_scale(p._animation_tree, 0.0)
				LadderClimbConfigScript.set_climb_seek(p._animation_tree, 0.0)
				_tween_finish_blend(p, 0.0, LADDER_FINISH_BLEND_IN)


func _update_climbing(p, delta: float) -> void:
	var climb_input := _get_climb_input()
	var sprinting := Input.is_key_pressed(KEY_SHIFT)
	var playback := 0.0
	var sliding := sprinting and climb_input < -LADDER_CLIMB_INPUT_DEADZONE
	var climbing := false
	var sprint_climb := false

	if sliding:
		var slide_speed := LADDER_SLIDE_DOWN_SPEED / climb_length
		progress -= slide_speed * delta
		progress = clampf(progress, 0.0, 1.0)
	elif absf(climb_input) >= LADDER_CLIMB_INPUT_DEADZONE:
		climbing = true
		sprint_climb = sprinting and climb_input > 0.0
		var speed_mult := LADDER_SPRINT_CLIMB_MULTIPLIER if sprint_climb else 1.0
		playback = climb_input * LADDER_CLIMB_PLAYBACK_SPEED * speed_mult
		var climb_speed := LADDER_CLIMB_ASCENT_SPEED * speed_mult / climb_length
		progress += climb_input * climb_speed * delta
		progress = clampf(progress, 0.0, 1.0)

	p._update_ladder_audio(climbing, sprint_climb, sliding)

	if p._animation_tree != null and p._ladder_climb_nodes_ready:
		LadderClimbConfigScript.set_climb_playback_scale(p._animation_tree, playback)

	_sync_body_position(p)

	if progress >= LADDER_TOP_THRESHOLD and from_bottom:
		_pop_off_top(p)
	elif progress <= LADDER_BOTTOM_THRESHOLD and (sliding or not from_bottom):
		_finish_at_bottom(p)


func _update_exit(p, delta: float) -> void:
	exit_timer += delta
	if exit_timer >= LADDER_MOUNT_BLEND_DURATION:
		finish(p)


func _pop_off_top(p) -> void:
	if not active or piece == null:
		return
	var saved_motion := saved_motion_mode
	progress = 1.0
	_sync_body_position(p)
	finish_immediate(p)
	p.motion_mode = saved_motion
	p.velocity = Vector3(0.0, LADDER_TOP_POP_UP, 0.0)
	p._climb_fall_state.armed = true


func _finish_at_bottom(p) -> void:
	p._stop_ladder_audio()
	phase = LadderClimbConfigScript.Phase.EXIT
	exit_timer = 0.0
	p.global_position = GroyperBodyUtils.snap_position_to_floor(
		p.get_world_3d(),
		piece.get_bottom_position(),
		GroyperBodyUtils.get_collision_feet_offset(p)
	)
	_tween_blend(p, 0.0, LADDER_MOUNT_BLEND_DURATION)


func try_jump_off(p) -> void:
	if not active or piece == null:
		return
	if phase == LadderClimbConfigScript.Phase.MOUNT:
		return
	var jump_dir: Vector3 = piece.get_jump_off_direction(p)
	var saved_motion := saved_motion_mode
	finish_immediate(p)
	p.motion_mode = saved_motion
	p.velocity = jump_dir * LADDER_JUMP_OFF_SPEED + Vector3(0.0, LADDER_JUMP_OFF_UP, 0.0)
	p._climb_fall_state.armed = true
	p._climb_fall_state.begin(p)
	p.move_and_slide()


func finish(p) -> void:
	var saved_motion := saved_motion_mode
	finish_immediate(p)
	p.motion_mode = saved_motion
	p.velocity = Vector3.ZERO
	p._climb_fall_state.armed = true


func finish_immediate(p) -> void:
	p._stop_ladder_audio()
	_cancel_blend_tween()
	_cancel_finish_blend_tween()
	_cancel_position_tween()
	active = false
	phase = LadderClimbConfigScript.Phase.NONE
	piece = null
	init_animation_tree_state(p)


func _get_climb_input() -> float:
	var climb := 0.0
	if Input.is_key_pressed(KEY_W):
		climb += 1.0
	if Input.is_key_pressed(KEY_S):
		climb -= 1.0
	return climb


func _sync_body_position(p) -> void:
	if piece == null:
		return
	var bottom: Vector3 = piece.get_bottom_position()
	var top: Vector3 = piece.get_top_position()
	p.global_position = bottom.lerp(top, progress)


func _get_anim_length(p, anim_path: StringName, fallback: float) -> float:
	if p._animation_player == null or not p._animation_player.has_animation(anim_path):
		return fallback
	return maxf(p._animation_player.get_animation(anim_path).length, 0.001)


func apply_tree_blends(p) -> void:
	if p._animation_tree == null or not p._ladder_climb_nodes_ready:
		return
	LadderClimbConfigScript.set_master_blend(p._animation_tree, blend)
	LadderClimbConfigScript.set_finish_blend(p._animation_tree, finish_blend)


func _set_blend(value: float, p) -> void:
	blend = value
	apply_tree_blends(p)


func _set_finish_blend(value: float, p) -> void:
	finish_blend = value
	apply_tree_blends(p)


func _cancel_blend_tween() -> void:
	if _blend_tween != null and _blend_tween.is_valid():
		_blend_tween.kill()
	_blend_tween = null


func _cancel_finish_blend_tween() -> void:
	if _finish_blend_tween != null and _finish_blend_tween.is_valid():
		_finish_blend_tween.kill()
	_finish_blend_tween = null


func _cancel_position_tween() -> void:
	if _position_tween != null and _position_tween.is_valid():
		_position_tween.kill()
	_position_tween = null


func _tween_blend(p, target: float, duration: float) -> void:
	_cancel_blend_tween()
	if duration <= 0.001:
		_set_blend(target, p)
		return
	_blend_tween = p.create_tween()
	_blend_tween.set_ease(Tween.EASE_OUT)
	_blend_tween.set_trans(Tween.TRANS_SINE)
	_blend_tween.tween_method(_set_blend.bind(p), blend, target, duration)


func _tween_finish_blend(p, target: float, duration: float) -> void:
	_cancel_finish_blend_tween()
	if duration <= 0.001:
		_set_finish_blend(target, p)
		return
	_finish_blend_tween = p.create_tween()
	_finish_blend_tween.set_ease(Tween.EASE_OUT)
	_finish_blend_tween.set_trans(Tween.TRANS_SINE)
	_finish_blend_tween.tween_method(
		_set_finish_blend.bind(p),
		finish_blend,
		target,
		duration
	)


func init_animation_tree_state(p) -> void:
	blend = 0.0
	finish_blend = 0.0
	if p._animation_tree == null or not p._ladder_climb_nodes_ready:
		return
	LadderClimbConfigScript.set_master_blend(p._animation_tree, 0.0)
	LadderClimbConfigScript.set_finish_blend(p._animation_tree, 0.0)
	LadderClimbConfigScript.set_climb_seek(p._animation_tree, -1.0)
	LadderClimbConfigScript.set_finish_seek(p._animation_tree, -1.0)
	LadderClimbConfigScript.set_climb_playback_scale(p._animation_tree, 0.0)
	LadderClimbConfigScript.set_finish_playback_scale(p._animation_tree, 0.0)
