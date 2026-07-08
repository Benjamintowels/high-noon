extends GroypetteNpc
class_name GroypetteAmbushCaptive

enum CaptiveState {
	HARASSED,
	WARNED,
	FLEEING,
	THANKING,
	ESCORTING,
	WALKING_AWAY,
	ARRIVED_HOME,
}

const SCARED_VOICE_INTERVAL := 3.0
const IDLE_PAUSE_MIN := 2.5
const IDLE_PAUSE_MAX := 5.0
const RUN_SEGMENT_MIN := 0.7
const RUN_SEGMENT_MAX := 1.3
const ARRIVE_DISTANCE := 1.1
const THANK_APPROACH_DISTANCE := 2.0
const ESCORT_RUN_SPEED_SCALE := 1.3

var _captive_state := CaptiveState.HARASSED
var _bandit_spots: Array[Vector3] = []
var _bandit_spot_index := 0
var _run_timer := 0.0
var _idle_pause_timer := 0.0
var _scared_voice_timer := SCARED_VOICE_INTERVAL
var _escort_markers: Array[Marker3D] = []
var _escort_marker_index := 0
var _player_ref: Node3D
var _on_escort_finished: Callable = Callable()


func configure_ambush_captive(bandits: Array[GroyperBanditNpc], center: Vector3) -> void:
	global_position = center
	snap_to_floor()
	_bandit_spots.clear()
	for bandit in bandits:
		if is_instance_valid(bandit):
			_bandit_spots.append(bandit.global_position)
	if _bandit_spots.is_empty():
		_bandit_spots.append(center)
	_bandit_spot_index = 0
	_captive_state = CaptiveState.HARASSED
	_scared_voice_timer = SCARED_VOICE_INTERVAL
	_run_timer = 0.0
	_idle_pause_timer = randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)


func resume_harassment() -> void:
	if _defeated:
		return
	_captive_state = CaptiveState.HARASSED
	_velocity_zero()
	_scared_voice_timer = SCARED_VOICE_INTERVAL
	_run_timer = 0.0
	_idle_pause_timer = randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)


func begin_thank_player(player: Node3D, on_finished: Callable = Callable()) -> void:
	if _defeated:
		if on_finished.is_valid():
			on_finished.call()
		return
	_player_ref = player
	_on_escort_finished = on_finished
	_captive_state = CaptiveState.THANKING
	_velocity_zero()


func begin_walk_away() -> void:
	_captive_state = CaptiveState.WALKING_AWAY
	if _player_ref != null and is_instance_valid(_player_ref):
		var away := global_position - _player_ref.global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			_walk_direction = away.normalized()
		else:
			_walk_direction = Vector3.BACK
	_run_timer = 4.0


func begin_escort_home(markers: Array[Marker3D]) -> void:
	_escort_markers = markers.duplicate()
	_sort_escort_markers_by_distance()
	_escort_marker_index = 0
	_captive_state = CaptiveState.ESCORTING
	_velocity_zero()


func _sort_escort_markers_by_distance() -> void:
	if _escort_markers.is_empty():
		return
	_escort_markers.sort_custom(
		func(a: Marker3D, b: Marker3D) -> bool:
			if a == null or not is_instance_valid(a):
				return false
			if b == null or not is_instance_valid(b):
				return true
			var dist_a := global_position.distance_squared_to(a.global_position)
			var dist_b := global_position.distance_squared_to(b.global_position)
			return dist_a < dist_b
	)


func play_flirty_line() -> void:
	_play_flirty_voice()


func play_cute_line() -> void:
	_play_voice(GroypetteAudio.pick_cute_voice(), 0.04)


func _physics_process(delta: float) -> void:
	if _defeated:
		super._physics_process(delta)
		return

	match _captive_state:
		CaptiveState.HARASSED:
			_process_harassed(delta)
		CaptiveState.THANKING:
			_process_thanking(delta)
		CaptiveState.ESCORTING:
			_process_escorting(delta)
		CaptiveState.WALKING_AWAY:
			_process_walking_away(delta)
		CaptiveState.ARRIVED_HOME:
			velocity.x = 0.0
			velocity.z = 0.0
			move_and_slide()
			update_npc_locomotion_audio(delta, 0.0, false, false)
			return
		_:
			super._physics_process(delta)
			return

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	move_and_slide()
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	_update_locomotion_blend(delta, horizontal_speed, horizontal_speed > 2.5)
	update_npc_locomotion_audio(delta, horizontal_speed, horizontal_speed > 0.05, horizontal_speed > 2.5)


