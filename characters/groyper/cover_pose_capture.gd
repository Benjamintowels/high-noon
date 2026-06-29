@tool
class_name CoverPoseCapture
extends Node

## Pose the skeleton in groyper_body.tscn, then enable a capture toggle in the Inspector.
## Writes clips to cover_pose.tres (same workflow as SaddlePoseCapture).

const CoverPoseConfigScript := preload("res://characters/groyper/cover_pose_config.gd")

@export var capture_crouch_cover_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture_pose(
			CoverPoseConfigScript.CROUCH_COVER,
			CoverPoseConfigScript.LIBRARY_NAME,
			CoverPoseConfigScript.OUT_PATH,
			CoverPoseConfigScript.AUTHORING_BONES,
			CoverPoseConfigScript.AUTHORING_POSITION_BONES
		)
		capture_crouch_cover_pose = false

@export var capture_cover_peek_aim_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture_pose(
			CoverPoseConfigScript.COVER_PEEK_AIM,
			CoverPoseConfigScript.COVER_PEEK_LIBRARY_NAME,
			CoverPoseConfigScript.COVER_PEEK_OUT_PATH,
			CoverPoseConfigScript.AUTHORING_BONES,
			CoverPoseConfigScript.AUTHORING_POSITION_BONES
		)
		capture_cover_peek_aim_pose = false


func _capture_pose(
	animation_name: StringName,
	library_name: StringName,
	out_path: String,
	rotation_bones: Array[String],
	position_bones: Array[String]
) -> void:
	var body := get_parent()
	if body == null:
		push_error("CoverPoseCapture: parent must be Body.")
		return

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("CoverPoseCapture: missing Skeleton3D or AnimationPlayer on Body.")
		return

	var animation := _build_pose_animation(skeleton, rotation_bones, position_bones)
	var library := load(out_path) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	if library.has_animation(animation_name):
		library.remove_animation(animation_name)
	library.add_animation(animation_name, animation)

	if not animation_player.has_animation_library(library_name):
		animation_player.add_animation_library(library_name, library)
	else:
		var existing := animation_player.get_animation_library(library_name)
		if existing.has_animation(animation_name):
			existing.remove_animation(animation_name)
		existing.add_animation(animation_name, animation.duplicate(true))

	var err := ResourceSaver.save(library, out_path)
	if err != OK:
		push_error("CoverPoseCapture: failed to save %s (error %s)." % [out_path, err])
		return

	print(
		"CoverPoseCapture: saved %d tracks to %s/%s. "
		+ "Revert any Skeleton3D bone overrides in groyper_body.tscn before saving the scene."
		% [
			animation.get_track_count(),
			out_path,
			animation_name,
		]
	)


func _build_pose_animation(
	skeleton: Skeleton3D,
	rotation_bones: Array[String],
	position_bones: Array[String]
) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in rotation_bones:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(track, 0.0, skeleton.get_bone_pose_rotation(bone_id))

	for bone_name: String in position_bones:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("CoverPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(track, 0.0, skeleton.get_bone_pose_position(bone_id))

	return animation
