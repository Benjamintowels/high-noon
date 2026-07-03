extends Area3D
class_name RuinsLootChest

const SWORD_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_grip.tscn")
const SHIELD_GRIP_SCENE := preload("res://characters/baldwin/equipment/shield_grip.tscn")
const SWORD_SHIELD_PICKUP_SCENE := preload("res://gameplay/world/sword_shield_pickup.tscn")

const LOOT_LIFT := 0.72
const LOOT_DROP_DISTANCE := 1.35
const LOOT_DROP_DURATION := 0.75

@export var requires_key := true

var _opened := false
var _player_in_range: Node3D
var _loot_display: Node3D

@onready var _chest: Node3D = $ChestBase


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_spawn_loot_display()


func get_interact_hint() -> String:
	if _opened or PlayerInventory.has_sword_shield:
		return ""
	if requires_key and not PlayerInventory.has_ruins_key:
		return "Locked (Need Key)"
	return "Open Chest"


func interact(player: Node3D) -> void:
	if _opened or player == null or PlayerInventory.has_sword_shield:
		return
	if requires_key and not PlayerInventory.has_ruins_key:
		return

	_opened = true
	if _chest != null and _chest.has_method("open_chest"):
		_chest.open_chest(1.5)

	_hide_loot_display()
	_drop_loot_pickup()

	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)


func _spawn_loot_display() -> void:
	if PlayerInventory.has_sword_shield:
		return

	_loot_display = Node3D.new()
	_loot_display.name = "LootDisplay"
	add_child(_loot_display)
	_loot_display.position = Vector3(0.0, LOOT_LIFT, 0.0)

	var sword: Node3D = SWORD_GRIP_SCENE.instantiate()
	sword.rotation_degrees = Vector3(75.0, 30.0, 0.0)
	sword.position = Vector3(-0.28, 0.0, 0.0)
	sword.scale = Vector3(1.25, 1.25, 1.25)
	_loot_display.add_child(sword)

	var shield: Node3D = SHIELD_GRIP_SCENE.instantiate()
	shield.rotation_degrees = Vector3(75.0, -20.0, 0.0)
	shield.position = Vector3(0.28, 0.0, 0.0)
	shield.scale = Vector3(1.1, 1.1, 1.1)
	_loot_display.add_child(shield)


func _drop_loot_pickup() -> void:
	if PlayerInventory.has_sword_shield:
		return

	var parent := get_parent()
	if parent == null:
		return

	var pickup := SWORD_SHIELD_PICKUP_SCENE.instantiate() as SwordShieldPickup
	if pickup == null:
		return

	pickup.snap_on_ready = false
	parent.add_child(pickup)

	var start_pos := global_position + Vector3(0.0, LOOT_LIFT, 0.0)
	var drop_dir := -global_transform.basis.z
	drop_dir.y = 0.0
	if drop_dir.length_squared() < 0.0001:
		drop_dir = Vector3.FORWARD
	else:
		drop_dir = drop_dir.normalized()

	var end_pos := global_position + drop_dir * LOOT_DROP_DISTANCE
	end_pos.y = start_pos.y - LOOT_LIFT + 0.05

	pickup.global_position = start_pos

	var tween := create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_QUAD)
	tween.tween_property(pickup, "global_position", end_pos, LOOT_DROP_DURATION)
	tween.tween_callback(pickup.snap_to_floor)


func _hide_loot_display() -> void:
	if _loot_display != null:
		_loot_display.visible = false


func _on_body_entered(body: Node3D) -> void:
	if _opened or PlayerInventory.has_sword_shield:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
