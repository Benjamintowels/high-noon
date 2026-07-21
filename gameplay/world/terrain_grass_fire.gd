extends Node

## Burns Terrain3D instanced grass (grass / grass_2) when a flaming host walks
## near a clump. Overlay fire VFX for BURN_DURATION, then collapse + ash FX
## before removing the Multimesh instance.
## Each ignition rolls SPREAD_CHANCE against neighboring clumps within TOUCH_RADIUS.
##
## MultiMesh instances have no per-blade scripts, so this builds a spatial hash
## of transforms from Terrain3DRegion.instances once, then only touches nearby
## cells while anything is on fire.

const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const FxFramesLoaderScript := preload("res://gameplay/fx/fx_frames_loader.gd")
const ImpactFXScript := preload("res://gameplay/shooting/impact_fx.gd")
const SmokePuffFXScript := preload("res://gameplay/fx/smoke_puff_fx.gd")

const GROUP_NAME := &"terrain_grass_fire"
const TARGET_MESH_NAMES: Array[StringName] = [&"grass_2", &"grass"]

const BURN_DURATION := 3.0
## Collapse + ash hold before the Multimesh entry is deleted.
const BURNOUT_DURATION := 0.45
const IGNITE_RADIUS := 1.7
const TOUCH_RADIUS := 1.45
const SPREAD_CHANCE := 0.5
const SPREAD_DELAY := 0.35
const GRID_CELL := 4.0
const VFX_HEIGHT := 0.55
const FIRE_TINT := Color(1.0, 0.55, 0.18, 1.0)
const IGNITE_TINT := Color(1.0, 0.72, 0.28, 0.95)
const ASH_SMOKE_TINT := Color(0.22, 0.2, 0.18, 0.85)
const EMBER_TINT := Color(1.0, 0.4, 0.12, 0.9)
const BODY_PIXEL_SIZE := 0.022
const IGNITE_PIXEL_SIZE := 0.03
const ASH_SMOKE_PIXEL_SIZE := 0.028
const EMBER_PIXEL_SIZE := 0.016
const COLLAPSE_SCALE_Y := 0.08
const MAX_ACTIVE_BURNS := 96
const MAX_IGNITES_PER_PULSE := 8
## Fire-gem bullet trails: sample the shot segment for grass under the beam.
const TRAIL_SAMPLE_STEP := 1.6
const TRAIL_MAX_SAMPLES := 12
const TRAIL_MAX_IGNITES := 10

var _terrain: Node
var _instancer: Object
var _indexed := false
## patch_id -> { pos, mesh_id, region_loc, cell, index }
var _patches: Dictionary = {}
## Vector2i grid cell -> Array[int] patch ids
var _grid: Dictionary = {}
var _next_patch_id := 1
## patch_id -> burn state dict
var _burning: Dictionary = {}
## patch ids already consumed (burned away or mid-burn)
var _consumed: Dictionary = {}
var _mmi_dirty := false


static func ensure_for_tree(tree: SceneTree) -> Node:
	if tree == null:
		return null
	var existing := tree.get_first_node_in_group(GROUP_NAME)
	if existing != null:
		return existing
	var terrain := _find_terrain3d(tree)
	if terrain == null:
		return null
	var script: Script = load("res://gameplay/world/terrain_grass_fire.gd") as Script
	if script == null:
		return null
	var node: Node = script.new() as Node
	if node == null:
		return null
	node.name = "TerrainGrassFire"
	terrain.add_child(node)
	return node


static func _find_terrain3d(tree: SceneTree) -> Node:
	var root := tree.current_scene
	if root == null:
		root = tree.root
	if root == null:
		return null
	return _find_terrain3d_under(root)


static func _find_terrain3d_under(node: Node) -> Node:
	if node == null:
		return null
	if String(node.get_class()) == "Terrain3D":
		return node
	for child in node.get_children():
		var found := _find_terrain3d_under(child)
		if found != null:
			return found
	return null


func _ready() -> void:
	add_to_group(GROUP_NAME)
	_terrain = get_parent()
	if _terrain == null or String(_terrain.get_class()) != "Terrain3D":
		_terrain = _find_terrain3d_under(get_tree().current_scene) if get_tree() != null else null
	if _terrain != null:
		_instancer = _terrain.get("instancer")
	call_deferred("_rebuild_index")


