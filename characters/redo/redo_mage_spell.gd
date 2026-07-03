extends RefCounted
class_name RedoMageSpell

const FireWaveEffectScript := preload("res://gameplay/fx/fire_wave_effect.gd")
const FireWaveFXScript := preload("res://gameplay/fx/fire_wave_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const RedoMeleeStrikeScript := preload("res://characters/redo/redo_melee_strike.gd")

const SPELL_MIN_RANGE := RedoMeleeStrikeScript.RANGE + 1.0
const SPELL_MAX_RANGE := 13.0
const WINDUP_MIN := 0.35
const WINDUP_MAX := 0.85
const CAST_FRACTION := 0.52
const COOLDOWN := 2.8
const DAMAGE := 1
const WAVE_SPEED := 10.5
const WAVE_MAX_DISTANCE := 16.0
const WAVE_HALF_WIDTH := 1.35
const WAVE_ORIGIN_FORWARD := 1.35
const WAVE_HEIGHT := 0.45
const KNOCKBACK_SPEED := 5.5
const KNOCKBACK_UP := 0.85
const PLAYER_KNOCKBACK_SPEED := 3.8
const PLAYER_KNOCKBACK_UP := 0.65
const STUN_DURATION := 0.55


static func is_in_spell_range(actor: Node3D, target: Node3D) -> bool:
	if actor == null or target == null:
		return false
	var offset := target.global_position - actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	return distance >= SPELL_MIN_RANGE and distance <= SPELL_MAX_RANGE


static func get_cast_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	return RedoMeleeStrikeScript.get_strike_direction(actor, aim_target)


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
	FireWaveFXScript.spawn_launch(fx_parent, origin, cast_dir)

	var wave := FireWaveEffectScript.new()
	wave.name = "FireWaveEffect"
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
