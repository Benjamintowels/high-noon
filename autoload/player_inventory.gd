extends Node

signal inventory_changed
signal worn_hat_changed(hat_id: StringName)

const GroyperHatCatalog := preload("res://characters/groyper/groyper_hat_catalog.gd")
const ElementalGems := preload("res://gameplay/items/elemental_gems.gd")

const STARTING_GRAM := 20
## Carry-weight resistance. 1 matches the baseline weapon slowdown curve;
## higher Strength reduces how much equipped weight taxes walk/run speed.
const STARTING_STRENGTH := 1
const COWBOY_HAT_ID := &"cowboy"
const REVOLVER_AMMO_MAX := 100
const STARTING_REVOLVER_AMMO := 0
# Bow arrows are a persistent reserve (like revolver ammo), NOT refilled on
# every draw. Mirrors GroyperWeapons BOW max_ammo — keep in sync.
const BOW_AMMO_MAX := 100
const STARTING_BOW_AMMO := 10

var gram := STARTING_GRAM
var strength := STARTING_STRENGTH
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
## Free (unequipped) elemental gems in inventory.
var owned_elemental_gems: Array[StringName] = []
## Per weapon-type embedded gems. Keys are stringified weapon ids for JSON.
var weapon_embedded_gems: Dictionary = {}


func reset_for_new_game() -> void:
	PlayerDeathLoot.clear_active_loot()
	gram = STARTING_GRAM
	strength = STARTING_STRENGTH
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
	owned_elemental_gems = []
	weapon_embedded_gems = {}
	inventory_changed.emit()


func reset_for_home_start() -> void:
	PlayerDeathLoot.clear_active_loot()
	gram = STARTING_GRAM
	strength = STARTING_STRENGTH
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
	owned_elemental_gems = []
	weapon_embedded_gems = {}
	inventory_changed.emit()


