extends Node3D

@export var base_energy := 3.0
@export var flicker_strength := 0.16
@export var flicker_speed := 8.5

@onready var _light: OmniLight3D = $Light

var _phase := 0.0


func _ready() -> void:
	_phase = randf() * TAU
	if _light != null:
		_light.light_energy = base_energy


func _process(delta: float) -> void:
	if _light == null:
		return
	_phase += delta * flicker_speed
	var wobble := sin(_phase) * 0.55 + sin(_phase * 2.31) * 0.3
	_light.light_energy = base_energy * (1.0 + wobble * flicker_strength)
