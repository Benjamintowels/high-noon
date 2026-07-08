extends Node3D

const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")
const HOME_REVOLVER_PICKUP_SCRIPT := preload("res://gameplay/world/home_revolver_pickup.gd")
const HOME_HAT_PICKUP_SCRIPT := preload("res://gameplay/world/home_hat_pickup.gd")
const REVOLVER_AMMO_PICKUP_SCENE := preload("res://gameplay/world/revolver_ammo_pickup.tscn")

const HOME_AMMO_AMOUNT := 6


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
	WOOD_BULLET_COVER.apply_to(self)
	call_deferred("_setup_interior_torch")
	call_deferred("_setup_home_pickups")


func _setup_interior_torch() -> void:
	var wall_torch := get_node_or_null("WallTorch")
	if wall_torch == null:
		return
	var fire := wall_torch.get_node_or_null("Fire")
	if fire != null and fire.has_method("set_respect_day_night"):
		fire.call("set_respect_day_night", false)


func _setup_home_pickups() -> void:
	_setup_revolver_pickup()
	_setup_hat_pickup()
	_setup_ammo_pickup()


func _setup_ammo_pickup() -> void:
	if get_node_or_null("HomeAmmoPickup") != null:
		return

	var marker := get_node_or_null("HomeAmmo") as Marker3D
	if marker == null:
		push_warning("HomeInterior: missing HomeAmmo marker.")
		return

	var pickup := REVOLVER_AMMO_PICKUP_SCENE.instantiate() as RevolverAmmoPickup
	pickup.name = "HomeAmmoPickup"
	pickup.ammo_amount = HOME_AMMO_AMOUNT
	pickup.requires_revolver = true
	pickup.auto_attract = true
	add_child(pickup)
	pickup.global_position = marker.global_position


func _setup_revolver_pickup() -> void:
	var display := get_node_or_null("Revolver") as Node3D
	if display == null:
		push_warning("HomeInterior: missing Revolver display node.")
		return

	if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER):
		display.queue_free()
		return

	_attach_pickup(display, HOME_REVOLVER_PICKUP_SCRIPT, "RevolverPickup")


func _setup_hat_pickup() -> void:
	var display := get_node_or_null("hat01") as Node3D
	if display == null:
		push_warning("HomeInterior: missing hat01 display node.")
		return

	if PlayerInventory.owns_hat(PlayerInventory.COWBOY_HAT_ID):
		display.queue_free()
		return

	_attach_pickup(display, HOME_HAT_PICKUP_SCRIPT, "HatPickup")


func _attach_pickup(display: Node3D, script: Script, pickup_name: String) -> void:
	if get_node_or_null(pickup_name) != null:
		return

	var pickup := Area3D.new()
	pickup.name = pickup_name
	pickup.set_script(script)
	pickup.set("display_node", display)
	add_child(pickup)
	pickup.global_position = display.global_position
