extends Node3D

const BlastDamageScript := preload("res://gameplay/shooting/blast_damage.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const MuzzleFlashFXScript := preload("res://gameplay/fx/muzzle_flash_fx.gd")
const LAUNCHER_SCENE := preload("res://Assets/Guns/rocketlaucher.fbx")

const START_SPEED := 42.0
const MAX_SPEED := 145.0
const RAMP_DISTANCE := 48.0
const MAX_RANGE := 180.0
const PROJECTILE_RADIUS := 0.42
const HIT_RADIUS := 0.55
const BLAST_RADIUS := 5.5
const BLAST_FORCE := 28.0
const VISUAL_SCALE := 4.2
const GRIP_VISUAL_SCALE := 3.5
const SMOKE_INTERVAL := 0.05
const SMOKE_DISTANCE := 1.4

var _direction := Vector3.FORWARD
var _launch_origin := Vector3.ZERO
var _target := Vector3.ZERO
var _distance := 0.0
var _smoke_timer := 0.0
var _smoke_distance_accum := 0.0
var _exclude: Array[RID] = []
var _shooter: Node3D
var _exploded := false
var _on_exploded: Callable = Callable()
var _collision_shape: SphereShape3D
var _replay_visual_only := false
var _vfx_parent: Node


func setup(
	origin: Vector3,
	direction: Vector3,
	exclude: Array = [],
	shooter: Node3D = null,
	on_exploded: Callable = Callable()
) -> void:
	_replay_visual_only = false
	_launch_origin = origin
	_direction = direction.normalized()
	global_position = origin
	_align_to_direction(_direction)
	_shooter = shooter
	_on_exploded = on_exploded
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)

	_collision_shape = SphereShape3D.new()
	_collision_shape.radius = PROJECTILE_RADIUS
	_attach_visual()
	_emit_trail_smoke()
	set_physics_process(true)
	set_process(false)


func setup_replay(origin: Vector3, target: Vector3, vfx_parent: Node = null) -> void:
	_replay_visual_only = true
	_vfx_parent = vfx_parent
	_launch_origin = origin
	_target = target
	_direction = (_target - _launch_origin).normalized()
	if _direction.length_squared() < 0.0001:
		_direction = Vector3.FORWARD
	global_position = origin
	_align_to_direction(_direction)
	_shooter = null
	_on_exploded = Callable()
	_exploded = false
	_distance = 0.0
	_attach_visual()
	_emit_trail_smoke()
	set_physics_process(false)
	set_process(false)


func sync_replay_time(time: float, launch_t: float, impact_t: float) -> bool:
	if not _replay_visual_only or _exploded or not is_instance_valid(self):
		return _exploded

	var span := maxf(impact_t - launch_t, 0.001)
	var alpha := clampf((time - launch_t) / span, 0.0, 1.0)
	var prev_pos := global_position
	global_position = _launch_origin.lerp(_target, alpha)
	var step_length := global_position.distance_to(prev_pos)
	_distance = global_position.distance_to(_launch_origin)
	if step_length > 0.001:
		_update_trail_smoke(0.0, step_length)

	if alpha >= 1.0:
		_detonate_visual(_target)
		return true

	return false


func _align_to_direction(direction: Vector3) -> void:
	if direction.length_squared() < 0.0001:
		return
	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.98:
		up = Vector3.RIGHT
	global_transform.basis = Basis.looking_at(direction, up)


func _attach_visual() -> void:
	var visual := _extract_rocket_visual()
	if visual == null:
		_attach_fallback_visual()
		return

	visual.scale = Vector3.ONE * VISUAL_SCALE
	visual.rotation = Vector3.ZERO
	visual.position = Vector3.ZERO
	add_child(visual)
	_add_glow_shell()


func _attach_fallback_visual() -> void:
	var body := MeshInstance3D.new()
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.12
	mesh.bottom_radius = 0.12
	mesh.height = 0.55
	body.mesh = mesh
	body.rotation.x = PI * 0.5

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.82, 0.2, 0.12, 1.0)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.35, 0.1)
	material.emission_energy_multiplier = 2.0
	body.material_override = material
	body.scale = Vector3.ONE * VISUAL_SCALE
	add_child(body)


func _add_glow_shell() -> void:
	var glow := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = PROJECTILE_RADIUS * 1.15
	mesh.height = PROJECTILE_RADIUS * 2.3
	glow.mesh = mesh

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(1.0, 0.55, 0.15, 0.18)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.45, 0.1)
	material.emission_energy_multiplier = 1.6
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	glow.material_override = material
	add_child(glow)


static func apply_grip_rocket_scale(visual: Node3D) -> void:
	if visual != null:
		visual.scale = Vector3.ONE * GRIP_VISUAL_SCALE


