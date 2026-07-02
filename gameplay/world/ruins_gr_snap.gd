class_name RuinsGRSnap
extends RefCounted

## Grid + stair landing math for RuinsGR cave layout pieces.

const STAIR_RAMP_COLLISION := preload("res://gameplay/world/stair_ramp_collision.gd")

const TILE_SIZE := 6.6

const STAIRS_XL_RISE := 2.2
const STAIRS_XL_BOTTOM_Z := 1.4
const STAIRS_XL_TOP_Z := -1.4

const BLOCK_MD_TOP_Y := 1.600831
const BLOCK_MD_HALF_Z := 6.39819 * 0.5

const STAIRS_XL_LINK_LOCAL := Vector3(
	0.0,
	STAIRS_XL_RISE,
	STAIRS_XL_TOP_Z - STAIRS_XL_BOTTOM_Z,
)
const LANDING_TILE_OFFSET_LOCAL := Vector3(
	0.0,
	STAIRS_XL_RISE - BLOCK_MD_TOP_Y,
	STAIRS_XL_TOP_Z - BLOCK_MD_HALF_Z,
)

const LANDING_TILE_XZ_RADIUS := 4.5
const LANDING_TILE_Y_TOLERANCE := 1.25
const CHAIN_BOTTOM_MATCH_RADIUS := 1.5

## Pull the ramp top back along the climb so a flat landing owns the top steps.
## Standard third-person approach: slope ends below the deck; flat collider handles the lip.
const LANDING_RAMP_TOP_TRIM := 1.0


static func apply_to_layout(layout_root: Node3D) -> void:
	if layout_root == null:
		return
	var structures := layout_root.get_node_or_null("Structures") as Node3D
	var floor_root := layout_root.get_node_or_null("Floor") as Node3D
	if structures != null:
		_snap_stair_chain(structures)
	if floor_root != null and structures != null:
		_snap_floor_landings(floor_root, structures)


static func get_stairs_with_landings(floor_root: Node3D, structures_root: Node3D) -> Array[Node3D]:
	var landed: Array[Node3D] = []
	if floor_root == null or structures_root == null:
		return landed
	for stair in _collect_stairs(structures_root):
		if stair_has_landing(stair, floor_root):
			landed.append(stair)
	return landed


static func stair_has_landing(stair: Node3D, floor_root: Node3D) -> bool:
	if stair == null or floor_root == null:
		return false
	var top := get_stair_top_world(stair)
	for child in floor_root.get_children():
		if child is Node3D and _is_floor_tile(child) and _tile_near_stair_top(child as Node3D, top, stair):
			return true
	return false


static func get_stair_top_world(stair: Node3D) -> Vector3:
	return stair.global_transform * Vector3(0.0, STAIRS_XL_RISE, STAIRS_XL_TOP_Z)


static func get_stair_bottom_world(stair: Node3D) -> Vector3:
	return stair.global_transform * Vector3(0.0, 0.0, STAIRS_XL_BOTTOM_Z)


static func landing_ramp_config(has_landing: bool) -> Dictionary:
	if has_landing:
		return {
			"bottom_overlap": 0.12,
			"top_overlap": 0.0,
			"top_trim": LANDING_RAMP_TOP_TRIM,
		}
	return {"bottom_overlap": 0.12, "top_overlap": 0.12, "top_trim": 0.0}


## Tiles closest to each stair top — use open-edge slabs so descent is not blocked.
static func get_landing_connector_tiles(
	floor_root: Node3D,
	structures_root: Node3D,
) -> Dictionary:
	var connectors: Dictionary = {}
	if floor_root == null or structures_root == null:
		return connectors

	for stair in _collect_stairs(structures_root):
		if not stair_has_landing(stair, floor_root):
			continue
		var top_point := get_stair_top_world(stair)
		var tiles := _collect_landing_candidates(floor_root, top_point, stair)
		if tiles.is_empty():
			continue
		connectors[_closest_tile_to_point(tiles, top_point)] = stair
	return connectors


static func _snap_stair_chain(structures_root: Node3D) -> void:
	var stairs := _collect_stairs(structures_root)
	if stairs.size() < 2:
		return

	var ordered := _order_stairs_for_chain(stairs)
	for index in range(1, ordered.size()):
		_snap_stair_to_previous(ordered[index - 1], ordered[index])


static func _snap_stair_to_previous(prev: Node3D, next: Node3D) -> void:
	var basis := prev.global_transform.basis
	next.global_transform = Transform3D(basis, prev.global_transform.origin + basis * STAIRS_XL_LINK_LOCAL)


