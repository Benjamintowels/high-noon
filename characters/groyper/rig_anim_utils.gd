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


## Duplicate an imported clip so bone keys can be edited and saved in a local .tres.
static func make_authored(animation: Animation) -> Animation:
	var authored := animation.duplicate(true)
	authored.resource_name = ""
	for track_idx in range(authored.get_track_count()):
		authored.track_set_imported(track_idx, false)
	return authored


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


static func make_reversed_animation(source: Animation) -> Animation:
	var reversed := source.duplicate(true)
	reversed.resource_name = ""
	var duration := source.length

	for track_idx in reversed.get_track_count():
		var key_count: int = reversed.track_get_key_count(track_idx)
		if key_count <= 0:
			continue

		var reversed_keys: Array = []
		for key_idx in key_count:
			var source_time: float = reversed.track_get_key_time(track_idx, key_idx)
			var mapped_time: float = duration - source_time
			# Loop seam keys land on both 0 and length — keep the 0-side key only.
			if mapped_time >= duration - 0.00001:
				continue
			reversed_keys.append({
				"time": mapped_time,
				"value": reversed.track_get_key_value(track_idx, key_idx),
				"transition": reversed.track_get_key_transition(track_idx, key_idx),
			})
		reversed_keys.sort_custom(func(a, b): return a.time < b.time)

		for key_idx in range(key_count - 1, -1, -1):
			reversed.track_remove_key(track_idx, key_idx)

		var last_time := -1.0
		for key in reversed_keys:
			var key_time: float = key.time
			if key_time - last_time <= 0.00001:
				continue
			var new_key_idx: int = reversed.track_insert_key(track_idx, key_time, key.value)
			reversed.track_set_key_transition(track_idx, new_key_idx, key.transition)
			last_time = key_time

	for track_idx in reversed.get_track_count():
		reversed.track_set_imported(track_idx, false)

	seal_loop_endpoints(reversed)
	return reversed


static func seal_loop_endpoints(animation: Animation, time_epsilon: float = 0.00001) -> void:
	var duration := animation.length
	for track_idx in animation.get_track_count():
		var key_count: int = animation.track_get_key_count(track_idx)
		if key_count <= 0:
			continue

		var keys: Array = []
		for key_idx in key_count:
			var key_time := animation.track_get_key_time(track_idx, key_idx)
			if key_time >= duration - time_epsilon:
				continue
			keys.append({
				"time": key_time,
				"value": animation.track_get_key_value(track_idx, key_idx),
				"transition": animation.track_get_key_transition(track_idx, key_idx),
			})

		keys.sort_custom(func(a, b): return a.time < b.time)

		for key_idx in range(key_count - 1, -1, -1):
			animation.track_remove_key(track_idx, key_idx)

		var last_time := -1.0
		for key in keys:
			var key_time: float = key.time
			if key_time - last_time <= time_epsilon:
				continue
			var new_key_idx: int = animation.track_insert_key(track_idx, key_time, key.value)
			animation.track_set_key_transition(track_idx, new_key_idx, key.transition)
			last_time = key_time


static func extract_pose_at_time(source: Animation, sample_time: float) -> Animation:
	var sample := clampf(sample_time, 0.0, maxf(source.length - 0.0001, 0.0))
	var pose := Animation.new()
	pose.length = 1.0
	pose.loop_mode = Animation.LOOP_LINEAR

	for track_idx in source.get_track_count():
		var track_type := source.track_get_type(track_idx)
		var key_count := source.track_get_key_count(track_idx)
		if key_count <= 0:
			continue

		var key_idx := source.track_find_key(track_idx, sample, Animation.FIND_MODE_APPROX)
		key_idx = clampi(key_idx, 0, key_count - 1)

		var new_idx := pose.add_track(track_type)
		pose.track_set_path(new_idx, source.track_get_path(track_idx))
		pose.track_set_interpolation_type(new_idx, Animation.INTERPOLATION_LINEAR)
		pose.track_set_imported(new_idx, false)

		match track_type:
			Animation.TYPE_ROTATION_3D:
				var rotation: Quaternion = source.track_get_key_value(track_idx, key_idx)
				pose.rotation_track_insert_key(new_idx, 0.0, rotation)
			Animation.TYPE_POSITION_3D:
				var position: Vector3 = source.track_get_key_value(track_idx, key_idx)
				pose.position_track_insert_key(new_idx, 0.0, position)
			Animation.TYPE_SCALE_3D:
				var scale: Vector3 = source.track_get_key_value(track_idx, key_idx)
				pose.scale_track_insert_key(new_idx, 0.0, scale)
			Animation.TYPE_BLEND_SHAPE:
				var value: float = source.track_get_key_value(track_idx, key_idx)
				pose.blend_shape_track_insert_key(new_idx, 0.0, value)

	return make_authored(pose)
