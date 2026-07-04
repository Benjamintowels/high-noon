extends RefCounted
class_name TcChargeRun

const AlertSymbolFXScript := preload("res://gameplay/fx/alert_symbol_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const DirectionalImpactFXScript := preload("res://gameplay/fx/directional_impact_fx.gd")
const FactionAffinityScript := preload("res://gameplay/faction/faction_affinity.gd")
const FireWaveFXScript := preload("res://gameplay/fx/fire_wave_fx.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")

const COOLDOWN := 14.0
const WINDUP_DURATION := 0.55
const CHARGE_SPEED := 10.5
const TRACK_STRENGTH := 1.5
const MAX_TRACK_BLEND := 0.028
const MAX_DURATION := 4.0
const HIT_RADIUS := 2.8
const DAMAGE := 1
const KNOCKBACK_SPEED := 7.5
const KNOCKBACK_UP := 1.65
const STUN_DURATION := 0.85
const MIN_RANGE := 4.0
const MAX_RANGE := 34.0
const ALERT_HEAD_OFFSET := 1.15
const TRAIL_INTERVAL := 0.07
const TRAIL_BACK_OFFSET := 1.6
const CAMERA_SHAKE := 0.48
const CAMERA_SHAKE_PULSE := 0.18
const WALL_NORMAL_Y_MAX := 0.55


static func can_cast(cooldown: float) -> bool:
	return cooldown <= 0.0


static func is_in_range(boss: Node3D, target: Node3D) -> bool:
	if boss == null or target == null:
		return false
	var offset := target.global_position - boss.global_position
	offset.y = 0.0
	var distance := offset.length()
	return distance >= MIN_RANGE and distance <= MAX_RANGE


static func find_nearest_player(boss: Node) -> Node3D:
	var actor := boss as Node3D
	if actor == null:
		return null

	var tree := actor.get_tree()
	if tree == null:
		return null

	var best: Node3D = null
	var best_dist_sq := INF
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if not (node is Node3D):
			continue
		if not _is_valid_target(boss, node):
			continue
		var offset := (node as Node3D).global_position - actor.global_position
		offset.y = 0.0
		var dist_sq := offset.length_squared()
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best = node as Node3D
	return best


static func spawn_target_alert(boss: Node, target: Node3D) -> void:
	if target == null:
		return
	var fx_parent := ImpactFXScript.parent_for(boss)
	var anchor := _get_alert_anchor(target)
	AlertSymbolFXScript.spawn_above_frames(
		fx_parent,
		anchor,
		FxCatalogScript.alert_002_frames()
	)


static func update_charge_direction(
	current_direction: Vector3,
	boss: Node3D,
	target: Node3D,
	delta: float
) -> Vector3:
	var flat := current_direction
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	else:
		flat = flat.normalized()

	if target == null or not is_instance_valid(target):
		return flat

	var to_target := target.global_position - boss.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		return flat

	var desired := to_target.normalized()
	var blend := clampf(TRACK_STRENGTH * delta, 0.0, MAX_TRACK_BLEND)
	return flat.lerp(desired, blend).normalized()


static func spawn_fire_trail(boss: Node3D, direction: Vector3) -> void:
	var flat := direction
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	else:
		flat = flat.normalized()

	var fx_parent := ImpactFXScript.parent_for(boss)
	var origin := boss.global_position + Vector3(0.0, 1.0, 0.0) - flat * TRAIL_BACK_OFFSET
	FireWaveFXScript.spawn_segment(fx_parent, origin, flat)


static func apply_camera_shake_pulse(boss: Node) -> void:
	var tree := boss.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if node.has_method("apply_camera_shake"):
			node.apply_camera_shake(CAMERA_SHAKE_PULSE)


static func apply_camera_shake_hit(boss: Node) -> void:
	var tree := boss.get_tree()
	if tree == null:
		return
	for node in tree.get_nodes_in_group(&"overworld_player"):
		if node.has_method("apply_camera_shake"):
			node.apply_camera_shake(CAMERA_SHAKE)


static func check_player_hit(boss: Node3D, target: Node3D) -> bool:
	if boss == null or target == null or not is_instance_valid(target):
		return false
	var hit_point := _get_target_hit_point(target)
	var offset := hit_point - boss.global_position
	offset.y = 0.0
	return offset.length_squared() <= HIT_RADIUS * HIT_RADIUS


static func apply_player_hit(boss: Node, target: Node, direction: Vector3) -> bool:
	if not _is_valid_target(boss, target):
		return false

	var hit_position := _get_target_hit_point(target as Node3D)
	var flat_dir := direction
	flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	else:
		flat_dir = flat_dir.normalized()

	var hit_info := {
		"position": hit_position,
		"direction": flat_dir,
		"shooter": boss,
		"damage": DAMAGE,
		"knockback_speed": KNOCKBACK_SPEED,
		"knockback_up": KNOCKBACK_UP,
		"melee": true,
		"force_knockback": true,
		"melee_stun_duration": STUN_DURATION,
		"charge_run_hit": true,
	}

	if target.has_method("enter_overworld_combat"):
		target.enter_overworld_combat()
	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
		if target.has_method("was_melee_hit_absorbed") and target.was_melee_hit_absorbed():
			return true
		if target.has_method("apply_melee_stun"):
			target.apply_melee_stun(STUN_DURATION)
		MeleeHitFXScript.play(boss, target, hit_position, flat_dir)
		GameAudioScript.play_punch(boss, hit_position)
		CombatHitFlashScript.flash_damage(target)
		apply_camera_shake_hit(boss)
		return true
	return false


static func spawn_wall_impact(boss: Node3D, impact_point: Vector3, wall_normal: Vector3) -> void:
	var fx_parent := ImpactFXScript.parent_for(boss)
	var flat_normal := wall_normal
	flat_normal.y = 0.0
	if flat_normal.length_squared() < 0.0001:
		flat_normal = -boss.global_transform.basis.z
	else:
		flat_normal = flat_normal.normalized()

	DirectionalImpactFXScript.spawn(
		fx_parent,
		impact_point,
		-flat_normal,
		0.042
	)
	GameAudioScript.play_punch(boss, impact_point)


static func is_wall_collision(normal: Vector3) -> bool:
	return absf(normal.y) <= WALL_NORMAL_Y_MAX


static func is_boss_room(boss: Node) -> bool:
	var tree := boss.get_tree()
	if tree == null:
		return false
	for node in tree.get_nodes_in_group(&"caves_boss_room"):
		if node != null and is_instance_valid(node):
			return true
	return false


static func _get_alert_anchor(target: Node3D) -> Vector3:
	if target.has_method("get_threat_aim_point"):
		return target.get_threat_aim_point() + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0)
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position) + Vector3(0.0, ALERT_HEAD_OFFSET, 0.0)
	return target.global_position + Vector3(0.0, ALERT_HEAD_OFFSET + 0.8, 0.0)


static func _get_target_hit_point(target: Node3D) -> Vector3:
	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		return capsule.get("center", target.global_position)
	return target.global_position + Vector3(0.0, 1.0, 0.0)


static func _is_valid_target(boss: Node, target: Node) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if boss != null and boss.has_method("get_faction_id") and target.has_method("get_faction_id"):
		if FactionAffinityScript.are_allies(boss, target):
			return false
	return target.has_method("receive_bullet_hit")
