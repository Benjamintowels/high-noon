extends Node

signal inventory_changed

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")

const STARTING_GRAM := 20
const COWBOY_HAT_ID := &"cowboy"

var gram := STARTING_GRAM
var owned_weapons: Array[int] = [GroyperWeapons.Id.REVOLVER]
var owned_hats: Array[StringName] = [COWBOY_HAT_ID]
var has_knife := false
var has_sword_shield := false
var has_ruins_key := false
var has_treasure_map := false


func reset_for_new_game() -> void:
	gram = STARTING_GRAM
	owned_weapons = [GroyperWeapons.Id.REVOLVER]
	owned_hats = [COWBOY_HAT_ID]
	has_knife = false
	has_sword_shield = false
	has_ruins_key = false
	has_treasure_map = false
	inventory_changed.emit()


func capture_snapshot() -> Dictionary:
	return {
		"gram": gram,
		"owned_weapons": owned_weapons.duplicate(),
		"owned_hats": owned_hats.duplicate(),
		"has_knife": has_knife,
		"has_sword_shield": has_sword_shield,
		"has_ruins_key": has_ruins_key,
		"has_treasure_map": has_treasure_map,
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	gram = int(snapshot.get("gram", STARTING_GRAM))
	owned_weapons = _duplicate_weapon_array(snapshot.get("owned_weapons", [GroyperWeapons.Id.REVOLVER]))
	owned_hats = _duplicate_hat_array(snapshot.get("owned_hats", [COWBOY_HAT_ID]))
	has_knife = bool(snapshot.get("has_knife", false))
	has_sword_shield = bool(snapshot.get("has_sword_shield", false))
	has_ruins_key = bool(snapshot.get("has_ruins_key", false))
	has_treasure_map = bool(snapshot.get("has_treasure_map", false))
	reconcile_owned_sword_shield()
	inventory_changed.emit()


func count_weapon(weapon_id: int) -> int:
	var count := 0
	for weapon in owned_weapons:
		if weapon == weapon_id:
			count += 1
	return count


func owns_hat(hat_id: StringName) -> bool:
	return owned_hats.has(hat_id)


func can_afford(cost: int) -> bool:
	return gram >= cost


func spend_gram(amount: int) -> bool:
	if not can_afford(amount):
		return false
	gram -= amount
	inventory_changed.emit()
	return true


func add_gram(amount: int) -> void:
	if amount <= 0:
		return
	gram += amount
	inventory_changed.emit()


func add_hat(hat_id: StringName) -> bool:
	if hat_id.is_empty() or owns_hat(hat_id):
		return false
	owned_hats.append(hat_id)
	inventory_changed.emit()
	return true


func add_weapon(weapon_id: int) -> void:
	owned_weapons.append(weapon_id)
	inventory_changed.emit()


func set_has_knife(value: bool) -> void:
	if has_knife == value:
		return
	has_knife = value
	inventory_changed.emit()


func set_has_sword_shield(value: bool) -> void:
	var changed := has_sword_shield != value
	has_sword_shield = value
	var owned_before := owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD)
	_sync_sword_shield_weapon_entry()
	if changed or owned_before != owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD):
		inventory_changed.emit()


func reconcile_owned_sword_shield() -> void:
	var owned_before := owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD)
	_sync_sword_shield_weapon_entry()
	if owned_before != owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD):
		inventory_changed.emit()


func _sync_sword_shield_weapon_entry() -> void:
	var weapon_id := GroyperWeapons.Id.SWORD_SHIELD
	if has_sword_shield:
		if not owns_weapon_type(weapon_id):
			owned_weapons.append(weapon_id)
	else:
		var filtered: Array[int] = []
		for weapon in owned_weapons:
			if weapon != weapon_id:
				filtered.append(weapon)
		owned_weapons = filtered


func set_has_ruins_key(value: bool) -> void:
	if has_ruins_key == value:
		return
	has_ruins_key = value
	inventory_changed.emit()


func set_has_treasure_map(value: bool) -> void:
	if has_treasure_map == value:
		return
	has_treasure_map = value
	inventory_changed.emit()


func owns_weapon_type(weapon_id: int) -> bool:
	return count_weapon(weapon_id) > 0


func get_unique_owned_weapons() -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	for weapon in owned_weapons:
		if seen.has(weapon):
			continue
		seen[weapon] = true
		result.append(weapon)
	return result


func get_weapon_display_name(weapon_id: int) -> String:
	match weapon_id:
		GroyperWeapons.Id.REVOLVER:
			return "Revolver"
		GroyperWeapons.Id.MAC10:
			return "Mac-10"
		GroyperWeapons.Id.SHOTGUN:
			return "Shotgun"
		GroyperWeapons.Id.RPG:
			return "RPG"
		GroyperWeapons.Id.AWP:
			return "AWP"
		GroyperWeapons.Id.AK47:
			return "AK-47"
		GroyperWeapons.Id.LASSO:
			return "Lasso"
		GroyperWeapons.Id.BOW:
			return "Bow"
		GroyperWeapons.Id.SHOVEL:
			return "Shovel"
		GroyperWeapons.Id.SWORD_SHIELD:
			return "Sword & Shield"
		_:
			return "Weapon"


func get_hat_display_name(hat_id: StringName) -> String:
	if hat_id == COWBOY_HAT_ID:
		return "Cowboy Hat"
	return GroyperHatCatalog.get_display_name(hat_id)


func _duplicate_weapon_array(source: Variant) -> Array[int]:
	var result: Array[int] = []
	if source is Array:
		for item in source:
			result.append(int(item))
	if result.is_empty():
		result.append(GroyperWeapons.Id.REVOLVER)
	return result


func _duplicate_hat_array(source: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if source is Array:
		for item in source:
			result.append(StringName(str(item)))
	if result.is_empty():
		result.append(COWBOY_HAT_ID)
	return result
