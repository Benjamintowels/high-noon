extends Node
class_name TownIntroCutscene
## One-time sheriff confrontation at the Town/TownIntro trigger (near the
## church gate). The sheriff and two deputies stop the player, question him
## about cattle thieves (yes/no choice), then the deputies close in while the
## screen fades to black and the player is hauled into the Jail interior
## (ShopInteriors/JailInterior). Persisted via TownIntroProgress.

const DEPUTY_SCENE := preload("res://characters/groyper/groyper_town_npc.tscn")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const SHERIFF_SPEAKER := "Sheriff Money Bags"
const HOLD_IT_LINE := "Hold it"
const QUESTION_LINES: PackedStringArray = [
	"We've had reports of cattle thieves in these parts",
	"You wouldn't know anything about that would you?",
]
const YES_LINES: PackedStringArray = [
	"We'll you're gonna have to come on down to the station with me son",
]
const NO_LINES: PackedStringArray = [
	"....mmmm well see about that",
	"Take him away boys",
]
const JAIL_LINES: PackedStringArray = [
	"So your Uncle has a Ranch? but its crop not cattle",
	"Alright he's not who were lookin' for",
	"You're free to go",
]

const WALK_SPEED := 2.2
const GRAVITY := 22.0
const SHERIFF_STOP_DISTANCE := 2.0
const DEPUTY_STOP_DISTANCE := 1.1
const DEPUTY_FLANK_OFFSET := 1.6
const DEPUTY_GRAB_SPREAD := 0.8
const WALK_TIMEOUT := 8.0
const DEPUTY_GRAB_LEAD_SECONDS := 0.6
const FADE_TO_BLACK_SECONDS := 1.8
const FADE_IN_SECONDS := 0.5
const JAIL_SETTLE_SECONDS := 0.7
const JAIL_EXIT_STOP_DISTANCE := 0.9
const JAIL_EXIT_WALK_TIMEOUT := 14.0
const CAMERA_RETURN_SECONDS := 1.0

var _stage: Node3D
var _player: Node3D
var _sheriff: Node3D
var _trigger: Area3D
var _deputies: Array[Node3D] = []
## npc -> {"target": Vector3, "stop": float}; controlled NPCs without an
## entry stand still and face the player.
var _walk_orders := {}
var _controlled: Array[Node3D] = []
var _active := false
var _driving := false
var _dialog_step_done := false
var _questioning_done := false


func setup(trigger: Area3D, player: Node3D, sheriff: Node3D, stage: Node3D) -> void:
	if TownIntroProgress.completed or trigger == null or player == null or sheriff == null:
		if trigger != null:
			trigger.monitoring = false
		return

	_trigger = trigger
	_player = player
	_sheriff = sheriff
	_stage = stage
	_configure_trigger(trigger)
	if not trigger.body_entered.is_connected(_on_body_entered):
		trigger.body_entered.connect(_on_body_entered)


func _configure_trigger(trigger: Area3D) -> void:
	trigger.monitoring = true
	trigger.monitorable = false
	var collision := trigger.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = false


func _on_body_entered(body: Node3D) -> void:
	if _active or TownIntroProgress.completed:
		return
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player = body
	_begin_sequence()


func _physics_process(delta: float) -> void:
	if not _driving:
		return
	for npc in _controlled:
		_step_npc(npc, delta)


