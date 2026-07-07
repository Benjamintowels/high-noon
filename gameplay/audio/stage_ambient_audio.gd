extends Node
class_name StageAmbientAudio

const DAY_AMBIENT := preload("res://Assets/Sounds/Birds.mp3")
const NIGHT_AMBIENT := preload("res://Assets/Sounds/NightDesert.mp3")
const CROSSFADE_SECONDS := 2.0

var _player: AudioStreamPlayer
var _playing_night := false
var _fade: Tween


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.name = "AmbientPlayer"
	add_child(_player)
	DayNightCycle.cycle_progress_changed.connect(_on_cycle_changed)
	_on_cycle_changed(DayNightCycle.cycle_progress)


func _exit_tree() -> void:
	if DayNightCycle.cycle_progress_changed.is_connected(_on_cycle_changed):
		DayNightCycle.cycle_progress_changed.disconnect(_on_cycle_changed)


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
		_player.stream = stream
		_player.volume_db = 0.0
		_player.play()
		return

	var half_fade := CROSSFADE_SECONDS * 0.5
	_fade = create_tween()
	_fade.tween_property(_player, "volume_db", -40.0, half_fade)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_fade.tween_callback(func() -> void:
		_player.stream = stream
		_player.play()
	)
	_fade.tween_property(_player, "volume_db", 0.0, half_fade)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
