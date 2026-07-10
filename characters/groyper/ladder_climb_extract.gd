@tool
class_name LadderClimbExtract
extends RefCounted

const LadderClimbConfigScript := preload("res://characters/groyper/ladder_climb_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var climb_loop := _extract_merged_clip(
		LadderClimbConfigScript.MESHY_CLIMB_LOOP,
		Animation.LOOP_LINEAR
	)
	if climb_loop == null:
		return ERR_CANT_CREATE

	var climb_finish := _extract_merged_clip(
		LadderClimbConfigScript.MESHY_CLIMB_FINISH,
		Animation.LOOP_NONE
	)
	if climb_finish == null:
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(LadderClimbConfigScript.CLIMB_LOOP, climb_loop)
	library.add_animation(LadderClimbConfigScript.CLIMB_FINISH, climb_finish)

	var lib_err := ResourceSaver.save(library, LadderClimbConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"LadderClimbExtract: failed to save %s (error %s)."
			% [LadderClimbConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"LadderClimbExtract: saved ladder_climb_loop/ladder_climb_finish -> %s"
		% LadderClimbConfigScript.OUT_PATH
	)
	return OK


static func _extract_merged_clip(meshy_clip: StringName, loop_mode: Animation.LoopMode) -> Animation:
	var raw := _load_merged_clip(meshy_clip)
	if raw == null:
		push_error(
			"LadderClimbExtract: failed to load '%s' from %s."
			% [meshy_clip, LadderClimbConfigScript.CLIMB_MERGED_SCENE]
		)
		return null

	var animation := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(animation)
	animation.loop_mode = loop_mode
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
			LadderClimbConfigScript.CLIMB_MERGED_SCENE,
			candidate
		)
		if raw != null:
			return raw
	return null


static func load_authored_library() -> AnimationLibrary:
	var library := load(LadderClimbConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"LadderClimbExtract: missing %s — run extract first."
			% LadderClimbConfigScript.OUT_PATH
		)
		return null
	return library
