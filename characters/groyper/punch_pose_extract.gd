@tool
class_name PunchPoseExtract
extends RefCounted

## Extract Meshy right-upper-hook FBX into punch.tres for in-editor editing.


static func extract_to_res() -> Error:
	var punch_animation := _extract_authored_clip(
		PunchPoseConfig.PUNCH_SCENE,
		String(PunchPoseConfig.PUNCH)
	)
	if punch_animation == null:
		return ERR_CANT_CREATE

	var punch_err := ResourceSaver.save(punch_animation, PunchPoseConfig.PUNCH_CLIP_PATH)
	if punch_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.PUNCH_CLIP_PATH, punch_err]
		)
		return punch_err

	var elbow_animation := _extract_authored_clip(
		PunchPoseConfig.ELBOW_STRIKE_SCENE,
		String(PunchPoseConfig.ELBOW_STRIKE)
	)
	if elbow_animation == null:
		return ERR_CANT_CREATE

	var elbow_err := ResourceSaver.save(elbow_animation, PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH)
	if elbow_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH, elbow_err]
		)
		return elbow_err

	var saved_punch := load(PunchPoseConfig.PUNCH_CLIP_PATH) as Animation
	var saved_elbow := load(PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH) as Animation
	if saved_punch == null or saved_elbow == null:
		push_error("PunchPoseExtract: failed to reload authored punch clips.")
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(PunchPoseConfig.PUNCH, saved_punch)
	library.add_animation(PunchPoseConfig.ELBOW_STRIKE, saved_elbow)

	var lib_err := ResourceSaver.save(library, PunchPoseConfig.OUT_PATH)
	if lib_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"PunchPoseExtract: saved %s, %s -> %s"
		% [PunchPoseConfig.PUNCH, PunchPoseConfig.ELBOW_STRIKE, PunchPoseConfig.OUT_PATH]
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	var punch_animation := _load_authored_clip(
		PunchPoseConfig.PUNCH_SCENE,
		PunchPoseConfig.PUNCH_CLIP_PATH,
		String(PunchPoseConfig.PUNCH)
	)
	var elbow_animation := _load_authored_clip(
		PunchPoseConfig.ELBOW_STRIKE_SCENE,
		PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH,
		String(PunchPoseConfig.ELBOW_STRIKE)
	)
	if punch_animation == null or elbow_animation == null:
		push_error(
			"PunchPoseExtract: missing punch combo clips — run extract in groyper_body."
		)
		return null

	var library := load(PunchPoseConfig.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	for clip_name: StringName in [PunchPoseConfig.PUNCH, PunchPoseConfig.ELBOW_STRIKE]:
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
	library.add_animation(PunchPoseConfig.PUNCH, punch_animation)
	library.add_animation(PunchPoseConfig.ELBOW_STRIKE, elbow_animation)
	return library


static func _load_authored_clip(
	scene_path: String,
	clip_path: String,
	clip_name: String
) -> Animation:
	var animation := _extract_authored_clip(scene_path, clip_name)
	if animation == null:
		animation = load(clip_path) as Animation
	return animation


static func _extract_authored_clip(scene_path: String, clip_name: String = "") -> Animation:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("PunchPoseExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	if not clip_name.is_empty():
		animation.resource_name = clip_name
	return RigAnimUtils.make_authored(animation)
