@tool
extends Node
class_name HorseAnimBaker

## Rebake Horsey clips from the rigged FBX into editable scene-local animations.

const HorseAnimUtilsScript := preload("res://characters/animals/horse_anim_utils.gd")
const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


@export var rebake_animations: bool = false:
	set(value):
		rebake_animations = value
		if value and Engine.is_editor_hint():
			bake_from_fbx()
			rebake_animations = false


@export var localize_for_editing: bool = false:
	set(value):
		localize_for_editing = value
		if value and Engine.is_editor_hint():
			localize_horse_library()
			localize_for_editing = false


@export var export_to_anims: bool = false:
	set(value):
		export_to_anims = value
		if value and Engine.is_editor_hint():
			export_horse_library()
			export_to_anims = false


func bake_from_fbx() -> void:
	var library := HorseAnimUtilsScript.bake_library(true)
	if library == null:
		push_error("HorseAnimBaker: failed to bake horse animations.")
		return

	_set_horse_library(library)
	_save_rig_scene()
	print(
		"HorseAnimBaker: rebaked idle/walk/bow -> ",
		HorseAnimConfigScript.LIB_PATH,
		" (embedded into horsey_rig.tscn)"
	)


func localize_horse_library() -> void:
	var anim_player := _find_horse_animation_player()
	if anim_player == null or not anim_player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		push_warning("HorseAnimBaker: no horse animation library to localize.")
		return

	var source: AnimationLibrary = anim_player.get_animation_library(HorseAnimConfigScript.LIBRARY)
	_set_horse_library(HorseAnimUtilsScript.localize_library_for_editing(source))
	_save_rig_scene()
	print("HorseAnimBaker: localized horse animations for in-scene editing.")


func export_horse_library() -> void:
	var anim_player := _find_horse_animation_player()
	if anim_player == null or not anim_player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		push_warning("HorseAnimBaker: no horse animation library to export.")
		return

	var library: AnimationLibrary = anim_player.get_animation_library(HorseAnimConfigScript.LIBRARY)
	if HorseAnimUtilsScript.export_library_to_disk(library):
		_save_rig_scene()
		print("HorseAnimBaker: exported scene edits to characters/animals/anims/.")


func _set_horse_library(library: AnimationLibrary) -> void:
	var anim_player := _find_horse_animation_player()
	if anim_player == null:
		return
	if anim_player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		anim_player.remove_animation_library(HorseAnimConfigScript.LIBRARY)
	anim_player.add_animation_library(HorseAnimConfigScript.LIBRARY, library)


func _find_horse_animation_player() -> AnimationPlayer:
	var owner_node := get_parent()
	if owner_node == null:
		return null
	return RigAnimUtilsScript.find_animation_player(owner_node) as AnimationPlayer


func _save_rig_scene() -> void:
	if not Engine.is_editor_hint():
		return
	var owner_node := get_parent()
	if owner_node == null:
		return
	var packed := PackedScene.new()
	var err := packed.pack(owner_node)
	if err != OK:
		push_error("HorseAnimBaker: failed to pack horsey rig scene (%s)." % err)
		return
	err = ResourceSaver.save(packed, HorseAnimConfigScript.RIGGED_SCENE)
	if err != OK:
		push_error("HorseAnimBaker: failed to save horsey_rig.tscn (%s)." % err)

