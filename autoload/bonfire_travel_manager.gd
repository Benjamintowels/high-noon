extends Node

## Fast travel between bonfires the player has lit. Plays a letterboxed
## fade-to-black cinematic, then either teleports within the current stage or
## swaps scenes and lets the destination stage spawn the player at the bonfire.

# The hotel is home base — unlocked as a destination at new-game spawn rather
# than by lighting a bonfire. Its interior lazy-loads, so arrival resolves the
# spawn marker through the InteriorZoneSlot instead of a bonfire node.
const HOTEL_TRAVEL_ENTRY := {
	"id": "hotel",
	"name": "Hotel",
	"stage_path": "res://stages/stage1/stage1.tscn",
	"interior_slot": "ShopInteriors/NewGameHotelInterior",
	"spawn_marker": "FastTravelSpawn",
	"travelable": true,
}

const BAR_HEIGHT := 130.0
const BAR_TIME := 0.4
const FADE_OUT_TIME := 0.65
const FADE_IN_TIME := 0.9
const BLACK_HOLD_TIME := 0.25

var _layer: CanvasLayer
var _top_bar: ColorRect
var _bottom_bar: ColorRect
var _fade_rect: ColorRect
var _traveling := false
var _pending_travel: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_layer = CanvasLayer.new()
	_layer.layer = 110
	_layer.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.name = "TravelFade"
	_fade_rect.color = Color.BLACK
	_fade_rect.modulate.a = 0.0
	_fade_rect.visible = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_layer.add_child(_fade_rect)

	_top_bar = _make_bar("TravelLetterboxTop", Control.PRESET_TOP_WIDE)
	_bottom_bar = _make_bar("TravelLetterboxBottom", Control.PRESET_BOTTOM_WIDE)


func _make_bar(bar_name: String, preset: Control.LayoutPreset) -> ColorRect:
	var bar := ColorRect.new()
	bar.name = bar_name
	bar.color = Color.BLACK
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.set_anchors_preset(preset)
	bar.visible = false
	_layer.add_child(bar)
	return bar


func is_traveling() -> bool:
	return _traveling


func has_pending_travel() -> bool:
	return not _pending_travel.is_empty()


func consume_pending_travel() -> Dictionary:
	var travel := _pending_travel
	_pending_travel = {}
	return travel


func travel_to(entry: Dictionary, player: Node3D) -> void:
	if _traveling or entry.is_empty():
		return
	var target_stage_path := str(entry.get("stage_path", ""))
	if target_stage_path == "":
		return
	_traveling = true

	var tree := get_tree()
	var stage := tree.current_scene
	var same_stage := stage != null and target_stage_path == stage.scene_file_path
	if not same_stage:
		ResourceLoader.load_threaded_request(target_stage_path)

	if player != null and player.has_method("set_transition_locked"):
		player.set_transition_locked(true)
	AdventureSave.sync_runtime_state(player, null)

	await _show_bars()
	await _fade_to_black()

	# Snap day/night while the screen is black so the reveal already shows
	# the new phase. Interior destinations defer until door exit.
	if str(entry.get("interior_slot", "")) == "":
		DayNightCycle.advance_phase()

	if same_stage:
		_teleport_within_stage(stage, player, entry)
		_sync_canyon_zone_for_travel(stage, entry)
		await tree.create_timer(BLACK_HOLD_TIME).timeout
	else:
		_pending_travel = entry.duplicate(true)
		GameState.selected_game_mode = GameState.GameMode.OVERWORLD
		GameState.pending_stage_path = target_stage_path
		await _change_scene_threaded(target_stage_path)
		# Let the destination stage build itself (its own fade overlay starts
		# fully black underneath ours) before revealing it.
		await tree.process_frame
		await tree.process_frame

	await _fade_from_black()
	await _hide_bars()

	if same_stage and player != null and is_instance_valid(player) \
			and player.has_method("set_transition_locked"):
		player.set_transition_locked(false)
	_traveling = false


