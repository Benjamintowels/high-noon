extends SceneTree

const PavelAnimUtilsScript := preload("res://characters/pavel/pavel_anim_utils.gd")


func _initialize() -> void:
	var library := PavelAnimUtilsScript.bake_library()
	quit(0 if library != null else 1)
