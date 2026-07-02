extends Node

const SAVE_PATH := "user://adventure_save.json"
const SAVE_VERSION := 1
const FADE_DURATION := 0.65

var _loaded_save: Dictionary = {}
var _pending_town_restore := false


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


func capture_and_store(player: Node, stage: Node, return_marker: Marker3D) -> void:
	var snapshot := _build_snapshot(player, stage, return_marker)
	_loaded_save = snapshot
	_write_to_disk(snapshot)


func apply_to_player(player: Node, include_transform: bool = false) -> void:
	if _loaded_save.is_empty():
		_load_from_disk()
	if _loaded_save.is_empty():
		return

	_apply_quest_snapshots(_loaded_save.get("quests", {}))
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
	get_tree().change_scene_to_file(GameState.CAVES_PATH)


func transition_to_town(player: Node, stage: Node) -> void:
	_pending_town_restore = true

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
	get_tree().change_scene_to_file(stage_path)


func clear_save() -> void:
	_loaded_save = {}
	_pending_town_restore = false
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)


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
	}


func _capture_quest_snapshots() -> Dictionary:
	return {
		"cow_wrangle": {
			"active": CowWrangleQuest.active,
			"accepted": CowWrangleQuest.accepted,
			"completed": CowWrangleQuest.completed,
			"wrangled_count": CowWrangleQuest.wrangled_count,
		},
		"pink_tree_treasure": {
			"accepted": PinkTreeTreasureQuest.accepted,
		},
	}


func _apply_quest_snapshots(quest_data: Dictionary) -> void:
	var cow: Dictionary = quest_data.get("cow_wrangle", {})
	if not cow.is_empty():
		CowWrangleQuest.active = bool(cow.get("active", false))
		CowWrangleQuest.accepted = bool(cow.get("accepted", false))
		CowWrangleQuest.completed = bool(cow.get("completed", false))
		CowWrangleQuest.wrangled_count = int(cow.get("wrangled_count", 0))
		if CowWrangleQuest.accepted:
			CowWrangleQuest.wrangle_count_changed.emit(
				CowWrangleQuest.wrangled_count,
				CowWrangleQuest.REQUIRED_COWS
			)

	var pink_tree: Dictionary = quest_data.get("pink_tree_treasure", {})
	if not pink_tree.is_empty():
		PinkTreeTreasureQuest.accepted = bool(pink_tree.get("accepted", false))


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
		_loaded_save = parsed
	else:
		_loaded_save = {}


func _get_fade_overlay(stage: Node) -> ColorRect:
	if stage != null and stage.has_method("get_duel_fade_overlay"):
		return stage.get_duel_fade_overlay()
	return null
