@tool
extends Node
class_name PavelAnimBaker

const PavelAnimUtilsScript := preload("res://characters/pavel/pavel_anim_utils.gd")
const PavelAnimConfigScript := preload("res://characters/pavel/pavel_anim_config.gd")


@export var rebake_animations: bool = false:
	set(value):
		rebake_animations = value
		if value and Engine.is_editor_hint():
			bake_from_merged_fbx()
			rebake_animations = false


func bake_from_merged_fbx() -> void:
	var library := PavelAnimUtilsScript.bake_library()
	if library == null:
		push_error("PavelAnimBaker: merged FBX bake failed.")
		return

	var anim_player := _find_animation_player()
	if anim_player != null:
		if anim_player.has_animation_library(PavelAnimConfigScript.LIBRARY):
			anim_player.remove_animation_library(PavelAnimConfigScript.LIBRARY)
		anim_player.add_animation_library(PavelAnimConfigScript.LIBRARY, library)

	print("PavelAnimBaker: rebaked clips -> ", PavelAnimConfigScript.LIB_PATH)


func _find_animation_player() -> AnimationPlayer:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return owner_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
