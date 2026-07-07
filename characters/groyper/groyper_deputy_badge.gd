extends Node
class_name GroyperDeputyBadge

const BADGE_MOUNT_SCENE := preload("res://characters/groyper/badge_mount.tscn")

var _skeleton: Skeleton3D
var _mount: BoneAttachment3D
var _badge_visual: Node3D


func bind_skeleton(skeleton: Skeleton3D) -> void:
	if skeleton == null:
		return
	_skeleton = skeleton
	_ensure_mount()
	refresh_badge_visual()


func refresh_badge_visual() -> void:
	if _skeleton == null:
		return
	_ensure_mount()
	if _mount == null:
		return

	var should_show: bool = PlayerInventory.has_deputy_badge
	if _badge_visual != null and is_instance_valid(_badge_visual):
		_badge_visual.visible = should_show
		return

	if not should_show:
		return

	_badge_visual = _build_star_visual()
	var offset := _mount.get_node_or_null("BadgeOffset") as Node3D
	if offset != null:
		offset.add_child(_badge_visual)
	else:
		_mount.add_child(_badge_visual)


func _ensure_mount() -> void:
	if _skeleton == null:
		return
	_mount = _skeleton.get_node_or_null("BadgeMount") as BoneAttachment3D
	if _mount != null:
		return

	var mount: BoneAttachment3D = BADGE_MOUNT_SCENE.instantiate()
	_skeleton.add_child(mount)
	_mount = mount


func _build_star_visual() -> Node3D:
	var root := Node3D.new()
	root.name = "DeputyBadge"

	for i in 5:
		var point := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, 0.04, 0.32)
		point.mesh = mesh
		var material := StandardMaterial3D.new()
		material.albedo_color = Color(0.92, 0.78, 0.18, 1.0)
		material.metallic = 0.65
		material.roughness = 0.28
		point.material_override = material
		var angle := (float(i) / 5.0) * TAU - PI * 0.5
		point.rotation.y = angle
		point.position = Vector3(cos(angle), 0.0, sin(angle)) * 0.22
		root.add_child(point)

	var center := MeshInstance3D.new()
	var center_mesh := CylinderMesh.new()
	center_mesh.top_radius = 0.1
	center_mesh.bottom_radius = 0.1
	center_mesh.height = 0.05
	center.mesh = center_mesh
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.72, 0.52, 0.12, 1.0)
	center_mat.metallic = 0.5
	center.material_override = center_mat
	root.add_child(center)

	return root
