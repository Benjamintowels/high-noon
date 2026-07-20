extends Node3D

## Makes static world props (rocks, fence planks, barrels, boxes, trees) solid
## obstacles that shatter when hit by a dynamite blast.

const WoodBreakFXScript := preload("res://gameplay/fx/wood_break_fx.gd")
const DirtBurstFXScript := preload("res://gameplay/fx/dirt_burst_fx.gd")
const LeafBurstFXScript := preload("res://gameplay/fx/leaf_burst_fx.gd")
const ParryTossFXScript := preload("res://gameplay/fx/parry_toss_fx.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

enum PropKind {
	WOOD,
	ROCK,
	TREE,
}

const FIRE_BREAK_DAMAGE := 2.0

@export var prop_kind: PropKind = PropKind.WOOD
@export var collision_size := Vector3(1.2, 1.2, 1.2)
@export var auto_fit_collision := true

var _broken := false
var _body: StaticBody3D
var _fire_damage_accum := 0.0


static func install_on(node: Node3D, kind: PropKind = PropKind.WOOD) -> Node3D:
	if node == null:
		return null
	if node.has_meta("breakable_prop_installed"):
		return node.get_node_or_null("BreakableProp") as Node3D
	var breaker = load("res://gameplay/world/breakable_prop.gd").new()
	breaker.name = "BreakableProp"
	breaker.prop_kind = kind
	node.add_child(breaker)
	node.set_meta("breakable_prop_installed", true)
	return breaker


func _ready() -> void:
	add_to_group("breakable_prop")
	_ensure_collision()


func get_prop_center() -> Vector3:
	var host := get_parent() as Node3D
	if host == null:
		return global_position
	if auto_fit_collision:
		var aabb := _combined_aabb(host)
		if aabb.size.length_squared() > 0.0001:
			return host.to_global(aabb.get_center())
	return host.global_position + Vector3(0.0, collision_size.y * 0.5, 0.0)


func break_from_explosion(hit_info: Dictionary) -> void:
	_break(hit_info)


func receive_punch(hit_info: Dictionary) -> void:
	if bool(hit_info.get("explosion", false)) or bool(hit_info.get("dynamite", false)):
		_break(hit_info)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if bool(hit_info.get("fire_burn", false)):
		apply_fire_damage(float(hit_info.get("chip_damage", 0.2)))
		return
	if bool(hit_info.get("explosion", false)) or bool(hit_info.get("dynamite", false)):
		_break(hit_info)


func apply_fire_damage(amount: float) -> void:
	if _broken or amount <= 0.0:
		return
	if prop_kind != PropKind.WOOD:
		return
	_fire_damage_accum += amount
	if _fire_damage_accum >= FIRE_BREAK_DAMAGE:
		_break({"direction": Vector3.UP, "fire_burn": true})


func _break(hit_info: Dictionary) -> void:
	if _broken:
		return
	_broken = true
	var host := get_parent() as Node3D
	var center := get_prop_center()
	var parent := host.get_parent() if host != null else get_parent()
	var direction: Vector3 = hit_info.get("direction", Vector3.UP)

	match prop_kind:
		PropKind.ROCK:
			DirtBurstFXScript.spawn_burst(parent, center, 14)
			_spawn_rock_chunks(parent, center, direction)
			GameAudioScript.play_knife_thud(parent, center)
		PropKind.TREE:
			LeafBurstFXScript.spawn(parent, center)
			WoodBreakFXScript.spawn(parent, center, 16, 5, direction)
			DirtBurstFXScript.spawn_burst(parent, center, 8)
			GameAudioScript.play_table_break(parent, center)
		_:
			WoodBreakFXScript.spawn(parent, center, 14, 5, direction)
			ParryTossFXScript.spawn_bounce_flash(parent, center)
			GameAudioScript.play_table_break(parent, center)

	_shake_player(center)
	if host != null:
		host.visible = false
		_disable_host_collision(host)
		host.queue_free()
	else:
		queue_free()


func _ensure_collision() -> void:
	var host := get_parent() as Node3D
	if host == null:
		return

	# If the prop already has collision (PropCollision, rock StaticBody, etc.),
	# only ensure layer 1 — never rebuild shapes on scaled ExtraTrees bodies.
	# ExtraTrees parent StaticBodies under a ~100x mesh transform; sizing a box
	# in host space on that body double-scales into a sky-high collider.
	var existing := _find_static_body(host)
	if existing != null:
		_body = existing
		_enable_blocking_collision(existing)
		if prop_kind == PropKind.ROCK:
			_upgrade_rock_concave_to_box(existing)
		return

	# Rocks / props with no collision yet: add a host-local box at the AABB center.
	var aabb := _combined_aabb(host)
	_body = StaticBody3D.new()
	_body.name = "BreakableCollision"
	_body.collision_layer = 1
	_body.collision_mask = 0
	host.add_child(_body)
	var shape := CollisionShape3D.new()
	shape.shape = _make_box_shape_from_aabb(aabb)
	if aabb.size.length_squared() > 0.0001:
		shape.position = aabb.get_center()
	_body.add_child(shape)


func _upgrade_rock_concave_to_box(body: StaticBody3D) -> void:
	# Concave trimeshes often don't block CharacterBody3D in Jolt. Rebuild the
	# box in the StaticBody's own local space (usually the mesh node), not the
	# breakable host space, so parent scales aren't applied twice.
	var space_node := body.get_parent() as Node3D
	if space_node == null:
		space_node = get_parent() as Node3D
	if space_node == null:
		return
	var aabb := _combined_aabb(space_node)
	if aabb.size.length_squared() < 0.0001:
		return
	# Convert AABB from space_node local into body local.
	var to_body := body.global_transform.affine_inverse() * space_node.global_transform
	var body_aabb := _xform_aabb(to_body, aabb)
	var box := _make_box_shape_from_aabb(body_aabb)
	var placed := false
	for child in body.get_children():
		if child is CollisionShape3D:
			var col := child as CollisionShape3D
			col.shape = box
			col.position = body_aabb.get_center()
			col.disabled = false
			placed = true
			break
	if not placed:
		var shape := CollisionShape3D.new()
		shape.shape = box
		shape.position = body_aabb.get_center()
		body.add_child(shape)


func _find_static_body(host: Node) -> StaticBody3D:
	if host is StaticBody3D:
		return host as StaticBody3D
	for child in host.get_children():
		var found := _find_static_body(child)
		if found != null:
			return found
	return null


func _enable_blocking_collision(body: StaticBody3D) -> void:
	body.collision_layer = 1
	body.collision_mask = 0
	for child in body.get_children():
		if child is CollisionShape3D:
			(child as CollisionShape3D).disabled = false


func _make_box_shape_from_aabb(aabb: AABB) -> BoxShape3D:
	var box := BoxShape3D.new()
	if auto_fit_collision and aabb.size.length_squared() > 0.0001:
		# Clamp so a bad AABB can never create a stage-sized platform.
		box.size = Vector3(
			clampf(aabb.size.x, 0.4, 12.0),
			clampf(aabb.size.y, 0.4, 18.0),
			clampf(aabb.size.z, 0.4, 12.0)
		)
		return box
	box.size = collision_size
	return box


func _combined_aabb(host: Node3D) -> AABB:
	var merged := AABB()
	var has_any := false
	var meshes: Array = []
	if host is MeshInstance3D:
		meshes.append(host)
	meshes.append_array(host.find_children("*", "MeshInstance3D", true, false))
	for node in meshes:
		var mesh_inst := node as MeshInstance3D
		if mesh_inst.mesh == null or not mesh_inst.visible:
			continue
		var local_aabb := mesh_inst.get_aabb()
		var xf := host.global_transform.affine_inverse() * mesh_inst.global_transform
		var world_aabb := _xform_aabb(xf, local_aabb)
		if not has_any:
			merged = world_aabb
			has_any = true
		else:
			merged = merged.merge(world_aabb)
	return merged if has_any else AABB()


func _xform_aabb(xf: Transform3D, aabb: AABB) -> AABB:
	var points: Array[Vector3] = []
	for i in 8:
		points.append(xf * aabb.get_endpoint(i))
	var out := AABB(points[0], Vector3.ZERO)
	for i in range(1, 8):
		out = out.expand(points[i])
	return out


func _disable_host_collision(host: Node) -> void:
	if host is CollisionObject3D:
		var body := host as CollisionObject3D
		body.collision_layer = 0
		body.collision_mask = 0
	for child in host.get_children():
		_disable_host_collision(child)


func _spawn_rock_chunks(parent: Node, center: Vector3, direction: Vector3) -> void:
	if parent == null:
		return
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.38, 0.34, 0.3)
	mat.roughness = 0.95
	for i in 7:
		var piece := RigidBody3D.new()
		piece.collision_layer = 2
		piece.collision_mask = 1
		piece.mass = 2.2
		var mesh_inst := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(
			randf_range(0.18, 0.45),
			randf_range(0.14, 0.32),
			randf_range(0.16, 0.4)
		)
		mesh.material = mat
		mesh_inst.mesh = mesh
		piece.add_child(mesh_inst)
		var col := CollisionShape3D.new()
		var shape := BoxShape3D.new()
		shape.size = mesh.size
		col.shape = shape
		piece.add_child(col)
		parent.add_child(piece)
		piece.global_position = center + Vector3(
			randf_range(-0.3, 0.3),
			randf_range(0.1, 0.5),
			randf_range(-0.3, 0.3)
		)
		var impulse := direction.normalized() * randf_range(4.0, 9.0)
		impulse += Vector3(randf_range(-3.0, 3.0), randf_range(3.0, 7.0), randf_range(-3.0, 3.0))
		piece.apply_central_impulse(impulse)
		piece.apply_torque_impulse(Vector3(
			randf_range(-6.0, 6.0),
			randf_range(-6.0, 6.0),
			randf_range(-6.0, 6.0)
		))
		var tree := parent.get_tree()
		if tree != null:
			tree.create_timer(6.0).timeout.connect(piece.queue_free)


func _shake_player(center: Vector3) -> void:
	var tree := get_tree()
	if tree == null:
		return
	for group_name: StringName in [&"overworld_player", &"player"]:
		for node in tree.get_nodes_in_group(group_name):
			if node is Node3D and node.has_method("apply_camera_shake"):
				var dist := (node as Node3D).global_position.distance_to(center)
				if dist < 18.0:
					node.apply_camera_shake(lerpf(0.55, 0.2, dist / 18.0))
