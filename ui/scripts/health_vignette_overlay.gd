class_name HealthVignetteOverlay
extends CanvasLayer

const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")

const FADE_SPEED := 5.0

@onready var _vignette: ColorRect = $Vignette

var _shader_material: ShaderMaterial
var _target_intensity := 0.0
var _display_intensity := 0.0


func _ready() -> void:
	_shader_material = _vignette.material as ShaderMaterial
	visible = false


func _process(delta: float) -> void:
	if _shader_material == null:
		return

	_display_intensity = lerpf(
		_display_intensity,
		_target_intensity,
		1.0 - exp(-FADE_SPEED * delta)
	)
	visible = _display_intensity > 0.004 or _target_intensity > 0.004
	_shader_material.set_shader_parameter("intensity", _display_intensity)


func set_health(current: int, max_health: int = BulletHitDamage.PLAYER_MAX_HEALTH) -> void:
	if max_health <= 0 or current >= max_health:
		_target_intensity = 0.0
		return

	var missing_ratio := 1.0 - float(current) / float(max_health)
	_target_intensity = pow(missing_ratio, 0.8)
