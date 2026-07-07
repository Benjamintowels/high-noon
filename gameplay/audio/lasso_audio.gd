extends Node
class_name LassoAudio

const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")
const LassoTautDragScript := preload("res://gameplay/lasso/lasso_taut_drag.gd")

const TWIRL_VOLUME_DB := -14.0
const THROW_VOLUME_DB := -2.0
const TIGHTEN_VOLUME_DB := -4.0
const DRAG_LOOP_VOLUME_DB := -18.0
const SILENCE_DB := -60.0
const DRAG_ACTIVE_SPEED := 0.35
const TWIRL_FADE_IN := 0.1
const DRAG_FADE_IN := 0.14
const DRAG_FADE_OUT := 0.22

var _owner: Node3D
var _lasso_controller: LassoController
var _last_state := LassoController.State.IDLE
var _twirl_player: AudioStreamPlayer3D
var _drag_player: AudioStreamPlayer3D
var _twirl_fade: Tween
var _drag_fade: Tween
var _drag_audible := false
var _tighten_played := false


func setup(owner_node: Node3D, lasso_controller: LassoController) -> void:
	_owner = owner_node
	_lasso_controller = lasso_controller
	if _lasso_controller != null and not _lasso_controller.state_changed.is_connected(_on_state_changed):
		_lasso_controller.state_changed.connect(_on_state_changed)
	set_process(true)


func _process(_delta: float) -> void:
	if _lasso_controller == null or _owner == null:
		return
	if _lasso_controller.get_state() == LassoController.State.DRAGGING:
		_update_drag_loop()
	else:
		_fade_drag_loop_out()
	_sync_loop_positions()


func _on_state_changed(new_state: LassoController.State) -> void:
	match new_state:
		LassoController.State.IDLE:
			_stop_twirl()
			_fade_drag_loop_out()
			_tighten_played = false
		LassoController.State.CHARGING:
			_start_twirl()
		LassoController.State.THROWING:
			_stop_twirl()
			_play_throw()
		LassoController.State.TIGHTENING:
			_stop_twirl()
			_play_tighten_once()
		LassoController.State.DRAGGING:
			_stop_twirl()
		LassoController.State.RETRACTING:
			_stop_twirl()
			_fade_drag_loop_out()
	_last_state = new_state


func _start_twirl() -> void:
	_ensure_twirl_player()
	if not _twirl_player.playing:
		_twirl_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
		_twirl_player.play()
	_fade_twirl_volume_to(TWIRL_VOLUME_DB, TWIRL_FADE_IN)


func _stop_twirl() -> void:
	_fade_twirl_volume_to(SILENCE_DB, 0.08, true)


func _play_throw() -> void:
	if _owner == null:
		return
	GameAudio.play_rope_throw(_owner, _get_audio_position(), THROW_VOLUME_DB)


func _play_tighten_once() -> void:
	if _tighten_played or _owner == null:
		return
	var stream := GameAudio.pick_rope_pull_sound()
	if stream == null:
		return
	_tighten_played = true
	GameAudio.play_rope_one_shot(_owner, stream, _get_audio_position(), TIGHTEN_VOLUME_DB)


func _update_drag_loop() -> void:
	if not _is_actively_pulling():
		_fade_drag_loop_out()
		return

	_ensure_drag_player()
	if not _drag_player.playing:
		var stream := GameAudio.pick_rope_pull_sound()
		if stream == null:
			return
		_drag_player.stream = _make_looped(stream)
		_drag_player.pitch_scale = randf_range(GameAudio.PITCH_MIN, GameAudio.PITCH_MAX)
		_drag_player.volume_db = SILENCE_DB
		_drag_player.play()
	_fade_drag_volume_to(DRAG_LOOP_VOLUME_DB, DRAG_FADE_IN)


