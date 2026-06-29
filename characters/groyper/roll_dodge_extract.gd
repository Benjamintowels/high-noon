@tool
class_name RollDodgeExtract
extends RefCounted

## Extract Meshy roll FBX clips into local authored resources for in-editor editing.
## run_roll is saved to its own run_roll.tres so bone keys are fully editable.
## Re-run from the editor via RollDodgeExtractNode or headless CLI.


static func extract_to_res() -> Error:
	var walk_animation := _extract_authored_clip(RollDodgeConfig.WALK_ROLL_SCENE)
	if walk_animation == null:
		return ERR_CANT_CREATE

	var run_animation := _extract_authored_clip(RollDodgeConfig.RUN_ROLL_SCENE)
	if run_animation == null:
		return ERR_CANT_CREATE

	var run_err := ResourceSaver.save(run_animation, RollDodgeConfig.RUN_ROLL_OUT_PATH)
	if run_err != OK:
		push_error(
			"RollDodgeExtract: failed to save %s (error %s)."
			% [RollDodgeConfig.RUN_ROLL_OUT_PATH, run_err]
		)
		return run_err

	var saved_run := load(RollDodgeConfig.RUN_ROLL_OUT_PATH) as Animation
	if saved_run == null:
		push_error("RollDodgeExtract: failed to reload %s." % RollDodgeConfig.RUN_ROLL_OUT_PATH)
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(RollDodgeConfig.WALK_ROLL, walk_animation)
	library.add_animation(RollDodgeConfig.RUN_ROLL, saved_run)

	var lib_err := ResourceSaver.save(library, RollDodgeConfig.OUT_PATH)
	if lib_err != OK:
		push_error(
			"RollDodgeExtract: failed to save %s (error %s)."
			% [RollDodgeConfig.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"RollDodgeExtract: saved walk_roll -> %s, run_roll -> %s"
		% [RollDodgeConfig.OUT_PATH, RollDodgeConfig.RUN_ROLL_OUT_PATH]
	)
	return OK


static func extract_run_roll_only() -> Error:
	var run_animation := _extract_authored_clip(RollDodgeConfig.RUN_ROLL_SCENE)
	if run_animation == null:
		return ERR_CANT_CREATE

	var err := ResourceSaver.save(run_animation, RollDodgeConfig.RUN_ROLL_OUT_PATH)
	if err != OK:
		push_error(
			"RollDodgeExtract: failed to save %s (error %s)."
			% [RollDodgeConfig.RUN_ROLL_OUT_PATH, err]
		)
		return err

	print("RollDodgeExtract: refreshed run_roll -> %s" % RollDodgeConfig.RUN_ROLL_OUT_PATH)
	return OK


static func _extract_authored_clip(scene_path: String) -> Animation:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("RollDodgeExtract: failed to load clip from %s." % scene_path)
		return null

	var animation := RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE
	return RigAnimUtils.make_authored(animation)


static func load_authored_library() -> AnimationLibrary:
	var library := load(RollDodgeConfig.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error("RollDodgeExtract: missing %s — run extract first." % RollDodgeConfig.OUT_PATH)
		return null

	if not library.has_animation(RollDodgeConfig.RUN_ROLL):
		var run_animation := load(RollDodgeConfig.RUN_ROLL_OUT_PATH) as Animation
		if run_animation != null:
			library.add_animation(RollDodgeConfig.RUN_ROLL, run_animation)

	return library
