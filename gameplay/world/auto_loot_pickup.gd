extends Area3D
class_name AutoLootPickup

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const ATTRACT_RANGE := 1.05
const COLLECT_RANGE := 0.32
const ATTRACT_SPEED := 8.5
const SPIN_SPEED := 1.4
const BOB_AMOUNT := 0.03
const BOB_SPEED := 3.2
const DROP_ARC_DURATION := 0.48
const DEFAULT_PICKUP_LOCK := 0.35

var _picked_up := false
var _attracting := false
var _pickup_locked := false
var _lock_timer := 0.0
var _player: Node3D
var _visual_root: Node3D
var _bob_base_y := 0.0
var _bob_time := 0.0
var _drop_tween: Tween


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

	var shape_node := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = ATTRACT_RANGE
	shape_node.shape = sphere
	shape_node.position = Vector3(0.0, 0.15, 0.0)
	add_child(shape_node)

	_build_visual()
	_bob_base_y = _visual_root.position.y
	set_process(true)


func lock_pickup_for(duration: float) -> void:
	_pickup_locked = duration > 0.0
	_lock_timer = maxf(duration, 0.0)
	_attracting = false


func unlock_pickup() -> void:
	_pickup_locked = false
	_lock_timer = 0.0


func play_drop_arc(from_pos: Vector3) -> void:
	var facing := Vector3.FORWARD
	var player := _find_player()
	if player != null:
		var away := from_pos - player.global_position
		away.y = 0.0
		if away.length_squared() > 0.0001:
			facing = away.normalized()
		else:
			var right := player.global_transform.basis.x
			right.y = 0.0
			facing = right.normalized() if right.length_squared() > 0.0001 else Vector3.RIGHT

	var side := facing.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()
	var lateral := (randf() * 2.0 - 1.0) * 0.35
	var end_pos := from_pos + facing * randf_range(0.55, 0.95) + side * lateral
	end_pos.y = from_pos.y
	play_drop_arc_to(from_pos, end_pos)


func play_drop_arc_to(from_pos: Vector3, end_pos: Vector3) -> void:
	if _drop_tween != null and _drop_tween.is_valid():
		_drop_tween.kill()

	global_position = from_pos
	var mid := from_pos.lerp(end_pos, 0.5)
	mid.y = maxf(from_pos.y, end_pos.y) + randf_range(0.45, 0.75)

	_drop_tween = create_tween()
	_drop_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_drop_tween.tween_method(
		func(t: float) -> void:
			var a := from_pos.lerp(mid, t)
			var b := mid.lerp(end_pos, t)
			global_position = a.lerp(b, t),
		0.0,
		1.0,
		DROP_ARC_DURATION
	)


func _process(delta: float) -> void:
	if _picked_up:
		return

	if _pickup_locked:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			unlock_pickup()

	if _visual_root != null:
		_bob_time += delta
		_visual_root.rotate_y(SPIN_SPEED * delta)
		if not _attracting:
			_visual_root.position.y = _bob_base_y + sin(_bob_time * BOB_SPEED) * BOB_AMOUNT

	if _pickup_locked or _player == null:
		return
	if not _can_collect():
		return

	var to_player := _player.global_position + Vector3(0.0, 0.85, 0.0) - global_position
	var distance := to_player.length()
	if distance > ATTRACT_RANGE:
		_attracting = false
		return

	_attracting = true
	if distance <= COLLECT_RANGE:
		_collect(_player)
		return

	var step := minf(ATTRACT_SPEED * delta, distance)
	global_position += to_player.normalized() * step


func _collect(player: Node3D) -> void:
	if _picked_up or _pickup_locked:
		return

	var collected := _apply_pickup()
	if collected <= 0:
		return

	GameAudio.play_loot_pickup(self, global_position)
	_notify_player_pickup(player, collected)

	_picked_up = true
	_attracting = false
	monitoring = false

	if _visual_root != null:
		var tween := create_tween()
		tween.tween_property(_visual_root, "scale", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _can_collect() -> bool:
	return true


func _apply_pickup() -> int:
	return 0


func _notify_player_pickup(_player: Node3D, _amount: int) -> void:
	pass


func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "LootVisual"
	add_child(_visual_root)
	_visual_root.position.y = 0.04


func _find_player() -> Node3D:
	if _player != null and is_instance_valid(_player):
		return _player
	var tree := get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("player") as Node3D


func _on_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	if body is CharacterBody3D and body.is_in_group("player"):
		_player = body
	elif body is CharacterBody3D and body.is_in_group("overworld_player"):
		_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		_attracting = false
