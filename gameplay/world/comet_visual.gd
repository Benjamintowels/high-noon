extends Node3D
class_name CometVisual

const FIRE_SCENE := preload("res://Assets/World/RuinsGR/AccessoriesScenes/fire.tscn")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

## Large scale so the lantern fire reads at sky distance while tuning placement.
const COMET_FIRE_SCALE := 24.0

var _fire_root: Node3D
var _fade_tween: Tween
var _trail_timer: Timer
var _last_position := Vector3.ZERO


func _ready() -> void:
	_last_position = global_position
	_build_visuals()
	_start_trail_puffs()


func set_flight_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	look_at(global_position + direction.normalized(), Vector3.UP)


func fade_out(duration: float = 0.5) -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_stop_fire()
	_fade_tween = create_tween()
	if _fire_root != null:
		_fade_tween.tween_property(_fire_root, "scale", Vector3.ONE * 0.05, duration)
	_fade_tween.finished.connect(queue_free)


func _build_visuals() -> void:
	var fire := FIRE_SCENE.instantiate()
	fire.name = "CometFire"
	add_child(fire)
	fire.scale = Vector3.ONE * COMET_FIRE_SCALE
	if fire.has_method("set_respect_day_night"):
		fire.set_respect_day_night(false)
	_tune_fire_for_sky(fire)
	_fire_root = fire


func _tune_fire_for_sky(fire: Node3D) -> void:
	var light := fire.get_node_or_null("Light") as OmniLight3D
	if light != null:
		light.omni_range = 240.0
		light.light_energy = 20.0
		light.shadow_enabled = false

	var particles := fire.get_node_or_null("FireVFX") as CPUParticles3D
	if particles != null:
		particles.amount = 520
		particles.emission_sphere_radius = 7.0
		particles.scale_amount_min = 2.8
		particles.scale_amount_max = 4.8
		particles.speed_scale = 0.35
		particles.emitting = true

	var audio := fire.get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	if audio != null:
		audio.autoplay = false
		audio.stop()


func _stop_fire() -> void:
	if _fire_root == null:
		return
	var particles := _fire_root.get_node_or_null("FireVFX") as CPUParticles3D
	if particles != null:
		particles.emitting = false
	var light := _fire_root.get_node_or_null("Light") as OmniLight3D
	if light != null:
		light.visible = false
	var audio := _fire_root.get_node_or_null("AudioStreamPlayer3D") as AudioStreamPlayer3D
	if audio != null:
		audio.stop()


func _start_trail_puffs() -> void:
	_trail_timer = Timer.new()
	_trail_timer.wait_time = 0.18
	_trail_timer.timeout.connect(_emit_trail_puff)
	add_child(_trail_timer)
	_trail_timer.start()


func _emit_trail_puff() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SmokePuffFXScript.spawn_trail(parent, global_position, randf_range(1.2, 2.4))


func _process(_delta: float) -> void:
	var movement := global_position - _last_position
	if movement.length_squared() > 0.04:
		set_flight_direction(movement)
	_last_position = global_position
