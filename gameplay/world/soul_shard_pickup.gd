extends AutoLootPickup
class_name SoulShardPickup

const ATTRACT_RANGE_OVERRIDE := 2.1
const COLOR_PINK := Color(0.95, 0.45, 0.78, 1.0)
const COLOR_PURPLE := Color(0.62, 0.28, 0.92, 1.0)
const COLOR_RED := Color(0.92, 0.18, 0.12, 1.0)
const XP_COLOR_MIN := 1
const XP_COLOR_MAX := 40

@export var shard_amount := 1

var _remaining := 0


static func color_for_xp(xp: int) -> Color:
	var t := inverse_lerp(float(XP_COLOR_MIN), float(XP_COLOR_MAX), float(xp))
	t = clampf(t, 0.0, 1.0)
	if t < 0.45:
		return COLOR_PINK.lerp(COLOR_PURPLE, t / 0.45)
	return COLOR_PURPLE.lerp(COLOR_RED, (t - 0.45) / 0.55)


static func spawn_eject_drop(parent: Node, from_pos: Vector3, amount: int) -> SoulShardPickup:
	if parent == null or amount <= 0:
		return null
	var pickup := SoulShardPickup.new()
	pickup.shard_amount = maxi(amount, 1)
	pickup._remaining = pickup.shard_amount
	parent.add_child(pickup)
	pickup.global_position = from_pos
	pickup.lock_pickup_for(DEFAULT_PICKUP_LOCK)
	pickup.play_drop_arc(from_pos)
	return pickup


func _ready() -> void:
	if _remaining <= 0:
		_remaining = maxi(shard_amount, 1)
	super._ready()


func _get_attract_range() -> float:
	return ATTRACT_RANGE_OVERRIDE


func _apply_pickup() -> int:
	if _remaining <= 0:
		return 0
	PlayerInventory.add_soul_shards(_remaining)
	var collected := _remaining
	_remaining = 0
	return collected


func _build_visual() -> void:
	super._build_visual()

	var shard_color := color_for_xp(shard_amount)
	var glow_color := shard_color.lerp(Color.WHITE, 0.35)

	var shard := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.11, 0.16, 0.07)
	shard.mesh = mesh
	shard.rotation_degrees = Vector3(18.0, 32.0, 12.0)

	var shard_mat := StandardMaterial3D.new()
	shard_mat.albedo_color = shard_color
	shard_mat.metallic = 0.15
	shard_mat.roughness = 0.28
	shard_mat.emission_enabled = true
	shard_mat.emission = glow_color * 0.4
	shard_mat.emission_energy_multiplier = 1.0
	shard.material_override = shard_mat
	_visual_root.add_child(shard)

	var core := MeshInstance3D.new()
	var core_mesh := PrismMesh.new()
	core_mesh.size = Vector3(0.05, 0.09, 0.03)
	core.mesh = core_mesh
	core.rotation_degrees = Vector3(18.0, 32.0, 12.0)
	core.position.y = 0.02

	var core_mat := StandardMaterial3D.new()
	core_mat.albedo_color = glow_color
	core_mat.metallic = 0.05
	core_mat.roughness = 0.18
	core_mat.emission_enabled = true
	core_mat.emission = glow_color * 0.55
	core_mat.emission_energy_multiplier = 1.2
	core.material_override = core_mat
	_visual_root.add_child(core)
