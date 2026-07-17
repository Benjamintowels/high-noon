extends RefCounted
class_name MuzzleFlashFX

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const FxNodeBudget := preload("res://gameplay/fx/fx_node_budget.gd")

const PIXEL_SIZE := 0.014
const EPIC_EXPLOSION_PIXEL_SIZE := 0.022
const NIGHT_FLASH_DURATION := 0.09
const NIGHT_FLASH_ENERGY := 2.6
const NIGHT_FLASH_RANGE := 3.8
const MAX_MUZZLE_FLASHES := 12
const MUZZLE_FLASHES_NAME := &"MuzzleFlashes"
const NIGHT_FLASHES_NAME := &"MuzzleNightFlashes"
const MAX_NIGHT_FLASHES := 6

## Shotgun triangle flash — one MeshInstance3D / one draw call, pooled.
const SHOTGUN_TRI_FLASHES_NAME := &"ShotgunTriangleFlashes"
const MAX_SHOTGUN_TRI_FLASHES := 8
const SHOTGUN_TRI_COUNT := 9
const SHOTGUN_STREAK_COUNT := 3
const SHOTGUN_FLASH_DURATION := 0.1
const SHOTGUN_FLASH_LENGTH := 0.55
const SHOTGUN_FLASH_META_TWEEN := &"flash_tween"
const SHOTGUN_FLASH_META_MAT := &"flash_material"


static func spawn(
	parent: Node,
	global_position: Vector3,
	style: StringName = &"default",
	pixel_size_override: float = -1.0,
	gun_muzzle: bool = false,
	modulate_override: Color = Color(0, 0, 0, 0),
	direction: Vector3 = Vector3.ZERO
) -> void:
	if parent == null:
		return

	if gun_muzzle:
		_spawn_night_light_flash(parent, global_position)

	var frames: SpriteFrames = null
	var pixel_size := PIXEL_SIZE
	var modulate := Color(1.0, 0.92, 0.78, 1.0)

	match style:
		&"shotgun_blast":
			_spawn_shotgun_triangle_flash(
				parent,
				global_position,
				direction,
				pixel_size_override,
				modulate_override
			)
			return
		&"epic_explosion":
			frames = FxCatalogScript.epic_explosion_frames()
			pixel_size = EPIC_EXPLOSION_PIXEL_SIZE
			modulate = Color(1.0, 0.95, 0.82, 1.0)
		&"symmetrical_large":
			frames = FxCatalogScript.symmetrical_explosion_large_frames()
			pixel_size = EPIC_EXPLOSION_PIXEL_SIZE
			modulate = Color(1.0, 0.88, 0.62, 1.0)
		&"symmetrical", &"default":
			frames = FxCatalogScript.muzzle_frames()
		_:
			frames = FxCatalogScript.muzzle_frames()

	if pixel_size_override > 0.0:
		pixel_size = pixel_size_override
	if modulate_override.a > 0.001:
		modulate = modulate_override

	_spawn_flash_sprite(parent, global_position, frames, pixel_size, modulate)


