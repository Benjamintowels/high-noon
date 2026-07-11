@tool
class_name TwoHandedExtract
extends RefCounted

## Extracts the two-handed melee clips from the 2Handed merged FBX (and a
## duplicate of the sword & shield spin attack) into an editable AnimationLibrary
## saved at TwoHandedConfig.OUT_PATH. Mirrors the ladder_climb / flying_kick
## extraction workflow so the clips show up (and are editable) in the Groyper
## body scene's AnimationPlayer.

const TwoHandedConfigScript := preload("res://characters/groyper/two_handed_config.gd")
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var library := AnimationLibrary.new()

	var clips := [
		[TwoHandedConfigScript.CLIP_IDLE, TwoHandedConfigScript.MESHY_IDLE, Animation.LOOP_LINEAR],
		[TwoHandedConfigScript.CLIP_WALK, TwoHandedConfigScript.MESHY_WALK, Animation.LOOP_LINEAR],
		[TwoHandedConfigScript.CLIP_SPRINT, TwoHandedConfigScript.MESHY_SPRINT, Animation.LOOP_LINEAR],
		[TwoHandedConfigScript.CLIP_ATTACK, TwoHandedConfigScript.MESHY_ATTACK, Animation.LOOP_NONE],
		[TwoHandedConfigScript.CLIP_COMBO, TwoHandedConfigScript.MESHY_COMBO, Animation.LOOP_NONE],
		[TwoHandedConfigScript.CLIP_PARRY, TwoHandedConfigScript.MESHY_PARRY, Animation.LOOP_NONE],
	]

	for entry in clips:
		var clip := _extract_merged_clip(entry[1], entry[2])
		if clip == null:
			return ERR_CANT_CREATE
		library.add_animation(entry[0], clip)

	# Holding-block pose: first frame of the parry, looped so it holds.
	var parry := library.get_animation(TwoHandedConfigScript.CLIP_PARRY)
	if parry != null:
		var hold := RigAnimUtilsScript.extract_pose_at_time(parry, 0.0)
		hold.loop_mode = Animation.LOOP_LINEAR
		library.add_animation(TwoHandedConfigScript.CLIP_BLOCK_HOLD, hold)

	# Editable duplicate of the sword & shield spin attack.
	var spin := _extract_scene_clip(TwoHandedConfigScript.SPIN_ATTACK_SCENE, Animation.LOOP_NONE)
	if spin != null:
		library.add_animation(TwoHandedConfigScript.CLIP_SPIN_ATTACK, spin)

	var err := ResourceSaver.save(library, TwoHandedConfigScript.OUT_PATH)
	if err != OK:
		push_error(
			"TwoHandedExtract: failed to save %s (error %s)."
			% [TwoHandedConfigScript.OUT_PATH, err]
		)
		return err

	print("TwoHandedExtract: saved -> %s" % TwoHandedConfigScript.OUT_PATH)
	return OK


static func _extract_merged_clip(meshy_clip: StringName, loop_mode: Animation.LoopMode) -> Animation:
	var raw := _load_merged_clip(meshy_clip)
	if raw == null:
		push_error(
			"TwoHandedExtract: missing clip '%s' in %s."
			% [meshy_clip, TwoHandedConfigScript.MERGED_SCENE]
		)
		return null
	return _prepare(raw, loop_mode)


static func _extract_scene_clip(scene_path: String, loop_mode: Animation.LoopMode) -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("TwoHandedExtract: failed to load clip from %s." % scene_path)
		return null
	return _prepare(raw, loop_mode)


static func _prepare(raw: Animation, loop_mode: Animation.LoopMode) -> Animation:
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
			TwoHandedConfigScript.MERGED_SCENE,
			candidate
		)
		if raw != null:
			return raw
	return null


static func load_authored_library() -> AnimationLibrary:
	var library := load(TwoHandedConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		push_error(
			"TwoHandedExtract: missing %s — run extract first."
			% TwoHandedConfigScript.OUT_PATH
		)
		return null
	return library
