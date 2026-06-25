extends Node

signal replay_finished

const SHOT_BEAM := preload("res://characters/groyper/shot_beam.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const RPG_ROCKET_SCENE := preload("res://gameplay/shooting/rpg_rocket.tscn")
const DuelPacesScript := preload("res://gameplay/duel/duel_paces.gd")

const RECORD_INTERVAL := 1.0 / 24.0
const REPLAY_SPEED := 0.82
const IMPACT_TIME_SCALE := 0.12
const IMPACT_RAMP_REAL_DURATION := 1.2
const IMPACT_POST_REAL_DURATION := 1.45
const MIN_PRE_IMPACT_DURATION := 0.35
const FADE_OUT_DURATION := 0.55
const FADE_IN_DURATION := 0.65
const CAMERA_LOOK_HEIGHT := 0.35
const CLASSIC_CAMERA_HEIGHT := 2.15
const CLASSIC_SIDE_BASE := 9.5
const CLASSIC_SIDE_PER_PACE := 0.36
const CLASSIC_MIN_SIDE_DISTANCE := 7.5
const CLASSIC_MAX_SIDE_DISTANCE := 24.0
const CLASSIC_MIN_FOV := 40.0
const CLASSIC_MAX_FOV := 68.0
const ELEVATED_MIN_HEIGHT := 8.5
const ELEVATED_MAX_HEIGHT := 19.0
const ELEVATED_HEIGHT_PER_PACE := 0.36
const ELEVATED_MIN_SIDE_DISTANCE := 2.0
const ELEVATED_MAX_SIDE_DISTANCE := 7.5
const ELEVATED_SIDE_PER_PACE := 0.07
const ELEVATED_MIN_FOV := 48.0
const ELEVATED_MAX_FOV := 90.0
const CHARACTER_FRAMING_MARGIN := 3.0
const FRAMING_PADDING := 1.18
const BUILDING_CLEARANCE_PADDING := 1.1
const LETTERBOX_HEIGHT := 72.0

enum PlaybackPhase { IDLE, PRE_IMPACT, POST_IMPACT }

var _player: Node3D
var _enemy: Node3D
var _stage: Node3D
var _overlay: CanvasLayer
var _fade_overlay: ColorRect

var _recording := false
var _record_time := 0.0
var _record_accum := 0.0
var _capture_hooked := false
var _keyframes: Array[Dictionary] = []
var _shot_events: Array[Dictionary] = []
var _rpg_events: Array[Dictionary] = []
var _impact_time := -1.0
var _impact_victim := ""
var _impact_hit_info: Dictionary = {}

var _playing := false
var _skipped := false
var _playback_phase := PlaybackPhase.IDLE
var _replay_time := 0.0
var _replay_duration := 0.0
var _impact_post_deadline_msec := 0
var _impact_ramp_start_msec := 0
var _fired_shots: Array[int] = []
var _spawned_rpg: Dictionary = {}
var _detonated_rpg: Array[int] = []

var _replay_camera: Camera3D
var _letterbox_top: ColorRect
var _letterbox_bottom: ColorRect
var _finish_callback: Callable
var _finishing := false


func setup(
	player: Node3D,
	enemy: Node3D,
	stage: Node3D,
	overlay: CanvasLayer,
	fade_overlay: ColorRect
) -> void:
	_player = player
	_enemy = enemy
	_stage = stage
	_overlay = overlay
	_fade_overlay = fade_overlay
	if _replay_camera == null:
		_build_replay_camera()
	if _letterbox_top == null:
		_build_letterbox()


func has_content() -> bool:
	return not _keyframes.is_empty() and _replay_duration > 0.05


func is_playing() -> bool:
	return _playing


func start_recording() -> void:
	_reset_playback_state()
	_recording = true
	_record_time = 0.0
	_record_accum = 0.0
	_keyframes.clear()
	_shot_events.clear()
	_rpg_events.clear()
	_impact_time = -1.0
	_impact_victim = ""
	_impact_hit_info = {}
	_replay_duration = 0.0
	set_process(true)
	_hook_capture()
	_capture_keyframe(0.0)


func finish_recording() -> void:
	if not _recording:
		return

	if _impact_time >= 0.0:
		_trim_keyframes_after(_impact_time)
		_replay_duration = maxf(_impact_time, MIN_PRE_IMPACT_DURATION)
	else:
		_capture_keyframe(_record_time)
		_replay_duration = maxf(_record_time, MIN_PRE_IMPACT_DURATION)

	_recording = false
	_unhook_capture()
	set_process(_playing)


func record_shot(from: Vector3, to: Vector3) -> void:
	if not _recording:
		return
	_shot_events.append({"t": _record_time, "from": from, "to": to})


func record_rpg_launch(from: Vector3, direction: Vector3) -> void:
	if not _recording:
		return
	var dir := direction.normalized()
	_rpg_events.append({
		"launch_t": _record_time,
		"impact_t": -1.0,
		"from": from,
		"to": from + dir * 12.0,
		"direction": dir,
	})


func has_pending_rpg_launch() -> bool:
	return not _rpg_events.is_empty() and float(_rpg_events[-1].get("impact_t", -1.0)) < 0.0


func record_rpg_impact(from: Vector3, to: Vector3) -> void:
	if not _recording or _rpg_events.is_empty():
		return
	var event: Dictionary = _rpg_events[_rpg_events.size() - 1]
	if float(event.get("impact_t", -1.0)) >= 0.0:
		return
	event["impact_t"] = _record_time
	event["from"] = from
	event["to"] = to


func record_impact(victim: String, hit_info: Dictionary) -> void:
	if not _recording or _impact_time >= 0.0:
		return
	_impact_victim = victim
	_impact_hit_info = _serialize_hit_info(hit_info)
	_impact_time = _record_time
	_capture_keyframe(_record_time)
	_trim_keyframes_after(_impact_time)


func play(on_finished: Callable = Callable()) -> void:
	_reset_time_scale()

	if not has_content():
		if on_finished.is_valid():
			on_finished.call()
		return

	_finish_callback = on_finished
	_playing = true
	_skipped = false
	_playback_phase = PlaybackPhase.PRE_IMPACT
	_replay_time = 0.0
	_impact_post_deadline_msec = 0
	_fired_shots.clear()
	_spawned_rpg.clear()
	_detonated_rpg.clear()
	_clear_replay_rockets()
	set_process(true)

	if _player != null and _player.has_method("reset_visual_for_replay"):
		_player.reset_visual_for_replay()
	if _enemy != null and _enemy.has_method("reset_visual_for_replay"):
		_enemy.reset_visual_for_replay()

	if _player != null and _player.has_method("set_replay_mode"):
		_player.set_replay_mode(true)
	if _enemy != null and _enemy.has_method("set_replay_mode"):
		_enemy.set_replay_mode(true)

	if _replay_camera != null:
		_replay_camera.current = true

	_show_letterbox(true)
	if _overlay != null and _overlay.has_method("show_replay_hud"):
		_overlay.show_replay_hud()

	_apply_replay_at_time(0.0)
	_update_replay_camera(0.0)


func skip() -> void:
	if _playing and not _skipped:
		_skip_replay()


func _process(delta: float) -> void:
	if _recording:
		_record_time += GameTime.process_delta(delta)
		return

	if not _playing:
		return

	if Input.is_action_just_pressed("ui_accept"):
		_skip_replay()
		return

	match _playback_phase:
		PlaybackPhase.PRE_IMPACT:
			_process_pre_impact(delta)
		PlaybackPhase.POST_IMPACT:
			_process_post_impact()
		_:
			pass


func _process_pre_impact(delta: float) -> void:
	_replay_time += GameTime.process_delta(delta) * REPLAY_SPEED
	_apply_replay_at_time(_replay_time)
	_update_replay_camera(_replay_time)

	var reached_impact := _impact_time >= 0.0 and _replay_time >= _impact_time
	var reached_end := _replay_time >= _replay_duration

	if reached_impact:
		_begin_post_impact()
	elif reached_end:
		_end_replay_with_fade()


func _process_post_impact() -> void:
	_update_impact_slowmo_ramp()
	if Time.get_ticks_msec() >= _impact_post_deadline_msec:
		_end_replay_with_fade()


func _begin_post_impact() -> void:
	if _playback_phase == PlaybackPhase.POST_IMPACT:
		return

	_replay_time = _impact_time if _impact_time >= 0.0 else _replay_time
	_apply_replay_at_time(_replay_time)

	_playback_phase = PlaybackPhase.POST_IMPACT

	var victim := _get_victim_node()
	print("[DuelRoundReplay] _begin_post_impact victim=%s hit_info_empty=%s" % [
		_impact_victim,
		_impact_hit_info.is_empty(),
	])
	if victim != null and victim.has_method("apply_replay_ragdoll") \
			and not _impact_hit_info.is_empty():
		victim.apply_replay_ragdoll(_deserialize_hit_info(_impact_hit_info))
	elif victim == null or _impact_hit_info.is_empty():
		push_warning("[DuelRoundReplay] post-impact ragdoll skipped victim=%s hit=%s" % [
			_impact_victim,
			_impact_hit_info,
		])

	GameTime.set_visual_slowmo(IMPACT_TIME_SCALE)
	_impact_ramp_start_msec = Time.get_ticks_msec()
	_impact_post_deadline_msec = _impact_ramp_start_msec \
		+ int(IMPACT_POST_REAL_DURATION * 1000.0)

	if _overlay != null and _overlay.has_method("begin_replay_slowmo"):
		_overlay.begin_replay_slowmo()
	elif _overlay != null and _overlay.has_method("pulse_replay_impact"):
		_overlay.pulse_replay_impact()

	_punch_replay_letterbox()


func _update_impact_slowmo_ramp() -> void:
	var elapsed := float(Time.get_ticks_msec() - _impact_ramp_start_msec) / 1000.0
	var ramp := clampf(elapsed / IMPACT_RAMP_REAL_DURATION, 0.0, 1.0)
	ramp = ramp * ramp * (3.0 - 2.0 * ramp)
	var visual_scale := lerpf(IMPACT_TIME_SCALE, 1.0, ramp)
	GameTime.set_visual_slowmo(visual_scale)
	if _overlay != null and _overlay.has_method("update_replay_visual_slowmo"):
		_overlay.update_replay_visual_slowmo(ramp)


func _input(event: InputEvent) -> void:
	if not _playing or _finishing:
		return
	if event is InputEventMouseButton and event.pressed:
		_skip_replay()


func _skip_replay() -> void:
	_skipped = true
	_end_replay_with_fade()


func _reset_playback_state() -> void:
	_playback_phase = PlaybackPhase.IDLE
	_impact_post_deadline_msec = 0
	_impact_ramp_start_msec = 0


func _reset_time_scale() -> void:
	GameTime.ensure_realtime()
	GameTime.reset_visual_slowmo()


func _hook_capture() -> void:
	if _capture_hooked:
		return
	var tree := get_tree()
	if tree == null:
		return
	if not tree.process_frame.is_connected(_capture_after_poses):
		tree.process_frame.connect(_capture_after_poses)
	_capture_hooked = true


func _unhook_capture() -> void:
	if not _capture_hooked:
		return
	var tree := get_tree()
	if tree != null and tree.process_frame.is_connected(_capture_after_poses):
		tree.process_frame.disconnect(_capture_after_poses)
	_capture_hooked = false


func _capture_after_poses() -> void:
	if not _recording:
		return
	_record_accum += GameTime.process_delta(get_process_delta_time())
	while _record_accum >= RECORD_INTERVAL:
		_record_accum -= RECORD_INTERVAL
		_capture_keyframe(_record_time)


func _get_victim_node() -> Node3D:
	if _impact_victim == "player":
		return _player
	if _impact_victim == "enemy":
		return _enemy
	return null


func _serialize_hit_info(hit_info: Dictionary) -> Dictionary:
	return {
		"position": hit_info.get("position", Vector3.ZERO),
		"normal": hit_info.get("normal", Vector3.UP),
		"direction": hit_info.get("direction", Vector3.FORWARD),
		"speed": hit_info.get("speed", 185.0),
	}


func _deserialize_hit_info(data: Dictionary) -> Dictionary:
	return {
		"position": data.get("position", Vector3.ZERO),
		"normal": data.get("normal", Vector3.UP),
		"direction": data.get("direction", Vector3.FORWARD),
		"speed": data.get("speed", 185.0),
	}


func _trim_keyframes_after(cutoff: float) -> void:
	var trimmed: Array[Dictionary] = []
	for frame in _keyframes:
		if frame["t"] <= cutoff + 0.001:
			trimmed.append(frame)
	_keyframes = trimmed

	var trimmed_shots: Array[Dictionary] = []
	for event in _shot_events:
		if event["t"] <= cutoff + 0.05:
			trimmed_shots.append(event)
	_shot_events = trimmed_shots


func _capture_keyframe(time: float) -> void:
	_keyframes.append({
		"t": time,
		"player": _capture_actor(_player),
		"enemy": _capture_actor(_enemy),
	})


func _capture_actor(actor: Node3D) -> Dictionary:
	if actor == null or not actor.has_method("capture_replay_snapshot"):
		return {}
	return actor.capture_replay_snapshot()


func _apply_replay_at_time(time: float) -> void:
	if _playback_phase == PlaybackPhase.POST_IMPACT:
		return

	var frame := _sample_keyframes(time)
	if frame.is_empty():
		return

	if _player != null and _player.has_method("apply_replay_snapshot"):
		var player_snap: Dictionary = frame.get("player", {})
		if not player_snap.is_empty():
			_player.apply_replay_snapshot(player_snap)
	if _enemy != null and _enemy.has_method("apply_replay_snapshot"):
		var enemy_snap: Dictionary = frame.get("enemy", {})
		if not enemy_snap.is_empty():
			_enemy.apply_replay_snapshot(enemy_snap)

	_fire_shots_up_to_time(time)
	_update_rpg_replay_at_time(time)


func _sample_keyframes(time: float) -> Dictionary:
	if _keyframes.is_empty():
		return {}

	if time <= _keyframes[0]["t"]:
		return _keyframes[0]

	for index in range(_keyframes.size() - 1):
		var a: Dictionary = _keyframes[index]
		var b: Dictionary = _keyframes[index + 1]
		if time <= b["t"]:
			var span: float = b["t"] - a["t"]
			var alpha := 0.0 if span <= 0.0001 else clampf((time - a["t"]) / span, 0.0, 1.0)
			return _lerp_frames(a, b, alpha)

	return _keyframes[_keyframes.size() - 1]


func _lerp_frames(a: Dictionary, b: Dictionary, alpha: float) -> Dictionary:
	return {
		"t": lerpf(a["t"], b["t"], alpha),
		"player": _lerp_snapshot(a.get("player", {}), b.get("player", {}), alpha),
		"enemy": _lerp_snapshot(a.get("enemy", {}), b.get("enemy", {}), alpha),
	}


func _lerp_snapshot(from: Dictionary, to: Dictionary, alpha: float) -> Dictionary:
	if from.is_empty():
		return to
	if to.is_empty():
		return from

	var eased := alpha * alpha * (3.0 - 2.0 * alpha)
	var result := {}

	if from.has("pos") and to.has("pos"):
		result["pos"] = from["pos"].lerp(to["pos"], eased)
	if from.has("rot_y") and to.has("rot_y"):
		result["rot_y"] = lerpf(from["rot_y"], to["rot_y"], eased)
	if from.has("rig_y") or to.has("rig_y"):
		result["rig_y"] = lerpf(from.get("rig_y", 0.0), to.get("rig_y", 0.0), eased)
	if from.has("lean_current") and to.has("lean_current"):
		result["lean_current"] = from["lean_current"].lerp(to["lean_current"], eased)
	if from.has("lean_blend") and to.has("lean_blend"):
		result["lean_blend"] = lerpf(from["lean_blend"], to["lean_blend"], eased)
	if from.has("lean_hold") or to.has("lean_hold"):
		result["lean_hold"] = lerpf(from.get("lean_hold", 0.0), to.get("lean_hold", 0.0), eased)
	if from.has("draw_state") and to.has("draw_state"):
		result["draw_state"] = to["draw_state"] if alpha >= 0.5 else from["draw_state"]
	if from.has("draw_progress") and to.has("draw_progress"):
		result["draw_progress"] = lerpf(from["draw_progress"], to["draw_progress"], eased)
	if from.has("gun_in_hand") and to.has("gun_in_hand"):
		result["gun_in_hand"] = to["gun_in_hand"] if alpha >= 0.5 else from["gun_in_hand"]
	if from.has("aim_target") and to.has("aim_target"):
		result["aim_target"] = from["aim_target"].lerp(to["aim_target"], eased)
	if from.has("jump_active") and to.has("jump_active"):
		result["jump_active"] = to["jump_active"] if alpha >= 0.5 else from["jump_active"]
	if from.has("jump_timer") or to.has("jump_timer"):
		result["jump_timer"] = lerpf(from.get("jump_timer", 0.0), to.get("jump_timer", 0.0), eased)
	if from.has("step_start") and to.has("step_start"):
		result["step_start"] = from["step_start"].lerp(to["step_start"], eased)
	elif to.has("step_start"):
		result["step_start"] = to["step_start"]
	elif from.has("step_start"):
		result["step_start"] = from["step_start"]
	if from.has("step_end") and to.has("step_end"):
		result["step_end"] = from["step_end"].lerp(to["step_end"], eased)
	elif to.has("step_end"):
		result["step_end"] = to["step_end"]
	elif from.has("step_end"):
		result["step_end"] = from["step_end"]
	if from.has("step_timer") or to.has("step_timer"):
		result["step_timer"] = lerpf(from.get("step_timer", 0.0), to.get("step_timer", 0.0), eased)
	if from.has("step_duration") or to.has("step_duration"):
		result["step_duration"] = lerpf(
			from.get("step_duration", 0.38),
			to.get("step_duration", 0.38),
			eased
		)
	var from_step_dir: Vector2 = from.get("step_direction", Vector2.ZERO)
	var to_step_dir: Vector2 = to.get("step_direction", Vector2.ZERO)
	if from_step_dir.length_squared() > 0.0001 or to_step_dir.length_squared() > 0.0001:
		if from_step_dir.length_squared() < 0.0001:
			result["step_direction"] = to_step_dir
		elif to_step_dir.length_squared() < 0.0001:
			result["step_direction"] = from_step_dir
		else:
			result["step_direction"] = from_step_dir.lerp(to_step_dir, eased).normalized()
	if from.has("step_active") or to.has("step_active") or result.has("step_timer"):
		result["step_active"] = (
			from.get("step_active", false)
			or to.get("step_active", false)
			or result.get("step_timer", 0.0) > 0.001
		)
	if from.has("forearm_recoil") or to.has("forearm_recoil"):
		result["forearm_recoil"] = lerpf(from.get("forearm_recoil", 0.0), to.get("forearm_recoil", 0.0), eased)
	if from.has("weapon") or to.has("weapon"):
		result["weapon"] = _lerp_weapon_snapshot(from.get("weapon", {}), to.get("weapon", {}), eased)

	return result


func _lerp_weapon_snapshot(from: Dictionary, to: Dictionary, alpha: float) -> Dictionary:
	if from.is_empty():
		return to
	if to.is_empty():
		return from

	var eased := alpha * alpha * (3.0 - 2.0 * alpha)
	return {
		"draw_state": to["draw_state"] if alpha >= 0.5 else from["draw_state"],
		"draw_progress": lerpf(from["draw_progress"], to["draw_progress"], eased),
		"gun_in_hand": to["gun_in_hand"] if alpha >= 0.5 else from["gun_in_hand"],
		"draw_active": to["draw_active"] if alpha >= 0.5 else from["draw_active"],
		"aim_target": from["aim_target"].lerp(to["aim_target"], eased),
		"forearm_recoil": lerpf(from.get("forearm_recoil", 0.0), to.get("forearm_recoil", 0.0), eased),
	}


func _fire_shots_up_to_time(time: float) -> void:
	for index in _shot_events.size():
		if index in _fired_shots:
			continue
		var event: Dictionary = _shot_events[index]
		if event["t"] > time:
			continue
		_fired_shots.append(index)
		if _stage != null:
			SHOT_BEAM.spawn(_stage, event["from"], event["to"])
			MuzzleFlashFXScript.spawn(_stage, event["from"])


func _update_rpg_replay_at_time(time: float) -> void:
	if _stage == null:
		return

	for index in _rpg_events.size():
		if index in _detonated_rpg:
			continue

		var event: Dictionary = _rpg_events[index]
		var impact_t := float(event.get("impact_t", -1.0))
		var launch_t := float(event.get("launch_t", 0.0))
		if impact_t < 0.0 or time < launch_t:
			continue

		if index not in _spawned_rpg:
			var rocket: Node3D = RPG_ROCKET_SCENE.instantiate()
			rocket.add_to_group("replay_rpg_rocket")
			_stage.add_child(rocket)
			var from: Vector3 = event["from"]
			var to: Vector3 = event["to"]
			if rocket.has_method("setup_replay"):
				rocket.setup_replay(from, to, _stage)
			_spawned_rpg[index] = rocket
			MuzzleFlashFXScript.spawn(_stage, from, &"symmetrical")
			if _player != null and _player.has_method("hide_rpg_grip_rocket_for_replay"):
				_player.hide_rpg_grip_rocket_for_replay()

		if index not in _spawned_rpg:
			continue

		var rocket_node: Node = _spawned_rpg[index]
		if not is_instance_valid(rocket_node):
			_spawned_rpg.erase(index)
			continue
		if rocket_node.has_method("sync_replay_time") \
				and rocket_node.sync_replay_time(time, launch_t, impact_t):
			_detonated_rpg.append(index)
			_spawned_rpg.erase(index)


func _clear_replay_rockets() -> void:
	if _stage == null:
		_spawned_rpg.clear()
		_detonated_rpg.clear()
		return
	for child in _stage.get_children():
		if child.is_in_group("replay_rpg_rocket"):
			child.queue_free()
	_spawned_rpg.clear()
	_detonated_rpg.clear()


func _update_replay_camera(time: float) -> void:
	if _replay_camera == null or _player == null or _enemy == null:
		return

	var framing := _compute_replay_framing(_player.global_position, _enemy.global_position)
	var midpoint: Vector3 = framing["midpoint"]
	var side: Vector3 = framing["side"]
	var side_distance: float = framing["side_distance"]
	var camera_height: float = framing["camera_height"]
	var fov: float = framing["fov"]

	var drift := sin(time * 1.35) * 0.28
	var cam_pos := midpoint + side * side_distance + Vector3(0.0, camera_height, drift)
	_replay_camera.fov = fov
	_replay_camera.global_position = cam_pos
	_replay_camera.look_at(midpoint + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0), Vector3.UP)


