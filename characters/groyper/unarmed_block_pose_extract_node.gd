@tool
extends Node

## Attach to groyper_body.tscn. Toggle extract_unarmed_block_pose in the Inspector to refresh
## unarmed_block_pose.tres from the Meshy parry FBX (frame 0).

const UnarmedBlockPoseExtractScript := preload(
	"res://characters/groyper/unarmed_block_pose_extract.gd"
)

@export var extract_unarmed_block_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		var err := UnarmedBlockPoseExtractScript.extract_to_res()
		if err != OK:
			push_error("UnarmedBlockPoseExtractNode: extraction failed (%s)." % err)
		extract_unarmed_block_pose = false