func _process(delta: float) -> void:
	if _burning.is_empty():
		set_process(false)
		return
	var to_burnout: Array[int] = []
	var to_remove: Array[int] = []
	for patch_id in _burning.keys():
		var state: Dictionary = _burning[patch_id]
		var phase := String(state.get("phase", "burn"))
		state["time_left"] = float(state.get("time_left", 0.0)) - delta
		if phase == "burn":
			if not bool(state.get("spread_rolled", false)):
				state["spread_at"] = float(state.get("spread_at", SPREAD_DELAY)) - delta
				if float(state["spread_at"]) <= 0.0:
					state["spread_rolled"] = true
					_roll_spread(int(patch_id), state.get("source") as Node)
			if float(state["time_left"]) <= 0.0:
				to_burnout.append(int(patch_id))
		elif float(state["time_left"]) <= 0.0:
			to_remove.append(int(patch_id))
	for patch_id in to_burnout:
		_begin_burnout(patch_id)
	for patch_id in to_remove:
		_complete_burnout(patch_id)
	if _mmi_dirty:
		_flush_mmi_updates()


## Called from OnFireStatus spread ticks — cheap when the host is far from grass.
func try_ignite_near(world_pos: Vector3, source: Node = null) -> void:
	_try_ignite_near_budgeted(world_pos, source, MAX_IGNITES_PER_PULSE)


## Fire-gem muzzle→impact beam. XZ grid probes only — negligible vs trail particles.
func try_ignite_along_segment(from: Vector3, to: Vector3, source: Node = null) -> void:
	if not _indexed and not _rebuild_index():
		return
	if _burning.size() >= MAX_ACTIVE_BURNS:
		return
	var delta := to - from
	var length := delta.length()
	if length < 0.05:
		_try_ignite_near_budgeted(to, source, TRAIL_MAX_IGNITES)
		return
	var direction := delta / length
	var sample_count := clampi(int(ceil(length / TRAIL_SAMPLE_STEP)) + 1, 2, TRAIL_MAX_SAMPLES)
	var ignited := 0
	for i in sample_count:
		if ignited >= TRAIL_MAX_IGNITES or _burning.size() >= MAX_ACTIVE_BURNS:
			break
		var t := float(i) / float(sample_count - 1)
		ignited += _try_ignite_near_budgeted(
			from + direction * (length * t),
			source,
			TRAIL_MAX_IGNITES - ignited
		)


## Returns how many new patches were ignited this call.
func _try_ignite_near_budgeted(world_pos: Vector3, source: Node, budget: int) -> int:
	if budget <= 0:
		return 0
	if not _indexed and not _rebuild_index():
		return 0
	if _burning.size() >= MAX_ACTIVE_BURNS:
		return 0
	var ignited := 0
	for patch_id in _gather_nearby(world_pos, IGNITE_RADIUS):
		if ignited >= budget:
			break
		if _ignite_patch(patch_id, source):
			ignited += 1
	return ignited


## One-shot helper for bullets/pellets with an active fire trail.
static func try_ignite_fire_trail(
	tree: SceneTree,
	from: Vector3,
	to: Vector3,
	source: Node = null
) -> void:
	var grass_fire := ensure_for_tree(tree)
	if grass_fire != null and grass_fire.has_method("try_ignite_along_segment"):
		grass_fire.call("try_ignite_along_segment", from, to, source)


func _rebuild_index() -> bool:
	_patches.clear()
	_grid.clear()
	_indexed = false
	if _terrain == null or not is_instance_valid(_terrain):
		return false
	var data: Variant = _terrain.get("data")
	if data == null:
		return false
	var mesh_ids := _resolve_target_mesh_ids()
	if mesh_ids.is_empty():
		return false

	var regions: Array = []
	if data.has_method("get_regions_active"):
		regions = data.call("get_regions_active") as Array
	elif data.has_method("get_regions"):
		regions = data.call("get_regions") as Array
	if regions.is_empty():
		return false

	_next_patch_id = 1
	for region in regions:
		if region == null:
			continue
		var region_loc: Vector2i = region.get("location") as Vector2i
		var instances: Variant = region.get("instances")
		if not (instances is Dictionary):
			continue
		var by_mesh: Dictionary = instances as Dictionary
		for mesh_id in mesh_ids:
			if not by_mesh.has(mesh_id):
				continue
			var cells: Variant = by_mesh[mesh_id]
			if not (cells is Dictionary):
				continue
			for cell_key in (cells as Dictionary).keys():
				var cell: Vector2i = cell_key as Vector2i
				var entry: Variant = cells[cell_key]
				if not (entry is Array) or (entry as Array).is_empty():
					continue
				var transforms: Variant = (entry as Array)[0]
				if not (transforms is Array):
					continue
				var xforms: Array = transforms as Array
				for i in xforms.size():
					var xform: Transform3D = xforms[i] as Transform3D
					var pos := xform.origin
					var patch_id := _next_patch_id
					_next_patch_id += 1
					_patches[patch_id] = {
						"pos": pos,
						"mesh_id": int(mesh_id),
						"region_loc": region_loc,
						"region": region,
						"cell": cell,
						"index": i,
					}
					var gkey := _grid_key(pos)
					if not _grid.has(gkey):
						_grid[gkey] = [] as Array[int]
					(_grid[gkey] as Array).append(patch_id)

	_indexed = not _patches.is_empty()
	return _indexed