func get_travel_spawn_transform(stage: Node, entry: Dictionary) -> Transform3D:
	var interior_marker := _find_interior_spawn_marker(stage, entry)
	if interior_marker != null:
		return _overworld_body_transform_at(interior_marker.global_position)
	var bonfire := find_bonfire_in_stage(stage, entry)
	if bonfire != null:
		var stand_pos := bonfire.global_position
		if bonfire.has_method("get_respawn_global_position"):
			stand_pos = bonfire.get_respawn_global_position()
		return _overworld_body_transform_at(stand_pos)
	return Transform3D.IDENTITY


func _find_interior_spawn_marker(stage: Node, entry: Dictionary) -> Marker3D:
	var slot_path := str(entry.get("interior_slot", ""))
	if stage == null or slot_path == "":
		return null
	var slot := stage.get_node_or_null(slot_path)
	if slot == null or not slot.has_method("ensure_loaded"):
		return null
	var interior := slot.call("ensure_loaded") as Node3D
	if interior == null:
		return null
	var marker_name := str(entry.get("spawn_marker", ""))
	var marker: Marker3D = null
	if marker_name != "":
		marker = interior.get_node_or_null(marker_name) as Marker3D
	if marker == null:
		marker = interior.get_node_or_null("InteriorSpawn") as Marker3D
	return marker


func find_bonfire_in_stage(stage: Node, entry: Dictionary) -> Node3D:
	var bonfire_path := str(entry.get("bonfire_path", ""))
	if stage != null and bonfire_path != "":
		var node := stage.get_node_or_null(bonfire_path) as Node3D
		if node != null:
			return node

	var id := str(entry.get("id", ""))
	if id == "":
		return null
	for node in get_tree().get_nodes_in_group("bonfire"):
		if node is Node3D and str(node.get("checkpoint_id")) == id:
			return node as Node3D
	return null


static func _overworld_body_transform_at(position: Vector3) -> Transform3D:
	# Match overworld spawns: body root carries PI yaw; camera/model sync handles the rest.
	var basis := Basis.from_euler(Vector3(0.0, PI, 0.0))
	return Transform3D(basis, position)


func _teleport_within_stage(stage: Node, player: Node3D, entry: Dictionary) -> void:
	if player == null or not is_instance_valid(player):
		return
	var spawn := get_travel_spawn_transform(stage, entry)
	if spawn == Transform3D.IDENTITY:
		return
	player.global_transform = spawn
	if player.has_method("sync_overworld_spawn_orientation"):
		player.sync_overworld_spawn_orientation()
	if player.has_method("snap_to_floor"):
		player.snap_to_floor()
	if str(entry.get("interior_slot", "")) != "":
		# Arriving inside an interior — engage the interior camera and home
		# music the way a door entry would.
		if player.has_method("prepare_interior_spawn_camera"):
			player.prepare_interior_spawn_camera()
		ShopSession.start_home_music()


func _sync_canyon_zone_for_travel(stage: Node, entry: Dictionary) -> void:
	if stage == null:
		return
	var transition := stage.get_node_or_null("CanyonGateTransition")
	if transition == null:
		return
	var travel_id := str(entry.get("id", ""))
	if transition.has_method("sync_from_travel_id"):
		transition.sync_from_travel_id(travel_id)
	elif transition.has_method("sync_from_player_position"):
		transition.sync_from_player_position()


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


func _show_bars() -> void:
	_top_bar.visible = true
	_bottom_bar.visible = true
	_top_bar.offset_bottom = 0.0
	_bottom_bar.offset_top = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_top_bar, "offset_bottom", BAR_HEIGHT, BAR_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(_bottom_bar, "offset_top", -BAR_HEIGHT, BAR_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished


func _hide_bars() -> void:
	var tween := create_tween().set_parallel(true)
	tween.tween_property(_top_bar, "offset_bottom", 0.0, BAR_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tween.tween_property(_bottom_bar, "offset_top", 0.0, BAR_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished
	_top_bar.visible = false
	_bottom_bar.visible = false


func _fade_to_black() -> void:
	_fade_rect.visible = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 1.0, FADE_OUT_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	await tween.finished


func _fade_from_black() -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", 0.0, FADE_IN_TIME)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	await tween.finished
	_fade_rect.visible = false
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
