class_name LassoSwingConfig
extends RefCounted

## Authored lasso grapple swing / release / land clips for overworld traversal.

const LIBRARY_NAME := &"lasso_swing"
const SWING := &"swing"
const FALL := &"fall_2"
const LAND := &"dive_land_2"

const OUT_PATH := "res://characters/groyper/lasso_swing.tres"

const SWING_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Swing_on_Rope_to_Ground_frame_rate_60.fbx"
)
const FALL_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Climb_Attempt_and_Fall_2_frame_rate_60.fbx"
)
const LAND_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Dive_Down_and_Land_2_frame_rate_60.fbx"
)

const BLEND_NODE := &"LassoSwingBlend"
const POSE_BLEND_NODE := &"LassoSwingPoseBlend"
const LAND_BLEND_NODE := &"LassoSwingLandBlend"
const SWING_ANIM_NODE := &"LassoSwingAnim"
const SWING_TIME_SEEK := &"LassoSwingTimeSeek"
const SWING_TIME_SCALE := &"LassoSwingTimeScale"
const FALL_ANIM_NODE := &"LassoFallAnim"
const FALL_TIME_SEEK := &"LassoFallTimeSeek"
const LAND_ANIM_NODE := &"LassoLandAnim"
const LAND_TIME_SEEK := &"LassoLandTimeSeek"
const LAND_TIME_SCALE := &"LassoLandTimeScale"

enum Phase { NONE, SWING, RELEASE, AIR, LAND, EXIT }


static func get_swing_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, SWING])


static func get_fall_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, FALL])


static func get_land_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, LAND])


static func set_master_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BLEND_NODE, amount)


static func set_pose_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % POSE_BLEND_NODE, amount)


static func set_land_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % LAND_BLEND_NODE, amount)


static func set_swing_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % SWING_TIME_SEEK, time)


static func set_fall_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FALL_TIME_SEEK, time)


static func set_land_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % LAND_TIME_SEEK, time)


static func set_swing_playback_speed(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % SWING_TIME_SCALE, speed)


static func set_land_playback_speed(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/scale" % LAND_TIME_SCALE, speed)
