extends Node
class_name UnarmedParryThrow
## Drives the victim of a successful unarmed parry: ragdolled and spun around
## the player during the Skill 2 animation, then tossed in an arc as a live
## projectile. The victim's own lasso-captured physics branch (gravity +
## move_and_slide, AI suspended) does the flying; this node steers it.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ParryTossFXScript := preload("res://gameplay/fx/parry_toss_fx.gd")
const CombatHitFlashScript := preload("res://gameplay/fx/combat_hit_flash.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")
const MeleePunchScript := preload("res://gameplay/combat/melee_punch.gd")

const SPIN_RADIUS := 0.9
const SPIN_CENTER_HEIGHT := 0.92
const SPIN_CENTER_FORWARD := 0.28
const SPIN_REVOLUTIONS := 1.0
const TOSS_RELEASE_RADIUS := 0.72
const TOSS_RELEASE_HEIGHT := 0.75
const TOSS_FORWARD_SPEED := 9.5
const TOSS_UP_SPEED := 6.0
const BOUNCE_UP_SPEED := 3.4
const BOUNCE_HORIZONTAL_KEEP := 0.72
const SLIDE_DECAY := 0.86
const SLIDE_STOP_SPEED := 0.8
const TRAIL_INTERVAL := 0.09
const HIT_RADIUS := 0.6
## The flying ragdoll sprawls wide — props use a fatter contact radius so
## skimming a tabletop still counts as a crash.
const PROP_HIT_RADIUS := 0.9
const HIT_HEIGHT_OFFSET := 0.5
const BASE_DAMAGE := 1
const VICTIM_HIT_DAMAGE := 1
const FLY_SAFETY_SECONDS := 6.0
const MIN_AIR_TIME_BEFORE_GROUND := 0.12
const CORPSE_FLY_SAFETY_SECONDS := 2.5
const CORPSE_STRIKE_MIN_SPEED := 2.0

enum Phase { SPIN, FLY, SLIDE, RECOVER, DONE, CORPSE_FLY }

var _player: Node3D
var _victim: CharacterBody3D
var _ragdoll: Node
var _phase := Phase.SPIN
var _spin_duration := 1.4
var _spin_timer := 0.0
var _spin_angle0 := 0.0
var _air_time := 0.0
var _fly_elapsed := 0.0
var _trail_timer := 0.0
var _bounces := 0
var _hit_count := 0
var _struck_ids: Dictionary = {}
var _last_toss_dir := Vector3.FORWARD
var _fly_horizontal := Vector3.ZERO
var _corpse_last_pos := Vector3.ZERO


static func is_grab_victim_eligible(grabber: Node, victim: Node) -> bool:
	if not is_spin_throw_victim_eligible(grabber, victim):
		return false
	# Proactive Q grab ignores mid-swing targets; counters use is_counter_grab_victim_eligible.
	if victim.has_method("is_unarmed_melee_attacking") and victim.is_unarmed_melee_attacking():
		return false
	return true


## Shared lasso/ragdoll gates for spin throws (proactive or counter).
static func is_spin_throw_victim_eligible(grabber: Node, victim: Node) -> bool:
	if victim == null or not is_instance_valid(victim) or victim == grabber:
		return false
	if not (victim is CharacterBody3D):
		return false
	if victim.has_method("is_defeated") and victim.is_defeated():
		return false
	if not victim.has_method("begin_lasso_capture") or not victim.has_method("get_lasso_ragdoll"):
		return false
	if victim.has_method("is_lassoable") and not victim.is_lassoable():
		return false
	if victim.has_method("is_hostage_captured") and victim.is_hostage_captured():
		return false
	return true


## Counter-grab may snatch an attacker mid-swing.
static func is_counter_grab_victim_eligible(grabber: Node, victim: Node) -> bool:
	return is_spin_throw_victim_eligible(grabber, victim)


