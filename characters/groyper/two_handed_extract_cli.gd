extends SceneTree

const TwoHandedExtractScript := preload("res://characters/groyper/two_handed_extract.gd")


func _init() -> void:
	var err := TwoHandedExtractScript.extract_to_res()
	quit(0 if err == OK else 1)
