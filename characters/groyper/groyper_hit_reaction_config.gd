class_name GroyperHitReactionConfig
extends RefCounted

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")

enum Phase {
	NONE,
	FALLING,
	STANDING_UP,
}

const MESHY_BASE := (
	"res://Assets/CharacterModels/Groyper/GroyperSDanimations/Meshy_AI_Emerald_Embrace_biped/"
)
const FALLING_DOWN_SCENE := (
	MESHY_BASE + "Meshy_AI_Emerald_Embrace_biped_Animation_falling_down_frame_rate_60.fbx"
)

const LIBRARY := &"hit_reaction"
const CLIP_FALLING_DOWN := &"falling_down"

const HIT_REACTION_BLEND := &"HitReactionBlend"
const HIT_REACTION_POSE_BLEND := &"HitReactionPoseBlend"
const FALL_ANIM_NODE := &"HitReactionFallAnim"
const FALL_TIME_SEEK := &"HitReactionFallTimeSeek"
const STAND_ANIM_NODE := &"HitReactionStandAnim"
const STAND_TIME_SEEK := &"HitReactionStandTimeSeek"
const STAND_TIME_SCALE := &"HitReactionStandTimeScale"

const STUN_DURATION := 0.5
const LIGHT_HIT_STUN_DURATION := 0.3
const SEQUENCE_PLAYBACK_SPEED := 2.0
const STAND_UP_PLAYBACK_SPEED := 2.0
const BLEND_IN_DURATION := 0.22
const FALL_TO_STAND_BLEND := 0.32
const STAND_BLEND_OUT_START := 0.52
const STAND_CONTROL_UNLOCK_FRACTION := 0.58
## Finish once the stand clip is done and reaction weight is nearly gone.
const STAND_BLEND_FINISH_THRESHOLD := 0.03
const KNOCKDOWN_KNOCKBACK_THRESHOLD := 6.0
const KNOCKDOWN_IMPULSE_MIN_SPEED := 9.5
const KNOCKDOWN_IMPULSE_MAGIC_MIN_SPEED := 10.5
const KNOCKDOWN_IMPULSE_UP := 1.65
const KNOCKDOWN_IMPULSE_HOLD := 0.22

## Prone pose is authored upright; sink the visual mesh (and body origin) once grounded.
const FALL_GROUND_MODEL_Y_OFFSET := -0.48
const FALL_GROUND_BODY_Y_OFFSET := 0.30
const FALL_GROUND_SINK_START_FRACTION := 0.30
const FALL_GROUND_SINK_FULL_FRACTION := 0.68
const STAND_GROUND_SINK_RELEASE_START := 0.06
const STAND_GROUND_SINK_RELEASE_END := 0.48


static func get_falling_down_path() -> StringName:
	return StringName("%s/%s" % [LIBRARY, CLIP_FALLING_DOWN])


static func get_hit_knockback_strength(hit_info: Dictionary, knockback_applied: bool) -> float:
	if not knockback_applied:
		return 0.0
	if hit_info.has("knockback_speed"):
		return float(hit_info.knockback_speed)
	return BulletHitDamageScript.BODY_KNOCKBACK_SPEED


static func is_powerful_npc_hit(hit_info: Dictionary) -> bool:
	if bool(hit_info.get("fire_wave_hit", false)):
		return true
	if bool(hit_info.get("arcane_bolt_hit", false)):
		return true
	if bool(hit_info.get("arcane_nova_hit", false)):
		return true
	if bool(hit_info.get("hammer_hit", false)):
		return true
	if bool(hit_info.get("charge_run_hit", false)):
		return true
	var shooter: Node = hit_info.get("shooter")
	if shooter != null and is_instance_valid(shooter):
		if shooter.is_in_group(&"redo_npc") or shooter.is_in_group(&"pavel_npc"):
			return true
	return false


static func should_knockdown(hit_info: Dictionary, knockback_applied: bool) -> bool:
	if not knockback_applied:
		return false
	if is_powerful_npc_hit(hit_info):
		return true
	return get_hit_knockback_strength(hit_info, knockback_applied) >= KNOCKDOWN_KNOCKBACK_THRESHOLD


