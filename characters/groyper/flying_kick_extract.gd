@tool
class_name FlyingKickExtract
extends RefCounted

const FlyingKickConfigScript := preload("res://characters/groyper/flying_kick_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var raw := RigAnimUtilsScript.load_skeleton_animation(FlyingKickConfigScript.KICK_SCENE)
	if raw == null:
		push_error(
			"FlyingKickExtract: failed to load clip from %s." % FlyingKickConfigScript.KICK_SCENE
		)
		return ERR_CANT_CREATE

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	animation = RigAnimUtilsScript.make_authored(animation)

	var library := AnimationLibrary.new()
	library.add_animation(FlyingKickConfigScript.KICK, animation)

	var lib_err := ResourceSaver.save(library, FlyingKickConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"FlyingKickExtract: failed to save %s (error %s)."
			% [FlyingKickConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"FlyingKickExtract: saved %s -> %s"
		% [FlyingKickConfigScript.KICK, FlyingKickConfigScript.OUT_PATH]
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	var library := load(FlyingKickConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"FlyingKickExtract: missing %s — run extract first."
			% FlyingKickConfigScript.OUT_PATH
		)
		return null
	return library
