extends Node

const SHOP_MUSIC: AudioStream = preload("res://Assets/Sounds/Music/ShopMusic.mp3")
const SHOP_MUSIC_VOLUME_DB := -18.0
const SHOP_MUSIC_FADE_IN := 1.0
const SHOP_MUSIC_FADE_OUT := 1.25
const SHOP_MUSIC_SILENCE_DB := -80.0

var _active := false
var _player_snapshot: Dictionary = {}
var _world_snapshot: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_fade: Tween


func is_inside_shop() -> bool:
	return _active


func save_before_enter(player: Node, stage: Node) -> void:
	if player.has_method("capture_overworld_snapshot"):
		_player_snapshot = player.capture_overworld_snapshot()
	else:
		_player_snapshot = {}
	_world_snapshot = _capture_world_snapshot(stage)
	_active = true


func enter_interior(player: Node, interior_marker: Marker3D) -> void:
	if interior_marker == null:
		return
	if player.has_method("teleport_to_position_only"):
		player.teleport_to_position_only(interior_marker.global_position, false)
	_start_shop_music()


func restore_after_exit(player: Node, stage: Node, fallback_marker: Marker3D = null) -> void:
	_stop_shop_music()
	if _active and not _player_snapshot.is_empty():
		if player.has_method("apply_overworld_transform_snapshot"):
			player.apply_overworld_transform_snapshot(_player_snapshot.get("transform", {}))
		elif player.has_method("apply_overworld_snapshot"):
			player.apply_overworld_snapshot(_player_snapshot)
	elif fallback_marker != null and player.has_method("teleport_to_position_only"):
		player.teleport_to_position_only(fallback_marker.global_position)

	_restore_world_snapshot(stage, _world_snapshot)
	_player_snapshot = {}
	_world_snapshot = {}
	_active = false


func _capture_world_snapshot(stage: Node) -> Dictionary:
	if stage == null:
		return {}

	return {
		"stage_path": stage.scene_file_path,
	}


func _restore_world_snapshot(_stage: Node, _snapshot: Dictionary) -> void:
	pass


func _ensure_music_player() -> void:
	if _music_player != null:
		return

	var stream := SHOP_MUSIC.duplicate()
	if stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true

	_music_player = AudioStreamPlayer.new()
	_music_player.name = "ShopMusicPlayer"
	_music_player.stream = stream
	_music_player.volume_db = SHOP_MUSIC_SILENCE_DB
	add_child(_music_player)


func _start_shop_music() -> void:
	if SHOP_MUSIC == null:
		return

	_ensure_music_player()
	_kill_music_fade()

	if not _music_player.playing:
		_music_player.volume_db = SHOP_MUSIC_SILENCE_DB
		_music_player.play()

	_music_fade = create_tween()
	_music_fade.tween_property(_music_player, "volume_db", SHOP_MUSIC_VOLUME_DB, SHOP_MUSIC_FADE_IN)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _stop_shop_music() -> void:
	if _music_player == null or not _music_player.playing:
		return

	_kill_music_fade()
	_music_fade = create_tween()
	_music_fade.tween_property(_music_player, "volume_db", SHOP_MUSIC_SILENCE_DB, SHOP_MUSIC_FADE_OUT)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_music_fade.finished.connect(_on_shop_music_faded_out, CONNECT_ONE_SHOT)


func _on_shop_music_faded_out() -> void:
	if _music_player != null:
		_music_player.stop()


func _kill_music_fade() -> void:
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	_music_fade = null