static func find_grab_target(grabber: Node3D, direction: Vector3) -> CharacterBody3D:
	if grabber == null or direction.length_squared() < 0.0001:
		return null

	var tree := grabber.get_tree()
	if tree == null:
		return null

	var grab_dir := direction.normalized()
	var best_target: CharacterBody3D = null
	var best_score := INF
	var seen: Dictionary = {}
	var grab_range := MeleePunchScript.RANGE

	for node in tree.get_nodes_in_group(&"duel_target"):
		if seen.has(node.get_instance_id()):
			continue
		seen[node.get_instance_id()] = true
		if not is_grab_victim_eligible(grabber, node):
			continue

		var target := node as Node3D
		var to_target := target.global_position - grabber.global_position
		to_target.y = 0.0
		var distance_sq := to_target.length_squared()
		if distance_sq > grab_range * grab_range or distance_sq < 0.0001:
			continue

		var flat_dir := to_target.normalized()
		if flat_dir.dot(grab_dir) < MeleePunchScript.ARC_DOT_MIN:
			continue

		if distance_sq < best_score:
			best_score = distance_sq
			best_target = target as CharacterBody3D

	return best_target


func _get_spin_center() -> Vector3:
	var center := _player.global_position + Vector3(0.0, SPIN_CENTER_HEIGHT, 0.0)
	if _player != null and _player.has_method("get_punch_facing_direction"):
		var facing: Vector3 = _player.get_punch_facing_direction()
		if facing.length_squared() > 0.0001:
			center += facing.normalized() * SPIN_CENTER_FORWARD
	return center


func begin(player: Node3D, victim: CharacterBody3D, spin_duration: float) -> void:
	_player = player
	_victim = victim
	_spin_duration = maxf(spin_duration, 0.5)
	_spin_timer = _spin_duration

	var to_victim := victim.global_position - player.global_position
	to_victim.y = 0.0
	if to_victim.length_squared() < 0.0001:
		to_victim = Vector3.FORWARD
	_spin_angle0 = atan2(to_victim.x, to_victim.z)

	if victim.has_method("begin_lasso_capture"):
		victim.begin_lasso_capture(null, SPIN_RADIUS)
	if victim.has_method("get_lasso_ragdoll"):
		_ragdoll = victim.get_lasso_ragdoll()
	if _ragdoll != null and _ragdoll.has_method("activate_lasso_drag"):
		var anim_player: AnimationPlayer = null
		if victim.has_method("get_lasso_animation_player"):
			anim_player = victim.get_lasso_animation_player()
		_ragdoll.activate_lasso_drag(to_victim.normalized(), anim_player)


## Hostage shove: skip the spin and launch the victim forward like the toss.
func begin_shove(player: Node3D, victim: CharacterBody3D, direction: Vector3) -> void:
	_player = player
	_victim = victim
	_last_toss_dir = direction
	_phase = Phase.FLY

	if victim.has_method("begin_lasso_capture"):
		victim.begin_lasso_capture(null, SPIN_RADIUS)
	if victim.has_method("get_lasso_ragdoll"):
		_ragdoll = victim.get_lasso_ragdoll()

	var dir := direction
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	_last_toss_dir = dir

	_victim.global_position = (
		player.global_position
		+ dir * TOSS_RELEASE_RADIUS
		+ Vector3(0.0, TOSS_RELEASE_HEIGHT, 0.0)
	)
	_victim.velocity = Vector3.ZERO
	_fly_horizontal = dir * TOSS_FORWARD_SPEED
	if _ragdoll != null and _ragdoll.has_method("activate_lasso_drag"):
		var anim_player: AnimationPlayer = null
		if victim.has_method("get_lasso_animation_player"):
			anim_player = victim.get_lasso_animation_player()
		_ragdoll.activate_lasso_drag(dir, anim_player)
	if _ragdoll != null and _ragdoll.has_method("launch_airborne"):
		_ragdoll.launch_airborne(_fly_horizontal + Vector3.UP * TOSS_UP_SPEED)

	ParryTossFXScript.spawn_toss_burst(_victim.get_parent(), _victim.global_position, dir)
	GameAudioScript.play_sword_swing(_victim, _victim.global_position)

	_air_time = 0.0
	_fly_elapsed = 0.0
	_trail_timer = 0.0


