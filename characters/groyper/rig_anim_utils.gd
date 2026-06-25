class_name RigAnimUtils
extends RefCounted

const RigAnimConfigScript := preload("res://characters/groyper/rig_anim_config.gd")
const LeanPoseConfigScript := preload("res://characters/groyper/lean_pose_config.gd")

## Load skeleton clips from Meshy FBX scenes and prepare them for groyper_body's AnimationPlayer.


static func load_skeleton_animation(
	scene_path: String,
	clip_name: StringName = RigAnimConfigScript.MESHY_CLIP_NAME
) -> Animation:
	var scene: PackedScene = load(scene_path)
	if scene == null:
		push_error("RigAnimUtils: failed to load scene '%s'." % scene_path)
		return null

	var instance := scene.instantiate()
	var player := find_animation_player(instance)
	if player == null:
		instance.free()
		push_error("RigAnimUtils: no AnimationPlayer in '%s'." % scene_path)
		return null

	var resolved_name := resolve_animation_name(player, clip_name)
	if resolved_name.is_empty():
		var available := collect_animation_names(player)
		instance.free()
		push_error(
			"RigAnimUtils: no clip found in '%s' (have %s)."
			% [scene_path, available]
		)
		return null

	var animation := player.get_animation(resolved_name).duplicate(true)
	instance.free()
	return animation


static func resolve_animation_name(
	player: AnimationPlayer,
	preferred: StringName = RigAnimConfigScript.MESHY_CLIP_NAME
) -> StringName:
	if player.has_animation(preferred):
		return preferred

	for library_name: String in player.get_animation_library_list():
		var library: AnimationLibrary = player.get_animation_library(library_name)
		for animation_name: String in library.get_animation_list():
			if library_name.is_empty():
				return StringName(animation_name)
			return StringName("%s/%s" % [library_name, animation_name])

	for animation_name: String in player.get_animation_list():
		return StringName(animation_name)

	return StringName()


static func collect_animation_names(player: AnimationPlayer) -> Array[String]:
	var names: Array[String] = []
	for library_name: String in player.get_animation_library_list():
		var library: AnimationLibrary = player.get_animation_library(library_name)
		for animation_name: String in library.get_animation_list():
			if library_name.is_empty():
				names.append(animation_name)
			else:
				names.append("%s/%s" % [library_name, animation_name])
	for animation_name: String in player.get_animation_list():
		if animation_name not in names:
			names.append(animation_name)
	return names


static func find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found := find_animation_player(child)
		if found != null:
			return found
	return null


static func prepare_for_body_player(animation: Animation, strip_aim_bones: bool = true) -> Animation:
	var prepared := animation.duplicate(true)
	prepared.loop_mode = Animation.LOOP_NONE
	if strip_aim_bones:
		strip_aim_gun_tracks(prepared)
	return prepared


static func strip_root_motion(animation: Animation) -> void:
	const ROOT_BONE_NAMES := ["Hips", "Root", "mixamorig:Hips", "mixamorig:Root"]
	for track_idx in range(animation.get_track_count() - 1, -1, -1):
		if animation.track_get_type(track_idx) != Animation.TYPE_POSITION_3D:
			continue
		var path := String(animation.track_get_path(track_idx))
		for bone_name: String in ROOT_BONE_NAMES:
			if path.ends_with(":%s" % bone_name):
				animation.remove_track(track_idx)
				break


static func strip_aim_gun_tracks(animation: Animation) -> void:
	for track_idx in range(animation.get_track_count() - 1, -1, -1):
		var path := String(animation.track_get_path(track_idx))
		for bone_name: String in LeanPoseConfigScript.AIM_EXCLUDED_BONES:
			if path.ends_with(":%s" % bone_name):
				animation.remove_track(track_idx)
				break
