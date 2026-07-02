extends RefCounted
class_name KnifeThrowTrailFX

const BEAM_WIDTH := 0.038
const FADE_DURATION := 0.42
const TRAIL_COLOR := Color(1.0, 0.62, 0.62, 0.88)
const TRAIL_EMISSION := Color(1.0, 0.48, 0.48, 1.0)
const EMISSION_ENERGY := 2.8
const MIN_SEGMENT_LENGTH := 0.04


static func spawn_segment(parent: Node, from: Vector3, to: Vector3) -> void:
	if parent == null:
		return

	var delta := to - from
	var length := delta.length()
	if length < MIN_SEGMENT_LENGTH:
		return

	var direction := delta / length
	var beam := MeshInstance3D.new()
	beam.name = "KnifeTrailSegment"
	var box := BoxMesh.new()
	box.size = Vector3(BEAM_WIDTH, BEAM_WIDTH, length)
	beam.mesh = box

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = TRAIL_COLOR
	material.emission_enabled = true
	material.emission = TRAIL_EMISSION
	material.emission_energy_multiplier = EMISSION_ENERGY
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	beam.material_override = material

	parent.add_child(beam)

	var up := Vector3.UP
	if absf(direction.dot(up)) > 0.95:
		up = Vector3.FORWARD
	beam.global_basis = Basis.looking_at(direction, up)
	beam.global_position = from + direction * (length * 0.5)

	var tween := beam.create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(material, "albedo_color:a", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "emission_energy_multiplier", 0.0, FADE_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(beam.queue_free)


static func spawn_marker(parent: Node, global_position: Vector3) -> void:
	if parent == null:
		return

	var dot := MeshInstance3D.new()
	dot.name = "KnifeTrailMarker"
	var mesh := SphereMesh.new()
	mesh.radius = 0.05
	mesh.height = 0.1
	dot.mesh = mesh

	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(1.0, 0.7, 0.7, 0.95)
	material.emission_enabled = true
	material.emission = Color(1.0, 0.55, 0.55, 1.0)
	material.emission_energy_multiplier = 3.2
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dot.material_override = material

	parent.add_child(dot)
	dot.global_position = global_position

	var tween := dot.create_tween()
	tween.set_ignore_time_scale(true)
	tween.set_parallel(true)
	tween.tween_property(dot, "scale", Vector3.ONE * 1.8, FADE_DURATION * 0.65)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(material, "albedo_color:a", 0.0, FADE_DURATION * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(material, "emission_energy_multiplier", 0.0, FADE_DURATION * 0.65)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.finished.connect(dot.queue_free)
