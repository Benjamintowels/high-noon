extends Node
class_name ChurchSkeletonAmbush

const SkeletonEnemyScene := preload("res://characters/enemies/skeleton_enemy.tscn")
const FloatingEnemyHealthBarScript := preload("res://gameplay/ui/floating_enemy_health_bar.gd")
const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")

const SKELETON_COUNT := 10
const BURIED_DEPTH := 1.25
const RISE_DURATION := 1.15
const RISE_STAGGER := 0.32
const CINEMATIC_HOLD_SECONDS := 2.0
const CAMERA_RETURN_SECONDS := 0.65
const SPAWN_EDGE_PADDING := 3.5
const SPAWN_MIN_SEPARATION := 2.4
const SPAWN_ATTEMPTS_PER_SLOT := 12

var _player: Node3D
var _trigger: Area3D
var _spawn_parent: Node3D
var _skeletons: Array[SkeletonEnemy] = []
var _armed := false
var _active := false
var _require_reentry := false
var _player_inside := false
var _sequence_token := 0


func _ready() -> void:
	add_to_group("church_skeleton_ambush")


func setup(trigger: Area3D, player: Node3D) -> void:
	if trigger == null or player == null:
		return

	_player = player
	_trigger = trigger
	_spawn_parent = trigger.get_parent() as Node3D
	if _spawn_parent == null:
		_spawn_parent = trigger

	_configure_trigger()
	if not _trigger.body_entered.is_connected(_on_body_entered):
		_trigger.body_entered.connect(_on_body_entered)
	if not _trigger.body_exited.is_connected(_on_body_exited):
		_trigger.body_exited.connect(_on_body_exited)

	_armed = true
	call_deferred("_sync_player_inside")


func reset_for_bonfire_rest() -> void:
	_sequence_token += 1
	_despawn_skeletons()
	_active = false
	_armed = true
	_require_reentry = _player_inside
	if _trigger != null:
		_trigger.monitoring = true


func _configure_trigger() -> void:
	_trigger.monitoring = true
	_trigger.monitorable = false
	var collision := _trigger.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if collision != null:
		collision.disabled = false


func _sync_player_inside() -> void:
	if _trigger == null or _player == null:
		return
	_player_inside = _trigger.overlaps_body(_player)
	_require_reentry = _player_inside


func _on_body_entered(body: Node3D) -> void:
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player_inside = true
	if _require_reentry:
		return
	if not _armed or _active:
		return
	_player = body
	_begin_ambush()


func _on_body_exited(body: Node3D) -> void:
	if body == null or not body.is_in_group("overworld_player"):
		return
	_player_inside = false
	_require_reentry = false


func _begin_ambush() -> void:
	if _active or not _armed:
		return

	_active = true
	_armed = false
	_sequence_token += 1
	var token := _sequence_token
	_trigger.monitoring = false

	GameAudioScript.play_raid_drama_start(self)
	var spawn_positions := _build_spawn_positions()
	if spawn_positions.is_empty():
		push_warning("ChurchSkeletonAmbush: no spawn positions inside SkeletonTrigger.")
		_active = false
		_armed = true
		_trigger.monitoring = true
		return

	_spawn_skeletons(spawn_positions)
	if _skeletons.is_empty():
		_active = false
		_armed = true
		_trigger.monitoring = true
		return

	await _play_intro_cinematic(token)
	if token != _sequence_token:
		return

	_release_skeletons_to_combat()


func _play_intro_cinematic(token: int) -> void:
	var lead := _skeletons[0]
	if lead == null or not is_instance_valid(lead):
		return

	if _player != null and _player.has_method("begin_comet_cinematic_camera"):
		_player.begin_comet_cinematic_camera(lead)

	var hud := _get_raid_hud()
	if hud != null and hud.has_method("show_drama_letterbox_in"):
		hud.show_drama_letterbox_in()

	lead.begin_rise_from_ground(BURIED_DEPTH, RISE_DURATION)
	_stagger_remaining_rises(token, 1)

	await get_tree().create_timer(CINEMATIC_HOLD_SECONDS).timeout
	if token != _sequence_token:
		return

	if hud != null and hud.has_method("hide_drama_letterbox"):
		hud.hide_drama_letterbox()

	if _player != null and _player.has_method("begin_comet_cinematic_camera_exit"):
		_player.begin_comet_cinematic_camera_exit()

	await get_tree().create_timer(CAMERA_RETURN_SECONDS).timeout
	if token != _sequence_token:
		return

	if _player != null and _player.has_method("end_comet_cinematic"):
		_player.end_comet_cinematic()