func _compute_replay_framing(player_pos: Vector3, enemy_pos: Vector3) -> Dictionary:
	var midpoint := (player_pos + enemy_pos) * 0.5
	midpoint.y = 1.2

	var duel_axis := enemy_pos - player_pos
	var separation := Vector2(duel_axis.x, duel_axis.z).length()
	if separation < 0.01:
		duel_axis = Vector3(0.0, 0.0, 1.0)
		separation = 1.0
	else:
		duel_axis = duel_axis.normalized()

	var classic_height := CLASSIC_CAMERA_HEIGHT
	var classic_side := clampf(
		CLASSIC_SIDE_BASE + separation * CLASSIC_SIDE_PER_PACE,
		CLASSIC_MIN_SIDE_DISTANCE,
		CLASSIC_MAX_SIDE_DISTANCE
	)
	var elevated_height := clampf(
		ELEVATED_MIN_HEIGHT + separation * ELEVATED_HEIGHT_PER_PACE,
		ELEVATED_MIN_HEIGHT,
		ELEVATED_MAX_HEIGHT
	)
	var elevated_side := clampf(
		ELEVATED_MIN_SIDE_DISTANCE + separation * ELEVATED_SIDE_PER_PACE,
		ELEVATED_MIN_SIDE_DISTANCE,
		ELEVATED_MAX_SIDE_DISTANCE
	)

	var use_classic := DuelPacesScript.uses_classic_replay_camera(separation)
	var camera_height := classic_height if use_classic else elevated_height
	var side_distance := classic_side if use_classic else elevated_side
	var min_fov := CLASSIC_MIN_FOV if use_classic else ELEVATED_MIN_FOV
	var max_fov := CLASSIC_MAX_FOV if use_classic else ELEVATED_MAX_FOV
	var clearance_padding := 1.0 if use_classic else BUILDING_CLEARANCE_PADDING
	var side := _pick_replay_camera_side(
		duel_axis,
		player_pos,
		enemy_pos,
		midpoint,
		camera_height,
		side_distance
	)

	var half_span := separation * 0.5 + CHARACTER_FRAMING_MARGIN
	var aspect := _get_replay_viewport_aspect()
	var vertical_offset := camera_height - CAMERA_LOOK_HEIGHT
	var fov := _required_vertical_fov(
		half_span,
		side_distance,
		vertical_offset,
		aspect,
		clearance_padding,
		min_fov,
		max_fov
	)

	if fov > max_fov:
		fov = max_fov
		var max_horizontal_half := tan(deg_to_rad(fov * 0.5)) * aspect
		var needed_distance := (half_span * clearance_padding) / maxf(max_horizontal_half, 0.01)
		var side_sq := maxf(needed_distance * needed_distance - vertical_offset * vertical_offset, 0.0)
		var min_side := CLASSIC_MIN_SIDE_DISTANCE if use_classic else ELEVATED_MIN_SIDE_DISTANCE
		var max_side := CLASSIC_MAX_SIDE_DISTANCE if use_classic else ELEVATED_MAX_SIDE_DISTANCE
		side_distance = clampf(sqrt(side_sq), min_side, max_side)
		side = _pick_replay_camera_side(
			duel_axis,
			player_pos,
			enemy_pos,
			midpoint,
			camera_height,
			side_distance
		)
		fov = _required_vertical_fov(
			half_span,
			side_distance,
			vertical_offset,
			aspect,
			clearance_padding,
			min_fov,
			max_fov
		)
		fov = clampf(fov, min_fov, max_fov)

	if not use_classic and fov > max_fov * 0.96:
		camera_height = clampf(
			camera_height + separation * 0.12,
			ELEVATED_MIN_HEIGHT,
			ELEVATED_MAX_HEIGHT
		)
		vertical_offset = camera_height - CAMERA_LOOK_HEIGHT
		side = _pick_replay_camera_side(
			duel_axis,
			player_pos,
			enemy_pos,
			midpoint,
			camera_height,
			side_distance
		)
		fov = _required_vertical_fov(
			half_span,
			side_distance,
			vertical_offset,
			aspect,
			clearance_padding,
			min_fov,
			max_fov
		)
		fov = clampf(fov, min_fov, max_fov)

	return {
		"midpoint": midpoint,
		"side": side,
		"side_distance": side_distance,
		"camera_height": camera_height,
		"fov": fov,
	}