func _begin_sequence() -> void:
	_active = true
	if _trigger != null:
		_trigger.set_deferred("monitoring", false)

	# Let the church->town gate cinematic (and any open dialog) finish before
	# taking over the camera.
	while (
		is_instance_valid(_player)
		and _player.has_method("is_comet_cinematic_active")
		and _player.is_comet_cinematic_active()
	):
		await get_tree().process_frame
	while DialogManager.is_showing():
		await get_tree().process_frame

	if (
		_sheriff == null
		or not is_instance_valid(_sheriff)
		or (_sheriff.has_method("is_defeated") and _sheriff.is_defeated())
	):
		return

	_lock_player(true)
	_take_control(_sheriff)
	_spawn_deputies()
	_driving = true

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()
	if _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(_sheriff)
	if _player.has_method("orient_toward_world_position"):
		_player.orient_toward_world_position(_sheriff.global_position)

	_play_npc_voice(_sheriff, GameAudioScript.SHERIFF_INTERACT_VOICE)
	await _show_line(HOLD_IT_LINE)

	# The sheriff walks up to the player.
	_order_walk(_sheriff, _player.global_position, SHERIFF_STOP_DISTANCE)
	await _await_walks(WALK_TIMEOUT)

	await _run_questioning()

	# Deputies close in on the player while the screen fades to black.
	_order_deputy_grab()
	await get_tree().create_timer(DEPUTY_GRAB_LEAD_SECONDS).timeout

	var fade_overlay := _get_fade_overlay()
	if fade_overlay != null:
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
		var fade_out := create_tween()
		fade_out.tween_property(fade_overlay, "modulate:a", 1.0, FADE_TO_BLACK_SECONDS)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		await fade_out.finished

	await _enter_jail(fade_overlay)


func _show_line(line: String) -> void:
	_dialog_step_done = false
	DialogManager.show_dialog(
		SHERIFF_SPEAKER,
		line,
		func() -> void:
			DialogManager.hide_dialog()
			_dialog_step_done = true
	)
	while not _dialog_step_done:
		await get_tree().process_frame


func _run_questioning() -> void:
	_questioning_done = false
	_play_npc_voice(_sheriff, GameAudioScript.SHERIFF_DIALOG_LINE_2_VOICE)
	DialogManager.show_dialog_sequence(
		QUESTION_LINES,
		func() -> void:
			DialogManager.show_choices(
				PackedStringArray(["Yes", "No"]),
				func(choice_index: int) -> void:
					_show_verdict(YES_LINES if choice_index == 0 else NO_LINES)
			),
		SHERIFF_SPEAKER
	)
	while not _questioning_done:
		await get_tree().process_frame


func _show_verdict(lines: PackedStringArray) -> void:
	_play_npc_voice(_sheriff, GameAudioScript.SHERIFF_DIALOG_LINE_2_VOICE)
	DialogManager.show_dialog_sequence(
		lines,
		func() -> void:
			_questioning_done = true,
		SHERIFF_SPEAKER
	)


func _enter_jail(fade_overlay: ColorRect) -> void:
	var interior: Node = null
	if _stage != null:
		var slot: Node = _stage.get_node_or_null("ShopInteriors/JailInterior")
		if slot != null:
			# No door-entry snapshot: leaving the jail should drop the player
			# at the JailEntranceMarker fallback, not back at the arrest spot.
			ShopSession.begin_interior_space()
			interior = slot.call("ensure_loaded")
			var spawn := slot.call("get_spawn_marker") as Marker3D
			if spawn != null:
				ShopSession.enter_interior(_player, spawn, false)
			GameAudioScript.play_door_close(_stage, _player.global_position)
		else:
			push_warning("TownIntroCutscene: missing ShopInteriors/JailInterior slot.")

	# The screen is black: tidy up the town-side actors while nobody can see
	# it. The sheriff resumes his beat at his normal town spawn (by the jail).
	_driving = false
	_walk_orders.clear()
	_controlled.clear()
	_return_town_sheriff_to_spawn()
	for deputy in _deputies:
		if deputy != null and is_instance_valid(deputy):
			deputy.queue_free()
	_deputies.clear()

	TownIntroProgress.mark_completed()

	# Keep the cinematic camera/letterbox through the jail scene, retargeted
	# onto the jail-side sheriff instance.
	var jail_sheriff: Node3D = null
	if interior != null:
		jail_sheriff = interior.get_node_or_null("JailSheriff") as Node3D
	if jail_sheriff != null:
		_take_control(jail_sheriff)
		_driving = true
		if _player.has_method("begin_comet_cinematic_camera"):
			_player.begin_comet_cinematic_camera(jail_sheriff)
		if _player.has_method("orient_toward_world_position"):
			_player.orient_toward_world_position(jail_sheriff.global_position)

	if fade_overlay != null:
		var fade_in := create_tween()
		fade_in.tween_property(fade_overlay, "modulate:a", 0.0, FADE_IN_SECONDS)\
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		await fade_in.finished
		fade_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if jail_sheriff != null:
		await _run_jail_scene(jail_sheriff, interior)

	await _finish_sequence(jail_sheriff)


