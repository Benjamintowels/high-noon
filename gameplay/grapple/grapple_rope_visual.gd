extends MeshInstance3D
class_name GrappleRopeVisual

const ROPE_COLOR := Color(0.48, 0.42, 0.34, 1.0)
const SEGMENTS := 22

var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = ROPE_COLOR
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func update_rope(
	anchor: Vector3,
	hook_point: Vector3,
	slack_amount: float = 0.0,
	swing_angle: float = 0.0
) -> void:
	var local_anchor := to_local(anchor)
	var local_hook := to_local(hook_point)
	var span := local_anchor.distance_to(local_hook)
	var sag := span * clampf(0.06 + slack_amount * 0.38, 0.06, 0.55)
	var curl := slack_amount * 0.65

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in SEGMENTS + 1:
		var t := float(i) / float(SEGMENTS)
		var pos := local_anchor.lerp(local_hook, t)
		var wave := sin(t * PI)
		pos.y -= wave * sag
		var side := sin(t * PI * 2.4 + swing_angle) * curl * span * 0.04
		pos.x += side
		vertices.append(pos)
		normals.append(Vector3.UP)
		uvs.append(Vector2(t, 0.0))
		if i > 0:
			var base := i - 1
			indices.append_array([base, base + 1])

	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = indices

	var array_mesh := ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	mesh = array_mesh
