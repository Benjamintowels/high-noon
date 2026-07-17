extends Node3D

## Arcing grenade launcher round with smoke trail. Gravity lob toward aim, then
## BlastDamage on impact (or fuse timeout).

const BlastDamageScript := preload("res://gameplay/shooting/blast_damage.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const START_SPEED := 22.0
const LOFT := 0.35
const GRAVITY := 16.0
const MAX_FLIGHT_TIME := 6.0
const PROJECTILE_RADIUS := 0.18
const HIT_RADIUS := 0.28
const BLAST_RADIUS := 5.0
const BLAST_FORCE := 24.0
const BLAST_DAMAGE := 2
const VISUAL_SCALE := 0.35
const SMOKE_INTERVAL := 0.06
const SMOKE_DISTANCE := 0.9

var _velocity := Vector3.ZERO
var _shooter: Node3D
var _exclude: Array[RID] = []
var _flight_time := 0.0
var _smoke_timer := 0.0
var _smoke_distance_accum := 0.0
var _exploded := false
var _collision_shape: SphereShape3D
var _blast_radius := BLAST_RADIUS
var _blast_force := BLAST_FORCE
var _blast_damage := BLAST_DAMAGE


func setup(
	origin: Vector3,
	direction: Vector3,
	exclude: Array = [],
	shooter: Node3D = null,
	blast_radius: float = BLAST_RADIUS,
	blast_force: float = BLAST_FORCE,
	blast_damage: int = BLAST_DAMAGE,
	speed: float = START_SPEED
) -> void:
	_shooter = shooter
	_blast_radius = blast_radius
	_blast_force = blast_force
	_blast_damage = blast_damage
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)

	global_position = origin
	var dir := direction.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	# Soft loft so the round arcs like a thrown stick of dynamite.
	dir = (dir + Vector3.UP * LOFT).normalized()
	_velocity = dir * speed
	_collision_shape = SphereShape3D.new()
	_collision_shape.radius = PROJECTILE_RADIUS
	_attach_visual()
	_emit_trail_smoke()
	set_physics_process(true)


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())


func _attach_visual() -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = "Visual"
	var sphere := SphereMesh.new()
	sphere.radius = 0.08
	sphere.height = 0.16
	mesh.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.42, 0.28)
	mat.roughness = 0.85
	mesh.material_override = mat
	add_child(mesh)
	scale = Vector3.ONE * VISUAL_SCALE


func _physics_process(delta: float) -> void:
	if _exploded:
		return

	var dt := GameTime.physics_delta(delta)
	_flight_time += dt
	if _flight_time >= MAX_FLIGHT_TIME:
		_explode(global_position)
		return

	var from := global_position
	_velocity.y -= GRAVITY * dt
	var step := _velocity * dt
	var to := from + step
	var step_length := step.length()
	if step_length < 0.0001:
		return

	var space_state := get_world_3d().direct_space_state
	if space_state == null:
		queue_free()
		return

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.exclude = _exclude
	var hit := space_state.intersect_ray(query)
	if not hit.is_empty():
		_explode(hit.get("position", to))
		return

	# Sphere sweep for thicker hits.
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = _collision_shape
	shape_query.transform = Transform3D(Basis.IDENTITY, from)
	shape_query.motion = step
	shape_query.exclude = _exclude
	shape_query.collide_with_areas = true
	shape_query.collide_with_bodies = true
	var motion := space_state.cast_motion(shape_query)
	if motion.size() >= 2 and float(motion[0]) < 1.0:
		var impact := from.lerp(to, float(motion[0]))
		_explode(impact)
		return

	global_position = to
	_align_to_velocity()
	_update_trail_smoke(dt, step_length)


func _align_to_velocity() -> void:
	if _velocity.length_squared() < 0.0001:
		return
	look_at(global_position + _velocity.normalized(), Vector3.UP)


func _update_trail_smoke(delta: float, step_length: float) -> void:
	_smoke_timer -= delta
	_smoke_distance_accum += step_length
	if _smoke_timer > 0.0 and _smoke_distance_accum < SMOKE_DISTANCE:
		return
	_smoke_timer = SMOKE_INTERVAL
	_smoke_distance_accum = 0.0
	_emit_trail_smoke()


func _emit_trail_smoke() -> void:
	var parent := get_parent()
	if parent == null:
		return
	SmokePuffFXScript.spawn_trail(parent, global_position)


func _explode(center: Vector3) -> void:
	if _exploded:
		return
	_exploded = true
	set_physics_process(false)
	var parent := get_tree().current_scene if get_tree() != null else get_parent()
	if parent == null:
		parent = get_parent()
	GameAudio.play_explosion(parent if parent != null else self, center)
	BlastDamageScript.explode(center, _shooter, _blast_radius, _blast_force)
	# Extra chip damage for living targets inside the blast (BlastDamage knockback
	# path already hits duel_target; this bumps HP when receive_explosion exists).
	_apply_blast_damage(center)
	queue_free()


func _apply_blast_damage(center: Vector3) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for group_name: StringName in [&"duel_target", &"enemy"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node) or not (node is Node3D):
				continue
			if node == _shooter:
				continue
			var target := node as Node3D
			var dist := target.global_position.distance_to(center)
			if dist > _blast_radius:
				continue
			if target.has_method("receive_explosion"):
				target.receive_explosion(center, _blast_damage, _shooter)
			elif target.has_method("apply_damage"):
				target.apply_damage(_blast_damage, _shooter)
			elif target.has_method("take_damage"):
				target.take_damage(_blast_damage)
