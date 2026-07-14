extends "res://autoload/quest_state_base.gd"
## Hotel ↔ Uncle's Ranch door. Starts locked from the hotel side; opening from
## the ranch side (or with the ranch key) unlocks it for the rest of the save.

var unlocked := false


func get_save_key() -> String:
	return "hotel_ranch_door"


func get_save_fields() -> Array:
	return ["unlocked"]


func get_display_name() -> String:
	return ""


func mark_unlocked() -> void:
	if unlocked:
		return
	unlocked = true
	if not PlayerInventory.has_ranch_key:
		PlayerInventory.set_has_ranch_key(true)
