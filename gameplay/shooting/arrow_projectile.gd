extends Node3D

const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const BirdFeatherBurstFX := preload("res://characters/animals/bird_feather_burst_fx.gd")
const DuelHitTest := preload("res://gameplay/duel/duel_hit_test.gd")
const BulletHitDamage := preload("res://gameplay/shooting/bullet_hit_damage.gd")
const LightningGemCombat := preload("res://gameplay/combat/lightning_gem_combat.gd")
const FireGemCombat := preload("res://gameplay/combat/fire_gem_combat.gd")
const IceGemCombat := preload("res://gameplay/combat/ice_gem_combat.gd")

const ARROW_DAMAGE := 2
const GRAVITY := 9.8
const MAX_FLIGHT_TIME := 12.0
const VISUAL_SCALE := 3.0
const STICK_EMBED := 0.18
const HIT_RADIUS := 0.08
## Root-position prefilter radius: covers capsule center offset + half height
## + radius for the largest targets (mounted riders, horses).
const TARGET_PREFILTER_MARGIN := 5.0

var _velocity := Vector3.ZERO
var _shooter: Node3D
var _exclude: Array[RID] = []
var _flight_time := 0.0
var _stuck := false
var _stick_host: Node
var _boss_reflected := false


func setup(
	origin: Vector3,
	direction: Vector3,
	speed: float,
	exclude: Array = [],
	shooter: Node3D = null
) -> void:
	global_position = origin
	_shooter = shooter
	_exclude.clear()
	for item in exclude:
		if item is RID:
			_exclude.append(item)
		elif item is CollisionObject3D:
			_exclude.append(item.get_rid())
		elif item is Node3D:
			_add_exclude_node(item)

	var dir := direction.normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector3.FORWARD
	_velocity = dir * speed
	scale = Vector3.ONE * VISUAL_SCALE
	_orient_along_velocity()


func mark_as_boss_reflected() -> void:
	_boss_reflected = true


func enable_threat_outline(
	color: Color = Color(1.0, 0.08, 0.05, 0.9),
	grow: float = 0.07
) -> void:
	const AuraShader := preload("res://gameplay/fx/brawl_aura.gdshader")
	var material := ShaderMaterial.new()
	material.shader = AuraShader
	material.set_shader_parameter("aura_color", color)
	material.set_shader_parameter("grow_amount", grow)
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh != null:
			mesh.material_overlay = material


func _add_exclude_node(node: Node3D) -> void:
	if node is CollisionObject3D:
		_exclude.append(node.get_rid())
	for child in node.get_children():
		if child is CollisionObject3D:
			_exclude.append(child.get_rid())


func _physics_process(delta: float) -> void:
	if _stuck:
		return

	var dt := GameTime.physics_delta(delta)
	_flight_time += dt
	if _flight_time >= MAX_FLIGHT_TIME:
		queue_free()
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

	var hit := _cast_hit(space_state, from, to, step_length)
	if not hit.is_empty():
		_resolve_hit(hit)
		return

	global_position = to
	_orient_along_velocity()


func _cast_hit(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	step_length: float
) -> Dictionary:
	var direction := _velocity.normalized()
	if direction.length_squared() < 0.0001:
		direction = (to - from).normalized()
	var world_hit := _cast_world_ray(space_state, from, to, step_length)
	var duel_hit := _cast_duel_targets(from, direction, step_length)
	var horse_hit := _cast_horse_bodies(from, direction, step_length)
	var equestrian_hit := BulletHitDamage.resolve_equestrian_hit(
		from,
		direction,
		step_length,
		world_hit,
		duel_hit,
		horse_hit,
		get_tree(),
		_shooter
	)
	if not equestrian_hit.is_empty():
		return equestrian_hit
	return DuelHitTest.closest_hit(from, [world_hit, duel_hit])


