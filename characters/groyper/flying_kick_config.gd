class_name FlyingKickConfig
extends RefCounted

## Rising Flying Kick — unarmed sprint attack clip.
## Authored copy lives in flying_kick.tres (AnimationPlayer library flying_kick/kick
## on groyper_body.tscn) so bones/keyframes stay editable in the editor, same
## pattern as climb_fall. Re-extract from the FBX via the FlyingKickExtract node.

const LIBRARY_NAME := &"flying_kick"
const KICK := &"kick"

const OUT_PATH := "res://characters/groyper/flying_kick.tres"

const KICK_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Rising_Flying_Kick_frame_rate_60.fbx"
)

const ANIM_NODE := &"FlyingKickAnim"
const TIME_SEEK_NODE := &"FlyingKickTimeSeek"
const TIME_SCALE_NODE := &"FlyingKickTimeScale"
const BLEND_NODE := &"FlyingKickBlend"


static func get_animation_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, KICK])


static func set_tree_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_tree_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % TIME_SEEK_NODE, time)


static func set_tree_scale(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % TIME_SCALE_NODE, maxf(speed, 0.001))
