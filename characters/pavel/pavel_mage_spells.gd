extends RefCounted
class_name PavelMageSpells

const ArcaneBoltEffectScript := preload("res://gameplay/fx/arcane_bolt_effect.gd")
const ArcaneNovaFXScript := preload("res://gameplay/fx/arcane_nova_fx.gd")
const AlertSymbolFXScript := preload("res://gameplay/fx/alert_symbol_fx.gd")
const FireWaveEffectScript := preload("res://gameplay/fx/fire_wave_effect.gd")
const FireWaveFXScript := preload("res://gameplay/fx/fire_wave_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

enum SpellKind {
	FIRE_WAVE,
	ARCANE_BOLT,
	ARCANE_NOVA,
	HASTE,
}

const BLOCK_RANGE := 3.8
const NOVA_MIN_RANGE := 2.5
const NOVA_MAX_RANGE := 8.5
const FIRE_MIN_RANGE := 6.2
const FIRE_MAX_RANGE := 13.0
const BOLT_MIN_RANGE := 7.0
const BOLT_MAX_RANGE := 16.0

const WINDUP_MIN := 0.35
const WINDUP_MAX := 0.85
const CAST_FRACTION := 0.52
const COOLDOWN := 2.4
const HASTE_COOLDOWN := 12.0

const HASTE_SPEED_MULTIPLIER := 1.5
const HASTE_DURATION := 10.0

const FIRE_DAMAGE := 1
const BOLT_DAMAGE := 1
const NOVA_DAMAGE := 2


static func get_cast_direction(actor: Node3D, aim_target: Node = null) -> Vector3:
	if actor == null:
		return Vector3.FORWARD
	if aim_target is Node3D and is_instance_valid(aim_target):
		var to_target := (aim_target as Node3D).global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			return to_target.normalized()
	if actor.has_method("get_punch_facing_direction"):
		var facing: Vector3 = actor.get_punch_facing_direction()
		facing.y = 0.0
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	var forward := -actor.global_transform.basis.z
	forward.y = 0.0
	if forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return forward.normalized()


static func is_in_range(actor: Node3D, target: Node3D, min_range: float, max_range: float) -> bool:
	if actor == null or target == null:
		return false
	var offset := target.global_position - actor.global_position
	offset.y = 0.0
	var distance := offset.length()
	return distance >= min_range and distance <= max_range


static func pick_spell(actor: Node3D, target: Node3D, health: int, max_health: int, haste_active: bool) -> SpellKind:
	if not haste_active and (health <= 3 or (health < max_health and randf() < 0.18)):
		return SpellKind.HASTE

	var roll := randf()
	if is_in_range(actor, target, BOLT_MIN_RANGE, BOLT_MAX_RANGE) and roll < 0.34:
		return SpellKind.ARCANE_BOLT
	if is_in_range(actor, target, NOVA_MIN_RANGE, NOVA_MAX_RANGE) and roll < 0.58:
		return SpellKind.ARCANE_NOVA
	if is_in_range(actor, target, FIRE_MIN_RANGE, FIRE_MAX_RANGE):
		return SpellKind.FIRE_WAVE
	if is_in_range(actor, target, NOVA_MIN_RANGE, NOVA_MAX_RANGE):
		return SpellKind.ARCANE_NOVA
	if is_in_range(actor, target, BOLT_MIN_RANGE, BOLT_MAX_RANGE):
		return SpellKind.ARCANE_BOLT
	return SpellKind.FIRE_WAVE


static func get_cooldown(kind: SpellKind) -> float:
	if kind == SpellKind.HASTE:
		return HASTE_COOLDOWN
	return COOLDOWN


static func launch_spell(
	kind: SpellKind,
	attacker: Node,
	direction: Vector3,
	aim_target: Node = null
) -> void:
	match kind:
		SpellKind.FIRE_WAVE:
			launch_fire_wave(attacker, direction, aim_target)
		SpellKind.ARCANE_BOLT:
			launch_arcane_bolt(attacker, direction, aim_target)
		SpellKind.ARCANE_NOVA:
			launch_arcane_nova(attacker, direction, aim_target)
		SpellKind.HASTE:
			apply_haste_buff(attacker)


static func launch_fire_wave(
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

	var origin := actor.global_position + Vector3(0.0, 0.45, 0.0)
	origin += cast_dir * 1.35

	var fx_parent := ImpactFXScript.parent_for(actor)
	FireWaveFXScript.spawn_launch(fx_parent, origin, cast_dir)

	var wave := FireWaveEffectScript.new()
	wave.name = "FireWaveEffect"
	fx_parent.add_child(wave)
	wave.setup(
		attacker,
		origin,
		cast_dir,
		10.5,
		16.0,
		1.35,
		FIRE_DAMAGE,
		5.5,
		0.85,
		3.8,
		0.65,
		0.55
	)


static func launch_arcane_bolt(
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

	var origin := actor.global_position + Vector3(0.0, 1.05, 0.0)
	origin += cast_dir * 0.85

	var fx_parent := ImpactFXScript.parent_for(actor)
	var bolt := ArcaneBoltEffectScript.new()
	bolt.name = "ArcaneBoltEffect"
	fx_parent.add_child(bolt)
	bolt.setup(
		attacker,
		origin,
		cast_dir,
		14.0,
		18.0,
		BOLT_DAMAGE,
		4.5,
		0.55,
		0.45
	)


static func launch_arcane_nova(
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

	var center := actor.global_position + cast_dir * 3.2
	if aim_target is Node3D and is_instance_valid(aim_target):
		var to_target := (aim_target as Node3D).global_position - actor.global_position
		to_target.y = 0.0
		if to_target.length_squared() > 0.0001:
			center = (aim_target as Node3D).global_position
	center.y = actor.global_position.y + 0.15

	ArcaneNovaFXScript.detonate(
		attacker,
		center,
		3.4,
		cast_dir,
		NOVA_DAMAGE,
		6.0,
		0.9,
		0.65
	)


static func apply_haste_buff(attacker: Node) -> void:
	if attacker == null:
		return
	if attacker.has_method("receive_haste_buff"):
		attacker.receive_haste_buff(HASTE_DURATION, HASTE_SPEED_MULTIPLIER)
	spawn_haste_visual(attacker)


static func spawn_haste_visual(caster: Node) -> void:
	if not (caster is Node3D):
		return
	var fx_parent := ImpactFXScript.parent_for(caster)
	var origin := (caster as Node3D).global_position + Vector3(0.0, 1.35, 0.0)
	AlertSymbolFXScript.spawn_above(fx_parent, origin)
	SmokePuffFXScript.spawn_burst(fx_parent, origin, 4)
