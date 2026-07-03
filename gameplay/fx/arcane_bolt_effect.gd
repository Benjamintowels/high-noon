extends Node3D
class_name ArcaneBoltEffect

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

var _attacker: Node
var _direction := Vector3.FORWARD
var _speed := 14.0
var _max_distance := 18.0
var _damage := 1
var _knockback_speed := 4.5
var _knockback_up := 0.55
var _stun_duration := 0.45
var _traveled := 0.0
var _hit := false


func setup(
	attacker: Node,
	origin: Vector3,
	direction: Vector3,
	speed: float,
	max_distance: float,
	damage: int,
	knockback_speed: float,
	knockback_up: float,
	stun_duration: float
) -> void:
	_attacker = attacker
	global_position = origin
	_direction = direction
	_direction.y = 0.0
	if _direction.length_squared() < 0.0001:
		_direction = Vector3.FORWARD
	else:
		_direction = _direction.normalized()
	_speed = speed
	_max_distance = max_distance
	_damage = damage
	_knockback_speed = knockback_speed
	_knockback_up = knockback_up
	_stun_duration = stun_duration

	var fx_parent := ImpactFXScript.parent_for(self)
	MuzzleFlashFXScript.spawn(fx_parent, origin, &"symmetrical", 0.018)
	SmokePuffFXScript.spawn_trail(fx_parent, origin + Vector3(0.0, 0.05, 0.0), 0.14)


func _physics_process(delta: float) -> void:
	if _hit or _traveled >= _max_distance:
		queue_free()
		return

	var step := minf(_speed * delta, _max_distance - _traveled)
	if step <= 0.0:
		queue_free()
		return

	global_position += _direction * step
	_traveled += step
	_try_hit()


func _try_hit() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if not (node is Node3D):
				continue
			if not _is_valid_target(node):
				continue
			if not _is_target_in_bolt(node as Node3D):
				continue
			_apply_hit(node)
			_hit = true
			queue_free()
			return


func _is_target_in_bolt(target: Node3D) -> bool:
	var point := _get_target_point(target)
	var offset := point - global_position
	offset.y = 0.0
	return offset.length_squared() <= 0.55 * 0.55


func _apply_hit(target: Node) -> void:
	var hit_position := _get_target_point(target as Node3D)
	var hit_info := {
		"position": hit_position,
		"direction": _direction,
		"shooter": _attacker,
		"damage": _damage,
		"knockback_speed": _knockback_speed,
		"knockback_up": _knockback_up,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": _stun_duration,
		"arcane_bolt_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()
	if not target.has_method("receive_bullet_hit"):
		return

	target.receive_bullet_hit(hit_info)
	if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
		return
	if target.has_method("apply_melee_stun"):
		target.apply_melee_stun(_stun_duration)
	CombatHitFlashScript.flash_damage(target)
	var fx_parent := ImpactFXScript.parent_for(self)
	DirectionalImpactFXScript.spawn(fx_parent, hit_position, _direction, 0.028)
	GameAudioScript.play_punch(_attacker, hit_position)


func _is_valid_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target == _attacker:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if _attacker != null and _attacker.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(_attacker, target):
			return false
	if not target.has_method("receive_bullet_hit"):
		return false
	return true


func _get_target_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.0, 0.0))
	return target.global_position + Vector3(0.0, 1.0, 0.0)
