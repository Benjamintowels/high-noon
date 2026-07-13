extends "res://autoload/quest_state_base.gd"

var intro_complete := false


func get_save_key() -> String:
	return "horsey"


func get_save_fields() -> Array:
	return ["intro_complete"]


func mark_intro_complete() -> void:
	intro_complete = true
