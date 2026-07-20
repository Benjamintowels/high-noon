extends Node

## Hub progression for Roguelike mode. Written to user://roguelike_save.json via
## RoguelikeSave — never adventure_save.json. Holds banked currency, quest
## flags, and the player's weapon storage chest.

var level := 1
var xp := 0
var unspent_levels := 0

var banked_gram := 0
var banked_soul_shards := 0

## Quest items successfully extracted to the hub this session.
var hub_quest_items: Array[StringName] = []
## Hub-side flags set when quest items are extracted (e.g. &"rare_seed" -> true).
var hub_quest_flags: Dictionary = {}

## Weapons stored in the hub chest (save-backed). Duplicates allowed.
var stored_weapons: Array[int] = []


func reset_for_session() -> void:
	level = 1
	xp = 0
	unspent_levels = 0
	banked_gram = 0
	banked_soul_shards = 0
	hub_quest_items.clear()
	hub_quest_flags.clear()
	stored_weapons.clear()


func capture_snapshot() -> Dictionary:
	var quest_items: Array = []
	for item_id in hub_quest_items:
		quest_items.append(String(item_id))
	var flags := {}
	for key in hub_quest_flags.keys():
		flags[String(key)] = bool(hub_quest_flags[key])
	return {
		"level": level,
		"xp": xp,
		"unspent_levels": unspent_levels,
		"banked_gram": banked_gram,
		"banked_soul_shards": banked_soul_shards,
		"hub_quest_items": quest_items,
		"hub_quest_flags": flags,
		"stored_weapons": stored_weapons.duplicate(),
	}


func apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.is_empty():
		return
	level = maxi(int(snapshot.get("level", 1)), 1)
	xp = maxi(int(snapshot.get("xp", 0)), 0)
	unspent_levels = maxi(int(snapshot.get("unspent_levels", 0)), 0)
	banked_gram = maxi(int(snapshot.get("banked_gram", 0)), 0)
	banked_soul_shards = maxi(int(snapshot.get("banked_soul_shards", 0)), 0)
	hub_quest_items.clear()
	var items: Variant = snapshot.get("hub_quest_items", [])
	if items is Array:
		for item_id in items:
			var name := StringName(str(item_id))
			if not name.is_empty() and not hub_quest_items.has(name):
				hub_quest_items.append(name)
	hub_quest_flags.clear()
	var flags: Variant = snapshot.get("hub_quest_flags", {})
	if flags is Dictionary:
		for key in flags.keys():
			hub_quest_flags[StringName(str(key))] = bool(flags[key])
	stored_weapons.clear()
	var weapons: Variant = snapshot.get("stored_weapons", [])
	if weapons is Array:
		for weapon_id in weapons:
			stored_weapons.append(int(weapon_id))


func store_weapon(weapon_id: int) -> void:
	if weapon_id == GroyperWeapons.Id.UNARMED:
		return
	stored_weapons.append(weapon_id)


func take_stored_weapon(weapon_id: int) -> bool:
	var idx := stored_weapons.find(weapon_id)
	if idx < 0:
		return false
	stored_weapons.remove_at(idx)
	return true


func count_stored_weapon(weapon_id: int) -> int:
	var count := 0
	for stored_id in stored_weapons:
		if stored_id == weapon_id:
			count += 1
	return count


func get_stored_weapons_unique() -> Array[int]:
	var result: Array[int] = []
	var seen: Dictionary = {}
	for weapon_id in stored_weapons:
		if seen.has(weapon_id):
			continue
		seen[weapon_id] = true
		result.append(weapon_id)
	return result


func add_xp(amount: int) -> void:
	if amount <= 0:
		return
	xp += amount
	while xp >= xp_to_next_level():
		xp -= xp_to_next_level()
		level += 1
		unspent_levels += 1


func xp_to_next_level() -> int:
	return 10 + (level - 1) * 5


func can_spend_soul_shards_for_level(cost: int = 10) -> bool:
	return PlayerInventory.get_soul_shards() >= cost


func spend_soul_shards_for_level(cost: int = 10) -> bool:
	if not can_spend_soul_shards_for_level(cost):
		return false
	if not PlayerInventory.spend_soul_shards(cost):
		return false
	level += 1
	unspent_levels += 1
	return true


## Move current inventory currency into the hub bank, then clear the wallet.
## Call before zeroing for a new run so hub cash is not lost.
func deposit_inventory_to_bank() -> void:
	banked_gram += maxi(PlayerInventory.gram, 0)
	banked_soul_shards += maxi(PlayerInventory.get_soul_shards(), 0)
	PlayerInventory.clear_currency()


func apply_bank_to_inventory() -> void:
	PlayerInventory.set_currency(banked_gram, banked_soul_shards)


## Add extracted run currency into the bank and sync inventory to bank totals.
func bank_extracted(gram_amount: int, shard_amount: int) -> void:
	banked_gram += maxi(gram_amount, 0)
	banked_soul_shards += maxi(shard_amount, 0)
	apply_bank_to_inventory()


func has_hub_quest_item(item_id: StringName) -> bool:
	return hub_quest_items.has(item_id)


func has_hub_quest_flag(flag: StringName) -> bool:
	if flag.is_empty():
		return false
	return bool(hub_quest_flags.get(flag, false))


func set_hub_quest_flag(flag: StringName, value: bool = true) -> void:
	if flag.is_empty():
		return
	if value:
		hub_quest_flags[flag] = true
	else:
		hub_quest_flags.erase(flag)


func grant_hub_quest_item(item_id: StringName) -> void:
	if item_id.is_empty() or hub_quest_items.has(item_id):
		return
	hub_quest_items.append(item_id)
	hub_quest_flags[item_id] = true


func extract_quest_items(run_items: Array[StringName]) -> Array[StringName]:
	var granted: Array[StringName] = []
	for item_id in run_items:
		if item_id.is_empty() or hub_quest_items.has(item_id):
			continue
		grant_hub_quest_item(item_id)
		granted.append(item_id)
	return granted
