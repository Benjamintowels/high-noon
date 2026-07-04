@tool
extends Node
class_name TcAnimBaker

const TcAnimUtilsScript := preload("res://characters/tc/tc_anim_utils.gd")
const TcAnimConfigScript := preload("res://characters/tc/tc_anim_config.gd")


@export var rebake_animations: bool = false:
	set(value):
		rebake_animations = value
		if value and Engine.is_editor_hint():
			bake_from_merged_fbx()
			rebake_animations = false


func bake_from_merged_fbx() -> void:
	var library := TcAnimUtilsScript.bake_library()
	if library == null:
		push_error("TcAnimBaker: merged FBX bake failed.")
		return

	var anim_player := _find_animation_player()
	if anim_player != null:
		if anim_player.has_animation_library(TcAnimConfigScript.LIBRARY):
			anim_player.remove_animation_library(TcAnimConfigScript.LIBRARY)
		anim_player.add_animation_library(TcAnimConfigScript.LIBRARY, library)

	print("TcAnimBaker: rebaked clips -> ", TcAnimConfigScript.LIB_PATH)


func _find_animation_player() -> AnimationPlayer:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return owner_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
