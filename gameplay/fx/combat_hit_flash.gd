extends RefCounted
class_name CombatHitFlash

const BLOCK_COLOR := Color(0.55, 0.85, 1.45, 1.0)
const REFLECT_COLOR := Color(1.55, 1.22, 0.28, 1.0)
const DAMAGE_COLOR := Color(1.45, 0.28, 0.28, 1.0)
const PUNCH_WHITE := Color(2.4, 2.4, 2.4, 1.0)
const PUNCH_BLOCK_ACCENT := Color(0.35, 0.68, 1.55, 1.0)
const PUNCH_HIT_ACCENT := Color(1.55, 0.18, 0.18, 1.0)
const BLOCK_BREAK_BLUE := Color(0.35, 0.75, 1.7, 1.0)
const BLOCK_BREAK_WHITE := Color(2.5, 2.5, 2.5, 1.0)
const BLOCK_BREAK_ORANGE := Color(1.7, 0.55, 0.12, 1.0)
const ELECTRIFY_WHITE := Color(2.4, 2.4, 2.4, 1.0)
const ELECTRIFY_BLACK := Color(0.02, 0.02, 0.04, 1.0)
const ELECTRIFY_YELLOW := Color(1.0, 0.92, 0.18, 1.0)
const FLASH_IN := 0.03
const FLASH_HOLD := 0.05
const FLASH_OUT := 0.1
const PUNCH_FLASH_TO_ACCENT := 0.06
const BLOCK_BREAK_STEP := 0.055
## Two color steps + hold = 0.25s total electrify phase.
const ELECTRIFY_STEP := 0.08
const ELECTRIFY_HOLD := 0.09

const CACHE_META := &"combat_hit_flash_material_cache"
const LIGHTNING_FLASH_BUSY_META := &"lightning_flash_busy"
const ACTIVE_TWEENS_META := &"combat_hit_flash_tweens"


