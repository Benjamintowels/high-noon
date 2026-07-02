extends RefCounted
class_name BulletHitDamage

const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")

const DEFAULT_MAX_HEALTH := 2
const PLAYER_MAX_HEALTH := 8
const HORSE_MAX_HEALTH := 1
const HEAD_DAMAGE := 2
const BODY_DAMAGE := 1
const HEAD_HIT_RADIUS := 0.34
const BODY_KNOCKBACK_SPEED := 6.5
const BODY_KNOCKBACK_UP := 1.8
const RIDER_ZONE_BELOW_MOUNT := 0.15


static func cast_duel_target_ray(
	from: Vector3,
	dir: Vector3,
	max_distance: float,
	target: Node,
	hit_radius: float = 0.05
) -> float:
	var margin := hit_radius
	if target.has_method("is_mounted_on_horse") and target.is_mounted_on_horse():
		margin += 0.14

	var capsule_t := -1.0
	var head_t := -1.0

	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		capsule_t = cast_body_capsule_ray(
			from,
			dir,
			max_distance,
			capsule.get("center", Vector3.ZERO),
			capsule.get("half_height", 0.75),
			float(capsule.get("radius", 0.5)) + margin,
			capsule.get("axis", Vector3.UP)
		)

	if target.has_method("get_head_hit_sphere"):
		var head: Dictionary = target.get_head_hit_sphere()
		head_t = DuelHitTest.raycast_sphere(
			from,
			dir,
			max_distance,
			head.get("center", Vector3.ZERO),
			float(head.get("radius", HEAD_HIT_RADIUS)) + margin
		)

	# Torso capsule extends into the neck — if the ray hits the head sphere at all, prefer it.
	if head_t >= 0.0:
		return head_t
	return capsule_t


static func cast_body_capsule_ray(
	from: Vector3,
	dir: Vector3,
	max_distance: float,
	capsule_center: Vector3,
	capsule_half_height: float,
	capsule_radius: float,
	capsule_axis: Vector3 = Vector3.UP
) -> float:
	return DuelHitTest.raycast_capsule(
		from,
		dir,
		max_distance,
		capsule_center,
		capsule_half_height,
		capsule_radius,
		capsule_axis
	)


static func cast_horse_body_ray(
	from: Vector3,
	dir: Vector3,
	max_distance: float,
	horse: Node,
	hit_radius: float = 0.05
) -> float:
	if horse == null or not horse.has_method("get_bullet_capsule"):
		return -1.0
	var capsule: Dictionary = horse.get_bullet_capsule()
	return cast_body_capsule_ray(
		from,
		dir,
		max_distance,
		capsule.get("center", Vector3.ZERO),
		capsule.get("half_height", 0.75),
		float(capsule.get("radius", 0.5)) + hit_radius,
		capsule.get("axis", Vector3.UP)
	)


static func classify_hit_zone(target: Node, hit_info: Dictionary) -> StringName:
	if not target.has_method("get_head_hit_sphere"):
		return &"body"

	var head: Dictionary = target.get_head_hit_sphere()
	var center: Vector3 = head.get("center", Vector3.ZERO)
	var radius: float = float(head.get("radius", HEAD_HIT_RADIUS))
	var hit_position: Vector3 = hit_info.get("position", Vector3.ZERO)

	if hit_position.distance_to(center) <= radius + 0.04:
		return &"head"

	var ray_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	if hit_info.has("ray_origin") and ray_dir.length_squared() > 0.0001:
		var ray_origin: Vector3 = hit_info.ray_origin
		var max_dist := ray_origin.distance_to(hit_position) + radius
		if max_dist > 0.001:
			var head_t := DuelHitTest.raycast_sphere(ray_origin, ray_dir, max_dist, center, radius)
			if head_t >= 0.0:
				return &"head"

	return &"body"


static func damage_for_zone(zone: StringName) -> int:
	return HEAD_DAMAGE if zone == &"head" else BODY_DAMAGE


static func apply_body_knockback(body: CharacterBody3D, hit_info: Dictionary) -> void:
	if body == null:
		return

	var shot_dir: Vector3 = hit_info.get("direction", Vector3.FORWARD)
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001:
		shot_dir = -body.global_transform.basis.z
	shot_dir.y = 0.0
	if shot_dir.length_squared() < 0.0001:
		shot_dir = Vector3.FORWARD
	else:
		shot_dir = shot_dir.normalized()

	var knockback_speed := float(hit_info.get("knockback_speed", BODY_KNOCKBACK_SPEED))
	var knockback_up := float(hit_info.get("knockback_up", BODY_KNOCKBACK_UP))

	body.velocity.x += shot_dir.x * knockback_speed
	body.velocity.z += shot_dir.z * knockback_speed
	body.velocity.y = maxf(body.velocity.y, knockback_up)


