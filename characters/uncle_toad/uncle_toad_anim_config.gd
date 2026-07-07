class_name UncleToadAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/UncleToad/Meshy_AI_groyper_style_toad_we_biped/"
	+ "Meshy_AI_groyper_style_toad_we_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

## Neutral standing pose — use for default idle, not locomotion.
const MESHY_IDLE := &"Talk_with_Hands_Open_frame_rate_60_fbx"
## Walk-in-place emote — only as an occasional idle variant.
const MESHY_FUNKY := &"Funky_Walk_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_RUN := &"Running_frame_rate_60_fbx"

const MESHY_TALK_PASSION := &"Talk_Passionately_frame_rate_60_fbx"
const MESHY_TALK_HANDS_OPEN := &"Talk_with_Hands_Open_frame_rate_60_fbx"
const MESHY_TALK_HAND_RAISED := &"Talk_with_Left_Hand_Raised_frame_rate_60_fbx"

const MESHY_SOCIAL_TALK_CLIPS: Array[StringName] = [
	MESHY_TALK_PASSION,
	MESHY_TALK_HAND_RAISED,
	MESHY_FUNKY,
]

const LOCOMOTION_LIBRARY := &"uncle_toad_locomotion"
const IDLE_DEFAULT := &"idle_default"
const IDLE_FUNKY := &"idle_funky"
const IDLE_TALK_PASSION := &"idle_talk_passion"
const IDLE_TALK_HANDS_OPEN := &"idle_talk_hands_open"
const IDLE_TALK_HAND_RAISED := &"idle_talk_hand_raised"
const LOCOMOTION_WALK := &"walk"
const LOCOMOTION_RUN := &"run"

const MOVE_BLEND_NODE := &"MoveBlend"
const IDLE_STATE_NODE := &"IdleState"
const LOCOMOTION_BLEND_NODE := &"LocomotionBlend"
const IDLE_CROSSFADE := 0.25
const FUNKY_EMOTE_DELAY_MIN := 14.0
const FUNKY_EMOTE_DELAY_MAX := 28.0

const IDLE_CLIP_BY_STATE: Dictionary = {
	IDLE_DEFAULT: MESHY_IDLE,
	IDLE_FUNKY: MESHY_FUNKY,
	IDLE_TALK_PASSION: MESHY_TALK_PASSION,
	IDLE_TALK_HANDS_OPEN: MESHY_TALK_HANDS_OPEN,
	IDLE_TALK_HAND_RAISED: MESHY_TALK_HAND_RAISED,
}

const TALK_STATE_BY_MESHY: Dictionary = {
	MESHY_TALK_PASSION: IDLE_TALK_PASSION,
	MESHY_TALK_HANDS_OPEN: IDLE_TALK_HANDS_OPEN,
	MESHY_TALK_HAND_RAISED: IDLE_TALK_HAND_RAISED,
	MESHY_FUNKY: IDLE_FUNKY,
}

const LOOP_ONCE_STATES: Array[StringName] = [IDLE_FUNKY]
