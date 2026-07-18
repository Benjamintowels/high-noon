extends Node

## Disk persistence for Roguelike hub progress. Separate from Story Mode's
## adventure_save.json — never writes there.

const SAVE_PATH := "user://roguelike_save.json"
const SAVE_VERSION := 1


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func clear_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


## Snapshot hub/meta/inventory/zone state and write to disk.
func save_session() -> void:
	if not RunState.roguelike_active:
		return
	var snapshot := {
		"version": SAVE_VERSION,
		"completed_runs": _capture_completed_runs(),
		"meta": RunMetaProgress.capture_snapshot(),
		"inventory": PlayerInventory.capture_snapshot(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("RoguelikeSave: failed to write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(snapshot, "\t"))


## Load disk save into the active session autoloads. Returns false if missing/bad.
func load_session() -> bool:
	var snapshot := _read_snapshot()
	if snapshot.is_empty():
		return false
	_apply_completed_runs(snapshot.get("completed_runs", []))
	var meta: Variant = snapshot.get("meta", {})
	if meta is Dictionary:
		RunMetaProgress.apply_snapshot(meta)
	var inventory: Variant = snapshot.get("inventory", {})
	if inventory is Dictionary:
		PlayerInventory.apply_snapshot(inventory)
	RunMetaProgress.apply_bank_to_inventory()
	return true


func _read_snapshot() -> Dictionary:
	if not FileAccess.file_exists(SAVE_PATH):
		return {}
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("RoguelikeSave: failed to read %s" % SAVE_PATH)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var version := int(parsed.get("version", 0))
		if version > SAVE_VERSION:
			push_warning(
				"RoguelikeSave: save version %d newer than supported %d; ignoring"
				% [version, SAVE_VERSION]
			)
			return {}
		return parsed
	return {}


func _capture_completed_runs() -> Array:
	var out: Array = []
	for entry in RunState.completed_runs:
		if entry is Dictionary:
			out.append({
				"zone_id": str(entry.get("zone_id", "")),
				"victory": bool(entry.get("victory", false)),
			})
	return out


func _apply_completed_runs(raw: Variant) -> void:
	RunState.completed_runs.clear()
	if raw is not Array:
		return
	for entry in raw:
		if entry is not Dictionary:
			continue
		var zone_id := str(entry.get("zone_id", ""))
		if zone_id == "":
			continue
		RunState.completed_runs.append({
			"zone_id": zone_id,
			"victory": bool(entry.get("victory", false)),
		})