func _resolve_target_mesh_ids() -> Array[int]:
	var result: Array[int] = []
	var assets: Variant = _terrain.get("assets")
	if assets == null:
		# Fallback to the known stage1 / dry_gulch asset dock ids.
		return [0, 1] as Array[int]
	var mesh_list: Variant = assets.get("mesh_list")
	if not (mesh_list is Array):
		return [0, 1] as Array[int]
	for mesh_asset in mesh_list as Array:
		if mesh_asset == null:
			continue
		var mesh_name := StringName(str(mesh_asset.get("name")))
		if TARGET_MESH_NAMES.has(mesh_name):
			result.append(int(mesh_asset.get("id")))
	if result.is_empty():
		return [0, 1] as Array[int]
	return result


func _gather_nearby(world_pos: Vector3, radius: float) -> Array[int]:
	var out: Array[int] = []
	var radius_sq := radius * radius
	var center := _grid_key(world_pos)
	var cell_span := int(ceil(radius / GRID_CELL)) + 1
	for dz in range(-cell_span, cell_span + 1):
		for dx in range(-cell_span, cell_span + 1):
			var key := Vector2i(center.x + dx, center.y + dz)
			if not _grid.has(key):
				continue
			for patch_id in _grid[key] as Array:
				var id := int(patch_id)
				if _consumed.has(id) or _burning.has(id):
					continue
				var patch: Dictionary = _patches.get(id, {})
				if patch.is_empty():
					continue
				var pos: Vector3 = patch.get("pos", Vector3.ZERO)
				var dxp := pos.x - world_pos.x
				var dzp := pos.z - world_pos.z
				if dxp * dxp + dzp * dzp <= radius_sq:
					out.append(id)
	return out


func _ignite_patch(patch_id: int, source: Node) -> bool:
	if _consumed.has(patch_id) or _burning.has(patch_id):
		return false
	if not _patches.has(patch_id):
		return false
	if _burning.size() >= MAX_ACTIVE_BURNS:
		return false
	var patch: Dictionary = _patches[patch_id]
	var pos: Vector3 = patch.get("pos", Vector3.ZERO)
	_consumed[patch_id] = true
	_burning[patch_id] = {
		"phase": "burn",
		"time_left": BURN_DURATION,
		"spread_at": SPREAD_DELAY,
		"spread_rolled": false,
		"source": source,
		"vfx": _spawn_burn_vfx(pos),
	}
	set_process(true)
	return true


func _roll_spread(patch_id: int, source: Node) -> void:
	var patch: Dictionary = _patches.get(patch_id, {})
	if patch.is_empty():
		return
	var origin: Vector3 = patch.get("pos", Vector3.ZERO)
	for neighbor_id in _gather_nearby(origin, TOUCH_RADIUS):
		if neighbor_id == patch_id:
			continue
		if randf() > SPREAD_CHANCE:
			continue
		_ignite_patch(neighbor_id, source)


func _begin_burnout(patch_id: int) -> void:
	var state: Variant = _burning.get(patch_id, null)
	if not (state is Dictionary):
		return
	var burn_state: Dictionary = state as Dictionary
	if String(burn_state.get("phase", "")) == "out":
		return
	var patch: Dictionary = _patches.get(patch_id, {})
	var pos: Vector3 = patch.get("pos", Vector3.ZERO)
	_collapse_patch_instance(patch_id)
	var old_vfx: Variant = burn_state.get("vfx", null)
	if old_vfx is Node and is_instance_valid(old_vfx):
		(old_vfx as Node).queue_free()
	burn_state["phase"] = "out"
	burn_state["time_left"] = BURNOUT_DURATION
	burn_state["vfx"] = _spawn_burnout_vfx(pos)
	_burning[patch_id] = burn_state


