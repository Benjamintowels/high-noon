extends Node

var completed := false
var top_ranch_hostile := false


func reset_progress() -> void:
	completed = false
	set_top_ranch_hostile(false)


func mark_completed() -> void:
	completed = true


## Once flipped, Top Ranch stays hostile to the player for the rest of the
## game (a future sidequest can call this with false to make peace).
func set_top_ranch_hostile(value: bool) -> void:
	top_ranch_hostile = value
	FactionAffinity.top_ranch_hostile_to_player = value


func apply_snapshot(data: Dictionary) -> void:
	completed = bool(data.get("completed", false))
	set_top_ranch_hostile(bool(data.get("top_ranch_hostile", false)))


func capture_snapshot() -> Dictionary:
	return {
		"completed": completed,
		"top_ranch_hostile": top_ranch_hostile,
	}