## Stylized shotgun muzzle: a fan of unshaded triangles in a single ArrayMesh
## (one draw call). Pooled MeshInstance3D, short scale/alpha tween, no sprites.
static func _spawn_shotgun_triangle_flash(
	parent: Node,
	global_position: Vector3,
	direction: Vector3,
	pixel_size_override: float,
	modulate_override: Color
) -> void:
	var container := FxNodeBudget.ensure_container(parent, SHOTGUN_TRI_FLASHES_NAME)
	if container == null:
		return

	var flash := _acquire_triangle_flash(container)
	if flash == null:
		return

	_kill_triangle_flash_tween(flash)

	var forward := direction
	if forward.length_squared() < 0.0001:
		forward = Vector3.FORWARD
		var viewport := parent.get_viewport()
		if viewport != null:
			var camera := viewport.get_camera_3d()
			if camera != null:
				forward = -camera.global_transform.basis.z
	forward = forward.normalized()

	var up := Vector3.UP
	if absf(forward.dot(up)) > 0.92:
		up = Vector3.RIGHT
	flash.global_transform = Transform3D(Basis.looking_at(forward, up), global_position)

	var size_scale := 1.0
	if pixel_size_override > 0.0:
		size_scale = clampf(pixel_size_override / PIXEL_SIZE, 0.6, 3.0)

	var hot := Color(1.0, 0.96, 0.78, 1.0)
	var mid := Color(1.0, 0.72, 0.28, 0.92)
	var edge := Color(1.0, 0.42, 0.12, 0.55)
	if modulate_override.a > 0.001:
		hot = modulate_override
		mid = modulate_override.lerp(Color(1.0, 0.55, 0.15, modulate_override.a), 0.45)
		edge = Color(modulate_override.r, modulate_override.g * 0.5, modulate_override.b * 0.25, modulate_override.a * 0.55)

	flash.mesh = _build_shotgun_triangle_mesh(size_scale, hot, mid, edge)

	var material := _build_triangle_flash_material(hot)
	flash.material_override = material
	flash.set_meta(SHOTGUN_FLASH_META_MAT, material)
	flash.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flash.visible = true
	flash.scale = Vector3(0.35, 0.35, 0.45)

	var end_scale := Vector3(
		randf_range(1.05, 1.35),
		randf_range(1.05, 1.35),
		randf_range(1.25, 1.7)
	)
	var duration := SHOTGUN_FLASH_DURATION * randf_range(0.9, 1.15)

	var tween := flash.create_tween()
	flash.set_meta(SHOTGUN_FLASH_META_TWEEN, tween)
	tween.set_parallel(true)
	tween.tween_property(flash, "scale", end_scale, duration * 0.35)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_method(
		func(alpha: float) -> void:
			if is_instance_valid(material):
				material.albedo_color.a = alpha,
		1.0,
		0.0,
		duration
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(_retire_triangle_flash.bind(flash))


static func _build_shotgun_triangle_mesh(
	size_scale: float,
	hot: Color,
	mid: Color,
	edge: Color
) -> ArrayMesh:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var length := SHOTGUN_FLASH_LENGTH * size_scale

	# Radial star — tip at muzzle, bases fanned in the plane facing down-range.
	var spin := randf() * TAU
	for i in SHOTGUN_TRI_COUNT:
		var angle := spin + TAU * float(i) / float(SHOTGUN_TRI_COUNT)
		angle += randf_range(-0.12, 0.12)
		var radial := Vector3(cos(angle), sin(angle), 0.0)
		var tip_len := length * randf_range(0.55, 1.05)
		var tip := radial * tip_len + Vector3(0.0, 0.0, -randf_range(0.02, 0.1) * size_scale)
		var half_w := tip_len * randf_range(0.08, 0.16)
		var side := Vector3(-sin(angle), cos(angle), 0.0) * half_w
		# Slight push toward camera plane so thin spikes still read.
		var base_z := randf_range(0.0, 0.04) * size_scale
		var a := Vector3.ZERO
		var b := tip + side + Vector3(0.0, 0.0, -base_z)
		var c := tip - side + Vector3(0.0, 0.0, -base_z)
		_append_triangle(vertices, normals, colors, indices, a, b, c, hot, mid, edge)

	# Longer forward streaks sell the blast cone / pellet fan.
	for _streak in SHOTGUN_STREAK_COUNT:
		var yaw := randf_range(-0.55, 0.55)
		var pitch := randf_range(-0.35, 0.35)
		var dir := Vector3(sin(yaw), sin(pitch), -cos(yaw) * cos(pitch)).normalized()
		var streak_len := length * randf_range(1.15, 1.7)
		var tip := dir * streak_len
		var right := dir.cross(Vector3.UP)
		if right.length_squared() < 0.0001:
			right = dir.cross(Vector3.RIGHT)
		right = right.normalized() * (streak_len * randf_range(0.04, 0.08))
		var up := dir.cross(right).normalized() * (streak_len * 0.02)
		_append_triangle(
			vertices,
			normals,
			colors,
			indices,
			Vector3.ZERO,
			tip + right + up,
			tip - right + up,
			hot,
			mid,
			edge
		)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices

	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func _append_triangle(
	vertices: PackedVector3Array,
	normals: PackedVector3Array,
	colors: PackedColorArray,
	indices: PackedInt32Array,
	a: Vector3,
	b: Vector3,
	c: Vector3,
	color_a: Color,
	color_b: Color,
	color_c: Color
) -> void:
	var normal := (b - a).cross(c - a)
	if normal.length_squared() < 0.0000001:
		normal = Vector3.BACK
	else:
		normal = normal.normalized()
	var base := vertices.size()
	vertices.append(a)
	vertices.append(b)
	vertices.append(c)
	normals.append(normal)
	normals.append(normal)
	normals.append(normal)
	colors.append(color_a)
	colors.append(color_b)
	colors.append(color_c)
	indices.append(base)
	indices.append(base + 1)
	indices.append(base + 2)


static func _build_triangle_flash_material(albedo: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.albedo_color = Color(1.0, 1.0, 1.0, albedo.a)
	material.disable_receive_shadows = true
	return material


static func _acquire_triangle_flash(container: Node3D) -> MeshInstance3D:
	var node := FxNodeBudget.acquire_or_recycle(
		container,
		MAX_SHOTGUN_TRI_FLASHES,
		func() -> Node:
			var mesh_instance := MeshInstance3D.new()
			mesh_instance.name = "ShotgunTriFlash"
			return mesh_instance
	)
	return node as MeshInstance3D


static func _kill_triangle_flash_tween(flash: MeshInstance3D) -> void:
	if flash == null or not flash.has_meta(SHOTGUN_FLASH_META_TWEEN):
		return
	var tween: Tween = flash.get_meta(SHOTGUN_FLASH_META_TWEEN)
	if tween != null and is_instance_valid(tween):
		tween.kill()
	flash.remove_meta(SHOTGUN_FLASH_META_TWEEN)


static func _retire_triangle_flash(flash: MeshInstance3D) -> void:
	if flash == null or not is_instance_valid(flash):
		return
	_kill_triangle_flash_tween(flash)
	flash.visible = false
	flash.mesh = null
	flash.material_override = null
	if flash.has_meta(SHOTGUN_FLASH_META_MAT):
		flash.remove_meta(SHOTGUN_FLASH_META_MAT)


static func _spawn_flash_sprite(
	parent: Node,
	global_position: Vector3,
	frames: SpriteFrames,
	pixel_size: float,
	modulate: Color
) -> void:
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return

	var container := FxNodeBudget.ensure_container(parent, MUZZLE_FLASHES_NAME)
	if container == null:
		return

	var sprite := _acquire_flash_sprite(container)
	if sprite == null:
		return

	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.modulate = modulate
	sprite.visible = true
	sprite.global_position = global_position
	_disconnect_all(sprite.animation_finished)
	sprite.play()
	sprite.animation_finished.connect(
		func() -> void: _retire_flash(sprite),
		CONNECT_ONE_SHOT
	)


static func _disconnect_all(signal_obj: Signal) -> void:
	for connection in signal_obj.get_connections():
		signal_obj.disconnect(connection["callable"])


static func _acquire_flash_sprite(container: Node3D) -> AnimatedSprite3D:
	for child in container.get_children():
		var idle := child as AnimatedSprite3D
		if idle != null and not idle.visible:
			container.remove_child(idle)
			container.add_child(idle)
			return idle

	if container.get_child_count() >= MAX_MUZZLE_FLASHES:
		var oldest := container.get_child(0) as AnimatedSprite3D
		if oldest == null:
			FxNodeBudget.free_oldest(container)
			var created := AnimatedSprite3D.new()
			container.add_child(created)
			return created
		if oldest.is_playing():
			oldest.stop()
		container.remove_child(oldest)
		container.add_child(oldest)
		return oldest

	var sprite := AnimatedSprite3D.new()
	container.add_child(sprite)
	return sprite


static func _retire_flash(sprite: AnimatedSprite3D) -> void:
	if sprite == null or not is_instance_valid(sprite):
		return
	sprite.stop()
	sprite.visible = false


static func _spawn_night_light_flash(parent: Node, global_position: Vector3) -> void:
	if not DayNightCycle.is_outdoor_night():
		return

	var container := FxNodeBudget.ensure_container(parent, NIGHT_FLASHES_NAME)
	if container == null:
		return
	FxNodeBudget.ensure_child_budget(container, MAX_NIGHT_FLASHES)

	var holder := Node3D.new()
	holder.name = "MuzzleNightFlash"
	container.add_child(holder)
	holder.global_position = global_position

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.84, 0.48)
	light.light_energy = NIGHT_FLASH_ENERGY
	light.omni_range = NIGHT_FLASH_RANGE
	light.shadow_enabled = false
	holder.add_child(light)

	var tween := holder.create_tween()
	tween.tween_property(light, "light_energy", 0.0, NIGHT_FLASH_DURATION)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT)
	tween.tween_callback(holder.queue_free)
