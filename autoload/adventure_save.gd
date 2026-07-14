extends Node

const SAVE_PATH := "user://adventure_save.json"
const SAVE_VERSION := 1
const FADE_DURATION := 0.65

var _loaded_save: Dictionary = {}
var _pending_town_restore := false
var _pending_caves_restore := false
var _pending_bonfire_respawn := false
var _bonfire_respawn_fade_pending := false


func has_save() -> bool:
	return not _loaded_save.is_empty() or FileAccess.file_exists(SAVE_PATH)


func should_restore_on_stage_load() -> bool:
	return _pending_town_restore and has_save_data()


func has_save_data() -> bool:
	if not _loaded_save.is_empty():
		return true
	_load_from_disk()
	return not _loaded_save.is_empty()


func consume_pending_town_restore() -> bool:
	if not _pending_town_restore:
		return false
	_pending_town_restore = false
	return true


func should_restore_on_caves_load() -> bool:
	return _pending_caves_restore and has_save_data()


func consume_pending_caves_restore() -> bool:
	if not _pending_caves_restore:
		return false
	_pending_caves_restore = false
	return true


func capture_and_store(player: Node, stage: Node, return_marker: Marker3D) -> void:
	if _loaded_save.is_empty():
		_load_from_disk()
	var snapshot := _build_snapshot(player, stage, return_marker)
	# Lit bonfires persist for the whole playthrough — carry them across the
	# rebuilt snapshot instead of losing them on stage transitions.
	var lit: Variant = _loaded_save.get("lit_bonfires", [])
	if lit is Array and not (lit as Array).is_empty():
		snapshot["lit_bonfires"] = lit
	_loaded_save = snapshot
	_write_to_disk(snapshot)


func apply_to_player(player: Node, include_transform: bool = false) -> void:
	if _loaded_save.is_empty():
		_load_from_disk()
	if _loaded_save.is_empty():
		return

	_apply_quest_snapshots(_loaded_save.get("quests", {}))
	CompanionManager.apply_snapshot(_loaded_save.get("companions", {}))
	PlayerInventory.apply_snapshot(_loaded_save.get("inventory", {}))

	if not include_transform:
		var player_state: Dictionary = _loaded_save.get("player", {})
		if player.has_method("apply_overworld_snapshot"):
			var state_without_transform := player_state.duplicate(true)
			state_without_transform.erase("transform")
			player.apply_overworld_snapshot(state_without_transform)
		return

	if player.has_method("apply_overworld_snapshot"):
		player.apply_overworld_snapshot(_loaded_save.get("player", {}))


func get_return_spawn_transform() -> Transform3D:
	if _loaded_save.is_empty():
		_load_from_disk()
	var return_data: Dictionary = _loaded_save.get("return", {})
	var position: Variant = return_data.get("position")
	if position is Vector3:
		return _overworld_body_transform_at(position)
	return Transform3D.IDENTITY


static func _overworld_body_transform_at(position: Vector3) -> Transform3D:
	# Match Town/OverworldSpawn: body root carries PI yaw; camera/model sync handles the rest.
	var basis := Basis.from_euler(Vector3(0.0, PI, 0.0))
	return Transform3D(basis, position)


func get_return_stage_path() -> String:
	if _loaded_save.is_empty():
		_load_from_disk()
	return str(_loaded_save.get("return_stage_path", GameState.STAGE1_PATH))


func get_overworld_scenario_id() -> String:
	if _loaded_save.is_empty():
		_load_from_disk()
	return str(_loaded_save.get("overworld_scenario_id", GameState.SCENARIO_NORMAL_TOWN))


func transition_to_caves(player: Node, stage: Node, return_marker: Marker3D) -> void:
	ResourceLoader.load_threaded_request(GameState.CAVES_PATH)
	capture_and_store(player, stage, return_marker)

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	var fade_overlay := _get_fade_overlay(stage)
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = GameState.CAVES_PATH
	await _change_scene_threaded(GameState.CAVES_PATH)


func transition_to_boss_room(player: Node, stage: Node, return_marker: Marker3D) -> void:
	ResourceLoader.load_threaded_request(GameState.CAVES_BOSS_ROOM_PATH)
	sync_runtime_state(player, stage, return_marker)

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	var fade_overlay := _get_fade_overlay(stage)
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = GameState.CAVES_BOSS_ROOM_PATH
	await _change_scene_threaded(GameState.CAVES_BOSS_ROOM_PATH)


func transition_from_boss_room(player: Node, stage: Node) -> void:
	ResourceLoader.load_threaded_request(GameState.CAVES_PATH)
	sync_runtime_state(player, null, null)
	_pending_caves_restore = true

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	var fade_overlay := _get_fade_overlay(stage)
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = GameState.CAVES_PATH
	await _change_scene_threaded(GameState.CAVES_PATH)


