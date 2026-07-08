extends AutoLootPickup
class_name LootBagPickup

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")

const BAG_COLOR := Color(0.42, 0.3, 0.18, 1.0)
const TIE_COLOR := Color(0.28, 0.2, 0.12, 1.0)
const GRAM_GLOW := Color(0.62, 0.86, 0.98, 1.0)
const SHARD_GLOW := Color(0.95, 0.78, 0.28, 1.0)
const PICKUP_LOCK := 4.0
const ATTRACT_RANGE_BAG := 1.35
const COLLECT_RANGE_BAG := 0.42

var gram_amount := 0
var soul_shard_amount := 0


static func spawn_death_drop(
	parent: Node,
	from_pos: Vector3,
	gram: int,
	soul_shards: int
) -> LootBagPickup:
	if parent == null or (gram <= 0 and soul_shards <= 0):
		return null

	var pickup := LootBagPickup.new()
	pickup.gram_amount = maxi(gram, 0)
	pickup.soul_shard_amount = maxi(soul_shards, 0)
	parent.add_child(pickup)

	var world := pickup.get_world_3d()
	var floor_pos := from_pos
	if world != null:
		floor_pos = GroyperBodyUtils.snap_position_to_floor(world, from_pos, 0.08)
	pickup.global_position = floor_pos
	pickup.add_to_group("player_death_loot_bag")
	pickup.lock_pickup_for(PICKUP_LOCK)
	return pickup


func _ready() -> void:
	add_to_group("player_death_loot_bag")
	super._ready()


func _apply_pickup() -> int:
	if gram_amount <= 0 and soul_shard_amount <= 0:
		return 0

	if gram_amount > 0:
		PlayerInventory.add_gram(gram_amount)
	if soul_shard_amount > 0:
		PlayerInventory.add_soul_shards(soul_shard_amount)

	var collected := gram_amount + soul_shard_amount
	gram_amount = 0
	soul_shard_amount = 0
	PlayerDeathLoot.notify_loot_bag_collected()
	return collected


func _can_collect() -> bool:
	return gram_amount > 0 or soul_shard_amount > 0


func _build_visual() -> void:
	super._build_visual()

	var body := MeshInstance3D.new()
	var body_mesh := BoxMesh.new()
	body_mesh.size = Vector3(0.34, 0.22, 0.26)
	body.mesh = body_mesh
	body.position.y = 0.11

	var body_mat := StandardMaterial3D.new()
	body_mat.albedo_color = BAG_COLOR
	body_mat.roughness = 0.88
	body_mat.metallic = 0.05
	body.material_override = body_mat
	_visual_root.add_child(body)

	var tie := MeshInstance3D.new()
	var tie_mesh := CylinderMesh.new()
	tie_mesh.top_radius = 0.04
	tie_mesh.bottom_radius = 0.04
	tie_mesh.height = 0.08
	tie.mesh = tie_mesh
	tie.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	tie.position = Vector3(0.0, 0.22, 0.0)

	var tie_mat := StandardMaterial3D.new()
	tie_mat.albedo_color = TIE_COLOR
	tie_mat.roughness = 0.95
	tie.material_override = tie_mat
	_visual_root.add_child(tie)

	if gram_amount > 0:
		_add_loot_sparkle(GRAM_GLOW, Vector3(-0.06, 0.18, 0.05))
	if soul_shard_amount > 0:
		_add_loot_sparkle(SHARD_GLOW, Vector3(0.06, 0.2, -0.04))


func _add_loot_sparkle(color: Color, offset: Vector3) -> void:
	var sparkle := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.045
	mesh.height = 0.09
	sparkle.mesh = mesh
	sparkle.position = offset

	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color * 0.55
	mat.emission_energy_multiplier = 1.2
	mat.roughness = 0.2
	sparkle.material_override = mat
	_visual_root.add_child(sparkle)


func _process(delta: float) -> void:
	if _picked_up:
		return

	if _pickup_locked:
		_lock_timer -= delta
		if _lock_timer <= 0.0:
			unlock_pickup()

	if _visual_root != null:
		_bob_time += delta
		_visual_root.rotate_y(SPIN_SPEED * 0.65 * delta)
		if not _attracting:
			_visual_root.position.y = _bob_base_y + sin(_bob_time * BOB_SPEED) * (BOB_AMOUNT * 1.4)

	if _pickup_locked or _player == null:
		return
	if not _can_collect():
		return

	var to_player := _player.global_position + Vector3(0.0, 0.85, 0.0) - global_position
	var distance := to_player.length()
	if distance > ATTRACT_RANGE_BAG:
		_attracting = false
		return

	_attracting = true
	if distance <= COLLECT_RANGE_BAG:
		_collect(_player)
		return

	var step := minf(ATTRACT_SPEED * delta, distance)
	global_position += to_player.normalized() * step
