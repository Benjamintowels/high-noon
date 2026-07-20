extends RefCounted

## Nearest-filtered ice hit / shell sprites.

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")

const ICE_TINT := Color(0.55, 0.9, 1.15, 1.0)
const SHELL_TINT := Color(0.65, 0.92, 1.2, 0.95)
const CHILL_MODULATE_STACK1 := Color(0.70, 0.88, 1.12, 1.0)
const CHILL_MODULATE_STACK2 := Color(0.42, 0.72, 1.35, 1.0)
const CHILL_MAT_CACHE_META := &"ice_chill_material_cache"
const BURST_PIXEL := 0.03
const SHELL_PIXEL := 0.028
const AURA_PIXEL := 0.02


static func chill_modulate_for_stacks(stacks: int) -> Color:
	match stacks:
		1:
			return CHILL_MODULATE_STACK1
		2:
			return CHILL_MODULATE_STACK2
		_:
			return Color.WHITE


## Tint meshes blue via surface material albedo (MeshInstance3D has no modulate).
static func apply_chill_modulate(host: Node, tint: Color) -> void:
	if host == null or not is_instance_valid(host):
		return
	if tint.is_equal_approx(Color.WHITE):
		clear_chill_modulate(host)
		return
	var visual_root: Node = host.get_node_or_null("Model")
	if visual_root == null:
		visual_root = host
	var cache: Dictionary = _chill_material_cache(host)
	for node in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null or mesh.name.contains("Debug"):
			continue
		var surface_count := mesh.mesh.get_surface_count()
		if surface_count <= 0:
			continue
		var mesh_key := str(mesh.get_path())
		if not cache.has(mesh_key):
			var originals: Array = []
			for surface_idx in range(surface_count):
				originals.append(mesh.get_surface_override_material(surface_idx))
			cache[mesh_key] = originals
		var originals: Array = cache[mesh_key]
		for surface_idx in range(surface_count):
			var base: Material = (
				originals[surface_idx] if surface_idx < originals.size() else null
			)
			if base == null:
				base = mesh.mesh.surface_get_material(surface_idx)
			mesh.set_surface_override_material(surface_idx, _make_chill_tinted_material(base, tint))


static func clear_chill_modulate(host: Node) -> void:
	if host == null or not is_instance_valid(host):
		return
	if not host.has_meta(CHILL_MAT_CACHE_META):
		return
	var cache: Dictionary = host.get_meta(CHILL_MAT_CACHE_META)
	var visual_root: Node = host.get_node_or_null("Model")
	if visual_root == null:
		visual_root = host
	for node in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if mesh == null or mesh.mesh == null:
			continue
		var mesh_key := str(mesh.get_path())
		if not cache.has(mesh_key):
			continue
		var originals: Array = cache[mesh_key]
		var surface_count := mesh.mesh.get_surface_count()
		for surface_idx in range(surface_count):
			var original: Material = (
				originals[surface_idx] if surface_idx < originals.size() else null
			)
			mesh.set_surface_override_material(surface_idx, original)
	host.remove_meta(CHILL_MAT_CACHE_META)


static func _chill_material_cache(host: Node) -> Dictionary:
	if not host.has_meta(CHILL_MAT_CACHE_META):
		host.set_meta(CHILL_MAT_CACHE_META, {})
	return host.get_meta(CHILL_MAT_CACHE_META)


static func _make_chill_tinted_material(base: Material, tint: Color) -> Material:
	if base == null:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = tint
		return mat
	var dup := base.duplicate()
	if dup is BaseMaterial3D:
		var bm := dup as BaseMaterial3D
		bm.albedo_color = bm.albedo_color * tint
	return dup


static func spawn_chill_burst(host: Node) -> void:
	if host == null or not (host is Node3D):
		return
	var parent := ImpactFXScript.parent_for(host)
	if parent == null:
		return
	_spawn_burst_at(parent, (host as Node3D).global_position + Vector3(0.0, 1.2, 0.0), BURST_PIXEL, ICE_TINT)


## Bigger multi-burst when an ice block explodes / melts.
static func spawn_ice_explode(host: Node) -> void:
	if host == null or not (host is Node3D):
		return
	var parent := ImpactFXScript.parent_for(host)
	if parent == null:
		return
	var origin := (host as Node3D).global_position + Vector3(0.0, 1.05, 0.0)
	_spawn_burst_at(parent, origin, BURST_PIXEL * 1.55, Color(0.75, 0.95, 1.2, 1.0))
	_spawn_burst_at(parent, origin + Vector3(0.35, 0.15, -0.2), BURST_PIXEL * 1.1, ICE_TINT)
	_spawn_burst_at(parent, origin + Vector3(-0.3, 0.25, 0.25), BURST_PIXEL * 1.1, SHELL_TINT)
	var shell_frames := FxCatalogScript.ice_shell_frames()
	if shell_frames != null and shell_frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) > 0:
		var shell := AnimatedSprite3D.new()
		shell.sprite_frames = shell_frames
		shell.animation = FxFramesLoaderScript.ANIM_NAME
		shell.texture_filter = FxFramesLoaderScript.FILTER_3D
		shell.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		shell.pixel_size = SHELL_PIXEL * 1.4
		shell.modulate = Color(0.85, 0.98, 1.25, 1.0)
		parent.add_child(shell)
		shell.global_position = origin
		shell.play()
		shell.animation_finished.connect(shell.queue_free)


static func _spawn_burst_at(parent: Node, pos: Vector3, pixel_size: float, tint: Color) -> void:
	var frames := FxCatalogScript.ice_sparkle_burst_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.modulate = tint
	parent.add_child(sprite)
	sprite.global_position = pos
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)


static func spawn_shell_burst(host: Node) -> void:
	if host == null or not (host is Node3D):
		return
	var parent := ImpactFXScript.parent_for(host)
	if parent == null:
		return
	var frames := FxCatalogScript.ice_shell_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = SHELL_PIXEL
	sprite.modulate = SHELL_TINT
	parent.add_child(sprite)
	sprite.global_position = (host as Node3D).global_position + Vector3(0.0, 1.15, 0.0)
	sprite.play()
	sprite.animation_finished.connect(sprite.queue_free)


static func make_loop_aura(parent: Node3D, tint: Color = ICE_TINT) -> AnimatedSprite3D:
	if parent == null:
		return null
	var frames := FxCatalogScript.status_sparkling_loop_frames()
	if frames == null or frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return null
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = AURA_PIXEL
	sprite.modulate = tint
	parent.add_child(sprite)
	sprite.play()
	return sprite
