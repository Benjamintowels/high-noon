@tool
extends Node

## Attach to groyper_body.tscn. Toggle extract_roll_dodges in the Inspector to refresh roll_dodge.tres.

@export var extract_roll_dodges: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := RollDodgeExtract.extract_to_res()
		if err != OK:
			push_error("RollDodgeExtractNode: extraction failed (%s)." % err)
		extract_roll_dodges = false


@export var refresh_run_roll_from_fbx: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := RollDodgeExtract.extract_run_roll_only()
		if err != OK:
			push_error("RollDodgeExtractNode: run_roll refresh failed (%s)." % err)
		refresh_run_roll_from_fbx = false