static func process_hit(
	target: Node,
	hit_info: Dictionary,
	current_health: int,
	max_health: int = DEFAULT_MAX_HEALTH
) -> Dictionary:
	var lethal := bool(hit_info.get("lethal", false))
	var zone := &"body" if lethal else classify_hit_zone(target, hit_info)
	var damage := current_health if lethal else int(hit_info.get("damage", damage_for_zone(zone)))
	var new_health := 0 if lethal else clampi(current_health - damage, 0, max_health)
	var killed := lethal or new_health <= 0
	var knockback_applied := false

	hit_info["hit_zone"] = zone
	hit_info["damage"] = damage

	BloodSplatterFXScript.spawn_for_hit(target, hit_info)

	var is_melee := bool(hit_info.get("melee", false))
	var force_knockback := bool(hit_info.get("force_knockback", false))
	if not killed and target is CharacterBody3D and (is_melee or force_knockback or zone == &"body"):
		apply_body_knockback(target as CharacterBody3D, hit_info)
		knockback_applied = true

	return {
		"health": new_health,
		"killed": killed,
		"zone": zone,
		"damage": damage,
		"knockback_applied": knockback_applied,
	}


static func find_horse_from_collider(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.is_in_group("stupid_horse"):
			return node
		node = node.get_parent()
	return null


static func find_mounted_rider_for_horse(horse: Node, tree: SceneTree = null) -> Node:
	if horse == null:
		return null
	if horse.has_method("get_mounted_rider"):
		var rider: Node = horse.get_mounted_rider()
		if rider != null:
			return rider
	if tree == null or not horse.has_method("get_rider_mount_node"):
		return null
	var mount: Node3D = horse.get_rider_mount_node()
	if mount == null:
		return null
	for target in tree.get_nodes_in_group("duel_target"):
		if not is_instance_valid(target):
			continue
		if not target.has_method("receive_bullet_hit"):
			continue
		if target.has_method("is_model_on_horse_mount") and target.is_model_on_horse_mount(horse):
			return target
	return null


static func is_hit_in_rider_zone(horse: Node, hit_position: Vector3) -> bool:
	if horse == null:
		return false
	var saddle_y: float = horse.global_position.y + 1.0
	if horse.has_method("get_rider_mount_node"):
		var mount: Node3D = horse.get_rider_mount_node()
		if mount != null:
			saddle_y = mount.global_position.y
	return hit_position.y >= saddle_y - RIDER_ZONE_BELOW_MOUNT


static func is_vulnerable_to_shooter(shooter: Node, target: Node) -> bool:
	if target == null:
		return false
	if shooter != null and shooter == target:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if target.has_method("is_duel_defeated") and target.is_duel_defeated():
		return false
	if not target.has_method("receive_bullet_hit"):
		return false
	return true


static func _mounted_rider_hit_dict(
	ray_origin: Vector3,
	rider: Node,
	world_hit: Dictionary,
	duel_hit: Dictionary
) -> Dictionary:
	if not duel_hit.is_empty() and duel_hit.get("duel_target") == rider:
		return duel_hit
	var hit_position: Vector3 = world_hit.get("position", ray_origin)
	if duel_hit.is_empty() or duel_hit.get("duel_target") != rider:
		if not world_hit.is_empty():
			hit_position = world_hit.get("position", hit_position)
		elif duel_hit.has("position"):
			hit_position = duel_hit.position
	return {
		"position": hit_position,
		"normal": world_hit.get("normal", duel_hit.get("normal", Vector3.UP)),
		"collider": rider,
		"duel_target": rider,
	}


static func _horse_body_hit_dict(
	ray_origin: Vector3,
	horse: Node,
	source_hit: Dictionary
) -> Dictionary:
	var hit_position: Vector3 = source_hit.get("position", ray_origin)
	return {
		"position": hit_position,
		"normal": source_hit.get("normal", Vector3.UP),
		"collider": horse,
		"horse_target": horse,
	}


static func _closest_hit_candidate(ray_origin: Vector3, candidates: Array) -> Dictionary:
	var best: Dictionary = {}
	var best_distance := INF
	for candidate in candidates:
		if not candidate is Dictionary or candidate.is_empty() or not candidate.has("position"):
			continue
		var distance := ray_origin.distance_to(candidate.position)
		if distance < best_distance:
			best_distance = distance
			best = candidate
	return best


## Pick rider, horse hull, or world hit for mounted combat. Horse body wins below the saddle.
static func resolve_equestrian_hit(
	ray_origin: Vector3,
	ray_dir: Vector3,
	max_distance: float,
	world_hit: Dictionary,
	duel_hit: Dictionary,
	horse_hit: Dictionary,
	tree: SceneTree = null,
	shooter: Node = null
) -> Dictionary:
	var candidates: Array = []

	if not horse_hit.is_empty():
		var horse_target: Node = horse_hit.get("horse_target", horse_hit.get("collider"))
		if horse_target != null and (
			not horse_target.has_method("is_horse_defeated")
			or not horse_target.is_horse_defeated()
		):
			candidates.append(horse_hit)

	if not duel_hit.is_empty():
		var duel_target: Node = duel_hit.get("duel_target")
		if duel_target == null or is_vulnerable_to_shooter(shooter, duel_target):
			var horse_for_rider: Node = null
			if not horse_hit.is_empty():
				horse_for_rider = horse_hit.get("horse_target", horse_hit.get("collider"))
			if _include_mounted_rider_hit(horse_for_rider, duel_hit, horse_hit, ray_origin):
				candidates.append(duel_hit)

	if (
		duel_hit.is_empty()
		and not horse_hit.is_empty()
		and tree != null
		and ray_dir.length_squared() > 0.0001
		and max_distance > 0.0001
	):
		var horse: Node = horse_hit.get("horse_target", horse_hit.get("collider"))
		var rider := find_mounted_rider_for_horse(horse, tree)
		if rider != null and is_vulnerable_to_shooter(shooter, rider):
			var dir := ray_dir.normalized()
			var rider_t := cast_duel_target_ray(ray_origin, dir, max_distance, rider, 0.05)
			if rider_t >= 0.0:
				var rider_hit := {
					"position": ray_origin + dir * rider_t,
					"normal": -dir,
					"collider": rider,
					"duel_target": rider,
				}
				var horse_dist := ray_origin.distance_to(horse_hit.get("position", ray_origin))
				if rider_t <= horse_dist + 0.4:
					candidates.append(rider_hit)

	if not world_hit.is_empty():
		var horse := find_horse_from_collider(world_hit.get("collider"))
		if horse != null:
			var hit_position: Vector3 = world_hit.get("position", ray_origin)
			if is_hit_in_rider_zone(horse, hit_position):
				var rider := find_mounted_rider_for_horse(horse, tree)
				if rider != null and is_vulnerable_to_shooter(shooter, rider):
					candidates.append(_mounted_rider_hit_dict(ray_origin, rider, world_hit, duel_hit))
			elif not horse.has_method("is_horse_defeated") or not horse.is_horse_defeated():
				candidates.append(_horse_body_hit_dict(ray_origin, horse, world_hit))

	var resolved := _closest_hit_candidate(ray_origin, candidates)
	return resolved


static func _include_mounted_rider_hit(
	horse: Node,
	duel_hit: Dictionary,
	horse_hit: Dictionary,
	ray_origin: Vector3
) -> bool:
	if duel_hit.is_empty():
		return false
	var duel_target: Node = duel_hit.get("duel_target")
	if duel_target == null:
		return true
	var rider_mounted := false
	if duel_target.has_method("is_mounted_on_horse") and duel_target.is_mounted_on_horse():
		rider_mounted = true
	elif (
		horse != null
		and duel_target.has_method("is_model_on_horse_mount")
		and duel_target.is_model_on_horse_mount(horse)
	):
		rider_mounted = true
	if not rider_mounted:
		return true
	var rider_hit_position: Vector3 = duel_hit.get("position", ray_origin)
	if horse != null and not is_hit_in_rider_zone(horse, rider_hit_position):
		return false
	if horse_hit.is_empty():
		return true
	var rider_dist := ray_origin.distance_to(rider_hit_position)
	var horse_dist := ray_origin.distance_to(horse_hit.get("position", ray_origin))
	return rider_dist + 0.08 <= horse_dist


## Backward-compatible alias used by projectile scripts.
static func prefer_mounted_rider_hit(
	ray_origin: Vector3,
	ray_dir: Vector3,
	max_distance: float,
	world_hit: Dictionary,
	duel_hit: Dictionary,
	tree: SceneTree = null,
	shooter: Node = null,
	horse_hit: Dictionary = {}
) -> Dictionary:
	return resolve_equestrian_hit(
		ray_origin,
		ray_dir,
		max_distance,
		world_hit,
		duel_hit,
		horse_hit,
		tree,
		shooter
	)
