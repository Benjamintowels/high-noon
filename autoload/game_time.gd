extends Node

## Real-time clock helpers for gameplay simulation.
## Use physics_delta() / process_delta() for movement, combat, ragdoll, and props so
## results stay consistent across devices. Do not use Engine.time_scale for gameplay slow-mo.

var visual_time_scale := 1.0


func physics_delta(scaled_delta: float) -> float:
	return scaled_delta / maxf(Engine.time_scale, 0.001)


func process_delta(scaled_delta: float) -> float:
	return physics_delta(scaled_delta)


func visual_delta(scaled_delta: float) -> float:
	return process_delta(scaled_delta) * visual_time_scale


func set_visual_slowmo(scale: float) -> void:
	visual_time_scale = clampf(scale, 0.05, 1.0)


func reset_visual_slowmo() -> void:
	visual_time_scale = 1.0


func ensure_realtime() -> void:
	Engine.time_scale = 1.0
