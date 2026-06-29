@tool
class_name CoverPoseExtract
extends RefCounted

const CoverPoseConfigScript := preload("res://characters/groyper/cover_pose_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var roll_animation := _extract_roll_clip()
	if roll_animation == null:
		return ERR_CANT_CREATE

	var crouch_pose := RigAnimUtilsScript.extract_pose_at_time(roll_animation, roll_animation.length)
	crouch_pose.loop_mode = Animation.LOOP_LINEAR

	var library := AnimationLibrary.new()
	library.add_animation(CoverPoseConfigScript.ROLL_BEHIND_COVER, roll_animation)
	library.add_animation(CoverPoseConfigScript.CROUCH_COVER, crouch_pose)

	var err := ResourceSaver.save(library, CoverPoseConfigScript.OUT_PATH)
	if err != OK:
		push_error(
			"CoverPoseExtract: failed to save %s (error %s)."
			% [CoverPoseConfigScript.OUT_PATH, err]
		)
		return err

	var peek_err := save_cover_peek_library_from_crouch(crouch_pose)
	if peek_err != OK:
		return peek_err

	print(
		"CoverPoseExtract: saved roll_behind_cover + crouch_cover -> %s, cover_peek_aim -> %s"
		% [CoverPoseConfigScript.OUT_PATH, CoverPoseConfigScript.COVER_PEEK_OUT_PATH]
	)
	return OK


static func save_cover_peek_library_from_crouch(crouch_pose: Animation) -> Error:
	var peek_pose := duplicate_pose_clip(crouch_pose)
	var library := AnimationLibrary.new()
	library.add_animation(CoverPoseConfigScript.COVER_PEEK_AIM, peek_pose)
	var err := ResourceSaver.save(library, CoverPoseConfigScript.COVER_PEEK_OUT_PATH)
	if err != OK:
		push_error(
			"CoverPoseExtract: failed to save %s (error %s)."
			% [CoverPoseConfigScript.COVER_PEEK_OUT_PATH, err]
		)
	return err


static func duplicate_pose_clip(source: Animation) -> Animation:
	var animation := source.duplicate(true) as Animation
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR
	return animation


static func load_authored_library() -> AnimationLibrary:
	return load(CoverPoseConfigScript.OUT_PATH) as AnimationLibrary


static func load_cover_peek_library() -> AnimationLibrary:
	var library := load(CoverPoseConfigScript.COVER_PEEK_OUT_PATH) as AnimationLibrary
	if library != null:
		return library

	var cover_library := load_authored_library()
	if cover_library == null or not cover_library.has_animation(CoverPoseConfigScript.CROUCH_COVER):
		return null

	save_cover_peek_library_from_crouch(cover_library.get_animation(CoverPoseConfigScript.CROUCH_COVER))
	return load(CoverPoseConfigScript.COVER_PEEK_OUT_PATH) as AnimationLibrary


static func _extract_roll_clip() -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(CoverPoseConfigScript.ROLL_BEHIND_COVER_SCENE)
	if raw == null:
		push_error("CoverPoseExtract: failed to load roll behind cover FBX.")
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtilsScript.make_authored(animation)
