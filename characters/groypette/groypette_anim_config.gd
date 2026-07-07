class_name GroypetteAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Groypette/Meshy_AI_make_her_wear_a_white_biped/"
	+ "Meshy_AI_make_her_wear_a_white_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

const MESHY_IDLE_6 := &"Idle_6_frame_rate_60_fbx"
const MESHY_IDLE_15 := &"Idle_15_frame_rate_60_fbx"
const MESHY_CHEER := &"Cheer_with_Both_Hands_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_Woman_frame_rate_60_fbx"
const MESHY_RUN_A := &"Running_frame_rate_60_fbx"
const MESHY_RUN_B := &"run_fast_5_frame_rate_60_fbx"
const MESHY_STAND_UP := &"Stand_Up7_frame_rate_60_fbx"

const LOCOMOTION_LIBRARY := &"groypette_locomotion"
const STANDUP_LIBRARY := &"groypette_standup"
const IDLE_6 := &"idle_6"
const IDLE_15 := &"idle_15"
const IDLE_CHEER := &"idle_cheer"
const LOCOMOTION_WALK := &"walk"
const LOCOMOTION_RUN_A := &"run_a"
const LOCOMOTION_RUN_B := &"run_b"
const STAND_UP := &"stand_up"

const MOVE_BLEND_NODE := &"MoveBlend"
const IDLE_STATE_NODE := &"IdleState"
const LOCOMOTION_BLEND_NODE := &"LocomotionBlend"
const RUN_VARIANT_NODE := &"RunVariant"
const IDLE_CROSSFADE := 0.25
const IDLE_VARIANT_DELAY_MIN := 8.0
const IDLE_VARIANT_DELAY_MAX := 18.0

const IDLE_CLIP_BY_STATE: Dictionary = {
	IDLE_6: MESHY_IDLE_6,
	IDLE_15: MESHY_IDLE_15,
	IDLE_CHEER: MESHY_CHEER,
}

const LOOP_ONCE_STATES: Array[StringName] = [IDLE_CHEER]

const IDLE_VARIANTS: Array[StringName] = [IDLE_6, IDLE_15]
