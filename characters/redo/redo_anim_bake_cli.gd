extends SceneTree

const RedoAnimUtilsScript := preload("res://characters/redo/redo_anim_utils.gd")


func _initialize() -> void:
	var library := RedoAnimUtilsScript.bake_library()
	quit(0 if library != null else 1)
