extends Node3D
class_name GroundBird

const BirdFramesScript := preload("res://characters/animals/bird_frames.gd")
const BirdFacingScript := preload("res://characters/animals/bird_facing.gd")
const BirdFeatherBurstFX := preload("res://characters/animals/bird_feather_burst_fx.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

enum AiState { IDLE, TURN, HOP, FLEE_UP, FLEE_CIRCLE, FLEE_DOWN }

const PROXIMITY_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
	&"town_groyper",
	&"town_fast",
	&"town_sheriff",
]

const PROXIMITY_CHECK_INTERVAL := 0.15
const HOP_SPEED := 1.35
const HOP_ARC_HEIGHT := 0.11
const HOP_DURATION := 0.28
const HOP_DISTANCE_MIN := 0.14
const HOP_DISTANCE_MAX := 0.52
const IDLE_DURATION_MIN := 5.5
const IDLE_DURATION_MAX := 11.0
const FLEE_RISE_DURATION_MIN := 2.75
const FLEE_RISE_DURATION_MAX := 4.25
const FLEE_AIR_TIME_MIN := 14.0
const FLEE_AIR_TIME_MAX := 22.0
const FLEE_ALTITUDE_MIN := 16.0
const FLEE_ALTITUDE_MAX := 26.0
const FLEE_CIRCLE_RADIUS_MIN := 6.0
const FLEE_CIRCLE_RADIUS_MAX := 14.0
const FLEE_CIRCLE_SPEED_MIN := 0.18
const FLEE_CIRCLE_SPEED_MAX := 0.38
const FLEE_DESCENT_DURATION_MIN := 1.35
const FLEE_DESCENT_DURATION_MAX := 1.85
const FLEE_TAKEOFF_DRIFT_MAX := 0.75
const FLEE_GROUND_HOLD_DURATION := 0.25
const FLEE_GROUND_FLAP_SPEED := 1.65
const FLEE_GROUND_SKIM_SPEED := 1.05
const FLEE_GROUND_BOB_HEIGHT := 0.05
const FLEE_SPEED_START := 0.72
const FLEE_SPEED_RAMP_DURATION := 2.25
const SCARE_COOLDOWN := 0.35

@export var personality_seed := -1
@export var roam_center := Vector3.ZERO
@export var roam_radius := 3.5
@export var proximity_flee_radius := 3.75
@export var ground_height := 0.0
@export var pixel_size := 0.005
## Ground idle PNGs are much smaller than flight atlas frames; bump this to match.
@export var idle_pixel_scale := 2.35
@export var flight_pixel_scale := 1.5

@onready var _sprite: AnimatedSprite3D = $Sprite

var _ai_state := AiState.IDLE
var _state_timer := 0.0
var _rng := RandomNumberGenerator.new()
var _facing := BirdFacingScript.Facing.FRONT
var _flip_h := false
var _ground_position := Vector3.ZERO
var _hop_start := Vector3.ZERO
var _hop_end := Vector3.ZERO
var _hop_elapsed := 0.0
var _hops_remaining := 0
var _flee_direction := Vector3.ZERO
var _flee_rise_duration := 0.0
var _flee_rise_elapsed := 0.0
var _air_time_remaining := 0.0
var _circle_center := Vector3.ZERO
var _circle_radius := 0.0
var _circle_angle := 0.0
var _circle_angular_speed := 0.0
var _circle_max_angular_speed := 0.0
var _circle_base_altitude := 0.0
var _circle_altitude_wobble := 0.0
var _flight_elapsed := 0.0
var _landing_point := Vector3.ZERO
var _descent_duration := 0.0
var _descent_start := Vector3.ZERO
var _proximity_timer := 0.0
var _scare_cooldown := 0.0
var _dead := false
var _flight_facing_hold := 0.0

const FLIGHT_FACING_HOLD := 0.16


func _ready() -> void:
	add_to_group("ground_bird")
	add_to_group("duel_target")
	if personality_seed >= 0:
		_rng.seed = personality_seed
	else:
		_rng.randomize()

	if roam_center == Vector3.ZERO:
		roam_center = global_position

	ground_height = global_position.y
	_ground_position = global_position
	_pick_random_facing()

	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sprite.scale = Vector3.ONE
	_sprite.offset = Vector2(0.0, -6.0)

	_apply_idle_visual()
	_begin_idle()


