extends Area3D
class_name RuinsLootChest
## Interactable chest. Supports key lock (ruins sword/shield) or soul-shard
## lock (quest chests that permanently mark opened and drop dynamite/etc).

const SWORD_GRIP_SCENE := preload("res://characters/baldwin/equipment/sword_grip.tscn")
const SHIELD_GRIP_SCENE := preload("res://characters/baldwin/equipment/shield_grip.tscn")
const SWORD_SHIELD_PICKUP_SCENE := preload("res://gameplay/world/sword_shield_pickup.tscn")
const DYNAMITE_PICKUP_SCENE := preload("res://gameplay/world/dynamite_pickup.tscn")

const LOOT_LIFT := 0.72
const LOOT_DROP_DISTANCE := 1.35
const LOOT_DROP_DURATION := 0.75
const FALLBACK_DISPLAY_HEIGHT := 1.55

enum LockMode {
	NONE,
	KEY,
	SOUL_SHARDS,
}

enum LootKind {
	SWORD_SHIELD,
	DYNAMITE,
}

@export var lock_mode := LockMode.KEY
@export var requires_key := true
@export var chest_id: StringName = &""
@export var soul_shard_cost := 15
@export var loot_kind := LootKind.SWORD_SHIELD
@export var dynamite_ammo := 5

var _opened := false
var _requirement_revealed := false
var _dialog_busy := false
var _player_in_range: Node3D
var _loot_display: Node3D
var _requirement_root: Node3D
var _requirement_label: Label3D

@onready var _chest: Node3D = $ChestBase
@onready var _display_position: Marker3D = get_node_or_null("DisplayPosition") as Marker3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if requires_key and lock_mode == LockMode.NONE:
		lock_mode = LockMode.KEY
	if _is_permanently_opened():
		_opened = true
		return
	_spawn_loot_display()
	if lock_mode == LockMode.SOUL_SHARDS:
		_build_requirement_display()
		if not PlayerInventory.inventory_changed.is_connected(_on_inventory_changed):
			PlayerInventory.inventory_changed.connect(_on_inventory_changed)


func get_interact_hint() -> String:
	if _opened or _is_permanently_opened():
		return ""
	if _dialog_busy:
		return ""
	match lock_mode:
		LockMode.KEY:
			if not PlayerInventory.has_ruins_key:
				return "Locked (Need Key)"
		LockMode.SOUL_SHARDS:
			if not _requirement_revealed:
				return "Inspect Chest"
			if PlayerInventory.get_soul_shards() < soul_shard_cost:
				return "Need Soul Shards"
			return "Open Chest (%d)" % soul_shard_cost
		_:
			pass
	return "Open Chest"


func interact(player: Node3D) -> void:
	if _opened or player == null or _is_permanently_opened() or _dialog_busy:
		return

	if lock_mode == LockMode.KEY and not PlayerInventory.has_ruins_key:
		return

	if lock_mode == LockMode.SOUL_SHARDS:
		if not _requirement_revealed:
			_play_locked_inspect(player)
			return
		if not PlayerInventory.spend_soul_shards(soul_shard_cost):
			return

	_open_chest(player)


func _play_locked_inspect(player: Node3D) -> void:
	_dialog_busy = true
	if player.has_method("set_dialog_active"):
		player.set_dialog_active(true)
	DialogManager.show_dialog_sequence(
		PackedStringArray([
			"It's locked.",
			"It doesn't look like it takes Keys.",
		]),
		func() -> void:
			DialogManager.hide_dialog()
			if player != null and is_instance_valid(player) and player.has_method("set_dialog_active"):
				player.set_dialog_active(false)
			_dialog_busy = false
			_requirement_revealed = true
			_show_requirement_display()
			_refresh_requirement_label()
	)


func _open_chest(player: Node3D) -> void:
	_opened = true
	if chest_id != &"":
		LootChestProgress.mark_opened(chest_id)

	if _chest != null and _chest.has_method("open_chest"):
		_chest.open_chest(1.5)

	_hide_loot_display()
	_hide_requirement_display()
	_drop_loot_pickup()

	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	elif player != null and player.has_method("unregister_interactable"):
		player.unregister_interactable(self)


func _is_permanently_opened() -> bool:
	if chest_id != &"" and LootChestProgress.is_opened(chest_id):
		return true
	if loot_kind == LootKind.SWORD_SHIELD and PlayerInventory.has_sword_shield:
		return true
	return false


