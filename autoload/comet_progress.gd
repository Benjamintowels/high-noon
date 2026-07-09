extends Node

var completed := false


func reset_progress() -> void:
	completed = false


func mark_completed() -> void:
	completed = true


func apply_snapshot(data: Dictionary) -> void:
	completed = bool(data.get("completed", false))


func capture_snapshot() -> Dictionary:
	return {
		"completed": completed,
	}
