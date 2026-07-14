class_name BonfirePoseConfig
extends RefCounted

## Bonfire rest pose — stand up / sit cross-legged clips for overworld bonfire interaction.

const STAND_UP3_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Stand_Up3_frame_rate_60.fbx"
)
const SIT_CROSS_SCENE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
	+ "Meshy_AI_Emerald_Embrace_biped_Animation_Sit_Cross_Legged_on_Floor_frame_rate_60.fbx"
)

const LIBRARY_NAME := &"bonfire"
const STAND_UP3 := &"stand_up3"
const STAND_UP3_REVERSE := &"stand_up3_reverse"
const SIT_CROSS_LEGGED := &"sit_cross_legged"

const BONFIRE_BLEND := &"BonfireBlend"
const BONFIRE_POSE_BLEND := &"BonfirePoseBlend"
const STAND_ANIM_NODE := &"BonfireStandAnim"
const STAND_TIME_SEEK := &"BonfireStandTimeSeek"
const SIT_ANIM_NODE := &"BonfireSitAnim"

const BLEND_IN_DURATION := 0.28
const POSE_BLEND_DURATION := 0.35
const BLEND_OUT_DURATION := 0.32

const STAND_UP_SPEED := 2.625
const SIT_DOWN_SPEED := 2.625
const STAND_UP_MOVE_UNLOCK_FRACTION := 0.32
const STAND_UP_BLEND_OUT_START := 0.38

const CAMERA_BLEND_SPEED := 4.2
const CINEMATIC_CAMERA_SIDE := 1.15
const CINEMATIC_CAMERA_HEIGHT := 0.28
const CINEMATIC_CAMERA_DISTANCE := 3.55
const CINEMATIC_FOV := 68.0
const CINEMATIC_FOCUS_HEIGHT := 0.92
## Sit-cross clips are authored for an upright root — sink the visual mesh onto the floor
## (same offset as knockdown/lasso prone). Release while standing back up.
const SIT_MODEL_Y_OFFSET := -0.48
const SIT_MODEL_SINK_SPEED := 12.0


static func get_stand_up3_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, STAND_UP3])


static func get_stand_up3_reverse_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, STAND_UP3_REVERSE])


static func get_sit_cross_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY_NAME, SIT_CROSS_LEGGED])


static func set_bonfire_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BONFIRE_BLEND, amount)


static func set_pose_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % BONFIRE_POSE_BLEND, amount)


static func set_stand_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % STAND_TIME_SEEK, time)
