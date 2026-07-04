extends Node3D
class_name TcBubbleProjectile

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const CHASE_SPEED := 5.0
const DAMAGE := 1
const POP_RADIUS := 1.4
const STUN_DURATION := 0.45
const HIT_SPHERE_RADIUS := 0.42

var _attacker: Node
var _target: Node3D
var _lifetime := 3.0
var _popped := false
var _mesh: MeshInstance3D


func setup(attacker: Node, target: Node3D, lifetime: float) -> void:
	_attacker = attacker
	_target = target
	_lifetime = lifetime
	_spawn_visual()
	_setup_hit_body()
	add_to_group(&"tc_bubble")


func _spawn_visual() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.35
	sphere.height = 0.7
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(0.45, 0.82, 1.0, 0.72)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.55, 0.95)
	mat.emission_energy_multiplier = 1.4
	_mesh.material_override = mat
	add_child(_mesh)


func _setup_hit_body() -> void:
	var body := StaticBody3D.new()
	body.name = "HitBody"
	var shape_node := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = HIT_SPHERE_RADIUS
	shape_node.shape = shape
	body.add_child(shape_node)
	add_child(body)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _popped:
		return
	var direction: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	_pop_from_shot(direction)


func _physics_process(delta: float) -> void:
	if _popped:
		return

	_lifetime -= delta
	if _lifetime <= 0.0:
		_pop(false)
		return

	if _target == null or not is_instance_valid(_target):
		_pop(false)
		return

	var target_point := _get_target_point(_target)
	var to_target := target_point - global_position
	if to_target.length_squared() <= POP_RADIUS * POP_RADIUS:
		_pop(true)
		return

	var step := CHASE_SPEED * delta
	if to_target.length() <= step:
		global_position = target_point
		_pop(true)
		return

	global_position += to_target.normalized() * step


func _pop_from_shot(direction: Vector3) -> void:
	if _popped:
		return
	_popped = true

	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	else:
		flat_dir = flat_dir.normalized()

	var fx_parent := ImpactFXScript.parent_for(self)
	DirectionalImpactFXScript.spawn(fx_parent, global_position, flat_dir, 0.034)
	GameAudioScript.play_punch(_attacker, global_position)
	queue_free()


func _pop(hit: bool) -> void:
	if _popped:
		return
	_popped = true

	if hit and _target != null and is_instance_valid(_target):
		_apply_hit(_target)

	var fx_parent := ImpactFXScript.parent_for(self)
	DirectionalImpactFXScript.spawn(fx_parent, global_position, Vector3.FORWARD, 0.028)
	GameAudioScript.play_punch(_attacker, global_position)
	queue_free()


func _apply_hit(target: Node) -> void:
	if not _is_valid_target(target):
		return

	var hit_position := _get_target_point(target as Node3D)
	var hit_info := {
		"position": hit_position,
		"direction": (hit_position - global_position).normalized(),
		"shooter": _attacker,
		"damage": DAMAGE,
		"knockback_speed": 3.5,
		"knockback_up": 0.4,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"bubble_hit": true,
		"reflect_source": self,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()
	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			queue_free()
			return
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
	CombatHitFlashScript.flash_damage(target)


func _is_valid_target(target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if _attacker != null and _attacker.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(_attacker, target):
			return false
	return target.has_method("receive_bullet_hit")


func _get_target_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position + Vector3(0.0, 1.0, 0.0))
	return target.global_position + Vector3(0.0, 1.2, 0.0)