func transition_to_town(player: Node, stage: Node) -> void:
	ResourceLoader.load_threaded_request(get_return_stage_path())
	if player != null and stage != null:
		sync_runtime_state(player, stage, null)
	_pending_town_restore = true
	# Caves are treated like interiors: advance outdoor day/night on return.
	DayNightCycle.advance_phase()

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	var fade_overlay := _get_fade_overlay(stage)
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	var stage_path := get_return_stage_path()
	GameState.overworld_scenario_id = get_overworld_scenario_id()
	GameState.selected_game_mode = GameState.GameMode.OVERWORLD
	GameState.pending_stage_path = stage_path
	await _change_scene_threaded(stage_path)


## The scene was requested on a worker thread before the fade started; wait
## for that load to finish instead of blocking the main thread, then swap.
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


func consume_pending_bonfire_respawn() -> bool:
	if not _pending_bonfire_respawn:
		return false
	_pending_bonfire_respawn = false
	_bonfire_respawn_fade_pending = true
	return true


func consume_bonfire_respawn_fade_pending() -> bool:
	if not _bonfire_respawn_fade_pending:
		return false
	_bonfire_respawn_fade_pending = false
	return true


func begin_bonfire_respawn() -> void:
	_pending_bonfire_respawn = true
	if not _loaded_save.is_empty():
		_write_to_disk(_loaded_save)


func set_bonfire_checkpoint(bonfire: Node3D, stage: Node) -> void:
	if _loaded_save.is_empty():
		_load_from_disk()

	var bonfire_path := ""
	if stage != null and bonfire != null and is_instance_valid(bonfire):
		bonfire_path = str(stage.get_path_to(bonfire))

	var checkpoint_id: StringName = &""
	if bonfire is Bonfire:
		checkpoint_id = bonfire.checkpoint_id

	var checkpoint := {
		"bonfire_path": bonfire_path,
		"checkpoint_id": String(checkpoint_id),
		"stage_path": stage.scene_file_path if stage != null else GameState.STAGE1_PATH,
	}
	_loaded_save["bonfire"] = checkpoint
	_write_to_disk(_loaded_save)


func get_bonfire_spawn_transform(stage: Node = null) -> Transform3D:
	if _loaded_save.is_empty():
		_load_from_disk()

	var bonfire_data: Dictionary = _loaded_save.get("bonfire", {})
	if stage != null and not bonfire_data.is_empty():
		var bonfire_path := str(bonfire_data.get("bonfire_path", ""))
		if bonfire_path != "":
			var bonfire := stage.get_node_or_null(bonfire_path) as Node3D
			if bonfire == null:
				bonfire = _resolve_node_through_interior_slot(stage, bonfire_path)
			if bonfire != null:
				return _overworld_body_transform_at(bonfire.global_position)

	return _get_default_home_spawn_transform(stage)


## Checkpoints inside a lazy InteriorZoneSlot ("<slot>/Interior/<rest>") only
## resolve after the slot instantiates its interior.
static func _resolve_node_through_interior_slot(stage: Node, node_path: String) -> Node3D:
	var idx := node_path.find("/Interior/")
	if idx < 0:
		return null
	var slot := stage.get_node_or_null(node_path.substr(0, idx))
	if slot == null or not slot.has_method("ensure_loaded"):
		return null
	if slot.call("ensure_loaded") == null:
		return null
	return stage.get_node_or_null(node_path) as Node3D


func _get_default_home_spawn_transform(stage: Node) -> Transform3D:
	if stage == null:
		return Transform3D.IDENTITY
	var bonfire := stage.get_node_or_null("Church/Bonfire") as Node3D
	if bonfire != null:
		return _overworld_body_transform_at(bonfire.global_position)
	var spawn := stage.get_node_or_null("Church/ChurchSpawn") as Marker3D
	if spawn != null:
		return _overworld_body_transform_at(spawn.global_position)
	return Transform3D.IDENTITY


func get_bonfire_stage_path() -> String:
	if _loaded_save.is_empty():
		_load_from_disk()
	return str(_loaded_save.get("bonfire", {}).get("stage_path", GameState.STAGE1_PATH))


## Once lit, a bonfire stays lit for the rest of the playthrough. Entries are
## JSON-safe dictionaries: {id, name, stage_path, bonfire_path, travelable}.
func mark_bonfire_lit(entry: Dictionary) -> void:
	var id := str(entry.get("id", ""))
	if id == "":
		return
	if _loaded_save.is_empty():
		_load_from_disk()
	var lit: Array = _loaded_save.get("lit_bonfires", [])
	for existing in lit:
		if existing is Dictionary and str(existing.get("id", "")) == id:
			return
	lit.append(entry.duplicate(true))
	_loaded_save["lit_bonfires"] = lit
	_write_to_disk(_loaded_save)


func is_bonfire_lit(id: String) -> bool:
	if id == "":
		return false
	if _loaded_save.is_empty():
		_load_from_disk()
	for entry in _loaded_save.get("lit_bonfires", []):
		if entry is Dictionary and str(entry.get("id", "")) == id:
			return true
	return false


