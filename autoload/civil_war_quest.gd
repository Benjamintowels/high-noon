extends "res://autoload/quest_state_base.gd"

const DISPLAY_NAME := "Civil War"

var accepted := false


func get_save_key() -> String:
	return "civil_war"


func get_save_fields() -> Array:
	return ["accepted"]


func get_display_name() -> String:
	return DISPLAY_NAME
