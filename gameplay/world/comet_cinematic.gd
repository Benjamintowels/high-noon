extends Node
class_name CometCinematic

const CometVisualScript := preload("res://gameplay/world/comet_visual.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

const PLAYER_SPEAKER := "Groyper"
const NARRATION_LINE := "What was that??"

const FALLBACK_COMET_START := Vector3(-55.0, 98.0, 215.0)
const FALLBACK_COMET_END := Vector3(-305.0, 28.0, 245.0)
const CRASH_PAST_END_DISTANCE := 140.0

const FLIGHT_DURATION := 8.5
const CAMERA_RETURN_AT_PROGRESS := 0.55
const CAMERA_RETURN_DURATION := 1.0
const POST_CONTROL_CRASH_DELAY := 4.0

var _player: Node3D
var _trigger: Area3D
var _comet: CometVisual
var _comet_start_pos := Vector3.ZERO
var _comet_end_pos := Vector3.ZERO
var _crash_position := Vector3.ZERO
var _active := false
var _skip_requested := false
var _flight_tween: Tween
var _sequence_token := 0
var _camera_return_started := false
var _camera_return_started_at := 0.0


func setup(trigger: Area3D, player: Node3D) -> void:
	if CometProgress.completed or trigger == null or player == null:
		if trigger != null:
			trigger.monitoring = false
		return

	_player = player
	_trigger = trigger
	_configure_trigger(trigger)
	if not trigger.body_entered.is_connected(_on_body_entered):
		trigger.body_entered.connect(_on_body_entered)


func _configure_trigger(trigger: Area3D) -> void:
	trigger.monitoring = true
	trigger.monitorable = false
	var collision := trigger.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = false


func _on_body_entered(body: Node3D) -> void:
	if _active or CometProgress.completed:
		return
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player = body
	_begin_sequence()


func _begin_sequence() -> void:
	if _active:
		return
	_active = true
	_skip_requested = false
	_camera_return_started = false
	_camera_return_started_at = 0.0
	_sequence_token += 1
	var token := _sequence_token
	if _trigger != null:
		_trigger.monitoring = false

	_resolve_comet_markers()
	_spawn_comet()
	if _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(_comet, Callable(self, "_request_skip"))

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	GameAudioScript.play_comet_flyby(self, _comet_start_pos)
	await _fly_comet(token)
	if token != _sequence_token:
		return

	await _ensure_camera_returned(token)
	if token != _sequence_token:
		return

	if _comet != null and is_instance_valid(_comet):
		_comet.fade_out(0.65)
		_comet = null

	await _exit_letterbox()

	await get_tree().create_timer(POST_CONTROL_CRASH_DELAY).timeout
	if token != _sequence_token:
		return

	_play_distant_crash()
	await _show_narration()
	if token != _sequence_token:
		return

	CometProgress.mark_completed()
	_cleanup()


func _request_skip() -> void:
	if not _active or _skip_requested:
		return
	_skip_requested = true
	if _flight_tween != null and _flight_tween.is_valid():
		_flight_tween.kill()
	if _comet != null and is_instance_valid(_comet):
		_comet.global_position = _sample_comet_path(0.94)
	_begin_camera_return()


func _spawn_comet() -> void:
	var stage := get_tree().current_scene
	if stage == null:
		return
	_comet = CometVisualScript.new()
	_comet.name = "Comet"
	stage.add_child(_comet)
	_comet.global_position = _comet_start_pos


func _resolve_comet_markers() -> void:
	if _trigger == null:
		_comet_start_pos = FALLBACK_COMET_START
		_comet_end_pos = FALLBACK_COMET_END
	else:
		var start_marker := _trigger.get_node_or_null("CometStart") as Marker3D
		var end_marker := _trigger.get_node_or_null("CometEnd") as Marker3D
		if start_marker != null and end_marker != null:
			_comet_start_pos = start_marker.global_position
			_comet_end_pos = end_marker.global_position
		else:
			push_warning("CometCinematic: missing CometStart/CometEnd markers, using fallback path.")
			_comet_start_pos = FALLBACK_COMET_START
			_comet_end_pos = FALLBACK_COMET_END

	var flight := _comet_end_pos - _comet_start_pos
	if flight.length_squared() < 0.0001:
		_crash_position = _comet_end_pos
		return
	_crash_position = _comet_end_pos + flight.normalized() * CRASH_PAST_END_DISTANCE
	_crash_position.y = minf(_comet_end_pos.y * 0.12, 14.0)


func _fly_comet(token: int) -> void:
	if _comet == null:
		return
	if _flight_tween != null and _flight_tween.is_valid():
		_flight_tween.kill()
	_flight_tween = create_tween()
	_flight_tween.tween_method(_on_flight_progress, 0.0, 1.0, FLIGHT_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	while _flight_tween.is_running() and not _skip_requested and token == _sequence_token:
		await get_tree().process_frame


func _on_flight_progress(progress: float) -> void:
	_set_flight_progress(progress)
	if not _camera_return_started and progress >= CAMERA_RETURN_AT_PROGRESS:
		_begin_camera_return()


func _begin_camera_return() -> void:
	if _camera_return_started:
		return
	_camera_return_started = true
	_camera_return_started_at = Time.get_ticks_msec() / 1000.0
	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()


func _ensure_camera_returned(token: int) -> void:
	if _player == null:
		return
	if not _camera_return_started:
		_begin_camera_return()
	var duration := 0.45 if _skip_requested else CAMERA_RETURN_DURATION
	var elapsed := (Time.get_ticks_msec() / 1000.0) - _camera_return_started_at
	var remaining := maxf(duration - elapsed, 0.0)
	if remaining > 0.0:
		await get_tree().create_timer(remaining).timeout
	if token != _sequence_token:
		return
	if _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()


func _set_flight_progress(progress: float) -> void:
	if _comet == null or not is_instance_valid(_comet):
		return
	var position := _sample_comet_path(progress)
	var ahead_t := clampf(progress + 0.04, 0.0, 1.0)
	var ahead := _sample_comet_path(ahead_t)
	_comet.global_position = position
	_comet.set_flight_direction(ahead - position)


func _sample_comet_path(progress: float) -> Vector3:
	return _comet_start_pos.lerp(_comet_end_pos, clampf(progress, 0.0, 1.0))


func _exit_letterbox() -> void:
	var hud := _get_raid_hud()
	if hud == null or not hud.has_method("hide_drama_letterbox"):
		return
	var done := false
	hud.hide_drama_letterbox(func() -> void:
		done = true
	)
	while not done:
		await get_tree().process_frame


func _play_distant_crash() -> void:
	var stage := get_tree().current_scene
	if stage == null:
		return
	GameAudioScript.play_distant_comet_crash(stage, _crash_position)
	GameAudioScript.notify_birds_of_explosion(stage, _crash_position)
	MuzzleFlashFXScript.spawn(stage, _crash_position, &"epic_explosion", 0.16)
	SmokePuffFXScript.spawn_burst(stage, _crash_position, 8)
	if _player != null and _player.has_method("apply_camera_shake"):
		_player.apply_camera_shake(0.42)


func _show_narration() -> void:
	if _player == null:
		return
	_lock_player_dialog(true)
	var done := false
	DialogManager.show_dialog(
		PLAYER_SPEAKER,
		NARRATION_LINE,
		func() -> void:
			DialogManager.hide_dialog()
			done = true
	)
	while not done:
		await get_tree().process_frame
	_lock_player_dialog(false)
	if _player != null and _player.has_method("restore_explore_camera_control"):
		_player.restore_explore_camera_control()


func _cleanup() -> void:
	_active = false
	if _comet != null and is_instance_valid(_comet):
		_comet.queue_free()
	_comet = null


func _lock_player_dialog(active: bool) -> void:
	if _player == null:
		return
	if _player.has_method("set_transition_locked"):
		_player.set_transition_locked(active)
	if _player.has_method("set_dialog_active"):
		_player.set_dialog_active(active)


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null
