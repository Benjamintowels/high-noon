extends Node3D
class_name TcFallingBoulder

const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const HammerAoeFXScript := preload("res://gameplay/fx/hammer_aoe_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const TcMeleeStrikeScript := preload("res://characters/tc/tc_melee_strike.gd")

const GRAVITY := 32.0
const IMPACT_RADIUS := 3.2
const DAMAGE := 1
const KNOCKBACK_SPEED := 6.5
const KNOCKBACK_UP := 1.0
const PLAYER_KNOCKBACK_SPEED := 5.0
const PLAYER_KNOCKBACK_UP := 0.85
const STUN_DURATION := 0.75
const CAMERA_SHAKE := 0.85
const DROP_HEIGHT := 9.0

var _attacker: Node
var _ground_y := 0.0
var _falling := true
var _velocity := Vector3.ZERO
var _mesh: MeshInstance3D


func setup(attacker: Node, ground_point: Vector3) -> void:
	_attacker = attacker
	_ground_y = ground_point.y
	global_position = Vector3(ground_point.x, ground_point.y + DROP_HEIGHT, ground_point.z)
	_build_mesh()


func _build_mesh() -> void:
	_mesh = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.55
	sphere.height = 1.1
	_mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.42, 0.36, 0.3, 1.0)
	mat.roughness = 0.92
	mat.metallic = 0.05
	_mesh.material_override = mat
	add_child(_mesh)


func _physics_process(delta: float) -> void:
	if not _falling:
		return

	_velocity.y -= GRAVITY * delta
	global_position += _velocity * delta
	if _mesh != null:
		_mesh.rotate_y(delta * 4.5)
		_mesh.rotate_x(delta * 3.2)

	if global_position.y <= _ground_y + 0.35:
		global_position.y = _ground_y + 0.35
		_impact()


func _impact() -> void:
	if not _falling:
		return
	_falling = false

	var center := Vector3(global_position.x, _ground_y + 0.08, global_position.z)
	var fx_parent := ImpactFXScript.parent_for(self)
	HammerAoeFXScript.spawn(fx_parent, center, IMPACT_RADIUS)
	GameAudioScript.play_punch(_attacker, center)
	TcMeleeStrikeScript._topple_nearby_pillars(_attacker as Node3D, center, IMPACT_RADIUS)
	_shake_nearby_players()
	_apply_aoe_hits(center)
	queue_free()


func _apply_aoe_hits(center: Vector3) -> void:
	var tree := get_tree()
	if tree == null:
		return

	var radius_sq := IMPACT_RADIUS * IMPACT_RADIUS
	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == _attacker or not (node is Node3D):
				continue
			if not _is_valid_target(node):
				continue
			var point := _get_target_point(node as Node3D)
			var offset := point - center
			offset.y = 0.0
			if offset.length_squared() > radius_sq:
				continue

			var direction := offset.normalized() if offset.length_squared() > 0.0001 else Vector3.FORWARD
			var knockback_speed := KNOCKBACK_SPEED
			var knockback_up := KNOCKBACK_UP
			if node.is_in_group(&"overworld_player"):
				knockback_speed = PLAYER_KNOCKBACK_SPEED
				knockback_up = PLAYER_KNOCKBACK_UP

			var hit_info := {
				"position": point,
				"direction": direction,
				"shooter": _attacker,
				"damage": DAMAGE,
				"knockback_speed": knockback_speed,
				"knockback_up": knockback_up,
				"melee": true,
				"force_knockback": true,
				"melee_stun_duration": STUN_DURATION,
				"boulder_hit": true,
			}
			if node.has_method("enter_overworld_combat"):
				node.enter_overworld_combat()
			if node.has_method("receive_bullet_hit"):
				node.receive_bullet_hit(hit_info)
				if node.has_method("apply_melee_stun"):
					node.apply_melee_stun(STUN_DURATION)
				CombatHitFlashScript.flash_damage(node)


func _shake_nearby_players() -> void:
	var tree := get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if node.has_method("apply_camera_shake"):
			node.apply_camera_shake(CAMERA_SHAKE)


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
	return target.global_position + Vector3(0.0, 1.0, 0.0)
