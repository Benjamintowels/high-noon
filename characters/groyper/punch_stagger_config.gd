class_name PunchStaggerConfig
extends RefCounted

## Punch stagger / hit-reaction clips — authored in punch_stagger.tres on
## groyper_body.tscn (library punch_stagger/*). Re-extract via PunchStaggerExtract.

const LIBRARY_NAME := &"punch_stagger"
const OUT_PATH := "res://characters/groyper/punch_stagger.tres"

const HIT_REACTION_1 := &"hit_reaction_1"
const SLAP_REACTION := &"slap_reaction"
const FACE_PUNCH_1 := &"face_punch_1"
const ELECTROCUTION := &"electrocution"

## Clips used when a townsperson/bandit is staggered by a punch.
## Electrocution is reserved for lightning gem bolts — never picked here.
const PUNCH_STAGGER_CLIPS: Array[StringName] = [
	HIT_REACTION_1,
	SLAP_REACTION,
	FACE_PUNCH_1,
]

const MESHY_BASE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
)

const HIT_REACTION_1_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Hit_Reaction_1_frame_rate_60.fbx"
)
const SLAP_REACTION_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_Slap_Reaction_frame_rate_60.fbx"
)
const FACE_PUNCH_1_SCENE := (
	MESHY_BASE
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Face_Punch_Reaction_1_frame_rate_60.fbx"
)
const ELECTROCUTION_SCENE := (
	MESHY_BASE
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Electrocution_Reaction_frame_rate_60.fbx"
)

const HIT_REACTION_1_CLIP_PATH := "res://characters/groyper/hit_reaction_1.tres"
const SLAP_REACTION_CLIP_PATH := "res://characters/groyper/slap_reaction.tres"
const FACE_PUNCH_1_CLIP_PATH := "res://characters/groyper/face_punch_1.tres"
const ELECTROCUTION_CLIP_PATH := "res://characters/groyper/electrocution_reaction.tres"

const ANIM_NODE := &"PunchStaggerAnim"
const ANIM_NODE_B := &"PunchStaggerAnimB"
const TIME_SEEK_NODE := &"PunchStaggerTimeSeek"
const TIME_SEEK_NODE_B := &"PunchStaggerTimeSeekB"
const CROSS_BLEND_NODE := &"PunchStaggerCrossBlend"
const BLEND_NODE := &"PunchStaggerBlend"

const BLEND_IN := 0.08
const BLEND_OUT := 0.10
## Keep outer blend pinned while interrupting — crossfade owns the clip swap.
const INTERRUPT_BLEND_IN := 0.04
## Dual-slot reaction crossfade (smooth interrupt into a new hit reaction).
const INTERRUPT_CROSSFADE := 0.07


static func get_animation_path(clip_name: StringName) -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, clip_name])


static func clip_specs() -> Array[Dictionary]:
	return [
		{
			"name": HIT_REACTION_1,
			"scene": HIT_REACTION_1_SCENE,
			"path": HIT_REACTION_1_CLIP_PATH,
		},
		{
			"name": SLAP_REACTION,
			"scene": SLAP_REACTION_SCENE,
			"path": SLAP_REACTION_CLIP_PATH,
		},
		{
			"name": FACE_PUNCH_1,
			"scene": FACE_PUNCH_1_SCENE,
			"path": FACE_PUNCH_1_CLIP_PATH,
		},
		{
			"name": ELECTROCUTION,
			"scene": ELECTROCUTION_SCENE,
			"path": ELECTROCUTION_CLIP_PATH,
		},
	]


static func pick_punch_stagger_clip() -> StringName:
	if PUNCH_STAGGER_CLIPS.is_empty():
		return HIT_REACTION_1
	return PUNCH_STAGGER_CLIPS[randi() % PUNCH_STAGGER_CLIPS.size()]


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	set_slot_seek(animation_tree, 0, time)


static func set_slot_seek(animation_tree: AnimationTree, slot: int, time: float) -> void:
	if animation_tree == null:
		return
	var seek_node := TIME_SEEK_NODE_B if slot == 1 else TIME_SEEK_NODE
	animation_tree.set("parameters/%s/seek_request" % seek_node, time)


static func set_cross_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % CROSS_BLEND_NODE, amount)
