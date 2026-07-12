extends RigidBody3D
class_name PhysicsTable
## Heavy pushable wooden table. Builds its collider from the visual mesh at
## runtime (absorbing any editor scaling), wakes frozen props resting on its
## top so they ride along or tumble when it moves, and explodes into wood
## debris with a small damage AoE when a parry-thrown body crashes into it.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const ParryTossFXScript := preload("res://gameplay/fx/parry_toss_fx.gd")
const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")

const WORLD_COLLISION_LAYER := 1
const PUSHABLE_COLLISION_LAYER := 2
const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]

const PUSHER_RADIUS := 0.36
const CONTACT_SLACK := 0.22
const PUSH_ALIGNMENT_MIN := 0.2
const PUSH_FORCE := 150.0
const PUNCH_IMPULSE := 34.0
const PUNCH_TORQUE := 4.0
const BULLET_IMPULSE := 10.0
const RIDER_SCAN_HEIGHT := 0.7
const TABLETOP_KNOCK_MARGIN := Vector3(0.24, 0.4, 0.24)

const EXPLODE_RADIUS := 3.0
const EXPLODE_DAMAGE := 1
const EXPLODE_PROP_IMPULSE := 14.0
const WOOD_CHUNK_COUNT := 22
const DEBRIS_PIECE_COUNT := 7
const DEBRIS_LIFETIME := 7.0
const DEBRIS_IMPULSE := 4.5
const BREAK_CAMERA_SHAKE := 0.85
const MOVE_SOUND_SPEED := 0.65
const MOVE_SOUND_COOLDOWN := 0.42

@export var table_mass := 22.0
@export var explodes_on_thrown_body := true

var _half_extents := Vector3(0.9, 0.5, 0.65)
var _box_center := Vector3.ZERO
var _hit_cooldown := 0.0
var _move_sound_cooldown := 0.0
var _exploded := false


func _ready() -> void:
	add_to_group(&"punchable_prop")
	mass = table_mass
	collision_layer = PUSHABLE_COLLISION_LAYER
	# Peaceful NPCs walk through tables (their mask skips pushables), but a
	# mask that sees their layer lets the solver drag the table along with
	# them anyway. Only combat-layer NPCs may bump it physically.
	collision_mask = (
		TownNpcShoveScript.PUSHABLE_COLLISION_MASK
		& ~TownNpcShoveScript.TOWN_NPC_COLLISION_LAYER
	)
	linear_damp = 1.6
	angular_damp = 2.0
	continuous_cd = true
	contact_monitor = true
	max_contacts_reported = 8
	body_entered.connect(_on_body_entered)
	_absorb_editor_scale()
	call_deferred("_build_collider_from_visual")


func _absorb_editor_scale() -> void:
	# Non-uniform scale on a RigidBody breaks Jolt; move it onto the visual.
	var editor_scale := scale
	if editor_scale.is_equal_approx(Vector3.ONE):
		return
	scale = Vector3.ONE
	for child in get_children():
		if child is Node3D:
			var node := child as Node3D
			node.scale *= editor_scale
			node.position *= editor_scale


func _build_collider_from_visual() -> void:
	# Strip any imported static collision first.
	for child in find_children("PropCollision", "Node3D", true, false):
		child.queue_free()
	for child in find_children("*", "StaticBody3D", true, false):
		var body := child as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0

	var bounds := AABB()
	var found := false
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null:
			continue
		var mesh_aabb := mesh.get_aabb()
		var to_body := global_transform.affine_inverse() * mesh.global_transform
		var local_aabb := to_body * mesh_aabb
		if found:
			bounds = bounds.merge(local_aabb)
		else:
			bounds = local_aabb
			found = true
	if not found:
		push_warning("PhysicsTable: no visual mesh found; keeping fallback collider.")
		return

	_half_extents = bounds.size * 0.5
	_box_center = bounds.position + _half_extents

	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		add_child(shape_node)
	var box := BoxShape3D.new()
	box.size = bounds.size
	shape_node.shape = box
	shape_node.position = _box_center

	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = _box_center


func _physics_process(delta: float) -> void:
	_hit_cooldown = maxf(_hit_cooldown - delta, 0.0)
	_move_sound_cooldown = maxf(_move_sound_cooldown - delta, 0.0)
	if freeze or _exploded:
		return
	if linear_velocity.length_squared() > 0.01 or angular_velocity.length_squared() > 0.01:
		_wake_riders(false)
		_knock_nearby_tabletop_props(false)
		_try_play_move_sound()
	_apply_character_pushes()


