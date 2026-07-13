extends "res://autoload/quest_state_base.gd"

signal raid_completed

const DISPLAY_NAME := "Deputy"

var raid_finished := false
var accepted := false
var badge_collected := false


func get_save_key() -> String:
	return "deputy"


func get_save_fields() -> Array:
	return ["accepted", "badge_collected", "raid_finished"]


func get_display_name() -> String:
	return DISPLAY_NAME


func mark_raid_finished() -> void:
	if raid_finished:
		return
	raid_finished = true
	raid_completed.emit()


func collect_badge() -> void:
	if badge_collected:
		return
	badge_collected = true
	begin_quest()
