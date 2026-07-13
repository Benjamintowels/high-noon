extends "res://autoload/quest_state_base.gd"

var completed := false
var top_ranch_hostile := false


func get_save_key() -> String:
	return "hotel_brawl"


func get_save_fields() -> Array:
	return ["completed", "top_ranch_hostile"]


func mark_completed() -> void:
	completed = true


## Once flipped, Top Ranch stays hostile to the player for the rest of the
## game (a future sidequest can call this with false to make peace).
func set_top_ranch_hostile(value: bool) -> void:
	top_ranch_hostile = value
	FactionAffinity.top_ranch_hostile_to_player = value


func reset() -> void:
	super()
	FactionAffinity.top_ranch_hostile_to_player = top_ranch_hostile


func apply_snapshot(data: Dictionary) -> void:
	super(data)
	FactionAffinity.top_ranch_hostile_to_player = top_ranch_hostile
