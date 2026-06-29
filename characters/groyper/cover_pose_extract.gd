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

	print(
		"CoverPoseExtract: saved roll_behind_cover + crouch_cover -> %s"
		% CoverPoseConfigScript.OUT_PATH
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	return load(CoverPoseConfigScript.OUT_PATH) as AnimationLibrary


static func _extract_roll_clip() -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(CoverPoseConfigScript.ROLL_BEHIND_COVER_SCENE)
	if raw == null:
		push_error("CoverPoseExtract: failed to load roll behind cover FBX.")
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtilsScript.make_authored(animation)