func _try_play_move_sound() -> void:
	if _move_sound_cooldown > 0.0:
		return
	if linear_velocity.length() < MOVE_SOUND_SPEED:
		return
	_move_sound_cooldown = MOVE_SOUND_COOLDOWN
	GameAudioScript.play_table_move(self, get_prop_center())


func _apply_character_pushes() -> void:
	var contact_range := maxf(_half_extents.x, _half_extents.z) + PUSHER_RADIUS + CONTACT_SLACK
	for group_name in PUSHER_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CharacterBody3D:
				_apply_push_from_mover(node as CharacterBody3D, contact_range)


func _apply_push_from_mover(mover: CharacterBody3D, contact_range: float) -> void:
	# The table is heavy set dressing: NPCs only shove it around mid-brawl,
	# never while idly wandering. Players can always push it.
	if mover.is_in_group(&"town_npc"):
		if not (mover.has_method("is_combat_active") and mover.is_combat_active()):
			return
	var center := global_position + _box_center
	var offset := center - mover.global_position
	offset.y = 0.0
	if offset.length_squared() > contact_range * contact_range:
		return

	var intent := Vector3(mover.velocity.x, 0.0, mover.velocity.z)
	if mover.has_method("get_push_intent"):
		intent = mover.get_push_intent()
		intent.y = 0.0
	if intent.length_squared() < 0.04:
		return
	var push_dir := offset.normalized()
	if intent.normalized().dot(push_dir) < PUSH_ALIGNMENT_MIN:
		return

	sleeping = false
	_wake_riders(false)
	_knock_nearby_tabletop_props(false)
	apply_force(push_dir * PUSH_FORCE, _box_center - Vector3(0.0, _half_extents.y * 0.6, 0.0))


## Frozen props resting on the tabletop (bottles, cans) get woken and made to
## collide with pushable props, so they ride the table or tumble off it.
func _wake_riders(use_deferred: bool = false) -> void:
	var space := get_world_3d().direct_space_state
	var box := BoxShape3D.new()
	box.size = Vector3(_half_extents.x * 2.0, RIDER_SCAN_HEIGHT, _half_extents.z * 2.0)
	var scan_center := global_position + _box_center + Vector3(0.0, _half_extents.y + RIDER_SCAN_HEIGHT * 0.5, 0.0)
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = box
	query.transform = Transform3D(global_transform.basis, scan_center)
	query.collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	query.collide_with_bodies = true
	query.exclude = [get_rid()]
	for hit in space.intersect_shape(query, 24):
		var collider: Object = hit.collider
		if collider is RigidBody3D:
			_wake_rider(collider as RigidBody3D, use_deferred)

	var tabletop_center := global_position + _box_center
	var tabletop_reach := _half_extents + TABLETOP_KNOCK_MARGIN
	for node in get_tree().get_nodes_in_group(&"tabletop_prop"):
		if not (node is RigidBody3D):
			continue
		var rider := node as RigidBody3D
		if not rider.freeze:
			continue
		if not _is_point_in_table_bounds(rider.global_position, tabletop_center, tabletop_reach):
			continue
		_wake_rider(rider, use_deferred)


func _knock_nearby_tabletop_props(use_deferred: bool) -> void:
	var tabletop_center := global_position + _box_center
	var knock_reach := _half_extents + TABLETOP_KNOCK_MARGIN + Vector3(0.18, 0.0, 0.18)
	for node in get_tree().get_nodes_in_group(&"tabletop_prop"):
		if not (node is RigidBody3D):
			continue
		var prop := node as RigidBody3D
		if not prop.freeze:
			continue
		if not _is_point_in_table_bounds(prop.global_position, tabletop_center, knock_reach):
			continue
		_wake_rider(prop, use_deferred)


func _is_point_in_table_bounds(world_point: Vector3, center: Vector3, half_extents: Vector3) -> bool:
	var local := global_transform.basis.inverse() * (world_point - center)
	return (
		absf(local.x) <= half_extents.x
		and absf(local.y) <= half_extents.y
		and absf(local.z) <= half_extents.z
	)


func _on_body_entered(body: Node) -> void:
	if not (body is RigidBody3D) or not body.is_in_group(&"tabletop_prop"):
		return
	_wake_rider(body as RigidBody3D, true)


func _wake_rider(rider: RigidBody3D, use_deferred: bool) -> void:
	if not is_instance_valid(rider) or not rider.freeze:
		return
	if rider.has_method("wake_from_table"):
		if use_deferred:
			rider.call_deferred("wake_from_table", self)
		else:
			rider.wake_from_table(self)
		return
	var new_mask := rider.collision_mask | TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	if use_deferred:
		rider.set_deferred("collision_mask", new_mask)
		rider.set_deferred("freeze", false)
		rider.set_deferred("sleeping", false)
		return
	rider.collision_mask = new_mask
	rider.freeze = false
	rider.sleeping = false
	if linear_velocity.length_squared() > 0.0001:
		rider.linear_velocity += linear_velocity
	if angular_velocity.length_squared() > 0.0001:
		rider.angular_velocity += angular_velocity * 0.35


