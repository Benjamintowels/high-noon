extends SceneTree

## Headless bake: Godot --headless --path . --script res://tools/bake_skeleton_groyper_anims.gd

const SkeletonAnimUtilsScript := preload("res://characters/enemies/skeleton_anim_utils.gd")


func _initialize() -> void:
	var library := SkeletonAnimUtilsScript.bake_library()
	if library == null:
		push_error("Skeleton groyper anim bake failed.")
		quit(1)
		return
	print("Skeleton groyper anim bake complete.")
	quit(0)
