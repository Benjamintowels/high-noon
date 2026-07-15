extends Node

## Roguelike-mode session state. Deliberately NOT a quest_state autoload: nothing
## here is ever written to adventure_save.json — Story Mode's save file must be
## untouched by Roguelike sessions, and run state must die with the run.
##
## Lifecycle:
##   Main menu "Roguelike"  -> begin_roguelike_session() -> hub loads
##   Hub run gate           -> travel_to_zone()           -> zone loads
##   Zone exit gate         -> return_to_hub(victory)     -> hub loads at gate
##   Death anywhere in mode -> handle_player_death()      -> hub loads at spawn
## Leaving via the main menu / Story Mode resets everything.

const HUBWORLD_PATH := "res://stages/hubworld/hubworld.tscn"

## Zone registry: id -> {path, title}. Progression hooks in later; for now all
## four gates are open from the start.
const ZONES := {
	"zone_1": {
		"path": "res://stages/runs/zone_1.tscn",
		"title": "The Dry Gulch",
	},
	"zone_2": {
		"path": "res://stages/runs/zone_2.tscn",
		"title": "The Bone Flats",
	},
	"zone_3": {
		"path": "res://stages/runs/zone_3.tscn",
		"title": "The Red Mesa",
	},
	"zone_4": {
		"path": "res://stages/runs/zone_4.tscn",
		"title": "The Dead Forest",
	},
}

## True from the moment the player picks Roguelike on the main menu until they
## leave the mode. Gates the player death path away from bonfire checkpoints.
var roguelike_active := false
## True only while inside a run zone.
var run_active := false
var current_zone_id := ""

## Hub read-once flags: which spawn to use when hubworld.tscn loads.
var _pending_return_zone_id := ""
var _pending_death_return := false
var _death_fade_pending := false

## Run results log for future meta-progression ({zone_id, victory} entries).
var completed_runs: Array[Dictionary] = []


func begin_roguelike_session() -> void:
	roguelike_active = true
	run_active = false
	current_zone_id = ""
	_pending_return_zone_id = ""
	_pending_death_return = false
	_death_fade_pending = false
	completed_runs.clear()


func end_roguelike_session() -> void:
	roguelike_active = false
	run_active = false
	current_zone_id = ""
	_pending_return_zone_id = ""
	_pending_death_return = false
	_death_fade_pending = false


func is_run_active() -> bool:
	return run_active


func get_zone_title(zone_id: String) -> String:
	var zone: Dictionary = ZONES.get(zone_id, {})
	return str(zone.get("title", "Unknown Territory"))


func get_zone_path(zone_id: String) -> String:
	var zone: Dictionary = ZONES.get(zone_id, {})
	return str(zone.get("path", ""))


## Hub gate crossing: mark the run active and swap to the zone scene. The gate
## drives the walk/fade cinematic and awaits this once the screen is black.
func travel_to_zone(zone_id: String) -> void:
	var path := get_zone_path(zone_id)
	if path == "":
		push_warning("RunState: unknown zone id '%s'." % zone_id)
		return
	run_active = true
	current_zone_id = zone_id
	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = path
	await _change_scene_threaded(path)


## Zone exit gate: bank the result and return to the hub, spawning at the gate
## the run started from.
func return_to_hub(victory: bool = true) -> void:
	if run_active:
		completed_runs.append({"zone_id": current_zone_id, "victory": victory})
	_pending_return_zone_id = current_zone_id
	run_active = false
	current_zone_id = ""
	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = HUBWORLD_PATH
	await _change_scene_threaded(HUBWORLD_PATH)


## Player death anywhere in roguelike mode. Called from the death cinematic —
## the caller performs the actual change_scene while the screen is black.
func handle_player_death() -> void:
	if run_active:
		completed_runs.append({"zone_id": current_zone_id, "victory": false})
	run_active = false
	current_zone_id = ""
	_pending_return_zone_id = ""
	_pending_death_return = true
	_death_fade_pending = true
	# Run loot bags die with the run scene — no corpse runs in roguelike mode.
	PlayerDeathLoot.clear_active_loot()


## Hub _ready: zone id of the gate to spawn at, or "" for the default spawn.
## Consuming clears it.
func consume_pending_return_zone() -> String:
	var zone_id := _pending_return_zone_id
	_pending_return_zone_id = ""
	return zone_id


func consume_pending_death_return() -> bool:
	if not _pending_death_return:
		return false
	_pending_death_return = false
	return true


## Hub fade-in handoff after a death return (mirrors the bonfire respawn fade).
func consume_death_fade_pending() -> bool:
	if not _death_fade_pending:
		return false
	_death_fade_pending = false
	return true


## Threaded load + swap, same pattern as AdventureSave/_BonfireTravelManager.
## Callers should have requested the load before fading so this rarely blocks.
func request_scene_preload(scene_path: String) -> void:
	if scene_path != "":
		ResourceLoader.load_threaded_request(scene_path)


func _change_scene_threaded(scene_path: String) -> void:
	while true:
		var status := ResourceLoader.load_threaded_get_status(scene_path)
		if status == ResourceLoader.THREAD_LOAD_LOADED:
			break
		if status == ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			await get_tree().process_frame
			continue
		# No request in flight or it failed — fall back to a blocking load.
		get_tree().change_scene_to_file(scene_path)
		return

	var packed := ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed == null:
		get_tree().change_scene_to_file(scene_path)
		return
	get_tree().change_scene_to_packed(packed)
