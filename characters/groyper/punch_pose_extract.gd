@tool
class_name PunchPoseExtract
extends RefCounted

## Extract Meshy straight-punch FBX into punch.tres for in-editor editing.


static func extract_to_res() -> Error:
	var animation := _extract_authored_clip(PunchPoseConfig.PUNCH_SCENE)
	if animation == null:
		return ERR_CANT_CREATE

	var clip_err := ResourceSaver.save(animation, PunchPoseConfig.PUNCH_CLIP_PATH)
	if clip_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.PUNCH_CLIP_PATH, clip_err]
		)
		return clip_err

	var saved_clip := load(PunchPoseConfig.PUNCH_CLIP_PATH) as Animation
	if saved_clip == null:
		push_error("PunchPoseExtract: failed to reload %s." % PunchPoseConfig.PUNCH_CLIP_PATH)
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(PunchPoseConfig.PUNCH, saved_clip)

	var lib_err := ResourceSaver.save(library, PunchPoseConfig.OUT_PATH)
	if lib_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"PunchPoseExtract: saved %s -> %s and %s"
		% [PunchPoseConfig.PUNCH, PunchPoseConfig.PUNCH_CLIP_PATH, PunchPoseConfig.OUT_PATH]
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	var library := load(PunchPoseConfig.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"PunchPoseExtract: missing %s — run PunchPoseExtract or capture in groyper_body."
			% PunchPoseConfig.OUT_PATH
		)
		return null

	if not library.has_animation(PunchPoseConfig.PUNCH):
		var punch_animation := load(PunchPoseConfig.PUNCH_CLIP_PATH) as Animation
		if punch_animation != null:
			library.add_animation(PunchPoseConfig.PUNCH, punch_animation)

	return library


static func _extract_authored_clip(scene_path: String) -> Animation:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("PunchPoseExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	animation.resource_name = String(PunchPoseConfig.PUNCH)
	return RigAnimUtils.make_authored(animation)
