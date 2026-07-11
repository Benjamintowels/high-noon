extends Node

## Drives outdoor day/night by rotating the scene sun and tinting its light.
## The desert sky shader reads LIGHT0_DIRECTION from the same DirectionalLight3D.

signal cycle_progress_changed(progress: float)

const FULL_CYCLE_SECONDS := 600.0
const MORNING_START_HOURS := 7.5  # 7:30 AM
const NIGHT_START_HOURS := 18.0   # 6:00 PM
## Rotating a shadow-casting DirectionalLight forces the whole 4-split shadow
## map to re-render, so the sun moves in discrete steps (~0.3° each) instead
## of every frame — shadows can be cached between steps.
const SUN_UPDATE_INTERVAL := 0.5

var cycle_progress := 0.0
var _session_started := false
var _active_sun: DirectionalLight3D
var _base_sun_energy := 1.35
var _base_sun_color := Color(1.0, 0.94, 0.82)
var _sun_update_accum := 0.0


func _process(delta: float) -> void:
	if _active_sun == null:
		return
	_sun_update_accum += GameTime.process_delta(delta)
	if _sun_update_accum < SUN_UPDATE_INTERVAL:
		return
	cycle_progress = fmod(
		cycle_progress + _sun_update_accum / FULL_CYCLE_SECONDS,
		1.0
	)
	_sun_update_accum = 0.0
	_apply_to_sun(_active_sun)
	cycle_progress_changed.emit(cycle_progress)


func bind_outdoor_scene(sun: DirectionalLight3D) -> void:
	_ensure_random_start()
	_active_sun = sun
	_base_sun_energy = sun.light_energy
	_base_sun_color = sun.light_color
	sun.position = Vector3.ZERO
	sun.rotation = Vector3.ZERO
	sun.rotation_order = EULER_ORDER_ZXY
	_apply_to_sun(sun)


func unbind_outdoor_scene(sun: DirectionalLight3D) -> void:
	if _active_sun == sun:
		_active_sun = null


func get_time_of_day_hours() -> float:
	return cycle_progress * 24.0


func is_morning_time() -> bool:
	var hours := get_time_of_day_hours()
	return hours >= MORNING_START_HOURS and hours < NIGHT_START_HOURS


func is_night_time() -> bool:
	return not is_morning_time()


func set_cycle_progress(progress: float) -> void:
	cycle_progress = fmod(progress, 1.0)
	if cycle_progress < 0.0:
		cycle_progress += 1.0
	if _active_sun != null:
		_apply_to_sun(_active_sun)
	cycle_progress_changed.emit(cycle_progress)


func get_sun_height() -> float:
	var sun_angle := (cycle_progress * 2.0 - 0.5) * -PI
	return cos(sun_angle)


func get_night_factor() -> float:
	return 1.0 - smoothstep(-0.15, 0.1, get_sun_height())


## Outdoor lamps turn on at 6:00 PM and off at 7:30 AM.
func should_outdoor_lights_be_on(_currently_on: bool) -> bool:
	return is_night_time()


func is_outdoor_night() -> bool:
	return _active_sun != null and is_night_time()


func _ensure_random_start() -> void:
	if _session_started:
		return
	cycle_progress = randf()
	_session_started = true


func _apply_to_sun(sun: DirectionalLight3D) -> void:
	sun.rotation_order = EULER_ORDER_ZXY
	sun.rotation.x = (cycle_progress * 2.0 - 0.5) * -PI

	var sun_direction := sun.to_global(Vector3(0.0, 0.0, 1.0)).normalized()
	var sun_height := sun_direction.y

	var energy_factor := smoothstep(-0.05, 0.35, sun_height)
	sun.light_energy = energy_factor * _base_sun_energy

	var sunset_factor := 1.0 - smoothstep(0.0, 0.25, abs(sun_height))
	var night_factor := 1.0 - smoothstep(-0.15, 0.1, sun_height)

	var day_color := _base_sun_color
	var sunset_color := Color(1.0, 0.55, 0.25)
	var night_color := Color(0.45, 0.55, 0.85)

	var tinted := day_color.lerp(sunset_color, sunset_factor * 0.85)
	tinted = tinted.lerp(night_color, night_factor * 0.7)
	sun.light_color = tinted