## Dead-victim variant (flying kick kills): the defeat ragdoll already flies
## its own launch arc, so nothing here steers the body — this just rides along
## and strikes whatever the corpse clips, same as the live toss.
func begin_corpse_flight(player: Node3D, victim: CharacterBody3D, direction: Vector3) -> void:
	_player = player
	_victim = victim
	_phase = Phase.CORPSE_FLY

	var dir := direction
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	_last_toss_dir = dir
	_fly_horizontal = dir * TOSS_FORWARD_SPEED
	_corpse_last_pos = victim.global_position
	_struck_ids[victim.get_instance_id()] = true

	_fly_elapsed = 0.0
	_trail_timer = 0.0


func _update_corpse_flight(delta: float) -> void:
	_fly_elapsed += delta
	_trail_timer -= delta

	var pos := _victim.global_position
	var moved := pos - _corpse_last_pos
	_corpse_last_pos = pos
	var speed := moved.length() / maxf(delta, 0.0001)

	if speed >= CORPSE_STRIKE_MIN_SPEED:
		if _trail_timer <= 0.0:
			_trail_timer = TRAIL_INTERVAL
			ParryTossFXScript.spawn_trail_puff(
				_victim.get_parent(),
				pos + Vector3(0.0, HIT_HEIGHT_OFFSET, 0.0)
			)
		_strike_along_path(Vector3(moved.x, 0.0, moved.z))

	# Done once the body has come to rest (after a brief takeoff grace) or on
	# the safety timeout.
	if (
		_fly_elapsed > CORPSE_FLY_SAFETY_SECONDS
		or (_fly_elapsed > 0.3 and speed < CORPSE_STRIKE_MIN_SPEED * 0.5)
	):
		_phase = Phase.DONE


func _physics_process(delta: float) -> void:
	if _victim == null or not is_instance_valid(_victim):
		queue_free()
		return

	match _phase:
		Phase.SPIN:
			_update_spin(delta)
		Phase.FLY:
			_update_fly(delta)
		Phase.SLIDE:
			_update_slide(delta)
		Phase.RECOVER:
			_update_recover(delta)
		Phase.CORPSE_FLY:
			_update_corpse_flight(delta)
		Phase.DONE:
			queue_free()


func _update_spin(delta: float) -> void:
	if _player == null or not is_instance_valid(_player):
		_toss()
		return

	_spin_timer -= delta
	var progress := 1.0 - clampf(_spin_timer / _spin_duration, 0.0, 1.0)
	var angle := _spin_angle0 + progress * TAU * SPIN_REVOLUTIONS
	var offset := Vector3(sin(angle), 0.0, cos(angle)) * SPIN_RADIUS
	_victim.global_position = _get_spin_center() + offset
	_victim.velocity = Vector3.ZERO

	var tangent := Vector3(cos(angle), 0.0, -sin(angle))
	if _ragdoll != null and _ragdoll.has_method("update_lasso_pull"):
		_ragdoll.update_lasso_pull(tangent * 6.0, delta)

	# The swung body is already a weapon mid-spin: sweep-hit anything in the
	# orbit with tangential knockback.
	_strike_along_path(tangent)

	if _spin_timer <= 0.0:
		_toss()


func _toss() -> void:
	var dir := Vector3.FORWARD
	if _player != null and is_instance_valid(_player) and _player.has_method("get_parry_throw_direction"):
		dir = _player.get_parry_throw_direction()
	elif _player != null and is_instance_valid(_player) and _player.has_method("get_punch_facing_direction"):
		dir = _player.get_punch_facing_direction()
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	dir = dir.normalized()
	_last_toss_dir = dir

	# Release from the player's side along the toss direction.
	if _player != null and is_instance_valid(_player):
		_victim.global_position = (
			_player.global_position
			+ dir * TOSS_RELEASE_RADIUS
			+ Vector3(0.0, TOSS_RELEASE_HEIGHT, 0.0)
		)
	_victim.velocity = Vector3.ZERO
	_fly_horizontal = dir * TOSS_FORWARD_SPEED
	if _ragdoll != null and _ragdoll.has_method("launch_airborne"):
		_ragdoll.launch_airborne(_fly_horizontal + Vector3.UP * TOSS_UP_SPEED)

	ParryTossFXScript.spawn_toss_burst(_victim.get_parent(), _victim.global_position, dir)
	GameAudioScript.play_sword_swing(_victim, _victim.global_position)

	if _player != null and is_instance_valid(_player) and _player.has_method("notify_parry_throw_released"):
		_player.notify_parry_throw_released()

	_phase = Phase.FLY
	_air_time = 0.0
	_fly_elapsed = 0.0
	_trail_timer = 0.0