func _stagger_remaining_rises(token: int, start_index: int) -> void:
	for i in range(start_index, _skeletons.size()):
		var skeleton := _skeletons[i]
		if skeleton == null or not is_instance_valid(skeleton):
			continue
		var delay := float(i - start_index + 1) * RISE_STAGGER
		_schedule_skeleton_rise(skeleton, delay, token)


func _schedule_skeleton_rise(skeleton: SkeletonEnemy, delay: float, token: int) -> void:
	var timer := get_tree().create_timer(delay)
	timer.timeout.connect(func() -> void:
		if token != _sequence_token:
			return
		if skeleton == null or not is_instance_valid(skeleton):
			return
		skeleton.begin_rise_from_ground(BURIED_DEPTH, RISE_DURATION)
	)


func _release_skeletons_to_combat() -> void:
	for skeleton in _skeletons:
		if skeleton == null or not is_instance_valid(skeleton) or skeleton.is_defeated():
			continue
		skeleton.force_alert_to_player(_player)

	if _player != null and _player.has_method("enter_overworld_combat"):
		_player.enter_overworld_combat()


func _spawn_skeletons(positions: Array[Vector3]) -> void:
	_despawn_skeletons()
	for spawn_position in positions:
		var skeleton: SkeletonEnemy = SkeletonEnemyScene.instantiate()
		_spawn_parent.add_child(skeleton)
		skeleton.global_position = spawn_position
		skeleton.snap_to_floor()
		FloatingEnemyHealthBarScript.attach_to(skeleton)
		_skeletons.append(skeleton)


func _despawn_skeletons() -> void:
	for skeleton in _skeletons:
		if skeleton != null and is_instance_valid(skeleton):
			skeleton.queue_free()
	_skeletons.clear()


func _build_spawn_positions() -> Array[Vector3]:
	var bounds := _compute_trigger_bounds()
	if bounds.is_empty():
		return []

	var center: Vector3 = bounds.get("center", Vector3.ZERO)
	var half_extents: Vector2 = bounds.get("half_extents", Vector2.ONE)
	var usable_x := maxf(half_extents.x - SPAWN_EDGE_PADDING, 1.0)
	var usable_z := maxf(half_extents.y - SPAWN_EDGE_PADDING, 1.0)
	var rng := RandomNumberGenerator.new()
	rng.randomize()

	var positions: Array[Vector3] = []
	for _i in SKELETON_COUNT:
		var placed := false
		for _attempt in SPAWN_ATTEMPTS_PER_SLOT:
			var offset := Vector3(
				rng.randf_range(-usable_x, usable_x),
				0.0,
				rng.randf_range(-usable_z, usable_z)
			)
			var candidate := center + offset
			if _is_far_enough(candidate, positions):
				positions.append(candidate)
				placed = true
				break
		if not placed:
			var fallback_angle := (TAU / float(SKELETON_COUNT)) * float(positions.size())
			positions.append(
				center + Vector3(cos(fallback_angle) * usable_x * 0.65, 0.0, sin(fallback_angle) * usable_z * 0.65)
			)
	return positions


func _is_far_enough(candidate: Vector3, positions: Array[Vector3]) -> bool:
	for existing in positions:
		var flat := Vector2(candidate.x - existing.x, candidate.z - existing.z)
		if flat.length_squared() < SPAWN_MIN_SEPARATION * SPAWN_MIN_SEPARATION:
			return false
	return true


func _compute_trigger_bounds() -> Dictionary:
	if _trigger == null:
		return {}

	var shape_node := _trigger.get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null or shape_node.shape == null:
		return {
			"center": _trigger.global_position,
			"half_extents": Vector2(12.0, 10.0),
		}

	var shape := shape_node.shape
	var shape_center := shape_node.global_position
	shape_center.y = _trigger.global_position.y

	if shape is BoxShape3D:
		var box := shape as BoxShape3D
		var half := box.size * 0.5
		return {
			"center": shape_center,
			"half_extents": Vector2(half.x, half.z),
		}

	if shape is SphereShape3D:
		var radius := (shape as SphereShape3D).radius
		return {
			"center": shape_center,
			"half_extents": Vector2(radius, radius),
		}

	return {
		"center": shape_center,
		"half_extents": Vector2(12.0, 10.0),
	}


func _get_raid_hud() -> RaidHud:
	if _player != null and _player.has_method("get_raid_hud"):
		return _player.get_raid_hud()
	return null
