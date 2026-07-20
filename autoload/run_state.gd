extends Node

## Roguelike-mode session state. Never writes adventure_save.json — Story Mode
## stays untouched. Hub/meta progress persists via RoguelikeSave
## (user://roguelike_save.json).
##
## Lifecycle:
##   Main menu "Roguelike"  -> begin_roguelike_session() -> hub loads
##   Hub run gate           -> travel_to_zone()           -> zone loads
##   Zone exit gate         -> present_run_results(true)  -> hub loads at gate
##   Death anywhere in mode -> present_run_results(false) -> hub loads at spawn
## Leaving via the main menu / Story Mode resets everything.

const HUBWORLD_PATH := "res://stages/hubworld/hubworld.tscn"
const RunResultsScreenScript := preload("res://ui/scripts/run_results_screen.gd")
const RunWeaponExtractMenuScript := preload("res://ui/scripts/run_weapon_extract_menu.gd")

## Zone registry: id -> {path, title}.
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

## zone_id -> prerequisite zone that must be won this session. Empty = always open.
const ZONE_UNLOCK_REQUIREMENTS := {
	"zone_1": "",
	"zone_2": "zone_1",
	"zone_3": "zone_1",
	"zone_4": "zone_1",
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

## Per-run stats for the results screen (gross earned / kills).
var run_kills := 0
var run_gram_collected := 0
var run_soul_shards_collected := 0
var gram_chests_opened := 0
var shard_chests_opened := 0
var run_quest_items: Array[StringName] = []
var horsey_spawned_this_run := false
## Kills since last gem-enemy spawn (pity; guaranteed within 50).
var gem_enemy_pity := 0
## True if the zone boss was defeated this run (subquest; extract still optional).
var run_boss_defeated_this_run := false

var _extracting := false


## Start a Roguelike session. When load_existing_save is true, restore disk
## progress (Continue); otherwise wipe memory state for a fresh New Game.
func begin_roguelike_session(load_existing_save: bool = false) -> void:
	roguelike_active = true
	run_active = false
	current_zone_id = ""
	_pending_return_zone_id = ""
	_pending_death_return = false
	_death_fade_pending = false
	_extracting = false
	reset_run_counters()
	if load_existing_save and RoguelikeSave.has_save() and RoguelikeSave.load_session():
		return
	completed_runs.clear()
	_reset_meta_progress()


func end_roguelike_session() -> void:
	roguelike_active = false
	run_active = false
	current_zone_id = ""
	_pending_return_zone_id = ""
	_pending_death_return = false
	_death_fade_pending = false
	_extracting = false
	reset_run_counters()
	_reset_meta_progress()


func _reset_meta_progress() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return
	var meta := tree.root.get_node_or_null("RunMetaProgress")
	if meta != null and meta.has_method("reset_for_session"):
		meta.reset_for_session()


func reset_run_counters() -> void:
	run_kills = 0
	run_gram_collected = 0
	run_soul_shards_collected = 0
	gram_chests_opened = 0
	shard_chests_opened = 0
	run_quest_items.clear()
	horsey_spawned_this_run = false
	gem_enemy_pity = 0
	run_boss_defeated_this_run = false


func is_run_active() -> bool:
	return run_active


func has_completed_zone(zone_id: String) -> bool:
	if zone_id == "":
		return false
	for entry in completed_runs:
		if str(entry.get("zone_id", "")) == zone_id and bool(entry.get("victory", false)):
			return true
	return false


func record_zone_result(zone_id: String, victory: bool) -> void:
	if zone_id == "":
		return
	completed_runs.append({"zone_id": zone_id, "victory": victory})


func is_zone_unlocked(zone_id: String) -> bool:
	if zone_id == "" or not ZONES.has(zone_id):
		return false
	var requirement := str(ZONE_UNLOCK_REQUIREMENTS.get(zone_id, ""))
	if requirement == "":
		return true
	return has_completed_zone(requirement)


func get_unlock_requirement_title(zone_id: String) -> String:
	var requirement := str(ZONE_UNLOCK_REQUIREMENTS.get(zone_id, ""))
	if requirement == "":
		return ""
	return get_zone_title(requirement)


func get_zone_title(zone_id: String) -> String:
	var zone: Dictionary = ZONES.get(zone_id, {})
	return str(zone.get("title", "Unknown Territory"))


func get_zone_path(zone_id: String) -> String:
	var zone: Dictionary = ZONES.get(zone_id, {})
	return str(zone.get("path", ""))


func record_kill() -> void:
	if not run_active:
		return
	run_kills += 1
	var director: Variant = get_meta("active_run_director", null)
	if director != null and is_instance_valid(director):
		if director.has_method("on_player_kill"):
			director.call("on_player_kill")
		elif director.has_method("on_player_kill_for_gem_enemy"):
			director.call("on_player_kill_for_gem_enemy")


func note_boss_defeated() -> void:
	if not run_active:
		return
	run_boss_defeated_this_run = true


func has_defeated_zone_boss(zone_id: String) -> bool:
	if zone_id == "":
		return false
	return RunMetaProgress.has_hub_quest_flag(StringName("%s_boss_defeated" % zone_id))


func record_gram_collected(amount: int) -> void:
	if not run_active or amount <= 0:
		return
	run_gram_collected += amount


func record_soul_shards_collected(amount: int) -> void:
	if not run_active or amount <= 0:
		return
	run_soul_shards_collected += amount


func add_run_quest_item(item_id: StringName) -> void:
	if not run_active or item_id.is_empty():
		return
	if run_quest_items.has(item_id):
		return
	run_quest_items.append(item_id)


func get_gram_chest_cost(base_cost: int, mult: float) -> int:
	return _escalating_cost(base_cost, mult, gram_chests_opened)


func get_shard_chest_cost(base_cost: int, mult: float) -> int:
	return _escalating_cost(base_cost, mult, shard_chests_opened)


func note_gram_chest_opened() -> void:
	gram_chests_opened += 1


func note_shard_chest_opened() -> void:
	shard_chests_opened += 1


func _escalating_cost(base_cost: int, mult: float, opens: int) -> int:
	var safe_base := maxi(base_cost, 1)
	var safe_mult := maxf(mult, 1.0)
	return maxi(1, int(round(float(safe_base) * pow(safe_mult, float(opens)))))


## Hub gate crossing: bank hub cash, zero the run wallet, mark the run active.
func travel_to_zone(zone_id: String) -> void:
	var path := get_zone_path(zone_id)
	if path == "":
		push_warning("RunState: unknown zone id '%s'." % zone_id)
		return
	RunMetaProgress.deposit_inventory_to_bank()
	reset_run_counters()
	run_active = true
	current_zone_id = zone_id
	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = path
	await _change_scene_threaded(path)


## Victory portal / death: show results, extract currency, then load hub.
func return_to_hub(victory: bool = true) -> void:
	await present_run_results(victory)


## Player death anywhere in roguelike mode. Called from the death cinematic —
## presents the results screen, then loads the hub while the screen is black.
func handle_player_death() -> void:
	await present_run_results(false)


func present_run_results(victory: bool) -> void:
	if _extracting:
		return
	_extracting = true

	var zone_id := current_zone_id
	var zone_title := get_zone_title(zone_id) if zone_id != "" else "The Run"

	var wallet_gram := PlayerInventory.gram
	var wallet_shards := PlayerInventory.get_soul_shards()
	var extract_gram := wallet_gram
	var extract_shards := wallet_shards
	if not victory:
		extract_gram = int(floor(float(wallet_gram) * 0.5))
		extract_shards = int(floor(float(wallet_shards) * 0.5))

	var quest_preview: Array[StringName] = []
	if victory:
		quest_preview = run_quest_items.duplicate()

	var payload := {
		"victory": victory,
		"zone_title": zone_title,
		"kills": run_kills,
		"gram_collected": run_gram_collected,
		"soul_shards_collected": run_soul_shards_collected,
		"wallet_gram": wallet_gram,
		"wallet_shards": wallet_shards,
		"extract_gram": extract_gram,
		"extract_shards": extract_shards,
		"quest_items": quest_preview,
	}

	DeathOverlayManager.prepare_for_scene_reload()
	PlayerDeathLoot.clear_active_loot()

	var screen: Node = RunResultsScreenScript.new()
	get_tree().root.add_child(screen)
	await screen.play_results(payload)
	if is_instance_valid(screen):
		screen.queue_free()

	await _apply_weapon_extract(victory)

	RunMetaProgress.bank_extracted(extract_gram, extract_shards)
	if victory:
		RunMetaProgress.extract_quest_items(run_quest_items)
		# Kill-goal extract completes the zone; boss subquest is separate.
		if run_boss_defeated_this_run and zone_id != "":
			RunMetaProgress.set_hub_quest_flag(StringName("%s_boss_defeated" % zone_id), true)
	run_quest_items.clear()

	if run_active and zone_id != "":
		completed_runs.append({"zone_id": zone_id, "victory": victory})

	if victory:
		_pending_return_zone_id = zone_id
		_pending_death_return = false
		_death_fade_pending = false
	else:
		_pending_return_zone_id = ""
		_pending_death_return = true
		_death_fade_pending = true

	run_active = false
	current_zone_id = ""
	reset_run_counters()
	_extracting = false

	# Persist hub bank / zone unlocks / kept loadout before the scene swap.
	RoguelikeSave.save_session()

	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = HUBWORLD_PATH
	await _change_scene_threaded(HUBWORLD_PATH)


## Death: strip all run weapons. Victory: keep one chosen weapon (or starting
## revolver if they skip / only had one type).
func _apply_weapon_extract(victory: bool) -> void:
	if not victory:
		PlayerInventory.reset_weapons_after_failed_extract()
		return

	var extractable := PlayerInventory.get_extractable_weapons()
	if extractable.is_empty():
		PlayerInventory.reset_weapons_after_failed_extract()
		return
	if extractable.size() == 1:
		PlayerInventory.keep_only_extracted_weapon(extractable[0])
		return

	var menu: Node = RunWeaponExtractMenuScript.new()
	get_tree().root.add_child(menu)
	var chosen: int = await menu.pick_weapon(extractable)
	if is_instance_valid(menu):
		menu.queue_free()
	if chosen < 0:
		PlayerInventory.reset_weapons_after_failed_extract()
	else:
		PlayerInventory.keep_only_extracted_weapon(chosen)


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
