extends Node

const LootBagPickupScript := preload("res://gameplay/world/loot_bag_pickup.gd")

var _stage_path := ""
var _position := Vector3.ZERO
var _gram := 0
var _soul_shards := 0
var _spawned_bag: LootBagPickup


func has_active_loot() -> bool:
	return _gram > 0 or _soul_shards > 0


func drop_player_loot(stage: Node, death_position: Vector3) -> void:
	_discard_active_loot()

	var currency := PlayerInventory.take_all_currency()
	_gram = int(currency.get("gram", 0))
	_soul_shards = int(currency.get("soul_shards", 0))
	if not has_active_loot():
		return

	_stage_path = stage.scene_file_path if stage != null else ""
	_position = death_position
	_spawn_bag_in_stage(stage)


func restore_loot_bag_for_stage(stage: Node) -> void:
	if stage == null or not has_active_loot():
		return
	if stage.scene_file_path != _stage_path:
		return
	if _spawned_bag != null and is_instance_valid(_spawned_bag):
		return
	_spawn_bag_in_stage(stage)


func notify_loot_bag_collected() -> void:
	_stage_path = ""
	_position = Vector3.ZERO
	_gram = 0
	_soul_shards = 0
	_spawned_bag = null


func clear_active_loot() -> void:
	_discard_active_loot()


func _discard_active_loot() -> void:
	if _spawned_bag != null and is_instance_valid(_spawned_bag):
		_spawned_bag.queue_free()
	_spawned_bag = null
	_stage_path = ""
	_position = Vector3.ZERO
	_gram = 0
	_soul_shards = 0


func _spawn_bag_in_stage(stage: Node) -> void:
	if stage == null or not has_active_loot():
		return
	if stage.scene_file_path != _stage_path:
		return

	var bag := LootBagPickupScript.spawn_death_drop(
		stage,
		_position,
		_gram,
		_soul_shards
	)
	if bag == null:
		return

	_spawned_bag = bag
	bag.tree_exiting.connect(func() -> void:
		if _spawned_bag == bag:
			_spawned_bag = null
	)
