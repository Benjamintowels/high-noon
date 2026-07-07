@tool
extends Node

## Applies stage materials while editing so loose GLB props are visible and movable.


func _enter_tree() -> void:
	if Engine.is_editor_hint():
		call_deferred("_apply_materials")


func _apply_materials() -> void:
	var stage := get_parent()
	if stage == null:
		return
	Stage1VisualSetup.apply_materials(stage)
