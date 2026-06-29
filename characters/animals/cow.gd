extends CharacterBody3D

const GameAudio := preload("res://gameplay/audio/game_audio.gd")
const GrassPatch := preload("res://characters/animals/tall_grass.gd")

enum State { IDLE, MOVE_TO_GRASS, GRAZING, WANDER }

const GRAVITY := 22.0
const GRAZE_RANGE := 1.35
const GRASS_SEARCH_RADIUS := 40.0
const WALK_SPEED := 0.42
const TURN_SPEED := 4.0
const MOO_HIT_COOLDOWN := 1.2

@export var personality_seed := -1
@export var roam_center := Vector3.ZERO
@export var roam_radius := 8.0

@onready var _facing: Node3D = $Facing
@onready var _visual: Node3D = $Facing/Visual

var state: State = State.IDLE
var _target_grass: GrassPatch
var _idle_timer := 0.0
var _wander_target := Vector3.ZERO
var _chew_time := 0.0
var _rng := RandomNumberGenerator.new()
var _moo_hit_cooldown := 0.0
var _body_bob := 0.0
var _lasso_captured := false
var _lasso_player: Node3D
var _lasso_rope_length := 8.5


func _ready() -> void:
	add_to_group("cow")
	add_to_group("lassoable")
	if personality_seed >= 0:
		_rng.seed = personality_seed
	else:
		_rng.randomize()

	if roam_center == Vector3.ZERO:
		roam_center = global_position

	_build_visual()
	_idle_timer = _rng.randf_range(4.0, 10.0)


func _physics_process(delta: float) -> void:
	_moo_hit_cooldown = maxf(_moo_hit_cooldown - delta, 0.0)

	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = minf(velocity.y, 0.0)

	if _lasso_captured:
		if _lasso_player != null:
			apply_lasso_drag(_lasso_player, delta)
		move_and_slide()
		return

	match state:
		State.IDLE:
			velocity.x = 0.0
			velocity.z = 0.0
			_idle_timer -= delta
			if _idle_timer <= 0.0:
				_try_seek_grass()
		State.MOVE_TO_GRASS:
			_process_move_to_grass(delta)
		State.GRAZING:
			_process_grazing(delta)
		State.WANDER:
			_process_wander(delta)

	move_and_slide()
	_update_body_bob(delta)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if _moo_hit_cooldown > 0.0:
		return
	_moo_hit_cooldown = MOO_HIT_COOLDOWN
	var hit_position: Vector3 = hit_info.get("position", global_position)
	GameAudio.play_cow_moo(self, hit_position)

	if state == State.GRAZING:
		_finish_grazing()
	_idle_timer = _rng.randf_range(2.0, 5.0)
	state = State.IDLE


func _try_seek_grass() -> void:
	var grass: GrassPatch = _find_nearest_grass(global_position, GRASS_SEARCH_RADIUS)
	if grass == null:
		_begin_wander()
		return

	_target_grass = grass
	state = State.MOVE_TO_GRASS


func _process_move_to_grass(delta: float) -> void:
	if not _grass_is_valid():
		_begin_idle(_rng.randf_range(4.0, 9.0))
		return

	if _in_graze_range():
		_start_grazing()
		return

	var to_grass: Vector3 = _target_grass.global_position - global_position
	to_grass.y = 0.0
	if to_grass.length() < 0.05:
		_start_grazing()
		return

	var direction: Vector3 = to_grass.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	_face_direction(direction, delta)


func _process_grazing(delta: float) -> void:
	velocity.x = 0.0
	velocity.z = 0.0

	if not _grass_is_valid():
		_begin_idle(_rng.randf_range(3.0, 7.0))
		return

	_chew_time += delta
	if _target_grass.add_graze_work(delta):
		_finish_grazing()
		return

	var face: Vector3 = _target_grass.global_position - global_position
	face.y = 0.0
	if face.length_squared() > 0.001:
		_face_direction(face, delta)


func _process_wander(delta: float) -> void:
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() < 0.5 or _idle_timer <= 0.0:
		_begin_idle(_rng.randf_range(3.0, 8.0))
		return

	var direction: Vector3 = to_target.normalized()
	velocity.x = direction.x * WALK_SPEED
	velocity.z = direction.z * WALK_SPEED
	_face_direction(direction, delta)
	_idle_timer -= delta


func _start_grazing() -> void:
	state = State.GRAZING
	_chew_time = 0.0
	velocity.x = 0.0
	velocity.z = 0.0


func _finish_grazing() -> void:
	_target_grass = null
	_idle_timer = _rng.randf_range(1.5, 3.5)
	state = State.IDLE


func _begin_idle(duration: float) -> void:
	_target_grass = null
	state = State.IDLE
	_idle_timer = duration
	velocity.x = 0.0
	velocity.z = 0.0


func _begin_wander() -> void:
	state = State.WANDER
	_idle_timer = _rng.randf_range(3.0, 6.0)
	_wander_target = _pick_roam_point()


func _pick_roam_point() -> Vector3:
	for _attempt in 8:
		var offset := Vector3(
			_rng.randf_range(-roam_radius, roam_radius),
			0.0,
			_rng.randf_range(-roam_radius, roam_radius)
		)
		var point := roam_center + offset
		if point.distance_to(roam_center) <= roam_radius:
			return point
	return roam_center


