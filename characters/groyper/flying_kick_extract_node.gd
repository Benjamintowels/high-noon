@tool
extends Node

const FlyingKickExtractScript := preload("res://characters/groyper/flying_kick_extract.gd")

## Attach to groyper_body.tscn. Toggle extract_flying_kick in the Inspector to refresh flying_kick.tres.

@export var extract_flying_kick: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := FlyingKickExtractScript.extract_to_res()
		if err != OK:
			push_error("FlyingKickExtractNode: extraction failed (%s)." % err)
		extract_flying_kick = false
