extends RigidBody3D

## Run-zone physics barrel/crate: pushable, hostage-throwable, 1 HP break,
## drops auto-pickup loot. Distinct from cover Box / BreakableProp crates.
## WoodObjects meshes ship with large baked offsets — we recenter them so the
## collider matches the visible prop.

const GameAudioScript := preload("res://gameplay/audio/game_audio.gd")
const TownNpcShoveScript := preload("res://gameplay/world/town_npc_shove.gd")
const WoodBreakFXScript := preload("res://gameplay/fx/wood_break_fx.gd")
const RunDestructibleLootScript := preload("res://gameplay/runs/run_destructible_loot.gd")

const BARREL_SCENES := [
	preload("res://Assets/World/WoodObjects/Scenes/objects/Barrel_1.tscn"),
	preload("res://Assets/World/WoodObjects/Scenes/objects/Barrel_2.tscn"),
	preload("res://Assets/World/WoodObjects/Scenes/objects/Barrel_3.tscn"),
]
const CRATE_SCENE := preload("res://Assets/World/WoodObjects/Scenes/objects/MilkCrate.tscn")

const PUSHABLE_COLLISION_LAYER := 2
const PUSHER_GROUPS: Array[StringName] = [
	&"overworld_player",
	&"player",
	&"town_npc",
]

const PUSHER_RADIUS := 0.36
const CONTACT_SLACK := 0.16
const PUSH_ALIGNMENT_MIN := 0.2
const PUSH_FORCE := 70.0
const MOVE_SOUND_SPEED := 0.55
const MOVE_SOUND_COOLDOWN := 0.42

@export var is_barrel := true
@export var loot_mult := 1.0

const FIRE_BREAK_DAMAGE := 1.0

var _hostage_holder: Node3D
var _broken := false
var _move_sound_cooldown := 0.0
var _box_center := Vector3(0.0, 0.4, 0.0)
var _contact_radius := 0.45
var _fire_damage_accum := 0.0


func _ready() -> void:
	name = "RunLootProp"
	add_to_group(&"punchable_prop")
	# Reuse chair grab search so PropHostageTake works without player forks.
	add_to_group(&"sit_chair")
	mass = 8.0 if is_barrel else 6.0
	collision_layer = PUSHABLE_COLLISION_LAYER
	collision_mask = TownNpcShoveScript.PUSHABLE_COLLISION_MASK
	linear_damp = 1.1
	angular_damp = 1.3
	continuous_cd = true
	_spawn_visual()
	call_deferred("_finalize_collision")


func setup(as_barrel: bool, mult: float) -> void:
	is_barrel = as_barrel
	loot_mult = mult


func _spawn_visual() -> void:
	var scene: PackedScene = CRATE_SCENE
	if is_barrel:
		scene = BARREL_SCENES[randi() % BARREL_SCENES.size()]
	var visual: Node3D = scene.instantiate() as Node3D
	if visual == null:
		return
	visual.name = "RunLootVisual"
	add_child(visual)


func _finalize_collision() -> void:
	_strip_static_collision()
	_recenter_visual_and_build_collider()


func _strip_static_collision() -> void:
	for child in find_children("PropCollision", "Node3D", true, false):
		child.queue_free()
	for child in find_children("*", "StaticBody3D", true, false):
		var body := child as StaticBody3D
		body.collision_layer = 0
		body.collision_mask = 0


func _recenter_visual_and_build_collider() -> void:
	var bounds := _compute_local_mesh_aabb()
	if bounds.size.length_squared() < 0.0001:
		_ensure_fallback_collider()
		return

	# Shift visual so the mesh bottom-center sits on the RigidBody origin.
	var shift := Vector3(
		-(bounds.position.x + bounds.size.x * 0.5),
		-bounds.position.y,
		-(bounds.position.z + bounds.size.z * 0.5)
	)
	var visual := get_node_or_null("RunLootVisual") as Node3D
	if visual != null:
		visual.position += shift

	bounds = _compute_local_mesh_aabb()
	_box_center = bounds.position + bounds.size * 0.5
	_contact_radius = maxf(bounds.size.x, bounds.size.z) * 0.5

	var shape_node := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if shape_node == null:
		shape_node = CollisionShape3D.new()
		shape_node.name = "CollisionShape3D"
		add_child(shape_node)
	var box := BoxShape3D.new()
	box.size = bounds.size
	shape_node.shape = box
	shape_node.position = _box_center

	center_of_mass_mode = RigidBody3D.CENTER_OF_MASS_MODE_CUSTOM
	center_of_mass = _box_center


