extends Area3D
class_name WeaponPickup

const GroyperBodyUtils := preload("res://characters/groyper/groyper_body_utils.gd")
const PICKUP_SCENE := preload("res://gameplay/world/weapon_pickup.tscn")

@export var weapon_id: GroyperWeapons.Id = GroyperWeapons.Id.AWP

var _picked_up := false
var _player_in_range: Node3D
var _display_root: Node3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_display_mesh()
	call_deferred("snap_to_floor")


func snap_to_floor() -> void:
	global_position = GroyperBodyUtils.snap_position_to_floor(get_world_3d(), global_position, 0.0)


static func spawn_death_drop(
	parent: Node,
	from_pos: Vector3,
	weapon_id: GroyperWeapons.Id
) -> WeaponPickup:
	if parent == null or not _is_droppable_weapon_id(weapon_id):
		return null

	var pickup: WeaponPickup = PICKUP_SCENE.instantiate()
	pickup.weapon_id = weapon_id
	parent.add_child(pickup)
	pickup.global_position = from_pos
	pickup.call_deferred("snap_to_floor")
	return pickup


static func _is_droppable_weapon_id(weapon_id: GroyperWeapons.Id) -> bool:
	if GroyperWeapons.is_unarmed(weapon_id) or GroyperWeapons.is_lasso(weapon_id):
		return false
	return GroyperWeapons.GRIP_SCENES.has(weapon_id)


func get_interact_hint() -> String:
	if _picked_up:
		return ""
	return "Take %s" % PlayerInventory.get_weapon_display_name(weapon_id)


func interact(player: Node3D) -> void:
	if _picked_up or player == null:
		return

	var upgraded_to_dual := false
	if weapon_id == GroyperWeapons.Id.REVOLVER:
		if PlayerInventory.owns_weapon_type(GroyperWeapons.Id.DUAL_REVOLVER):
			pass  # Already dual — consume pickup without stacking.
		elif PlayerInventory.owns_weapon_type(GroyperWeapons.Id.REVOLVER):
			upgraded_to_dual = PlayerInventory.try_upgrade_revolver_to_dual()
		else:
			PlayerInventory.add_weapon(weapon_id)
	elif not PlayerInventory.owns_weapon_type(weapon_id):
		PlayerInventory.add_weapon(weapon_id)

	if weapon_id == GroyperWeapons.Id.BOW:
		ChurchSanctifyQuest.mark_recurve_bow_collected()
		# Floor reserve to starting quiver so a home-start pickup is immediately usable.
		var need := maxi(0, PlayerInventory.STARTING_BOW_AMMO - PlayerInventory.get_bow_ammo())
		if need > 0:
			if player.has_method("add_bow_ammo"):
				player.call("add_bow_ammo", need)
			else:
				PlayerInventory.add_bow_ammo(need)

	if upgraded_to_dual and player.has_method("equip_weapon"):
		player.equip_weapon(GroyperWeapons.Id.DUAL_REVOLVER, true)
	elif player.has_method("refresh_stowed_weapon_visuals"):
		player.refresh_stowed_weapon_visuals()

	_picked_up = true
	_hide_display()
	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)


func _spawn_display_mesh() -> void:
	_display_root = Node3D.new()
	_display_root.name = "DisplayMesh"
	add_child(_display_root)

	if weapon_id == GroyperWeapons.Id.BOW:
		_spawn_bow_ground_pad()

	var grip_scene := GroyperWeapons.get_grip_scene(weapon_id)
	var grip: Node3D = grip_scene.instantiate()
	_display_root.add_child(grip)
	_apply_display_transform(grip)


func _apply_display_transform(grip: Node3D) -> void:
	match weapon_id:
		GroyperWeapons.Id.BOW:
			grip.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			grip.position = Vector3(0.0, 0.05, 0.0)
			grip.scale = Vector3.ONE
		GroyperWeapons.Id.LASSO:
			grip.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			grip.scale = Vector3(1.8, 1.8, 1.8)
		GroyperWeapons.Id.SHOVEL:
			grip.rotation_degrees = Vector3(90.0, 0.0, 0.0)
			grip.scale = Vector3(1.5, 1.5, 1.5)
		_:
			grip.rotation_degrees = Vector3(0.0, 90.0, 0.0)
			grip.scale = _get_display_scale()


func _get_display_scale() -> Vector3:
	var s := GroyperWeapons.get_pickup_display_scale(weapon_id)
	return Vector3(s, s, s)


func _spawn_bow_ground_pad() -> void:
	var pad := MeshInstance3D.new()
	pad.name = "GroundPad"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.18
	mesh.bottom_radius = 0.2
	mesh.height = 0.03
	pad.mesh = mesh
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.52, 0.34, 0.18, 1.0)
	material.roughness = 0.9
	pad.material_override = material
	pad.position = Vector3(0.0, 0.015, 0.0)
	_display_root.add_child(pad)


func _hide_display() -> void:
	if _display_root != null:
		_display_root.visible = false
	visible = false


func _on_body_entered(body: Node3D) -> void:
	if _picked_up:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
