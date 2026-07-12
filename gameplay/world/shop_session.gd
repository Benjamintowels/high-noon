extends Node

const SHOP_MUSIC: AudioStream = preload("res://Assets/Sounds/Music/ShopMusic.mp3")
const HOME_MUSIC: AudioStream = preload("res://Assets/Sounds/HomeMusic.mp3")
const SMITH_MUSIC: AudioStream = preload("res://Assets/Sounds/SmithMusic.mp3")
const SHOP_MUSIC_VOLUME_DB := -18.0
const HOME_MUSIC_VOLUME_DB := -28.0
const SMITH_MUSIC_VOLUME_DB := -30.0
const SHOP_MUSIC_FADE_IN := 1.0
const SHOP_MUSIC_FADE_OUT := 1.25
const SHOP_MUSIC_SILENCE_DB := -80.0

var _active := false
var _interior_music_only := false
var _player_snapshot: Dictionary = {}
var _world_snapshot: Dictionary = {}
var _music_player: AudioStreamPlayer
var _music_fade: Tween
var _music_volume_db := SHOP_MUSIC_VOLUME_DB
var _music_source: AudioStream


func is_inside_shop() -> bool:
	return _active or _interior_music_only


func is_interior_space() -> bool:
	return _active


func reset_for_outdoor_spawn() -> void:
	_active = false
	_interior_music_only = false
	_player_snapshot = {}
	_world_snapshot = {}
	_stop_shop_music()


## Mark the player as inside an interior without a door-entry snapshot (fast
## travel, death respawn, new-game start). Exit doors fall back to their
## entrance marker when no snapshot exists.
func begin_interior_space() -> void:
	_active = true


func save_before_enter(player: Node, stage: Node) -> void:
	if player.has_method("capture_overworld_snapshot"):
		_player_snapshot = player.capture_overworld_snapshot()
	else:
		_player_snapshot = {}
	_world_snapshot = _capture_world_snapshot(stage)
	_active = true
	_interior_music_only = false


func enter_interior(
	player: Node,
	interior_marker: Marker3D,
	play_music: bool = true,
	music_stream: AudioStream = null,
	music_volume_db: float = SHOP_MUSIC_VOLUME_DB,
) -> void:
	if interior_marker == null:
		return
	if player.has_method("teleport_to_position_only"):
		player.teleport_to_position_only(interior_marker.global_position, false)
	if play_music:
		_start_interior_music(music_stream if music_stream != null else SHOP_MUSIC, music_volume_db)


func start_home_music() -> void:
	_interior_music_only = true
	_start_interior_music(HOME_MUSIC, HOME_MUSIC_VOLUME_DB)


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
	_interior_music_only = false


func _capture_world_snapshot(stage: Node) -> Dictionary:
	if stage == null:
		return {}

	return {
		"stage_path": stage.scene_file_path,
	}


func _restore_world_snapshot(_stage: Node, _snapshot: Dictionary) -> void:
	pass


func _ensure_music_player(stream: AudioStream) -> void:
	if stream == null:
		return

	if _music_player == null:
		_music_player = AudioStreamPlayer.new()
		_music_player.name = "InteriorMusicPlayer"
		_music_player.volume_db = SHOP_MUSIC_SILENCE_DB
		add_child(_music_player)

	if _music_source == stream and _music_player.stream != null:
		return

	var looped := stream.duplicate()
	if looped is AudioStreamMP3:
		(looped as AudioStreamMP3).loop = true

	_music_player.stop()
	_music_player.stream = looped
	_music_source = stream


func _start_interior_music(stream: AudioStream, volume_db: float) -> void:
	if stream == null:
		return

	_music_volume_db = volume_db
	_kill_music_fade()

	var same_track := _music_player != null and _music_source == stream and _music_player.stream != null
	if same_track and _music_player.playing:
		_music_fade = create_tween()
		_music_fade.tween_property(_music_player, "volume_db", _music_volume_db, SHOP_MUSIC_FADE_IN)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		return

	var crossfade := _music_player != null and _music_player.playing and _music_source != stream
	if crossfade:
		_music_fade = create_tween()
		_music_fade.tween_property(_music_player, "volume_db", SHOP_MUSIC_SILENCE_DB, SHOP_MUSIC_FADE_OUT * 0.5)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_music_fade.tween_callback(func() -> void:
			_ensure_music_player(stream)
			_music_player.volume_db = SHOP_MUSIC_SILENCE_DB
			_music_player.play()
			_music_fade = create_tween()
			_music_fade.tween_property(_music_player, "volume_db", _music_volume_db, SHOP_MUSIC_FADE_IN)\
				.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		)
		return

	_ensure_music_player(stream)

	if not _music_player.playing:
		_music_player.volume_db = SHOP_MUSIC_SILENCE_DB
		_music_player.play()

	_music_fade = create_tween()
	_music_fade.tween_property(_music_player, "volume_db", _music_volume_db, SHOP_MUSIC_FADE_IN)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _start_shop_music() -> void:
	_start_interior_music(SHOP_MUSIC, SHOP_MUSIC_VOLUME_DB)


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
	_music_source = null


func _kill_music_fade() -> void:
	if _music_fade != null and _music_fade.is_valid():
		_music_fade.kill()
	_music_fade = null
