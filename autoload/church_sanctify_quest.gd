extends "res://autoload/quest_state_base.gd"
## Church / Chief Getcha questline progress.
##
## Fields are intentionally flat and easy to tweak from the journal/debug
## tooling or by calling the mark_* / set_progress helpers — AdventureSave
## persists the whole quest_state group automatically.

signal sanctified
signal chief_defeated_changed
signal recurve_bow_collected_changed

const DISPLAY_NAME := "The Old Church"

## Talked to Chief / fight started.
var accepted := false
## Chief defeated once — church grounds stay sanctified (no skeleton ambush).
var chief_defeated := false
## Player took the Recurve Bow reward from the church.
var recurve_bow_collected := false


func get_save_key() -> String:
	return "church_sanctify"


func get_save_fields() -> Array:
	return ["accepted", "chief_defeated", "recurve_bow_collected"]


func get_display_name() -> String:
	return DISPLAY_NAME


func get_active_quest_labels() -> Array[String]:
	if not accepted:
		return []
	if chief_defeated and recurve_bow_collected:
		return []
	if chief_defeated:
		return ["%s — Sanctified" % DISPLAY_NAME]
	return [DISPLAY_NAME]


func is_sanctified() -> bool:
	return chief_defeated


func begin_quest() -> void:
	if accepted:
		return
	accepted = true
	quest_accepted.emit()


func mark_chief_defeated() -> void:
	if chief_defeated:
		return
	accepted = true
	chief_defeated = true
	chief_defeated_changed.emit()
	sanctified.emit()


func mark_recurve_bow_collected() -> void:
	if recurve_bow_collected:
		return
	recurve_bow_collected = true
	recurve_bow_collected_changed.emit()


## Dev / questline editing: set any subset of progress flags in one call.
## Example: ChurchSanctifyQuest.set_progress({ "chief_defeated": true })
func set_progress(fields: Dictionary) -> void:
	var was_defeated := chief_defeated
	if fields.has("accepted"):
		accepted = bool(fields["accepted"])
	if fields.has("chief_defeated"):
		chief_defeated = bool(fields["chief_defeated"])
	if fields.has("recurve_bow_collected"):
		recurve_bow_collected = bool(fields["recurve_bow_collected"])
	if chief_defeated and not was_defeated:
		sanctified.emit()
		chief_defeated_changed.emit()
	elif was_defeated != chief_defeated:
		chief_defeated_changed.emit()


func reset() -> void:
	var was_defeated := chief_defeated
	accepted = false
	chief_defeated = false
	recurve_bow_collected = false
	if was_defeated:
		chief_defeated_changed.emit()


func apply_snapshot(data: Dictionary) -> void:
	if data.has("accepted"):
		accepted = bool(data["accepted"])
	if data.has("chief_defeated"):
		chief_defeated = bool(data["chief_defeated"])
	if data.has("recurve_bow_collected"):
		recurve_bow_collected = bool(data["recurve_bow_collected"])
