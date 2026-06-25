extends Node3D

const CAMERA_MAX_PITCH: float = deg_to_rad(45.0)
const CAMERA_MIN_PITCH: float = deg_to_rad(-25.0)
const CAMERA_RATIO: float = 0.625

@export var mouse_sensitivity: float = 0.002
@export var mouse_y_inversion: float = -1.0

@onready var _camera_pitch: Node3D = %Arm
@onready var _camera: Camera3D = %Camera3D


func _ready() -> void:
	_camera.current = true
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotation.y -= event.relative.x * mouse_sensitivity
		_camera_pitch.rotation.x += event.relative.y * mouse_sensitivity * CAMERA_RATIO * mouse_y_inversion
		_camera_pitch.rotation.x = clamp(_camera_pitch.rotation.x, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			get_viewport().set_input_as_handled()
	elif event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