static func _extract_rocket_visual() -> Node3D:
	var launcher: Node = LAUNCHER_SCENE.instantiate()
	var rocket := _find_rocketbullet_node(launcher)
	if rocket == null:
		launcher.queue_free()
		return null

	var visual := rocket.duplicate() as Node3D
	launcher.queue_free()
	return visual


static func _find_rocketbullet_node(root: Node) -> Node3D:
	for child in root.find_children("*", "", true, false):
		var lowered := child.name.to_lower()
		if lowered.contains("rocket") and lowered.contains("bullet"):
			return child as Node3D
	return null


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())


func _physics_process(delta: float) -> void:
	if _replay_visual_only or _exploded:
		return

	var dt := GameTime.physics_delta(delta)
	var speed := _get_current_speed()
	var from := global_position
	var step := _direction * speed * dt
	var to := from + step
	var step_length := step.length()

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		queue_free()
		return

	var hit := _cast_hit(space_state, from, step, step_length)
	if not hit.is_empty():
		_detonate(hit.position)
		return

	global_position = to
	_distance += step_length
	_update_trail_smoke(dt, step_length)
	if _distance >= MAX_RANGE:
		_detonate(to)


func _get_current_speed() -> float:
	var ramp := clampf(_distance / RAMP_DISTANCE, 0.0, 1.0)
	ramp = ramp * ramp
	return lerpf(START_SPEED, MAX_SPEED, ramp)


func _update_trail_smoke(delta: float, step_length: float) -> void:
	_smoke_timer -= delta
	_smoke_distance_accum += step_length
	if _smoke_timer > 0.0 and _smoke_distance_accum < SMOKE_DISTANCE:
		return

	_smoke_timer = SMOKE_INTERVAL
	_smoke_distance_accum = 0.0
	_emit_trail_smoke()


func _emit_trail_smoke() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		return
	SmokePuffFXScript.spawn_trail(
		parent,
		global_position - _direction * 0.25,
		randf_range(0.24, 0.34)
	)


func _cast_hit(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	motion: Vector3,
	step_length: float
) -> Dictionary:
	var duel_hit := _cast_duel_targets(from, _direction, step_length)
	var world_hit := _cast_world_ray(space_state, from, from + motion, step_length)

	if duel_hit.is_empty():
		return world_hit
	if world_hit.is_empty():
		return duel_hit

	var duel_dist := from.distance_to(duel_hit.position)
	var world_dist := from.distance_to(world_hit.position)
	return duel_hit if duel_dist <= world_dist else world_hit


func _cast_world_ray(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	max_distance: float
) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	if not _exclude.is_empty():
		query.exclude = _exclude

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	var hit_distance := from.distance_to(hit.position)
	if hit_distance > max_distance + 0.001:
		return {}

	return {"position": hit.position}


func _cast_duel_targets(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")

	var best_t := max_distance + 1.0
	var best_target: Node = null

	for target in get_tree().get_nodes_in_group("duel_target"):
		if target == _shooter or not _is_vulnerable_duel_target(target):
			continue
		if not target.has_method("get_bullet_capsule"):
			continue

		var capsule: Dictionary = target.get_bullet_capsule()
		var center: Vector3 = capsule.get("center", Vector3.ZERO)
		var half_height: float = capsule.get("half_height", 0.75)
		var radius: float = capsule.get("radius", 0.5) + HIT_RADIUS
		var axis: Vector3 = capsule.get("axis", Vector3.UP)

		var hit_t := DuelHitTest.raycast_capsule(
			from, dir, max_distance, center, half_height, radius, axis
		)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_target = target

	if best_target == null:
		return {}

	return {
		"position": from + dir * best_t,
	}


func _is_vulnerable_duel_target(target: Node) -> bool:
	if target == null:
		return false
	if target.has_method("is_defeated") and target.is_defeated():
		return false
	if target.has_method("is_duel_defeated") and target.is_duel_defeated():
		return false
	return target.has_method("receive_bullet_hit") or target.has_method("apply_bullet_hit")


func _detonate(center: Vector3) -> void:
	if _exploded:
		return
	_exploded = true

	BlastDamageScript.explode(center, _shooter, BLAST_RADIUS, BLAST_FORCE)

	if _on_exploded.is_valid():
		_on_exploded.call(_launch_origin, center)

	queue_free()


func _detonate_visual(center: Vector3) -> void:
	if _exploded:
		return
	_exploded = true

	var parent: Node = _vfx_parent
	if parent == null or not is_instance_valid(parent):
		parent = get_parent()
	if parent == null or not is_instance_valid(parent):
		var tree := get_tree()
		if tree != null:
			parent = tree.current_scene
	if parent != null and is_instance_valid(parent):
		BlastDamageScript.explode_visual(parent, center, BLAST_RADIUS)

	call_deferred("queue_free")
