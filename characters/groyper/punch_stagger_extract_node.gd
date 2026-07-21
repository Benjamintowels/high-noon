@tool
extends Node

## Attach to groyper_body.tscn. Toggle extract_punch_stagger to refresh punch_stagger.tres
## from the Meshy hit-reaction FBXs.

const PunchStaggerExtractScript := preload("res://characters/groyper/punch_stagger_extract.gd")

@export var extract_punch_stagger: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := PunchStaggerExtractScript.extract_to_res()
		if err != OK:
			push_error("PunchStaggerExtractNode: extraction failed (%s)." % err)
		extract_punch_stagger = false
