class_name PunchStaggerReaction
extends RefCounted

## Runtime punch-stagger overlay for town NPCs / bandits.
## Clips are authored in punch_stagger.tres (edit on groyper_body).
## Dual slots + crossfade keep interrupt blends quick and smooth.

const PunchStaggerConfigScript := preload("res://characters/groyper/punch_stagger_config.gd")
const PunchStaggerExtractScript := preload("res://characters/groyper/punch_stagger_extract.gd")
const PunchPoseConfigScript := preload("res://characters/groyper/punch_pose_config.gd")

## Full-body stagger reads better than upper-body-only for NPC hits.
const STAGGER_BLEND_BONES: Array[String] = [
	"Hips",
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
	"LeftUpLeg",
	"LeftLeg",
	"RightUpLeg",
	"RightLeg",
]


static func ensure_library(animation_player: AnimationPlayer) -> bool:
	if animation_player == null:
		return false
	var source := PunchStaggerExtractScript.load_authored_library()
	if source == null:
		return false
	if animation_player.has_animation_library(PunchStaggerConfigScript.LIBRARY_NAME):
		animation_player.remove_animation_library(PunchStaggerConfigScript.LIBRARY_NAME)
	animation_player.add_animation_library(
		PunchStaggerConfigScript.LIBRARY_NAME,
		source.duplicate(true)
	)
	var required: Array[StringName] = []
	required.append_array(PunchStaggerConfigScript.PUNCH_STAGGER_CLIPS)
	required.append(PunchStaggerConfigScript.ELECTROCUTION)
	for clip_name: StringName in required:
		if not animation_player.has_animation(
			PunchStaggerConfigScript.get_animation_path(clip_name)
		):
			push_warning("PunchStaggerReaction: missing stagger clip %s." % clip_name)
			return false
	return true


## Returns {
##   "output": StringName,
##   "anim_node": AnimationNodeAnimation,
##   "anim_node_b": AnimationNodeAnimation,
## }.
static func attach_nodes(
	blend_tree: AnimationNodeBlendTree,
	input_node: StringName,
	animation_player: AnimationPlayer
) -> Dictionary:
	if not ensure_library(animation_player):
		return {"output": input_node, "anim_node": null, "anim_node_b": null}

	var default_clip := PunchStaggerConfigScript.get_animation_path(
		PunchStaggerConfigScript.HIT_REACTION_1
	)
	var anim_node := AnimationNodeAnimation.new()
	anim_node.animation = default_clip
	var anim_node_b := AnimationNodeAnimation.new()
	anim_node_b.animation = default_clip

	var time_seek := AnimationNodeTimeSeek.new()
	var time_seek_b := AnimationNodeTimeSeek.new()
	var cross_blend := AnimationNodeBlend2.new()
	cross_blend.sync = false

	var react_blend := AnimationNodeBlend2.new()
	react_blend.sync = false
	_configure_stagger_blend_filter(react_blend)

	blend_tree.add_node(PunchStaggerConfigScript.ANIM_NODE, anim_node)
	blend_tree.add_node(PunchStaggerConfigScript.ANIM_NODE_B, anim_node_b)
	blend_tree.add_node(PunchStaggerConfigScript.TIME_SEEK_NODE, time_seek)
	blend_tree.add_node(PunchStaggerConfigScript.TIME_SEEK_NODE_B, time_seek_b)
	blend_tree.add_node(PunchStaggerConfigScript.CROSS_BLEND_NODE, cross_blend)
	blend_tree.add_node(PunchStaggerConfigScript.BLEND_NODE, react_blend)

	blend_tree.connect_node(
		PunchStaggerConfigScript.TIME_SEEK_NODE,
		0,
		PunchStaggerConfigScript.ANIM_NODE
	)
	blend_tree.connect_node(
		PunchStaggerConfigScript.TIME_SEEK_NODE_B,
		0,
		PunchStaggerConfigScript.ANIM_NODE_B
	)
	blend_tree.connect_node(
		PunchStaggerConfigScript.CROSS_BLEND_NODE,
		0,
		PunchStaggerConfigScript.TIME_SEEK_NODE
	)
	blend_tree.connect_node(
		PunchStaggerConfigScript.CROSS_BLEND_NODE,
		1,
		PunchStaggerConfigScript.TIME_SEEK_NODE_B
	)
	blend_tree.connect_node(PunchStaggerConfigScript.BLEND_NODE, 0, input_node)
	blend_tree.connect_node(
		PunchStaggerConfigScript.BLEND_NODE,
		1,
		PunchStaggerConfigScript.CROSS_BLEND_NODE
	)
	return {
		"output": PunchStaggerConfigScript.BLEND_NODE,
		"anim_node": anim_node,
		"anim_node_b": anim_node_b,
	}


static func init_tree_state(animation_tree: AnimationTree) -> void:
	PunchStaggerConfigScript.set_tree_blend(animation_tree, 0.0)
	PunchStaggerConfigScript.set_cross_blend(animation_tree, 0.0)
	PunchStaggerConfigScript.set_slot_seek(animation_tree, 0, 0.0)
	PunchStaggerConfigScript.set_slot_seek(animation_tree, 1, 0.0)


static func set_slot_clip(
	anim_node: AnimationNodeAnimation,
	clip_name: StringName
) -> void:
	if anim_node == null:
		return
	anim_node.animation = PunchStaggerConfigScript.get_animation_path(clip_name)


static func set_clip(anim_node: AnimationNodeAnimation, clip_name: StringName) -> void:
	set_slot_clip(anim_node, clip_name)


static func get_clip_length(
	animation_player: AnimationPlayer,
	clip_name: StringName,
	fallback: float = 1.0
) -> float:
	if animation_player == null:
		return fallback
	var path := PunchStaggerConfigScript.get_animation_path(clip_name)
	if not animation_player.has_animation(path):
		return fallback
	return animation_player.get_animation(path).length


static func _configure_stagger_blend_filter(blend_node: AnimationNodeBlend2) -> void:
	blend_node.filter_enabled = true
	for bone_name: String in STAGGER_BLEND_BONES:
		blend_node.set_filter_path(
			NodePath("%s%s" % [PunchPoseConfigScript.SKELETON_TRACK_PREFIX, bone_name]),
			true
		)
