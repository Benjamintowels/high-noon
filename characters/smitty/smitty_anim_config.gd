class_name SmittyAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/Smitty/Meshy_AI_groyper_style_toad_mu_biped/"
	+ "Meshy_AI_groyper_style_toad_mu_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

const MESHY_IDLE := &"Idle_02_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_HAMMER := &"Heavy_Hammer_Swing_frame_rate_60_fbx"

const WORK_LIBRARY := &"smitty_work"
const CLIP_IDLE := &"idle"
const CLIP_HAMMER := &"hammer"

const WORK_BLEND_NODE := &"WorkBlend"
const IDLE_CROSSFADE := 0.3
const HAMMER_STRIKE_NORMALIZED := 0.72
