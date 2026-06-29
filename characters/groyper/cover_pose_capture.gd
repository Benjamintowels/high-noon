@tool
class_name CoverPoseCapture
extends Node

## Pose the skeleton in groyper_body.tscn, then enable capture_crouch_cover_pose in the Inspector.
## Writes only the crouch_cover clip to cover_pose.tres (same workflow as SaddlePoseCapture).

const CoverPoseConfigScript := preload("res://characters/groyper/cover_pose_config.gd")

@export var capture_crouch_cover_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture()
		capture_crouch_cover_pose = false


func _capture() -> void:
	var body := get_parent()
	if body == null:
		push_error("CoverPoseCapture: parent must be Body.")
		return

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("CoverPoseCapture: missing Skeleton3D or AnimationPlayer on Body.")
		return

	var animation := _build_pose_animation(skeleton)
	var library := load(CoverPoseConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	if library.has_animation(CoverPoseConfigScript.CROUCH_COVER):
		library.remove_animation(CoverPoseConfigScript.CROUCH_COVER)
	library.add_animation(CoverPoseConfigScript.CROUCH_COVER, animation)

	if not animation_player.has_animation_library(CoverPoseConfigScript.LIBRARY_NAME):
		animation_player.add_animation_library(CoverPoseConfigScript.LIBRARY_NAME, library)
	else:
		var existing := animation_player.get_animation_library(CoverPoseConfigScript.LIBRARY_NAME)
		if existing.has_animation(CoverPoseConfigScript.CROUCH_COVER):
			existing.remove_animation(CoverPoseConfigScript.CROUCH_COVER)
		existing.add_animation(CoverPoseConfigScript.CROUCH_COVER, animation.duplicate(true))

	var err := ResourceSaver.save(library, CoverPoseConfigScript.OUT_PATH)
	if err != OK:
		push_error("CoverPoseCapture: failed to save %s (error %s)." % [CoverPoseConfigScript.OUT_PATH, err])
		return

	print(
		"CoverPoseCapture: saved %d tracks to %s/%s. "
		+ "Revert any Skeleton3D bone overrides in groyper_body.tscn before saving the scene."
		% [
			animation.get_track_count(),
			CoverPoseConfigScript.OUT_PATH,
			CoverPoseConfigScript.CROUCH_COVER,
		]
	)


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in CoverPoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(track, 0.0, skeleton.get_bone_pose_rotation(bone_id))

	for bone_name: String in CoverPoseConfigScript.AUTHORING_POSITION_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(track, 0.0, skeleton.get_bone_pose_position(bone_id))

	return animation
