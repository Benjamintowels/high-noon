extends SceneTree

const LassoSwingExtractScript := preload("res://characters/groyper/lasso_swing_extract.gd")


func _init() -> void:
	var err := LassoSwingExtractScript.extract_to_res()
	quit(0 if err == OK else 1)
