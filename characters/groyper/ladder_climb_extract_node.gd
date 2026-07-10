@tool
extends Node

const LadderClimbExtractScript := preload("res://characters/groyper/ladder_climb_extract.gd")

## Attach to groyper_body.tscn. Toggle extract_ladder_climb in the Inspector to refresh ladder_climb.tres.

@export var extract_ladder_climb: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := LadderClimbExtractScript.extract_to_res()
		if err != OK:
			push_error("LadderClimbExtractNode: extraction failed (%s)." % err)
		extract_ladder_climb = false
