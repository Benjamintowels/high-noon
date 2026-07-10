extends SceneTree

const LadderClimbExtractScript := preload("res://characters/groyper/ladder_climb_extract.gd")


func _init() -> void:
	var err := LadderClimbExtractScript.extract_to_res()
	quit(0 if err == OK else 1)
