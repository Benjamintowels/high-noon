extends SceneTree

const TcAnimUtilsScript := preload("res://characters/tc/tc_anim_utils.gd")


func _initialize() -> void:
	var library := TcAnimUtilsScript.bake_library()
	quit(0 if library != null else 1)