func _pick_replay_camera_side(
	duel_axis: Vector3,
	player_pos: Vector3,
	enemy_pos: Vector3,
	midpoint: Vector3,
	camera_height: float,
	side_distance: float
) -> Vector3:
	var side_a := duel_axis.cross(Vector3.UP).normalized()
	if side_a.length_squared() < 0.01:
		side_a = Vector3.RIGHT
	var side_b := -side_a
	var look_target := midpoint + Vector3(0.0, CAMERA_LOOK_HEIGHT, 0.0)

	for side in [side_a, side_b]:
		var cam_pos: Vector3 = midpoint + side * side_distance + Vector3(0.0, camera_height, 0.0)
		var forward: Vector3 = (look_target - cam_pos).normalized()
		var right: Vector3 = forward.cross(Vector3.UP).normalized()
		if right.length_squared() < 0.01:
			continue
		var player_screen_x: float = right.dot(player_pos - look_target)
		var enemy_screen_x: float = right.dot(enemy_pos - look_target)
		if player_screen_x < enemy_screen_x:
			return side

	return side_a


func _required_vertical_fov(
	half_span: float,
	side_distance: float,
	vertical_offset: float,
	aspect: float,
	extra_padding: float = 1.0,
	min_fov: float = CLASSIC_MIN_FOV,
	max_fov: float = ELEVATED_MAX_FOV
) -> float:
	var camera_distance := sqrt(side_distance * side_distance + vertical_offset * vertical_offset)
	camera_distance = maxf(camera_distance, 0.01)
	var horizontal_half_fov := atan((half_span * FRAMING_PADDING * extra_padding) / camera_distance)
	var vertical_fov := rad_to_deg(2.0 * atan(tan(horizontal_half_fov) / maxf(aspect, 0.01)))
	return clampf(vertical_fov, min_fov, max_fov)


