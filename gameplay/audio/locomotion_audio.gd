extends Node
class_name LocomotionAudio

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const LOCO_FADE_IN := 0.1
const LOCO_FADE_OUT := 0.16
const LOCO_SILENCE_DB := -50.0
const NPC_VOLUME_OFFSET_DB := -6.0
const NPC_CULL_DISTANCE := 60.0
const NPC_CULL_DISTANCE_SQ := NPC_CULL_DISTANCE * NPC_CULL_DISTANCE
const PITCH_FADE := 0.1
const SURFACE_SWAP_FADE := 0.12

enum Kind { PLAYER, HORSE, NPC }
enum LocoMode { NONE, WALK, RUN }
enum FootSurface { DIRT, GRASS, WOOD }

var _owner: Node3D
var _kind := Kind.PLAYER
var _volume_offset_db := 0.0
var _proximity_cull := false
var _culled := false

var _loco_player: AudioStreamPlayer3D
var _walk_loop: AudioStream
var _run_loop: AudioStream
var _loco_fade: Tween
var _pitch_fade: Tween
var _loco_mode := LocoMode.NONE
var _loco_audible := false
var _foot_surface := FootSurface.DIRT
var _uses_pitch_sprint := false


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
	_update_foot_surface()
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
	elif not has_move_input or horizontal_speed <= 0.05:
		_fade_loco_out()


func _ensure_loco_player() -> void:
	if _loco_player != null:
		return

	if _kind == Kind.HORSE:
		_walk_loop = _make_looped(GameAudio.HORSE_WALK_FOOTSTEP)
		_run_loop = _make_looped(GameAudio.HORSE_RUN_FOOTSTEP)
	else:
		_foot_surface = _resolve_foot_surface()
		_refresh_foot_loops()

	_loco_player = AudioStreamPlayer3D.new()
	_loco_player.name = "LocoLoop"
	_loco_player.max_distance = 80.0
	_loco_player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
	_loco_player.unit_size = 4.0
	_loco_player.volume_db = LOCO_SILENCE_DB
	_loco_player.pitch_scale = 1.0
	add_child(_loco_player)


func _update_foot_surface() -> void:
	if _kind == Kind.HORSE:
		return

	var target_surface := _resolve_foot_surface()
	if target_surface == _foot_surface:
		return

	_foot_surface = target_surface
	_refresh_foot_loops()
	_loco_mode = LocoMode.NONE


func _resolve_foot_surface() -> FootSurface:
	if _kind == Kind.PLAYER and ShopSession.is_inside_shop():
		return FootSurface.WOOD
	if _kind == Kind.PLAYER and _is_on_terrain_ground():
		return FootSurface.GRASS
	return FootSurface.DIRT


func _is_on_terrain_ground() -> bool:
	var world := _owner.get_world_3d()
	if world == null:
		return false

	var space := world.direct_space_state
	var from := _owner.global_position + Vector3(0.0, 0.35, 0.0)
	var to := from + Vector3(0.0, -1.25, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_bodies = true
	query.collide_with_areas = false
	if _owner is CollisionObject3D:
		query.exclude = [(_owner as CollisionObject3D).get_rid()]

	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return false

	var node := hit.collider as Node
	while node != null:
		if node is Terrain3D:
			return true
		node = node.get_parent()
	return false


func _refresh_foot_loops() -> void:
	if _kind == Kind.HORSE:
		return

	_uses_pitch_sprint = _foot_surface in [FootSurface.GRASS, FootSurface.WOOD]
	match _foot_surface:
		FootSurface.WOOD:
			_walk_loop = _make_looped(GameAudio.WOOD_FOOTSTEP)
		FootSurface.GRASS:
			_walk_loop = _make_looped(GameAudio.GRASS_FOOTSTEP)
		_:
			_walk_loop = _make_looped(GameAudio.WALK_FOOTSTEP)
			_run_loop = _make_looped(GameAudio.SPRINT_FOOTSTEP)
			return

	_run_loop = _walk_loop


func _set_loco_mode(mode: LocoMode) -> void:
	var stream: AudioStream
	var target_db: float
	var target_pitch := 1.0

	match mode:
		LocoMode.RUN:
			stream = _walk_loop if _uses_pitch_sprint else _run_loop
			target_db = GameAudio.SPRINT_VOLUME_DB
			if _uses_pitch_sprint:
				target_pitch = GameAudio.FOOTSTEP_SPRINT_PITCH
		LocoMode.WALK:
			stream = _walk_loop
			target_db = 0.0
		_:
			return

	if (
		_loco_mode == mode
		and _loco_audible
		and _loco_player.playing
		and _loco_player.stream == stream
		and (
			not _uses_pitch_sprint
			or is_equal_approx(_loco_player.pitch_scale, target_pitch)
		)
	):
		return

	var stream_changed := _loco_player.stream != stream
	if stream_changed:
		_kill_pitch_fade()
		_loco_player.pitch_scale = 1.0
		_loco_player.stream = stream
		_loco_player.volume_db = LOCO_SILENCE_DB
		if not _loco_player.playing:
			_loco_player.play()
	elif not _loco_player.playing:
		_loco_player.volume_db = LOCO_SILENCE_DB
		_loco_player.play()

	_loco_mode = mode
	if _uses_pitch_sprint:
		_fade_pitch_to(target_pitch)
	elif not is_equal_approx(_loco_player.pitch_scale, 1.0):
		_fade_pitch_to(1.0)

	var fade_duration := SURFACE_SWAP_FADE if stream_changed else LOCO_FADE_IN
	_fade_loco_volume_to(target_db + _volume_offset_db, fade_duration)


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
	_loco_fade.tween_property(_loco_player, "volume_db", target_db, duration)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	if stop_after:
		_loco_fade.tween_callback(_stop_loco_player)


func _fade_pitch_to(target_pitch: float) -> void:
	if _loco_player == null:
		return
	if is_equal_approx(_loco_player.pitch_scale, target_pitch):
		return

	_kill_pitch_fade()
	_pitch_fade = create_tween()
	_pitch_fade.tween_property(_loco_player, "pitch_scale", target_pitch, PITCH_FADE)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func _kill_pitch_fade() -> void:
	if _pitch_fade != null and _pitch_fade.is_valid():
		_pitch_fade.kill()
	_pitch_fade = null


func _stop_loco_player() -> void:
	_kill_pitch_fade()
	if _loco_player.playing:
		_loco_player.stop()
	_loco_player.volume_db = LOCO_SILENCE_DB
	_loco_player.pitch_scale = 1.0
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
