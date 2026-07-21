@tool
class_name PunchPoseExtract
extends RefCounted

## Extract Meshy punch FBXs into authored clips + punch_pose.tres for in-editor editing.


static func extract_to_res() -> Error:
	var punch_animation := _extract_authored_clip(
		PunchPoseConfig.PUNCH_SCENE,
		String(PunchPoseConfig.PUNCH)
	)
	if punch_animation == null:
		return ERR_CANT_CREATE
	_merge_existing_strike_markers(punch_animation, PunchPoseConfig.PUNCH_CLIP_PATH)
	PunchPoseConfig.ensure_strike_markers(punch_animation, PunchPoseConfig.PUNCH)

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
	_merge_existing_strike_markers(elbow_animation, PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH)
	PunchPoseConfig.ensure_strike_markers(elbow_animation, PunchPoseConfig.ELBOW_STRIKE)

	var elbow_err := ResourceSaver.save(elbow_animation, PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH)
	if elbow_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH, elbow_err]
		)
		return elbow_err

	var double_animation := _extract_authored_clip(
		PunchPoseConfig.DOUBLE_COMBO_SCENE,
		String(PunchPoseConfig.DOUBLE_COMBO)
	)
	if double_animation == null:
		return ERR_CANT_CREATE
	_merge_existing_strike_markers(double_animation, PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH)
	PunchPoseConfig.ensure_strike_markers(double_animation, PunchPoseConfig.DOUBLE_COMBO)

	var double_err := ResourceSaver.save(double_animation, PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH)
	if double_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH, double_err]
		)
		return double_err

	var saved_punch := load(PunchPoseConfig.PUNCH_CLIP_PATH) as Animation
	var saved_elbow := load(PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH) as Animation
	var saved_double := load(PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH) as Animation
	if saved_punch == null or saved_elbow == null or saved_double == null:
		push_error("PunchPoseExtract: failed to reload authored punch clips.")
		return ERR_CANT_CREATE

	PunchPoseConfig.reload_strike_timing()

	var library := AnimationLibrary.new()
	library.add_animation(PunchPoseConfig.PUNCH, saved_punch)
	library.add_animation(PunchPoseConfig.ELBOW_STRIKE, saved_elbow)
	library.add_animation(PunchPoseConfig.DOUBLE_COMBO, saved_double)

	var lib_err := ResourceSaver.save(library, PunchPoseConfig.OUT_PATH)
	if lib_err != OK:
		push_error(
			"PunchPoseExtract: failed to save %s (error %s)."
			% [PunchPoseConfig.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"PunchPoseExtract: saved %s, %s, %s -> %s"
		% [
			PunchPoseConfig.PUNCH,
			PunchPoseConfig.ELBOW_STRIKE,
			PunchPoseConfig.DOUBLE_COMBO,
			PunchPoseConfig.OUT_PATH,
		]
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
	var double_animation := _load_authored_clip(
		PunchPoseConfig.DOUBLE_COMBO_SCENE,
		PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH,
		String(PunchPoseConfig.DOUBLE_COMBO)
	)
	if punch_animation == null or elbow_animation == null or double_animation == null:
		push_error(
			"PunchPoseExtract: missing punch combo clips — run extract in groyper_body."
		)
		return null

	var library := load(PunchPoseConfig.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	for clip_name: StringName in [
		PunchPoseConfig.PUNCH,
		PunchPoseConfig.ELBOW_STRIKE,
		PunchPoseConfig.DOUBLE_COMBO,
	]:
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
	library.add_animation(PunchPoseConfig.PUNCH, punch_animation)
	library.add_animation(PunchPoseConfig.ELBOW_STRIKE, elbow_animation)
	library.add_animation(PunchPoseConfig.DOUBLE_COMBO, double_animation)
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


## Copy editor-tuned strike markers from an existing clip onto a freshly extracted one.
static func _merge_existing_strike_markers(animation: Animation, existing_path: String) -> void:
	if animation == null:
		return
	var existing := load(existing_path) as Animation
	if existing == null:
		return
	for marker_name: StringName in existing.get_marker_names():
		var marker_str := String(marker_name)
		if not (
			marker_str == String(PunchPoseConfig.MARKER_STRIKE)
			or marker_str.begins_with("strike")
		):
			continue
		var time := existing.get_marker_time(marker_name)
		if animation.has_marker(marker_name):
			animation.remove_marker(marker_name)
		animation.add_marker(marker_name, time)


## Stamp default strike markers onto on-disk clips without re-extracting bones.
static func stamp_strike_markers() -> Error:
	var specs: Array[Dictionary] = [
		{"path": PunchPoseConfig.PUNCH_CLIP_PATH, "name": PunchPoseConfig.PUNCH},
		{"path": PunchPoseConfig.ELBOW_STRIKE_CLIP_PATH, "name": PunchPoseConfig.ELBOW_STRIKE},
		{"path": PunchPoseConfig.DOUBLE_COMBO_CLIP_PATH, "name": PunchPoseConfig.DOUBLE_COMBO},
	]
	for spec: Dictionary in specs:
		var path := String(spec["path"])
		var clip_name: StringName = spec["name"]
		var animation := load(path) as Animation
		if animation == null:
			push_error("PunchPoseExtract: missing %s for strike markers." % path)
			return ERR_FILE_NOT_FOUND
		PunchPoseConfig.ensure_strike_markers(animation, clip_name)
		var err := ResourceSaver.save(animation, path)
		if err != OK:
			push_error("PunchPoseExtract: failed to stamp markers on %s (%s)." % [path, err])
			return err

	# Refresh punch_pose.tres library refs.
	var library := load(PunchPoseConfig.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()
	for spec: Dictionary in specs:
		var path := String(spec["path"])
		var clip_name: StringName = spec["name"]
		var animation := load(path) as Animation
		if library.has_animation(clip_name):
			library.remove_animation(clip_name)
		library.add_animation(clip_name, animation)
	var lib_err := ResourceSaver.save(library, PunchPoseConfig.OUT_PATH)
	if lib_err != OK:
		return lib_err

	PunchPoseConfig.reload_strike_timing()
	print("PunchPoseExtract: stamped strike markers on punch clips.")
	return OK
