@tool
extends Node
class_name RedoAnimBaker

## Rebake Redo clips from the merged Meshy FBX into editable .tres files.

const RedoAnimUtilsScript := preload("res://characters/redo/redo_anim_utils.gd")
const RedoAnimConfigScript := preload("res://characters/redo/redo_anim_config.gd")
const LIB_PATH := RedoAnimConfigScript.LIB_PATH


@export var rebake_animations: bool = false:
	set(value):
		rebake_animations = value
		if value and Engine.is_editor_hint():
			bake_from_merged_fbx()
			rebake_animations = false


func bake_from_merged_fbx() -> void:
	var library := RedoAnimUtilsScript.bake_library()
	if library == null:
		push_error("RedoAnimBaker: merged FBX bake failed.")
		return

	var anim_player := _find_animation_player()
	if anim_player != null:
		if anim_player.has_animation_library(RedoAnimConfigScript.LIBRARY):
			anim_player.remove_animation_library(RedoAnimConfigScript.LIBRARY)
		anim_player.add_animation_library(RedoAnimConfigScript.LIBRARY, library)

	print("RedoAnimBaker: rebaked clips -> ", RedoAnimConfigScript.LIB_PATH)


func _find_animation_player() -> AnimationPlayer:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return owner_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
