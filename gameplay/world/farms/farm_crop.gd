extends Node3D

const CropBurstFXScript := preload("res://gameplay/world/farms/crop_burst_fx.gd")

const PROXIMITY_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
]

const REGROW_TIME := 40.0

@export var crop_texture: Texture2D
@export var crop_pixel_size: float = 0.0075
@export var crop_yaw: float = 0.0

@export var sway_radius := 0.9
@export var max_sway_deg := 26.0
@export var sway_speed := 9.0

var _destroyed := false
var _regrow_timer := 0.0
var _current_sway := Vector2.ZERO

@onready var _pivot: Node3D = $Pivot
@onready var _sprite: Sprite3D = $Pivot/Sprite
@onready var _hit_area: Area3D = $HitArea
@onready var _hit_shape: CollisionShape3D = $HitArea/CollisionShape3D


func _ready() -> void:
	add_to_group("farm_crop")
	rotation.y = crop_yaw
	_apply_visual()


func setup(texture: Texture2D, pixel_size: float, yaw: float) -> void:
	crop_texture = texture
	crop_pixel_size = pixel_size
	crop_yaw = yaw
	rotation.y = yaw
	if is_node_ready():
		_apply_visual()


func _apply_visual() -> void:
	if crop_texture == null or _sprite == null:
		return

	_sprite.texture = crop_texture
	_sprite.pixel_size = crop_pixel_size
	_sprite.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	_sprite.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_sprite.double_sided = true
	_sprite.centered = true
	_sprite.transparent = true
	_sprite.offset = Vector2.ZERO

	var world_height := crop_texture.get_height() * crop_pixel_size
	_sprite.position.y = world_height * 0.5
	_update_hit_volume(world_height)


func _update_hit_volume(world_height: float) -> void:
	if _hit_shape == null:
		return

	var shape := CylinderShape3D.new()
	shape.height = maxf(world_height * 0.85, 0.4)
	shape.radius = 0.18
	_hit_shape.shape = shape
	_hit_shape.position.y = shape.height * 0.5


func _process(delta: float) -> void:
	if _destroyed:
		_regrow_timer -= delta
		if _regrow_timer <= 0.0:
			_regrow()
		return

	var push := Vector2.ZERO
	var mover_pos := _find_nearest_mover()
	if mover_pos != null:
		var offset := Vector2(global_position.x - mover_pos.x, global_position.z - mover_pos.z)
		var dist := offset.length()
		if dist < sway_radius and dist > 0.001:
			var strength := 1.0 - (dist / sway_radius)
			push = offset.normalized() * strength

	_current_sway = _current_sway.lerp(push, sway_speed * delta)
	_pivot.rotation.x = deg_to_rad(-_current_sway.y * max_sway_deg)
	_pivot.rotation.z = deg_to_rad(_current_sway.x * max_sway_deg)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _destroyed:
		return
	_destroy_from_hit(hit_info)


func receive_bullet_hit(hit_info: Dictionary) -> void:
	apply_bullet_hit(hit_info)


func _destroy_from_hit(hit_info: Dictionary) -> void:
	_destroyed = true
	_regrow_timer = REGROW_TIME
	_hit_area.set_deferred("monitorable", false)
	_hit_area.set_deferred("collision_layer", 0)

	var hit_position: Vector3 = hit_info.get("position", global_position)
	var direction: Vector3 = hit_info.get("direction", Vector3.UP)

	var fx_parent := get_tree().current_scene
	if fx_parent == null:
		fx_parent = get_parent()
	CropBurstFXScript.spawn(fx_parent, hit_position, direction)

	_pivot.visible = false


func _regrow() -> void:
	_destroyed = false
	_regrow_timer = 0.0
	_hit_area.monitorable = true
	_hit_area.collision_layer = 1
	_pivot.visible = true
	_current_sway = Vector2.ZERO
	_pivot.rotation = Vector3.ZERO


func _find_nearest_mover() -> Vector3:
	var tree := get_tree()
	if tree == null:
		return Vector3.INF

	var best_dist_sq := sway_radius * sway_radius
	var best_pos := Vector3.INF

	for group_name in PROXIMITY_GROUPS:
		for node in tree.get_nodes_in_group(group_name):
			if node == null or not is_instance_valid(node):
				continue
			if not node is Node3D:
				continue
			var node3d := node as Node3D
			var offset := node3d.global_position - global_position
			offset.y = 0.0
			var dist_sq := offset.length_squared()
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best_pos = node3d.global_position

	if best_pos == Vector3.INF:
		return Vector3.INF
	return best_pos
