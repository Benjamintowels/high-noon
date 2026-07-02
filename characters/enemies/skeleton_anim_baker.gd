@tool
extends Node
class_name SkeletonAnimBaker

## Rebake skeleton clips from groyper idle/walk + punch into editable .tres files.

const SkeletonAnimUtilsScript := preload("res://characters/enemies/skeleton_anim_utils.gd")
const LIB_PATH := SkeletonAnimUtilsScript.LIB_PATH


@export var rebake_animations: bool = false:
	set(value):
		rebake_animations = value
		if value and Engine.is_editor_hint():
			bake_from_groyper()
			rebake_animations = false


func bake_from_groyper() -> void:
	var library := SkeletonAnimUtilsScript.bake_library()
	if library == null:
		push_error("SkeletonAnimBaker: groyper retarget bake failed.")
		return

	var anim_player := _find_enemy_animation_player()
	if anim_player != null:
		anim_player.set_animation_library("", library)

	print("SkeletonAnimBaker: rebaked groyper idle/walk/punch -> ", LIB_PATH)


func _find_enemy_animation_player() -> AnimationPlayer:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return owner_node.get_node_or_null("AnimationPlayer") as AnimationPlayer
