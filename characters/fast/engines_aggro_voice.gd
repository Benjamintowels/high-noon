extends FastAggroVoice
class_name EnginesAggroVoice


func _play_easy_there_voice() -> void:
	_play_native_american_voice()


func _play_woah_voice() -> void:
	_play_native_american_voice()


func _play_aggro_voice() -> void:
	_play_native_american_voice()


func _play_cheer_voice() -> void:
	_play_native_american_voice()


func _play_native_american_voice() -> void:
	var stream: AudioStream = FastAudio.pick_native_american_warc()
	if stream == null:
		return
	_play_voice_line(stream)
