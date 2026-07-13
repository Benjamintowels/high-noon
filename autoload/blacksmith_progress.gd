extends "res://autoload/quest_state_base.gd"

var met_smitty := false


func get_save_key() -> String:
	return "blacksmith"


func get_save_fields() -> Array:
	return ["met_smitty"]


func mark_met() -> void:
	met_smitty = true
