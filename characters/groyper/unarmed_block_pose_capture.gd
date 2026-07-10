@tool
class_name UnarmedBlockPoseCapture
extends Node

## Pose editing for groyper_body.tscn (same workflow as PunchPoseCapture).
##
## Option A — edit keyframes directly:
##   Open characters/groyper/unarmed_block.tres in the FileSystem and edit bone tracks.
##
## Option B — pose in the viewport:
##   1. Select Body → AnimationPlayer → library UnarmedBlock, clip block_hold
##   2. Toggle Begin Editing Pose (or scrub to time 0)
##   3. Rotate bones in the 3D viewport
##   4. Toggle Capture Unarmed Block Pose
##   5. Revert any Skeleton3D bone overrides on groyper_body.tscn before saving the scene

const UnarmedBlockPoseConfigScript := preload(
	"res://characters/groyper/unarmed_block_pose_config.gd"
)

@export var begin_editing_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_begin_editing_pose()
		begin_editing_pose = false

@export var capture_unarmed_block_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_capture()
		capture_unarmed_block_pose = false

@export var reload_unarmed_block_pose: bool = false:
	set(value):
		if not value or not Engine.is_editor_hint():
			return
		_reload_pose_on_player()
		reload_unarmed_block_pose = false


func _begin_editing_pose() -> void:
	var body := _get_body()
	if body == null:
		return

	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		push_error("UnarmedBlockPoseCapture: missing AnimationPlayer on Body.")
		return

	_ensure_library_on_player(animation_player)
	var anim_path := String(UnarmedBlockPoseConfigScript.get_animation_path())
	if not animation_player.has_animation(anim_path):
		push_error("UnarmedBlockPoseCapture: missing animation %s on AnimationPlayer." % anim_path)
		return

	animation_player.stop()
	animation_player.play(anim_path)
	animation_player.seek(0.0, true)
	animation_player.advance(0)

	print(
		"UnarmedBlockPoseCapture: previewing %s at t=0. "
		+ "Pose bones in the viewport, then toggle Capture Unarmed Block Pose."
		% anim_path
	)


func _capture() -> void:
	var body := _get_body()
	if body == null:
		return

	var skeleton := body.get_node_or_null("Armature/Skeleton3D") as Skeleton3D
	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if skeleton == null or animation_player == null:
		push_error("UnarmedBlockPoseCapture: missing Skeleton3D or AnimationPlayer on Body.")
		return

	var animation := _build_pose_animation(skeleton)
	var clip_err := ResourceSaver.save(animation, UnarmedBlockPoseConfigScript.CLIP_PATH)
	if clip_err != OK:
		push_error(
			"UnarmedBlockPoseCapture: failed to save %s (error %s)."
			% [UnarmedBlockPoseConfigScript.CLIP_PATH, clip_err]
		)
		return

	var saved_clip := load(UnarmedBlockPoseConfigScript.CLIP_PATH) as Animation
	if saved_clip == null:
		push_error(
			"UnarmedBlockPoseCapture: failed to reload %s."
			% UnarmedBlockPoseConfigScript.CLIP_PATH
		)
		return

	var library := _build_library_with_clip(saved_clip)
	var lib_err := ResourceSaver.save(library, UnarmedBlockPoseConfigScript.OUT_PATH)
	if lib_err != OK:
		push_error(
			"UnarmedBlockPoseCapture: failed to save %s (error %s)."
			% [UnarmedBlockPoseConfigScript.OUT_PATH, lib_err]
		)
		return

	_sync_library_on_player(animation_player, saved_clip.duplicate(true))

	print(
		"UnarmedBlockPoseCapture: saved %d tracks to %s. "
		+ "Revert any Skeleton3D bone overrides in groyper_body.tscn before saving the scene."
		% [saved_clip.get_track_count(), UnarmedBlockPoseConfigScript.CLIP_PATH]
	)


func _reload_pose_on_player() -> void:
	var body := _get_body()
	if body == null:
		return

	var animation_player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if animation_player == null:
		return

	var saved_clip := load(UnarmedBlockPoseConfigScript.CLIP_PATH) as Animation
	if saved_clip == null:
		push_error(
			"UnarmedBlockPoseCapture: missing %s." % UnarmedBlockPoseConfigScript.CLIP_PATH
		)
		return

	_sync_library_on_player(animation_player, saved_clip.duplicate(true))
	print(
		"UnarmedBlockPoseCapture: reloaded %s onto AnimationPlayer."
		% UnarmedBlockPoseConfigScript.CLIP_PATH
	)


func _get_body() -> Node:
	var body := get_parent()
	if body == null:
		push_error("UnarmedBlockPoseCapture: parent must be Body.")
		return null
	return body


func _build_library_with_clip(animation: Animation) -> AnimationLibrary:
	var library := AnimationLibrary.new()
	library.add_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD, animation)
	return library


func _ensure_library_on_player(animation_player: AnimationPlayer) -> void:
	if animation_player.has_animation_library(UnarmedBlockPoseConfigScript.LIBRARY_NAME):
		return

	var library := load(UnarmedBlockPoseConfigScript.OUT_PATH) as AnimationLibrary
	if library == null:
		library = AnimationLibrary.new()
	animation_player.add_animation_library(UnarmedBlockPoseConfigScript.LIBRARY_NAME, library)


func _sync_library_on_player(animation_player: AnimationPlayer, animation: Animation) -> void:
	_ensure_library_on_player(animation_player)
	var library := animation_player.get_animation_library(UnarmedBlockPoseConfigScript.LIBRARY_NAME)
	if library.has_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD):
		library.remove_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD)
	library.add_animation(UnarmedBlockPoseConfigScript.BLOCK_HOLD, animation)


func _build_pose_animation(skeleton: Skeleton3D) -> Animation:
	var animation := Animation.new()
	animation.resource_name = String(UnarmedBlockPoseConfigScript.BLOCK_HOLD)
	animation.length = 1.0
	animation.loop_mode = Animation.LOOP_LINEAR

	for bone_name: String in UnarmedBlockPoseConfigScript.AUTHORING_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("UnarmedBlockPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_ROTATION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.rotation_track_insert_key(track, 0.0, skeleton.get_bone_pose_rotation(bone_id))

	for bone_name: String in UnarmedBlockPoseConfigScript.AUTHORING_POSITION_BONES:
		var bone_id := skeleton.find_bone(bone_name)
		if bone_id < 0:
			push_warning("UnarmedBlockPoseCapture: bone '%s' not found." % bone_name)
			continue

		var track := animation.add_track(Animation.TYPE_POSITION_3D)
		animation.track_set_path(track, NodePath("Armature/Skeleton3D:%s" % bone_name))
		animation.position_track_insert_key(track, 0.0, skeleton.get_bone_pose_position(bone_id))

	return animation
