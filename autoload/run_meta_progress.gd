extends Node

## Session-scoped hub progression for Roguelike mode. Not written to
## adventure_save.json. Holds banked currency extracted from runs plus
## victory-only quest item flags.

var level := 1
var xp := 0
var unspent_levels := 0

var banked_gram := 0
var banked_soul_shards := 0

## Quest items successfully extracted to the hub this session.
var hub_quest_items: Array[StringName] = []
## Hub-side flags set when quest items are extracted (e.g. &"rare_seed" -> true).
var hub_quest_flags: Dictionary = {}


func reset_for_session() -> void:
	level = 1
	xp = 0
	unspent_levels = 0
	banked_gram = 0
	banked_soul_shards = 0
	hub_quest_items.clear()
	hub_quest_flags.clear()


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