func _complete_burnout(patch_id: int) -> void:
	var state: Variant = _burning.get(patch_id, null)
	_burning.erase(patch_id)
	if state is Dictionary:
		var vfx: Variant = (state as Dictionary).get("vfx", null)
		if vfx is Node and is_instance_valid(vfx):
			(vfx as Node).queue_free()
	_remove_patch_instance(patch_id)
	_patches.erase(patch_id)


## Squash the Multimesh clump into a charred stub so the later delete isn't a pop.
func _collapse_patch_instance(patch_id: int) -> void:
	var patch: Dictionary = _patches.get(patch_id, {})
	if patch.is_empty():
		return
	var region: Variant = patch.get("region", null)
	var mesh_id := int(patch.get("mesh_id", -1))
	var cell: Vector2i = patch.get("cell", Vector2i.ZERO) as Vector2i
	var index := int(patch.get("index", -1))
	if region == null or mesh_id < 0 or index < 0:
		return
	var instances: Variant = region.get("instances")
	if not (instances is Dictionary):
		return
	var by_mesh: Dictionary = instances as Dictionary
	if not by_mesh.has(mesh_id):
		return
	var cells: Variant = by_mesh[mesh_id]
	if not (cells is Dictionary) or not (cells as Dictionary).has(cell):
		return
	var entry: Variant = (cells as Dictionary)[cell]
	if not (entry is Array) or (entry as Array).is_empty():
		return
	var entry_arr: Array = entry as Array
	var transforms: Variant = entry_arr[0]
	if not (transforms is Array):
		return
	var xforms: Array = transforms as Array
	if index < 0 or index >= xforms.size():
		return
	var xform: Transform3D = xforms[index] as Transform3D
	# Keep lateral footprint; crush height so ash FX reads as the clump dying.
	xform.basis = xform.basis.scaled(Vector3(1.05, COLLAPSE_SCALE_Y, 1.05))
	xforms[index] = xform
	if entry_arr.size() > 1 and entry_arr[1] is PackedColorArray:
		var colors: PackedColorArray = entry_arr[1] as PackedColorArray
		if index < colors.size():
			colors[index] = Color(0.12, 0.1, 0.08, 1.0)
			entry_arr[1] = colors
	if entry_arr.size() > 2:
		entry_arr[2] = true
	(cells as Dictionary)[cell] = entry_arr
	_mmi_dirty = true


func _remove_patch_instance(patch_id: int) -> void:
	var patch: Dictionary = _patches.get(patch_id, {})
	if patch.is_empty():
		return
	var region: Variant = patch.get("region", null)
	var mesh_id := int(patch.get("mesh_id", -1))
	var cell: Vector2i = patch.get("cell", Vector2i.ZERO) as Vector2i
	var index := int(patch.get("index", -1))
	if region == null or mesh_id < 0 or index < 0:
		return
	var instances: Variant = region.get("instances")
	if not (instances is Dictionary):
		return
	var by_mesh: Dictionary = instances as Dictionary
	if not by_mesh.has(mesh_id):
		return
	var cells: Variant = by_mesh[mesh_id]
	if not (cells is Dictionary) or not (cells as Dictionary).has(cell):
		return
	var entry: Variant = (cells as Dictionary)[cell]
	if not (entry is Array) or (entry as Array).is_empty():
		return
	var entry_arr: Array = entry as Array
	var transforms: Variant = entry_arr[0]
	if not (transforms is Array):
		return
	var xforms: Array = transforms as Array
	if index < 0 or index >= xforms.size():
		return
	xforms.remove_at(index)
	if entry_arr.size() > 1 and entry_arr[1] is PackedColorArray:
		var colors: PackedColorArray = entry_arr[1] as PackedColorArray
		if index < colors.size():
			colors.remove_at(index)
			entry_arr[1] = colors
	if entry_arr.size() > 2:
		entry_arr[2] = true
	(cells as Dictionary)[cell] = entry_arr
	_reindex_cell_patches(region, mesh_id, cell, index)
	_mmi_dirty = true


