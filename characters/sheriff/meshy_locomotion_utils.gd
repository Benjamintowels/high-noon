class_name MeshyLocomotionUtils
extends RefCounted

const LOCOMOTION_BLEND := &"LocomotionBlend"

## Some Meshy imports (e.g. Sheriff) need this offset on top of the body flip to face movement.
const MODEL_YAW_OFFSET := PI

## Build idle/walk locomotion clips on a Meshy rig body and wire a 1D blend AnimationTree.


static func facing_yaw_for_direction(direction: Vector3) -> float:
	return atan2(direction.x, direction.z) + MODEL_YAW_OFFSET


static func find_body_animation_player(body: Node) -> AnimationPlayer:
	var player := body.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if player != null:
		return player
	return RigAnimUtils.find_animation_player(body)


static func setup_locomotion_library(
	animation_player: AnimationPlayer,
	idle_scene: String,
	walk_scene: String,
	library_name: StringName = SheriffAnimConfig.LOCOMOTION_LIBRARY,
	idle_clip: StringName = SheriffAnimConfig.LOCOMOTION_IDLE,
	walk_clip: StringName = SheriffAnimConfig.LOCOMOTION_WALK
) -> bool:
	if animation_player == null:
		return false

	var library := AnimationLibrary.new()
	if not _add_locomotion_clip(library, idle_clip, idle_scene, true):
		return false
	if not _add_locomotion_clip(library, walk_clip, walk_scene, false):
		return false

	if animation_player.has_animation_library(library_name):
		animation_player.remove_animation_library(library_name)
	animation_player.add_animation_library(library_name, library)
	return true


static func setup_idle_walk_animation_tree(
	animation_tree: AnimationTree,
	animation_player: AnimationPlayer,
	library_name: StringName = SheriffAnimConfig.LOCOMOTION_LIBRARY,
	idle_clip: StringName = SheriffAnimConfig.LOCOMOTION_IDLE,
	walk_clip: StringName = SheriffAnimConfig.LOCOMOTION_WALK
) -> bool:
	if animation_tree == null or animation_player == null:
		return false

	var idle_path := StringName("%s/%s" % [library_name, idle_clip])
	var walk_path := StringName("%s/%s" % [library_name, walk_clip])
	if not animation_player.has_animation(idle_path) or not animation_player.has_animation(walk_path):
		push_error("MeshyLocomotionUtils: locomotion clips missing on AnimationPlayer.")
		return false

	var idle_node := AnimationNodeAnimation.new()
	idle_node.animation = idle_path

	var walk_node := AnimationNodeAnimation.new()
	walk_node.animation = walk_path

	var blend_space := AnimationNodeBlendSpace1D.new()
	blend_space.add_blend_point(idle_node, 0.0)
	blend_space.add_blend_point(walk_node, 1.0)
	blend_space.min_space = 0.0
	blend_space.max_space = 1.0
	blend_space.snap = 0.0

	var blend_tree := AnimationNodeBlendTree.new()
	blend_tree.add_node(LOCOMOTION_BLEND, blend_space)
	blend_tree.connect_node(&"output", 0, LOCOMOTION_BLEND)

	animation_tree.tree_root = blend_tree
	animation_tree.anim_player = animation_tree.get_path_to(animation_player)
	animation_tree.process_priority = -100
	animation_tree.active = true
	return true


static func set_locomotion_blend(animation_tree: AnimationTree, blend_value: float) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/LocomotionBlend/blend_position", blend_value)


static func _add_locomotion_clip(
	library: AnimationLibrary,
	clip_name: StringName,
	scene_path: String,
	strip_aim_bones: bool = false
) -> bool:
	var raw := RigAnimUtils.load_skeleton_animation(scene_path)
	if raw == null:
		push_error(
			"MeshyLocomotionUtils: failed to load locomotion clip '%s' from %s."
			% [clip_name, scene_path]
		)
		return false

	var animation := RigAnimUtils.prepare_for_body_player(raw, strip_aim_bones)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_LINEAR
	library.add_animation(clip_name, animation)
	return true
