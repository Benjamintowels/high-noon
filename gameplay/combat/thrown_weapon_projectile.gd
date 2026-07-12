extends "res://gameplay/combat/knife_projectile.gd"

## A thrown melee weapon (currently the 1H axe). Reuses the knife projectile's
## flight, trail, hit, stick, and pickup machinery; carries the real weapon grip
## mesh, spins end-over-end in flight, deals its own damage, and returns the
## weapon to the player's inventory on pickup.

const BaldwinBodyUtilsScript := preload("res://characters/baldwin/baldwin_body_utils.gd")
const GroyperWeaponsScript := preload("res://characters/groyper/groyper_weapons.gd")

const THROWN_DAMAGE := 1
const THROWN_VISUAL_SCALE := 1.0
const SPIN_SPEED_RAD := TAU * 2.2

var _weapon_id: int = GroyperWeaponsScript.Id.AXE_1H
var _visual_pivot: Node3D


static func spawn(
	parent: Node,
	weapon_id: int,
	origin: Vector3,
	direction: Vector3,
	speed: float,
	exclude: Array = [],
	shooter: Node3D = null
) -> Node3D:
	var projectile: Node3D = load("res://gameplay/combat/thrown_weapon_projectile.gd").new()
	projectile.name = "ThrownWeaponProjectile"
	projectile._weapon_id = weapon_id
	parent.add_child(projectile)
	projectile._build_visual()
	projectile.setup(origin, direction, speed, exclude, shooter)
	return projectile


func _build_visual() -> void:
	_visual_pivot = Node3D.new()
	_visual_pivot.name = "SpinPivot"
	add_child(_visual_pivot)
	var grip_scene := BaldwinBodyUtilsScript.melee_grip_scene_for(_weapon_id)
	if grip_scene == null:
		return
	var grip := grip_scene.instantiate() as Node3D
	_visual_pivot.add_child(grip)


func _process(delta: float) -> void:
	# End-over-end spin while flying; freezes once stuck.
	if _stuck or _visual_pivot == null:
		return
	_visual_pivot.rotate_x(SPIN_SPEED_RAD * GameTime.process_delta(delta))


func _get_damage() -> int:
	return THROWN_DAMAGE


func _get_visual_scale() -> float:
	return THROWN_VISUAL_SCALE


func _get_pickup_label() -> String:
	match _weapon_id:
		GroyperWeaponsScript.Id.AXE_1H:
			return "Axe"
		GroyperWeaponsScript.Id.SWORD_1H:
			return "Sword"
		_:
			return "Weapon"


func _apply_pickup(player: Node3D) -> void:
	PlayerInventory.add_weapon(_weapon_id)
	# Empty-handed pickup goes straight back into the hand.
	if (
		player.has_method("equip_weapon")
		and "_equipped_weapon" in player
		and player._equipped_weapon == GroyperWeaponsScript.Id.UNARMED
	):
		player.equip_weapon(_weapon_id, false)
