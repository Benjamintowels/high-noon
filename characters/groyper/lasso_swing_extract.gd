@tool
class_name LassoSwingExtract
extends RefCounted

const LassoSwingConfigScript := preload("res://characters/groyper/lasso_swing_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var swing_animation := _extract_authored_clip(LassoSwingConfigScript.SWING_SCENE, Animation.LOOP_NONE)
	if swing_animation == null:
		return ERR_CANT_CREATE

	var fall_animation := _extract_authored_clip(LassoSwingConfigScript.FALL_SCENE, Animation.LOOP_LINEAR)
	if fall_animation == null:
		return ERR_CANT_CREATE

	var land_animation := _extract_authored_clip(LassoSwingConfigScript.LAND_SCENE, Animation.LOOP_NONE)
	if land_animation == null:
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(LassoSwingConfigScript.SWING, swing_animation)
	library.add_animation(LassoSwingConfigScript.FALL, fall_animation)
	library.add_animation(LassoSwingConfigScript.LAND, land_animation)

	var lib_err := ResourceSaver.save(library, LassoSwingConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"LassoSwingExtract: failed to save %s (error %s)."
			% [LassoSwingConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print("LassoSwingExtract: saved swing/fall/land -> %s" % LassoSwingConfigScript.OUT_PATH)
	return OK


static func _extract_authored_clip(scene_path: String, loop_mode: Animation.LoopMode) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("LassoSwingExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
	return RigAnimUtilsScript.make_authored(animation)


static func load_authored_library() -> AnimationLibrary:
	var library := load(LassoSwingConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"LassoSwingExtract: missing %s — run extract first."
			% LassoSwingConfigScript.OUT_PATH
		)
		return null
	return library
