extends Node
## Spawns a timed burst of gram + soul-shard eject pickups around an origin.

const GramPickupScript := preload("res://gameplay/world/gram_pickup.gd")
const SoulShardPickupScript := preload("res://gameplay/world/soul_shard_pickup.gd")
const SELF_SCRIPT := preload("res://gameplay/world/loot_currency_shower.gd")

const DEFAULT_DURATION := 2.0
const DEFAULT_BURSTS := 10
const SPREAD_RADIUS := 1.35


static func start(
	parent: Node,
	origin: Vector3,
	gram_total: int,
	soul_shard_total: int,
	duration: float = DEFAULT_DURATION,
	burst_count: int = DEFAULT_BURSTS
) -> void:
	if parent == null:
		return
	var gram := maxi(gram_total, 0)
	var shards := maxi(soul_shard_total, 0)
	if gram <= 0 and shards <= 0:
		return

	var shower: Node = SELF_SCRIPT.new()
	shower.name = "LootCurrencyShower"
	parent.add_child(shower)
	shower.call(
		"_run",
		origin,
		gram,
		shards,
		maxf(duration, 0.05),
		maxi(burst_count, 1)
	)


func _run(
	origin: Vector3,
	gram_total: int,
	soul_shard_total: int,
	duration: float,
	burst_count: int
) -> void:
	var gram_parts := _split_amount(gram_total, burst_count)
	var shard_parts := _split_amount(soul_shard_total, burst_count)
	var interval := duration / float(burst_count)

	for i in burst_count:
		_spawn_burst(origin, gram_parts[i], shard_parts[i])
		if i < burst_count - 1:
			await get_tree().create_timer(interval).timeout
			if not is_inside_tree():
				return

	queue_free()


func _spawn_burst(origin: Vector3, gram_amount: int, shard_amount: int) -> void:
	var parent := get_parent()
	if parent == null:
		return
	if gram_amount > 0:
		GramPickupScript.spawn_eject_drop(parent, _offset_pos(origin), gram_amount)
	if shard_amount > 0:
		SoulShardPickupScript.spawn_eject_drop(parent, _offset_pos(origin), shard_amount)


func _offset_pos(origin: Vector3) -> Vector3:
	var angle := randf() * TAU
	var radius := randf_range(0.15, SPREAD_RADIUS)
	return origin + Vector3(cos(angle) * radius, randf_range(0.35, 1.1), sin(angle) * radius)


static func _split_amount(total: int, parts: int) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(parts)
	if total <= 0 or parts <= 0:
		return result

	var base := int(total / parts)
	var remainder := total % parts
	for i in parts:
		result[i] = base + (1 if i < remainder else 0)
	for i in range(parts - 1, 0, -1):
		var j := randi_range(0, i)
		var tmp := result[i]
		result[i] = result[j]
		result[j] = tmp
	return result
