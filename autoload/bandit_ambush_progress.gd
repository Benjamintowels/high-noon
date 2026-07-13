extends "res://autoload/quest_state_base.gd"

var completed := false


func get_save_key() -> String:
	return "bandit_ambush"


func get_save_fields() -> Array:
	return ["completed"]


func mark_completed() -> void:
	completed = true
