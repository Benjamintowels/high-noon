extends Node3D

## Lit stick of dynamite. Dropped at the player's feet or thrown like a hatchet.
## Burns for FUSE_DURATION with accelerating white/red flash, then detonates.

const DynamiteGripScene := preload("res://characters/groyper/dynamite_grip.tscn")
const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const FUSE_DURATION := 3.0
const GRAVITY := 18.0
const HIT_RADIUS := 0.12
const VISUAL_SCALE := 1.0
const SPIN_SPEED_RAD := TAU * 1.8
const IMPACT_STUN := 0.65
const IMPACT_KNOCKBACK := 7.5
const IMPACT_KNOCKBACK_UP := 2.2

var _velocity := Vector3.ZERO
var _shooter: Node3D
var _exclude: Array[RID] = []
var _fuse_left := FUSE_DURATION
var _landed := false
var _exploded := false
var _thrown := false
var _impact_applied := false
var _visual: Node3D
var _flash_materials: Array[StandardMaterial3D] = []
var _base_albedos: Array[Color] = []
var _omni: OmniLight3D


static func spawn_dropped(
	parent: Node,
	origin: Vector3,
	shooter: Node3D = null
) -> Node3D:
	var stick: Node3D = (load("res://gameplay/combat/dynamite_projectile.gd") as GDScript).new()
	stick.name = "DynamiteProjectile"
	parent.add_child(stick)
	stick._thrown = false
	stick._build_visual()
	# Fall under gravity with no forward throw; exclude the shooter so the stick
	# doesn't catch on the player capsule at hand height.
	var exclude: Array = []
	if shooter != null:
		exclude.append(shooter)
		var hitbox := shooter.get_node_or_null("Hitbox")
		if hitbox is CollisionObject3D:
			exclude.append(hitbox)
	stick._begin(origin, Vector3.ZERO, exclude, shooter)
	return stick


static func spawn_thrown(
	parent: Node,
	origin: Vector3,
	direction: Vector3,
	speed: float,
	exclude: Array = [],
	shooter: Node3D = null
) -> Node3D:
	var stick: Node3D = (load("res://gameplay/combat/dynamite_projectile.gd") as GDScript).new()
	stick.name = "DynamiteProjectile"
	parent.add_child(stick)
	stick._thrown = true
	stick._build_visual()
	stick._begin(origin, direction.normalized() * speed, exclude, shooter)
	return stick


func _build_visual() -> void:
	_visual = DynamiteGripScene.instantiate()
	_visual.name = "Visual"
	add_child(_visual)
	scale = Vector3.ONE * VISUAL_SCALE
	_cache_flash_meshes(_visual)
	_omni = OmniLight3D.new()
	_omni.light_color = Color(1.0, 0.45, 0.12)
	_omni.light_energy = 0.0
	_omni.omni_range = 2.4
	add_child(_omni)


func _cache_flash_meshes(root: Node) -> void:
	_flash_materials.clear()
	_base_albedos.clear()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_inst := node as MeshInstance3D
		var mat := _ensure_flash_material(mesh_inst)
		if mat == null:
			continue
		_flash_materials.append(mat)
		_base_albedos.append(mat.albedo_color)


func _ensure_flash_material(mesh_inst: MeshInstance3D) -> StandardMaterial3D:
	if mesh_inst == null:
		return null
	var existing := mesh_inst.material_override
	if existing is StandardMaterial3D:
		var dup := (existing as StandardMaterial3D).duplicate() as StandardMaterial3D
		mesh_inst.material_override = dup
		return dup
	if mesh_inst.mesh == null or mesh_inst.mesh.get_surface_count() <= 0:
		return null
	var surface_mat := mesh_inst.get_active_material(0)
	if surface_mat is StandardMaterial3D:
		var surface_dup := (surface_mat as StandardMaterial3D).duplicate() as StandardMaterial3D
		mesh_inst.material_override = surface_dup
		return surface_dup
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = Color(0.72, 0.18, 0.12)
	fallback.roughness = 0.72
	mesh_inst.material_override = fallback
	return fallback


func _begin(origin: Vector3, velocity: Vector3, exclude: Array, shooter: Node3D) -> void:
	global_position = origin
	_velocity = velocity
	_shooter = shooter
	_fuse_left = FUSE_DURATION
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)
	if _thrown and _velocity.length_squared() > 0.0001:
		_orient_along_velocity()


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())
		elif child is Node3D:
			_add_exclude_node(child)


func _physics_process(delta: float) -> void:
	if _exploded:
		return
	var dt := GameTime.physics_delta(delta)

	_fuse_left -= dt
	_update_fuse_flash()
	if _fuse_left <= 0.0:
		_explode()
		return

	if _landed:
		return

	_velocity.y -= GRAVITY * dt
	var from := global_position
	var motion := _velocity * dt
	var space := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(from, from + motion)
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF
	query.exclude = _exclude
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		global_position = from + motion
		if _visual != null and _velocity.length_squared() > 0.01:
			# Light tumble on both drops and throws while airborne.
			_visual.rotate_x(SPIN_SPEED_RAD * dt * (1.0 if _thrown else 0.45))
		if _thrown:
			_orient_along_velocity()
		_try_overlap_stun(from)
		return

	global_position = hit.position
	_on_impact(hit)


