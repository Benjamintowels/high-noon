extends RefCounted
class_name ChurchRecurveReward
## Spawns the sanctified-church Recurve Bow + arrow pickups once.

const WeaponPickupScript := preload("res://gameplay/world/weapon_pickup.gd")
const ArrowAmmoPickupScript := preload("res://gameplay/world/arrow_ammo_pickup.gd")

const PICKUP_NAME := "ChurchRecurveBow"
const ARROW_COUNT := 8


static func spawn_if_needed(church: Node3D) -> void:
	if church == null:
		return
	if ChurchSanctifyQuest.recurve_bow_collected:
		return
	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.BOW):
		ChurchSanctifyQuest.mark_recurve_bow_collected()
		return
	if church.get_node_or_null(PICKUP_NAME) != null:
		return

	var spawn := church.get_node_or_null("RecurveBowSpawn") as Marker3D
	var chief_spawn := church.get_node_or_null("ChiefGetchaSpawn") as Marker3D
	var bow_pos := church.global_position
	var bow_yaw := 0.0
	if spawn != null:
		bow_pos = spawn.global_position
		bow_yaw = spawn.global_rotation.y
	elif chief_spawn != null:
		bow_pos = chief_spawn.global_position + chief_spawn.global_transform.basis.z * -1.8
		bow_yaw = chief_spawn.global_rotation.y

	var pickup: WeaponPickup = WeaponPickupScript.spawn_death_drop(
		church,
		bow_pos,
		GroyperWeapons.Id.BOW
	)
	if pickup == null:
		return
	pickup.name = PICKUP_NAME
	pickup.global_rotation.y = bow_yaw

	for i in ARROW_COUNT:
		var arrow: Area3D = ArrowAmmoPickupScript.new()
		arrow.ammo_amount = 1
		church.add_child(arrow)
		var angle := (TAU / float(ARROW_COUNT)) * float(i)
		arrow.global_position = bow_pos + Vector3(cos(angle) * 0.55, 0.0, sin(angle) * 0.55)
		arrow.global_rotation.y = bow_yaw
		if arrow.has_method("snap_to_floor"):
			arrow.call_deferred("snap_to_floor")
