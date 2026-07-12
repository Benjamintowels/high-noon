extends Node
class_name PropHostageTake
## Holds a physics prop (a SitChair) in front of the player like a hostage
## shield. The prop absorbs incoming bullets, can be dropped with Q or hurled
## with LMB. The hurl flies a steered projectile arc like the hostage toss —
## trail puffs, strikes on whatever it clips — and the prop shatters into
## wood debris on impact. Prop counterpart of UnarmedHostageTake.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ParryTossFXScript := preload("res://gameplay/fx/parry_toss_fx.gd")
const MeleeHitFXScript := preload("res://gameplay/fx/melee_hit_fx.gd")

const HOLD_FORWARD_OFFSET := 1.05
const HOLD_HEIGHT := 0.5
const SETUP_DURATION := 0.28
const POSITION_LERP_SPEED := 14.0

# Same arc feel as UnarmedParryThrow's hostage shove.
const FLY_FORWARD_SPEED := 9.5
const FLY_UP_SPEED := 6.0
const FLY_GRAVITY := 18.0
const FLY_SPIN_SPEED := 9.0
const FLY_SAFETY_SECONDS := 4.0
const TRAIL_INTERVAL := 0.09
const HIT_RADIUS := 0.7
const NPC_HIT_DAMAGE := 1

enum Phase { SETUP, HOLD, FLY, DONE }

var _player: Node3D
var _prop: RigidBody3D
var _phase := Phase.SETUP
var _begun := false
var _setup_timer := 0.0
var _setup_from := Transform3D()
var _fly_velocity := Vector3.ZERO
var _fly_dir := Vector3.FORWARD
var _fly_elapsed := 0.0
var _trail_timer := 0.0
var _struck_ids: Dictionary = {}


func get_victim() -> Node3D:
	return _prop


func begin(player: Node3D, prop: RigidBody3D) -> void:
	_player = player
	_prop = prop
	_begun = true
	_phase = Phase.SETUP
	_setup_timer = SETUP_DURATION
	_setup_from = prop.global_transform
	if prop.has_method("begin_hostage_hold"):
		prop.begin_hostage_hold(player)


func release(_enter_aggro := false) -> void:
	if _phase == Phase.DONE or _phase == Phase.FLY:
		return
	_finish()


## Launch the held prop as a projectile. The player is released immediately;
## this node keeps steering the frozen prop through its arc.
func shove() -> void:
	if _phase != Phase.HOLD or _prop == null or not is_instance_valid(_prop):
		return
	if _player == null or not is_instance_valid(_player):
		release()
		return

	var direction := _get_player_facing()
	_fly_dir = direction
	_fly_velocity = direction * FLY_FORWARD_SPEED + Vector3.UP * FLY_UP_SPEED
	_fly_elapsed = 0.0
	_trail_timer = 0.0
	_struck_ids.clear()
	if _player != null:
		_struck_ids[_player.get_instance_id()] = true
	_struck_ids[_prop.get_instance_id()] = true
	_phase = Phase.FLY

	ParryTossFXScript.spawn_toss_burst(_prop.get_parent(), _prop.global_position, direction)
	GameAudioScript.play_sword_swing(_prop, _prop.global_position)

	if _player.has_method("notify_hostage_take_ended"):
		_player.notify_hostage_take_ended()


func _physics_process(delta: float) -> void:
	if not _begun:
		return
	if _prop == null or not is_instance_valid(_prop):
		_finish()
		return

	match _phase:
		Phase.SETUP:
			_update_setup(delta)
		Phase.HOLD:
			_update_hold(delta)
		Phase.FLY:
			_update_fly(delta)
		Phase.DONE:
			queue_free()


func _update_setup(delta: float) -> void:
	_setup_timer -= delta
	var progress := 1.0 - clampf(_setup_timer / SETUP_DURATION, 0.0, 1.0)
	var eased := smoothstep(0.0, 1.0, progress)
	_prop.global_transform = _setup_from.interpolate_with(_get_hold_transform(), eased)

	if _setup_timer <= 0.0:
		_phase = Phase.HOLD
		_prop.global_transform = _get_hold_transform()


func _update_hold(delta: float) -> void:
	var weight := 1.0 - exp(-POSITION_LERP_SPEED * delta)
	_prop.global_transform = _prop.global_transform.interpolate_with(
		_get_hold_transform(), weight
	)


