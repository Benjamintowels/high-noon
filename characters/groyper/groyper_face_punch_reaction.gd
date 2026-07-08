class_name GroyperFacePunchReaction
extends RefCounted

const MESHY_BASE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
)
const FACE_PUNCH_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Face_Punch_Reaction_frame_rate_60.fbx"
)
const MESHY_CLIP := &"Face_Punch_Reaction_1_frame_rate_60_fbx"

const LIBRARY := &"face_punch_reaction"
const CLIP := &"face_punch_react"

const BLEND_NODE := &"FacePunchReactBlend"
const TIME_SEEK_NODE := &"FacePunchReactTimeSeek"
const TIME_SCALE_NODE := &"FacePunchReactTimeScale"
const ANIM_NODE := &"FacePunchReactAnim"

const PLAYBACK_SPEED := 2.0
const BLEND_IN := 0.08
const BLEND_OUT := 0.12

const UPPER_BODY_BONES: Array[String] = [
	"Spine",
	"Spine01",
	"Spine02",
	"neck",
	"Head",
	"LeftShoulder",
	"LeftArm",
	"LeftForeArm",
	"LeftHand",
	"RightShoulder",
	"RightArm",
	"RightForeArm",
	"RightHand",
]


static func clip_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY, CLIP])


static func ensure_library(animation_player: AnimationPlayer) -> bool:
	if animation_player == null:
		return false
	if animation_player.has_animation(clip_path()):
		return true

	var raw: Animation = RigAnimUtils.load_skeleton_animation(FACE_PUNCH_SCENE, MESHY_CLIP)
	if raw == null:
		push_error("GroyperFacePunchReaction: failed to load clip.")
		return false

	var animation: Animation = RigAnimUtils.prepare_for_body_player(raw, false)
	RigAnimUtils.strip_root_motion(animation)
	animation.loop_mode = Animation.LOOP_NONE

	var library := AnimationLibrary.new()
	library.add_animation(CLIP, animation)
	if animation_player.has_animation_library(LIBRARY):
		animation_player.remove_animation_library(LIBRARY)
	animation_player.add_animation_library(LIBRARY, library)
	return true


static func attach_nodes(
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName,
	animation_player: AnimationPlayer
) -> StringName:
	if not ensure_library(animation_player):
		return input_node

	var anim_path := clip_path()
	var anim_node := AnimationNodeAnimation.new()
	anim_node.animation = anim_path

	var time_seek := AnimationNodeTimeSeek.new()
	var time_scale := AnimationNodeTimeScale.new()

	var react_blend := AnimationNodeBlend2.new()
	react_blend.sync = false
	_configure_upper_body_filter(react_blend)

	blend_tree.add_node(ANIM_NODE, anim_node)
	blend_tree.add_node(TIME_SCALE_NODE, time_scale)
	blend_tree.add_node(TIME_SEEK_NODE, time_seek)
	blend_tree.add_node(BLEND_NODE, react_blend)
	blend_tree.connect_node(TIME_SEEK_NODE, 0, TIME_SCALE_NODE)
	blend_tree.connect_node(TIME_SCALE_NODE, 0, ANIM_NODE)
	blend_tree.connect_node(BLEND_NODE, 0, input_node)
	blend_tree.connect_node(BLEND_NODE, 1, TIME_SEEK_NODE)
	return BLEND_NODE


static func set_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree == null:
		return
	animation_tree.set("parameters/%s/seek_request" % TIME_SEEK_NODE, time)


static func set_playback_speed(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree == null:
		return
	var path := "parameters/%s/scale" % TIME_SCALE_NODE
	if animation_tree.get(path) != null:
		animation_tree.set(path, maxf(speed, 0.001))


static func init_tree_state(animation_tree: AnimationTree) -> void:
	set_blend(animation_tree, 0.0)
	set_seek(animation_tree, 0.0)
	set_playback_speed(animation_tree, PLAYBACK_SPEED)


static func get_duration(animation_player: AnimationPlayer, fallback: float = 0.55) -> float:
	if animation_player == null or not animation_player.has_animation(clip_path()):
		return fallback / PLAYBACK_SPEED
	return animation_player.get_animation(clip_path()).length / PLAYBACK_SPEED


static func _configure_upper_body_filter(blend: AnimationNodeBlend2) -> void:
	blend.filter_enabled = true
	for bone_name: String in UPPER_BODY_BONES:
		blend.set_filter_path(
			NodePath("%s%s" % [PunchPoseConfig.SKELETON_TRACK_PREFIX, bone_name]),
			true
		)
