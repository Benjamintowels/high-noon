class_name UncleToadAudio
extends RefCounted

const SCREAM := preload("res://Assets/CharacterModels/UncleToad/Voicelines/Scream.mp3")

const WOAH_VOICES: Array[AudioStream] = [
	preload(
		"res://Assets/CharacterModels/UncleToad/Voicelines/Refined_cowboy_drawl_#4-1783446599011.mp3"
	),
]

const TALK_VOICES: Array[AudioStream] = [
	preload("res://Assets/CharacterModels/UncleToad/Voicelines/southern_talk_#2-1783446651946.mp3"),
	preload("res://Assets/CharacterModels/UncleToad/Voicelines/southern_talk_#3-1783446655986.mp3"),
	preload("res://Assets/CharacterModels/UncleToad/Voicelines/southern_talk_#4-1783446660236.mp3"),
	preload(
		"res://Assets/CharacterModels/UncleToad/Voicelines/Uncle_Sam_speaking_w_#3-1783446474175.mp3"
	),
]


static func pick_woah_voice() -> AudioStream:
	return _pick_random(WOAH_VOICES)


static func pick_talk_voice() -> AudioStream:
	return _pick_random(TALK_VOICES)


static func _pick_random(pool: Array[AudioStream]) -> AudioStream:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]
