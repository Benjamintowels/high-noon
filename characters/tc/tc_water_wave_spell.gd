extends RefCounted
class_name TcWaterWaveSpell

const WaterWaveEffectScript := preload("res://gameplay/fx/water_wave_effect.gd")
const WaterWaveFXScript := preload("res://gameplay/fx/water_wave_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const TcMeleeStrikeScript := preload("res://characters/tc/tc_melee_strike.gd")

const SPELL_MIN_RANGE := TcMeleeStrikeScript.RANGE + 1.5
const SPELL_MAX_RANGE := 16.0
const WINDUP_MIN := 0.35
const WINDUP_MAX := 0.75
const CAST_FRACTION := 0.48
const COOLDOWN := 2.4
const DAMAGE := 1
const WAVE_SPEED := 11.5
const WAVE_MAX_DISTANCE := 20.0
const WAVE_HALF_WIDTH := 2.2
const WAVE_ORIGIN_FORWARD := 2.0
const WAVE_HEIGHT := 1.2
const KNOCKBACK_SPEED := 6.0
const KNOCKBACK_UP := 0.9
const PLAYER_KNOCKBACK_SPEED := 4.5
const PLAYER_KNOCKBACK_UP := 0.7
const STUN_DURATION := 0.6


static func is_in_spell_range(actor: Node3D, target: Node3D) -> bool:
	if actor == null or target == null:
		return false
	var offset := target.global_position - actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	return distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE


static func get_cast_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	return TcMeleeStrikeScript.get_strike_direction(actor, aim_target)


static func launch_wave(
	attacker: Node,
	direction: Vector3,
	aim_target: Node = null
) -> void:
	var actor := attacker as Node3D
	if actor == null:
		return

	var cast_dir := get_cast_direction(actor, aim_target)
	if direction.length_squared() > 0.0001:
		var flat_dir := direction
		flat_dir.y = 0.0
		if flat_dir.length_squared() > 0.0001:
			cast_dir = flat_dir.normalized()

	var origin := actor.global_position + Vector3(0.0, WAVE_HEIGHT, 0.0)
	origin += cast_dir * WAVE_ORIGIN_FORWARD

	var fx_parent := ImpactFXScript.parent_for(actor)
	WaterWaveFXScript.spawn_launch(fx_parent, origin, cast_dir)

	var wave := WaterWaveEffectScript.new()
	wave.name = "WaterWaveEffect"
	fx_parent.add_child(wave)
	wave.setup(
		attacker,
		origin,
		cast_dir,
		WAVE_SPEED,
		WAVE_MAX_DISTANCE,
		WAVE_HALF_WIDTH,
		DAMAGE,
		KNOCKBACK_SPEED,
		KNOCKBACK_UP,
		PLAYER_KNOCKBACK_SPEED,
		PLAYER_KNOCKBACK_UP,
		STUN_DURATION
	)
