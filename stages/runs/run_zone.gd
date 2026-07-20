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
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")
const STAGE1_VISUAL_SETUP := preload("res://stages/stage1/stage1_visual_setup.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")

@export var zone_id := ""

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay

var _player: Node3D


func _ready() -> void:
	FxCatalogScript.warm_all()
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
	STAGE1_VISUAL_SETUP.apply_materials(self)
	_setup_prop_collision()

	_fade_overlay.modulate.a = 1.0
	_spawn_player()
	call_deferred("_start_run_content")

	await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_fade_overlay, "modulate:a", 0.0, FADE_IN_DURATION)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished

	if _player != null and _player.has_method("set_transition_locked"):
		_player.set_transition_locked(false)


func _exit_tree() -> void:
	DayNightCycle.unbind_outdoor_scene($Sun)


func get_duel_fade_overlay() -> ColorRect:
	return _fade_overlay


func get_run_player() -> Node3D:
	return _player


## Building trimesh cover (Build_*) plus church PropCollision — same pass
## hubworld/stage1 use for walkable walls and bullet impact surfaces.
func _setup_prop_collision() -> void:
	WOOD_BULLET_COVER.apply_to(self)
	var church := get_node_or_null("Church") as Node3D
	if church == null:
		church = get_node_or_null("Sketchfab_Scene") as Node3D
	if church != null:
		WOOD_PROP_COLLISION.apply_to(church)


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


func _start_run_content() -> void:
	# Terrain3D collision is often not queryable until after a physics tick —
	# spawning enemies earlier drops them through the floor.
	await get_tree().physics_frame
	await get_tree().physics_frame
	if _player != null and is_instance_valid(_player) and _player.has_method("snap_to_floor"):
		_player.snap_to_floor()
	var director := get_node_or_null("RunDirector")
	if director != null and director.has_method("begin_run"):
		director.begin_run(_player)
		return
	_spawn_enemies_legacy()


func _spawn_enemies_legacy() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("spawn_enemy"):
			node.spawn_enemy()