func _cast_world_ray(
	space_state: PhysicsDirectSpaceState3D,
	from: Vector3,
	to: Vector3,
	max_distance: float
) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = true
	query.collide_with_bodies = true
	query.hit_back_faces = true
	if not _exclude.is_empty():
		query.exclude = _exclude

	var hit := space_state.intersect_ray(query)
	if hit.is_empty():
		return {}

	if from.distance_to(hit.position) > max_distance + 0.001:
		return {}

	return hit


func _cast_duel_targets(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_target: Node = null

	var reach := max_distance + TARGET_PREFILTER_MARGIN
	var reach_sq := reach * reach
	for target in get_tree().get_nodes_in_group("duel_target"):
		var target_3d := target as Node3D
		if target_3d != null and target_3d.global_position.distance_squared_to(from) > reach_sq:
			continue
		if target == _shooter or not _is_vulnerable_duel_target(target):
			continue
		if not target.has_method("get_bullet_capsule"):
			continue

		var hit_t := BulletHitDamage.cast_duel_target_ray(from, dir, max_distance, target, HIT_RADIUS)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_target = target

	if best_target == null:
		return {}

	return {
		"position": from + dir * best_t,
		"normal": -dir,
		"collider": best_target,
		"duel_target": best_target,
	}


func _is_vulnerable_duel_target(target: Node) -> bool:
	return BulletHitDamage.is_vulnerable_to_shooter(_shooter, target)


func _cast_horse_bodies(from: Vector3, dir: Vector3, max_distance: float) -> Dictionary:
	var best_t := max_distance + 1.0
	var best_horse: Node = null

	var reach := max_distance + TARGET_PREFILTER_MARGIN
	var reach_sq := reach * reach
	for node in get_tree().get_nodes_in_group("stupid_horse"):
		if not is_instance_valid(node):
			continue
		var node_3d := node as Node3D
		if node_3d != null and node_3d.global_position.distance_squared_to(from) > reach_sq:
			continue
		var hit_t := BulletHitDamage.cast_horse_body_ray(from, dir, max_distance, node, HIT_RADIUS)
		if hit_t >= 0.0 and hit_t < best_t:
			best_t = hit_t
			best_horse = node

	if best_horse == null:
		return {}

	return {
		"position": from + dir * best_t,
		"normal": -dir,
		"collider": best_horse,
		"horse_target": best_horse,
	}


func _orient_along_velocity() -> void:
	if _velocity.length_squared() < 0.0001:
		return
	var forward := _velocity.normalized()
	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.98:
		up = Vector3.FORWARD
	# Shaft mesh points along local -Z (Godot look_at / Basis.looking_at forward).
	global_transform.basis = Basis.looking_at(forward, up)


func _resolve_hit(hit: Dictionary) -> void:
	global_position = hit.position
	_orient_along_velocity()

	var collider: Object = hit.get("collider")
	var hit_kind := _classify_hit(collider)
	var hit_info := {
		"position": hit.position,
		"normal": hit.normal,
		"direction": _velocity.normalized(),
		"ray_origin": global_position - _velocity.normalized() * 0.2,
		"collider": collider,
		"shooter": _shooter,
		"damage": ARROW_DAMAGE,
		"arrow_hit": true,
		"projectile_kind": &"arrow",
		"projectile_speed": _velocity.length(),
	}
	if _boss_reflected:
		hit_info["reflected_hit"] = true
		hit_info["boss_reflected"] = true
	if hit.has("duel_target"):
		hit_info["duel_target"] = hit.duel_target
	if hit.has("horse_target"):
		hit_info["horse_target"] = hit.horse_target

	_play_impact_sound(hit_kind, hit.position)

	if hit_kind == &"bird":
		_explode_bird(collider, hit_info)
		queue_free()
		return

	if _dispatch_character_hit(collider, hit_info):
		if hit.has("duel_target"):
			queue_free()
			return
		var stick_parent := _resolve_stick_parent(collider, hit)
		if stick_parent != null and is_instance_valid(stick_parent):
			_stick_into(hit, stick_parent)
		return

	_stick_into(hit, _find_stick_parent(collider))


func _dispatch_character_hit(collider: Object, hit_info: Dictionary) -> bool:
	if hit_info.has("duel_target"):
		var duel_target: Node = hit_info.duel_target
		if duel_target != null and not BulletHitDamage.is_vulnerable_to_shooter(_shooter, duel_target):
			return false
		if duel_target != null and duel_target.has_method("receive_bullet_hit"):
			duel_target.receive_bullet_hit(hit_info)
			_try_elemental_procs(duel_target)
			return true

	if hit_info.has("horse_target"):
		var horse_target: Node = hit_info.horse_target
		if horse_target != null and horse_target.has_method("apply_bullet_hit"):
			horse_target.apply_bullet_hit(hit_info)
			return true

	var horse := BulletHitDamage.find_horse_from_collider(collider)
	if horse != null and horse.has_method("apply_bullet_hit"):
		horse.apply_bullet_hit(hit_info)
		return true

	if collider == null:
		return false

	var node := collider as Node
	while node != null:
		if node.has_method("apply_bullet_hit"):
			node.apply_bullet_hit(hit_info)
			# Hitboxes own apply_bullet_hit; resolve the actor for elemental procs.
			_try_elemental_procs(_resolve_elemental_combatant(node))
			return true
		if node.has_method("receive_bullet_hit"):
			if not BulletHitDamage.is_vulnerable_to_shooter(_shooter, node):
				return false
			node.receive_bullet_hit(hit_info)
			_try_elemental_procs(node)
			return true
		node = node.get_parent()

	return false


func _resolve_elemental_combatant(from_node: Node) -> Node:
	var node := from_node
	while node != null:
		if node.has_method("apply_fire_damage"):
			return node
		if node is CharacterBody3D and node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	node = from_node
	while node != null:
		if node.has_method("receive_bullet_hit"):
			return node
		node = node.get_parent()
	return from_node


func _try_elemental_procs(target: Node) -> void:
	if _shooter == null or target == null:
		return
	LightningGemCombat.try_proc_on_hit(_shooter, target, -1)
	FireGemCombat.try_proc_on_hit(_shooter, target, -1)
	IceGemCombat.try_proc_on_hit(_shooter, target, -1)


func _explode_bird(collider: Object, hit_info: Dictionary) -> void:
	var bird: Node = collider as Node
	while bird != null and not bird.is_in_group("ground_bird"):
		bird = bird.get_parent()

	if bird == null:
		return

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var direction: Vector3 = hit_info.get("direction", Vector3.UP)
	var fx_parent := get_tree().current_scene
	if fx_parent == null:
		fx_parent = get_parent()
	BirdFeatherBurstFX.spawn(fx_parent, hit_position, direction)
	GameAudio.play_explosion(fx_parent, hit_position)
	if bird.has_method("apply_bullet_hit"):
		bird.apply_bullet_hit(hit_info)
	elif bird.has_method("receive_bullet_hit"):
		bird.receive_bullet_hit(hit_info)


func _stick_into(hit: Dictionary, parent_node: Node) -> void:
	if parent_node == null or not is_instance_valid(parent_node):
		return

	_stuck = true
	set_physics_process(false)
	add_to_group("stuck_arrow")
	_stick_host = parent_node

	var normal: Vector3 = hit.get("normal", Vector3.UP).normalized()
	var forward := _velocity.normalized()
	if forward.length_squared() < 0.0001:
		forward = -normal
	var embed := forward * STICK_EMBED
	global_position = hit.position - embed
	global_transform.basis = Basis.looking_at(
		forward,
		Vector3.UP if absf(forward.dot(Vector3.UP)) < 0.98 else Vector3.FORWARD
	)

	var skeleton := _find_skeleton(parent_node)
	if skeleton != null:
		_stick_to_skeleton_bone(skeleton)
		return

	var world_xform := global_transform
	reparent(parent_node, true)
	global_transform = world_xform


func _stick_to_skeleton_bone(skeleton: Skeleton3D) -> void:
	var bone_id := _find_nearest_bone_id(skeleton, global_position)
	if bone_id < 0:
		bone_id = skeleton.find_bone("Spine02")
	if bone_id < 0:
		bone_id = skeleton.find_bone("Spine01")
	if bone_id < 0 and skeleton.get_bone_count() > 0:
		bone_id = 0
	if bone_id < 0:
		var fallback_xform := global_transform
		reparent(skeleton, true)
		global_transform = fallback_xform
		return

	var attachment := BoneAttachment3D.new()
	attachment.name = "StuckArrowMount"
	attachment.bone_idx = bone_id
	skeleton.add_child(attachment)

	var world_xform := global_transform
	reparent(attachment, true)
	global_transform = world_xform


func _resolve_stick_parent(collider: Object, _hit: Dictionary) -> Node:
	if collider is Node:
		var character := _find_character_root(collider as Node)
		if character != null:
			return character

		var oil_drum := _find_oil_drum(collider as Node)
		if oil_drum != null:
			if oil_drum.has_method("is_detonated") and oil_drum.call("is_detonated"):
				return null
			return oil_drum

	return _find_stick_parent(collider)


func _find_character_root(node: Node) -> Node:
	var current := node
	while current != null:
		if current.has_method("get_bullet_capsule") and current.has_method("receive_bullet_hit"):
			if current != _shooter:
				return current
		current = current.get_parent()
	return null


func _find_oil_drum(node: Node) -> Node:
	var current := node
	while current != null:
		if current.is_in_group("oil_drum"):
			return current
		current = current.get_parent()
	return null


func _find_skeleton(character: Node) -> Skeleton3D:
	if character == null:
		return null
	var skeleton := character.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		return skeleton
	return character.get_node_or_null("Model/Armature/Skeleton3D") as Skeleton3D


func _find_nearest_bone_id(skeleton: Skeleton3D, world_pos: Vector3) -> int:
	var best_id := -1
	var best_dist_sq := INF
	var sk_global := skeleton.global_transform

	for bone_id in skeleton.get_bone_count():
		var bone_global := sk_global * skeleton.get_bone_global_pose(bone_id)
		var dist_sq := bone_global.origin.distance_squared_to(world_pos)
		if dist_sq < best_dist_sq:
			best_dist_sq = dist_sq
			best_id = bone_id

	return best_id


func _find_stick_parent(collider: Object) -> Node:
	if collider is Node:
		var mark_root := ImpactFXScript.mark_root_for(collider as Node)
		if mark_root != null:
			return mark_root
		if collider is Node3D:
			return collider as Node3D
	return get_tree().current_scene


func _classify_hit(collider: Object) -> StringName:
	if collider == null:
		return &"generic"

	var node := collider as Node
	while node != null:
		if node.is_in_group("ground_bird"):
			return &"bird"
		if node.has_method("get_bullet_capsule") or node.has_method("receive_bullet_hit"):
			if node != _shooter:
				return &"character"
		if _is_wood_node(node):
			return &"wood"
		node = node.get_parent()

	return &"generic"


func _is_wood_node(node: Node) -> bool:
	if node.has_method("apply_bullet_hit") and node.get("surface_kind") == ImpactFX.SurfaceKind.WOOD:
		return true

	var node_name := node.name
	if node_name.begins_with("Build_"):
		return true
	if node_name.begins_with("Signs") or node_name.begins_with("Cart_"):
		return true
	if node_name == "PracticeFence" or node_name.begins_with("tree") or node_name.begins_with("pine_tree_serv"):
		return true
	return false


func _play_impact_sound(kind: StringName, position: Vector3) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	match kind:
		&"wood":
			GameAudio.play_arrow_wood_impact(parent, position)
		&"character", &"bird":
			GameAudio.play_arrow_body_impact(parent, position)
		_:
			pass