## The visual (and collider) sit at a baked offset from the node origin, so
## anything measuring distance to this prop must use these, not the origin.
func get_prop_center() -> Vector3:
	return global_position + _box_center


func get_prop_contact_radius() -> float:
	return maxf(_half_extents.x, _half_extents.z)


func get_prop_half_extents() -> Vector3:
	return _half_extents


func receive_punch(hit_info: Dictionary) -> void:
	if _exploded:
		return
	if explodes_on_thrown_body and bool(hit_info.get("thrown_body", false)):
		# This is called from inside a physics callback — freeing the body,
		# applying impulses, and activating defeat ragdolls mid-step crashes
		# Jolt. Mark now, detonate at idle time.
		_exploded = true
		call_deferred("_explode", hit_info)
		return

	_hit_cooldown = 0.5
	sleeping = false
	_wake_riders(false)
	_knock_nearby_tabletop_props(false)
	var dir: Vector3 = hit_info.get("direction", Vector3.ZERO)
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		dir = -global_transform.basis.z
	dir = dir.normalized()
	dir.y = 0.2
	apply_impulse(dir.normalized() * PUNCH_IMPULSE, _box_center + Vector3(0.0, _half_extents.y * 0.5, 0.0))
	apply_torque_impulse(Vector3(0.0, randf_range(-1.0, 1.0), 0.0) * PUNCH_TORQUE)
	GameAudioScript.play_knife_thud(self, global_position)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _exploded:
		return
	sleeping = false
	_wake_riders(false)
	_knock_nearby_tabletop_props(false)
	var dir: Vector3 = hit_info.get("direction", Vector3.ZERO)
	if dir.length_squared() < 0.0001:
		return
	var hit_position: Vector3 = hit_info.get("position", global_position)
	apply_impulse(dir.normalized() * BULLET_IMPULSE, hit_position - global_position)
	GameAudioScript.play_knife_thud(self, hit_position)


func _explode(hit_info: Dictionary) -> void:
	if not is_inside_tree():
		return
	var center := global_position + _box_center
	var scene_parent := get_parent()
	var shooter: Node3D = hit_info.get("shooter") as Node3D
	var thrown_victim: Node = hit_info.get("thrown_victim") as Node

	_wake_riders(true)
	_spawn_wood_debris(scene_parent, center)
	_spawn_physics_debris(scene_parent, center)
	_spawn_break_flash(scene_parent, center)
	ParryTossFXScript.spawn_bounce_flash(scene_parent, center)
	ParryTossFXScript.spawn_toss_burst(scene_parent, center + Vector3(0.0, 0.3, 0.0), hit_info.get("direction", Vector3.FORWARD))
	GameAudioScript.play_table_break(scene_parent, center)
	_shake_player_camera(center)

	# Damage every nearby NPC and shove nearby physics props outward.
	var tree := get_tree()
	for node in tree.get_nodes_in_group(&"duel_target"):
		if not (node is Node3D) or node == shooter or node == thrown_victim:
			continue
		if node.is_in_group(&"overworld_player"):
			continue
		if not node.has_method("receive_bullet_hit"):
			continue
		if node.has_method("is_defeated") and node.is_defeated():
			continue
		var target := node as Node3D
		var to_target := target.global_position - center
		if to_target.length() > EXPLODE_RADIUS:
			continue
		var away := Vector3(to_target.x, 0.0, to_target.z)
		away = away.normalized() if away.length_squared() > 0.0001 else Vector3.FORWARD
		# Same hit shape as a landed punch: melee damage arrives as chip.
		node.receive_bullet_hit({
			"damage": 0,
			"chip_damage": float(EXPLODE_DAMAGE),
			"melee": true,
			"punch_hit": true,
			"direction": away,
			"position": target.global_position + Vector3(0.0, 1.0, 0.0),
			"shooter": shooter,
			"knockback_speed": 5.0,
			"knockback_up": 1.4,
			"force_knockback": true,
			"melee_stun_duration": 0.55,
			"face_punch_reaction": true,
		})

	for group_name: StringName in [&"punchable_prop", &"sit_chair"]:
		for node in tree.get_nodes_in_group(group_name):
			if node == self or not (node is RigidBody3D):
				continue
			var prop := node as RigidBody3D
			var prop_center := prop.global_position
			if node.has_method("get_prop_center"):
				prop_center = node.get_prop_center()
			var to_prop := prop_center - center
			var distance := to_prop.length()
			if distance > EXPLODE_RADIUS or distance < 0.001:
				continue
			var falloff := 1.0 - distance / EXPLODE_RADIUS
			prop.sleeping = false
			prop.apply_impulse(
				(to_prop.normalized() + Vector3.UP * 0.4).normalized() * EXPLODE_PROP_IMPULSE * falloff * prop.mass / 7.0
			)

	queue_free()


