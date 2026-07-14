extends "res://autoload/quest_state_base.gd"
## One-time flag for the sheriff "cattle thieves" cutscene at the TownIntro
## trigger (gameplay/world/town_intro_cutscene.gd).

var completed := false


func get_save_key() -> String:
	return "town_intro"


func get_save_fields() -> Array:
	return ["completed"]


func mark_completed() -> void:
	completed = true
