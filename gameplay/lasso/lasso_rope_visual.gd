extends MeshInstance3D
class_name LassoRopeVisual

const ROPE_COLOR := Color(0.62, 0.45, 0.28, 1.0)
const SEGMENTS := 14
const SAG_FACTOR := 0.09

var _material: StandardMaterial3D


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_material.albedo_color = ROPE_COLOR
	_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = _material
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func update_rope(anchor: Vector3, target: Vector3, slack: bool = false) -> void:
	var local_anchor := to_local(anchor)
	var local_target := to_local(target)
	var span := local_anchor.distance_to(local_target)
	var sag := span * (0.22 if slack else 0.09)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()

	for i in SEGMENTS + 1:
		var t := float(i) / float(SEGMENTS)
		var pos := local_anchor.lerp(local_target, t)
		pos.y -= sin(t * PI) * sag
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
