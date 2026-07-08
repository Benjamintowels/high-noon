extends RefCounted
class_name MeshyCivilianNpcShove

## Gentle step-aside when the player (or horse) walks into meshy civilian NPCs.

const TownNpcShove := preload("res://gameplay/world/town_npc_shove.gd")

const SHOVE_STEP_WALK_BLEND := 1.0

var _host: Node

var gentle_shove_stepping := false
var gentle_shove_step_time := 0.0
var gentle_shove_step_dir := Vector3.ZERO
var gentle_shove_step_from := Vector3.ZERO
var gentle_shove_step_distance := 0.0
var gentle_shove_step_cooldown := 0.0
var shove_settling := false
var shove_settle_time := 0.0
var shove_settle_from_blend := 0.0
var shove_settle_duration := TownNpcShove.SHOVE_SETTLE_DURATION


func bind(host: Node) -> void:
	_host = host
	if host is CharacterBody3D:
		TownNpcShove.configure_npc_collision(host)


func is_busy() -> bool:
	return gentle_shove_stepping or shove_settling


func process_physics(delta: float) -> bool:
	if _host == null:
		return false

	var npc := _host as CharacterBody3D
	if npc == null:
		return false

	gentle_shove_step_cooldown = maxf(gentle_shove_step_cooldown - delta, 0.0)

	if gentle_shove_stepping:
		_process_gentle_shove_step(npc, delta)
		return true

	if shove_settling:
		_process_shove_settle(npc, delta)
		return true

	if not _host.call("is_npc_shoveable"):
		return false

	var shove_contact := TownNpcShove.find_strongest_contact(npc)
	var shove_level: int = int(shove_contact.get("level", TownNpcShove.Level.NONE))
	if shove_level == TownNpcShove.Level.LETHAL:
		_host.call(
			"receive_bullet_hit",
			TownNpcShove.build_lethal_hit_info(
				npc,
				shove_contact.get("mover") as CharacterBody3D,
				shove_contact.get("push_dir", Vector3.ZERO)
			)
		)
		npc.move_and_slide()
		_host.call("update_npc_locomotion_audio", delta, 0.0, false, false)
		return true

	var push_dir: Vector3 = shove_contact.get("push_dir", Vector3.FORWARD)
	var speed := float(shove_contact.get("speed", 0.0))
	var distance_scale := 1.0
	if shove_level == TownNpcShove.Level.STUMBLE:
		distance_scale = 1.35
		if _host.has_method("play_npc_shove_stumble_voice"):
			_host.call("play_npc_shove_stumble_voice")

	if (
		shove_level in [TownNpcShove.Level.GENTLE, TownNpcShove.Level.STUMBLE]
		and gentle_shove_step_cooldown <= 0.0
	):
		_begin_gentle_shove_step(npc, push_dir, speed, distance_scale)
		_process_gentle_shove_step(npc, delta)
		return true

	return false


func _begin_gentle_shove_step(
	npc: CharacterBody3D,
	push_dir: Vector3,
	speed: float,
	distance_scale: float = 1.0
) -> void:
	_host.call("_capture_shove_resume_state")
	gentle_shove_stepping = true
	gentle_shove_step_time = 0.0
	gentle_shove_step_dir = push_dir
	if gentle_shove_step_dir.length_squared() < 0.0001:
		gentle_shove_step_dir = -npc.global_transform.basis.z
	gentle_shove_step_dir.y = 0.0
	gentle_shove_step_dir = gentle_shove_step_dir.normalized()
	gentle_shove_step_from = npc.global_position
	var speed_ratio := clampf(speed / TownNpcShove.GENTLE_MAX_SPEED, 0.65, 1.15)
	gentle_shove_step_distance = TownNpcShove.SHOVE_STEP_DISTANCE * speed_ratio * distance_scale
	npc.velocity = Vector3.ZERO
	_host.call("_face_position", npc.global_position + gentle_shove_step_dir, 0.016)


func _process_gentle_shove_step(npc: CharacterBody3D, delta: float) -> void:
	var gravity: float = float(_host.GRAVITY)
	if not npc.is_on_floor():
		npc.velocity.y -= gravity * delta
	else:
		npc.velocity.y = minf(npc.velocity.y, 0.0)

	gentle_shove_step_time += delta
	var t := clampf(gentle_shove_step_time / TownNpcShove.SHOVE_STEP_DURATION, 0.0, 1.0)
	var move_t := TownNpcShove.gentle_step_ease(t)
	var blend := TownNpcShove.gentle_step_walk_blend(t, SHOVE_STEP_WALK_BLEND)
	_host.call("_set_shove_step_locomotion", blend)

	var target_pos := (
		gentle_shove_step_from
		+ gentle_shove_step_dir * (gentle_shove_step_distance * move_t)
	)
	npc.global_position = TownNpcShove.clip_step_position(
		npc,
		gentle_shove_step_from,
		target_pos
	)
	_host.call("_face_position", npc.global_position + gentle_shove_step_dir, delta)

	npc.move_and_slide()
	_host.call(
		"update_npc_locomotion_audio",
		delta,
		gentle_shove_step_distance / TownNpcShove.SHOVE_STEP_DURATION,
		true,
		false
	)

	if t >= 1.0:
		_end_gentle_shove_step()


func _end_gentle_shove_step() -> void:
	var from_blend: float = _host.call("_get_shove_step_blend")
	gentle_shove_stepping = false
	gentle_shove_step_time = 0.0
	gentle_shove_step_cooldown = TownNpcShove.SHOVE_STEP_COOLDOWN
	_begin_shove_settle(from_blend)
	_host.call("_resume_after_shove")


func _begin_shove_settle(
	from_blend: float,
	duration: float = TownNpcShove.SHOVE_SETTLE_DURATION
) -> void:
	shove_settling = true
	shove_settle_time = 0.0
	shove_settle_from_blend = from_blend
	shove_settle_duration = duration
	_host.call("_set_shove_step_locomotion", from_blend)


func _process_shove_settle(npc: CharacterBody3D, delta: float) -> void:
	var gravity: float = float(_host.GRAVITY)
	if not npc.is_on_floor():
		npc.velocity.y -= gravity * delta
	else:
		npc.velocity.y = minf(npc.velocity.y, 0.0)

	npc.velocity.x = 0.0
	npc.velocity.z = 0.0

	shove_settle_time += delta
	var t := clampf(shove_settle_time / shove_settle_duration, 0.0, 1.0)
	var eased := TownNpcShove.settle_ease(t)
	var target: float = _host.call("_get_shove_settle_target_blend")
	var blend := lerpf(shove_settle_from_blend, target, eased)
	_host.call("_set_shove_step_locomotion", blend)

	npc.move_and_slide()
	_host.call("update_npc_locomotion_audio", delta, 0.0, false, false)

	if t >= 1.0:
		shove_settling = false
		_host.call("_set_shove_move_blend", target)
