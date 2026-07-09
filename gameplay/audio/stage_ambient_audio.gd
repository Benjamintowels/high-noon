extends Node
class_name StageAmbientAudio

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const DAY_AMBIENT := preload("res://Assets/Sounds/Birds.mp3")
const NIGHT_AMBIENT := preload("res://Assets/Sounds/NightDesert.mp3")
const CROSSFADE_SECONDS := 2.0
const INDOOR_FADE_SECONDS := 0.8
const MUTE_DB := -60.0

const OWL_INTERVAL_MIN := 10.0
const OWL_INTERVAL_MAX := 15.0
const OWL_CHANCE := 0.5

var _player: AudioStreamPlayer
var _playing_night := false
var _fade: Tween
var _pending_stream: AudioStream
var _indoors := false
var _owl_timer := 0.0


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "AmbientPlayer"
	add_child(_player)
	_owl_timer = randf_range(OWL_INTERVAL_MIN, OWL_INTERVAL_MAX)
	DayNightCycle.cycle_progress_changed.connect(_on_cycle_changed)
	_on_cycle_changed(DayNightCycle.cycle_progress)


func _exit_tree() -> void:
	if DayNightCycle.cycle_progress_changed.is_connected(_on_cycle_changed):
		DayNightCycle.cycle_progress_changed.disconnect(_on_cycle_changed)


func _process(delta: float) -> void:
	var inside := ShopSession.is_inside_shop()
	if inside != _indoors:
		_indoors = inside
		_fade_to_target()

	_owl_timer -= delta
	if _owl_timer <= 0.0:
		_owl_timer = randf_range(OWL_INTERVAL_MIN, OWL_INTERVAL_MAX)
		if DayNightCycle.is_night_time() and not _indoors and randf() < OWL_CHANCE:
			GameAudioScript.play_owl_hoot(self)


func _target_volume_db() -> float:
	return MUTE_DB if _indoors else 0.0


func _on_cycle_changed(_progress: float) -> void:
	var want_night := DayNightCycle.is_night_time()
	if want_night == _playing_night and _player.playing:
		return
	_playing_night = want_night
	_switch_ambient(want_night)


func _switch_ambient(night: bool) -> void:
	var source := NIGHT_AMBIENT if night else DAY_AMBIENT
	if source == null:
		return

	var stream := source.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	if _fade != null and _fade.is_valid():
		_fade.kill()

	if not _player.playing:
		_pending_stream = stream
		_apply_pending_stream()
		_player.volume_db = _target_volume_db()
		return

	_pending_stream = stream
	var half_fade := CROSSFADE_SECONDS * 0.5
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", -40.0, half_fade)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_callback(_apply_pending_stream)
	_fade.tween_property(_player, "volume_db", _target_volume_db(), half_fade)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _apply_pending_stream() -> void:
	if _pending_stream == null:
		return
	_player.stream = _pending_stream
	_pending_stream = null
	_player.play()


func _fade_to_target() -> void:
	if _fade != null and _fade.is_valid():
		_fade.kill()
	_apply_pending_stream()
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", _target_volume_db(), INDOOR_FADE_SECONDS)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
