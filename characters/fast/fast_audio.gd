class_name FastAudio
extends RefCounted

const FallbackGameAudio := preload("res://gameplay/audio/game_audio.gd")

const FAST_TALK_ROOT := "res://Assets/Sounds/FastTalk"

static var _aggro_sounds: Array[AudioStream] = []
static var _woah_sounds: Array[AudioStream] = []
static var _cheer_sounds: Array[AudioStream] = []
static var _loaded := false


static func pick_aggro_voice() -> AudioStream:
	_ensure_loaded()
	if _aggro_sounds.is_empty():
		return FallbackGameAudio.pick_aggro_voice()
	return _aggro_sounds[randi() % _aggro_sounds.size()]


static func pick_woah_voice() -> AudioStream:
	_ensure_loaded()
	if _woah_sounds.is_empty():
		return FallbackGameAudio.pick_woah_voice()
	return _woah_sounds[randi() % _woah_sounds.size()]


static func pick_cheer_voice() -> AudioStream:
	_ensure_loaded()
	if _cheer_sounds.is_empty():
		return FallbackGameAudio.pick_cheer_voice()
	return _cheer_sounds[randi() % _cheer_sounds.size()]


static func _ensure_loaded() -> void:
	if _loaded:
		return
	_loaded = true
	_load_dir(FAST_TALK_ROOT, _aggro_sounds)
	_load_dir("%s/Woah" % FAST_TALK_ROOT, _woah_sounds)
	_load_dir("%s/Cheer" % FAST_TALK_ROOT, _cheer_sounds)


static func _load_dir(dir_path: String, out_pool: Array[AudioStream]) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and _is_audio_file(file_name):
			var stream: Variant = load("%s/%s" % [dir_path, file_name])
			if stream is AudioStream:
				out_pool.append(stream)
		file_name = dir.get_next()
	dir.list_dir_end()


static func _is_audio_file(file_name: String) -> bool:
	return (
		file_name.ends_with(".mp3")
		or file_name.ends_with(".wav")
		or file_name.ends_with(".ogg")
	)