func _find_nearest_grass(origin: Vector3, max_distance: float) -> GrassPatch:
	var best: GrassPatch = null
	var best_dist := max_distance * max_distance
	for node in get_tree().get_nodes_in_group("tall_grass"):
		var grass: GrassPatch = node as GrassPatch
		if grass == null or not is_instance_valid(grass) or grass.consumed:
			continue
		var d := origin.distance_squared_to(grass.global_position)
		if d < best_dist:
			best_dist = d
			best = grass
	return best


func _grass_is_valid() -> bool:
	return _target_grass != null and is_instance_valid(_target_grass) and not _target_grass.consumed


func _in_graze_range() -> bool:
	if not _grass_is_valid():
		return false
	var flat: Vector3 = _target_grass.global_position - global_position
	flat.y = 0.0
	return flat.length() <= GRAZE_RANGE


func _face_direction(direction: Vector3, delta: float) -> void:
	var target_yaw := atan2(direction.x, direction.z)
	_facing.rotation.y = lerp_angle(_facing.rotation.y, target_yaw, 1.0 - exp(-TURN_SPEED * delta))


func _update_body_bob(delta: float) -> void:
	if _visual == null:
		return
	if state == State.GRAZING:
		_visual.position.y = sin(_chew_time * 3.2) * 0.035
	elif state == State.MOVE_TO_GRASS or state == State.WANDER:
		_body_bob += delta * 5.5
		_visual.position.y = sin(_body_bob) * 0.02
	else:
		_visual.position.y = 0.0


func _build_visual() -> void:
	var body_color := Color(0.98, 0.98, 0.96)
	var spot_color := Color(0.04, 0.04, 0.04)
	var hoof_color := Color(0.28, 0.22, 0.18)
	var horn_color := Color(0.78, 0.72, 0.58)

	var body := _make_box(Vector3(0.95, 0.62, 1.45), Vector3(0.0, 0.62, 0.0), body_color)
	_visual.add_child(body)

	var head := _make_box(Vector3(0.42, 0.38, 0.48), Vector3(0.0, 0.78, 0.82), body_color)
	_visual.add_child(head)

	var snout := _make_box(Vector3(0.3, 0.22, 0.2), Vector3(0.0, 0.68, 1.02), Color(0.9, 0.88, 0.86))
	_visual.add_child(snout)

	_add_spots(spot_color)

	for side in [-1.0, 1.0]:
		var horn := _make_box(Vector3(0.06, 0.18, 0.06), Vector3(0.16 * side, 1.02, 0.72), horn_color)
		horn.rotation.z = deg_to_rad(18.0 * side)
		_visual.add_child(horn)

	for x in [-0.28, 0.28]:
		for z in [-0.42, 0.42]:
			var leg := _make_box(Vector3(0.14, 0.42, 0.14), Vector3(x, 0.21, z), hoof_color)
			_visual.add_child(leg)


func _add_spots(spot_color: Color) -> void:
	for spot_def in _pick_spot_layout():
		var spot := _make_box(spot_def["size"], spot_def["pos"], spot_color)
		_visual.add_child(spot)


func _pick_spot_layout() -> Array[Dictionary]:
	var spots: Array[Dictionary] = []
	var spot_count := _rng.randi_range(5, 8)

	for _i in spot_count:
		var side := -1.0 if _rng.randf() < 0.5 else 1.0
		spots.append({
			"size": Vector3(
				0.06,
				_rng.randf_range(0.18, 0.34),
				_rng.randf_range(0.2, 0.4)
			),
			"pos": Vector3(
				side * 0.49,
				_rng.randf_range(0.5, 0.76),
				_rng.randf_range(-0.42, 0.38)
			),
		})

	spots.append({
		"size": Vector3(0.06, 0.2, 0.18),
		"pos": Vector3(0.23, 0.84, 0.88),
	})
	spots.append({
		"size": Vector3(0.34, 0.08, 0.24),
		"pos": Vector3(0.0, 0.9, 0.02),
	})
	spots.append({
		"size": Vector3(0.06, 0.26, 0.3),
		"pos": Vector3(-0.49, 0.64, -0.18),
	})

	return spots


func _make_box(size: Vector3, local_pos: Vector3, color: Color) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.position = local_pos
	var mesh := BoxMesh.new()
	mesh.size = size
	mesh_instance.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.88
	mesh_instance.material_override = mat
	return mesh_instance


func is_lassoable() -> bool:
	return not _lasso_captured


func get_lasso_attach_point() -> Vector3:
	return global_position + Vector3(0.0, 0.95, 0.0)


func get_lasso_rope_length() -> float:
	return _lasso_rope_length


func get_lasso_max_match_speed() -> float:
	return 24.0


func get_lasso_drag_visual() -> Node3D:
	return _visual


func begin_lasso_capture(player: Node3D, rope_length: float, _ring: LassoRing = null) -> void:
	_lasso_captured = true
	_lasso_player = player
	_lasso_rope_length = rope_length
	velocity = Vector3.ZERO
	state = State.IDLE


func end_lasso_capture() -> void:
	_lasso_captured = false
	_lasso_player = null
	velocity = Vector3.ZERO


func apply_lasso_drag(player: Node3D, delta: float) -> void:
	if not _lasso_captured or player == null:
		return
	const LassoTargetUtils := preload("res://gameplay/lasso/lasso_target_utils.gd")
	LassoTargetUtils.apply_taut_drag(self, self, player, _lasso_rope_length, delta)
	_update_body_bob(delta)
