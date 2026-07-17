extends RefCounted

## Persistent black semi-transparent ground scorch left by dynamite blasts.
## Recycles Decals at capacity so repeated explosions stay performant.

const FxNodeBudget := preload("res://gameplay/fx/fx_node_budget.gd")

const MAX_CRATERS := 24
const CRATER_ROOT_NAME := &"ExplosionCraters"

static var _crater_texture: Texture2D


static func spawn(parent: Node, center: Vector3, radius: float = 3.5) -> void:
	if parent == null:
		return
	var crater_parent := _resolve_parent(parent)
	if crater_parent == null:
		return

	var holes := FxNodeBudget.ensure_container(crater_parent, CRATER_ROOT_NAME)
	if holes == null:
		return

	var decal := FxNodeBudget.acquire_or_recycle(
		holes,
		MAX_CRATERS,
		func() -> Node: return Decal.new()
	) as Decal
	if decal == null:
		return

	var size := clampf(radius * 0.85, 2.2, 6.5)
	decal.size = Vector3(size, 0.55, size)
	decal.texture_albedo = _get_crater_texture()
	decal.modulate = Color(0.04, 0.04, 0.05, 0.82)
	decal.albedo_mix = 0.92
	decal.normal_fade = 0.2
	decal.upper_fade = 0.18
	decal.lower_fade = 0.18
	decal.global_transform = _ground_decal_transform(center)


static func _resolve_parent(parent: Node) -> Node3D:
	if parent is Node3D:
		return parent as Node3D
	var tree := parent.get_tree() if parent != null else null
	if tree == null:
		return null
	var scene := tree.current_scene
	return scene as Node3D if scene is Node3D else null


static func _ground_decal_transform(center: Vector3) -> Transform3D:
	var n := Vector3.UP
	var tangent := Vector3.RIGHT
	var bitangent := n.cross(tangent).normalized()
	var basis := Basis(tangent, n, bitangent)
	basis = basis.rotated(n, randf() * TAU)
	return Transform3D(basis, center + Vector3(0.0, 0.04, 0.0))


static func _get_crater_texture() -> Texture2D:
	if _crater_texture != null:
		return _crater_texture
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	var center := Vector2(31.5, 31.5)
	for y in 64:
		for x in 64:
			var d := Vector2(float(x), float(y)).distance_to(center) / 32.0
			var edge := clampf(1.0 - d, 0.0, 1.0)
			var ring := pow(edge, 0.55)
			var core := pow(clampf(1.0 - d * 1.35, 0.0, 1.0), 1.8)
			var alpha := clampf(ring * 0.55 + core * 0.75, 0.0, 1.0)
			var shade := lerpf(0.08, 0.02, core)
			img.set_pixel(x, y, Color(shade, shade, shade * 1.05, alpha))
	_crater_texture = ImageTexture.create_from_image(img)
	return _crater_texture
