class_name HorseAnimUtils
extends RefCounted

const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")
const HorseAnimConfigScript := preload("res://characters/animals/horse_anim_config.gd")


static func load_clip(
	source_clip: StringName,
	loop_mode: Animation.LoopMode,
	strip_root_motion: bool = true
) -> Animation:
	var raw: Animation = RigAnimUtilsScript.load_skeleton_animation(
		HorseAnimConfigScript.RIGGED_FBX_SCENE,
		source_clip
	)
	if raw == null:
		push_error(
			"HorseAnimUtils: failed to load '%s' from '%s'."
			% [source_clip, HorseAnimConfigScript.RIGGED_FBX_SCENE]
		)
		return null

	var animation: Animation = RigAnimUtilsScript.prepare_for_body_player(raw, false)
	if strip_root_motion:
		RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	if loop_mode == Animation.LOOP_LINEAR:
		RigAnimUtilsScript.seal_loop_endpoints(animation)
	return duplicate_for_editing(animation)


static func duplicate_for_editing(animation: Animation) -> Animation:
	if animation == null:
		return null
	var copy: Animation = animation.duplicate(true)
	copy.resource_name = animation.resource_name
	for track_idx in copy.get_track_count():
		copy.track_set_imported(track_idx, false)
	return copy


static func library_needs_localization(library: AnimationLibrary) -> bool:
	if library == null:
		return false
	for anim_name: String in library.get_animation_list():
		var animation: Animation = library.get_animation(anim_name)
		if animation != null and not animation.resource_path.is_empty():
			return true
	return false


static func localize_library_for_editing(library: AnimationLibrary) -> AnimationLibrary:
	var localized := AnimationLibrary.new()
	if library == null:
		return localized
	for anim_name: String in library.get_animation_list():
		var animation: Animation = library.get_animation(anim_name)
		if animation == null:
			continue
		localized.add_animation(anim_name, duplicate_for_editing(animation))
	return localized


static func export_library_to_disk(library: AnimationLibrary) -> bool:
	if library == null:
		return false

	DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(HorseAnimConfigScript.OUT_DIR)
	)

	var clips := {
		HorseAnimConfigScript.IDLE_PATH: HorseAnimConfigScript.BOW_CLIP,
		HorseAnimConfigScript.WALK_PATH: HorseAnimConfigScript.WALK_CLIP,
		HorseAnimConfigScript.RUN_PATH: HorseAnimConfigScript.RUN_CLIP,
		HorseAnimConfigScript.BOW_PATH: HorseAnimConfigScript.BOW_CLIP,
	}
	for path: String in clips:
		var clip_name: StringName = clips[path]
		if not library.has_animation(String(clip_name)):
			push_error("HorseAnimUtils: missing '%s' in horse library." % clip_name)
			return false
		var animation: Animation = duplicate_for_editing(library.get_animation(String(clip_name)))
		animation.resource_name = String(clip_name)
		var err := ResourceSaver.save(animation, path)
		if err != OK:
			push_error("HorseAnimUtils: failed to save %s (error %s)." % [path, err])
			return false

	var exported := AnimationLibrary.new()
	exported.add_animation(
		String(HorseAnimConfigScript.IDLE_CLIP),
		load(HorseAnimConfigScript.IDLE_PATH)
	)
	exported.add_animation(
		String(HorseAnimConfigScript.WALK_CLIP),
		load(HorseAnimConfigScript.WALK_PATH)
	)
	exported.add_animation(
		String(HorseAnimConfigScript.RUN_CLIP),
		load(HorseAnimConfigScript.RUN_PATH)
	)
	exported.add_animation(
		String(HorseAnimConfigScript.BOW_CLIP),
		load(HorseAnimConfigScript.BOW_PATH)
	)
	var lib_err := ResourceSaver.save(exported, HorseAnimConfigScript.LIB_PATH)
	if lib_err != OK:
		push_error(
			"HorseAnimUtils: failed to save %s (error %s)."
			% [HorseAnimConfigScript.LIB_PATH, lib_err]
		)
		return false

	print("HorseAnimUtils: exported horse library -> ", HorseAnimConfigScript.LIB_PATH)
	return true


