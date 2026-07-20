extends Node3D

## Red ground aim telegraph as flat 2D textures (Decals), feet-level, parallel
## to the ground. Used for gun / AOE warnings — not for melee (melee uses AlertSymbolFX).
## Load via preload("res://gameplay/fx/attack_telegraph.gd").

signal filled
signal finished

const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const _SELF := preload("res://gameplay/fx/attack_telegraph.gd")

const FILL_DURATION := 1.0
## Guns fill a bit slower so the dodge window is readable.
const GUN_FILL_DURATION := 1.35
const GUN_LOCK_COMMIT := 0.25
const DEFAULT_GUN_RADIUS := 1.05
const GROUND_RAY_UP := 2.5
const GROUND_RAY_DOWN := 8.0
## Sit right on the floor so the decal reads as feet-level.
const GROUND_Y_PAD := 0.02
const DECAL_HEIGHT := 0.45

static var _ring_texture: Texture2D
static var _fill_texture: Texture2D

var _radius := DEFAULT_GUN_RADIUS
var _duration := FILL_DURATION
var _elapsed := 0.0
var _filled := false
var _locked := true
var _outline: Decal
var _fill: Decal
var _closing := false


static func begin(
	source: Node,
	world_pos: Vector3,
	radius: float = DEFAULT_GUN_RADIUS,
	duration: float = FILL_DURATION
) -> Node3D:
	var parent := ImpactFXScript.parent_for(source)
	if parent == null and source != null and source.is_inside_tree():
		parent = source.get_tree().root
	if parent == null:
		parent = source
	if parent == null:
		return null
	var telegraph: Node3D = _SELF.new()
	telegraph.name = "AttackTelegraph"
	telegraph._radius = maxf(radius, 0.2)
	telegraph._duration = maxf(duration, 0.05)
	parent.add_child(telegraph)
	telegraph._build_visuals()
	telegraph.set_world_point(world_pos)
	telegraph.lock()
	return telegraph


func _ready() -> void:
	set_physics_process(true)


func set_world_point(pos: Vector3) -> void:
	global_transform = _ground_decal_transform(_ground_point_at(pos))


func lock() -> void:
	_locked = true


func is_locked() -> bool:
	return _locked


func is_filled() -> bool:
	return _filled


func get_fill_t() -> float:
	return clampf(_elapsed / maxf(_duration, 0.001), 0.0, 1.0)


func get_ground_position() -> Vector3:
	return global_position


func get_aim_point(height_offset: float = 1.05) -> Vector3:
	return global_position + Vector3(0.0, height_offset, 0.0)


func cancel() -> void:
	if _closing:
		return
	_closing = true
	queue_free()


func complete() -> void:
	if _closing:
		return
	_closing = true
	finished.emit()
	queue_free()


func _physics_process(delta: float) -> void:
	if _closing:
		return
	if _filled:
		return
	_elapsed += delta
	var t := get_fill_t()
	_apply_fill_visual(t)
	if t >= 1.0 and not _filled:
		_filled = true
		_apply_fill_visual(1.0)
		filled.emit()


func _build_visuals() -> void:
	var size := _radius * 2.0
	_outline = Decal.new()
	_outline.name = "Outline"
	_outline.size = Vector3(size, DECAL_HEIGHT, size)
	_outline.texture_albedo = _get_ring_texture()
	_outline.modulate = Color(1.0, 0.15, 0.1, 0.95)
	_outline.albedo_mix = 1.0
	_outline.normal_fade = 0.15
	_outline.upper_fade = 0.12
	_outline.lower_fade = 0.12
	add_child(_outline)

	_fill = Decal.new()
	_fill.name = "Fill"
	_fill.size = Vector3(0.02, DECAL_HEIGHT, 0.02)
	_fill.texture_albedo = _get_fill_texture()
	_fill.modulate = Color(1.0, 0.12, 0.08, 0.55)
	_fill.albedo_mix = 1.0
	_fill.normal_fade = 0.15
	_fill.upper_fade = 0.12
	_fill.lower_fade = 0.12
	add_child(_fill)
	_apply_fill_visual(0.0)


func _apply_fill_visual(t: float) -> void:
	if _fill == null:
		return
	var s := maxf(_radius * 2.0 * t, 0.02)
	_fill.size = Vector3(s, DECAL_HEIGHT, s)
	_fill.modulate.a = lerpf(0.2, 0.62, t)


func _ground_point_at(pos: Vector3) -> Vector3:
	var space := get_world_3d().direct_space_state if is_inside_tree() else null
	if space == null:
		return Vector3(pos.x, pos.y + GROUND_Y_PAD, pos.z)
	var from := pos + Vector3(0.0, GROUND_RAY_UP, 0.0)
	var to := pos - Vector3(0.0, GROUND_RAY_DOWN, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	var hit := space.intersect_ray(query)
	if hit.is_empty():
		return Vector3(pos.x, pos.y + GROUND_Y_PAD, pos.z)
	var point: Vector3 = hit.get("position", pos)
	return point + Vector3(0.0, GROUND_Y_PAD, 0.0)


static func _ground_decal_transform(center: Vector3) -> Transform3D:
	# Decal projects along -Y; basis Y = up keeps it parallel to the ground.
	var n := Vector3.UP
	var tangent := Vector3.RIGHT
	var bitangent := n.cross(tangent).normalized()
	var basis := Basis(tangent, n, bitangent)
	return Transform3D(basis, center)


static func _get_ring_texture() -> Texture2D:
	if _ring_texture != null:
		return _ring_texture
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	var outer := center.x
	var inner := outer * 0.78
	for y in size:
		for x in size:
			var d := Vector2(float(x), float(y)).distance_to(center)
			var alpha := 0.0
			if d <= outer and d >= inner:
				var edge := 1.0 - absf(((d - inner) / maxf(outer - inner, 0.001)) * 2.0 - 1.0)
				alpha = pow(clampf(edge, 0.0, 1.0), 0.65)
			img.set_pixel(x, y, Color(1.0, 0.2, 0.12, alpha))
	_ring_texture = ImageTexture.create_from_image(img)
	return _ring_texture


static func _get_fill_texture() -> Texture2D:
	if _fill_texture != null:
		return _fill_texture
	var size := 128
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2((size - 1) * 0.5, (size - 1) * 0.5)
	var radius := center.x
	for y in size:
		for x in size:
			var d := Vector2(float(x), float(y)).distance_to(center) / radius
			var alpha := 0.0
			if d <= 1.0:
				alpha = pow(1.0 - d, 0.35) * 0.9
			img.set_pixel(x, y, Color(1.0, 0.15, 0.1, alpha))
	_fill_texture = ImageTexture.create_from_image(img)
	return _fill_texture


## Kept for callers that still aim frontal AOEs relative to an actor.
static func actor_flat_forward(actor: Node3D) -> Vector3:
	if actor == null:
		return Vector3.FORWARD
	if actor.has_method("get_punch_facing_direction"):
		var facing: Vector3 = actor.get_punch_facing_direction()
		facing.y = 0.0
		if facing.length_squared() > 0.0001:
			return facing.normalized()
	var model := actor.get_node_or_null("Model") as Node3D
	if model != null:
		var forward := -model.global_transform.basis.z
		forward.y = 0.0
		if forward.length_squared() > 0.0001:
			return forward.normalized()
	var basis_forward := -actor.global_transform.basis.z
	basis_forward.y = 0.0
	if basis_forward.length_squared() > 0.0001:
		return basis_forward.normalized()
	return Vector3.FORWARD
