extends Node3D

const SHOP_KEEPER_SCENE := preload("res://characters/groyper/shop_keeper_npc.tscn")
const SHOP_ITEM_SCENE := preload("res://gameplay/world/shop_item_display.tscn")
const WOOD_PROP_COLLISION := preload("res://gameplay/world/wood_prop_collision.gd")
const WOOD_BULLET_COVER := preload("res://gameplay/world/wood_bullet_cover.gd")


func _ready() -> void:
	WOOD_PROP_COLLISION.apply_to(self)
	WOOD_BULLET_COVER.apply_to(self)
	_spawn_shopkeeper()
	_spawn_shop_items()


func _spawn_shopkeeper() -> void:
	var marker := get_node_or_null("ShopKeep") as Marker3D
	if marker == null:
		push_warning("ShopInterior: missing ShopKeep marker.")
		return

	var keeper: Node3D = SHOP_KEEPER_SCENE.instantiate()
	add_child(keeper)
	keeper.global_transform = marker.global_transform


func _spawn_shop_items() -> void:
	_spawn_shop_item("Items", GroyperWeapons.Id.SHOTGUN, 20, "Shotgun")
	_spawn_shop_item("Items2", GroyperWeapons.Id.REVOLVER, 15, "Revolver")


func _spawn_shop_item(
	marker_name: String,
	weapon_id: GroyperWeapons.Id,
	price_gram: int,
	display_name: String
) -> void:
	var marker := get_node_or_null(marker_name) as Marker3D
	if marker == null:
		push_warning("ShopInterior: missing %s marker." % marker_name)
		return

	var item: ShopItemDisplay = SHOP_ITEM_SCENE.instantiate()
	item.weapon_id = weapon_id
	item.price_gram = price_gram
	item.display_name = display_name
	add_child(item)
	item.global_transform = marker.global_transform
