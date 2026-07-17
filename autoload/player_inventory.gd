extends Node

signal inventory_changed
signal worn_hat_changed(hat_id: StringName)

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")

const STARTING_GRAM := 20
const COWBOY_HAT_ID := &"cowboy"
const REVOLVER_AMMO_MAX := 100
const STARTING_REVOLVER_AMMO := 0
# Bow arrows are a persistent reserve (like revolver ammo), NOT refilled on
# every draw. Mirrors GroyperWeapons BOW max_ammo — keep in sync.
const BOW_AMMO_MAX := 100
const STARTING_BOW_AMMO := 10

var gram := STARTING_GRAM
var soul_shards := 0
var owned_weapons: Array[int] = [GroyperWeapons.Id.REVOLVER]
var owned_hats: Array[StringName] = [COWBOY_HAT_ID]
var worn_hat := COWBOY_HAT_ID
var has_knife := false
var has_sword_shield := false
var has_ruins_key := false
var has_ranch_key := false
var has_treasure_map := false
var has_deputy_badge := false
var revolver_ammo := STARTING_REVOLVER_AMMO
var bow_ammo := STARTING_BOW_AMMO
## Inventory consumable packs: each entry is the shard amount granted on use.
var soul_shard_packs: Array = []


func reset_for_new_game() -> void:
	PlayerDeathLoot.clear_active_loot()
	gram = STARTING_GRAM
	soul_shards = 0
	owned_weapons = [GroyperWeapons.Id.REVOLVER]
	owned_hats = [COWBOY_HAT_ID]
	_set_worn_hat_internal(COWBOY_HAT_ID)
	has_knife = false
	has_sword_shield = false
	has_ruins_key = false
	has_ranch_key = false
	has_treasure_map = false
	has_deputy_badge = false
	revolver_ammo = STARTING_REVOLVER_AMMO
	bow_ammo = STARTING_BOW_AMMO
	soul_shard_packs = []
	inventory_changed.emit()


func reset_for_home_start() -> void:
	PlayerDeathLoot.clear_active_loot()
	gram = STARTING_GRAM
	soul_shards = 0
	owned_weapons = []
	owned_hats = []
	_set_worn_hat_internal(&"")
	has_knife = false
	has_sword_shield = false
	has_ruins_key = false
	has_ranch_key = false
	has_treasure_map = false
	has_deputy_badge = false
	revolver_ammo = STARTING_REVOLVER_AMMO
	bow_ammo = 0
	soul_shard_packs = []
	inventory_changed.emit()


