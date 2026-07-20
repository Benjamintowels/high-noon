extends RefCounted

## Lifecycle wrapper for ground gun/AOE telegraphs and melee alert timing.
## Load via preload("res://gameplay/combat/npc_attack_telegraph.gd").

const AttackTelegraphScript := preload("res://gameplay/fx/attack_telegraph.gd")

## Shared melee telegraph: face + lock aim, AlertSymbol, then strike.
const MELEE_ALERT_DURATION := 1.0
const MELEE_LUNGE_IMPULSE := 4.2

var _telegraph: Node3D
var _locked_aim := Vector3.ZERO
var _has_locked_aim := false
var _commit_timer := 0.0
var _awaiting_commit := false
var _melee_alert_timer := 0.0
var _melee_alert_active := false
var _has_melee_lock := false
var _melee_lock_dir := Vector3.ZERO


func has_telegraph() -> bool:
	return _telegraph != null and is_instance_valid(_telegraph)


func is_filled() -> bool:
	return has_telegraph() and _telegraph.is_filled()


func is_locked() -> bool:
	return has_telegraph() and _telegraph.is_locked()


func is_awaiting_commit() -> bool:
	return _awaiting_commit


func is_melee_alerting() -> bool:
	return _melee_alert_active


func get_fill_t() -> float:
	if not has_telegraph():
		return 0.0
	return _telegraph.get_fill_t()


func get_ground_position() -> Vector3:
	if _has_locked_aim:
		return Vector3(_locked_aim.x, 0.0, _locked_aim.z)
	if has_telegraph():
		return _telegraph.get_ground_position()
	return Vector3.ZERO


func get_aim_point(height_offset: float = 1.05) -> Vector3:
	if _has_locked_aim:
		if height_offset > 0.0 and absf(_locked_aim.y) < 0.05:
			return Vector3(_locked_aim.x, _locked_aim.y + height_offset, _locked_aim.z)
		return _locked_aim
	if has_telegraph():
		return _telegraph.get_aim_point(height_offset)
	return Vector3.ZERO


func get_flat_direction_from(origin: Vector3) -> Vector3:
	if _has_melee_lock:
		return get_melee_lock_direction()
	var aim := Vector3.ZERO
	if _has_locked_aim:
		aim = Vector3(_locked_aim.x, origin.y, _locked_aim.z)
	elif has_telegraph():
		aim = _telegraph.get_ground_position()
		aim.y = origin.y
	var dir := aim - origin
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	return dir.normalized()


func get_melee_lock_direction() -> Vector3:
	if not _has_melee_lock:
		return Vector3.FORWARD
	var d := _melee_lock_dir
	d.y = 0.0
	if d.length_squared() < 0.0001:
		return Vector3.FORWARD
	return d.normalized()


## Gun aim: plant a static feet-level disc under the target (no tracking).
func begin_gun_aim(
	source: Node,
	target: Node3D,
	radius: float = AttackTelegraphScript.DEFAULT_GUN_RADIUS,
	duration: float = AttackTelegraphScript.GUN_FILL_DURATION
) -> Node3D:
	cancel()
	if source == null or target == null or not is_instance_valid(target):
		return null
	var feet := target.global_position
	_telegraph = AttackTelegraphScript.begin(source, feet, radius, duration)
	if _telegraph == null:
		return null
	_telegraph.lock()
	_locked_aim = _telegraph.get_aim_point(1.05)
	_has_locked_aim = true
	_telegraph.filled.connect(_on_filled_keep_aim, CONNECT_ONE_SHOT)
	return _telegraph


## Compat: tracking is no longer used — guns snap to current feet and stay.
func begin_tracking(
	source: Node,
	target: Node3D,
	radius: float = AttackTelegraphScript.DEFAULT_GUN_RADIUS,
	duration: float = AttackTelegraphScript.GUN_FILL_DURATION,
	_max_speed: float = 0.0
) -> Node3D:
	return begin_gun_aim(source, target, radius, duration)


