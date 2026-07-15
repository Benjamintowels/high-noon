extends Node3D

## Shared driver for roguelike run zones. A zone is a self-contained scene the
## player walks into from a hub gate and leaves through an exit gate (or by
## dying — death returns to the hub, never a bonfire; there are no checkpoints
## mid-run).
##
## Scene contract (see zone_1.tscn):
## - PlayerSpawn Marker3D
## - Enemies host node in group "cave_enemy_root" with cave_enemy_spawn markers
## - an Area3D with run_gate.gd (destination = HUB) as the exit
## - FadeLayer/FadeOverlay ColorRect
## - WorldEnvironment named "WorldEnvironment" (death desaturation looks it up)

const FADE_IN_DURATION := 1.25
const GROYPER_OVERWORLD_PLAYER_SCENE := preload(
	"res://characters/groyper/groyper_overworld_player.tscn"
)
const FxCatalogScript := preload("res://gameplay/fx/fx_catalog.gd")

@export var zone_id := ""

@onready var _fade_overlay: ColorRect = $FadeLayer/FadeOverlay

var _player: Node3D


func _ready() -> void:
	FxCatalogScript.warm_all()
	add_to_group("run_zone_stage")
	# Direct-boot support (editor F6): register the run so gates/death work.
	if not RunState.roguelike_active:
		RunState.begin_roguelike_session()
	if not RunState.is_run_active() and zone_id != "":
		RunState.run_active = true
		RunState.current_zone_id = zone_id
	ShopSession.reset_for_outdoor_spawn()
	DayNightCycle.bind_outdoor_scene($Sun)

	_fade_overlay.modulate.a = 1.0
	_spawn_player()
	call_deferred("_spawn_enemies")

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


func _spawn_enemies() -> void:
	for node in get_tree().get_nodes_in_group("cave_enemy_spawn"):
		if node.has_method("spawn_enemy"):
			node.spawn_enemy()
