extends Node3D

const FLAME_ON := preload("res://Assets/Sounds/FlameOn.mp3")

@export var base_energy := 3.0
@export var flicker_strength := 0.16
@export var flicker_speed := 8.5
@export var respect_day_night := false

@onready var _light: OmniLight3D = $Light
@onready var _particles: CPUParticles3D = $FireVFX
@onready var _audio: AudioStreamPlayer3D = $AudioStreamPlayer3D

var _phase := 0.0
var _is_lit := true
var _ignite_audio: AudioStreamPlayer3D


func set_respect_day_night(enabled: bool) -> void:
	if respect_day_night == enabled:
		return
	respect_day_night = enabled
	_bind_day_night(enabled)
	_update_lit_state()


func _ready() -> void:
	_phase = randf() * TAU
	_setup_ignite_audio()
	_bind_day_night(respect_day_night)
	_update_lit_state()


func _exit_tree() -> void:
	_bind_day_night(false)


func _process(delta: float) -> void:
	if _light == null or not _is_lit:
		return

	_phase += delta * flicker_speed
	var wobble := sin(_phase) * 0.55 + sin(_phase * 2.31) * 0.3
	_light.light_energy = base_energy * (1.0 + wobble * flicker_strength)


func _on_cycle_changed(_progress: float) -> void:
	if not respect_day_night:
		return
	var should_be_lit := DayNightCycle.should_outdoor_lights_be_on(_is_lit)
	if should_be_lit != _is_lit:
		_set_lit(should_be_lit, should_be_lit)


func _update_lit_state() -> void:
	if not respect_day_night:
		_set_lit(true)
		return
	_set_lit(DayNightCycle.should_outdoor_lights_be_on(_is_lit))


func _bind_day_night(enabled: bool) -> void:
	if enabled:
		if not DayNightCycle.cycle_progress_changed.is_connected(_on_cycle_changed):
			DayNightCycle.cycle_progress_changed.connect(_on_cycle_changed)
	else:
		if DayNightCycle.cycle_progress_changed.is_connected(_on_cycle_changed):
			DayNightCycle.cycle_progress_changed.disconnect(_on_cycle_changed)


func _setup_ignite_audio() -> void:
	_ignite_audio = AudioStreamPlayer3D.new()
	_ignite_audio.name = "IgniteAudio"
	_ignite_audio.stream = FLAME_ON
	_ignite_audio.volume_db = 10.0
	_ignite_audio.max_distance = 15.0
	add_child(_ignite_audio)


func _set_lit(lit: bool, play_ignite: bool = false) -> void:
	_is_lit = lit
	if _light != null:
		_light.visible = lit
	if _particles != null:
		_particles.emitting = lit
	if _audio != null:
		if lit:
			if not _audio.playing:
				_audio.play()
		else:
			_audio.stop()
	if lit and play_ignite and _ignite_audio != null:
		_ignite_audio.play()
