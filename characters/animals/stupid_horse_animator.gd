extends Node3D
class_name StupidHorseAnimator

enum Mode { IDLE, WALK }

@export var walk_bob_height := 0.045
@export var walk_sway_deg := 2.5
@export var idle_breathe_height := 0.012
@export var idle_sway_deg := 1.2
@export var blend_speed := 5.0

var mode := Mode.IDLE

var _phase := 0.0
var _base_y := 0.0
var _current_y := 0.0
var _current_pitch := 0.0
var _current_roll := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	_current_y = _base_y


func set_mode(next_mode: Mode) -> void:
	mode = next_mode


func update_animation(delta: float, horizontal_speed: float) -> void:
	var walking := mode == Mode.WALK or horizontal_speed > 0.08
	if walking:
		_animate_walk(delta, horizontal_speed)
	else:
		_animate_idle(delta)


func _animate_idle(delta: float) -> void:
	_phase += delta * 1.1

	var target_y := _base_y + sin(_phase) * idle_breathe_height
	var target_pitch := sin(_phase * 0.85 + 0.4) * deg_to_rad(idle_sway_deg)
	var target_roll := cos(_phase * 0.7) * deg_to_rad(idle_sway_deg * 0.6)

	_apply_smoothed(delta, target_y, target_pitch, target_roll)


func _animate_walk(delta: float, speed: float) -> void:
	var step_rate := clampf(speed * 0.9, 1.4, 3.2)
	_phase += delta * step_rate * TAU

	# Smooth bob: ease in/out instead of sharp abs(sin) steps.
	var bob_wave := (1.0 - cos(_phase)) * 0.5
	var target_y := _base_y + bob_wave * walk_bob_height
	var target_roll := sin(_phase) * deg_to_rad(walk_sway_deg)
	var target_pitch := sin(_phase * 2.0) * deg_to_rad(walk_sway_deg * 0.35)

	_apply_smoothed(delta, target_y, target_pitch, target_roll)


func _apply_smoothed(
	delta: float,
	target_y: float,
	target_pitch: float,
	target_roll: float
) -> void:
	var step := 1.0 - exp(-blend_speed * delta)
	_current_y = lerpf(_current_y, target_y, step)
	_current_pitch = lerpf(_current_pitch, target_pitch, step)
	_current_roll = lerpf(_current_roll, target_roll, step)

	position.y = _current_y
	rotation.x = _current_pitch
	rotation.z = _current_roll