static func bake_library(save_to_disk: bool = true) -> AnimationLibrary:
	var walk := load_clip(HorseAnimConfigScript.WALK_SOURCE_CLIP, Animation.LOOP_LINEAR)
	var bow := load_clip(HorseAnimConfigScript.BOW_SOURCE_CLIP, Animation.LOOP_NONE)
	if walk == null or bow == null:
		return null

	var idle := RigAnimUtilsScript.extract_pose_at_time(walk, 0.0)
	idle.loop_mode = Animation.LOOP_LINEAR
	idle = duplicate_for_editing(idle)

	walk.resource_name = String(HorseAnimConfigScript.WALK_CLIP)
	bow.resource_name = String(HorseAnimConfigScript.BOW_CLIP)
	idle.resource_name = String(HorseAnimConfigScript.IDLE_CLIP)

	if save_to_disk:
		DirAccess.make_dir_recursive_absolute(
			ProjectSettings.globalize_path(HorseAnimConfigScript.OUT_DIR)
		)
		var paths := {
			HorseAnimConfigScript.IDLE_PATH: idle,
			HorseAnimConfigScript.WALK_PATH: walk,
			HorseAnimConfigScript.BOW_PATH: bow,
		}
		for path: String in paths:
			var err := ResourceSaver.save(paths[path], path)
			if err != OK:
				push_error("HorseAnimUtils: failed to save %s (error %s)." % [path, err])
				return null

	var library := AnimationLibrary.new()
	library.add_animation(
		String(HorseAnimConfigScript.IDLE_CLIP),
		load(HorseAnimConfigScript.IDLE_PATH) if save_to_disk else idle
	)
	library.add_animation(
		String(HorseAnimConfigScript.WALK_CLIP),
		load(HorseAnimConfigScript.WALK_PATH) if save_to_disk else walk
	)
	library.add_animation(
		String(HorseAnimConfigScript.BOW_CLIP),
		load(HorseAnimConfigScript.BOW_PATH) if save_to_disk else bow
	)

	if save_to_disk:
		var lib_err := ResourceSaver.save(library, HorseAnimConfigScript.LIB_PATH)
		if lib_err != OK:
			push_error(
				"HorseAnimUtils: failed to save %s (error %s)."
				% [HorseAnimConfigScript.LIB_PATH, lib_err]
			)
			return null
		print("HorseAnimUtils: baked horse animation library -> ", HorseAnimConfigScript.LIB_PATH)

	return localize_library_for_editing(library)


static func load_authored_library() -> AnimationLibrary:
	if not ResourceLoader.exists(HorseAnimConfigScript.LIB_PATH):
		return null
	var library: AnimationLibrary = load(HorseAnimConfigScript.LIB_PATH)
	return library


static func ensure_library(player: AnimationPlayer) -> bool:
	if player == null:
		return false

	if player.has_animation_library(HorseAnimConfigScript.LIBRARY):
		var existing: AnimationLibrary = player.get_animation_library(HorseAnimConfigScript.LIBRARY)
		if existing != null and not library_needs_localization(existing):
			if (
				existing.has_animation(String(HorseAnimConfigScript.WALK_CLIP))
				and existing.has_animation(String(HorseAnimConfigScript.RUN_CLIP))
				and existing.has_animation(String(HorseAnimConfigScript.BOW_CLIP))
			):
				return true
		player.remove_animation_library(HorseAnimConfigScript.LIBRARY)

	var library := load_authored_library()
	if library == null:
		library = bake_library(true)
	if library == null:
		return false

	player.add_animation_library(
		HorseAnimConfigScript.LIBRARY,
		localize_library_for_editing(library)
	)
	return true
