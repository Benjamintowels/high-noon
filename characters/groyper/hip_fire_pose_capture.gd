@tool
class_name HipFirePoseCapture
extends Node

## Pose the skeleton in groyper_body.tscn, then toggle a capture export in the Inspector.
## Writes standalone Animation resources (same pattern as punch.tres) so HipFireAim
## clips stay editable in the AnimationPlayer.

const LIBRARY_PATH := "res://characters/groyper/hip_fire_aim.tres"
const HipFireAimPoseConfigScript := preload("res://characters/groyper/hip_fire_aim_pose_config.gd")

@export var capture_neutral_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture(HipFireAimPoseConfigScript.POSE_NAME_NEUTRAL)
		capture_neutral_pose = false

@export var capture_ads_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture(HipFireAimPoseConfigScript.POSE_NAME_ADS)
		capture_ads_pose = false


func _capture(pose_name: StringName) -> void:
	var body := get_parent()
	if body == null:
		push_error("HipFirePoseCapture: parent must be Body.")
		return

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("HipFirePoseCapture: missing Skeleton3D or AnimationPlayer on Body.")
		return

	if animation_player.root_node != NodePath(".."):
		push_warning(
			"HipFirePoseCapture: AnimationPlayer root_node should be '..' (Body). "
			+ "Current: %s" % str(animation_player.root_node)
		)

	var anim_path := HipFireAimPoseConfigScript.get_pose_resource_path(pose_name)
	var animation := _build_pose_animation(skeleton)
	animation.resource_path = anim_path

	var err := ResourceSaver.save(animation, anim_path)
	if err != OK:
		push_error("HipFirePoseCapture: failed to save %s (error %s)." % [anim_path, err])
		return

	# Keep the AnimationLibrary pointing at the external Animation file.
	var library := load(LIBRARY_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()
	if library.has_animation(pose_name):
		library.remove_animation(pose_name)
	library.add_animation(pose_name, animation)
	err = ResourceSaver.save(library, LIBRARY_PATH)
	if err != OK:
		push_error("HipFirePoseCapture: failed to save %s (error %s)." % [LIBRARY_PATH, err])
		return

	if not animation_player.has_animation_library(HipFireAimPoseConfigScript.LIBRARY_NAME):
		animation_player.add_animation_library(HipFireAimPoseConfigScript.LIBRARY_NAME, library)
	else:
		var existing := animation_player.get_animation_library(HipFireAimPoseConfigScript.LIBRARY_NAME)
		if existing.has_animation(pose_name):
			existing.remove_animation(pose_name)
		# Same instance as the saved ExtResource — editor edits write through.
		existing.add_animation(pose_name, animation)

	print(
		"HipFirePoseCapture: saved %s (%d bone tracks) to %s"
		% [pose_name, animation.get_track_count(), anim_path]
	)


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in HipFireAimPoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("HipFirePoseCapture: bone '%s' not found." % bone_name)
			continue

		var rot_track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(rot_track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(
			rot_track, 0.0, skeleton.get_bone_pose_rotation(bone_id)
		)

		var pos_track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(pos_track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(
			pos_track, 0.0, skeleton.get_bone_pose_position(bone_id)
		)

	return animation
