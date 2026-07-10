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
	var snapshot := _build_snapshot(player, stage, return_marker)
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


func transition_to_boss_room(player: Node, stage: Node, return_marker: Marker3D) -> void:
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
	get_tree().change_scene_to_file(GameState.CAVES_BOSS_ROOM_PATH)


func transition_from_boss_room(player: Node, stage: Node) -> void:
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
	get_tree().change_scene_to_file(GameState.CAVES_PATH)


func transition_to_town(player: Node, stage: Node) -> void:
	if player != null and stage != null:
		sync_runtime_state(player, stage, null)
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
			if bonfire != null:
				return _overworld_body_transform_at(bonfire.global_position)

	return _get_default_home_spawn_transform(stage)


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


func has_bonfire_checkpoint() -> bool:
	if _loaded_save.is_empty():
		_load_from_disk()
	var bonfire_data: Dictionary = _loaded_save.get("bonfire", {})
	return bonfire_data.has("bonfire_path") and str(bonfire_data.get("bonfire_path", "")) != ""


func clear_save() -> void:
	_loaded_save = {}
	_pending_town_restore = false
	_pending_caves_restore = false
	_pending_bonfire_respawn = false
	_bonfire_respawn_fade_pending = false
	PlayerDeathLoot.clear_active_loot()
	CompanionManager.apply_snapshot({})
	HorseyProgress.reset_progress()
	BanditAmbushProgress.reset_progress()
	CometProgress.reset_progress()
	HotelBrawlProgress.reset_progress()
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
		"blacksmith": BlacksmithProgress.capture_snapshot(),
		"horsey": HorseyProgress.capture_snapshot(),
		"bandit_ambush": BanditAmbushProgress.capture_snapshot(),
		"comet_cinematic": CometProgress.capture_snapshot(),
		"hotel_brawl": HotelBrawlProgress.capture_snapshot(),
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

	var blacksmith: Dictionary = quest_data.get("blacksmith", {})
	if not blacksmith.is_empty():
		BlacksmithProgress.apply_snapshot(blacksmith)

	var horsey: Dictionary = quest_data.get("horsey", {})
	if not horsey.is_empty():
		HorseyProgress.apply_snapshot(horsey)

	var bandit_ambush: Dictionary = quest_data.get("bandit_ambush", {})
	if not bandit_ambush.is_empty():
		BanditAmbushProgress.apply_snapshot(bandit_ambush)

	var comet_cinematic: Dictionary = quest_data.get("comet_cinematic", {})
	if not comet_cinematic.is_empty():
		CometProgress.apply_snapshot(comet_cinematic)

	var hotel_brawl: Dictionary = quest_data.get("hotel_brawl", {})
	if not hotel_brawl.is_empty():
		HotelBrawlProgress.apply_snapshot(hotel_brawl)


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
