extends Node

signal quest_accepted

const DISPLAY_NAME := "Civil War"

var accepted := false


func reset_quest() -> void:
	accepted = false


func begin_quest() -> void:
	if accepted:
		return
	accepted = true
	quest_accepted.emit()


func get_active_quest_labels() -> Array[String]:
	if not accepted:
		return []
	return [DISPLAY_NAME]
