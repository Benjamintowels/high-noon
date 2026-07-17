extends Area3D

## Reusable debug chest: opens a weapon grid and drops/grants the pick. Never locks.

const WeaponPickupScript := preload("res://gameplay/world/weapon_pickup.gd")
const CHEST_VISUAL_SCENE := preload("res://Assets/World/RuinsGR/AccessoriesScenes/ChestBase.tscn")
const MENU_SCENE := preload("res://gameplay/debug/debug_weapon_chest_menu.tscn")

const LOOT_DROP_DISTANCE := 1.35
const LOOT_DROP_DURATION := 0.75
const FALLBACK_DISPLAY_HEIGHT := 2.65
## Reserve rounds granted for ammo weapons so reload can be tested immediately.
const ARMORY_RESERVE_AMMO := 100

var _player_in_range: Node3D
var _chest: Node3D
var _display_position: Marker3D
var _menu: CanvasLayer
var _busy := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_ensure_visuals()
	_ensure_menu()


func get_interact_hint() -> String:
	if _busy:
		return ""
	return "Open Armory"


func interact(player: Node3D) -> void:
	if _busy or player == null:
		return
	_player_in_range = player
	_busy = true
	if _chest != null and _chest.has_method("open_chest"):
		_chest.open_chest(1.2)
	_menu.open_menu()


func _ensure_visuals() -> void:
	_chest = get_node_or_null("ChestBase") as Node3D
	if _chest == null:
		_chest = CHEST_VISUAL_SCENE.instantiate() as Node3D
		_chest.name = "ChestBase"
		add_child(_chest)
	_display_position = get_node_or_null("DisplayPosition") as Marker3D
	if _display_position == null:
		_display_position = Marker3D.new()
		_display_position.name = "DisplayPosition"
		_display_position.position = Vector3(0.0, FALLBACK_DISPLAY_HEIGHT, 0.0)
		add_child(_display_position)
	if get_node_or_null("CollisionShape3D") == null:
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 1.8, 2.4)
		shape_node.shape = box
		shape_node.position = Vector3(0.0, 0.9, 0.0)
		add_child(shape_node)


func _ensure_menu() -> void:
	_menu = get_node_or_null("DebugWeaponChestMenu") as CanvasLayer
	if _menu == null:
		_menu = MENU_SCENE.instantiate() as CanvasLayer
		_menu.name = "DebugWeaponChestMenu"
		add_child(_menu)
	if not _menu.weapon_selected.is_connected(_on_weapon_selected):
		_menu.weapon_selected.connect(_on_weapon_selected)
	if not _menu.closed.is_connected(_on_menu_closed):
		_menu.closed.connect(_on_menu_closed)


func _on_weapon_selected(weapon_id: int) -> void:
	var player := _player_in_range
	var id := weapon_id as GroyperWeapons.Id
	_grant_armory_reserve_ammo(id)
	# Always add + equip so the mag starts full; drop is a visual extra (pickup
	# won't duplicate once the type is already owned).
	_grant_weapon(player, id)
	if WeaponPickupScript._is_droppable_weapon_id(id):
		_drop_weapon(id)


func _grant_armory_reserve_ammo(weapon_id: GroyperWeapons.Id) -> void:
	if not GroyperWeapons.uses_ammo(weapon_id):
		return
	if GroyperWeapons.is_dynamite(weapon_id):
		return
	if weapon_id == GroyperWeapons.Id.BOW:
		PlayerInventory.set_bow_ammo(ARMORY_RESERVE_AMMO)
		return
	# Revolver reserve is the shared firearm reload pool used by overworld reload.
	if GroyperWeapons.is_firearm(weapon_id) or weapon_id == GroyperWeapons.Id.REVOLVER:
		PlayerInventory.set_revolver_ammo(ARMORY_RESERVE_AMMO)


func _drop_weapon(weapon_id: GroyperWeapons.Id) -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return
	var pickup := WeaponPickupScript.spawn_death_drop(parent, _get_drop_start(), weapon_id)
	if pickup != null:
		_tween_loot_to_ground(pickup)


func _grant_weapon(player: Node3D, weapon_id: GroyperWeapons.Id) -> void:
	if weapon_id == GroyperWeapons.Id.SWORD_SHIELD:
		PlayerInventory.set_has_sword_shield(true)
	else:
		PlayerInventory.add_weapon(weapon_id)
	if player != null and player.has_method("equip_weapon"):
		player.equip_weapon(weapon_id, true)
	elif player != null and player.has_method("refresh_stowed_weapon_visuals"):
		player.refresh_stowed_weapon_visuals()


func _get_drop_start() -> Vector3:
	if _display_position != null:
		return _display_position.global_position
	return global_position + Vector3(0.0, FALLBACK_DISPLAY_HEIGHT, 0.0)


func _tween_loot_to_ground(pickup: Node3D) -> void:
	var start_pos := _get_drop_start()
	var drop_dir := -global_transform.basis.z
	drop_dir.y = 0.0
	if drop_dir.length_squared() < 0.0001:
		drop_dir = Vector3.FORWARD
	else:
		drop_dir = drop_dir.normalized()
	var end_pos := global_position + drop_dir * LOOT_DROP_DISTANCE
	end_pos.y = global_position.y + 0.05
	pickup.global_position = start_pos
	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pickup, "global_position", end_pos, LOOT_DROP_DURATION)
	if pickup.has_method("snap_to_floor"):
		tween.tween_callback(pickup.snap_to_floor)


func _on_menu_closed() -> void:
	_busy = false


func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
		_player_in_range = null