func _process(delta: float) -> void:
	if _dead:
		return
	_scare_cooldown = maxf(_scare_cooldown - delta, 0.0)
	_proximity_timer -= delta

	if _proximity_timer <= 0.0 and _ai_state <= AiState.HOP:
		_proximity_timer = PROXIMITY_CHECK_INTERVAL
		_check_proximity_threats()

	match _ai_state:
		AiState.IDLE:
			_process_idle(delta)
		AiState.TURN:
			_process_turn(delta)
		AiState.HOP:
			_process_hop(delta)
		AiState.FLEE_UP:
			_process_flee_up(delta)
		AiState.FLEE_CIRCLE:
			_process_flee_circle(delta)
		AiState.FLEE_DOWN:
			_process_flee_down(delta)


func scare_from(threat_position: Vector3) -> void:
	if _dead:
		return
	if _scare_cooldown > 0.0:
		return
	_scare_cooldown = SCARE_COOLDOWN

	if _ai_state >= AiState.FLEE_UP:
		_flee_direction = BirdFacingScript.flee_direction(threat_position, global_position)
		return

	_begin_flee(threat_position)


func _check_proximity_threats() -> void:
	var radius_sq := proximity_flee_radius * proximity_flee_radius
	for group_name in PROXIMITY_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node) or not node is Node3D:
				continue
			var actor := node as Node3D
			if actor.global_position.distance_squared_to(global_position) <= radius_sq:
				_begin_flee(actor.global_position)
				return