func _update_fly(delta: float) -> void:
	_fly_elapsed += delta
	_air_time += delta
	_trail_timer -= delta
	_victim.velocity = Vector3.ZERO
	if _trail_timer <= 0.0:
		_trail_timer = TRAIL_INTERVAL
		ParryTossFXScript.spawn_trail_puff(
			_victim.get_parent(),
			_victim.global_position + Vector3(0.0, HIT_HEIGHT_OFFSET, 0.0)
		)

	_strike_along_path()
	_check_wall_impact(delta)

	var airborne: bool = _ragdoll != null and _ragdoll.has_method("is_airborne") and _ragdoll.is_airborne()
	if not airborne and _air_time > MIN_AIR_TIME_BEFORE_GROUND:
		_bounces += 1
		if _bounces == 1:
			_fly_horizontal *= BOUNCE_HORIZONTAL_KEEP
			if _ragdoll.has_method("launch_airborne"):
				_ragdoll.launch_airborne(_fly_horizontal + Vector3.UP * BOUNCE_UP_SPEED)
			ParryTossFXScript.spawn_bounce_flash(_victim.get_parent(), _victim.global_position)
			GameAudioScript.play_knife_thud(_victim, _victim.global_position)
			_air_time = 0.0
		else:
			GameAudioScript.play_knife_thud(_victim, _victim.global_position)
			if _ragdoll.has_method("end_airborne_to_lasso_drag"):
				_ragdoll.end_airborne_to_lasso_drag()
			_phase = Phase.SLIDE
	elif _fly_elapsed > FLY_SAFETY_SECONDS:
		if _ragdoll != null and _ragdoll.has_method("end_airborne_to_lasso_drag"):
			_ragdoll.end_airborne_to_lasso_drag()
		_phase = Phase.SLIDE


## The airborne integration only tracks the floor, so stop the arc when the
## body is about to fly through a wall.
func _check_wall_impact(delta: float) -> void:
	if _fly_horizontal.length_squared() < 0.01:
		return
	var space := _victim.get_world_3d().direct_space_state
	var from := _victim.global_position + Vector3(0.0, HIT_HEIGHT_OFFSET, 0.0)
	var to := from + _fly_horizontal.normalized() * (_fly_horizontal.length() * delta + 0.45)
	var query := PhysicsRayQueryParameters3D.create(from, to, 1)
	query.exclude = [_victim.get_rid()]
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return
	_hit_count += 1
	GameAudioScript.play_knife_thud(_victim, hit.position)
	_fly_horizontal = Vector3.ZERO
	if _ragdoll != null and _ragdoll.has_method("launch_airborne") and _ragdoll.is_airborne():
		_ragdoll.launch_airborne(Vector3.ZERO)


func _update_slide(delta: float) -> void:
	# Skid along the ground in drag mode: the body slides, the ragdoll visual
	# follows, and it grinds to a quick stop.
	_fly_horizontal *= SLIDE_DECAY
	_victim.velocity.x = _fly_horizontal.x
	_victim.velocity.z = _fly_horizontal.z
	if _ragdoll != null and _ragdoll.has_method("update_lasso_pull"):
		_ragdoll.update_lasso_pull(_fly_horizontal, delta)
	var horizontal_speed := _fly_horizontal.length()
	if horizontal_speed > 2.0:
		_strike_along_path()
	if horizontal_speed < SLIDE_STOP_SPEED:
		_victim.velocity = Vector3.ZERO
		_finish_landing(delta)


func _finish_landing(_delta: float) -> void:
	_victim.velocity = Vector3.ZERO

	var total_damage := BASE_DAMAGE + _hit_count
	if _victim.has_method("receive_bullet_hit") and not _is_victim_defeated():
		_victim.receive_bullet_hit({
			"damage": total_damage,
			"melee": true,
			"direction": _last_toss_dir,
			"position": _victim.global_position + Vector3(0.0, HIT_HEIGHT_OFFSET, 0.0),
			"shooter": _player,
		})

	if _is_victim_defeated():
		if _victim.has_method("end_lasso_capture"):
			_victim.end_lasso_capture()
		_phase = Phase.DONE
		return

	if _ragdoll != null and _ragdoll.has_method("deactivate_lasso_drag"):
		_ragdoll.deactivate_lasso_drag()
	_phase = Phase.RECOVER


