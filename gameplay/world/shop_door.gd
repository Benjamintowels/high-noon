extends Area3D

enum DoorMode { ENTER, EXIT }

const FADE_DURATION := 0.5
const INTERACT_RANGE := 2.75

@export var door_mode := DoorMode.ENTER
@export var destination: NodePath

var _transitioning := false
var _player_in_range: Node3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func get_interact_hint() -> String:
	return "Leave Shop" if door_mode == DoorMode.EXIT else "Enter Shop"


func interact(player: Node3D) -> void:
	if _transitioning or player == null:
		return

	var dest := get_node_or_null(destination) as Marker3D
	if door_mode == DoorMode.ENTER and dest == null:
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
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	if door_mode == DoorMode.ENTER:
		ShopSession.save_before_enter(player, stage)
		ShopSession.enter_interior(player, dest)
	else:
		ShopSession.restore_after_exit(player, stage, dest)

	if fade_overlay != null:
		var fade_in := create_tween()
		fade_in.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_in.finished
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if player.has_method("set_transition_locked"):
		player.set_transition_locked(false)


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
