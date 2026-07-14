extends Node

## Discrete outdoor day/night phases. The sun snaps once per phase and holds
## until the next area-transition advance — no continuous shadow-map rebuilds.
## Gate cinematics may briefly tween between phases for a sky-shift effect.

signal cycle_progress_changed(progress: float)
signal phase_changed(phase: int)

enum Phase {
	MORNING,
	DAY,
	SUNSET,
	NIGHT,
}

const PHASE_COUNT := 4

## Fixed cycle_progress values chosen for sun height / tint (not clock hours).
const PHASE_PROGRESS := {
	Phase.MORNING: 0.18,
	Phase.DAY: 0.28,
	Phase.SUNSET: 0.48,
	Phase.NIGHT: 0.70,
}

const PHASE_NAMES := {
	Phase.MORNING: "Dawn",
	Phase.DAY: "Day",
	Phase.SUNSET: "Dusk",
	Phase.NIGHT: "Night",
}

var current_phase: int = Phase.MORNING
var cycle_progress := 0.18
var _session_started := false
var _active_sun: DirectionalLight3D
var _base_sun_energy := 1.35
var _base_sun_color := Color(1.0, 0.94, 0.82)
var _phase_tween: Tween


func _ready() -> void:
	set_process(false)


func bind_outdoor_scene(sun: DirectionalLight3D) -> void:
	_ensure_session_start()
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


## Instant snap to the next phase (use while the screen is black).
func advance_phase() -> void:
	_ensure_session_start()
	set_phase((current_phase + 1) % PHASE_COUNT)


## Tween sun/sky from the current phase to the next over duration seconds.
## Logic phase flips immediately; visuals lerp (forward-wrapping Night→Morning).
func advance_phase_tweened(duration: float) -> void:
	_ensure_session_start()
	_kill_phase_tween()

	var next := (current_phase + 1) % PHASE_COUNT
	var from := cycle_progress
	var to := float(PHASE_PROGRESS[next])
	# Always travel forward in progress space so Night→Morning rises into dawn.
	if to <= from:
		to += 1.0

	var phase_did_change := next != current_phase
	current_phase = next
	if phase_did_change:
		phase_changed.emit(current_phase)

	if duration <= 0.0:
		_set_cycle_progress_visual(to)
		return

	_phase_tween = create_tween()
	_phase_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_phase_tween.tween_method(_set_cycle_progress_visual, from, to, duration)


func set_phase(phase: int) -> void:
	_ensure_session_start()
	_kill_phase_tween()
	var wrapped := posmod(phase, PHASE_COUNT)
	var phase_did_change := wrapped != current_phase
	current_phase = wrapped
	cycle_progress = float(PHASE_PROGRESS[current_phase])
	if _active_sun != null:
		_apply_to_sun(_active_sun)
	cycle_progress_changed.emit(cycle_progress)
	if phase_did_change:
		phase_changed.emit(current_phase)


func get_phase_name() -> String:
	return str(PHASE_NAMES.get(current_phase, "Dawn"))


func get_time_of_day_hours() -> float:
	return cycle_progress * 24.0


func is_morning_time() -> bool:
	return current_phase == Phase.MORNING or current_phase == Phase.DAY


func is_night_time() -> bool:
	return current_phase == Phase.NIGHT


## Dawn/dusk/night all read as dark — only full Day is "bright". Drives the
## ambient soundscape (birds vs. night desert) and bird roosting.
func is_dark_time() -> bool:
	return current_phase != Phase.DAY


## Outdoor wall lamps: on at dawn, dusk, and night — off during day.
func should_outdoor_lights_be_on(_currently_on: bool) -> bool:
	return current_phase != Phase.DAY


func is_outdoor_night() -> bool:
	return _active_sun != null and is_night_time()


func get_sun_height() -> float:
	var sun_angle := (cycle_progress * 2.0 - 0.5) * -PI
	return cos(sun_angle)


func get_night_factor() -> float:
	return 1.0 - smoothstep(-0.15, 0.1, get_sun_height())


## Debug / settings: snap continuous 0–1 progress onto the nearest phase.
func set_cycle_progress(progress: float) -> void:
	var wrapped := fmod(progress, 1.0)
	if wrapped < 0.0:
		wrapped += 1.0
	var best_phase := Phase.MORNING
	var best_dist := 999.0
	for phase in PHASE_PROGRESS.keys():
		var dist := absf(float(PHASE_PROGRESS[phase]) - wrapped)
		if dist < best_dist:
			best_dist = dist
			best_phase = int(phase)
	set_phase(best_phase)


func _ensure_session_start() -> void:
	if _session_started:
		return
	_session_started = true
	current_phase = Phase.MORNING
	cycle_progress = float(PHASE_PROGRESS[Phase.MORNING])


func _set_cycle_progress_visual(progress: float) -> void:
	cycle_progress = fmod(progress, 1.0)
	if cycle_progress < 0.0:
		cycle_progress += 1.0
	if _active_sun != null:
		_apply_to_sun(_active_sun)
	cycle_progress_changed.emit(cycle_progress)


func _kill_phase_tween() -> void:
	if _phase_tween != null and _phase_tween.is_valid():
		_phase_tween.kill()
	_phase_tween = null


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
