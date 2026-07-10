@tool
class_name ClimbFallExtract
extends RefCounted

const ClimbFallConfigScript := preload("res://characters/groyper/climb_fall_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var fall_entry := _extract_authored_scene_clip(
		ClimbFallConfigScript.FALL_ENTRY_SCENE,
		Animation.LOOP_NONE
	)
	if fall_entry == null:
		return ERR_CANT_CREATE

	var fall_loop := _extract_authored_scene_clip(
		ClimbFallConfigScript.FALL_LOOP_SCENE,
		Animation.LOOP_LINEAR
	)
	if fall_loop == null:
		return ERR_CANT_CREATE

	var fall_land := _extract_merged_land_clip()
	if fall_land == null:
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(ClimbFallConfigScript.FALL_ENTRY, fall_entry)
	library.add_animation(ClimbFallConfigScript.FALL_LOOP, fall_loop)
	library.add_animation(ClimbFallConfigScript.FALL_LAND, fall_land)

	var lib_err := ResourceSaver.save(library, ClimbFallConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"ClimbFallExtract: failed to save %s (error %s)."
			% [ClimbFallConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"ClimbFallExtract: saved fall_entry/fall_loop/fall_land -> %s"
		% ClimbFallConfigScript.OUT_PATH
	)
	return OK


static func _extract_authored_scene_clip(
	scene_path: String,
	loop_mode: Animation.LoopMode
) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("ClimbFallExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	return RigAnimUtilsScript.make_authored(animation)


static func _extract_merged_land_clip() -> Animation:
	var raw := _load_merged_clip(ClimbFallConfigScript.MESHY_FALL_LAND)
	if raw == null:
		push_error(
			"ClimbFallExtract: failed to load '%s' from %s."
			% [
				ClimbFallConfigScript.MESHY_FALL_LAND,
				ClimbFallConfigScript.CLIMB_MERGED_SCENE,
			]
		)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtilsScript.make_authored(animation)


static func _load_merged_clip(meshy_clip: StringName) -> Animation:
	var candidates: Array[StringName] = [meshy_clip]
	var clip_text := String(meshy_clip)
	if not clip_text.ends_with("_frame_rate_60_fbx"):
		candidates.append(StringName("%s_frame_rate_60_fbx" % clip_text))
	if clip_text.ends_with("_frame_rate_60_fbx"):
		candidates.append(StringName(clip_text.trim_suffix("_frame_rate_60_fbx")))

	for candidate: StringName in candidates:
		var raw := RigAnimUtilsScript.load_skeleton_animation(
			ClimbFallConfigScript.CLIMB_MERGED_SCENE,
			candidate
		)
		if raw != null:
			return raw
	return null


static func load_authored_library() -> AnimationLibrary:
	var library := load(ClimbFallConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"ClimbFallExtract: missing %s — run extract first."
			% ClimbFallConfigScript.OUT_PATH
		)
		return null
	return library