func _process_idle(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_pick_next_ground_behavior()


func _process_turn(delta: float) -> void:
	_state_timer -= delta
	if _state_timer <= 0.0:
		_begin_idle()


func _process_hop(delta: float) -> void:
	_hop_elapsed += delta
	var t := clampf(_hop_elapsed / HOP_DURATION, 0.0, 1.0)
	var eased := t * t * (3.0 - 2.0 * t)
	var flat_pos := _hop_start.lerp(_hop_end, eased)
	flat_pos.y = ground_height + sin(t * PI) * HOP_ARC_HEIGHT
	global_position = flat_pos

	var move_dir := _hop_end - _hop_start
	move_dir.y = 0.0
	if move_dir.length_squared() > 0.0001:
		_update_facing_from_direction(move_dir)

	if t >= 1.0:
		_ground_position = Vector3(_hop_end.x, ground_height, _hop_end.z)
		global_position = _ground_position
		if _hops_remaining > 0:
			_start_next_hop()
		else:
			_begin_idle()


func _process_flee_up(delta: float) -> void:
	_flee_rise_elapsed += delta
	_air_time_remaining -= delta
	_flight_elapsed += delta

	if _air_time_remaining <= 0.0:
		_begin_flee_down()
		return

	if _flight_elapsed < FLEE_GROUND_HOLD_DURATION:
		var pos := global_position
		pos.y = ground_height + sin(_flight_elapsed * 20.0) * FLEE_GROUND_BOB_HEIGHT
		pos.x += _flee_direction.x * FLEE_GROUND_SKIM_SPEED * delta
		pos.z += _flee_direction.z * FLEE_GROUND_SKIM_SPEED * delta
		global_position = pos
		_update_flight_visuals(_flee_direction, 0.0, FLEE_GROUND_FLAP_SPEED, delta)
		return

	var climb_elapsed := _flight_elapsed - FLEE_GROUND_HOLD_DURATION
	var speed_scale := _flight_speed_scale()
	var rise_t := clampf(climb_elapsed / _flee_rise_duration, 0.0, 1.0)
	var vertical_progress := _smoothstep(rise_t) * lerpf(0.82, 1.0, speed_scale)
	var pos := global_position
	pos.y = lerpf(ground_height, _circle_base_altitude, clampf(vertical_progress, 0.0, 1.0))
	pos.x += _flee_direction.x * FLEE_TAKEOFF_DRIFT_MAX * speed_scale * delta
	pos.z += _flee_direction.z * FLEE_TAKEOFF_DRIFT_MAX * speed_scale * delta
	global_position = pos
	_update_flight_visuals(_flee_direction, speed_scale, -1.0, delta)

	if vertical_progress >= 0.98 or climb_elapsed >= _flee_rise_duration:
		_begin_flee_circle()


func _process_flee_circle(delta: float) -> void:
	_air_time_remaining -= delta
	_flight_elapsed += delta
	var speed_scale := _flight_speed_scale()
	_circle_angle += _circle_max_angular_speed * speed_scale * delta

	var orbit_offset := Vector3(
		cos(_circle_angle) * _circle_radius,
		0.0,
		sin(_circle_angle) * _circle_radius
	)
	var target_pos := _circle_center + orbit_offset
	var target_y := _circle_base_altitude + sin(_circle_angle * 2.1 + _circle_radius) * _circle_altitude_wobble
	var pos := target_pos
	pos.y = lerpf(global_position.y, target_y, minf(3.5 * delta, 1.0))
	global_position = pos

	var tangent := Vector3(
		-sin(_circle_angle) * signf(_circle_angular_speed),
		0.0,
		cos(_circle_angle) * signf(_circle_angular_speed)
	)
	_update_flight_visuals(tangent, speed_scale, -1.0, delta)

	if _air_time_remaining <= 0.0:
		_begin_flee_down()


func _process_flee_down(delta: float) -> void:
	_flee_rise_elapsed += delta
	_flight_facing_hold = maxf(_flight_facing_hold - delta, 0.0)
	var fall_t := clampf(_flee_rise_elapsed / _descent_duration, 0.0, 1.0)
	var eased := _ease_in(fall_t)
	var speed_scale := lerpf(FLEE_SPEED_START, 0.85, eased)

	var pos := _descent_start.lerp(_landing_point, eased)
	pos.y = lerpf(_descent_start.y, ground_height, eased)
	global_position = pos

	var move_dir := _landing_point - global_position
	move_dir.y = 0.0
	if move_dir.length_squared() > 0.01:
		_update_flight_visuals(move_dir, speed_scale, -1.0, delta)
	else:
		_update_flight_visuals(_flee_direction, speed_scale, -1.0, delta)

	if fall_t >= 1.0:
		_ground_position = Vector3(_landing_point.x, ground_height, _landing_point.z)
		global_position = _ground_position
		roam_center = _ground_position
		_apply_idle_visual()
		_begin_idle()


func _pick_next_ground_behavior() -> void:
	var roll := _rng.randf()
	if roll < 0.22:
		_begin_hop()
	elif roll < 0.38:
		_begin_turn()
	else:
		_begin_idle()


func _begin_idle() -> void:
	_ai_state = AiState.IDLE
	_state_timer = _rng.randf_range(IDLE_DURATION_MIN, IDLE_DURATION_MAX)
	_apply_idle_visual()


func _begin_turn() -> void:
	_ai_state = AiState.TURN
	_state_timer = _rng.randf_range(0.3, 0.65)
	_pick_random_facing()
	_apply_idle_visual()


func _begin_hop() -> void:
	_ai_state = AiState.HOP
	_hops_remaining = _rng.randi_range(1, 2)
	_start_next_hop()


func _start_next_hop() -> void:
	if _hops_remaining <= 0:
		_begin_idle()
		return

	_hops_remaining -= 1
	_hop_start = Vector3(_ground_position.x, ground_height, _ground_position.z)
	_hop_end = _pick_hop_point()

	if _hop_start.distance_to(_hop_end) < HOP_DISTANCE_MIN * 0.75:
		if _hops_remaining > 0:
			_start_next_hop()
		else:
			_begin_idle()
		return

	_hop_elapsed = 0.0
	global_position = _hop_start
	_apply_idle_visual()


func _begin_flee(threat_position: Vector3) -> void:
	_flee_direction = BirdFacingScript.flee_direction(threat_position, global_position)
	_circle_base_altitude = ground_height + _rng.randf_range(FLEE_ALTITUDE_MIN, FLEE_ALTITUDE_MAX)
	_circle_center = Vector3(_ground_position.x, 0.0, _ground_position.z)
	_circle_center += _flee_direction * _rng.randf_range(4.0, 11.0)
	_circle_radius = _rng.randf_range(FLEE_CIRCLE_RADIUS_MIN, FLEE_CIRCLE_RADIUS_MAX)
	_circle_angle = _rng.randf_range(0.0, TAU)
	_circle_max_angular_speed = _rng.randf_range(FLEE_CIRCLE_SPEED_MIN, FLEE_CIRCLE_SPEED_MAX)
	_circle_angular_speed = _circle_max_angular_speed
	if _rng.randf() < 0.5:
		_circle_angular_speed *= -1.0
		_circle_max_angular_speed *= -1.0
	_circle_altitude_wobble = _rng.randf_range(0.8, 2.4)
	_air_time_remaining = _rng.randf_range(FLEE_AIR_TIME_MIN, FLEE_AIR_TIME_MAX)
	_flee_rise_duration = _rng.randf_range(FLEE_RISE_DURATION_MIN, FLEE_RISE_DURATION_MAX)
	_flee_rise_elapsed = 0.0
	_flight_elapsed = 0.0
	_flight_facing_hold = 0.0
	_update_facing_from_direction(_flee_direction)

	GameAudio.play_bird_flap(self, global_position)

	_ai_state = AiState.FLEE_UP
	_update_flight_visuals(_flee_direction, 0.0, FLEE_GROUND_FLAP_SPEED, 0.0)


func _begin_flee_circle() -> void:
	var offset := global_position - _circle_center
	offset.y = 0.0
	var dist := offset.length()
	if dist > 0.35:
		_circle_radius = clampf(dist, FLEE_CIRCLE_RADIUS_MIN, FLEE_CIRCLE_RADIUS_MAX)
		_circle_angle = atan2(offset.z, offset.x)
	_ai_state = AiState.FLEE_CIRCLE


func _begin_flee_down() -> void:
	_landing_point = _pick_ground_landing_point()
	_descent_start = global_position
	_descent_duration = _rng.randf_range(FLEE_DESCENT_DURATION_MIN, FLEE_DESCENT_DURATION_MAX)
	_flee_rise_elapsed = 0.0
	_ai_state = AiState.FLEE_DOWN


func is_defeated() -> bool:
	return _dead


func get_bullet_capsule() -> Dictionary:
	var center := global_position + Vector3(0.0, 0.18, 0.0)
	return {
		"center": center,
		"half_height": 0.1,
		"radius": 0.24,
		"axis": Vector3.UP,
	}


func receive_bullet_hit(hit_info: Dictionary) -> void:
	apply_bullet_hit(hit_info)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _dead:
		return
	_die_from_hit(hit_info)


func _die_from_hit(hit_info: Dictionary) -> void:
	_dead = true
	set_process(false)
	remove_from_group("ground_bird")
	remove_from_group("duel_target")

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var direction: Vector3 = hit_info.get("direction", Vector3.UP)

	var fx_parent := get_tree().current_scene
	if fx_parent == null:
		fx_parent = get_parent()
	BirdFeatherBurstFX.spawn(fx_parent, hit_position, direction)
	GameAudio.play_bird_death(self, hit_position)
	queue_free()


func _pick_roam_point() -> Vector3:
	var offset := Vector3(
		_rng.randf_range(-roam_radius, roam_radius),
		0.0,
		_rng.randf_range(-roam_radius, roam_radius)
	)
	var point := roam_center + offset
	point.y = ground_height
	return point


func _pick_hop_point() -> Vector3:
	for _attempt in 8:
		var angle := _rng.randf_range(0.0, TAU)
		var dist := _rng.randf_range(HOP_DISTANCE_MIN, HOP_DISTANCE_MAX)
		var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		var candidate := _ground_position + offset
		candidate.y = ground_height

		var to_center := candidate - roam_center
		to_center.y = 0.0
		if to_center.length() <= roam_radius:
			return candidate

	return _pick_short_hop_fallback()


func _pick_short_hop_fallback() -> Vector3:
	var angle := _rng.randf_range(0.0, TAU)
	var dist := _rng.randf_range(HOP_DISTANCE_MIN, HOP_DISTANCE_MAX * 0.85)
	var offset := Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	var candidate := _ground_position + offset
	candidate.y = ground_height
	return candidate


func _pick_ground_landing_point() -> Vector3:
	for _attempt in 8:
		var candidate := _pick_roam_point()
		candidate.y = ground_height
		if candidate.distance_to(_ground_position) >= 1.2:
			return candidate
	var fallback := _pick_roam_point()
	fallback.y = ground_height
	return fallback


func _update_facing_from_direction(direction: Vector3) -> void:
	var camera := get_viewport().get_camera_3d()
	var facing_info: Dictionary = BirdFacingScript.classify(direction, camera)
	_facing = facing_info["facing"]
	_flip_h = facing_info["flip_h"]


func _update_flight_facing_from_direction(direction: Vector3, delta: float) -> bool:
	_flight_facing_hold = maxf(_flight_facing_hold - delta, 0.0)
	if direction.length_squared() < 0.0001:
		return false

	var camera := get_viewport().get_camera_3d()
	var facing_info: Dictionary = BirdFacingScript.classify(direction, camera)
	var next_facing: BirdFacingScript.Facing = facing_info["facing"]
	var next_flip: bool = facing_info["flip_h"]
	if next_facing == _facing and next_flip == _flip_h:
		return false
	if _flight_facing_hold > 0.0:
		return false

	_facing = next_facing
	_flip_h = next_flip
	_flight_facing_hold = FLIGHT_FACING_HOLD
	return true


func _apply_idle_visual() -> void:
	_sprite.speed_scale = 1.0
	_sprite.pixel_size = pixel_size * idle_pixel_scale
	_sprite.sprite_frames = BirdFramesScript.idle_frames(_facing)
	_sprite.animation = BirdFramesScript.IDLE_ANIM
	_sprite.flip_h = _flip_h
	_sprite.play()


func _apply_flight_visual(force_refresh: bool = false) -> void:
	_sprite.pixel_size = pixel_size * flight_pixel_scale
	_sprite.flip_h = _flip_h
	var frames := BirdFramesScript.flight_frames(_facing)
	if (
		force_refresh
		or _sprite.sprite_frames != frames
		or _sprite.animation != BirdFramesScript.FLAP_ANIM
	):
		_sprite.sprite_frames = frames
		_sprite.animation = BirdFramesScript.FLAP_ANIM
		_sprite.play()


func _update_flight_visuals(
	move_direction: Vector3,
	speed_scale: float,
	flap_speed_override: float = -1.0,
	delta: float = 0.0
) -> void:
	var facing_changed := _update_flight_facing_from_direction(move_direction, delta)
	if flap_speed_override > 0.0:
		_sprite.speed_scale = flap_speed_override
	else:
		_sprite.speed_scale = lerpf(0.88, 1.0, speed_scale)
	_apply_flight_visual(facing_changed or flap_speed_override > 0.0)


func _flight_speed_scale() -> float:
	var ramp_elapsed := maxf(_flight_elapsed - FLEE_GROUND_HOLD_DURATION, 0.0)
	var ramp_t := clampf(ramp_elapsed / FLEE_SPEED_RAMP_DURATION, 0.0, 1.0)
	var eased := ramp_t * ramp_t * (3.0 - 2.0 * ramp_t)
	return lerpf(FLEE_SPEED_START, 1.0, eased)


func _pick_random_facing() -> void:
	match _rng.randi_range(0, 3):
		0:
			_facing = BirdFacingScript.Facing.FRONT
			_flip_h = false
		1:
			_facing = BirdFacingScript.Facing.BACK
			_flip_h = false
		2:
			_facing = BirdFacingScript.Facing.RIGHT
			_flip_h = false
		3:
			_facing = BirdFacingScript.Facing.RIGHT
			_flip_h = true


func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 2.0)


func _ease_in(t: float) -> float:
	return pow(clampf(t, 0.0, 1.0), 2.0)


func _smoothstep(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)