func _run_jail_scene(jail_sheriff: Node3D, interior: Node) -> void:
	# Let the room settle on screen before the sheriff starts talking.
	await get_tree().create_timer(JAIL_SETTLE_SECONDS).timeout

	_play_npc_voice(jail_sheriff, GameAudioScript.SHERIFF_DIALOG_LINE_2_VOICE)
	_dialog_step_done = false
	DialogManager.show_dialog_sequence(
		JAIL_LINES,
		func() -> void:
			_dialog_step_done = true,
		SHERIFF_SPEAKER
	)
	while not _dialog_step_done:
		await get_tree().process_frame

	# The sheriff heads out the door and back to his town beat.
	var exit_target := jail_sheriff.global_position + Vector3(4.0, 0.0, 0.0)
	var exit_door := interior.get_node_or_null("ExitDoor") as Node3D
	if exit_door != null:
		exit_target = exit_door.global_position
	_order_walk(jail_sheriff, exit_target, JAIL_EXIT_STOP_DISTANCE)
	await _await_walks(JAIL_EXIT_WALK_TIMEOUT)
	GameAudioScript.play_door_close(_stage, jail_sheriff.global_position)


func _finish_sequence(jail_sheriff: Node3D) -> void:
	_driving = false
	_walk_orders.clear()
	_controlled.clear()

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()
	# Unlike the town->jail cut this happens on screen, so blend the camera
	# back instead of snapping (mirrors CometCinematic's return timing).
	if _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()
		await get_tree().create_timer(CAMERA_RETURN_SECONDS).timeout
	if _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()

	# Free the camera target only after the cinematic camera let go of it.
	if jail_sheriff != null and is_instance_valid(jail_sheriff):
		jail_sheriff.queue_free()

	_lock_player(false)

	# Persist completion immediately so the arrest can never re-trigger on
	# this save file, even if the player dies before the next bonfire rest.
	AdventureSave.sync_runtime_state(_player, _stage)


func _return_town_sheriff_to_spawn() -> void:
	if _sheriff == null or not is_instance_valid(_sheriff):
		return
	var marker: Marker3D = null
	if _stage != null:
		marker = _stage.get_node_or_null("Town/SheriffSpawn") as Marker3D
	if marker != null:
		_sheriff.global_transform = marker.global_transform
	_release_npc(_sheriff)
	if _sheriff.has_method("_snap_to_floor"):
		_sheriff.call_deferred("_snap_to_floor")


func _spawn_deputies() -> void:
	var host := _resolve_actor_host()
	var dir := _flat_direction(_sheriff.global_position, _player.global_position)
	var side := dir.cross(Vector3.UP).normalized()

	for i in 2:
		var deputy: Node3D = DEPUTY_SCENE.instantiate()
		deputy.set("idle_duration_min", 999999.0)
		deputy.set("idle_duration_max", 999999.0)
		host.add_child(deputy)
		var flank := side * (DEPUTY_FLANK_OFFSET if i == 0 else -DEPUTY_FLANK_OFFSET)
		deputy.global_position = _sheriff.global_position - dir * 1.8 + flank
		if deputy.has_method("snap_to_floor"):
			deputy.call_deferred("snap_to_floor")
		_take_control(deputy)
		_deputies.append(deputy)


