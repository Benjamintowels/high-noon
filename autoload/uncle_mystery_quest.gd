extends "res://autoload/quest_state_base.gd"
## Multi-part Uncle Mystery questline. Part 1 is the HomeAmbush at Uncle's ranch.

signal part1_completed
signal home_visited_changed

const DISPLAY_NAME := "Uncle's Mystery"
const PART_COUNT := 4

## Player has entered home_interior at least once.
var home_visited := false
## True only after leaving home_interior — outdoor ambush may fire.
var ambush_armed := false
## Quest accepted (shown in journal).
var accepted := false
## Part 1: HomeAmbush cleared (last bandit fled).
var part1_done := false
## Reserved for later quest beats.
var part2_done := false
var part3_done := false
var part4_done := false


func get_save_key() -> String:
	return "uncle_mystery"


func get_save_fields() -> Array:
	return [
		"home_visited",
		"ambush_armed",
		"accepted",
		"part1_done",
		"part2_done",
		"part3_done",
		"part4_done",
	]


func get_display_name() -> String:
	return DISPLAY_NAME


func get_active_quest_labels() -> Array[String]:
	if not accepted:
		return []
	if part4_done:
		return []
	return ["%s (%d/%d)" % [DISPLAY_NAME, _completed_part_count(), PART_COUNT]]


func _completed_part_count() -> int:
	var count := 0
	if part1_done:
		count += 1
	if part2_done:
		count += 1
	if part3_done:
		count += 1
	if part4_done:
		count += 1
	return count


func is_ambush_primed() -> bool:
	return ambush_armed and not part1_done


func is_part1_done() -> bool:
	return part1_done


func mark_home_visited() -> void:
	if home_visited:
		return
	home_visited = true
	begin_quest()
	home_visited_changed.emit()


## Call when the player leaves home_interior after visiting. Visiting alone must
## not arm the fight — interior load happens while the player is still outdoors.
func arm_ambush_after_home_exit() -> void:
	if part1_done or not home_visited:
		return
	if ambush_armed:
		return
	ambush_armed = true


func mark_part1_done() -> void:
	if part1_done:
		return
	accepted = true
	part1_done = true
	part1_completed.emit()


func begin_quest() -> void:
	if accepted:
		return
	accepted = true
	quest_accepted.emit()