func _spawn_wood_debris(parent: Node, center: Vector3) -> void:
	if parent == null:
		return
	var particles := CPUParticles3D.new()
	particles.one_shot = true
	particles.amount = WOOD_CHUNK_COUNT
	particles.lifetime = 1.2
	particles.explosiveness = 1.0
	particles.direction = Vector3.UP
	particles.spread = 70.0
	particles.initial_velocity_min = 3.5
	particles.initial_velocity_max = 7.5
	particles.angular_velocity_min = -360.0
	particles.angular_velocity_max = 360.0
	particles.gravity = Vector3(0.0, -14.0, 0.0)
	var chunk := BoxMesh.new()
	chunk.size = Vector3(0.24, 0.07, 0.12)
	chunk.material = _wood_material()
	particles.mesh = chunk
	parent.add_child(particles)
	particles.global_position = center
	particles.emitting = true
	parent.get_tree().create_timer(1.8).timeout.connect(particles.queue_free)


## A handful of real physics planks that clatter out of the wreck, linger,
## then shrink away.
func _spawn_physics_debris(parent: Node, center: Vector3) -> void:
	if parent == null:
		return
	var material := _wood_material()
	for i in DEBRIS_PIECE_COUNT:
		var piece := RigidBody3D.new()
		piece.collision_layer = PUSHABLE_COLLISION_LAYER
		piece.collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
		piece.mass = 1.2
		piece.linear_damp = 0.4
		piece.angular_damp = 0.6

		var size := Vector3(
			randf_range(0.28, 0.55),
			randf_range(0.04, 0.08),
			randf_range(0.1, 0.22)
		)
		var mesh_instance := MeshInstance3D.new()
		var plank := BoxMesh.new()
		plank.size = size
		plank.material = material
		mesh_instance.mesh = plank
		piece.add_child(mesh_instance)

		var shape := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = size
		shape.shape = box
		piece.add_child(shape)

		parent.add_child(piece)
		var angle := TAU * float(i) / float(DEBRIS_PIECE_COUNT) + randf_range(-0.3, 0.3)
		var out := Vector3(cos(angle), 0.0, sin(angle))
		piece.global_position = center + out * randf_range(0.15, 0.5) + Vector3(0.0, randf_range(0.1, 0.45), 0.0)
		piece.rotation = Vector3(randf_range(0.0, TAU), randf_range(0.0, TAU), randf_range(0.0, TAU))
		piece.apply_impulse((out + Vector3.UP * randf_range(0.6, 1.2)).normalized() * DEBRIS_IMPULSE * piece.mass)
		piece.apply_torque_impulse(Vector3(
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0),
			randf_range(-1.0, 1.0)
		) * 1.4)

		var tween := piece.create_tween()
		tween.tween_interval(DEBRIS_LIFETIME)
		tween.tween_property(mesh_instance, "scale", Vector3(0.01, 0.01, 0.01), 0.6)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		tween.tween_callback(piece.queue_free)


func _wood_material() -> StandardMaterial3D:
	var wood := StandardMaterial3D.new()
	wood.albedo_color = Color(0.42, 0.28, 0.16)
	wood.roughness = 0.9
	return wood


func _shake_player_camera(center: Vector3) -> void:
	for node in get_tree().get_nodes_in_group(&"overworld_player"):
		if not (node is Node3D) or not node.has_method("apply_camera_shake"):
			continue
		var distance := (node as Node3D).global_position.distance_to(center)
		var strength := BREAK_CAMERA_SHAKE * clampf(1.0 - distance / 10.0, 0.25, 1.0)
		node.apply_camera_shake(strength)


func _spawn_break_flash(parent: Node, center: Vector3) -> void:
	if parent == null:
		return
	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.8, 0.5)
	light.light_energy = 5.0
	light.omni_range = EXPLODE_RADIUS + 0.5
	light.shadow_enabled = false
	parent.add_child(light)
	light.global_position = center
	var tween := light.create_tween()
	tween.tween_property(light, "light_energy", 0.0, 0.3)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(light.queue_free)
