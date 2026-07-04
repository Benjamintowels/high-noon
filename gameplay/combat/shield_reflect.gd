extends RefCounted
class_name ShieldReflect

const CombatKnockdownScript := preload("res://gameplay/combat/combat_knockdown.gd")
const MeleeBlockFXScript := preload("res://gameplay/fx/melee_block_fx.gd")
const ReflectedProjectileScript := preload("res://gameplay/combat/reflected_projectile.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const WINDOW_DURATION := 0.32
const TOTAL_DURATION := 0.95
const COOLDOWN := 1.1
const FACING_DOT_MIN := 0.25
const REFLECTED_PROJECTILE_ORIGIN_Y := 1.1


static func is_projectile_hit(hit_info: Dictionary) -> bool:
	if bool(hit_info.get("bubble_hit", false)):
		return true
	if bool(hit_info.get("fire_wave_hit", false)):
		return true
	if bool(hit_info.get("water_wave_hit", false)):
		return true
	if bool(hit_info.get("knife_throw", false)):
		return true
	if bool(hit_info.get("arrow_hit", false)):
		return true
	if bool(hit_info.get("reflected_hit", false)):
		return false
	return not bool(hit_info.get("melee", false))


static func is_facing_attack(defender: Node3D, hit_info: Dictionary) -> bool:
	if defender == null:
		return false
	if not defender.has_method("_get_melee_flat_forward"):
		return true

	var forward: Vector3 = defender.call("_get_melee_flat_forward")
	if forward.length_squared() < 0.0001:
		return true

	var attacker: Node = hit_info.get("shooter")
	if attacker is Node3D:
		var to_attacker := (attacker as Node3D).global_position - defender.global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return forward.dot(to_attacker.normalized()) >= FACING_DOT_MIN

	var attack_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	attack_dir.y = 0.0
	if attack_dir.length_squared() < 0.0001:
		return true
	return forward.dot(attack_dir.normalized()) <= -FACING_DOT_MIN


static func get_look_direction(defender: Node3D) -> Vector3:
	if defender != null and defender.has_method("_get_melee_flat_forward"):
		var look_forward: Vector3 = defender.call("_get_melee_flat_forward")
		if look_forward.length_squared() > 0.0001:
			return look_forward.normalized()
	if defender == null:
		return Vector3.FORWARD
	var basis := defender.global_transform.basis
	var flat_forward := -basis.z
	flat_forward.y = 0.0
	if flat_forward.length_squared() < 0.0001:
		return Vector3.FORWARD
	return flat_forward.normalized()


static func get_reflect_direction(defender: Node3D, attacker: Node) -> Vector3:
	if defender != null and attacker is Node3D and is_instance_valid(attacker):
		var to_attacker := (attacker as Node3D).global_position - defender.global_position
		to_attacker.y = 0.0
		if to_attacker.length_squared() > 0.0001:
			return to_attacker.normalized()
	return get_look_direction(defender)


static func resolve_hit(defender: Node3D, hit_info: Dictionary) -> void:
	var attacker: Node = hit_info.get("shooter")
	var contact: Vector3 = hit_info.get("position", defender.global_position)
	var direction: Vector3 = get_reflect_direction(defender, attacker)

	MeleeBlockFXScript.play(defender, attacker, contact, direction)
	GameAudioScript.play_punch(defender, contact)
	cancel_reflect_source(hit_info)

	if is_projectile_hit(hit_info):
		spawn_reflected_projectile(defender, attacker, contact, direction)
	else:
		CombatKnockdownScript.apply_from_reflect(attacker, defender, hit_info)


static func cancel_reflect_source(hit_info: Dictionary) -> void:
	var source: Variant = hit_info.get("reflect_source")
	if source == null or not (source is Node):
		return
	var node := source as Node
	if not is_instance_valid(node):
		return
	if node.has_method("cancel_for_reflect"):
		node.call("cancel_for_reflect")
	else:
		node.queue_free()


static func spawn_reflected_projectile(
	defender: Node3D,
	original_attacker: Node,
	origin: Vector3,
	direction: Vector3
) -> void:
	var fx_parent := ImpactFXScript.parent_for(defender)
	var projectile := ReflectedProjectileScript.new()
	projectile.name = "ReflectedProjectile"
	fx_parent.add_child(projectile)
	projectile.setup(defender, original_attacker, origin, direction)
