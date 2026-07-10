extends Node
class_name LadderAudio

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const FADE_IN := 0.1
const FADE_OUT := 0.16
const SILENCE_DB := -50.0
const CLIMB_SPRINT_PITCH := 2.0
const PITCH_FADE := 0.1

enum Mode { NONE, CLIMB, SLIDE }

var _owner: Node3D
var _player: AudioStreamPlayer3D
var _climb_loop: AudioStream
var _slide_loop: AudioStream
var _mode := Mode.NONE
var _fade: Tween
var _pitch_fade: Tween
var _audible := false


func setup(owner_node: Node3D) -> void:
	_owner = owner_node
	_ensure_player()


func update(climbing: bool, sprint_climb: bool, sliding: bool) -> void:
	if _owner == null:
		return

	_ensure_player()
	_player.global_position = _owner.global_position

	if sliding:
		_set_mode(Mode.SLIDE, 1.0, 0.0)
	elif climbing:
		var pitch := CLIMB_SPRINT_PITCH if sprint_climb else 1.0
		_set_mode(Mode.CLIMB, pitch, 0.0)
	else:
		_fade_out()


func stop() -> void:
	_mode = Mode.NONE
	_fade_out()


func _ensure_player() -> void:
	if _player != null:
		return

	_climb_loop = _make_looped(GameAudio.LADDER_CLIMB)
	_slide_loop = _make_looped(GameAudio.LADDER_SLIDE)

	_player = AudioStreamPlayer3D.new()
	_player.name = "LadderLoop"
	_player.max_distance = 80.0
	_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_player.unit_size = 4.0
	_player.volume_db = SILENCE_DB
	_player.pitch_scale = 1.0
	add_child(_player)


func _set_mode(mode: Mode, pitch: float, volume_db: float) -> void:
	if _player == null:
		return

	var stream := _slide_loop if mode == Mode.SLIDE else _climb_loop
	var stream_changed := _player.stream != stream

	if (
		_mode == mode
		and _audible
		and _player.playing
		and not stream_changed
		and is_equal_approx(_player.pitch_scale, pitch)
	):
		return

	if stream_changed:
		_kill_pitch_fade()
		_player.stream = stream
		_player.pitch_scale = 1.0
		_player.volume_db = SILENCE_DB
		if not _player.playing:
			_player.play()
	elif not _player.playing:
		_player.volume_db = SILENCE_DB
		_player.play()

	_mode = mode
	_fade_pitch_to(pitch)

	var fade_duration := FADE_IN
	_fade_volume_to(volume_db, fade_duration)


func _fade_out() -> void:
	if _mode == Mode.NONE and not _audible:
		return

	_mode = Mode.NONE
	_fade_volume_to(SILENCE_DB, FADE_OUT, true)


func _fade_volume_to(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()

	_audible = target_db > SILENCE_DB + 1.0
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", target_db, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stop_after:
		_fade.tween_callback(_stop_player)


func _fade_pitch_to(target_pitch: float) -> void:
	if _player == null:
		return
	if is_equal_approx(_player.pitch_scale, target_pitch):
		return

	_kill_pitch_fade()
	_pitch_fade = create_tween()
	_pitch_fade.tween_property(_player, "pitch_scale", target_pitch, PITCH_FADE)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_pitch_fade() -> void:
	if _pitch_fade != null and _pitch_fade.is_valid():
		_pitch_fade.kill()
	_pitch_fade = null


func _stop_player() -> void:
	_kill_pitch_fade()
	if _player.playing:
		_player.stop()
	_player.volume_db = SILENCE_DB
	_player.pitch_scale = 1.0
	_audible = false


func _make_looped(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate()
	if copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	elif copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	return copy
