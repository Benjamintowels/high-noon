@tool
class_name PunchStaggerExtract
extends RefCounted

## Extract Meshy hit-reaction FBXs into authored clips + punch_stagger.tres.

const PunchStaggerConfigScript := preload("res://characters/groyper/punch_stagger_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var library := AnimationLibrary.new()
	for spec: Dictionary in PunchStaggerConfigScript.clip_specs():
		var clip_name: StringName = spec["name"]
		var scene_path := String(spec["scene"])
		var clip_path := String(spec["path"])
		var animation := _extract_authored_clip(scene_path, String(clip_name))
		if animation == null:
			return ERR_CANT_CREATE
		var save_err := ResourceSaver.save(animation, clip_path)
		if save_err != OK:
			push_error(
				"PunchStaggerExtract: failed to save %s (error %s)." % [clip_path, save_err]
			)
			return save_err
		var saved := load(clip_path) as Animation
		if saved == null:
			push_error("PunchStaggerExtract: failed to reload %s." % clip_path)
			return ERR_CANT_CREATE
		library.add_animation(clip_name, saved)

	var lib_err := ResourceSaver.save(library, PunchStaggerConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"PunchStaggerExtract: failed to save %s (error %s)."
			% [PunchStaggerConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"PunchStaggerExtract: saved punch_stagger library -> %s"
		% PunchStaggerConfigScript.OUT_PATH
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	var library := load(PunchStaggerConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"PunchStaggerExtract: missing %s — run extract in groyper_body."
			% PunchStaggerConfigScript.OUT_PATH
		)
		return null
	return library


static func _extract_authored_clip(scene_path: String, clip_name: String) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("PunchStaggerExtract: failed to load clip from %s." % scene_path)
		return null
	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	if not clip_name.is_empty():
		animation.resource_name = clip_name
	return RigAnimUtilsScript.make_authored(animation)
