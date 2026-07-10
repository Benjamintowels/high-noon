@tool
extends Node

const ClimbFallExtractScript := preload("res://characters/groyper/climb_fall_extract.gd")

## Attach to groyper_body.tscn. Toggle extract_climb_fall in the Inspector to refresh climb_fall.tres.

@export var extract_climb_fall: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := ClimbFallExtractScript.extract_to_res()
		if err != OK:
			push_error("ClimbFallExtractNode: extraction failed (%s)." % err)
		extract_climb_fall = false