func capture_snapshot() -> Dictionary:
	return {
		"gram": gram,
		"soul_shards": soul_shards,
		"owned_weapons": owned_weapons.duplicate(),
		"owned_hats": owned_hats.duplicate(),
		"worn_hat": String(worn_hat),
		"has_knife": has_knife,
		"has_sword_shield": has_sword_shield,
		"has_ruins_key": has_ruins_key,
		"has_ranch_key": has_ranch_key,
		"has_treasure_map": has_treasure_map,
		"has_deputy_badge": has_deputy_badge,
		"revolver_ammo": revolver_ammo,
		"bow_ammo": bow_ammo,
		"soul_shard_packs": soul_shard_packs.duplicate(),
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	gram = int(snapshot.get("gram", STARTING_GRAM))
	soul_shards = maxi(int(snapshot.get("soul_shards", 0)), 0)
	owned_weapons = _duplicate_weapon_array(snapshot.get("owned_weapons", [GroyperWeapons.Id.REVOLVER]))
	owned_hats = _duplicate_hat_array(snapshot.get("owned_hats", [COWBOY_HAT_ID]))
	_apply_worn_hat_snapshot(snapshot)
	has_knife = bool(snapshot.get("has_knife", false))
	has_sword_shield = bool(snapshot.get("has_sword_shield", false))
	has_ruins_key = bool(snapshot.get("has_ruins_key", false))
	has_ranch_key = bool(snapshot.get("has_ranch_key", false))
	has_treasure_map = bool(snapshot.get("has_treasure_map", false))
	has_deputy_badge = bool(snapshot.get("has_deputy_badge", false))
	revolver_ammo = clampi(int(snapshot.get("revolver_ammo", STARTING_REVOLVER_AMMO)), 0, REVOLVER_AMMO_MAX)
	bow_ammo = clampi(int(snapshot.get("bow_ammo", STARTING_BOW_AMMO)), 0, BOW_AMMO_MAX)
	soul_shard_packs = []
	var packs: Variant = snapshot.get("soul_shard_packs", [])
	if packs is Array:
		for entry in packs:
			soul_shard_packs.append(maxi(int(entry), 1))
	reconcile_owned_sword_shield()
	inventory_changed.emit()


func get_revolver_ammo() -> int:
	return revolver_ammo


func get_revolver_ammo_max() -> int:
	return REVOLVER_AMMO_MAX


func get_revolver_ammo_space() -> int:
	return maxi(REVOLVER_AMMO_MAX - revolver_ammo, 0)


func add_revolver_ammo(amount: int) -> int:
	if amount <= 0:
		return 0
	var space := get_revolver_ammo_space()
	if space <= 0:
		return 0
	var added := mini(amount, space)
	revolver_ammo += added
	inventory_changed.emit()
	return added


func set_revolver_ammo(amount: int, emit: bool = true) -> void:
	var clamped := clampi(amount, 0, REVOLVER_AMMO_MAX)
	if clamped == revolver_ammo:
		return
	revolver_ammo = clamped
	if emit:
		inventory_changed.emit()


func try_consume_revolver_ammo(amount: int = 1) -> bool:
	if amount <= 0:
		return true
	if revolver_ammo < amount:
		return false
	revolver_ammo -= amount
	inventory_changed.emit()
	return true


func get_bow_ammo() -> int:
	return bow_ammo


func get_bow_ammo_max() -> int:
	return BOW_AMMO_MAX


func get_bow_ammo_space() -> int:
	return maxi(BOW_AMMO_MAX - bow_ammo, 0)


func add_bow_ammo(amount: int) -> int:
	if amount <= 0:
		return 0
	var space := get_bow_ammo_space()
	if space <= 0:
		return 0
	var added := mini(amount, space)
	bow_ammo += added
	inventory_changed.emit()
	return added


## Set the reserve directly. Firing passes emit=false (the player refreshes the
## quiver itself) to avoid emitting inventory_changed on every shot.
func set_bow_ammo(amount: int, emit: bool = true) -> void:
	var clamped := clampi(amount, 0, BOW_AMMO_MAX)
	if clamped == bow_ammo:
		return
	bow_ammo = clamped
	if emit:
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
	if RunState.run_active and RunState.has_method("record_gram_collected"):
		RunState.record_gram_collected(amount)
	inventory_changed.emit()


func get_soul_shards() -> int:
	return soul_shards


func add_soul_shards(amount: int) -> void:
	if amount <= 0:
		return
	soul_shards += amount
	if RunState.run_active and RunState.has_method("record_soul_shards_collected"):
		RunState.record_soul_shards_collected(amount)
	inventory_changed.emit()


## Spend soul shards. Returns false if the player cannot afford the cost.
func spend_soul_shards(amount: int) -> bool:
	if amount <= 0:
		return true
	if soul_shards < amount:
		return false
	soul_shards -= amount
	inventory_changed.emit()
	return true


func add_soul_shard_pack(amount: int) -> void:
	if amount <= 0:
		return
	soul_shard_packs.append(amount)
	inventory_changed.emit()


func get_soul_shard_packs() -> Array:
	return soul_shard_packs.duplicate()


## Consume one inventory pack by index and grant its shards. Returns amount granted.
func use_soul_shard_pack(index: int) -> int:
	if index < 0 or index >= soul_shard_packs.size():
		return 0
	var amount := maxi(int(soul_shard_packs[index]), 0)
	soul_shard_packs.remove_at(index)
	if amount > 0:
		add_soul_shards(amount)
	else:
		inventory_changed.emit()
	return amount


func take_all_currency() -> Dictionary:
	var taken := {
		"gram": gram,
		"soul_shards": soul_shards,
	}
	if taken.gram > 0 or taken.soul_shards > 0:
		gram = 0
		soul_shards = 0
		inventory_changed.emit()
	return taken


## Death respawn leaves carried currency on the loot bag only.
func clear_currency() -> void:
	if gram == 0 and soul_shards == 0:
		return
	gram = 0
	soul_shards = 0
	inventory_changed.emit()


## Roguelike hub bank sync — set both currencies without additive pickup SFX.
func set_currency(gram_amount: int, shard_amount: int) -> void:
	var next_gram := maxi(gram_amount, 0)
	var next_shards := maxi(shard_amount, 0)
	if next_gram == gram and next_shards == soul_shards:
		return
	gram = next_gram
	soul_shards = next_shards
	inventory_changed.emit()


func add_hat(hat_id: StringName) -> bool:
	if hat_id.is_empty() or owns_hat(hat_id):
		return false
	owned_hats.append(hat_id)
	# A bareheaded cowboy puts a found hat straight on.
	if worn_hat.is_empty():
		_set_worn_hat_internal(hat_id)
	inventory_changed.emit()
	return true


## Removes one owned hat (e.g. knocked off in combat and left in the world).
func remove_hat(hat_id: StringName) -> bool:
	var idx := owned_hats.find(hat_id)
	if idx < 0:
		return false
	owned_hats.remove_at(idx)
	if worn_hat == hat_id and not owns_hat(hat_id):
		_set_worn_hat_internal(&"")
	inventory_changed.emit()
	return true


func get_worn_hat() -> StringName:
	return worn_hat


func set_worn_hat(hat_id: StringName) -> bool:
	if not hat_id.is_empty() and not owns_hat(hat_id):
		return false
	if worn_hat == hat_id:
		return true
	_set_worn_hat_internal(hat_id)
	inventory_changed.emit()
	return true


func _set_worn_hat_internal(hat_id: StringName) -> void:
	if worn_hat == hat_id:
		return
	worn_hat = hat_id
	worn_hat_changed.emit(worn_hat)


func _apply_worn_hat_snapshot(snapshot: Dictionary) -> void:
	var worn := StringName(str(snapshot.get("worn_hat", COWBOY_HAT_ID)))
	if not worn.is_empty() and not owns_hat(worn):
		worn = owned_hats[0] if not owned_hats.is_empty() else &""
	_set_worn_hat_internal(worn)


func add_weapon(weapon_id: int) -> void:
	owned_weapons.append(weapon_id)
	inventory_changed.emit()


## Adds several copies of a consumable weapon (e.g. dynamite sticks) in one emit.
func add_weapon_count(weapon_id: int, count: int) -> void:
	if count <= 0:
		return
	for i in count:
		owned_weapons.append(weapon_id)
	inventory_changed.emit()


## Removes a single instance of a weapon (e.g. one thrown into the world).
func remove_one_weapon(weapon_id: int) -> void:
	var idx := owned_weapons.find(weapon_id)
	if idx < 0:
		return
	owned_weapons.remove_at(idx)
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


func set_has_ranch_key(value: bool) -> void:
	if has_ranch_key == value:
		return
	has_ranch_key = value
	inventory_changed.emit()


func set_has_treasure_map(value: bool) -> void:
	if has_treasure_map == value:
		return
	has_treasure_map = value
	inventory_changed.emit()


func set_has_deputy_badge(value: bool) -> void:
	if has_deputy_badge == value:
		return
	has_deputy_badge = value
	inventory_changed.emit()


func owns_weapon_type(weapon_id: int) -> bool:
	if weapon_id == GroyperWeapons.Id.UNARMED:
		return true
	return count_weapon(weapon_id) > 0


func get_unique_owned_weapons() -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	for weapon in owned_weapons:
		if seen.has(weapon):
			continue
		seen[weapon] = true
		result.append(weapon)
	# Fists are always available, cycled last.
	if not seen.has(GroyperWeapons.Id.UNARMED):
		result.append(GroyperWeapons.Id.UNARMED)
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
		GroyperWeapons.Id.UNARMED:
			return "Unarmed"
		GroyperWeapons.Id.BOW:
			return "Recurve Bow"
		GroyperWeapons.Id.SHOVEL:
			return "Shovel"
		GroyperWeapons.Id.SWORD_SHIELD:
			return "Sword & Shield"
		GroyperWeapons.Id.HAMMER:
			return "Hammer"
		GroyperWeapons.Id.AXE_1H:
			return "Axe"
		GroyperWeapons.Id.SWORD_1H:
			return "Sword"
		GroyperWeapons.Id.AXE_2H:
			return "Great Axe"
		GroyperWeapons.Id.SWORD_2H:
			return "Greatsword"
		GroyperWeapons.Id.HAMMER_2H:
			return "War Hammer"
		GroyperWeapons.Id.DYNAMITE:
			return "Dynamite"
		GroyperWeapons.Id.TORCH:
			return "Torch"
		GroyperWeapons.Id.AK47U:
			return "AK-47U"
		GroyperWeapons.Id.G36:
			return "G36"
		GroyperWeapons.Id.M1911:
			return "1911"
		GroyperWeapons.Id.GRENADE_LAUNCHER:
			return "Grenade Launcher"
		GroyperWeapons.Id.WINCHESTER:
			return "Winchester"
		GroyperWeapons.Id.M4XL:
			return "M4XL"
		GroyperWeapons.Id.DEATH_AXE:
			return "Death Axe"
		GroyperWeapons.Id.BASEBALL_BAT:
			return "Baseball Bat"
		GroyperWeapons.Id.BUSTER_SWORD:
			return "Buster Sword"
		GroyperWeapons.Id.LIGHTSABER:
			return "Lightsaber"
		GroyperWeapons.Id.POLESAW:
			return "Polesaw"
		GroyperWeapons.Id.LIFE_SWORD:
			return "Life Sword"
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