func _try_overlap_stun(from: Vector3) -> void:
	if not _thrown or _impact_applied:
		return
	var space := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = HIT_RADIUS * 1.6
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = sphere
	shape_query.transform = Transform3D(Basis.IDENTITY, global_position)
	shape_query.collision_mask = 0xFFFFFFFF
	shape_query.exclude = _exclude
	var hits := space.intersect_shape(shape_query, 8)
	for result in hits:
		var collider: Object = result.get("collider")
		if _resolve_character_target(collider) != null:
			_on_impact({"collider": collider, "position": global_position, "normal": Vector3.UP})
			return
	# Also check path from previous position for fast throws.
	var path_query := PhysicsRayQueryParameters3D.create(from, global_position)
	path_query.exclude = _exclude
	path_query.collision_mask = 0xFFFFFFFF
	var path_hit := space.intersect_ray(path_query)
	if not path_hit.is_empty() and _resolve_character_target(path_hit.get("collider")) != null:
		_on_impact(path_hit)


func _orient_along_velocity() -> void:
	if _velocity.length_squared() < 0.0001:
		return
	look_at(global_position + _velocity.normalized(), Vector3.UP)


func _on_impact(hit: Dictionary) -> void:
	_landed = true
	_velocity = Vector3.ZERO
	var collider: Object = hit.get("collider")
	var normal: Vector3 = hit.get("normal", Vector3.UP)
	if normal.length_squared() > 0.0001:
		global_position += normal.normalized() * 0.05
	GameAudio.play_knife_thud(self, global_position)
	if _thrown and not _impact_applied:
		_impact_applied = true
		_try_impact_stun(collider, hit)


func _try_impact_stun(collider: Object, hit: Dictionary) -> void:
	var target := _resolve_character_target(collider)
	if target == null or target == _shooter:
		return
	if target.has_method("is_defeated") and target.is_defeated():
		return
	var hit_pos: Vector3 = hit.get("position", global_position)
	var direction := _velocity.normalized() if _velocity.length_squared() > 0.0001 else Vector3.FORWARD
	var hit_info := {
		"position": hit_pos,
		"normal": hit.get("normal", -direction),
		"direction": direction,
		"damage": 0,
		"chip_damage": 0.0,
		"melee": true,
		"punch_hit": true,
		"dynamite_throw": true,
		"knockback_speed": IMPACT_KNOCKBACK,
		"knockback_up": IMPACT_KNOCKBACK_UP,
		"force_knockback": true,
		"melee_stun_duration": IMPACT_STUN,
		"face_punch_reaction": true,
		"shooter": _shooter,
	}
	if target is CharacterBody3D:
		var body := target as CharacterBody3D
		body.velocity += direction * IMPACT_KNOCKBACK * 0.55
		body.velocity.y = maxf(body.velocity.y, IMPACT_KNOCKBACK_UP)
	if target.has_method("receive_bullet_hit"):
		target.receive_bullet_hit(hit_info)
	elif target.has_method("apply_bullet_hit"):
		target.apply_bullet_hit(hit_info)


func _resolve_character_target(collider: Object) -> Node:
	var node := collider as Node
	while node != null:
		if node.is_in_group("duel_target") or node.is_in_group("overworld_player"):
			return node
		if node.has_method("receive_bullet_hit") and node is CharacterBody3D:
			return node
		node = node.get_parent()
	return null


func _update_fuse_flash() -> void:
	var progress := 1.0 - clampf(_fuse_left / FUSE_DURATION, 0.0, 1.0)
	var freq := lerpf(2.5, 18.0, progress * progress)
	var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() * 0.001 * TAU * freq)
	var flash := Color(1.0, lerpf(1.0, 0.15, pulse), lerpf(1.0, 0.12, pulse), 1.0)
	var white_mix := lerpf(0.0, 0.85, pulse * progress)
	var color := flash.lerp(Color(1.0, 1.0, 1.0, 1.0), white_mix)
	var mix := lerpf(0.15, 1.0, progress)
	for i in _flash_materials.size():
		var mat := _flash_materials[i]
		if mat == null:
			continue
		var tinted := _base_albedos[i].lerp(color, mix)
		mat.albedo_color = tinted
		mat.emission_enabled = true
		mat.emission = color * lerpf(0.05, 1.35, pulse * progress)
		mat.emission_energy_multiplier = lerpf(0.2, 3.5, pulse * progress)
	if _omni != null:
		_omni.light_energy = lerpf(0.15, 4.5, pulse * progress)
		_omni.light_color = Color(1.0, lerpf(0.55, 0.2, pulse), 0.08)


func _explode() -> void:
	if _exploded:
		return
	_exploded = true
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	var center := global_position
	# Load at call-time so a stale/unresolved preload can't crash throw spawn.
	var explosion_script = load("res://gameplay/combat/dynamite_explosion.gd")
	if explosion_script != null:
		# Defaults match WEAPON_STATS[DYNAMITE] blast_damage/radius.
		explosion_script.call("detonate", parent, center, _shooter)
	else:
		push_error("DynamiteProjectile: failed to load dynamite_explosion.gd")
	queue_free()