static func _snap_floor_landings(floor_root: Node3D, structures_root: Node3D) -> void:
	var stairs := _collect_stairs(structures_root)
	if stairs.is_empty():
		return

	var top_stair := _get_highest_stair(stairs)
	var top_point := get_stair_top_world(top_stair)
	var landing_tiles := _collect_landing_candidates(floor_root, top_point, top_stair)
	if landing_tiles.is_empty():
		return

	var primary := _closest_tile_to_point(landing_tiles, top_point)
	_snap_tile_to_stair_top(primary, top_stair)

	var climb_axis := -(top_stair.global_transform.basis.z).normalized()
	for tile in landing_tiles:
		if tile == primary:
			continue
		var along := (tile.global_position - primary.global_position).dot(climb_axis)
		var steps := int(roundf(along / TILE_SIZE))
		tile.global_transform = Transform3D(
			primary.global_transform.basis,
			primary.global_position + climb_axis * (TILE_SIZE * float(steps)),
		)


static func _snap_tile_to_stair_top(tile: Node3D, stair: Node3D) -> void:
	var basis := stair.global_transform.basis
	tile.global_transform = Transform3D(basis, stair.global_transform.origin + basis * LANDING_TILE_OFFSET_LOCAL)


static func _collect_stairs(structures_root: Node3D) -> Array[Node3D]:
	var stairs: Array[Node3D] = []
	for child in structures_root.get_children():
		if child is Node3D and STAIR_RAMP_COLLISION.is_stair_node(child):
			stairs.append(child as Node3D)
	return stairs


static func _order_stairs_for_chain(stairs: Array[Node3D]) -> Array[Node3D]:
	if stairs.is_empty():
		return stairs

	var remaining: Array[Node3D] = []
	remaining.assign(stairs)
	var ordered: Array[Node3D] = [_find_chain_start(remaining)]
	remaining.erase(ordered[0])

	while not remaining.is_empty():
		var tail_top := get_stair_top_world(ordered.back())
		var best_index := 0
		var best_distance := INF
		for index in range(remaining.size()):
			var distance := get_stair_bottom_world(remaining[index]).distance_to(tail_top)
			if distance < best_distance:
				best_distance = distance
				best_index = index
		ordered.append(remaining[best_index])
		remaining.remove_at(best_index)

	return ordered


static func _find_chain_start(stairs: Array[Node3D]) -> Node3D:
	var best := stairs[0]
	var best_score := INF
	for stair in stairs:
		var bottom := get_stair_bottom_world(stair)
		var matches := 0
		for other in stairs:
			if other == stair:
				continue
			if get_stair_top_world(other).distance_to(bottom) <= CHAIN_BOTTOM_MATCH_RADIUS:
				matches += 1
		var score := bottom.y + float(matches) * 100.0
		if score < best_score:
			best_score = score
			best = stair
	return best


static func _get_highest_stair(stairs: Array[Node3D]) -> Node3D:
	var best := stairs[0]
	var best_y := get_stair_top_world(best).y
	for stair in stairs:
		var top_y := get_stair_top_world(stair).y
		if top_y > best_y:
			best_y = top_y
			best = stair
	return best


static func _collect_landing_candidates(
	floor_root: Node3D,
	top_point: Vector3,
	stair: Node3D,
) -> Array[Node3D]:
	var tiles: Array[Node3D] = []
	for child in floor_root.get_children():
		if child is Node3D and _is_floor_tile(child) and _tile_near_stair_top(child as Node3D, top_point, stair):
			tiles.append(child as Node3D)
	return tiles


static func _is_floor_tile(node: Node) -> bool:
	if node.name in ["FloorTileCollision", "TerrainCollision"]:
		return false
	var name_lower := String(node.name).to_lower()
	return name_lower.contains("block_")


static func _tile_near_stair_top(tile: Node3D, top_point: Vector3, stair: Node3D) -> bool:
	var local := stair.global_transform.affine_inverse() * tile.global_position
	if absf(local.x) > LANDING_TILE_XZ_RADIUS:
		return false
	if local.z > STAIRS_XL_TOP_Z + 0.5:
		return false
	var xz_distance := Vector2(
		tile.global_position.x - top_point.x,
		tile.global_position.z - top_point.z,
	).length()
	return xz_distance <= TILE_SIZE * 3.5


static func _closest_tile_to_point(tiles: Array[Node3D], point: Vector3) -> Node3D:
	var best := tiles[0]
	var best_distance := best.global_position.distance_to(point)
	for tile in tiles:
		var distance := tile.global_position.distance_to(point)
		if distance < best_distance:
			best_distance = distance
			best = tile
	return best
