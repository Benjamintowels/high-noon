extends SceneTree

const PunchPoseExtractScript := preload("res://characters/groyper/punch_pose_extract.gd")

func _init() -> void:
	print("PunchPoseExtractCLI: starting")
	var err := PunchPoseExtractScript.extract_to_res()
	print("PunchPoseExtractCLI: finished err=%s" % err)
	quit(0 if err == OK else 1)
