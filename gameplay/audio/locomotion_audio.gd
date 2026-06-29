extends Node
class_name LocomotionAudio

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const LOCO_FADE_IN := 0.1
const LOCO_FADE_OUT := 0.16
const LOCO_SILENCE_DB := -50.0
const NPC_VOLUME_OFFSET_DB := -6.0
const NPC_CULL_DISTANCE := 60.0
const NPC_CULL_DISTANCE_SQ := NPC_CULL_DISTANCE * NPC_CULL_DISTANCE

enum Kind { PLAYER, HORSE, NPC }
enum LocoMode { NONE, WALK, RUN }

var _owner: Node3D
var _kind := Kind.PLAYER
var _volume_offset_db := 0.0
var _proximity_cull := false
var _culled := false

var _loco_player: AudioStreamPlayer3D
var _walk_loop: AudioStream
var _run_loop: AudioStream
var _loco_fade: Tween
var _loco_mode := LocoMode.NONE
var _loco_audible := false


func setup(owner_node: Node3D, kind: Kind = Kind.PLAYER) -> void:
	_owner = owner_node
	_kind = kind
	_volume_offset_db = NPC_VOLUME_OFFSET_DB if kind == Kind.NPC else 0.0
	_proximity_cull = kind == Kind.NPC
	_ensure_loco_player()


func update(
	_delta: float,
	has_move_input: bool,
	sprinting: bool,
	horizontal_speed: float,
	on_floor: bool
) -> void:
	if _owner == null:
		return

	if _proximity_cull:
		if not _is_within_proximity():
			if not _culled:
				_fade_loco_out()
				_culled = true
			return
		_culled = false

	_ensure_loco_player()
	_loco_player.global_position = _owner.global_position

	var want_run := (
		has_move_input
		and on_floor
		and sprinting
		and horizontal_speed > 0.2
	)
	var want_walk := (
		has_move_input
		and on_floor
		and not sprinting
		and horizontal_speed > 0.05
	)

	if want_run:
		_set_loco_mode(LocoMode.RUN)
	elif want_walk:
		_set_loco_mode(LocoMode.WALK)
	elif not has_move_input:
		_fade_loco_out()


func _ensure_loco_player() -> void:
	if _loco_player != null:
		return

	if _kind == Kind.HORSE:
		_walk_loop = _make_looped(GameAudio.HORSE_WALK_FOOTSTEP)
		_run_loop = _make_looped(GameAudio.HORSE_RUN_FOOTSTEP)
	else:
		_walk_loop = _make_looped(GameAudio.WALK_FOOTSTEP)
		_run_loop = _make_looped(GameAudio.SPRINT_FOOTSTEP)

	_loco_player = AudioStreamPlayer3D.new()
	_loco_player.name = "LocoLoop"
	_loco_player.max_distance = 80.0
	_loco_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_loco_player.unit_size = 4.0
	_loco_player.volume_db = LOCO_SILENCE_DB
	add_child(_loco_player)


func _set_loco_mode(mode: LocoMode) -> void:
	if _loco_mode == mode and _loco_audible and _loco_player.playing:
		return

	var stream: AudioStream
	var target_db: float
	match mode:
		LocoMode.RUN:
			stream = _run_loop
			target_db = GameAudio.SPRINT_VOLUME_DB
		LocoMode.WALK:
			stream = _walk_loop
			target_db = 0.0
		_:
			return

	if _loco_player.stream != stream:
		_loco_player.stream = stream
		_loco_player.volume_db = LOCO_SILENCE_DB
		_loco_player.play()
	elif not _loco_player.playing:
		_loco_player.volume_db = LOCO_SILENCE_DB
		_loco_player.play()

	_loco_mode = mode
	_fade_loco_volume_to(target_db + _volume_offset_db, LOCO_FADE_IN)


func _fade_loco_out() -> void:
	if _loco_mode == LocoMode.NONE and not _loco_audible:
		return

	_loco_mode = LocoMode.NONE
	_fade_loco_volume_to(LOCO_SILENCE_DB, LOCO_FADE_OUT, true)


func _fade_loco_volume_to(target_db: float, duration: float, stop_after: bool = false) -> void:
	if _loco_fade != null and _loco_fade.is_valid():
		_loco_fade.kill()

	_loco_audible = target_db > LOCO_SILENCE_DB + 1.0
	_loco_fade = create_tween()
	_loco_fade.tween_property(_loco_player, "volume_db", target_db, duration)
	if stop_after:
		_loco_fade.tween_callback(_stop_loco_player)


func _stop_loco_player() -> void:
	if _loco_player.playing:
		_loco_player.stop()
	_loco_player.volume_db = LOCO_SILENCE_DB
	_loco_audible = false


func _is_within_proximity() -> bool:
	var viewport := _owner.get_viewport()
	if viewport == null:
		return true

	var camera := viewport.get_camera_3d()
	if camera == null:
		return true

	return (
		_owner.global_position.distance_squared_to(camera.global_position)
		<= NPC_CULL_DISTANCE_SQ
	)


func _make_looped(stream: AudioStream) -> AudioStream:
	var copy := stream.duplicate()
	if copy is AudioStreamWAV:
		(copy as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
	elif copy is AudioStreamMP3:
		(copy as AudioStreamMP3).loop = true
	elif copy is AudioStreamOggVorbis:
		(copy as AudioStreamOggVorbis).loop = true
	return copy