static func get_knockdown_impulse_speed(hit_info: Dictionary) -> float:
	var from_hit := get_hit_knockback_strength(hit_info, true)
	var min_speed := (
		KNOCKDOWN_IMPULSE_MAGIC_MIN_SPEED
		if is_powerful_npc_hit(hit_info)
		else KNOCKDOWN_IMPULSE_MIN_SPEED
	)
	return maxf(from_hit, min_speed)


static func get_knockdown_impulse_up(hit_info: Dictionary) -> float:
	return maxf(float(hit_info.get("knockback_up", 0.0)), KNOCKDOWN_IMPULSE_UP)


static func get_knockdown_impulse_hold() -> float:
	return KNOCKDOWN_IMPULSE_HOLD / maxf(SEQUENCE_PLAYBACK_SPEED, 0.001)


static func get_knockdown_stun_duration() -> float:
	return STUN_DURATION / maxf(SEQUENCE_PLAYBACK_SPEED, 0.001)


static func get_sequence_blend_in_duration() -> float:
	return BLEND_IN_DURATION / maxf(SEQUENCE_PLAYBACK_SPEED, 0.001)


static func get_fall_to_stand_blend_duration() -> float:
	return FALL_TO_STAND_BLEND / maxf(SEQUENCE_PLAYBACK_SPEED, 0.001)


static func get_stand_playback_speed() -> float:
	return STAND_UP_PLAYBACK_SPEED * SEQUENCE_PLAYBACK_SPEED


static func compute_stand_reaction_blend(progress: float) -> float:
	var p := clampf(progress, 0.0, 1.0)
	if p < STAND_BLEND_OUT_START:
		return 1.0
	var out_t := clampf(
		(p - STAND_BLEND_OUT_START) / maxf(1.0 - STAND_BLEND_OUT_START, 0.001),
		0.0,
		1.0
	)
	var eased := out_t * out_t * (3.0 - 2.0 * out_t)
	return 1.0 - eased


static func should_finish_stand_up(progress: float, blend_amount: float) -> bool:
	return progress >= 1.0 and blend_amount <= STAND_BLEND_FINISH_THRESHOLD


static func get_fall_ground_sink_weight(
	fall_time: float,
	fall_duration: float,
	on_floor: bool
) -> float:
	if not on_floor or fall_duration <= 0.0:
		return 0.0
	var progress := clampf(fall_time / fall_duration, 0.0, 1.0)
	var span := maxf(FALL_GROUND_SINK_FULL_FRACTION - FALL_GROUND_SINK_START_FRACTION, 0.001)
	var t := clampf((progress - FALL_GROUND_SINK_START_FRACTION) / span, 0.0, 1.0)
	return _smoothstep(t)


static func get_stand_ground_sink_weight(stand_progress: float) -> float:
	var span := maxf(STAND_GROUND_SINK_RELEASE_END - STAND_GROUND_SINK_RELEASE_START, 0.001)
	var t := clampf((stand_progress - STAND_GROUND_SINK_RELEASE_START) / span, 0.0, 1.0)
	return 1.0 - _smoothstep(t)


static func _smoothstep(t: float) -> float:
	return t * t * (3.0 - 2.0 * t)


static func set_reaction_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % HIT_REACTION_BLEND, amount)


static func set_pose_blend(animation_tree: AnimationTree, amount: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/blend_amount" % HIT_REACTION_POSE_BLEND, amount)


static func set_fall_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % FALL_TIME_SEEK, time)


static func set_stand_seek(animation_tree: AnimationTree, time: float) -> void:
	if animation_tree != null:
		animation_tree.set("parameters/%s/seek_request" % STAND_TIME_SEEK, time)


static func set_stand_playback_speed(animation_tree: AnimationTree, speed: float) -> void:
	if animation_tree != null:
		animation_tree.set(
			"parameters/%s/scale" % STAND_TIME_SCALE,
			maxf(speed, 0.001)
		)
