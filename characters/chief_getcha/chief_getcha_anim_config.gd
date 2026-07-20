class_name ChiefGetchaAnimConfig
extends RefCounted

const MERGED_SCENE := (
	"res://Assets/CharacterModels/ChiefGetcha/Meshy_AI_groyper_style_toad_na_biped/"
	+ "Meshy_AI_groyper_style_toad_na_biped_Meshy_AI_Meshy_Merged_Animations.fbx"
)

const MESHY_SIT := &"Sit_Cross_Legged_on_Floor_frame_rate_60_fbx"
const MESHY_STAND_UP := &"Stand_Up3_frame_rate_60_fbx"
const MESHY_IDLE := &"Combat_Stance_frame_rate_60_fbx"
const MESHY_WALK := &"Walking_frame_rate_60_fbx"
const MESHY_RUN := &"Running_frame_rate_60_fbx"
## Block hold uses Groyper authored upper-body pose (UnarmedBlock/block_hold),
## not a Meshy combat-stance clip — see ChiefGetchaNpc block setup.
const MESHY_PUNCH := &"Weapon_Combo_1_frame_rate_60_fbx"
const MESHY_COMBO := &"Weapon_Combo_2_frame_rate_60_fbx"
## Skill-3-style two-hitter (selectable brawl attack alongside Weapon Combo 1).
const MESHY_DOUBLE_COMBO := &"Double_Combo_Attack_frame_rate_60_fbx"
const MESHY_SKILL_3 := &"Skill_03_frame_rate_60_fbx"
const MESHY_KICK := &"Boxing_Guard_Right_Straight_Kick_frame_rate_60_fbx"
const MESHY_SPIN_KICK := &"Lunge_Spin_Kick_frame_rate_60_fbx"
const MESHY_FLYING_KICK := &"Rising_Flying_Kick_frame_rate_60_fbx"
const MESHY_CHARGE := &"Run_and_Jump_frame_rate_60_fbx"
const MESHY_ROLL := &"Roll_Dodge_1_frame_rate_60_fbx"
const MESHY_HIT := &"Hit_Reaction_frame_rate_60_fbx"
const MESHY_BOW_WALK := &"Walk_Forward_with_Bow_Aimed_frame_rate_60_fbx"
## Actually a sprint-with-bow locomotion clip (used as archery run).
const MESHY_BOW_AIM := &"Female_Bow_Charge_Left_Hand_frame_rate_60_fbx"

const LIBRARY := &"chief_getcha"
const CLIP_SIT := &"sit"
const CLIP_STAND_UP := &"stand_up"
const CLIP_IDLE := &"idle"
const CLIP_WALK := &"walk"
const CLIP_RUN := &"run"
const CLIP_PUNCH := &"punch"
const CLIP_COMBO := &"combo"
const CLIP_DOUBLE_COMBO := &"double_combo"
const CLIP_SKILL_3 := &"skill_3"
const CLIP_KICK := &"kick"
const CLIP_SPIN_KICK := &"spin_kick"
const CLIP_FLYING_KICK := &"flying_kick"
const CLIP_CHARGE := &"charge"
const CLIP_ROLL := &"roll"
const CLIP_HIT := &"hit"
const CLIP_BOW_WALK := &"bow_walk"
const CLIP_BOW_SPRINT := &"bow_aim"
const CLIP_BOW_AIM := &"bow_aim"

const MOVE_BLEND_NODE := &"MoveBlend"
const LOCOMOTION_BLEND_NODE := &"LocomotionBlend"
const BLOCK_BLEND_NODE := &"BlockBlend"
const ATTACK_ONE_SHOT := &"AttackOneShot"
const ROLL_ONE_SHOT := &"RollOneShot"
const HIT_ONE_SHOT := &"HitOneShot"

## Absolute strike times (seconds into the attack clip).
## PackedFloat32Array literals are not valid GDScript const expressions — use helpers.
const FLYING_KICK_STRIKE_TIME := 0.3
## Archery throw uses Skill 3 spin — slightly before connect so the bolt leaves with the swing.
const ARCHERY_THROW_FIRE_TIME := 0.9

const HITBOX_FORWARD := 2.6
const HITBOX_KICK := 2.8
const HITBOX_SPIN := 3.4
const HITBOX_FLYING := 3.4
const HITBOX_SWEEP := 3.2
const ARC_FORWARD := 0.2
const ARC_SWEEP := -0.12

const PUNCH_AOE_RADIUS := 1.6
const PUNCH_AOE_DAMAGE := 1.0

const STAND_UP_CROSSFADE := 0.12
const BLOCK_COUNTER_KICK_CHANCE := 0.6
## When a block counter fires, chance it is the large spin kick vs straight kick.
const BLOCK_COUNTER_SPIN_KICK_CHANCE := 0.5
const BLOCK_BLEND_THRESHOLD := 0.35
## Blue/white clash burst when Chief blocks a punch.
const BLOCK_CLASH_FX_MODULATE := Color(0.72, 0.92, 1.55, 1.0)

## Legacy fraction helpers (first strike time) for any leftover callers.
const PUNCH_STRIKE_FRACTION := 0.65
const COMBO_STRIKE_FRACTION := 1.0
const KICK_STRIKE_FRACTION := 0.6
const SPIN_KICK_STRIKE_FRACTION := 1.22
const FLYING_KICK_STRIKE_FRACTION := 0.3


static func punch_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([0.65, 2.4])


static func combo_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([1.0, 2.0, 3.0])


static func double_combo_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([0.6, 1.1])


static func skill_3_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([1.1])


static func kick_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([0.6])


static func spin_kick_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([1.22])


static func flying_kick_strike_times(_anim_length: float = 0.0) -> PackedFloat32Array:
	return PackedFloat32Array([FLYING_KICK_STRIKE_TIME])