func _reindex_cell_patches(region: Variant, mesh_id: int, cell: Vector2i, removed_index: int) -> void:
	var region_loc: Vector2i = region.get("location") as Vector2i
	for patch_id in _patches.keys():
		var patch: Dictionary = _patches[patch_id]
		if int(patch.get("mesh_id", -1)) != mesh_id:
			continue
		if patch.get("cell", Vector2i(-999999, -999999)) != cell:
			continue
		if patch.get("region_loc", Vector2i(-999999, -999999)) != region_loc:
			continue
		var idx := int(patch.get("index", -1))
		if idx > removed_index:
			patch["index"] = idx - 1
			_patches[patch_id] = patch


func _flush_mmi_updates() -> void:
	_mmi_dirty = false
	if _instancer == null or not is_instance_valid(_terrain):
		_instancer = _terrain.get("instancer") if _terrain != null else null
	if _instancer == null:
		return
	# Queued + de-duplicated by Terrain3D; safe to call often.
	_instancer.call("update_mmis")


func _spawn_burn_vfx(world_pos: Vector3) -> Node3D:
	var root := _make_vfx_root(world_pos, "GrassFireVfx")
	_play_sprite_frames(
		root,
		FxCatalogScript.epic_explosion_frames(),
		IGNITE_PIXEL_SIZE,
		IGNITE_TINT
	)
	var loop_frames := FxCatalogScript.status_sparkling_loop_frames()
	if loop_frames != null and loop_frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) > 0:
		var loop_sprite := AnimatedSprite3D.new()
		loop_sprite.sprite_frames = loop_frames
		loop_sprite.animation = FxFramesLoaderScript.ANIM_NAME
		loop_sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
		loop_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		loop_sprite.pixel_size = BODY_PIXEL_SIZE
		loop_sprite.modulate = FIRE_TINT
		root.add_child(loop_sprite)
		loop_sprite.play()

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.45, 0.12, 1.0)
	light.light_energy = 1.4
	light.omni_range = 1.8
	light.shadow_enabled = false
	root.add_child(light)
	return root


func _spawn_burnout_vfx(world_pos: Vector3) -> Node3D:
	var root := _make_vfx_root(world_pos, "GrassBurnoutVfx")
	# Ash plume + dying embers sell the Multimesh collapse.
	_play_sprite_frames(
		root,
		FxCatalogScript.directional_smoke_frames(),
		ASH_SMOKE_PIXEL_SIZE,
		ASH_SMOKE_TINT
	)
	_play_sprite_frames(
		root,
		FxCatalogScript.status_sparkling_loop_frames(),
		EMBER_PIXEL_SIZE,
		EMBER_TINT,
		true
	)
	var parent := root.get_parent()
	if parent != null:
		SmokePuffFXScript.spawn_trail(parent, world_pos + Vector3(0.0, 0.15, 0.0), 0.18)
		SmokePuffFXScript.spawn_trail(
			parent,
			world_pos + Vector3(randf_range(-0.12, 0.12), 0.2, randf_range(-0.12, 0.12)),
			0.14
		)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.35, 0.1, 1.0)
	light.light_energy = 0.7
	light.omni_range = 1.2
	light.shadow_enabled = false
	root.add_child(light)
	var tween := root.create_tween()
	tween.tween_property(light, "light_energy", 0.0, BURNOUT_DURATION)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	return root


func _make_vfx_root(world_pos: Vector3, node_name: String) -> Node3D:
	var parent := ImpactFXScript.parent_for(self)
	if parent == null:
		parent = get_tree().current_scene if get_tree() != null else self
	var root := Node3D.new()
	root.name = node_name
	parent.add_child(root)
	root.global_position = world_pos + Vector3(0.0, VFX_HEIGHT, 0.0)
	return root


func _play_sprite_frames(
	parent: Node3D,
	frames: SpriteFrames,
	pixel_size: float,
	tint: Color,
	auto_free_on_finish: bool = true
) -> void:
	if parent == null or frames == null:
		return
	if frames.get_frame_count(FxFramesLoaderScript.ANIM_NAME) == 0:
		return
	var sprite := AnimatedSprite3D.new()
	sprite.sprite_frames = frames
	sprite.animation = FxFramesLoaderScript.ANIM_NAME
	sprite.texture_filter = FxFramesLoaderScript.FILTER_3D
	sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sprite.pixel_size = pixel_size
	sprite.modulate = tint
	parent.add_child(sprite)
	sprite.play()
	if auto_free_on_finish:
		sprite.animation_finished.connect(sprite.queue_free)


func _grid_key(pos: Vector3) -> Vector2i:
	return Vector2i(int(floor(pos.x / GRID_CELL)), int(floor(pos.z / GRID_CELL)))
