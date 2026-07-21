extends Node3D

## Shared driver for roguelike run zones. A zone is a self-contained scene the
## player walks into from a hub gate and leaves through a return portal (or by
## dying — death returns to the hub, never a bonfire; there are no checkpoints
## mid-run).
##
## Scene contract (see zone_1.tscn):
## - PlayerSpawn Marker3D
## - Optional Terrain/Terrain3D (flat floor imported at runtime until sculpted)
## - Enemies host node in group "cave_enemy_root" with cave_enemy_spawn markers
## - Optional RunDirector child (difficulty / waves / boss / portal)
## - ReturnPortal Area3D with run_return_portal.gd (E to extract), sealed until boss outro
## - FadeLayer/FadeOverlay ColorRect
## - WorldEnvironment named "WorldEnvironment" (death desaturation looks it up)

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const STAGE1_VISUAL_SETUP := preload("res://stages/stage1/stage1_visual_setup.gd")
const TerrainGrassFireScript := preload("res://gameplay/world/terrain_grass_fire.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
const StagedSetupQueueScript := preload("res://gameplay/world/staged_setup_queue.gd")
const HitchProfiler := preload("res://gameplay/debug/run_hitch_profiler.gd")

@export var zone_id := ""
## When on, prints [HITCH] timings for boot / enemy spawn / cover / dynamite.
## zone_1 ships with this enabled for profiling — untick when done.
@export var hitch_profile := false

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay

var _player: Node3D
var _setup_queue: Node


func _ready() -> void:
	# Cover first — heavy setup below must not flash the default clear color.
	_fade_overlay.modulate.a = 1.0

	if hitch_profile:
		HitchProfiler.force_enable(true)
	HitchProfiler.announce_enabled()

	var hitch_t := HitchProfiler.begin()
	FxCatalogScript.warm_all()
	HitchProfiler.end(HitchProfiler.LABEL_ZONE_FX_WARM, hitch_t)

	add_to_group("run_zone_stage")
	# Direct-boot support (editor F6): register the run so gates/death work.
	# Load the current roguelike save when present (same as hub F6), then
	# deposit wallet → bank so the run starts like a real gate travel.
	if not RunState.roguelike_active:
		RunState.begin_roguelike_session(RoguelikeSave.has_save())
	if not RunState.is_run_active() and zone_id != "":
		# Editor F6 / direct boot: mirror travel_to_zone wallet prep.
		RunMetaProgress.deposit_inventory_to_bank()
		RunState.reset_run_counters()
		RunState.run_active = true
		RunState.current_zone_id = zone_id
	ShopSession.reset_for_outdoor_spawn()
	DayNightCycle.bind_outdoor_scene($Sun)
	_ensure_terrain_floor()

	hitch_t = HitchProfiler.begin()
	STAGE1_VISUAL_SETUP.apply_materials(self)
	HitchProfiler.end(HitchProfiler.LABEL_ZONE_MATERIALS, hitch_t)

	_start_staged_cover_setup()

	hitch_t = HitchProfiler.begin()
	_spawn_player()
	HitchProfiler.end(HitchProfiler.LABEL_ZONE_PLAYER_SPAWN, hitch_t)

	call_deferred("_start_run_content")
	call_deferred("_bootstrap_terrain_grass_fire")
	call_deferred("_grant_test_fire_gem")

	# Terrain3D collision / floor snap need a physics tick before reveal.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()

	await _reveal_after_load()

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func _exit_tree() -> void:
	DayNightCycle.unbind_outdoor_scene($Sun)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func get_run_player() -> Node3D:
	return _player


func _reveal_after_load() -> void:
	if RunState.is_covering():
		_fade_overlay.modulate.a = 0.0
		await RunState.fade_from_black()
		return

	# Editor F6 / direct boot — stage overlay only.
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


## Bullet-cover trimesh used to run whole-zone in _ready — one big hitch on
## Dry Gulch (~72 trees + buildings). Amortize behind the boot fade like stage1.
func _start_staged_cover_setup() -> void:
	_setup_queue = StagedSetupQueueScript.new()
	_setup_queue.name = "StagedSetupQueue"
	add_child(_setup_queue)

	for target in WOOD_BULLET_COVER.collect_cover_targets(self):
		var detail := String(target.name) if target != null else ""
		_setup_queue.enqueue(
			_profiled_cover_job.bind(
				WOOD_BULLET_COVER.generate_cover_for.bind(target),
				detail
			)
		)

	var church := get_node_or_null("Church") as Node3D
	if church == null:
		church = get_node_or_null("Sketchfab_Scene") as Node3D
	if church != null:
		_setup_queue.enqueue(
			_profiled_cover_job.bind(
				WOOD_PROP_COLLISION.apply_to.bind(church),
				"church_props"
			)
		)

	if HitchProfiler.is_enabled() and _setup_queue.has_signal("drained"):
		_setup_queue.drained.connect(_on_cover_setup_drained, CONNECT_ONE_SHOT)


func _profiled_cover_job(job: Callable, detail: String) -> void:
	var hitch_t := HitchProfiler.begin()
	if job.is_valid():
		job.call()
	HitchProfiler.end(HitchProfiler.LABEL_ZONE_COVER_JOB, hitch_t, detail)


func _on_cover_setup_drained() -> void:
	HitchProfiler.print_summary()


## Until real terrain regions are sculpted in the editor, import a flat region
## at runtime so the zone has a walkable floor. Once the data directory has
## saved regions this is a no-op — editor sculpting replaces it.
func _ensure_terrain_floor() -> void:
	var terrain := get_node_or_null("Terrain/Terrain3D")
	if terrain == null:
		return
	var data: Variant = terrain.get("data")
	if data == null:
		return
	if int(data.call("get_region_count")) > 0:
		return
	var img := Image.create_empty(512, 512, false, Image.FORMAT_RF)
	data.call("import_images", [img, null, null], Vector3(-256.0, 0.0, -256.0), 0.0, 1.0)
	print(
		"RunZone %s: no saved terrain regions — imported flat floor (%d regions)."
		% [zone_id, int(data.call("get_region_count"))]
	)


func _spawn_player() -> void:
	var spawn := get_node_or_null("PlayerSpawn") as Marker3D
	_player = GROYPER_OVERWORLD_PLAYER_SCENE.instantiate()
	add_child(_player)
	if spawn != null:
		_player.global_transform = spawn.global_transform
	if _player.has_method("sync_overworld_spawn_orientation"):
		_player.sync_overworld_spawn_orientation()
	if _player.has_method("set_transition_locked"):
		_player.set_transition_locked(true)
	call_deferred("_finalize_player_spawn")


func _finalize_player_spawn() -> void:
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()


func _bootstrap_terrain_grass_fire() -> void:
	TerrainGrassFireScript.ensure_for_tree(get_tree())


## Temporary test grant so fire-gem grass ignition can be tried without armory.
func _grant_test_fire_gem() -> void:
	if _player_has_fire_gem():
		return
	PlayerInventory.add_elemental_gem(ElementalGems.FIRE)


func _player_has_fire_gem() -> bool:
	if PlayerInventory.count_free_elemental_gem(ElementalGems.FIRE) > 0:
		return true
	for location in PlayerInventory.get_embedded_gem_locations():
		if StringName(str(location.get("gem_id", ""))) == ElementalGems.FIRE:
			return true
	return false


func _start_run_content() -> void:
	# Terrain3D collision is often not queryable until after a physics tick —
	# spawning enemies earlier drops them through the floor.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()
	var director := get_node_or_null("RunDirector")
	if director != null and director.has_method("begin_run"):
		await director.begin_run(_player)
		return
	_spawn_enemies_legacy()


func _spawn_enemies_legacy() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("spawn_enemy"):
			node.spawn_enemy()
