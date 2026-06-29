extends RefCounted
class_name FactionBrandUtils

const FactionIds := preload("res://gameplay/faction/faction_ids.gd")


static func get_brand_color(faction_id: StringName) -> Color:
	match faction_id:
		FactionIds.TOWNSPEOPLE:
			return Color(0.15, 0.35, 0.75)
		FactionIds.BANDITS:
			return Color(0.72, 0.18, 0.14)
		_:
			return Color(0.35, 0.35, 0.35)


static func apply_brand_to_cow(visual: Node3D, faction_id: StringName) -> void:
	if visual == null or faction_id == &"":
		return

	var brand_root := Node3D.new()
	brand_root.name = "FactionBrand"
	visual.add_child(brand_root)

	var color := get_brand_color(faction_id)
	var plate := _make_box(Vector3(0.28, 0.28, 0.04), Vector3(-0.49, 0.66, 0.0), color)
	brand_root.add_child(plate)

	match faction_id:
		FactionIds.TOWNSPEOPLE:
			var bar_h := _make_box(Vector3(0.04, 0.18, 0.05), Vector3(-0.49, 0.66, 0.0), Color(0.98, 0.98, 0.96))
			var bar_v := _make_box(Vector3(0.18, 0.04, 0.05), Vector3(-0.49, 0.66, 0.0), Color(0.98, 0.98, 0.96))
			brand_root.add_child(bar_h)
			brand_root.add_child(bar_v)
		FactionIds.BANDITS:
			var slash := _make_box(Vector3(0.04, 0.2, 0.05), Vector3(-0.49, 0.66, 0.0), Color(0.98, 0.98, 0.96))
			slash.rotation.z = deg_to_rad(35.0)
			brand_root.add_child(slash)
		_:
			var dot := _make_box(Vector3(0.08, 0.08, 0.05), Vector3(-0.49, 0.66, 0.0), Color(0.98, 0.98, 0.96))
			brand_root.add_child(dot)


static func _make_box(size: Vector3, local_pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = local_pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.82
	mesh_instance.material_override = mat
	return mesh_instance
