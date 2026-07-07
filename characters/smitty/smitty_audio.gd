class_name SmittyAudio
extends RefCounted

const TALK_VOICES: Array[AudioStream] = [
	preload("res://Assets/CharacterModels/Smitty/SmittyVoiceLines/Deep,_resonant_male__#1-1783458731658.mp3"),
	preload("res://Assets/CharacterModels/Smitty/SmittyVoiceLines/Deep,_resonant_male__#3-1783458735201.mp3"),
	preload("res://Assets/CharacterModels/Smitty/SmittyVoiceLines/Deep,_resonant_male__#4-1783458738870.mp3"),
]


static func pick_talk_voice() -> AudioStream:
	if TALK_VOICES.is_empty():
		return null
	return TALK_VOICES[randi() % TALK_VOICES.size()]