func capture_snapshot() -> Dictionary:
	return {
		"gram": gram,
		"strength": strength,
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
		"owned_elemental_gems": _snapshot_gem_array(owned_elemental_gems),
		"weapon_embedded_gems": _snapshot_weapon_embedded_gems(),
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	gram = int(snapshot.get("gram", STARTING_GRAM))
	strength = maxi(int(snapshot.get("strength", STARTING_STRENGTH)), 1)
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
	owned_elemental_gems = _duplicate_gem_array(snapshot.get("owned_elemental_gems", []))
	weapon_embedded_gems = _duplicate_weapon_embedded_gems(snapshot.get("weapon_embedded_gems", {}))
	reconcile_owned_sword_shield()
	_reconcile_weapon_embedded_gems()
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


func get_strength() -> int:
	return maxi(strength, 1)


func set_strength(amount: int, emit: bool = true) -> void:
	var clamped := maxi(amount, 1)
	if clamped == strength:
		return
	strength = clamped
	if emit:
		inventory_changed.emit()


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


func get_owned_elemental_gems() -> Array[StringName]:
	return owned_elemental_gems.duplicate()


func add_elemental_gem(gem_id: StringName) -> bool:
	if not ElementalGems.is_valid(gem_id):
		return false
	owned_elemental_gems.append(gem_id)
	# Fresh pickups auto-seat into the equipped/next weapon with a free slot.
	if _auto_embed_gem_on_next_open_slot(gem_id):
		return true
	inventory_changed.emit()
	return true


## Walk unique owned weapons starting at the player's current weapon (then next
## in cycle order) and embed `gem_id` into the first free slot. Returns true if
## embedded (embed_gem already emitted inventory_changed).
func _auto_embed_gem_on_next_open_slot(gem_id: StringName) -> bool:
	var weapons := get_unique_owned_weapons()
	if weapons.is_empty():
		return false
	var start_index := weapons.find(_resolve_current_weapon_for_gem_attach())
	if start_index < 0:
		start_index = 0
	for offset in weapons.size():
		var weapon_id: int = weapons[(start_index + offset) % weapons.size()]
		if get_free_gem_slot(weapon_id) < 0:
			continue
		return embed_gem(weapon_id, gem_id)
	return false


func _resolve_current_weapon_for_gem_attach() -> int:
	var tree: SceneTree = null
	if is_inside_tree():
		tree = get_tree()
	else:
		var main_loop := Engine.get_main_loop()
		if main_loop is SceneTree:
			tree = main_loop as SceneTree
	if tree == null:
		return -1
	for node in tree.get_nodes_in_group("overworld_player"):
		if not is_instance_valid(node):
			continue
		# Match weapon-cycle "current" during mid-swap putaways.
		if bool(node.get("_pending_unarmed_equip")):
			return GroyperWeapons.Id.UNARMED
		if bool(node.get("_pending_weapon_equip")):
			return int(node.get("_pending_weapon_equip_id"))
		if bool(node.get("_pending_melee_holster")):
			return int(node.get("_pending_melee_holster_weapon"))
		var equipped: Variant = node.get("_equipped_weapon")
		if equipped != null:
			return int(equipped)
	return -1


func count_free_elemental_gem(gem_id: StringName) -> int:
	var count := 0
	for owned_id in owned_elemental_gems:
		if owned_id == gem_id:
			count += 1
	return count


func get_embedded_gems(weapon_id: int) -> Array[StringName]:
	var key := _weapon_gem_key(weapon_id)
	var result: Array[StringName] = []
	var slots: Variant = weapon_embedded_gems.get(key, [])
	if slots is Array:
		for entry in slots:
			var gem_id := StringName(str(entry))
			if ElementalGems.is_valid(gem_id):
				result.append(gem_id)
	return result


func weapon_has_gem(weapon_id: int, gem_id: StringName) -> bool:
	return get_embedded_gems(weapon_id).has(gem_id)


func get_free_gem_slot(weapon_id: int) -> int:
	var max_slots := GroyperWeapons.get_gem_slots(weapon_id as GroyperWeapons.Id)
	if max_slots <= 0:
		return -1
	var embedded := get_embedded_gems(weapon_id)
	if embedded.size() >= max_slots:
		return -1
	return embedded.size()


func embed_gem(weapon_id: int, gem_id: StringName) -> bool:
	if not ElementalGems.is_valid(gem_id):
		return false
	if not owns_weapon_type(weapon_id):
		return false
	var free_slot := get_free_gem_slot(weapon_id)
	if free_slot < 0:
		return false
	var free_idx := owned_elemental_gems.find(gem_id)
	if free_idx < 0:
		return false
	owned_elemental_gems.remove_at(free_idx)
	var key := _weapon_gem_key(weapon_id)
	var slots: Array = []
	var existing: Variant = weapon_embedded_gems.get(key, [])
	if existing is Array:
		for entry in existing:
			var existing_id := StringName(str(entry))
			if ElementalGems.is_valid(existing_id):
				slots.append(existing_id)
	slots.append(gem_id)
	weapon_embedded_gems[key] = slots
	inventory_changed.emit()
	return true


## Remove one embedded gem from a weapon slot and return it to free inventory.
func remove_embedded_gem(weapon_id: int, slot: int = 0) -> bool:
	var gem_id := _pop_embedded_gem(weapon_id, slot)
	if gem_id.is_empty():
		return false
	owned_elemental_gems.append(gem_id)
	inventory_changed.emit()
	return true


## Attach a free gem, or move/swap an embedded gem from another weapon onto `target`.
## `source_weapon_id` < 0 means take from free inventory.
func assign_gem_to_weapon(
	target_weapon_id: int,
	gem_id: StringName,
	source_weapon_id: int = -1
) -> bool:
	if not ElementalGems.is_valid(gem_id):
		return false
	if not owns_weapon_type(target_weapon_id):
		return false
	if GroyperWeapons.get_gem_slots(target_weapon_id as GroyperWeapons.Id) <= 0:
		return false
	if source_weapon_id == target_weapon_id:
		return false

	if source_weapon_id < 0:
		if owned_elemental_gems.find(gem_id) < 0:
			return false
		# Full slot: displace current gem back to free, then embed the chosen free gem.
		if get_free_gem_slot(target_weapon_id) < 0:
			var displaced := _pop_embedded_gem(target_weapon_id, 0)
			if not displaced.is_empty():
				owned_elemental_gems.append(displaced)
		return embed_gem(target_weapon_id, gem_id)

	if not owns_weapon_type(source_weapon_id):
		return false
	var source_gems := get_embedded_gems(source_weapon_id)
	var source_slot := source_gems.find(gem_id)
	if source_slot < 0:
		return false

	var moved := _pop_embedded_gem(source_weapon_id, source_slot)
	if moved.is_empty():
		return false

	var displaced := &""
	if get_free_gem_slot(target_weapon_id) < 0:
		displaced = _pop_embedded_gem(target_weapon_id, 0)

	_push_embedded_gem(target_weapon_id, moved)
	if not displaced.is_empty():
		# True swap: displaced gem lands on the source weapon.
		_push_embedded_gem(source_weapon_id, displaced)
	inventory_changed.emit()
	return true


## Locations of every embedded gem for UI pickers.
## Each entry: { "weapon_id": int, "gem_id": StringName, "slot": int }
func get_embedded_gem_locations() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for weapon_id in get_unique_owned_weapons():
		var gems := get_embedded_gems(weapon_id)
		for slot_i in gems.size():
			result.append({
				"weapon_id": weapon_id,
				"gem_id": gems[slot_i],
				"slot": slot_i,
			})
	return result


func _pop_embedded_gem(weapon_id: int, slot: int) -> StringName:
	var key := _weapon_gem_key(weapon_id)
	var slots: Array = []
	var existing: Variant = weapon_embedded_gems.get(key, [])
	if existing is Array:
		for entry in existing:
			var existing_id := StringName(str(entry))
			if ElementalGems.is_valid(existing_id):
				slots.append(existing_id)
	if slot < 0 or slot >= slots.size():
		return &""
	var gem_id: StringName = slots[slot]
	slots.remove_at(slot)
	if slots.is_empty():
		weapon_embedded_gems.erase(key)
	else:
		weapon_embedded_gems[key] = slots
	return gem_id


func _push_embedded_gem(weapon_id: int, gem_id: StringName) -> void:
	if not ElementalGems.is_valid(gem_id):
		return
	var key := _weapon_gem_key(weapon_id)
	var slots: Array = []
	var existing: Variant = weapon_embedded_gems.get(key, [])
	if existing is Array:
		for entry in existing:
			var existing_id := StringName(str(entry))
			if ElementalGems.is_valid(existing_id):
				slots.append(existing_id)
	slots.append(gem_id)
	weapon_embedded_gems[key] = slots


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
	if count_weapon(weapon_id) <= 0 and weapon_id != GroyperWeapons.Id.UNARMED:
		_return_embedded_gems_to_free(weapon_id)
	inventory_changed.emit()


## Roguelike death extract: lose everything carried; keep the starting revolver.
func reset_weapons_after_failed_extract() -> void:
	_return_all_embedded_gems_except([GroyperWeapons.Id.REVOLVER, GroyperWeapons.Id.UNARMED])
	owned_weapons = [GroyperWeapons.Id.REVOLVER]
	has_knife = false
	has_sword_shield = false
	inventory_changed.emit()


## Roguelike victory extract: keep exactly one chosen weapon type (one copy).
func keep_only_extracted_weapon(weapon_id: int) -> void:
	var keep_ids: Array[int] = [GroyperWeapons.Id.UNARMED]
	if weapon_id == GroyperWeapons.Id.UNARMED or weapon_id < 0:
		keep_ids.append(GroyperWeapons.Id.REVOLVER)
	else:
		keep_ids.append(weapon_id)
	_return_all_embedded_gems_except(keep_ids)
	has_knife = false
	has_sword_shield = false
	owned_weapons = []
	if weapon_id == GroyperWeapons.Id.UNARMED or weapon_id < 0:
		owned_weapons = [GroyperWeapons.Id.REVOLVER]
	elif weapon_id == GroyperWeapons.Id.SWORD_SHIELD:
		has_sword_shield = true
		_sync_sword_shield_weapon_entry()
	else:
		owned_weapons = [weapon_id]
	inventory_changed.emit()


## Unique owned weapons eligible for victory extract (excludes fists).
func get_extractable_weapons() -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	for weapon_id in owned_weapons:
		if weapon_id == GroyperWeapons.Id.UNARMED:
			continue
		if seen.has(weapon_id):
			continue
		seen[weapon_id] = true
		result.append(weapon_id)
	return result


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
	var owned_after := owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD)
	if owned_before and not owned_after:
		_return_embedded_gems_to_free(GroyperWeapons.Id.SWORD_SHIELD)
	if changed or owned_before != owned_after:
		inventory_changed.emit()


