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


func schedule_raid_bark() -> void:
	var kinds: Array[VoiceKind] = [VoiceKind.AGGRO, VoiceKind.WOAH, VoiceKind.CHEER]
	var kind: VoiceKind = kinds[randi() % kinds.size()]
	_schedule_voice(
		_effective_aimed_voice_chance(),
		_effective_aimed_voice_delay_max(),
		kind
	)