func _compute_local_mesh_aabb() -> AABB:
	var bounds := AABB()
	var found := false
	for child in find_children("*", "MeshInstance3D", true, false):
		var mesh := child as MeshInstance3D
		if mesh.mesh == null:
			continue
		var mesh_aabb := mesh.get_aabb()
		var to_body := global_transform.affine_inverse() * mesh.global_transform
		var local_aabb := to_body * mesh_aabb
		if found:
			bounds = bounds.merge(local_aabb)
		else:
			bounds = local_aabb
			found = true
	return bounds


func _ensure_fallback_collider() -> void:
	if get_node_or_null("CollisionShape3D") != null:
		return
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(0.7, 1.0, 0.7) if is_barrel else Vector3(0.65, 0.55, 0.65)
	shape_node.shape = box
	shape_node.position = Vector3(0.0, box.size.y * 0.5, 0.0)
	_box_center = shape_node.position
	_contact_radius = maxf(box.size.x, box.size.z) * 0.5
	add_child(shape_node)


func get_prop_center() -> Vector3:
	return global_position + _box_center


func get_prop_contact_radius() -> float:
	return _contact_radius


func _physics_process(delta: float) -> void:
	_move_sound_cooldown = maxf(_move_sound_cooldown - delta, 0.0)
	if freeze or _hostage_holder != null or _broken:
		return
	_try_play_move_sound()
	_apply_character_pushes()


func _try_play_move_sound() -> void:
	if _move_sound_cooldown > 0.0:
		return
	if linear_velocity.length() < MOVE_SOUND_SPEED:
		return
	_move_sound_cooldown = MOVE_SOUND_COOLDOWN
	GameAudioScript.play_table_move(self, get_prop_center())


func _apply_character_pushes() -> void:
	var contact_range := _contact_radius + PUSHER_RADIUS + CONTACT_SLACK
	for group_name in PUSHER_GROUPS:
		for node in get_tree().get_nodes_in_group(group_name):
			if node is CharacterBody3D:
				_apply_push_from_mover(node as CharacterBody3D, contact_range)


func _apply_push_from_mover(mover: CharacterBody3D, contact_range: float) -> void:
	var center := get_prop_center()
	var offset := center - mover.global_position
	offset.y = 0.0
	if offset.length_squared() > contact_range * contact_range:
		return
	var intent := Vector3(mover.velocity.x, 0.0, mover.velocity.z)
	if mover.has_method("get_push_intent"):
		intent = mover.get_push_intent()
	intent.y = 0.0
	if intent.length_squared() < 0.04:
		return
	var push_dir := offset.normalized()
	if intent.normalized().dot(push_dir) < PUSH_ALIGNMENT_MIN:
		return
	sleeping = false
	apply_force(push_dir * PUSH_FORCE, _box_center)


func can_be_hostage_held() -> bool:
	return _hostage_holder == null and not _broken


func is_hostage_held() -> bool:
	return _hostage_holder != null


func begin_hostage_hold(holder: Node3D) -> void:
	_hostage_holder = holder
	linear_velocity = Vector3.ZERO
	angular_velocity = Vector3.ZERO
	freeze = true


func end_hostage_hold(holder: Node3D) -> void:
	if _hostage_holder != holder:
		return
	_hostage_holder = null
	freeze = false
	sleeping = false


func receive_punch(_hit_info: Dictionary) -> void:
	break_apart(_hit_info.get("direction", Vector3.ZERO))


func receive_bullet_hit(hit_info: Dictionary) -> void:
	apply_bullet_hit(hit_info)


func apply_bullet_hit(hit_info: Dictionary) -> void:
	if bool(hit_info.get("fire_burn", false)):
		apply_fire_damage(float(hit_info.get("chip_damage", 0.2)))
		return
	break_apart(hit_info.get("direction", Vector3.ZERO))


func apply_fire_damage(amount: float) -> void:
	if _broken or amount <= 0.0:
		return
	_fire_damage_accum += amount
	if _fire_damage_accum >= FIRE_BREAK_DAMAGE:
		break_apart(Vector3.UP)


func break_from_explosion(hit_info: Dictionary = {}) -> void:
	break_apart(hit_info.get("direction", Vector3.UP))


func break_apart(burst_direction: Vector3 = Vector3.ZERO) -> void:
	if _broken:
		return
	_broken = true
	var scene_parent := get_tree().current_scene
	if scene_parent == null:
		scene_parent = get_parent()
	var center := get_prop_center()
	WoodBreakFXScript.spawn(scene_parent, center, 12, 4, burst_direction)
	GameAudioScript.play_table_break(scene_parent, center)
	RunDestructibleLootScript.roll_and_spawn(scene_parent, center, loot_mult)
	queue_free()


func can_be_sat_on() -> bool:
	return false


func get_interact_hint() -> String:
	return ""


func interact(_player: Node3D) -> void:
	pass
