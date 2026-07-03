extends Node3D
class_name FireWaveEffect

const BulletHitDamageScript := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FireWaveFXScript := preload("res://gameplay/fx/fire_wave_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const SEGMENT_INTERVAL := 0.09

var _attacker: Node
var _direction := Vector3.FORWARD
var _speed := 10.0
var _max_distance := 16.0
var _half_width := 1.35
var _damage := 1
var _knockback_speed := 5.5
var _knockback_up := 0.85
var _player_knockback_speed := 3.8
var _player_knockback_up := 0.65
var _stun_duration := 0.55

var _traveled := 0.0
var _segment_timer := 0.0
var _hit_ids: Dictionary = {}


func setup(
	attacker: Node,
	origin: Vector3,
	direction: Vector3,
	speed: float,
	max_distance: float,
	half_width: float,
	damage: int,
	knockback_speed: float,
	knockback_up: float,
	player_knockback_speed: float,
	player_knockback_up: float,
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
	_half_width = half_width
	_damage = damage
	_knockback_speed = knockback_speed
	_knockback_up = knockback_up
	_player_knockback_speed = player_knockback_speed
	_player_knockback_up = player_knockback_up
	_stun_duration = stun_duration
	_segment_timer = 0.0


func _physics_process(delta: float) -> void:
	if _traveled >= _max_distance:
		queue_free()
		return

	var step := minf(_speed * delta, _max_distance - _traveled)
	if step <= 0.0:
		queue_free()
		return

	global_position += _direction * step
	_traveled += step

	_segment_timer -= delta
	if _segment_timer <= 0.0:
		_segment_timer = SEGMENT_INTERVAL
		var fx_parent := ImpactFXScript.parent_for(self)
		FireWaveFXScript.spawn_segment(fx_parent, global_position, _direction)

	_apply_hits()


func _apply_hits() -> void:
	var tree := get_tree()
	if tree == null:
		return

	var seen: Dictionary = {}
	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == _attacker or not (node is Node3D):
				continue
			if _hit_ids.has(node.get_instance_id()):
				continue
			if not _is_valid_target(node):
				continue
			if not _is_target_in_wave(node as Node3D):
				continue
			_hit_ids[node.get_instance_id()] = true
			_apply_hit(node)


func _is_target_in_wave(target: Node3D) -> bool:
	var point := _get_target_point(target)
	var offset := point - global_position
	offset.y = 0.0
	var along := offset.dot(_direction)
	if along < -0.75 or along > _half_width * 1.35:
		return false
	var lateral := offset - _direction * along
	return lateral.length_squared() <= _half_width * _half_width


func _apply_hit(target: Node) -> void:
	var hit_position := _get_target_point(target as Node3D)
	var knockback_speed := _knockback_speed
	var knockback_up := _knockback_up
	if target.is_in_group(&"overworld_player"):
		knockback_speed = _player_knockback_speed
		knockback_up = _player_knockback_up

	var hit_info := {
		"position": hit_position,
		"direction": _direction,
		"shooter": _attacker,
		"damage": _damage,
		"knockback_speed": knockback_speed,
		"knockback_up": knockback_up,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": _stun_duration,
		"fire_wave_hit": true,
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
	DirectionalImpactFXScript.spawn(fx_parent, hit_position, _direction, 0.024)
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
