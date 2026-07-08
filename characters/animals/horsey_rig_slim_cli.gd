extends SceneTree

## One-shot maintainer: externalize heavy horsey_rig subresources and resave a slim scene.

const RIG_SCENE := "res://characters/animals/horsey_rig.tscn"
const MESH_PATH := "res://characters/animals/horsey_mesh.res"
const SKIN_PATH := "res://characters/animals/horsey_skin.res"

const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")
const HorseAnimUtilsScript := preload("res://characters/animals/horse_anim_utils.gd")


func _init() -> void:
	var err := slim_rig_scene()
	if err != OK:
		push_error("horsey_rig_slim_cli: failed (%s)." % error_string(err))
	quit(err)


func slim_rig_scene() -> Error:
	var packed := load(RIG_SCENE) as PackedScene
	if packed == null:
		return ERR_CANT_OPEN

	var rig_root: Node3D = packed.instantiate() as Node3D
	if rig_root == null:
		return ERR_CANT_CREATE

	var mesh_instance := rig_root.get_node_or_null("Armature/Skeleton3D/Cube_001") as MeshInstance3D
	if mesh_instance == null:
		rig_root.free()
		return ERR_DOES_NOT_EXIST

	var mesh_err := _save_external_mesh(mesh_instance)
	if mesh_err != OK:
		rig_root.free()
		return mesh_err

	var anim_player := rig_root.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player == null:
		rig_root.free()
		return ERR_DOES_NOT_EXIST

	var lib_err := _externalize_horse_library(anim_player)
	if lib_err != OK:
		rig_root.free()
		return lib_err

	_clear_imported_animation_library(anim_player)

	var out_packed := PackedScene.new()
	var pack_err := out_packed.pack(rig_root)
	rig_root.free()
	if pack_err != OK:
		return pack_err

	return ResourceSaver.save(out_packed, RIG_SCENE)


func _save_external_mesh(mesh_instance: MeshInstance3D) -> Error:
	var mesh := mesh_instance.mesh
	if mesh == null:
		return ERR_DOES_NOT_EXIST

	var mesh_copy: ArrayMesh = mesh.duplicate(true) as ArrayMesh
	if mesh_copy == null:
		return ERR_CANT_CREATE

	var mesh_err := ResourceSaver.save(mesh_copy, MESH_PATH, ResourceSaver.FLAG_COMPRESS)
	if mesh_err != OK:
		return mesh_err

	var skin := mesh_instance.skin
	if skin == null:
		return ERR_DOES_NOT_EXIST

	var skin_copy: Skin = skin.duplicate(true) as Skin
	if skin_copy == null:
		return ERR_CANT_CREATE

	var skin_err := ResourceSaver.save(skin_copy, SKIN_PATH, ResourceSaver.FLAG_COMPRESS)
	if skin_err != OK:
		return skin_err

	mesh_instance.mesh = load(MESH_PATH) as Mesh
	mesh_instance.skin = load(SKIN_PATH) as Skin
	return OK


func _externalize_horse_library(anim_player: AnimationPlayer) -> Error:
	if not anim_player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		push_error("horsey_rig_slim_cli: missing '%s' animation library." % HorseAnimConfigScript.LIBRARY)
		return ERR_DOES_NOT_EXIST

	var library: AnimationLibrary = anim_player.get_animation_library(HorseAnimConfigScript.LIBRARY)
	if not HorseAnimUtilsScript.export_library_to_disk(library):
		return ERR_CANT_CREATE

	anim_player.remove_animation_library(HorseAnimConfigScript.LIBRARY)
	anim_player.add_animation_library(
		HorseAnimConfigScript.LIBRARY,
		load(HorseAnimConfigScript.LIB_PATH) as AnimationLibrary
	)
	return OK


func _clear_imported_animation_library(anim_player: AnimationPlayer) -> void:
	for library_name: StringName in anim_player.get_animation_library_list():
		if library_name == HorseAnimConfigScript.LIBRARY:
			continue
		anim_player.remove_animation_library(library_name)
