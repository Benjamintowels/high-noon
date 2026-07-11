@tool
extends Node

const TwoHandedExtractScript := preload("res://characters/groyper/two_handed_extract.gd")

## Attach to groyper_body.tscn. Toggle extract_two_handed in the Inspector to
## refresh two_handed.tres from the source FBX clips.

@export var extract_two_handed: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := TwoHandedExtractScript.extract_to_res()
		if err != OK:
			push_error("TwoHandedExtractNode: extraction failed (%s)." % err)
		extract_two_handed = false
