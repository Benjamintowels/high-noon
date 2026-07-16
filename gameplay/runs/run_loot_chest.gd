extends Area3D

## Run-local loot chest. Never writes LootChestProgress / adventure_save.
## Free / gram / soul-shard locks with MegaBonk-style escalating costs.
## Drops a wheel weapon, or rarely Horsey.

const WeaponPickupScript := preload("res://gameplay/world/weapon_pickup.gd")
const CHEST_VISUAL_SCENE := preload("res://Assets/World/RuinsGR/AccessoriesScenes/ChestBase.tscn")
const HORSEY_SCENE := preload("res://characters/animals/horsey_horse.tscn")

const LOOT_DROP_DISTANCE := 1.35
const LOOT_DROP_DURATION := 0.75
## Chest mesh top is ~0.9m; float the cost label clearly above the lid.
const FALLBACK_DISPLAY_HEIGHT := 2.65

enum LockMode { FREE, GRAM, SOUL_SHARDS }

const WEAPON_POOL: Array[int] = [
	GroyperWeapons.Id.REVOLVER,
	GroyperWeapons.Id.MAC10,
	GroyperWeapons.Id.SHOTGUN,
	GroyperWeapons.Id.RPG,
	GroyperWeapons.Id.AWP,
	GroyperWeapons.Id.AK47,
	GroyperWeapons.Id.BOW,
	GroyperWeapons.Id.SHOVEL,
	GroyperWeapons.Id.HAMMER,
	GroyperWeapons.Id.AXE_1H,
]

@export var lock_mode := LockMode.FREE
@export var gram_base_cost := 25
@export var gram_cost_mult := 1.75
@export var shard_base_cost := 3
@export var shard_cost_mult := 1.6
@export var horsey_chance := 0.03
@export var rare_seed_chance := 0.0

var _opened := false
var _player_in_range: Node3D
var _chest: Node3D
var _requirement_label: Label3D
var _display_position: Marker3D


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1
	monitorable = false
	monitoring = true
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_ensure_visuals()
	_build_cost_label()
	if not PlayerInventory.inventory_changed.is_connected(_on_inventory_changed):
		PlayerInventory.inventory_changed.connect(_on_inventory_changed)
	_refresh_cost_label()


func configure(
	mode: int,
	gram_base: int,
	gram_mult: float,
	shard_base: int,
	shard_mult: float,
	horsey: float,
	seed_chance: float
) -> void:
	lock_mode = mode as LockMode
	gram_base_cost = gram_base
	gram_cost_mult = gram_mult
	shard_base_cost = shard_base
	shard_cost_mult = shard_mult
	horsey_chance = horsey
	rare_seed_chance = seed_chance
	if is_inside_tree():
		if _requirement_label == null and lock_mode != LockMode.FREE:
			_build_cost_label()
		_refresh_cost_label()


func get_interact_hint() -> String:
	if _opened:
		return ""
	match lock_mode:
		LockMode.GRAM:
			var cost := _current_gram_cost()
			if PlayerInventory.gram < cost:
				return "Need Gram (%d)" % cost
			return "Open Chest (%d Gram)" % cost
		LockMode.SOUL_SHARDS:
			var shard_cost := _current_shard_cost()
			if PlayerInventory.get_soul_shards() < shard_cost:
				return "Need Soul Shards (%d)" % shard_cost
			return "Open Chest (%d Shards)" % shard_cost
		_:
			return "Open Chest"


func interact(player: Node3D) -> void:
	if _opened or player == null:
		return
	match lock_mode:
		LockMode.GRAM:
			var cost := _current_gram_cost()
			if not PlayerInventory.spend_gram(cost):
				return
			RunState.note_gram_chest_opened()
		LockMode.SOUL_SHARDS:
			var shard_cost := _current_shard_cost()
			if not PlayerInventory.spend_soul_shards(shard_cost):
				return
			RunState.note_shard_chest_opened()
		_:
			pass
	_open_chest(player)


func _current_gram_cost() -> int:
	return RunState.get_gram_chest_cost(gram_base_cost, gram_cost_mult)


func _current_shard_cost() -> int:
	return RunState.get_shard_chest_cost(shard_base_cost, shard_cost_mult)


func _ensure_visuals() -> void:
	_chest = get_node_or_null("ChestBase") as Node3D
	if _chest == null:
		_chest = CHEST_VISUAL_SCENE.instantiate() as Node3D
		_chest.name = "ChestBase"
		add_child(_chest)
	_display_position = get_node_or_null("DisplayPosition") as Marker3D
	if _display_position == null:
		_display_position = Marker3D.new()
		_display_position.name = "DisplayPosition"
		_display_position.position = Vector3(0.0, FALLBACK_DISPLAY_HEIGHT, 0.0)
		add_child(_display_position)
	if get_node_or_null("CollisionShape3D") == null:
		var shape_node := CollisionShape3D.new()
		var box := BoxShape3D.new()
		box.size = Vector3(2.4, 1.8, 2.4)
		shape_node.shape = box
		shape_node.position = Vector3(0.0, 0.9, 0.0)
		add_child(shape_node)