func get_lit_bonfires() -> Array[Dictionary]:
	if _loaded_save.is_empty():
		_load_from_disk()
	var result: Array[Dictionary] = []
	for entry in _loaded_save.get("lit_bonfires", []):
		if entry is Dictionary:
			result.append((entry as Dictionary).duplicate(true))
	return result


## True when the death checkpoint sits inside a lazy-loaded interior (e.g. the
## hotel fireplace) — respawns there need the interior camera/session.
func is_bonfire_checkpoint_interior() -> bool:
	if _loaded_save.is_empty():
		_load_from_disk()
	var bonfire_path := str(_loaded_save.get("bonfire", {}).get("bonfire_path", ""))
	return bonfire_path.contains("/Interior/")


func has_bonfire_checkpoint() -> bool:
	if _loaded_save.is_empty():
		_load_from_disk()
	var bonfire_data: Dictionary = _loaded_save.get("bonfire", {})
	return bonfire_data.has("bonfire_path") and str(bonfire_data.get("bonfire_path", "")) != ""


func get_bonfire_checkpoint_id() -> String:
	if _loaded_save.is_empty():
		_load_from_disk()
	return str(_loaded_save.get("bonfire", {}).get("checkpoint_id", ""))


func clear_save() -> void:
	_loaded_save = {}
	_pending_town_restore = false
	_pending_caves_restore = false
	_pending_bonfire_respawn = false
	_bonfire_respawn_fade_pending = false
	PlayerDeathLoot.clear_active_loot()
	CompanionManager.apply_snapshot({})
	for quest in _quest_states():
		quest.reset()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


func sync_runtime_state(player: Node, stage: Node, return_marker: Marker3D = null) -> void:
	if _loaded_save.is_empty():
		_load_from_disk()
	if _loaded_save.is_empty():
		capture_and_store(player, stage, return_marker)
		return

	if player != null and player.has_method("capture_overworld_snapshot"):
		_loaded_save["player"] = player.capture_overworld_snapshot()
	_loaded_save["companions"] = CompanionManager.capture_snapshot()
	_loaded_save["inventory"] = PlayerInventory.capture_snapshot()
	_loaded_save["quests"] = _capture_quest_snapshots()
	if return_marker != null:
		_loaded_save["return"] = {"position": return_marker.global_transform.origin}
	if stage != null:
		_loaded_save["return_stage_path"] = stage.scene_file_path
	_write_to_disk(_loaded_save)


func _build_snapshot(player: Node, stage: Node, return_marker: Marker3D) -> Dictionary:
	var player_snapshot: Dictionary = {}
	if player.has_method("capture_overworld_snapshot"):
		player_snapshot = player.capture_overworld_snapshot()

	var return_transform := Transform3D.IDENTITY
	if return_marker != null:
		return_transform = return_marker.global_transform

	return {
		"version": SAVE_VERSION,
		"return_stage_path": stage.scene_file_path if stage != null else GameState.STAGE1_PATH,
		"overworld_scenario_id": GameState.overworld_scenario_id,
		"return": {
			"position": return_transform.origin,
		},
		"inventory": PlayerInventory.capture_snapshot(),
		"player": player_snapshot,
		"quests": _capture_quest_snapshots(),
		"companions": CompanionManager.capture_snapshot(),
	}


# Every autoload extending quest_state_base.gd is in this group and
# saves/loads/resets itself — new quests need no changes here.
func _quest_states() -> Array:
	return get_tree().get_nodes_in_group("quest_state")


func _capture_quest_snapshots() -> Dictionary:
	var snapshots := {}
	for quest in _quest_states():
		snapshots[quest.get_save_key()] = quest.capture_snapshot()
	return snapshots


func _apply_quest_snapshots(quest_data: Dictionary) -> void:
	for quest in _quest_states():
		var data: Dictionary = quest_data.get(quest.get_save_key(), {})
		if not data.is_empty():
			quest.apply_snapshot(data)


func _write_to_disk(snapshot: Dictionary) -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("AdventureSave: failed to write %s" % SAVE_PATH)
		return
	file.store_string(JSON.stringify(snapshot, "\t"))


func _load_from_disk() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		_loaded_save = {}
		return

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("AdventureSave: failed to read %s" % SAVE_PATH)
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if parsed is Dictionary:
		var version := int(parsed.get("version", 0))
		if version > SAVE_VERSION:
			push_warning("AdventureSave: save version %d is newer than supported %d; ignoring save" % [version, SAVE_VERSION])
			_loaded_save = {}
			return
		_loaded_save = parsed
	else:
		_loaded_save = {}


func _get_fade_overlay(stage: Node) -> ColorRect:
	if stage != null and stage.has_method("get_duel_fade_overlay"):
		return stage.get_duel_fade_overlay()
	return null
