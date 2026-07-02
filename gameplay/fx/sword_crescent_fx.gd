extends RefCounted
class_name SwordCrescentFX

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const DURATION := 0.28
const ARC_DEGREES := 108.0
const ARC_SEGMENTS := 14
const INNER_RADIUS_SCALE := 0.55
const OUTER_RADIUS_SCALE := 1.0
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


static func _spawn_arc(parent: Node, origin: Vector3, direction: Vector3, strike_range: float) -> void:
	var fx_root := Node3D.new()
	fx_root.name = "SwordCrescentFX"
	parent.add_child(fx_root)
	fx_root.global_position = origin

	var basis := Basis.looking_at(direction, Vector3.UP)
	fx_root.global_transform = Transform3D(basis, origin)

	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = _build_crescent_mesh(strike_range)
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


static func _build_crescent_mesh(strike_range: float) -> ArrayMesh:
	var inner_radius := strike_range * INNER_RADIUS_SCALE
	var outer_radius := strike_range * OUTER_RADIUS_SCALE
	var half_arc := deg_to_rad(ARC_DEGREES * 0.5)
	var start_angle := -half_arc
	var end_angle := half_arc

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	for segment_idx in ARC_SEGMENTS + 1:
		var t := float(segment_idx) / float(ARC_SEGMENTS)
		var angle := lerpf(start_angle, end_angle, t)
		var dir := Vector3(sin(angle), 0.0, -cos(angle))
		vertices.append(dir * inner_radius)
		vertices.append(dir * outer_radius)
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
		var color_t := t
		var color := Color(0.88, 0.95, 1.0, 0.95).lerp(Color(0.72, 0.86, 1.0, 0.85), color_t)
		colors.append(color)
		colors.append(Color(1.0, 1.0, 1.0, 0.75))

	for segment_idx in ARC_SEGMENTS:
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
