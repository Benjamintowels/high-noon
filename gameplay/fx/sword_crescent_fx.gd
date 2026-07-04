extends RefCounted
class_name SwordCrescentFX

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const DURATION := 0.28
const SPIN_DURATION := 0.32
const ARC_DEGREES := 108.0
const SPIN_ARC_DEGREES := 180.0
const ARC_SEGMENTS := 14
const SPIN_ARC_SEGMENTS := 16
const INNER_RADIUS_SCALE := 0.55
const OUTER_RADIUS_SCALE := 1.0
const SPIN_INNER_RADIUS_SCALE := 0.48
const SPIN_OUTER_RADIUS_SCALE := 1.08
const HEIGHT_OFFSET := 1.05


static func spawn_for_hit(
	attacker: Node3D,
	_hit_position: Vector3,
	direction: Vector3,
	strike_range: float
) -> void:
	if attacker == null:
		return
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	flat_dir = flat_dir.normalized()

	var origin := attacker.global_position + Vector3(0.0, HEIGHT_OFFSET, 0.0)
	var parent := ImpactFXScript.parent_for(attacker)
	_spawn_arc(parent, origin, flat_dir, strike_range)


static func spawn_preview(attacker: Node3D, direction: Vector3, strike_range: float) -> void:
	if attacker == null:
		return
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = -attacker.global_transform.basis.z
		flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	flat_dir = flat_dir.normalized()
	var origin := attacker.global_position + Vector3(0.0, HEIGHT_OFFSET, 0.0)
	var parent := ImpactFXScript.parent_for(attacker)
	_spawn_arc(parent, origin, flat_dir, strike_range)


static func spawn_vertical_preview(attacker: Node3D, direction: Vector3, strike_range: float) -> void:
	if attacker == null:
		return
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = -attacker.global_transform.basis.z
		flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	flat_dir = flat_dir.normalized()
	var origin := attacker.global_position + Vector3(0.0, HEIGHT_OFFSET, 0.0)
	var parent := ImpactFXScript.parent_for(attacker)
	_spawn_vertical_arc(parent, origin, flat_dir, strike_range)


static func spawn_spin_preview(attacker: Node3D, direction: Vector3, strike_range: float) -> void:
	if attacker == null:
		return
	var flat_dir := Vector3(direction.x, 0.0, direction.z)
	if flat_dir.length_squared() < 0.0001:
		flat_dir = -attacker.global_transform.basis.z
		flat_dir.y = 0.0
	if flat_dir.length_squared() < 0.0001:
		flat_dir = Vector3.FORWARD
	flat_dir = flat_dir.normalized()
	var origin := attacker.global_position + Vector3(0.0, HEIGHT_OFFSET, 0.0)
	var parent := ImpactFXScript.parent_for(attacker)
	_spawn_spin_arc(parent, origin, flat_dir, strike_range)


static func _spawn_arc(parent: Node, origin: Vector3, direction: Vector3, strike_range: float) -> void:
	var fx_root := Node3D.new()
	fx_root.name = "SwordCrescentFX"
	parent.add_child(fx_root)
	fx_root.global_position = origin

	var basis := Basis.looking_at(direction, Vector3.UP)
	fx_root.global_transform = Transform3D(basis, origin)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_crescent_mesh(strike_range, ARC_DEGREES, ARC_SEGMENTS, INNER_RADIUS_SCALE, OUTER_RADIUS_SCALE, false)
	mesh_instance.material_override = _build_material()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx_root.add_child(mesh_instance)

	mesh_instance.scale = Vector3(0.65, 0.65, 0.65)
	var tween := fx_root.create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.15, 1.15, 1.15), DURATION * 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "scale", Vector3(0.2, 0.2, 0.2), DURATION * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(fx_root.queue_free)