func _build_cost_label() -> void:
	if lock_mode == LockMode.FREE:
		return
	_requirement_label = Label3D.new()
	_requirement_label.name = "CostLabel"
	_requirement_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_requirement_label.no_depth_test = true
	_requirement_label.font_size = 56
	_requirement_label.outline_size = 10
	_requirement_label.pixel_size = 0.014
	_requirement_label.outline_modulate = Color(0.05, 0.02, 0.08, 0.9)
	_display_position.add_child(_requirement_label)
	_requirement_label.position = Vector3.ZERO


func _refresh_cost_label() -> void:
	if _requirement_label == null or _opened:
		return
	match lock_mode:
		LockMode.GRAM:
			var cost := _current_gram_cost()
			_requirement_label.text = "%d Gram" % cost
			_requirement_label.modulate = (
				Color(0.7, 1.0, 0.75, 1.0)
				if PlayerInventory.gram >= cost
				else Color(1.0, 0.85, 0.55, 1.0)
			)
		LockMode.SOUL_SHARDS:
			var shard_cost := _current_shard_cost()
			_requirement_label.text = "%d Shards" % shard_cost
			_requirement_label.modulate = (
				Color(0.85, 0.55, 0.95, 1.0)
				if PlayerInventory.get_soul_shards() >= shard_cost
				else Color(1.0, 0.7, 0.85, 1.0)
			)
		_:
			_requirement_label.text = ""


func _on_inventory_changed() -> void:
	_refresh_cost_label()


func _open_chest(player: Node3D) -> void:
	_opened = true
	if _chest != null and _chest.has_method("open_chest"):
		_chest.open_chest(1.5)
	if _requirement_label != null:
		_requirement_label.visible = false

	if _player_in_range != null and _player_in_range.has_method("unregister_interactable"):
		_player_in_range.unregister_interactable(self)
	elif player != null and player.has_method("unregister_interactable"):
		player.unregister_interactable(self)

	_drop_loot()


func _drop_loot() -> void:
	var parent := get_tree().current_scene
	if parent == null:
		parent = get_parent()
	if parent == null:
		return

	if rare_seed_chance > 0.0 and randf() < rare_seed_chance:
		RunState.add_run_quest_item(&"rare_seed")

	if (
		horsey_chance > 0.0
		and not RunState.horsey_spawned_this_run
		and randf() < horsey_chance
	):
		RunState.horsey_spawned_this_run = true
		_spawn_horsey(parent)
		return

	var weapon_id: GroyperWeapons.Id = WEAPON_POOL[randi() % WEAPON_POOL.size()] as GroyperWeapons.Id
	# Guard: only drop IDs the weapon-pickup pipeline accepts.
	if not WeaponPickupScript._is_droppable_weapon_id(weapon_id):
		weapon_id = GroyperWeapons.Id.REVOLVER
	var drop_pos := _get_drop_start()
	var pickup := WeaponPickupScript.spawn_death_drop(parent, drop_pos, weapon_id)
	if pickup != null:
		pickup.set("weapon_id", weapon_id)
		_tween_loot_to_ground(pickup)


func _spawn_horsey(parent: Node) -> void:
	var horse: Node3D = HORSEY_SCENE.instantiate() as Node3D
	if horse == null:
		return
	parent.add_child(horse)
	var drop_dir := -global_transform.basis.z
	drop_dir.y = 0.0
	if drop_dir.length_squared() < 0.0001:
		drop_dir = Vector3.FORWARD
	else:
		drop_dir = drop_dir.normalized()
	horse.global_position = global_position + drop_dir * 2.2 + Vector3(0.0, 0.2, 0.0)
	if horse.has_method("snap_to_floor"):
		horse.snap_to_floor()
	var hud_player := _player_in_range
	if hud_player != null and hud_player.has_method("get_raid_hud"):
		var hud: Node = hud_player.get_raid_hud()
		if hud != null and hud.has_method("show_zone_title"):
			hud.show_zone_title("Horsey!!!", 2.4)


func _get_drop_start() -> Vector3:
	if _display_position != null:
		return _display_position.global_position
	return global_position + Vector3(0.0, FALLBACK_DISPLAY_HEIGHT, 0.0)


func _tween_loot_to_ground(pickup: Node3D) -> void:
	var start_pos := _get_drop_start()
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


func _on_body_entered(body: Node3D) -> void:
	if _opened:
		return
	if body is CharacterBody3D and body.has_method("register_interactable"):
		_player_in_range = body
		body.register_interactable(self)


func _on_body_exited(body: Node3D) -> void:
	if body == _player_in_range:
		_player_in_range = null
		if body.has_method("unregister_interactable"):
			body.unregister_interactable(self)
