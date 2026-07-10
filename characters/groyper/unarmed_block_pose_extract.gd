@tool
class_name UnarmedBlockPoseExtract
extends RefCounted

## Bootstrap unarmed_block.tres from the Meshy parry FBX (frame 0), then edit in groyper_body.

const UnarmedBlockPoseConfigScript := preload(
	"res://characters/groyper/unarmed_block_pose_config.gd"
)
const RigAnimUtilsScript := preload("res://characters/groyper/rig_anim_utils.gd")


static func extract_to_res() -> Error:
	var block_animation := _extract_authored_clip(
		UnarmedBlockPoseConfigScript.SOURCE_SCENE,
		String(UnarmedBlockPoseConfigScript.BLOCK_HOLD)
	)
	if block_animation == null:
		return ERR_CANT_CREATE

	var block_err := ResourceSaver.save(block_animation, UnarmedBlockPoseConfigScript.CLIP_PATH)
	if block_err != OK:
		push_error(
			"UnarmedBlockPoseExtract: failed to save %s (error %s)."
			% [UnarmedBlockPoseConfigScript.CLIP_PATH, block_err]
		)
		return block_err

	var saved_clip := load(UnarmedBlockPoseConfigScript.CLIP_PATH) as Animation
	if saved_clip == null:
		push_error(
			"UnarmedBlockPoseExtract: failed to reload %s."
			% UnarmedBlockPoseConfigScript.CLIP_PATH
		)
		return ERR_CANT_CREATE

	var library := AnimationLibrary.new()
	library.add_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD, saved_clip)

	var lib_err := ResourceSaver.save(library, UnarmedBlockPoseConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"UnarmedBlockPoseExtract: failed to save %s (error %s)."
			% [UnarmedBlockPoseConfigScript.OUT_PATH, lib_err]
		)
		return lib_err

	print(
		"UnarmedBlockPoseExtract: saved %s -> %s"
		% [UnarmedBlockPoseConfigScript.CLIP_PATH, UnarmedBlockPoseConfigScript.OUT_PATH]
	)
	return OK


static func load_authored_library() -> AnimationLibrary:
	var library := load(UnarmedBlockPoseConfigScript.OUT_PATH) as AnimationLibrary
	if library == null or not library.has_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD):
		push_error(
			"UnarmedBlockPoseExtract: missing %s — author in groyper_body or run extract."
			% UnarmedBlockPoseConfigScript.OUT_PATH
		)
		return null
	return library


static func _extract_authored_clip(scene_path: String, clip_name: String = "") -> Animation:
	var raw := RigAnimUtilsScript.load_skeleton_animation(scene_path)
	if raw == null:
		push_error("UnarmedBlockPoseExtract: failed to load clip from %s." % scene_path)
		return null

	var prepared := RigAnimUtilsScript.prepare_for_body_player(raw, false)
	RigAnimUtilsScript.strip_root_motion(prepared)
	var pose := RigAnimUtilsScript.extract_pose_at_time(prepared, 0.0)
	pose = _filter_to_authoring_bones(pose)
	pose.loop_mode = Animation.LOOP_LINEAR
	if not clip_name.is_empty():
		pose.resource_name = clip_name
	return RigAnimUtilsScript.make_authored(pose)


static func _filter_to_authoring_bones(animation: Animation) -> Animation:
	var filtered := Animation.new()
	filtered.length = animation.length
	filtered.loop_mode = animation.loop_mode
	filtered.resource_name = animation.resource_name

	for track_idx in animation.get_track_count():
		var path := String(animation.track_get_path(track_idx))
		var bone_name := path.get_slice(":", 1)
		var track_type := animation.track_get_type(track_idx)
		var is_rotation := (
			track_type == Animation.TYPE_ROTATION_3D
			and bone_name in UnarmedBlockPoseConfigScript.AUTHORING_BONES
		)
		var is_position := (
			track_type == Animation.TYPE_POSITION_3D
			and bone_name in UnarmedBlockPoseConfigScript.AUTHORING_POSITION_BONES
		)
		if not is_rotation and not is_position:
			continue

		var new_idx := filtered.add_track(track_type)
		filtered.track_set_path(new_idx, animation.track_get_path(track_idx))
		filtered.track_set_interpolation_type(new_idx, Animation.INTERPOLATION_LINEAR)
		filtered.track_set_imported(new_idx, false)

		var key_count := animation.track_get_key_count(track_idx)
		for key_idx in key_count:
			var key_time := animation.track_get_key_time(track_idx, key_idx)
			match track_type:
				Animation.TYPE_ROTATION_3D:
					var rotation: Quaternion = animation.track_get_key_value(track_idx, key_idx)
					filtered.rotation_track_insert_key(new_idx, key_time, rotation)
				Animation.TYPE_POSITION_3D:
					var position: Vector3 = animation.track_get_key_value(track_idx, key_idx)
					filtered.position_track_insert_key(new_idx, key_time, position)

	return filtered
