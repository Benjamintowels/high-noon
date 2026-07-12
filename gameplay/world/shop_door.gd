extends Area3D

enum DoorMode { ENTER, EXIT }

const FADE_DURATION := 0.5
const INTERACT_RANGE := 2.75
const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const DEFAULT_SHOP_MUSIC: AudioStream = preload("res://Assets/Sounds/Music/ShopMusic.mp3")
const DEFAULT_SHOP_MUSIC_VOLUME_DB := -18.0

@export var door_mode := DoorMode.ENTER
@export var destination: NodePath
@export var enter_hint := "Enter Shop"
@export var exit_hint := "Leave Shop"
@export var play_shop_music := true
@export var interior_music: AudioStream
@export var interior_music_volume_db := DEFAULT_SHOP_MUSIC_VOLUME_DB

var _transitioning := false
var _player_in_range: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	return exit_hint if door_mode == DoorMode.EXIT else enter_hint


func interact(player: Node3D) -> void:
	if _transitioning or player == null:
		return

	var dest := get_node_or_null(destination) as Marker3D
	if door_mode == DoorMode.ENTER:
		dest = _resolve_interior_spawn(dest)
		if dest == null:
			push_warning("ShopDoor: missing interior destination at %s" % destination)
			return

	_transitioning = true
	await _transition_player(player, dest)
	_transitioning = false


func _transition_player(player: Node3D, dest: Marker3D) -> void:
	var fade_overlay := _get_fade_overlay()
	var stage := get_tree().current_scene

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		GameAudio.play_door_open(self, global_position)
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	if door_mode == DoorMode.ENTER:
		ShopSession.save_before_enter(player, stage)
		var music := interior_music if interior_music != null else DEFAULT_SHOP_MUSIC
		ShopSession.enter_interior(player, dest, play_shop_music, music, interior_music_volume_db)
	else:
		ShopSession.restore_after_exit(player, stage, dest)

	var close_pos := dest.global_position if dest != null else global_position
	if fade_overlay != null:
		# Parent the sound to the stage: exit doors live inside the interior
		# that is about to unload, and would take the sound down with them.
		GameAudio.play_door_close(stage if stage != null else self, close_pos)
		var fade_in := create_tween()
		fade_in.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_in.finished
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(false)

	# Unloading frees the interior — and exit doors along with it. Tweens die
	# with the node that created them, so this must stay the very last step or
	# the awaited fade above never finishes and the screen stays black.
	if door_mode == DoorMode.EXIT:
		_unload_interior_zone()


func _get_fade_overlay() -> ColorRect:
	var stage := get_tree().current_scene
	if stage != null and stage.has_method("get_duel_fade_overlay"):
		return stage.get_duel_fade_overlay()
	return null


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)


func _resolve_interior_spawn(dest: Marker3D) -> Marker3D:
	if dest == null:
		return null

	var slot := _find_interior_slot(dest)
	if slot == null:
		return dest

	if slot.has_method("ensure_loaded"):
		slot.call("ensure_loaded")
	if slot.has_method("get_spawn_marker"):
		return slot.call("get_spawn_marker") as Marker3D
	return dest


func _find_interior_slot(from_node: Node) -> Node:
	var current: Node = from_node
	while current != null:
		if current.has_method("ensure_loaded") and current.has_method("get_spawn_marker"):
			return current
		current = current.get_parent()
	return null


func _unload_interior_zone() -> void:
	var slot := _find_interior_slot(self)
	if slot != null and slot.has_method("unload"):
		slot.call("unload")