func reconcile_owned_sword_shield() -> void:
	var owned_before := owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD)
	_sync_sword_shield_weapon_entry()
	var owned_after := owns_weapon_type(GroyperWeapons.Id.SWORD_SHIELD)
	if owned_before and not owned_after:
		_return_embedded_gems_to_free(GroyperWeapons.Id.SWORD_SHIELD)
	if owned_before != owned_after:
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


func _weapon_gem_key(weapon_id: int) -> String:
	return str(weapon_id)


func _snapshot_gem_array(source: Array[StringName]) -> Array:
	var result: Array = []
	for gem_id in source:
		result.append(String(gem_id))
	return result


func _duplicate_gem_array(source: Variant) -> Array[StringName]:
	var result: Array[StringName] = []
	if source is Array:
		for item in source:
			var gem_id := StringName(str(item))
			if ElementalGems.is_valid(gem_id):
				result.append(gem_id)
	return result


func _snapshot_weapon_embedded_gems() -> Dictionary:
	var result := {}
	for key in weapon_embedded_gems.keys():
		var slots: Array = []
		var existing: Variant = weapon_embedded_gems[key]
		if existing is Array:
			for entry in existing:
				var gem_id := StringName(str(entry))
				if ElementalGems.is_valid(gem_id):
					slots.append(String(gem_id))
		if not slots.is_empty():
			result[str(key)] = slots
	return result


