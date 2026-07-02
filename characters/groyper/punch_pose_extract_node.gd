@tool
extends Node

## Attach to groyper_body.tscn. Toggle extract_punch_pose in the Inspector to refresh punch_pose.tres
## from the Meshy boxing punch FBX.

const PunchPoseExtractScript := preload("res://characters/groyper/punch_pose_extract.gd")

@export var extract_punch_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := PunchPoseExtractScript.extract_to_res()
		if err != OK:
			push_error("PunchPoseExtractNode: extraction failed (%s)." % err)
		extract_punch_pose = false
