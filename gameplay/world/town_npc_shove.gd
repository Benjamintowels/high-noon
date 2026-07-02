extends RefCounted
class_name TownNpcShove

## Player / horse collision shoves for peaceful town NPCs.
## Level 1 — walk speed: gentle displacement.
## Level 2 — run or mounted horse walk: stumble animation + voice.
## Level 3 — mounted horse sprint: lethal hit (ragdoll death).

enum Level {
	NONE,
	GENTLE,
	STUMBLE,
	LETHAL,
}

const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"stupid_horse",
]

const MOVER_CONTACT_RADIUS := 0.36
const NPC_CONTACT_RADIUS := 0.35
const CONTACT_SLACK := 0.14
const GENTLE_PUSH_SCALE := 0.55
const MIN_INTENT_SPEED_SQ := 0.04
const MIN_ALIGNMENT := 0.2

## Player walk (3.6) stays gentle; player run (7.2) and horse walk (5.5) stumble.
const GENTLE_MAX_SPEED := 4.8
## Horse sprint (20) is lethal; anything above this band is stumble.
const STUMBLE_MAX_SPEED := 11.0

const WORLD_COLLISION_LAYER := 1
const TOWN_NPC_COLLISION_LAYER := 8

const HORSE_CONTACT_RADIUS := 0.58
const SHOVE_STEP_DURATION := 0.36
const SHOVE_STEP_DISTANCE := 0.5
const SHOVE_STEP_COOLDOWN := 0.12
const SHOVE_SETTLE_DURATION := 0.32
const STUMBLE_EXIT_BLEND_DURATION := 0.35
const STUMBLE_SETTLE_DURATION := 0.48


static func settle_ease(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return 1.0 - pow(1.0 - clamped, 2.0)


static func configure_npc_collision(npc: CharacterBody3D) -> void:
	npc.collision_layer = TOWN_NPC_COLLISION_LAYER
	npc.collision_mask = WORLD_COLLISION_LAYER


static func configure_horse_collision(horse: CharacterBody3D) -> void:
	horse.collision_layer = WORLD_COLLISION_LAYER
	horse.collision_mask = WORLD_COLLISION_LAYER


static func gentle_step_ease(t: float) -> float:
	var clamped := clampf(t, 0.0, 1.0)
	return 0.5 - 0.5 * cos(PI * clamped)


static func gentle_step_walk_blend(t: float, peak: float) -> float:
	return sin(clampf(t, 0.0, 1.0) * PI) * peak


static func clip_step_position(npc: CharacterBody3D, from: Vector3, to: Vector3) -> Vector3:
	return from + _clip_motion_against_world(npc, to - from)


static func mover_contact_radius(mover: CharacterBody3D) -> float:
	if mover != null and mover.is_in_group(&"stupid_horse"):
		return HORSE_CONTACT_RADIUS
	return MOVER_CONTACT_RADIUS


static func compute_gentle_motion(npc: CharacterBody3D, mover: CharacterBody3D, delta: float) -> Vector3:
	var contact := _evaluate_contact(npc, mover, delta)
	if int(contact.get("level", Level.NONE)) != Level.GENTLE:
		return Vector3.ZERO
	return contact.get("motion", Vector3.ZERO)


static func find_strongest_contact(npc: CharacterBody3D) -> Dictionary:
	var result := _empty_contact()
	if npc == null:
		return result

	var tree := npc.get_tree()
	if tree == null:
		return result

	var delta := npc.get_physics_process_delta_time()
	for group_name in PUSHER_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node) or node == npc:
				continue
			if not node is CharacterBody3D:
				continue
			if should_skip_mover(node):
				continue
			var contact := _evaluate_contact(npc, node as CharacterBody3D, delta)
			if int(contact.get("level", Level.NONE)) > int(result.get("level", Level.NONE)):
				result = contact
			elif (
				int(contact.get("level", Level.NONE)) == int(result.get("level", Level.NONE))
				and float(contact.get("speed", 0.0)) > float(result.get("speed", 0.0))
			):
				result = contact

	return result


static func build_lethal_hit_info(
	npc: CharacterBody3D,
	mover: CharacterBody3D,
	push_dir: Vector3
) -> Dictionary:
	var shooter: Node = mover
	if mover.has_method("get_shove_shooter"):
		shooter = mover.call("get_shove_shooter")

	var hit_position := npc.global_position + Vector3(0.0, 1.0, 0.0)
	return {
		"position": hit_position,
		"direction": push_dir,
		"shooter": shooter,
		"lethal": true,
	}


static func classify_speed(speed: float) -> Level:
	if speed < 0.35:
		return Level.NONE
	if speed <= GENTLE_MAX_SPEED:
		return Level.GENTLE
	if speed <= STUMBLE_MAX_SPEED:
		return Level.STUMBLE
	return Level.LETHAL


static func _empty_contact() -> Dictionary:
	return {
		"level": Level.NONE,
		"mover": null,
		"push_dir": Vector3.ZERO,
		"speed": 0.0,
		"motion": Vector3.ZERO,
	}


static func _evaluate_contact(
	npc: CharacterBody3D,
	mover: CharacterBody3D,
	delta: float
) -> Dictionary:
	var offset := npc.global_position - mover.global_position
	offset.y = 0.0
	var dist := offset.length()
	var touch_dist := mover_contact_radius(mover) + NPC_CONTACT_RADIUS + CONTACT_SLACK
	if dist > touch_dist or dist < 0.001:
		return _empty_contact()

	var push_dir := offset.normalized()
	var intent := _get_mover_push_intent(mover)
	intent.y = 0.0
	if intent.length_squared() < MIN_INTENT_SPEED_SQ:
		return _empty_contact()

	var alignment := intent.normalized().dot(push_dir)
	if alignment < MIN_ALIGNMENT:
		return _empty_contact()

	var speed := intent.length()
	var level := classify_speed(speed)
	var penetration := clampf(
		(touch_dist - dist) / (CONTACT_SLACK + NPC_CONTACT_RADIUS),
		0.0,
		1.0
	)
	var push_speed := speed * lerpf(GENTLE_PUSH_SCALE, 1.0, penetration) * maxf(alignment, 0.35)
	var motion := Vector3.ZERO
	if level == Level.GENTLE:
		motion = _clip_motion_against_world(npc, push_dir * push_speed * delta)

	return {
		"level": level,
		"mover": mover,
		"push_dir": push_dir,
		"speed": speed,
		"motion": motion,
	}


static func _get_mover_push_intent(mover: CharacterBody3D) -> Vector3:
	if mover.has_method("get_push_intent"):
		return mover.call("get_push_intent")
	return Vector3(mover.velocity.x, 0.0, mover.velocity.z)


static func should_skip_mover(mover: Node) -> bool:
	return mover.has_method("is_mounted_on_horse") and mover.call("is_mounted_on_horse")


static func _clip_motion_against_world(npc: CharacterBody3D, motion: Vector3) -> Vector3:
	if motion.length_squared() < 0.000001:
		return Vector3.ZERO

	var space_state := npc.get_world_3d().direct_space_state
	if space_state == null:
		return motion

	var from := npc.global_position + Vector3(0.0, 0.8, 0.0)
	var to := from + motion
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collision_mask = WORLD_COLLISION_LAYER
	query.exclude = [npc.get_rid()]
	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return motion

	var travel := from.distance_to(hit.position) - NPC_CONTACT_RADIUS - 0.04
	if travel <= 0.0:
		return Vector3.ZERO
	return motion.normalized() * minf(motion.length(), travel)
