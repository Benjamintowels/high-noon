extends Node
## Shared base for quest/progress autoload singletons.
##
## A subclass declares its save key, persisted field names, and (optionally)
## a journal display name; it gets generic snapshot capture/apply, reset, and
## journal labels for free. Every instance joins the "quest_state" group, and
## AdventureSave persists/resets the whole group — a new quest autoload only
## needs to extend this file and override the three getters below. No edits
## to AdventureSave or the journal UI are required.
##
## NOTE: group membership is only visible once the autoload has entered the
## tree; consumers that run during an EARLIER autoload's _ready (e.g. the
## inventory menu) must defer their group iteration with call_deferred.

signal quest_accepted

const GROUP := "quest_state"

var _field_defaults := {}


func _ready() -> void:
	add_to_group(GROUP)
	for field in get_save_fields():
		_field_defaults[field] = get(field)


## Key under which this quest's snapshot is stored in the save file.
func get_save_key() -> String:
	push_error("%s: get_save_key() not overridden" % name)
	return name


## Property names persisted by capture_snapshot/apply_snapshot and
## restored to their declared defaults by reset().
func get_save_fields() -> Array:
	return []


## Journal label; empty string keeps the quest out of the journal list.
func get_display_name() -> String:
	return ""


func reset() -> void:
	for field in get_save_fields():
		set(field, _field_defaults[field])


# Back-compat aliases — both naming conventions predate this base class.
func reset_quest() -> void:
	reset()


func reset_progress() -> void:
	reset()


func begin_quest() -> void:
	if bool(get("accepted")):
		return
	set("accepted", true)
	quest_accepted.emit()


func get_active_quest_labels() -> Array[String]:
	if get_display_name() == "" or not bool(get("accepted")):
		return []
	return [get_display_name()]


func capture_snapshot() -> Dictionary:
	var snapshot := {}
	for field in get_save_fields():
		snapshot[field] = get(field)
	return snapshot


func apply_snapshot(data: Dictionary) -> void:
	for field in get_save_fields():
		if not data.has(field):
			continue
		var value: Variant = data[field]
		# JSON round-trips ints as floats; coerce to the declared type.
		match typeof(_field_defaults.get(field)):
			TYPE_BOOL:
				value = bool(value)
			TYPE_INT:
				value = int(value)
			TYPE_FLOAT:
				value = float(value)
			TYPE_STRING:
				value = str(value)
		set(field, value)
