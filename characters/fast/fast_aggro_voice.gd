extends TownAggroVoice
class_name FastAggroVoice

const FastAudio := preload("res://characters/fast/fast_audio.gd")


func _play_easy_there_voice() -> void:
	_play_voice_line(GameAudio.EASY_THERE_VOICE)


func _play_woah_voice() -> void:
	var stream: AudioStream = FastAudio.pick_woah_voice()
	if stream == null:
		return
	_play_voice_line(stream)


func _play_aggro_voice() -> void:
	var stream: AudioStream = FastAudio.pick_aggro_voice()
	if stream == null:
		return
	_play_voice_line(stream)


func _play_cheer_voice() -> void:
	var stream: AudioStream = FastAudio.pick_cheer_voice()
	if stream == null:
		return
	_play_voice_line(stream)
