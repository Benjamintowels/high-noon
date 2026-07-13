extends Area3D
class_name RevolverAmmoPickup

const GameAudio := preload("res://gameplay/audio/game_audio.gd")

const ATTRACT_RANGE := 1.05
const COLLECT_RANGE := 0.32
const ATTRACT_SPEED := 8.5
const SPIN_SPEED := 1.4
const BOB_AMOUNT := 0.03
const BOB_SPEED := 3.2
const DROP_ARC_DURATION := 0.48
const DEFAULT_PICKUP_LOCK := 1.5
const REWARD_DROP_MIN_PLAYER_DISTANCE := 3.4
const REWARD_DROP_DISTANCE := Vector2(2.6, 3.4)
const BODY_COLOR := Color(0.34, 0.34, 0.38, 1.0)
const BODY_BORDER := Color(0.52, 0.52, 0.58, 1.0)
const CHAMBER_COLOR := Color(0.95, 0.76, 0.18, 1.0)

@export var ammo_amount := 6
@export var requires_revolver := false
@export var auto_attract := true

var _picked_up := false
var _attracting := false
var _pickup_locked := false
var _lock_timer := 0.0
var _player: Node3D
var _visual_root: Node3D
var _bob_base_y := 0.0
var _bob_time := 0.0
var _drop_tween: Tween


static func spawn_at(
	parent: Node,
	world_pos: Vector3,
	amount: int,
	lock_duration: float = 0.0,
	requires_owned_revolver: bool = false
) -> RevolverAmmoPickup:
	var pickup := RevolverAmmoPickup.new()
	pickup.ammo_amount = maxi(amount, 1)
	pickup.requires_revolver = requires_owned_revolver
	parent.add_child(pickup)
	pickup.global_position = world_pos
	if lock_duration > 0.0:
		pickup.lock_pickup_for(lock_duration)
	return pickup


static func spawn_eject_drop(parent: Node, from_pos: Vector3, amount: int) -> RevolverAmmoPickup:
	if parent == null or amount <= 0:
		return null
	var pickup := spawn_at(parent, from_pos, amount, DEFAULT_PICKUP_LOCK, false)
	pickup.play_drop_arc(from_pos)
	return pickup


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


static func spawn_reward_drop(
	parent: Node,
	from_pos: Vector3,
	toward_pos: Vector3,
	amount: int,
	lock_duration: float = 0.75,
	keep_away_from: Vector3 = Vector3.INF
) -> RevolverAmmoPickup:
	if parent == null or amount <= 0:
		return null

	var flat := toward_pos - from_pos
	flat.y = 0.0
	if flat.length_squared() < 0.0001:
		flat = Vector3.FORWARD
	else:
		flat = flat.normalized()

	var side := flat.cross(Vector3.UP)
	if side.length_squared() < 0.0001:
		side = Vector3.RIGHT
	side = side.normalized()

	# Land short of the player so they walk up to it after the minigame.
	var end_pos := from_pos + flat * randf_range(REWARD_DROP_DISTANCE.x, REWARD_DROP_DISTANCE.y)
	end_pos += side * randf_range(-0.55, 0.55)
	end_pos.y = minf(from_pos.y, toward_pos.y)

	if keep_away_from != Vector3.INF:
		var from_player := end_pos - keep_away_from
		from_player.y = 0.0
		var player_dist := from_player.length()
		if player_dist < REWARD_DROP_MIN_PLAYER_DISTANCE:
			var push_dir := from_player.normalized() if player_dist > 0.001 else -flat
			end_pos = keep_away_from + push_dir * REWARD_DROP_MIN_PLAYER_DISTANCE
			end_pos.y = minf(from_pos.y, toward_pos.y)

	var pickup := spawn_at(parent, from_pos, amount, lock_duration, false)
	pickup.play_drop_arc_to(from_pos, end_pos)
	return pickup


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

	if not auto_attract or _pickup_locked or _player == null:
		return
	if not _can_collect_now():
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


## Overridable in subclasses (e.g. arrow pickups) for a different ammo pool.
func _can_collect_now() -> bool:
	if requires_revolver and not PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER):
		return false
	return PlayerInventory.get_revolver_ammo_space() > 0


## Overridable: add `amount` ammo, return how much was actually added.
func _add_ammo(player: Node3D, amount: int) -> int:
	var added := PlayerInventory.add_revolver_ammo(amount)
	if added > 0 and player != null and player.has_method("on_revolver_ammo_picked_up"):
		player.on_revolver_ammo_picked_up(added)
	return added


## Overridable: weapon id used for the pickup grab sound.
func _grab_sound_weapon_id() -> GroyperWeapons.Id:
	return GroyperWeapons.Id.REVOLVER


func _collect(player: Node3D) -> void:
	if _picked_up or _pickup_locked:
		return

	var added := _add_ammo(player, ammo_amount)
	if added <= 0:
		return

	ammo_amount -= added
	GameAudio.play_weapon_reload_grab(self, _grab_sound_weapon_id(), global_position)

	if ammo_amount > 0:
		return

	_picked_up = true
	_attracting = false
	monitoring = false

	if _visual_root != null:
		var tween := create_tween()
		tween.tween_property(_visual_root, "scale", Vector3.ZERO, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _build_visual() -> void:
	_visual_root = Node3D.new()
	_visual_root.name = "AmmoVisual"
	add_child(_visual_root)

	var body := MeshInstance3D.new()
	var body_mesh := CylinderMesh.new()
	body_mesh.top_radius = 0.075
	body_mesh.bottom_radius = 0.075
	body_mesh.height = 0.055
	body_mesh.radial_segments = 6
	body.mesh = body_mesh
	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BODY_COLOR
	body_mat.metallic = 0.35
	body_mat.roughness = 0.45
	body.material_override = body_mat
	_visual_root.add_child(body)

	var rim := MeshInstance3D.new()
	var rim_mesh := CylinderMesh.new()
	rim_mesh.top_radius = 0.082
	rim_mesh.bottom_radius = 0.082
	rim_mesh.height = 0.012
	rim_mesh.radial_segments = 6
	rim.mesh = rim_mesh
	rim.position.y = 0.028
	var rim_mat := StandardMaterial3D.new()
	rim_mat.albedo_color = BODY_BORDER
	rim_mat.metallic = 0.4
	rim_mat.roughness = 0.4
	rim.material_override = rim_mat
	_visual_root.add_child(rim)

	var chamber_mat := StandardMaterial3D.new()
	chamber_mat.albedo_color = CHAMBER_COLOR
	chamber_mat.metallic = 0.15
	chamber_mat.roughness = 0.35
	chamber_mat.emission_enabled = true
	chamber_mat.emission = CHAMBER_COLOR * 0.35
	chamber_mat.emission_energy_multiplier = 0.8

	for i in 6:
		var chamber := MeshInstance3D.new()
		var chamber_mesh := CylinderMesh.new()
		chamber_mesh.top_radius = 0.016
		chamber_mesh.bottom_radius = 0.016
		chamber_mesh.height = 0.01
		chamber_mesh.radial_segments = 6
		chamber.mesh = chamber_mesh
		chamber.material_override = chamber_mat
		var angle := (TAU * float(i) / 6.0) - PI * 0.5
		chamber.position = Vector3(cos(angle), 0.036, sin(angle)) * 0.042
		_visual_root.add_child(chamber)

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
	elif body is CharacterBody3D and body.has_method("on_revolver_ammo_picked_up"):
		_player = body


func _on_body_exited(body: Node3D) -> void:
	if body == _player:
		_player = null
		_attracting = false