func _order_deputy_grab() -> void:
	var dir := _flat_direction(_sheriff.global_position, _player.global_position)
	var side := dir.cross(Vector3.UP).normalized()
	for i in _deputies.size():
		var deputy := _deputies[i]
		if deputy == null or not is_instance_valid(deputy):
			continue
		var spread := side * (DEPUTY_GRAB_SPREAD if i == 0 else -DEPUTY_GRAB_SPREAD)
		_order_walk(deputy, _player.global_position + spread, DEPUTY_STOP_DISTANCE)


func _take_control(npc: Node3D) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	npc.set_physics_process(false)
	if npc is CharacterBody3D:
		(npc as CharacterBody3D).velocity = Vector3.ZERO
	if not _controlled.has(npc):
		_controlled.append(npc)


func _release_npc(npc: Node3D) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	npc.set_physics_process(true)
	if npc.has_method("cutscene_reset_ai"):
		npc.cutscene_reset_ai()


func _order_walk(npc: Node3D, target: Vector3, stop_distance: float) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	_walk_orders[npc] = {"target": target, "stop": stop_distance}


func _await_walks(timeout: float) -> void:
	var deadline := Time.get_ticks_msec() + int(timeout * 1000.0)
	while not _walk_orders.is_empty() and Time.get_ticks_msec() < deadline:
		await get_tree().physics_frame
	_walk_orders.clear()


func _step_npc(npc: Node3D, delta: float) -> void:
	if npc == null or not is_instance_valid(npc) or not npc is CharacterBody3D:
		return
	var body := npc as CharacterBody3D

	if not body.is_on_floor():
		body.velocity.y -= GRAVITY * delta
	else:
		body.velocity.y = minf(body.velocity.y, 0.0)

	var speed := 0.0
	if _walk_orders.has(npc):
		var order: Dictionary = _walk_orders[npc]
		var to_target: Vector3 = order["target"] - body.global_position
		to_target.y = 0.0
		if to_target.length() <= float(order["stop"]):
			_walk_orders.erase(npc)
			body.velocity.x = 0.0
			body.velocity.z = 0.0
		else:
			var dir := to_target.normalized()
			body.velocity.x = dir.x * WALK_SPEED
			body.velocity.z = dir.z * WALK_SPEED
			speed = WALK_SPEED
			if body.has_method("cutscene_face_position"):
				body.cutscene_face_position(body.global_position + dir, delta)
	else:
		body.velocity.x = 0.0
		body.velocity.z = 0.0
		if (
			_player != null
			and is_instance_valid(_player)
			and body.has_method("cutscene_face_position")
		):
			body.cutscene_face_position(_player.global_position, delta)

	body.move_and_slide()
	if body.has_method("cutscene_update_locomotion"):
		body.cutscene_update_locomotion(delta, speed)


func _flat_direction(from_pos: Vector3, to_pos: Vector3) -> Vector3:
	var dir := to_pos - from_pos
	dir.y = 0.0
	if dir.length_squared() < 0.0001:
		return Vector3.FORWARD
	return dir.normalized()


func _resolve_actor_host() -> Node:
	if _stage != null:
		var host := _stage.get_node_or_null("TownActors")
		if host != null:
			return host
	return _sheriff.get_parent()


func _play_npc_voice(npc: Node3D, stream: AudioStream) -> void:
	if npc == null or not is_instance_valid(npc):
		return
	var voice_position := npc.global_position + Vector3(0.0, 1.6, 0.0)
	if npc.has_method("get_voice_world_position"):
		voice_position = npc.get_voice_world_position()
	GameAudioScript.play_npc_voice(npc, stream, voice_position)


func _lock_player(active: bool) -> void:
	if _player == null or not is_instance_valid(_player):
		return
	if _player.has_method("set_transition_locked"):
		_player.set_transition_locked(active)
	if _player.has_method("set_dialog_active"):
		_player.set_dialog_active(active)


func _get_fade_overlay() -> ColorRect:
	if _stage != null and _stage.has_method("get_duel_fade_overlay"):
		return _stage.get_duel_fade_overlay()
	return null


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null
