extends SceneTree

const CoverPoseExtractScript := preload("res://characters/groyper/cover_pose_extract.gd")

func _init() -> void:
	var err: Error = CoverPoseExtractScript.extract_to_res()
	quit(0 if err == OK else 1)
