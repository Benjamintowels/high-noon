extends RefCounted

## Rolls auto-pickup showers for run destructible props.

const GramPickupScript := preload("res://gameplay/world/gram_pickup.gd")
const SoulShardPickupScript := preload("res://gameplay/world/soul_shard_pickup.gd")
const HealthPickupScript := preload("res://gameplay/world/health_pickup.gd")
const RevolverAmmoPickupScript := preload("res://gameplay/world/revolver_ammo_pickup.gd")
const DROP_KINDS := [&"gram", &"shards", &"heart", &"revolver_ammo"]


static func roll_and_spawn(parent: Node, origin: Vector3, loot_mult: float = 1.0) -> void:
	if parent == null:
		return
	var drops := randi_range(1, 3)
	var mult := maxf(loot_mult, 0.05)
	for i in drops:
		var kind: StringName = DROP_KINDS[randi() % DROP_KINDS.size()]
		var offset := Vector3(
			cos(TAU * float(i) / float(drops) + randf()) * 0.35,
			0.2,
			sin(TAU * float(i) / float(drops) + randf()) * 0.35
		)
		var pos := origin + offset
		match kind:
			&"gram":
				var gram_amt := maxi(1, int(round(float(randi_range(1, 4)) * mult)))
				GramPickupScript.spawn_eject_drop(parent, pos, gram_amt)
			&"shards":
				var shard_amt := maxi(1, int(round(float(randi_range(1, 2)) * mult)))
				SoulShardPickupScript.spawn_eject_drop(parent, pos, shard_amt)
			&"heart":
				HealthPickupScript.spawn_eject_drop(parent, pos, 1)
			&"revolver_ammo":
				var ammo := maxi(1, int(round(float(randi_range(2, 6)) * mult)))
				RevolverAmmoPickupScript.spawn_eject_drop(parent, pos, ammo)
