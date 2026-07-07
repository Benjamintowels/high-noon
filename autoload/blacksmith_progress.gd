extends Node

var met_smitty := false


func reset_progress() -> void:
	met_smitty = false


func mark_met() -> void:
	met_smitty = true


func apply_snapshot(data: Dictionary) -> void:
	met_smitty = bool(data.get("met_smitty", false))


func capture_snapshot() -> Dictionary:
	return {
		"met_smitty": met_smitty,
	}
