extends Node

var intro_complete := false


func reset_progress() -> void:
	intro_complete = false


func mark_intro_complete() -> void:
	intro_complete = true


func apply_snapshot(data: Dictionary) -> void:
	intro_complete = bool(data.get("intro_complete", false))


func capture_snapshot() -> Dictionary:
	return {
		"intro_complete": intro_complete,
	}
