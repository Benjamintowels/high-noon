@tool
class_name SaddlePoseCapture
extends Node

## Pose the skeleton in groyper_body.tscn, then enable capture_saddle_pose in the Inspector.

const OUT_PATH := "res://characters/groyper/saddle.tres"
const SaddlePoseConfigScript := preload("res://characters/groyper/saddle_pose_config.gd")

@export var capture_saddle_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture()
		capture_saddle_pose = false


func _capture() -> void:
	var body := get_parent()
	if body == null:
		push_error("SaddlePoseCapture: parent must be Body.")
		return

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("SaddlePoseCapture: missing Skeleton3D or AnimationPlayer on Body.")
		return

	var animation := _build_pose_animation(skeleton)
	var library := load(OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()

	if library.has_animation(SaddlePoseConfigScript.POSE_NAME):
		library.remove_animation(SaddlePoseConfigScript.POSE_NAME)
	library.add_animation(SaddlePoseConfigScript.POSE_NAME, animation)

	if not animation_player.has_animation_library(SaddlePoseConfigScript.LIBRARY_NAME):
		animation_player.add_animation_library(SaddlePoseConfigScript.LIBRARY_NAME, library)
	else:
		var existing := animation_player.get_animation_library(SaddlePoseConfigScript.LIBRARY_NAME)
		if existing.has_animation(SaddlePoseConfigScript.POSE_NAME):
			existing.remove_animation(SaddlePoseConfigScript.POSE_NAME)
		existing.add_animation(SaddlePoseConfigScript.POSE_NAME, animation.duplicate(true))

	var err := ResourceSaver.save(library, OUT_PATH)
	if err != OK:
		push_error("SaddlePoseCapture: failed to save %s (error %s)." % [OUT_PATH, err])
		return

	print(
		"SaddlePoseCapture: saved %d tracks to %s. "
		+ "Revert any Skeleton3D bone overrides in groyper_body.tscn before saving the scene."
		% [animation.get_track_count(), OUT_PATH]
	)


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in SaddlePoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("SaddlePoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(track, 0.0, skeleton.get_bone_pose_rotation(bone_id))

	for bone_name: String in SaddlePoseConfigScript.AUTHORING_POSITION_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("SaddlePoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(track, 0.0, skeleton.get_bone_pose_position(bone_id))

	return animation