static func flash_block(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash(actor, BLOCK_COLOR)


static func flash_reflect(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash(actor, REFLECT_COLOR)


static func flash_damage(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash(actor, DAMAGE_COLOR)


static func flash_punch_block(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash_two_tone(actor, PUNCH_WHITE, PUNCH_BLOCK_ACCENT)


static func flash_punch_hit(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash_two_tone(actor, PUNCH_WHITE, PUNCH_HIT_ACCENT)


## Successful unarmed parry: white snap into gold on the parried attacker.
static func flash_parry(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash_two_tone(actor, PUNCH_WHITE, REFLECT_COLOR)


## Guard shattered: blue → white → orange.
static func flash_block_break(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash_three_tone(actor, BLOCK_BREAK_BLUE, BLOCK_BREAK_WHITE, BLOCK_BREAK_ORANGE)


## Ice gem freeze: light blue snap into white.
static func flash_ice_freeze(actor: Node) -> void:
	if _is_electrify_busy(actor):
		return
	_flash_two_tone(actor, BLOCK_BREAK_BLUE, BLOCK_BREAK_WHITE)


## Lightning gem zap: white → black → yellow (~0.25s). Exclusive over other flashes.
static func flash_electrify(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	if bool(actor.get_meta(LIGHTNING_FLASH_BUSY_META, false)):
		return
	_cancel_active_flashes(actor)
	actor.set_meta(LIGHTNING_FLASH_BUSY_META, true)
	_flash_three_tone(
		actor,
		ELECTRIFY_WHITE,
		ELECTRIFY_BLACK,
		ELECTRIFY_YELLOW,
		ELECTRIFY_STEP,
		ELECTRIFY_HOLD
	)
	var tree := actor.get_tree()
	if tree == null:
		actor.set_meta(LIGHTNING_FLASH_BUSY_META, false)
		return
	var clear_after := ELECTRIFY_STEP * 2.0 + ELECTRIFY_HOLD + 0.02
	tree.create_timer(clear_after).timeout.connect(
		func() -> void:
			if is_instance_valid(actor):
				actor.set_meta(LIGHTNING_FLASH_BUSY_META, false)
	)


static func _is_electrify_busy(actor: Node) -> bool:
	if actor == null or not is_instance_valid(actor):
		return true
	return bool(actor.get_meta(LIGHTNING_FLASH_BUSY_META, false))


static func _cancel_active_flashes(actor: Node) -> void:
	if actor == null or not is_instance_valid(actor):
		return
	var tweens: Variant = actor.get_meta(ACTIVE_TWEENS_META, [])
	if tweens is Array:
		for item in tweens:
			if item is Tween and is_instance_valid(item):
				(item as Tween).kill()
	actor.set_meta(ACTIVE_TWEENS_META, [])
	_restore_cached_materials(actor)


static func _restore_cached_materials(actor: Node) -> void:
	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return
	var cache: Dictionary = _get_material_cache(actor)
	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		var mesh_key := str(mesh.get_path())
		if not cache.has(mesh_key):
			continue
		var originals: Array = cache[mesh_key]
		var surface_count := mesh.mesh.get_surface_count()
		for surface_idx in range(surface_count):
			var original: Material = originals[surface_idx] if surface_idx < originals.size() else null
			mesh.set_surface_override_material(surface_idx, original)


static func _track_tween(actor: Node, tween: Tween) -> void:
	if actor == null or tween == null:
		return
	var tweens: Variant = actor.get_meta(ACTIVE_TWEENS_META, [])
	var list: Array = tweens if tweens is Array else []
	list.append(tween)
	actor.set_meta(ACTIVE_TWEENS_META, list)


static func _flash(actor: Node, flash_color: Color) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var tree := actor.get_tree()
	if tree == null:
		return

	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		_flash_mesh(actor, mesh, flash_color, tree)


static func _get_visual_root(actor: Node) -> Node:
	if actor.has_node("Model"):
		return actor.get_node("Model")
	return actor


static func _should_skip_mesh(mesh: MeshInstance3D) -> bool:
	if mesh.name.contains("Debug"):
		return true
	return mesh.mesh == null


static func _flash_mesh(
	actor: Node,
	mesh: MeshInstance3D,
	flash_color: Color,
	tree: SceneTree
) -> void:
	var surface_count := mesh.mesh.get_surface_count()
	if surface_count <= 0:
		return

	var cache: Dictionary = _get_material_cache(actor)
	var mesh_key := str(mesh.get_path())
	if not cache.has(mesh_key):
		var cached_originals: Array = []
		for surface_idx in range(surface_count):
			cached_originals.append(mesh.get_surface_override_material(surface_idx))
		cache[mesh_key] = cached_originals

	var originals: Array = cache[mesh_key]
	for surface_idx in range(surface_count):
		var flash_mat := StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.albedo_color = flash_color
		flash_mat.emission_enabled = true
		flash_mat.emission = flash_color * 0.35
		mesh.set_surface_override_material(surface_idx, flash_mat)

	var tween := tree.create_tween()
	_track_tween(actor, tween)
	tween.tween_interval(FLASH_IN + FLASH_HOLD)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(mesh):
			return
		for surface_idx in range(surface_count):
			var original: Material = originals[surface_idx] if surface_idx < originals.size() else null
			mesh.set_surface_override_material(surface_idx, original)
	)


static func _flash_two_tone(actor: Node, start_color: Color, accent_color: Color) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var tree := actor.get_tree()
	if tree == null:
		return

	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		_flash_mesh_two_tone(actor, mesh, start_color, accent_color, tree)


static func _flash_mesh_two_tone(
	actor: Node,
	mesh: MeshInstance3D,
	start_color: Color,
	accent_color: Color,
	tree: SceneTree
) -> void:
	var surface_count := mesh.mesh.get_surface_count()
	if surface_count <= 0:
		return

	var cache: Dictionary = _get_material_cache(actor)
	var mesh_key := str(mesh.get_path())
	if not cache.has(mesh_key):
		var cached_originals: Array = []
		for surface_idx in range(surface_count):
			cached_originals.append(mesh.get_surface_override_material(surface_idx))
		cache[mesh_key] = cached_originals

	var originals: Array = cache[mesh_key]
	var flash_materials: Array[StandardMaterial3D] = []
	for surface_idx in range(surface_count):
		var flash_mat := StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.albedo_color = start_color
		flash_mat.emission_enabled = true
		flash_mat.emission = start_color * 0.35
		mesh.set_surface_override_material(surface_idx, flash_mat)
		flash_materials.append(flash_mat)

	var tween := tree.create_tween()
	_track_tween(actor, tween)
	tween.set_parallel(true)
	for flash_mat: StandardMaterial3D in flash_materials:
		tween.tween_property(flash_mat, "albedo_color", accent_color, PUNCH_FLASH_TO_ACCENT)
		tween.tween_property(flash_mat, "emission", accent_color * 0.35, PUNCH_FLASH_TO_ACCENT)
	tween.set_parallel(false)
	tween.tween_interval(FLASH_IN + FLASH_HOLD)
	tween.tween_callback(func() -> void:
		if not is_instance_valid(mesh):
			return
		for surface_idx in range(surface_count):
			var original: Material = originals[surface_idx] if surface_idx < originals.size() else null
			mesh.set_surface_override_material(surface_idx, original)
	)


static func _flash_three_tone(
	actor: Node,
	first_color: Color,
	second_color: Color,
	third_color: Color,
	step_duration: float = BLOCK_BREAK_STEP,
	hold_duration: float = -1.0
) -> void:
	if actor == null or not is_instance_valid(actor):
		return

	var visual_root := _get_visual_root(actor)
	if visual_root == null:
		return

	var tree := actor.get_tree()
	if tree == null:
		return

	var hold := hold_duration if hold_duration >= 0.0 else (FLASH_IN + FLASH_HOLD)
	for mesh: MeshInstance3D in visual_root.find_children("*", "MeshInstance3D", true, false):
		if _should_skip_mesh(mesh):
			continue
		_flash_mesh_three_tone(
			actor,
			mesh,
			first_color,
			second_color,
			third_color,
			tree,
			step_duration,
			hold
		)


static func _flash_mesh_three_tone(
	actor: Node,
	mesh: MeshInstance3D,
	first_color: Color,
	second_color: Color,
	third_color: Color,
	tree: SceneTree,
	step_duration: float = BLOCK_BREAK_STEP,
	hold_duration: float = FLASH_IN + FLASH_HOLD
) -> void:
	var surface_count := mesh.mesh.get_surface_count()
	if surface_count <= 0:
		return

	var cache: Dictionary = _get_material_cache(actor)
	var mesh_key := str(mesh.get_path())
	if not cache.has(mesh_key):
		var cached_originals: Array = []
		for surface_idx in range(surface_count):
			cached_originals.append(mesh.get_surface_override_material(surface_idx))
		cache[mesh_key] = cached_originals

	var originals: Array = cache[mesh_key]
	var flash_materials: Array[StandardMaterial3D] = []
	for surface_idx in range(surface_count):
		var flash_mat := StandardMaterial3D.new()
		flash_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		flash_mat.albedo_color = first_color
		flash_mat.emission_enabled = true
		flash_mat.emission = first_color * 0.4
		mesh.set_surface_override_material(surface_idx, flash_mat)
		flash_materials.append(flash_mat)

	var step := maxf(step_duration, 0.01)
	var tween := tree.create_tween()
	_track_tween(actor, tween)
	tween.set_parallel(true)
	for flash_mat: StandardMaterial3D in flash_materials:
		tween.tween_property(flash_mat, "albedo_color", second_color, step)
		tween.tween_property(flash_mat, "emission", second_color * 0.4, step)
	tween.set_parallel(false)
	tween.set_parallel(true)
	for flash_mat: StandardMaterial3D in flash_materials:
		tween.tween_property(flash_mat, "albedo_color", third_color, step)
		tween.tween_property(flash_mat, "emission", third_color * 0.45, step)
	tween.set_parallel(false)
	tween.tween_interval(maxf(hold_duration, 0.0))
	tween.tween_callback(func() -> void:
		if not is_instance_valid(mesh):
			return
		for surface_idx in range(surface_count):
			var original: Material = originals[surface_idx] if surface_idx < originals.size() else null
			mesh.set_surface_override_material(surface_idx, original)
	)


static func _get_material_cache(actor: Node) -> Dictionary:
	if not actor.has_meta(CACHE_META):
		actor.set_meta(CACHE_META, {})
	return actor.get_meta(CACHE_META)
