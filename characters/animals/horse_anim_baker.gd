@tool
extends Node
class_name HorseAnimBaker

## Rebake Horsey clips from the rigged FBX into external anims/ resources.

const HorseAnimUtilsScript := preload("res://characters/animals/horse_anim_utils.gd")
const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")

const MESH_PATH := "res://characters/animals/horsey_mesh.res"
const SKIN_PATH := "res://characters/animals/horsey_skin.res"


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
		HorseAnimConfigScript.LIB_PATH
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

	_externalize_mesh_resources(owner_node)
	_externalize_horse_library_for_save()

	var packed := PackedScene.new()
	var err := packed.pack(owner_node)
	if err != OK:
		push_error("HorseAnimBaker: failed to pack horsey rig scene (%s)." % err)
		return
	err = ResourceSaver.save(packed, HorseAnimConfigScript.RIGGED_SCENE)
	if err != OK:
		push_error("HorseAnimBaker: failed to save horsey_rig.tscn (%s)." % err)


func _externalize_mesh_resources(owner_node: Node) -> void:
	var mesh_instance := owner_node.get_node_or_null(
		"Armature/Skeleton3D/Cube_001"
	) as MeshInstance3D
	if mesh_instance == null:
		return

	var mesh := mesh_instance.mesh
	if mesh != null and mesh.resource_path.is_empty():
		var mesh_copy: ArrayMesh = mesh.duplicate(true) as ArrayMesh
		if mesh_copy != null and ResourceSaver.save(mesh_copy, MESH_PATH, ResourceSaver.FLAG_COMPRESS) == OK:
			mesh_instance.mesh = load(MESH_PATH) as Mesh

	var skin := mesh_instance.skin
	if skin != null and skin.resource_path.is_empty():
		var skin_copy: Skin = skin.duplicate(true) as Skin
		if skin_copy != null and ResourceSaver.save(skin_copy, SKIN_PATH, ResourceSaver.FLAG_COMPRESS) == OK:
			mesh_instance.skin = load(SKIN_PATH) as Skin


func _externalize_horse_library_for_save() -> void:
	var anim_player := _find_horse_animation_player()
	if anim_player == null:
		return

	if anim_player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		var library: AnimationLibrary = anim_player.get_animation_library(
			HorseAnimConfigScript.LIBRARY
		)
		if library != null and not HorseAnimUtilsScript.export_library_to_disk(library):
			push_warning("HorseAnimBaker: failed to export horse library before save.")
		anim_player.remove_animation_library(HorseAnimConfigScript.LIBRARY)
		anim_player.add_animation_library(
			HorseAnimConfigScript.LIBRARY,
			load(HorseAnimConfigScript.LIB_PATH) as AnimationLibrary
		)

	for library_name: StringName in anim_player.get_animation_library_list():
		if library_name == HorseAnimConfigScript.LIBRARY:
			continue
		anim_player.remove_animation_library(library_name)

