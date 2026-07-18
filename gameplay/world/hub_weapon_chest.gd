extends Area3D

## Hub weapon locker: deposit inventory weapons into save-backed storage, or
## withdraw stored weapons back into the pack.

const CHEST_VISUAL_SCENE := preload("res://Assets/World/RuinsGR/AccessoriesScenes/ChestBase.tscn")
const MENU_SCRIPT := preload("res://gameplay/world/hub_weapon_chest_menu.gd")

const FALLBACK_DISPLAY_HEIGHT := 2.65

var _player_in_range: Node3D
var _chest: Node3D
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
	return "Open Weapon Chest"


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
	if get_node_or_null("CollisionShape3D") == null:
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 1.8, 2.4)
		shape_node.shape = box
		shape_node.position = Vector3(0.0, 0.9, 0.0)
		add_child(shape_node)


func _ensure_menu() -> void:
	_menu = get_node_or_null("HubWeaponChestMenu") as CanvasLayer
	if _menu == null:
		_menu = MENU_SCRIPT.new()
		_menu.name = "HubWeaponChestMenu"
		add_child(_menu)
	if not _menu.weapon_selected.is_connected(_on_weapon_selected):
		_menu.weapon_selected.connect(_on_weapon_selected)
	if not _menu.closed.is_connected(_on_menu_closed):
		_menu.closed.connect(_on_menu_closed)


func _on_weapon_selected(weapon_id: int) -> void:
	if _menu.is_deposit_mode():
		_deposit_weapon(weapon_id)
	else:
		_withdraw_weapon(weapon_id)
	RoguelikeSave.save_session()


func _deposit_weapon(weapon_id: int) -> void:
	if not PlayerInventory.owns_weapon_type(weapon_id):
		return
	if weapon_id == GroyperWeapons.Id.SWORD_SHIELD:
		if not PlayerInventory.has_sword_shield:
			return
		PlayerInventory.set_has_sword_shield(false)
		RunMetaProgress.store_weapon(weapon_id)
	else:
		PlayerInventory.remove_one_weapon(weapon_id)
		RunMetaProgress.store_weapon(weapon_id)
	# Never leave the hub pack empty — restore the starting sidearm.
	if PlayerInventory.get_extractable_weapons().is_empty():
		PlayerInventory.add_weapon(GroyperWeapons.Id.REVOLVER)
	_refresh_player_loadout()


func _withdraw_weapon(weapon_id: int) -> void:
	if not RunMetaProgress.take_stored_weapon(weapon_id):
		return
	if weapon_id == GroyperWeapons.Id.SWORD_SHIELD:
		PlayerInventory.set_has_sword_shield(true)
	else:
		PlayerInventory.add_weapon(weapon_id)
	var player := _player_in_range
	if player != null and player.has_method("equip_weapon"):
		player.equip_weapon(weapon_id, true)
	else:
		_refresh_player_loadout()


func _refresh_player_loadout() -> void:
	var player := _player_in_range
	if player == null:
		return
	if player.has_method("refresh_stowed_weapon_visuals"):
		player.refresh_stowed_weapon_visuals()
	# If the equipped weapon was deposited, fall back to starting / first owned.
	if not player.has_method("equip_weapon"):
		return
	var equipped := int(player.get("_equipped_weapon"))
	if equipped == GroyperWeapons.Id.UNARMED or PlayerInventory.owns_weapon_type(equipped):
		return
	var fallback := GroyperWeapons.get_starting_weapon()
	if not PlayerInventory.owns_weapon_type(fallback):
		var owned := PlayerInventory.get_unique_owned_weapons()
		fallback = owned[0] if not owned.is_empty() else GroyperWeapons.Id.UNARMED
	player.equip_weapon(fallback, false)


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
