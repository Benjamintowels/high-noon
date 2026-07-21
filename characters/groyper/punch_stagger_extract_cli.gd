extends SceneTree

const PunchStaggerExtractScript := preload("res://characters/groyper/punch_stagger_extract.gd")


func _init() -> void:
	print("PunchStaggerExtractCLI: starting")
	var err := PunchStaggerExtractScript.extract_to_res()
	print("PunchStaggerExtractCLI: finished err=%s" % err)
	quit(0 if err == OK else 1)
