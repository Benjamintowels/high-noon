extends Node3D

const FLASH_DURATION := 0.08
const FLASH_ENERGY := 5.5

var _light: OmniLight3D
var _tween: Tween


func _ready() -> void:
	_light = OmniLight3D.new()
	_light.name = "StrikeFlash"
	_light.light_color = Color(1.0, 0.82, 0.45, 1.0)
	_light.light_energy = 0.0
	_light.omni_range = 2.5
	_light.shadow_enabled = false
	add_child(_light)


func flash() -> void:
	if _light == null:
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_light.light_energy = FLASH_ENERGY
	_tween = create_tween()
	_tween.tween_property(_light, "light_energy", 0.0, FLASH_DURATION)\
		.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
