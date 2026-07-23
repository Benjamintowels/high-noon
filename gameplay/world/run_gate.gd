extends Area3D

## Roguelike run gate: canyon-gate style "keep walking" cinematic, but instead
## of culling zones it fades to black and swaps scenes (hub -> run zone, or
## zone -> hub), implying distance traveled during the cut. Auto-triggers on
## walk-through — no interact prompt.
##
## Scene contract: a Marker3D child named "WalkTarget" ahead of the gate on the
## far side sets the cinematic walk direction. Hub gates also carry a
## "ReturnSpawn" Marker3D the hub uses to place the player coming back from a
## run through this gate.

enum Destination { RUN_ZONE, HUB }

const WALK_HOLD_SECONDS := 0.9
const FADE_SECONDS := 1.5
const BLACK_HOLD_SECONDS := 0.25
const MOVE_DIR_MIN_SPEED := 0.35
const DEFAULT_WALK_SPEED := 3.6
const HUB_TITLE := "The Town"

@export var destination := Destination.RUN_ZONE
@export var zone_id := "zone_1"
## When false the gate ignores the player (used for locked hub gates / sealed portals).
@export var gate_enabled := true

var _transitioning := false


func _ready() -> void:
	add_to_group("run_gate")
	monitoring = gate_enabled
	monitorable = false
	collision_layer = 0
	collision_mask = 1
	body_entered.connect(_on_body_entered)


func set_gate_enabled(enabled: bool) -> void:
	gate_enabled = enabled
	monitoring = enabled and not _transitioning


func _on_body_entered(body: Node3D) -> void:
	if _transitioning or not gate_enabled:
		return
	if body == null or not body.is_in_group("overworld_player"):
		return
	if destination == Destination.RUN_ZONE and not RunState.is_zone_unlocked(zone_id):
		_show_locked_message(body)
		return
	_transitioning = true
	_begin_transition(body)


func _show_locked_message(player: Node3D) -> void:
	var required := RunState.get_unlock_requirement_title(zone_id)
	var message := "Gate sealed"
	if required != "":
		message = "Clear %s first" % required
	var hud: Node = null
	if player.has_method("get_raid_hud"):
		hud = player.get_raid_hud()
	if hud != null and hud.has_method("show_zone_title"):
		hud.show_zone_title(message, 2.0)


func _begin_transition(player: Node3D) -> void:
	var target_path := _target_scene_path()
	if target_path == "":
		push_warning("RunGate %s: no destination scene." % name)
		_transitioning = false
		return

	RunState.request_scene_preload(target_path)

	var walk_dir := _resolve_walk_direction(player)
	var walk_speed := DEFAULT_WALK_SPEED
	if player is CharacterBody3D:
		var horizontal := Vector3(
			(player as CharacterBody3D).velocity.x,
			0.0,
			(player as CharacterBody3D).velocity.z
		)
		if horizontal.length() > MOVE_DIR_MIN_SPEED:
			walk_speed = horizontal.length()

	if player.has_method("begin_cinematic_walk"):
		player.begin_cinematic_walk(walk_dir, walk_speed)
	elif player.has_method("set_transition_locked"):
		player.set_transition_locked(true)

	var hud: Node = null
	if player.has_method("get_raid_hud"):
		hud = player.get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()
	if hud != null and hud.has_method("show_zone_title"):
		hud.show_zone_title(_destination_title(), WALK_HOLD_SECONDS + FADE_SECONDS)

	await get_tree().create_timer(WALK_HOLD_SECONDS).timeout
	if not is_inside_tree():
		return

	var fade_overlay := _get_fade_overlay()
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_SECONDS)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished
		if not is_inside_tree():
			return

	await get_tree().create_timer(BLACK_HOLD_SECONDS).timeout
	if not is_inside_tree():
		return

	# Autoload cover survives the outgoing stage FadeOverlay being freed.
	RunState.hold_black()

	# RunState (autoload) owns the coroutine that swaps scenes, so it survives
	# this gate being freed with the outgoing stage.
	if destination == Destination.HUB:
		await RunState.return_to_hub(true)
	else:
		# Day/Night difficulty picker on the black frame before the zone loads.
		await RunState.prompt_run_time_mode()
		await RunState.travel_to_zone(zone_id)


func _target_scene_path() -> String:
	if destination == Destination.HUB:
		return RunState.HUBWORLD_PATH
	return RunState.get_zone_path(zone_id)


func _destination_title() -> String:
	if destination == Destination.HUB:
		return HUB_TITLE
	return RunState.get_zone_title(zone_id)


func _resolve_walk_direction(player: Node3D) -> Vector3:
	var walk_target := get_node_or_null("WalkTarget") as Marker3D
	var dir := Vector3.ZERO
	if walk_target != null:
		dir = walk_target.global_position - player.global_position
	else:
		dir = -global_transform.basis.z
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	return dir.normalized()


func _get_fade_overlay() -> ColorRect:
	var stage := get_tree().current_scene
	if stage != null and stage.has_method("get_duel_fade_overlay"):
		return stage.get_duel_fade_overlay()
	return null
