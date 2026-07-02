extends Node

signal sound_muted_changed(muted: bool)

const SAVE_PATH := "user://game_settings.json"

var sound_muted := false


func _ready() -> void:
	_load_settings()
	_apply_sound_mute()


func set_sound_muted(muted: bool) -> void:
	if sound_muted == muted:
		return
	sound_muted = muted
	_apply_sound_mute()
	_save_settings()
	sound_muted_changed.emit(sound_muted)


func _apply_sound_mute() -> void:
	var master_bus := AudioServer.get_bus_index(&"Master")
	if master_bus < 0:
		return
	AudioServer.set_bus_mute(master_bus, sound_muted)


func _load_settings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		sound_muted = bool(parsed.get("sound_muted", false))


func _save_settings() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("GameSettings: failed to write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify({"sound_muted": sound_muted}))
