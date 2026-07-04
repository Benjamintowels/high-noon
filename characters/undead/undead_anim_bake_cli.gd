extends SceneTree

const UndeadAnimUtilsScript := preload("res://characters/undead/undead_anim_utils.gd")


func _initialize() -> void:
	var library := UndeadAnimUtilsScript.bake_library()
	quit(0 if library != null else 1)