static func _spawn_vertical_arc(parent: Node, origin: Vector3, direction: Vector3, strike_range: float) -> void:
	var fx_root := Node3D.new()
	fx_root.name = "SwordVerticalCrescentFX"
	parent.add_child(fx_root)
	fx_root.global_position = origin

	var basis := Basis.looking_at(direction, Vector3.UP)
	fx_root.global_transform = Transform3D(basis, origin)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_crescent_mesh(
		strike_range,
		ARC_DEGREES,
		ARC_SEGMENTS,
		INNER_RADIUS_SCALE,
		OUTER_RADIUS_SCALE,
		false,
		true
	)
	mesh_instance.material_override = _build_material()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx_root.add_child(mesh_instance)

	mesh_instance.scale = Vector3(0.65, 0.65, 0.65)
	var tween := fx_root.create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.15, 1.15, 1.15), DURATION * 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "scale", Vector3(0.2, 0.2, 0.2), DURATION * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(fx_root.queue_free)


static func _spawn_spin_arc(parent: Node, origin: Vector3, direction: Vector3, strike_range: float) -> void:
	var fx_root := Node3D.new()
	fx_root.name = "SwordSpinArcFX"
	parent.add_child(fx_root)
	fx_root.global_position = origin

	var basis := Basis.looking_at(direction, Vector3.UP)
	fx_root.global_transform = Transform3D(basis, origin)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_crescent_mesh(
		strike_range,
		SPIN_ARC_DEGREES,
		SPIN_ARC_SEGMENTS,
		SPIN_INNER_RADIUS_SCALE,
		SPIN_OUTER_RADIUS_SCALE,
		true
	)
	mesh_instance.material_override = _build_spin_material()
	mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx_root.add_child(mesh_instance)

	mesh_instance.scale = Vector3(0.55, 0.55, 0.55)
	var tween := fx_root.create_tween()
	tween.tween_property(mesh_instance, "scale", Vector3(1.22, 1.22, 1.22), SPIN_DURATION * 0.4)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(mesh_instance, "scale", Vector3(0.18, 0.18, 0.18), SPIN_DURATION * 0.6)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_callback(fx_root.queue_free)


static func _build_crescent_mesh(
	strike_range: float,
	arc_degrees: float,
	segments: int,
	inner_scale: float,
	outer_scale: float,
	spin_colors: bool,
	vertical: bool = false
) -> ArrayMesh:
	var inner_radius := strike_range * inner_scale
	var outer_radius := strike_range * outer_scale
	var half_arc := deg_to_rad(arc_degrees * 0.5)
	var start_angle := -half_arc
	var end_angle := half_arc

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	for segment_idx in segments + 1:
		var t := float(segment_idx) / float(segments)
		var angle := lerpf(start_angle, end_angle, t)
		var dir := (
			Vector3(sin(angle), -cos(angle), 0.0)
			if vertical
			else Vector3(sin(angle), 0.0, -cos(angle))
		)
		vertices.append(dir * inner_radius)
		vertices.append(dir * outer_radius)
		var normal := Vector3.BACK if vertical else Vector3.UP
		normals.append(normal)
		normals.append(normal)
		if spin_colors:
			var inner_color := Color(1.0, 0.88, 0.55, 0.92).lerp(Color(0.98, 0.72, 0.38, 0.82), t)
			var outer_color := Color(1.0, 0.95, 0.72, 0.78).lerp(Color(1.0, 0.82, 0.45, 0.65), t)
			colors.append(inner_color)
			colors.append(outer_color)
		else:
			var color := Color(0.88, 0.95, 1.0, 0.95).lerp(Color(0.72, 0.86, 1.0, 0.85), t)
			colors.append(color)
			colors.append(Color(1.0, 1.0, 1.0, 0.75))

	for segment_idx in segments:
		var base_idx := segment_idx * 2
		indices.append_array([
			base_idx,
			base_idx + 1,
			base_idx + 2,
			base_idx + 1,
			base_idx + 3,
			base_idx + 2,
		])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _build_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	return material


static func _build_spin_material() -> StandardMaterial3D:
	var material := _build_material()
	material.emission_enabled = true
	material.emission = Color(1.0, 0.82, 0.42)
	material.emission_energy_multiplier = 0.35
	return material
