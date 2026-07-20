extends RefCounted
class_name TcSlamAttack

const TcMeleeStrikeScript := preload("res://characters/tc/tc_melee_strike.gd")
const HammerAoeFXScript := preload("res://gameplay/fx/hammer_aoe_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const JUMP_HEIGHT := 5.5
const JUMP_DURATION := 0.55
const FALL_FORWARD_SPEED := 9.0
const SLAM_RADIUS := 6.5
const SLAM_DAMAGE := 2
const PLAYER_KNOCKBACK_SPEED := 7.5
const PLAYER_KNOCKBACK_UP := 1.4
const KNOCKBACK_SPEED := 9.0
const KNOCKBACK_UP := 1.5
const STUN_DURATION := 1.2
const CAMERA_SHAKE := 1.35
const PILLAR_TOPPLE_POWER := 8500


static func apply_slam_landing(
	attacker: Node,
	direction: Vector3,
	locked_ground_pos: Vector3 = Vector3.INF
) -> void:
	var actor := attacker as Node3D
	if actor == null:
		return

	var strike_dir := TcMeleeStrikeScript.get_strike_direction(actor, null)
	if direction.length_squared() > 0.0001:
		var flat := direction
		flat.y = 0.0
		if flat.length_squared() > 0.0001:
			strike_dir = flat.normalized()

	var center := actor.global_position
	if locked_ground_pos != Vector3.INF:
		center = locked_ground_pos
	var ground_center := Vector3(center.x, center.y + 0.08, center.z)
	var fx_parent := ImpactFXScript.parent_for(actor)
	HammerAoeFXScript.spawn(fx_parent, ground_center, SLAM_RADIUS)
	GameAudioScript.play_punch(actor, ground_center)
	TcMeleeStrikeScript._topple_nearby_pillars(actor, ground_center, SLAM_RADIUS)
	_shake_player(actor, CAMERA_SHAKE)
	_apply_slam_hits(attacker, strike_dir, ground_center)


static func _apply_slam_hits(attacker: Node, direction: Vector3, center: Vector3) -> void:
	var tree := attacker.get_tree()
	if tree == null:
		return

	var radius_sq := SLAM_RADIUS * SLAM_RADIUS
	for group_name: StringName in [&"overworld_player", &"crusader_npc", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == attacker or not (node is Node3D):
				continue
			if not TcMeleeStrikeScript._is_valid_strike_target(attacker, node):
				continue
			var point := TcMeleeStrikeScript._get_target_strike_point(node as Node3D)
			var offset := point - center
			offset.y = 0.0
			if offset.length_squared() > radius_sq:
				continue

			var knockback_speed := KNOCKBACK_SPEED
			var knockback_up := KNOCKBACK_UP
			if node.is_in_group(&"overworld_player"):
				knockback_speed = PLAYER_KNOCKBACK_SPEED
				knockback_up = PLAYER_KNOCKBACK_UP

			var hit_info := {
				"position": point,
				"direction": direction,
				"shooter": attacker,
				"damage": SLAM_DAMAGE,
				"knockback_speed": knockback_speed,
				"knockback_up": knockback_up,
				"melee": true,
				"force_knockback": true,
				"melee_stun_duration": STUN_DURATION,
				"slam_hit": true,
			}
			if node.has_method("enter_overworld_combat"):
				node.enter_overworld_combat()
			if node.has_method("receive_bullet_hit"):
				node.receive_bullet_hit(hit_info)
				if node.has_method("apply_melee_stun"):
					node.apply_melee_stun(STUN_DURATION)


static func _shake_player(origin: Node3D, strength: float) -> void:
	var tree := origin.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if node.has_method("apply_camera_shake"):
			node.apply_camera_shake(strength)