func _is_actively_pulling() -> bool:
	if _lasso_controller == null or not _lasso_controller.is_dragging():
		return false
	var captive := _lasso_controller.get_captured_target()
	if captive == null or not is_instance_valid(captive):
		return false
	if not (_owner is CharacterBody3D):
		return false

	var body := _owner as CharacterBody3D
	var speed := Vector2(body.velocity.x, body.velocity.z).length()
	if speed < DRAG_ACTIVE_SPEED:
		return false

	var leader_anchor := LassoTautDragScript.get_leader_anchor(_owner)
	var attach := LassoTargetUtils.get_attach_point(captive)
	var offset := leader_anchor - attach
	offset.y = 0.0
	var dist := offset.length()
	var rope_len := _lasso_controller.get_rope_length()
	if captive.has_method("get_lasso_rope_length"):
		rope_len = float(captive.call("get_lasso_rope_length"))
	if dist < rope_len * LassoTautDragScript.TAUT_RATIO:
		return false

	if captive.has_meta(&"lasso_ragdoll_active") and bool(captive.get_meta(&"lasso_ragdoll_active")):
		return true

	var leader_vel := LassoTautDragScript.get_leader_velocity(_owner)
	var to_leader := offset / maxf(dist, 0.001)
	var away_speed := Vector3(leader_vel.x, 0.0, leader_vel.z).dot(to_leader)
	return away_speed > 0.12


func _fade_drag_loop_out() -> void:
	if _drag_player == null or not _drag_audible:
		return
	_fade_drag_volume_to(SILENCE_DB, DRAG_FADE_OUT, true)


func _ensure_twirl_player() -> void:
	if _twirl_player != null:
		return
	_twirl_player = AudioStreamPlayer3D.new()
	_twirl_player.name = "LassoTwirlLoop"
	_twirl_player.stream = _make_looped(GameAudio.ROPE_TWIRL)
	_twirl_player.max_distance = 48.0
	_twirl_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_twirl_player.unit_size = 3.0
	_twirl_player.volume_db = SILENCE_DB
	add_child(_twirl_player)


func _ensure_drag_player() -> void:
	if _drag_player != null:
		return
	_drag_player = AudioStreamPlayer3D.new()
	_drag_player.name = "LassoDragLoop"
	_drag_player.max_distance = 56.0
	_drag_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_drag_player.unit_size = 4.0
	_drag_player.volume_db = SILENCE_DB
	add_child(_drag_player)


func _fade_twirl_volume_to(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _twirl_player == null:
		return
	if _twirl_fade != null and _twirl_fade.is_valid():
		_twirl_fade.kill()
	_twirl_fade = create_tween()
	_twirl_fade.tween_property(_twirl_player, "volume_db", target_db, duration)
	if stop_after:
		_twirl_fade.tween_callback(_stop_twirl_player)


func _fade_drag_volume_to(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _drag_player == null:
		return
	_drag_audible = target_db > SILENCE_DB + 1.0
	if _drag_fade != null and _drag_fade.is_valid():
		_drag_fade.kill()
	_drag_fade = create_tween()
	_drag_fade.tween_property(_drag_player, "volume_db", target_db, duration)
	if stop_after:
		_drag_fade.tween_callback(_stop_drag_player)


func _stop_twirl_player() -> void:
	if _twirl_player != null and _twirl_player.playing:
		_twirl_player.stop()
	if _twirl_player != null:
		_twirl_player.volume_db = SILENCE_DB


func _stop_drag_player() -> void:
	if _drag_player != null and _drag_player.playing:
		_drag_player.stop()
	if _drag_player != null:
		_drag_player.volume_db = SILENCE_DB
	_drag_audible = false


func _sync_loop_positions() -> void:
	var pos := _get_audio_position()
	if _twirl_player != null:
		_twirl_player.global_position = pos
	if _drag_player != null:
		_drag_player.global_position = pos


func _get_audio_position() -> Vector3:
	if _owner != null and _owner.has_method("get_lasso_throw_anchor"):
		return _owner.call("get_lasso_throw_anchor")
	if _owner is Node3D:
		return (_owner as Node3D).global_position + Vector3(0.0, 1.2, 0.0)
	return Vector3.ZERO


func _make_looped(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate()
	if copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	elif copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	return copy