func _duplicate_weapon_embedded_gems(source: Variant) -> Dictionary:
	var result := {}
	if source is Dictionary:
		for key in source.keys():
			var slots: Array = []
			var existing: Variant = source[key]
			if existing is Array:
				for entry in existing:
					var gem_id := StringName(str(entry))
					if ElementalGems.is_valid(gem_id):
						slots.append(gem_id)
			if not slots.is_empty():
				result[str(key)] = slots
	return result


func _return_embedded_gems_to_free(weapon_id: int) -> void:
	var key := _weapon_gem_key(weapon_id)
	var existing: Variant = weapon_embedded_gems.get(key, [])
	if existing is Array:
		for entry in existing:
			var gem_id := StringName(str(entry))
			if ElementalGems.is_valid(gem_id):
				owned_elemental_gems.append(gem_id)
	weapon_embedded_gems.erase(key)


func _return_all_embedded_gems_except(keep_weapon_ids: Array[int]) -> void:
	var keep: Dictionary = {}
	for weapon_id in keep_weapon_ids:
		keep[_weapon_gem_key(weapon_id)] = true
	var keys := weapon_embedded_gems.keys()
	for key in keys:
		if keep.has(str(key)):
			continue
		var existing: Variant = weapon_embedded_gems[key]
		if existing is Array:
			for entry in existing:
				var gem_id := StringName(str(entry))
				if ElementalGems.is_valid(gem_id):
					owned_elemental_gems.append(gem_id)
		weapon_embedded_gems.erase(key)


## Drop embeddings for weapon types no longer owned (except Unarmed).
func _reconcile_weapon_embedded_gems() -> void:
	var keys := weapon_embedded_gems.keys()
	for key in keys:
		var weapon_id := int(str(key))
		if weapon_id == GroyperWeapons.Id.UNARMED:
			continue
		if owns_weapon_type(weapon_id):
			var max_slots := GroyperWeapons.get_gem_slots(weapon_id as GroyperWeapons.Id)
			var slots: Array = []
			var existing: Variant = weapon_embedded_gems[key]
			if existing is Array:
				for entry in existing:
					var gem_id := StringName(str(entry))
					if ElementalGems.is_valid(gem_id):
						slots.append(gem_id)
			while slots.size() > max_slots:
				var overflow: StringName = slots.pop_back()
				owned_elemental_gems.append(overflow)
			if slots.is_empty():
				weapon_embedded_gems.erase(key)
			else:
				weapon_embedded_gems[key] = slots
		else:
			_return_embedded_gems_to_free(weapon_id)
