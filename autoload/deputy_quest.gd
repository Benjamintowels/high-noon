extends Node

signal quest_accepted
signal raid_completed

const DISPLAY_NAME := "Deputy"

var raid_finished := false
var accepted := false
var badge_collected := false


func reset_quest() -> void:
	raid_finished = false
	accepted = false
	badge_collected = false


func mark_raid_finished() -> void:
	if raid_finished:
		return
	raid_finished = true
	raid_completed.emit()


func begin_quest() -> void:
	if accepted:
		return
	accepted = true
	quest_accepted.emit()


func collect_badge() -> void:
	if badge_collected:
		return
	badge_collected = true
	begin_quest()


func get_active_quest_labels() -> Array[String]:
	if not accepted:
		return []
	return [DISPLAY_NAME]
