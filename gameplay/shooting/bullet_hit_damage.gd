extends RefCounted
class_name BulletHitDamage

const BloodSplatterFXScript := preload("res://gameplay/fx/blood_splatter_fx.gd")

const DEFAULT_MAX_HEALTH := 2
const PLAYER_MAX_HEALTH := 8
const HEAD_DAMAGE := 2
const BODY_DAMAGE := 1
const HEAD_HIT_RADIUS := 0.34
const BODY_KNOCKBACK_SPEED := 6.5
const BODY_KNOCKBACK_UP := 1.8


static func cast_duel_target_ray(
	from: Vector3,
	dir: Vector3,
	max_distance: float,
	target: Node,
	hit_radius: float = 0.05
) -> float:
	var capsule_t := -1.0
	var head_t := -1.0

	if target.has_method("get_bullet_capsule"):
		var capsule: Dictionary = target.get_bullet_capsule()
		capsule_t = DuelHitTest.raycast_capsule(
			from,
			dir,
			max_distance,
			capsule.get("center", Vector3.ZERO),
			capsule.get("half_height", 0.75),
			float(capsule.get("radius", 0.5)) + hit_radius,
			capsule.get("axis", Vector3.UP)
		)

	if target.has_method("get_head_hit_sphere"):
		var head: Dictionary = target.get_head_hit_sphere()
		head_t = DuelHitTest.raycast_sphere(
			from,
			dir,
			max_distance,
			head.get("center", Vector3.ZERO),
			float(head.get("radius", HEAD_HIT_RADIUS)) + hit_radius
		)

	# Torso capsule extends into the neck — if the ray hits the head sphere at all, prefer it.
	if head_t >= 0.0:
		return head_t
	return capsule_t


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

	body.velocity.x += shot_dir.x * BODY_KNOCKBACK_SPEED
	body.velocity.z += shot_dir.z * BODY_KNOCKBACK_SPEED
	body.velocity.y = maxf(body.velocity.y, BODY_KNOCKBACK_UP)


static func process_hit(
	target: Node,
	hit_info: Dictionary,
	current_health: int,
	max_health: int = DEFAULT_MAX_HEALTH
) -> Dictionary:
	var hit_position: Vector3 = hit_info.get("position", Vector3.ZERO)
	var zone := classify_hit_zone(target, hit_info)
	var damage := damage_for_zone(zone)
	var new_health := clampi(current_health - damage, 0, max_health)
	var killed := new_health <= 0
	var knockback_applied := false

	hit_info["hit_zone"] = zone
	hit_info["damage"] = damage

	BloodSplatterFXScript.spawn_for_hit(target, hit_info)

	if not killed and zone == &"body" and target is CharacterBody3D:
		apply_body_knockback(target as CharacterBody3D, hit_info)
		knockback_applied = true

	return {
		"health": new_health,
		"killed": killed,
		"zone": zone,
		"damage": damage,
		"knockback_applied": knockback_applied,
	}