func _get_replay_viewport_aspect() -> float:
	var viewport := get_viewport()
	if viewport == null:
		return 16.0 / 9.0

	var rect := viewport.get_visible_rect()
	var letterbox_total := LETTERBOX_HEIGHT * 2.0 if _letterbox_top != null and _letterbox_top.visible else 0.0
	var effective_height := maxf(rect.size.y - letterbox_total, 1.0)
	return rect.size.x / effective_height


func _punch_replay_letterbox() -> void:
	if _letterbox_top == null or _letterbox_bottom == null:
		return
	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(_letterbox_top, "offset_bottom", 108.0, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(_letterbox_bottom, "offset_top", -108.0, 0.18)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


func _build_replay_camera() -> void:
	if _replay_camera != null or _stage == null:
		return

	_replay_camera = Camera3D.new()
	_replay_camera.name = "ReplayCamera"
	_replay_camera.fov = CLASSIC_MIN_FOV
	_replay_camera.current = false
	_stage.add_child(_replay_camera)


func _build_letterbox() -> void:
	if _letterbox_top != null or _overlay == null:
		return

	_letterbox_top = ColorRect.new()
	_letterbox_top.name = "ReplayLetterboxTop"
	_letterbox_top.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_top.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_letterbox_top.offset_bottom = 72.0
	_letterbox_top.visible = false
	_overlay.add_child(_letterbox_top)

	_letterbox_bottom = ColorRect.new()
	_letterbox_bottom.name = "ReplayLetterboxBottom"
	_letterbox_bottom.color = Color(0.02, 0.015, 0.01, 0.92)
	_letterbox_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_letterbox_bottom.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	_letterbox_bottom.offset_top = -72.0
	_letterbox_bottom.visible = false
	_overlay.add_child(_letterbox_bottom)


func _show_letterbox(visible: bool) -> void:
	if _letterbox_top:
		_letterbox_top.visible = visible
		_letterbox_top.offset_bottom = 72.0
	if _letterbox_bottom:
		_letterbox_bottom.visible = visible
		_letterbox_bottom.offset_top = -72.0


func _restore_live_view() -> void:
	_reset_time_scale()
	_reset_playback_state()
	_clear_replay_rockets()
	_show_letterbox(false)
	if _overlay != null and _overlay.has_method("end_replay_slowmo"):
		_overlay.end_replay_slowmo()
	if _overlay != null and _overlay.has_method("hide_replay_hud"):
		_overlay.hide_replay_hud()

	if _replay_camera != null:
		_replay_camera.current = false

	if _player != null and _player.has_method("set_replay_mode"):
		_player.set_replay_mode(false)
	if _enemy != null and _enemy.has_method("set_replay_mode"):
		_enemy.set_replay_mode(false)


func _end_replay_with_fade() -> void:
	if not _playing or _finishing:
		return

	_playing = false
	_finishing = true
	_playback_phase = PlaybackPhase.IDLE
	set_process(_recording)

	if _fade_overlay == null:
		_complete_replay_transition()
		return

	var tween := create_tween()
	tween.set_ignore_time_scale(true)
	tween.tween_property(_fade_overlay, "modulate:a", 1.0, FADE_OUT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(_complete_replay_transition)


func _complete_replay_transition() -> void:
	_restore_live_view()
	replay_finished.emit()

	if _finish_callback.is_valid():
		_finish_callback.call()

	if _fade_overlay != null:
		var tween := create_tween()
		tween.set_ignore_time_scale(true)
		tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.finished.connect(func() -> void:
			_finishing = false
		)
	else:
		_finishing = false