func _update_fly(delta: float) -> void:
	_fly_elapsed += delta
	_trail_timer -= delta

	_fly_velocity.y -= FLY_GRAVITY * delta
	var from := _prop.global_position
	var to := from + _fly_velocity * delta

	# World impact: ray along this tick's motion (plus a lookahead margin) so
	# the prop never tunnels through a wall or the floor.
	var space := _prop.get_world_3d().direct_space_state
	var motion := to - from
	var probe_center := from + Vector3(0.0, 0.15, 0.0)
	var query := PhysicsRayQueryParameters3D.create(
		probe_center,
		probe_center + motion + motion.normalized() * 0.35,
		1
	)
	query.exclude = [_prop.get_rid()]
	var hit := space.intersect_ray(query)
	if not hit.is_empty():
		_shatter(hit.get("position", to))
		return

	_prop.global_position = to
	var tumble_axis: Vector3 = _fly_dir.cross(Vector3.UP)
	if tumble_axis.length_squared() > 0.0001:
		_prop.rotate(tumble_axis.normalized(), -FLY_SPIN_SPEED * delta)

	if _trail_timer <= 0.0:
		_trail_timer = TRAIL_INTERVAL
		ParryTossFXScript.spawn_trail_puff(_prop.get_parent(), _prop.global_position)

	if _strike_targets():
		return

	if _fly_elapsed > FLY_SAFETY_SECONDS:
		_shatter(_prop.global_position)


## The flying chair is a weapon: clip an NPC or a punchable prop and both
## sides get hit — the target takes the strike, the chair shatters.
## Returns true when the chair broke.
func _strike_targets() -> bool:
	var chair_center: Vector3 = _prop.global_position + Vector3(0.0, 0.3, 0.0)
	var tree := get_tree()
	if tree == null:
		return false

	for node in tree.get_nodes_in_group(&"duel_target"):
		if not (node is Node3D) or _struck_ids.has(node.get_instance_id()):
			continue
		if not node.has_method("receive_bullet_hit"):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		var target := node as Node3D
		var target_center := target.global_position + Vector3(0.0, 1.0, 0.0)
		if chair_center.distance_to(target_center) > HIT_RADIUS + 0.5:
			continue
		_struck_ids[node.get_instance_id()] = true
		node.receive_bullet_hit({
			"damage": NPC_HIT_DAMAGE,
			"melee": true,
			"punch_hit": true,
			"direction": _fly_dir,
			"position": target_center,
			"shooter": _player,
			"knockback_speed": 4.0,
			"knockback_up": 0.9,
		})
		MeleeHitFXScript.play(_player, node, target_center, _fly_dir)
		GameAudioScript.play_punch(target, target_center)
		_shatter(_prop.global_position)
		return true

	for node in tree.get_nodes_in_group(&"punchable_prop"):
		if not (node is Node3D) or _struck_ids.has(node.get_instance_id()):
			continue
		if not node.has_method("receive_punch"):
			continue
		var prop := node as Node3D
		var prop_center := prop.global_position + Vector3(0.0, 0.5, 0.0)
		if node.has_method("get_prop_center"):
			prop_center = node.get_prop_center()
		var contact_radius := 0.4
		if node.has_method("get_prop_contact_radius"):
			contact_radius = node.get_prop_contact_radius()
		if chair_center.distance_to(prop_center) > HIT_RADIUS + contact_radius:
			continue
		_struck_ids[node.get_instance_id()] = true
		node.receive_punch({
			"direction": _fly_dir,
			"position": _prop.global_position,
			"shooter": _player,
			"melee": true,
			"thrown_body": true,
		})
		_shatter(_prop.global_position)
		return true

	return false


func _shatter(at_position: Vector3) -> void:
	var prop := _prop
	_prop = null
	_phase = Phase.DONE
	if prop != null and is_instance_valid(prop):
		prop.global_position = at_position
		if prop.has_method("break_apart"):
			prop.break_apart(_fly_dir)
		else:
			prop.queue_free()
	queue_free()


func _get_hold_transform() -> Transform3D:
	var facing := _get_player_facing()
	var origin := (
		_player.global_position
		+ facing * HOLD_FORWARD_OFFSET
		+ Vector3(0.0, HOLD_HEIGHT, 0.0)
	)
	var yaw := atan2(facing.x, facing.z)
	return Transform3D(Basis(Vector3.UP, yaw), origin)


func _get_player_facing() -> Vector3:
	if _player != null and is_instance_valid(_player) and _player.has_method("get_punch_facing_direction"):
		var facing: Vector3 = _player.get_punch_facing_direction()
		facing.y = 0.0
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	return Vector3.FORWARD


func _finish() -> void:
	if _phase == Phase.DONE:
		return
	_phase = Phase.DONE

	if _prop != null and is_instance_valid(_prop):
		if _prop.has_method("end_hostage_hold"):
			_prop.end_hostage_hold(_player)
		_prop.sleeping = false

	_prop = null
	if _player != null and is_instance_valid(_player) and _player.has_method("notify_hostage_take_ended"):
		_player.notify_hostage_take_ended()
	queue_free()
