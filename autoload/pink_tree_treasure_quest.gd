extends "res://autoload/quest_state_base.gd"

const DISPLAY_NAME := "Pink Tree Treasure"

var accepted := false


func get_save_key() -> String:
	return "pink_tree_treasure"


func get_save_fields() -> Array:
	return ["accepted"]


func get_display_name() -> String:
	return DISPLAY_NAME
