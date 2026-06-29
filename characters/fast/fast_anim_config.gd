class_name FastAnimConfig
extends RefCounted

## Fast Meshy merged idle clips — walk/run still use shared Groyper RigAnimConfig scenes.

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Fast/Meshy_AI_Childlike_drawing_of__biped/"
	+ "Meshy_AI_Childlike_drawing_of__biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

## Meshy export names inside the merged FBX.
## idle3 (third) -> default loop, idle2 -> yawn emote, old default (idle1) -> gun aimed.
const MESHY_IDLE_DEFAULT := &"Idle_03_frame_rate_60_fbx"
const MESHY_IDLE_YAWN := &"Idle_02_frame_rate_60_fbx"
const MESHY_IDLE_GUN := &"Idle_5_frame_rate_60_fbx"

const IDLE_LIBRARY := &"fast_idle"
const IDLE_DEFAULT := &"idle_default"
const IDLE_YAWN := &"idle_yawn"
const IDLE_GUN := &"idle_gun"

const IDLE_YAWN_DELAY_MIN := 10.0
const IDLE_YAWN_DELAY_MAX := 20.0
const IDLE_CROSSFADE := 0.25

const MOVE_BLEND_NODE := &"MoveBlend"
const IDLE_STATE_NODE := &"IdleState"
const LOCOMOTION_BLEND_NODE := &"LocomotionBlend"
