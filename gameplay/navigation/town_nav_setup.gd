extends Node
class_name TownNavSetup

signal bake_finished

const BAKE_GROUP := &"town_navigation"
const RuinsGRSnapScript := preload("res://gameplay/world/ruins_gr_snap.gd")

var _region: NavigationRegion3D
var _baked := false


func _ready() -> void:
	add_to_group(BAKE_GROUP)


func is_baked() -> bool:
	return _baked


static func is_navigation_ready(tree: SceneTree) -> bool:
	for node in tree.get_nodes_in_group(BAKE_GROUP):
		if node is TownNavSetup and (node as TownNavSetup).is_baked():
			return true
	return false


func configure_and_bake(geometry_root: Node, bake_center: Vector3, bake_extents: Vector3) -> void:
	if geometry_root == null:
		return

	_region = NavigationRegion3D.new()
	_region.name = "TownNavigationRegion"
	add_child(_region)

	var nav_mesh := NavigationMesh.new()
	nav_mesh.agent_radius = 0.42
	nav_mesh.agent_height = 2.0
	nav_mesh.agent_max_climb = 0.45
	nav_mesh.agent_max_slope = 50.0
	nav_mesh.cell_size = 0.3
	nav_mesh.cell_height = 0.15
	nav_mesh.edge_max_length = 12.0
	nav_mesh.filter_low_hanging_obstacles = true
	nav_mesh.filter_ledge_spans = true
	nav_mesh.filter_walkable_low_height_spans = true
	nav_mesh.geometry_collision_mask = 1
	nav_mesh.filter_baking_aabb = AABB(-bake_extents * 0.5, bake_extents)
	nav_mesh.filter_baking_aabb_offset = bake_center

	_region.navigation_mesh = nav_mesh
	_region.use_edge_connections = false

	var geometry := NavigationMeshSourceGeometryData3D.new()
	NavigationServer3D.parse_source_geometry_data(nav_mesh, geometry, geometry_root)
	if not geometry.has_data():
		push_warning("TownNavSetup: no navigation source geometry found.")
		return

	var setup_ref := self
	var mesh_template := nav_mesh.duplicate()
	WorkerThreadPool.add_task(
		func() -> void:
			var baked_mesh: NavigationMesh = mesh_template.duplicate()
			NavigationServer3D.bake_from_source_geometry_data(baked_mesh, geometry)
			setup_ref._apply_baked_mesh.call_deferred(baked_mesh),
		false,
		"TownNavSetupBake"
	)


func _apply_baked_mesh(nav_mesh: NavigationMesh) -> void:
	if _region == null:
		return
	_region.navigation_mesh = nav_mesh
	_baked = true
	bake_finished.emit()


func add_ruins_stair_nav_links(layout_root: Node3D) -> void:
	if _region == null or layout_root == null:
		return
	var floor_root := layout_root.get_node_or_null("Floor") as Node3D
	var structures_root := layout_root.get_node_or_null("Structures") as Node3D
	if floor_root == null or structures_root == null:
		return
	for stair in RuinsGRSnapScript.get_stairs_with_landings(floor_root, structures_root):
		var link := NavigationLink3D.new()
		link.name = "StairNavLink_%s" % stair.name
		link.global_transform = stair.global_transform
		link.start_position = Vector3(
			0.0,
			0.0,
			RuinsGRSnapScript.STAIRS_XL_BOTTOM_Z
		)
		link.end_position = Vector3(
			0.0,
			RuinsGRSnapScript.STAIRS_XL_RISE,
			RuinsGRSnapScript.STAIRS_XL_TOP_Z
		)
		link.bidirectional = true
		link.travel_cost = 1.0
		_region.add_child(link)
