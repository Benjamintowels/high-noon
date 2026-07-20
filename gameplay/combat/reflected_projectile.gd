extends Node3D
class_name ReflectedProjectile

const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const CombatKnockdownScript := preload("res://gameplay/combat/combat_knockdown.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FireWaveFXScript := preload("res://gameplay/fx/fire_wave_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")

const SPEED := 14.0
const MAX_RANGE := 42.0
const HIT_RADIUS := 0.85
const BOSS_HIT_RADIUS := 2.5
const DAMAGE := 1
const KNOCKBACK_SPEED := 6.5
const KNOCKBACK_UP := 0.75
const STUN_DURATION := 0.65
const SPAWN_FORWARD := 0.75
const SPAWN_HEIGHT := 1.1

var _defender: Node
var _original_attacker: Node
var _direction := Vector3.FORWARD
var _traveled := 0.0
var _hit_ids: Dictionary = {}


func setup(defender: Node, original_attacker: Node, origin: Vector3, direction: Vector3) -> void:
	_defender = defender
	_original_attacker = original_attacker
	_direction = direction
	_direction.y = 0.0
	if _direction.length_squared() < 0.0001:
		_direction = Vector3.FORWARD
	else:
		_direction = _direction.normalized()
	global_position = _compute_spawn_position(origin)
	_spawn_visual()


func _compute_spawn_position(contact: Vector3) -> Vector3:
	var spawn := contact
	if _defender is Node3D:
		spawn = (_defender as Node3D).global_position + Vector3(0.0, SPAWN_HEIGHT, 0.0)
	elif spawn.length_squared() < 0.0001:
		spawn = Vector3.ZERO
	spawn += _direction * SPAWN_FORWARD
	return spawn


func _spawn_visual() -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.28
	sphere.height = 0.56
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(1.0, 0.82, 0.28, 0.82)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.72, 0.18)
	mat.emission_energy_multiplier = 1.6
	mesh.material_override = mat
	add_child(mesh)


func _physics_process(delta: float) -> void:
	var step := SPEED * delta
	if step <= 0.0:
		return

	global_position += _direction * step
	_traveled += step

	var fx_parent := ImpactFXScript.parent_for(self)
	if int(_traveled / 0.12) != int((_traveled - step) / 0.12):
		FireWaveFXScript.spawn_segment(fx_parent, global_position, _direction)

	_try_hit_targets()

	if _traveled >= MAX_RANGE:
		queue_free()


func _try_hit_targets() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for group_name: StringName in [
		&"duel_target",
		&"overworld_player",
		&"cave_enemy",
		&"tc_boss",
		&"crusader_npc",
	]:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if node == _defender or not (node is Node3D):
				continue
			var node_id := node.get_instance_id()
			if _hit_ids.has(node_id):
				continue
			if not _is_valid_target(node):
				continue
			if not _is_target_in_radius(node as Node3D):
				continue
			_hit_ids[node_id] = true
			_apply_hit(node)


func _apply_hit(target: Node) -> void:
	var hit_position := _get_target_point(target as Node3D)
	var hit_info := {
		"position": hit_position,
		"direction": _direction,
		"shooter": _defender,
		"damage": DAMAGE,
		"knockback_speed": KNOCKBACK_SPEED,
		"knockback_up": KNOCKBACK_UP,
		"melee": false,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"reflected_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()

	if _should_apply_reflect_knockdown(target):
		CombatKnockdownScript.apply_from_reflect(target, _defender, hit_info)
		MeleeHitFXScript.play(_defender, target, hit_position, _direction)
		CombatHitFlashScript.flash_damage(target)
		queue_free()
		return

	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		MeleeHitFXScript.play(_defender, target, hit_position, _direction)
		CombatHitFlashScript.flash_damage(target)


func _should_apply_reflect_knockdown(target: Node) -> bool:
	return (
		_original_attacker != null
		and is_instance_valid(_original_attacker)
		and target == _original_attacker
	)


func _is_valid_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if _defender != null and _defender.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(_defender, target):
			return false
	return target.has_method("receive_bullet_hit")


func _is_target_in_radius(target: Node3D) -> bool:
	var point := _get_target_point(target)
	var offset := point - global_position
	offset.y = 0.0
	var radius := BOSS_HIT_RADIUS if target.is_in_group(&"tc_boss") else HIT_RADIUS
	return offset.length_squared() <= radius * radius


func _get_target_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.0, 0.0))
	return target.global_position + Vector3(0.0, 1.2, 0.0)