func _attach_chest_display(node: Node3D) -> void:
	# Prefer the scene marker so per-chest placement stays editable in the editor.
	if _display_position != null:
		_display_position.add_child(node)
		node.position = Vector3.ZERO
		return
	add_child(node)
	node.position = Vector3(0.0, FALLBACK_DISPLAY_HEIGHT, 0.0)


func _get_display_global_position() -> Vector3:
	if _display_position != null:
		return _display_position.global_position
	return global_position + Vector3(0.0, LOOT_LIFT, 0.0)


func _spawn_loot_display() -> void:
	if loot_kind != LootKind.SWORD_SHIELD:
		return
	if PlayerInventory.has_sword_shield:
		return

	_loot_display = Node3D.new()
	_loot_display.name = "LootDisplay"
	_attach_chest_display(_loot_display)

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


func _build_requirement_display() -> void:
	_requirement_root = Node3D.new()
	_requirement_root.name = "SoulShardRequirement"
	_attach_chest_display(_requirement_root)
	_requirement_root.visible = false

	var shard := MeshInstance3D.new()
	var mesh := PrismMesh.new()
	mesh.size = Vector3(0.16, 0.24, 0.1)
	shard.mesh = mesh
	shard.position = Vector3(-0.28, 0.0, 0.0)
	shard.rotation_degrees = Vector3(18.0, 32.0, 12.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.78, 0.22, 0.55, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.95, 0.35, 0.7, 1.0)
	mat.emission_energy_multiplier = 1.4
	shard.material_override = mat
	_requirement_root.add_child(shard)

	_requirement_label = Label3D.new()
	_requirement_label.name = "RequirementLabel"
	_requirement_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_requirement_label.font_size = 48
	_requirement_label.outline_size = 8
	_requirement_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
	_requirement_label.outline_modulate = Color(0.05, 0.02, 0.08, 0.9)
	_requirement_label.position = Vector3(0.18, 0.0, 0.0)
	_requirement_label.pixel_size = 0.012
	_requirement_root.add_child(_requirement_label)
	_refresh_requirement_label()


func _show_requirement_display() -> void:
	if _requirement_root == null:
		return
	_requirement_root.visible = true
	if _requirement_label == null:
		return
	_requirement_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(_requirement_label, "modulate:a", 1.0, 0.45)\
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hide_requirement_display() -> void:
	if _requirement_root != null:
		_requirement_root.visible = false


func _refresh_requirement_label() -> void:
	if _requirement_label == null:
		return
	var have := PlayerInventory.get_soul_shards()
	_requirement_label.text = "%d/%d" % [have, soul_shard_cost]
	if have >= soul_shard_cost:
		_requirement_label.modulate = Color(0.75, 1.0, 0.7, 1.0)
	else:
		_requirement_label.modulate = Color(1.0, 1.0, 1.0, 1.0)


func _on_inventory_changed() -> void:
	if _opened or not _requirement_revealed:
		return
	_refresh_requirement_label()


func _drop_loot_pickup() -> void:
	var parent := get_parent()
	if parent == null:
		return

	match loot_kind:
		LootKind.SWORD_SHIELD:
			_drop_sword_shield(parent)
		LootKind.DYNAMITE:
			_drop_dynamite(parent)


func _drop_sword_shield(parent: Node) -> void:
	if PlayerInventory.has_sword_shield:
		return
	var pickup := SWORD_SHIELD_PICKUP_SCENE.instantiate() as SwordShieldPickup
	if pickup == null:
		return
	pickup.snap_on_ready = false
	parent.add_child(pickup)
	_tween_loot_to_ground(pickup)


func _drop_dynamite(parent: Node) -> void:
	var pickup: Node = DYNAMITE_PICKUP_SCENE.instantiate()
	if pickup == null:
		return
	if "ammo_amount" in pickup:
		pickup.ammo_amount = dynamite_ammo
	if "snap_on_ready" in pickup:
		pickup.snap_on_ready = false
	parent.add_child(pickup)
	_tween_loot_to_ground(pickup)


func _tween_loot_to_ground(pickup: Node3D) -> void:
	var start_pos := _get_display_global_position()
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


func _hide_loot_display() -> void:
	if _loot_display != null:
		_loot_display.visible = false


func _on_body_entered(body: Node3D) -> void:
	if _opened or _is_permanently_opened():
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
