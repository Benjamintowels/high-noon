class_name FloorTileCollision
extends RefCounted

## Flat box colliders for RuinsGR floor tiles — matches BlocksScenes presets so
## decorative moss geometry is not part of walkable physics.

const COLLISION_ROOT_NAME := "FloorTileCollision"

const BLOCK_MD_SIZE := Vector3(6.40393, 1.60718, 6.39819)
const BLOCK_MD_OFFSET := Vector3(-0.000183105, 0.797241, 0.0032959)
const BLOCK_MD_TOP_Y := 1.600831

const SLAB_THICKNESS := 0.25
const BLOCK_MD_SLAB_SIZE := Vector3(BLOCK_MD_SIZE.x, SLAB_THICKNESS, BLOCK_MD_SIZE.z)
const BLOCK_MD_SLAB_OFFSET := Vector3(
	BLOCK_MD_OFFSET.x,
	BLOCK_MD_TOP_Y - SLAB_THICKNESS * 0.5,
	BLOCK_MD_OFFSET.z,
)


static func apply_to(root: Node) -> void:
	if root == null or not root is Node3D:
		return
	if root.get_node_or_null(COLLISION_ROOT_NAME) != null:
		return

	var collision_root := Node3D.new()
	collision_root.name = COLLISION_ROOT_NAME
	root.add_child(collision_root)

	for child in root.get_children():
		if child == collision_root:
			continue
		if not child is Node3D:
			continue
		if _should_skip_tile(child):
			continue
		_add_tile_body(collision_root, child as Node3D)


static func _should_skip_tile(node: Node) -> bool:
	return node.name in [COLLISION_ROOT_NAME, "TerrainCollision"]


static func _add_tile_body(collision_root: Node3D, tile: Node3D) -> void:
	_disable_embedded_tile_collision(tile)

	var body := StaticBody3D.new()
	body.name = "GroundBody"
	body.collision_layer = 1
	collision_root.add_child(body)
	body.global_transform = tile.global_transform

	var shape := BoxShape3D.new()
	shape.size = BLOCK_MD_SLAB_SIZE

	var collision := CollisionShape3D.new()
	collision.shape = shape
	collision.transform = Transform3D(Basis.IDENTITY, BLOCK_MD_SLAB_OFFSET)
	body.add_child(collision)


static func _disable_embedded_tile_collision(tile: Node3D) -> void:
	if tile is StaticBody3D:
		var body := tile as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0
		for shape_node in body.get_children():
			if shape_node is CollisionShape3D:
				(shape_node as CollisionShape3D).disabled = true
			elif shape_node is CollisionPolygon3D:
				(shape_node as CollisionPolygon3D).disabled = true
		return

	for child in tile.get_children():
		if child is StaticBody3D:
			var child_body := child as StaticBody3D
			child_body.collision_layer = 0
			child_body.collision_mask = 0
			for shape_node in child_body.get_children():
				if shape_node is CollisionShape3D:
					(shape_node as CollisionShape3D).disabled = true
				elif shape_node is CollisionPolygon3D:
					(shape_node as CollisionPolygon3D).disabled = true
		elif child is Node3D:
			_disable_embedded_tile_collision(child as Node3D)
