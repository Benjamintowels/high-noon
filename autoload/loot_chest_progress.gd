extends "res://autoload/quest_state_base.gd"
## Permanent opened flags for quest/progression loot chests (e.g. hotel soul chest).

var opened_chest_ids: Array = []


func get_save_key() -> String:
	return "loot_chest_progress"


func get_save_fields() -> Array:
	return ["opened_chest_ids"]


func is_opened(chest_id: StringName) -> bool:
	if chest_id == &"":
		return false
	return opened_chest_ids.has(String(chest_id))


func mark_opened(chest_id: StringName) -> void:
	if chest_id == &"":
		return
	var key := String(chest_id)
	if opened_chest_ids.has(key):
		return
	opened_chest_ids.append(key)


func apply_snapshot(data: Dictionary) -> void:
	super.apply_snapshot(data)
	# JSON arrays survive as Array; normalize to String entries.
	var normalized: Array = []
	for entry in opened_chest_ids:
		normalized.append(str(entry))
	opened_chest_ids = normalized