func _process_harassed(delta: float) -> void:
	_scared_voice_timer -= delta
	if _scared_voice_timer <= 0.0:
		_scared_voice_timer = SCARED_VOICE_INTERVAL
		_play_voice(GroypetteAudio.pick_scared_voice(), 0.06)

	if _idle_pause_timer > 0.0:
		_idle_pause_timer -= delta
		velocity.x = 0.0
		velocity.z = 0.0
		return

	if _run_timer <= 0.0:
		_run_timer = randf_range(RUN_SEGMENT_MIN, RUN_SEGMENT_MAX)

	_run_timer -= delta
	if _run_timer > 0.0 and not _bandit_spots.is_empty():
		var target := _bandit_spots[_bandit_spot_index]
		var to_target := target - global_position
		to_target.y = 0.0
		if to_target.length_squared() > ARRIVE_DISTANCE * ARRIVE_DISTANCE:
			var move_dir := to_target.normalized()
			velocity.x = move_dir.x * RUN_SPEED
			velocity.z = move_dir.z * RUN_SPEED
			_face_position(global_position + move_dir, delta)
			return
		_bandit_spot_index = (_bandit_spot_index + 1) % _bandit_spots.size()
		_run_timer = 0.0
		_idle_pause_timer = randf_range(IDLE_PAUSE_MIN, IDLE_PAUSE_MAX)

	velocity.x = 0.0
	velocity.z = 0.0


func _process_thanking(delta: float) -> void:
	if _player_ref == null or not is_instance_valid(_player_ref):
		_captive_state = CaptiveState.ARRIVED_HOME
		return

	var to_player := _player_ref.global_position - global_position
	to_player.y = 0.0
	if to_player.length_squared() > THANK_APPROACH_DISTANCE * THANK_APPROACH_DISTANCE:
		var move_dir := to_player.normalized()
		velocity.x = move_dir.x * RUN_SPEED * 0.65
		velocity.z = move_dir.z * RUN_SPEED * 0.65
		_face_position(global_position + move_dir, delta)
	else:
		velocity.x = 0.0
		velocity.z = 0.0
		_face_position(_player_ref.global_position, delta)


func _process_escorting(delta: float) -> void:
	if _escort_markers.is_empty():
		_finish_escort()
		return
	if _escort_marker_index >= _escort_markers.size():
		_finish_escort()
		return

	var marker := _escort_markers[_escort_marker_index]
	if marker == null or not is_instance_valid(marker):
		_escort_marker_index += 1
		return

	var to_marker := marker.global_position - global_position
	to_marker.y = 0.0
	if to_marker.length_squared() <= ARRIVE_DISTANCE * ARRIVE_DISTANCE:
		_escort_marker_index += 1
		if _escort_marker_index >= _escort_markers.size():
			_finish_escort()
		return

	var move_dir := to_marker.normalized()
	var escort_speed := RUN_SPEED * ESCORT_RUN_SPEED_SCALE
	velocity.x = move_dir.x * escort_speed
	velocity.z = move_dir.z * escort_speed
	_face_position(global_position + move_dir, delta)


func _process_walking_away(delta: float) -> void:
	_run_timer -= delta
	velocity.x = _walk_direction.x * WALK_SPEED
	velocity.z = _walk_direction.z * WALK_SPEED
	_face_position(global_position + _walk_direction, delta)
	if _run_timer <= 0.0:
		_captive_state = CaptiveState.ARRIVED_HOME
		_velocity_zero()
		if _on_escort_finished.is_valid():
			_on_escort_finished.call()


func _finish_escort() -> void:
	_captive_state = CaptiveState.ARRIVED_HOME
	_velocity_zero()
	_begin_idle()


func _velocity_zero() -> void:
	velocity.x = 0.0
	velocity.z = 0.0


func is_captive_alive() -> bool:
	return not _defeated


func get_interact_hint() -> String:
	if _captive_state == CaptiveState.ARRIVED_HOME:
		return "Talk"
	return super.get_interact_hint()
