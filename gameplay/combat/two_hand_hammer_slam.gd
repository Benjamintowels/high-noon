extends RefCounted
class_name TwoHandHammerSlam

## Ground-slam AOE for the player's two-handed war hammer: the overhead strike
## detonates a mini explosion at the impact point that deals 1 damage and
## launches everything nearby, on top of the 1-damage direct weapon hit.

const MeleeSwordSlashScript := preload("res://gameplay/combat/melee_sword_slash.gd")
const HammerAoeFXScript := preload("res://gameplay/fx/hammer_aoe_fx.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const SLAM_RADIUS := 3.0
const SLAM_DAMAGE := 1
const KNOCKBACK_SPEED := 13.0
const KNOCKBACK_UP := 2.2
const STUN_DURATION := 1.1
const CAMERA_SHAKE := 0.95
const SLAM_FORWARD_OFFSET_SCALE := 0.55


## Detonates the slam in front of the attacker. Returns how many targets it hit.
static func apply_slam(attacker: Node3D, direction: Vector3, strike_range: float) -> int:
	if attacker == null:
		return 0
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = -attacker.global_transform.basis.z
		flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	flat_dir = flat_dir.normalized()

	var center := attacker.global_position + flat_dir * strike_range * SLAM_FORWARD_OFFSET_SCALE
	var ground_center := center + Vector3(0.0, 0.1, 0.0)
	var fx_parent := ImpactFXScript.parent_for(attacker)
	HammerAoeFXScript.spawn(fx_parent, ground_center, SLAM_RADIUS)
	GameAudioScript.play_explosion(attacker, ground_center)
	if attacker.has_method("apply_camera_shake"):
		attacker.apply_camera_shake(CAMERA_SHAKE)
	return _apply_slam_hits(attacker, flat_dir, ground_center)


static func _apply_slam_hits(attacker: Node3D, direction: Vector3, center: Vector3) -> int:
	var tree := attacker.get_tree()
	if tree == null:
		return 0

	var radius_sq := SLAM_RADIUS * SLAM_RADIUS
	var hit_count := 0
	var seen: Dictionary = {}
	for group_name: StringName in [&"cave_enemy", &"duel_target"]:
		for node in tree.get_nodes_in_group(group_name):
			if seen.has(node.get_instance_id()):
				continue
			seen[node.get_instance_id()] = true
			if node == attacker or not (node is Node3D):
				continue
			if not MeleeSwordSlashScript._is_valid_strike_target(attacker, node):
				continue

			var anchor: Vector3 = MeleeSwordSlashScript._get_target_anchor(node as Node3D)
			var offset := anchor - center
			offset.y = 0.0
			if offset.length_squared() > radius_sq:
				continue

			# Blast targets radially outward from the slam point.
			var knock_dir := direction
			if offset.length_squared() > 0.0001:
				knock_dir = offset.normalized()

			var hit_info := {
				"position": anchor,
				"direction": knock_dir,
				"shooter": attacker,
				"damage": SLAM_DAMAGE,
				"knockback_speed": KNOCKBACK_SPEED,
				"knockback_up": KNOCKBACK_UP,
				"melee": true,
				"force_knockback": true,
				"melee_stun_duration": STUN_DURATION,
				"slam_hit": true,
				"heavy_hit": true,
			}
			if node.has_method("enter_overworld_combat"):
				node.enter_overworld_combat()
			if node.has_method("receive_bullet_hit"):
				node.receive_bullet_hit(hit_info)
				if node.has_method("apply_melee_stun"):
					node.apply_melee_stun(STUN_DURATION)
				hit_count += 1
	return hit_count