func _update_recover(delta: float) -> void:
	_victim.velocity = Vector3.ZERO
	if _victim.has_method("is_lasso_standup_active") and _victim.is_lasso_standup_active():
		if _victim.has_method("update_lasso_drag_standup"):
			_victim.update_lasso_drag_standup(delta)
		return

	if _ragdoll != null and _ragdoll.has_method("is_active") and _ragdoll.is_active():
		return

	if _victim.has_method("end_lasso_capture"):
		_victim.end_lasso_capture()
	if (
		not _is_victim_defeated()
		and _victim.has_method("enter_melee_aggro")
		and _player != null
		and is_instance_valid(_player)
	):
		_victim.enter_melee_aggro(_player)
	_phase = Phase.DONE


func _is_victim_defeated() -> bool:
	return _victim.has_method("is_defeated") and _victim.is_defeated()


## The flying body is a weapon: anything it clips takes a hit, and every new
## thing struck adds +1 to the damage the victim takes on landing.
func _strike_along_path(override_dir: Vector3 = Vector3.ZERO) -> void:
	var body_center := _victim.global_position + Vector3(0.0, HIT_HEIGHT_OFFSET, 0.0)
	var motion_dir := override_dir
	if motion_dir.length_squared() < 0.0001:
		motion_dir = Vector3(_fly_horizontal.x, 0.0, _fly_horizontal.z)
	motion_dir = motion_dir.normalized() if motion_dir.length_squared() > 0.0001 else _last_toss_dir
	var tree := _victim.get_tree()
	if tree == null:
		return

	for node in tree.get_nodes_in_group(&"duel_target"):
		if node == _victim or node == _player or not (node is Node3D):
			continue
		if _struck_ids.has(node.get_instance_id()):
			continue
		if not node.has_method("receive_bullet_hit"):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		var target := node as Node3D
		var target_center := target.global_position + Vector3(0.0, 1.0, 0.0)
		if body_center.distance_to(target_center) > HIT_RADIUS + 0.5:
			continue
		_struck_ids[node.get_instance_id()] = true
		_hit_count += 1
		node.receive_bullet_hit({
			"damage": VICTIM_HIT_DAMAGE,
			"melee": true,
			"punch_hit": true,
			"direction": motion_dir,
			"position": target_center,
			"shooter": _player,
			"knockback_speed": 4.0,
			"knockback_up": 0.9,
		})
		MeleeHitFXScript.play(_player, node, target_center, motion_dir)
		GameAudioScript.play_punch(_victim, target_center)

	for node in tree.get_nodes_in_group(&"punchable_prop"):
		if not (node is Node3D) or not node.has_method("receive_punch"):
			continue
		if _struck_ids.has(node.get_instance_id()):
			continue
		var prop := node as Node3D
		# Props like tables carry their visual at a baked offset from the
		# node origin — ask them where they really are and how big.
		var prop_center := prop.global_position + Vector3(0.0, 0.5, 0.0)
		if node.has_method("get_prop_center"):
			prop_center = node.get_prop_center()
		if node.has_method("get_prop_half_extents"):
			# Closest-point-on-box: correct for wide flat props like tables.
			var half: Vector3 = node.get_prop_half_extents()
			var to_local: Vector3 = prop.global_transform.basis.inverse() * (body_center - prop_center)
			var closest := to_local.clamp(-half, half)
			if (to_local - closest).length() > PROP_HIT_RADIUS:
				continue
		else:
			var contact_radius := 0.4
			if node.has_method("get_prop_contact_radius"):
				contact_radius = node.get_prop_contact_radius()
			if body_center.distance_to(prop_center) > PROP_HIT_RADIUS + contact_radius:
				continue
		_struck_ids[node.get_instance_id()] = true
		_hit_count += 1
		node.receive_punch({
			"direction": motion_dir,
			"position": _victim.global_position,
			"shooter": _player,
			"melee": true,
			"thrown_body": _phase != Phase.SPIN,
			"thrown_victim": _victim,
		})
