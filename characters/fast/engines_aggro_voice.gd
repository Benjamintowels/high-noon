extends FastAggroVoice
class_name EnginesAggroVoice


func schedule_raid_bark() -> void:
	_schedule_voice(
		_effective_aimed_voice_chance(),
		_effective_aimed_voice_delay_max(),
		VoiceKind.AGGRO
	)


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
