class_name GroypetteAudio
extends RefCounted

const CUTE_VOICES: Array[AudioStream] = [
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Cute_female_southern_#1-1783467471638.mp3"
	),
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Cute_female_southern_#2-1783467476237.mp3"
	),
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Cute_female_southern_#4-1783467481358.mp3"
	),
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Southern_woman_speak_#4-1783467526257.mp3"
	),
]

const FLIRTY_VOICES: Array[AudioStream] = [
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Flirty/Close-mic,_breathy_f_#2-1783467502906.mp3"
	),
]

const SCARED_VOICES: Array[AudioStream] = [
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Scared/Scared_female_southe_#1-1783467540745.mp3"
	),
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Scared/Scared_female_southe_#2-1783467545440.mp3"
	),
	preload(
		"res://Assets/CharacterModels/Groypette/Voicelines/Scared/Scared_female_southe_#4-1783467550787.mp3"
	),
]


static func pick_cute_voice() -> AudioStream:
	return _pick_random(CUTE_VOICES)


static func pick_flirty_voice() -> AudioStream:
	return _pick_random(FLIRTY_VOICES)


static func pick_scared_voice() -> AudioStream:
	return _pick_random(SCARED_VOICES)


static func _pick_random(pool: Array[AudioStream]) -> AudioStream:
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]