func begin_follow_forward(
	source: Node,
	actor: Node3D,
	forward_offset: float,
	radius: float,
	duration: float = AttackTelegraphScript.FILL_DURATION
) -> Node3D:
	# Melee no longer uses ground circles; keep as static frontal AOE helper for spells.
	cancel()
	if source == null or actor == null or not is_instance_valid(actor):
		return null
	var forward := AttackTelegraphScript.actor_flat_forward(actor)
	var start := actor.global_position + forward * forward_offset
	_telegraph = AttackTelegraphScript.begin(source, start, radius, duration)
	if _telegraph == null:
		return null
	_telegraph.lock()
	_locked_aim = _telegraph.get_ground_position()
	_has_locked_aim = true
	_telegraph.filled.connect(_on_filled_keep_aim, CONNECT_ONE_SHOT)
	return _telegraph


func begin_world(
	source: Node,
	world_pos: Vector3,
	radius: float,
	duration: float = AttackTelegraphScript.FILL_DURATION
) -> Node3D:
	cancel()
	if source == null:
		return null
	_telegraph = AttackTelegraphScript.begin(source, world_pos, radius, duration)
	if _telegraph == null:
		return null
	_telegraph.lock()
	_locked_aim = _telegraph.get_ground_position()
	_has_locked_aim = true
	_telegraph.filled.connect(_on_filled_keep_aim, CONNECT_ONE_SHOT)
	return _telegraph


## Face target, lock that aim line, start the shared melee alert timer.
func begin_melee_alert(attacker: Node3D, target: Node3D) -> bool:
	# Clear any ground disc first; melee uses AlertSymbolFX, not a circle.
	cancel()
	if attacker == null or target == null or not is_instance_valid(target):
		return false
	var to_target := target.global_position - attacker.global_position
	to_target.y = 0.0
	if to_target.length_squared() < 0.0001:
		to_target = AttackTelegraphScript.actor_flat_forward(attacker)
	_melee_lock_dir = to_target.normalized()
	_has_melee_lock = true
	_locked_aim = target.global_position
	_has_locked_aim = true
	_melee_alert_timer = MELEE_ALERT_DURATION
	_melee_alert_active = true
	return true


func tick_melee_alert(delta: float) -> bool:
	if not _melee_alert_active:
		return false
	_melee_alert_timer = maxf(_melee_alert_timer - delta, 0.0)
	if _melee_alert_timer > 0.0:
		return false
	_melee_alert_active = false
	return true


func cancel_melee_alert() -> void:
	_melee_alert_active = false
	_melee_alert_timer = 0.0
	_has_melee_lock = false
	_melee_lock_dir = Vector3.ZERO


func apply_melee_lunge(body: CharacterBody3D, impulse: float = MELEE_LUNGE_IMPULSE) -> void:
	if body == null:
		return
	var dir := get_melee_lock_direction()
	body.velocity.x += dir.x * impulse
	body.velocity.z += dir.z * impulse


func begin_gun_commit(commit_seconds: float = AttackTelegraphScript.GUN_LOCK_COMMIT) -> void:
	if not has_telegraph():
		return
	if not _telegraph.is_locked():
		_telegraph.lock()
	_locked_aim = _telegraph.get_aim_point(1.05)
	_has_locked_aim = true
	_awaiting_commit = true
	_commit_timer = maxf(commit_seconds, 0.0)


func tick_commit(delta: float) -> bool:
	if not _awaiting_commit:
		return false
	_commit_timer = maxf(_commit_timer - delta, 0.0)
	if _commit_timer > 0.0:
		return false
	_awaiting_commit = false
	return true


func complete() -> void:
	_awaiting_commit = false
	_commit_timer = 0.0
	if has_telegraph():
		_telegraph.complete()
	_telegraph = null


func cancel() -> void:
	_awaiting_commit = false
	_commit_timer = 0.0
	_has_locked_aim = false
	_locked_aim = Vector3.ZERO
	cancel_melee_alert()
	if has_telegraph():
		_telegraph.cancel()
	_telegraph = null


func _on_filled_keep_aim() -> void:
	if not has_telegraph():
		return
	_telegraph.lock()
	_locked_aim = _telegraph.get_aim_point(1.05)
	_has_locked_aim = true
